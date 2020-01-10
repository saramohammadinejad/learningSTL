%% Clear
clear all;
clc;
%% close all opened files
close all;
%% set a random seed
seed=0;
rng(seed);
%%
%initialization for enumerative solver 
InitBreach;
cd ('/Users/saramohamadi/Desktop/RE_HSCC/EnumerativeSolver')
numTraces = 31;    
traceTimeBegin = 0;
traceTimeHorizon = 400;   
timeRange = [traceTimeBegin, traceTimeHorizon];  
s1 = struct('name', 'x', ...
            'ops', {{'>','<'}}, ...
            'params', {{'valx'}}, ...
            'timeRange', timeRange, ...
            'range', [0, 1]);                         
signals = {s1}; 
Traces_good = makeBreachTraceSystem(signals);    
Traces_bad = makeBreachTraceSystem(signals); 
    
options.numSignatureTraces = 5;  
yapp = YAP(signals, numTraces, options); 
%% generating traces

for i=5:35
    period=i*2;
    delay=i-1;
    S = BreachSimulinkSystem('PID_controller');
    Ts=0.2;
    endTime=400;
    tspan = 0:Ts:endTime;
    S.SetTime(tspan);
    S.Sim;
    signalValues = S.GetSignalValues({'reference','measured output'});
    x = signalValues(1,:);
    y = signalValues(2,:);
    tr_in = [tspan' x'];
    tr_out = [tspan' y'];
    x2 = 1-x;
    tr_in2 = [tspan' x2'];
    BrTrace = BreachTraceSystem({'y'}, tr_out);
    yapp.addTrace(i,tr_in);
    
    % plotting

    if (period == 10)
        figure;
        hold all;
        subplot(2,2,1);
        plot (tspan, x,'r','LineWidth',2);
        title('bad input');
        axis([0 200 -1 2]);
        subplot(2,2,2);
        plot (tspan, y,'r', 'LineWidth',1.5);
        title('oscilating output');
        axis([0 200 -1 2]);

    end
    if (period == 60)

        subplot(2,2,3);
        plot (tspan, x, 'g','LineWidth',2);
        title('good input');
        axis([0 200 -1 2]);
        subplot(2,2,4);
        plot (tspan, y, 'g', 'LineWidth',1.5);
        title('setteled output');
        axis([0 200 -1 2]);

    end
    % good and bad traces for train
    if period > 42
        BrTrace.CheckSpec(sprintf('alw_[0,%d]( (y[t] > 1.5) => (alw_[%f,%f]((y[t]<1.04) and (y[t] > 0.96))))',endTime,(period/10)*3,(period/2)-(period/10)))
        Traces_good.AddTrace(tr_in);
        Traces_good.AddTrace(tr_in2);
    else
        BrTrace.CheckSpec(sprintf('alw_[0,%d]( (y[t] > 1.5) => (alw_[%f,%f]((y[t]<1.04) and (y[t] > 0.96))))',endTime,(period/10)*3,(period/2)-(period/10)))
        Traces_bad.AddTrace(tr_in);
        Traces_bad.AddTrace(tr_in2);
    end      
end


