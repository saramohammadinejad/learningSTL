%% Clear
clc;
clear all;
%% close all opened files
close all;
%% set a random seed
seed=0;
rng(seed);

%% Intitializations

% Set velocity limits
vmax = 28.5;
vmin = 20;

% Brake status: 1 to enable all brakes, -1 to disable all brakes
brake_status = -1;
if brake_status > 0
    disp("Normal: All brakes enabled");
elseif brake_status < 0
    disp("Anomaly: All brakes disabled");
end

% Initialize Breach, model, parameters
InitBreach;
mdl = 'train_system_3Brakes';
endTime = 100;
S = BreachSimulinkSystem(mdl);
simuationTimeHorizon = 0:1:endTime;
S.SetTime(simuationTimeHorizon); 
inputGen.type = 'VarStep';
numCP = 1; % number of control points
inputGen.cp = numCP;
S.SetInputGen(inputGen);
S.PrintParams();
params = cell(1,numCP);

for jj=1:numCP
    params{1,jj} = sprintf('vin_u%d',jj-1);
end

S.SetParamRanges(params,repmat([0 30],numCP,1));
S.PrintParams;
numSimulations = 30;
S.QuasiRandomSample(numSimulations);
S.PrintSignals();

%% Run simulations
S.Sim;
%% get signals from the model
signalValues = S.GetSignalValues({'Velocity'});
v_mat = [];
%% Save in CSV
for sn = 1:numSimulations
    vb_signals = signalValues{sn};
    velocities = vb_signals(1,:);
    v_mat = [v_mat; velocities];
end

if brake_status > 0
    %csvwrite('Traces_normal.csv', v_mat);
elseif brake_status < 0
    %csvwrite('Traces_anomaly.csv', v_mat);
end


normal_traces = csvread('Traces_normal.csv');
anomalous_traces = csvread('Traces_anomaly.csv');

%% plot traces
figure;
hold all;
	
plot(tspan,awgn(normal_traces(1:20,:),25,'measured'),'g');
plot(tspan,awgn(anomalous_traces(1:20,:),25,'measured'),'r');
axis([0 100 10 50])
title('train cruise control case study');

%%
%applying enumerative solver 
cd ('/Users/saramohamadi/Desktop/RE_HSCC/EnumerativeSolver')   
traceTimeBegin = 0;
traceTimeHorizon = 100;   
timeRange = [traceTimeBegin, traceTimeHorizon];  
s1 = struct('name', 'x', ...
            'ops', {{'<','>'}}, ...
            'params', {{'valx'}}, ...
            'timeRange', timeRange, ...
            'range', [5, 50]);     
signals = {s1}; 
Traces0 = makeBreachTraceSystem(signals);%anomalous
Traces1 = makeBreachTraceSystem(signals);%normal 

Traces0_test = makeBreachTraceSystem(signals);%anomalous
Traces1_test = makeBreachTraceSystem(signals);%normal 


options.numSignatureTraces = 3; 
numTraces = 10; 
yapp = YAP(signals, numTraces, options); 

%% train traces

for jj = 1:50
    x=awgn(normal_traces(jj,:),25,'measured');
    t=0:100;
    trace = [t' x'];
    Traces1.AddTrace(trace);
    yapp.addTrace(jj,trace);
    x=awgn(anomalous_traces(jj,:),25,'measured');
    trace = [t' x'];
    Traces0.AddTrace(trace);
end
%% test traces
    
for jj = 51:100
    x=awgn(normal_traces(jj,:),25,'measured');
    t=0:100;
    trace = [t' x'];
    Traces1_test.AddTrace(trace);
    x=awgn(anomalous_traces(jj,:),25,'measured');
    trace = [t' x'];
    Traces0_test.AddTrace(trace);
end
%% learning STL classifier with signature
clc
fprintf('running with optimization...\n')
j=1;
done=0;
f = formulaIterator(10, signals);
tic
while (1)  
    formula = f.nextFormula();
    yapp.addTimeParams(formula);  
    % check the equivalence of formulas
    if (yapp.isNew(formula))
            
        % set parameter ranges
        params = fieldnames(get_params(formula));
        numparam=length(params);
        paramranges = zeros(numparam,2);
            
        for i=1:numparam
            if string(params(i,1)) == "valx"
                paramranges (i,:)=[5, 50];
            elseif string(params(i,1)) == "tau_1"
                paramranges (i,:)=[0,100];
            elseif string(params(i,1)) == "tau_2"
                paramranges (i,:)=[0,100];
            elseif string(params(i,1)) == "tau_3"
                paramranges (i,:)=[0,100];
            end
        end
        % Monotonic_Bipartition function parameters
        uncertainty=10e-3;
        num_steps = 3; 
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
            mono=Monotonic_Bipartition (formula,paramranges,num_steps,uncertainty,Traces1,monoDir1);
            c1=reshape(mono.boundry_points,numparam,size(mono.boundry_points,2)/numparam)';

            % check points on validity domain boundary and choose
            % the point with MCR = 0
            for i = 1:size (c1,1)
                formula = set_params(formula,params, c1(i,:));
                robustness1(i,:)=Traces1.CheckSpec(formula);
                robustness2(i,:)=Traces0.CheckSpec(formula);

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
                    fprintf('train MCR=0\n')
                    fprintf('Elapsed time with signature based optimization:\n')
                    toc
                    done=1;
                    break; 
                else

                    TruePos=size(find (robustness1(i,:)> 0 == 1),2);
                    FalsePos=size(robustness1,2)-TruePos;

                    TrueNeg=size(find (robustness2(i,:) < 0 == 1),2);
                    FalseNeg=size(robustness2,2)-TrueNeg;



                    MCR = (FalsePos + FalseNeg)/(size(robustness1,2)+size(robustness2,2));

                    % check points on validity domain boundary and choose
                    % the point with MCR < 0.1
                    if MCR < 0.1
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
                        fprintf('train MCR = %f\n',MCR);
                        fprintf('Elapsed time with signature based optimization:\n')
                        toc
                        done=1;
                        break;
                    end
                end


            end
            if done==1
                break;
            end
        end      
    end
    j=j+1;
end
 
%%  learning STL classifier without signature
fprintf('***************************************************\n');
fprintf('running without optimization...\n')
j=1;
done=0;
f = formulaIterator(10, signals);
tic
while (1)
        
    formula = f.nextFormula();
    %set parameter ranges
    params = fieldnames(get_params(formula));
    numparam=length(params);
    paramranges = zeros(numparam,2);


    for i=1:numparam
        if string(params(i,1)) == "valx"
            paramranges (i,:)=[5, 50];
        elseif string(params(i,1)) == "tau_1"
            paramranges (i,:)=[0,100];
        elseif string(params(i,1)) == "tau_2"
            paramranges (i,:)=[0,100];
        elseif string(params(i,1)) == "tau_3"
            paramranges (i,:)=[0,100];
        end
    end
    % Monotonic_Bipartition function parameters
    uncertainty=10e-3;
    num_steps = 3; 
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
        mono=Monotonic_Bipartition (formula,paramranges,num_steps,uncertainty,Traces1,monoDir1);
        c1=reshape(mono.boundry_points,numparam,size(mono.boundry_points,2)/numparam)';

        % check points on validity domain boundary and choose
        % the point with MCR = 0
        for i = 1:size (c1,1)
            formula = set_params(formula,params, c1(i,:));
            robustness1(i,:)=Traces1.CheckSpec(formula);
            robustness2(i,:)=Traces0.CheckSpec(formula);

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
                fprintf('train MCR=0\n')
                fprintf('Elapsed time without signature based optimization:\n')
                toc
                %plot the learned thresholds by our tool
                y=[];
                y(1,1:size(tspan,2))=c1(i,1);
                plot(tspan,y,'b--','LineWidth',2);
                xlabel('t(s)');
                ylabel('v(m/s)');
                done=1;
                break; 
            else

                TruePos=size(find (robustness1(i,:)> 0 == 1),2);
                FalsePos=size(robustness1,2)-TruePos;

                TrueNeg=size(find (robustness2(i,:) < 0 == 1),2);
                FalseNeg=size(robustness2,2)-TrueNeg;

                MCR = (FalsePos + FalseNeg)/(size(robustness1,2)+size(robustness2,2));

                % check points on validity domain boundary and choose
                % the point with MCR = 0.1
                if MCR < 0.1
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
                    fprintf('train MCR = %f\n',MCR);
                    fprintf('Elapsed time without signature based optimization:\n')
                    toc
                    %plot the learned thresholds by our tool
                    y=[];
                    y(1,1:size(tspan,2))=c1(i,1);
                    plot(tspan,y,'b--','LineWidth',2);
                    xlabel('t(s)');
                    ylabel('v(m/s)');
                    done=1;
                    break;
                end
            end

        end
        if done==1
            break;
        end
    end
   
    j=j+1;
end
    
%% comuting testing MCR based on the learned STL classifier by our tool    
pos = Traces1_test.CheckSpec('alw_[0,100] (x[t] < 35.8816)');
neg = Traces0_test.CheckSpec('alw_[0,100] (x[t] < 35.8816)');
mcr_test = (size(find (pos < 0),1) + size(find (neg > 0),1))/100;
fprintf('test MCR = %f\n',mcr_test);