%% enumerative solver
clc
done=0;
fprintf('running with optimization...\n')
max_num_enumerating_formulas = 17;
j=1;
f = formulaIterator(10, signals);
tic
while (j < max_num_enumerating_formulas)
        
    formula = f.nextFormula();
    yapp.addTimeParams(formula); 
    % check the equivalence of formulas
    if (yapp.isNew(formula))
                
        params = fieldnames(get_params(formula));
        numparam=length(params);
        paramranges = zeros(numparam,2);
        % set parameter ranges    
        for i=1:numparam
            if string(params(i,1)) == "valx"
                paramranges (i,:)=[0,1];
            elseif string(params(i,1)) == "valy"
                paramranges (i,:)=[0,1];
            elseif string(params(i,1)) == "tau_1"
                paramranges (i,:)=[0,400];
            elseif string(params(i,1)) == "tau_2"
                paramranges (i,:)=[0,400];
            elseif string(params(i,1)) == "tau_3"
                paramranges (i,:)=[0,400];
            end
        end
        
        % Monotonic_Bipartition function parameters
        uncertainty=10e-3;
        num_steps = 2; 
        n= numparam;

        % monotonicity direction for enumerated formulas, will
        % automate this part in next version
        switch j
            case 1 
                monoDir1=0;
            case 2
                monoDir1=1;
            case 3
                monoDir1=1;
            case 4
                monoDir1=0;
            case 5
                monoDir1=[0,0];
            case 6
                monoDir1=[1,0];
            case 7
                monoDir1=[0,1];
            case 8
                monoDir1=[1,1];
            case 9
                monoDir1=[1,0];
            case 10
                monoDir1=[0,0];
            case 11
                monoDir1=[0,1,0];
            case 12
                monoDir1=[1,1,0];
            case 13
                monoDir1=[1,1];
            case 14
                monoDir1=[0,1];
            case 15
                monoDir1=[0,0,1];
            case 16
                monoDir1=[1,0,1];
            otherwise
                monoDir1=-1;      
        end
                              
        if (all(monoDir1)>=0)

            % obtain validity domain boundary
            mono=Monotonic_Bipartition (formula,paramranges,num_steps,uncertainty,Traces_bad,monoDir1);
            c1=reshape(mono.boundry_points,numparam,size(mono.boundry_points,2)/numparam)';

            % check points on validity domain boundary and choose
            % the point with MCR = 0
            for i = 1:size (c1,1)
                formula = set_params(formula,params, c1(i,:));
                robustness1(i,:)=Traces_bad.CheckSpec(formula);
                robustness2(i,:)=Traces_good.CheckSpec(formula);

                if and(all(robustness1(i,:)> 0),all(robustness2(i,:)<0)) 
                    fprintf('\n\n');
                    fprintf('The learned STL formula is:\n');
                    fprintf('\n');
                    fprintf(disp(formula));
                    fprintf('\n\n');
                    fprintf('The values of parameters are:\n');
                    for n = 1:size(params,1)
                        params(n)
                        c1(i,n)
                        fprintf('\n');
                    end
                    fprintf('MCR=0\n')
                    fprintf('Elapsed time with signature based optimization:\n')
                    toc
                    done=1;
                    break; 
                end

            end
            if done==1
                break;
            end
        end
    end
    j=j+1;
end   
%% enumerative solver
fprintf('******************************************\n');
fprintf('running without optimization...\n')
j=1;
f = formulaIterator(10, signals);
tic
while (1) 
        
    formula = f.nextFormula();
            
    params = fieldnames(get_params(formula));
    numparam=length(params);
    paramranges = zeros(numparam,2);
    %set parameter ranges
    for i=1:numparam
        if string(params(i,1)) == "valx"
            paramranges (i,:)=[0,1];
        elseif string(params(i,1)) == "valy"
            paramranges (i,:)=[0,1];
        elseif string(params(i,1)) == "tau_1"
            paramranges (i,:)=[0,400];
        elseif string(params(i,1)) == "tau_2"
            paramranges (i,:)=[0,400];
        elseif string(params(i,1)) == "tau_3"
            paramranges (i,:)=[0,400];
        end
    end

    % Monotonic_Bipartition function parameters
    uncertainty=10e-3;
    num_steps = 2; 
    n= numparam;

    % monotonicity direction for enumerated formulas, will
    % automate this part in next version            
    switch j
        case 1 
            monoDir1=0;
        case 2
            monoDir1=1;
        case 3
            monoDir1=1;
        case 4
            monoDir1=0;
        case 5
            monoDir1=[0,0];
        case 6
            monoDir1=[1,0];
        case 7
            monoDir1=[0,1];
        case 8
            monoDir1=[1,1];
        case 9
            monoDir1=[1,0];
        case 10
            monoDir1=[0,0];
        case 11
            monoDir1=[0,1,0];
        case 12
            monoDir1=[1,1,0];
        case 13
            monoDir1=[1,1];
        case 14
            monoDir1=[0,1];
        case 15
            monoDir1=[0,0,1];
        case 16
            monoDir1=[1,0,1];
        otherwise
            monoDir1=-1;      
    end
                    
                             
    if (all(monoDir1)>=0)

        % obtain validity domain boundary
        mono=Monotonic_Bipartition (formula,paramranges,num_steps,uncertainty,Traces_bad,monoDir1);
        c1=reshape(mono.boundry_points,numparam,size(mono.boundry_points,2)/numparam)';

        % check points on validity domain boundary and choose
        % the point with MCR = 0
        for i = 1:size (c1,1)
            formula = set_params(formula,params, c1(i,:));
            robustness1(i,:)=Traces_bad.CheckSpec(formula);
            robustness2(i,:)=Traces_good.CheckSpec(formula);

            if and(all(robustness1(i,:)> 0),all(robustness2(i,:)<0)) 
                fprintf('\n\n');
                fprintf('The learned STL formula is:\n');
                fprintf('\n');
                fprintf(disp(formula));
                fprintf('\n\n');
                fprintf('The values of parameters are:\n');
                for n = 1:size(params,1)
                    params(n)
                    c1(i,n)
                    fprintf('\n');
                end
                fprintf('MCR=0\n')
                fprintf('Elapsed time without signature based optimization:\n')
                toc
                return; 
            end

        end
    end
    j=j+1;
end