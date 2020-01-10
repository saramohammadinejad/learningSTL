%% Clear
clear all;
clc;
%% close all opened files
close all;
%% set a random seed
seed=0;
rng(seed);
%% read data from file
cd ('/Users/saramohamadi/Desktop/RE_HSCC/experiments/Maritime_surveillance/data');
navalData=importdata('navalData');
navalLabels=importdata('navalLabels');
navalTimes=importdata('navalTimes');
%% enumerative solver 
cd ('/Users/saramohamadi/Desktop/RE_HSCC/EnumerativeSolver')   
traceTimeBegin = 0;
traceTimeHorizon = 60;   
timeRange = [traceTimeBegin, traceTimeHorizon];  
s1 = struct('name', 'x', ...
            'ops', {{'<','>'}}, ...
            'params', {{'valx'}}, ...
            'timeRange', timeRange, ...
            'range', [0, 81]); 
s2 = struct('name', 'y', ...
            'ops', {{'<','>'}}, ...
            'params', {{'valy'}}, ...
            'timeRange', timeRange, ...
            'range', [15, 46]); 
signals = {s2,s1}; 
Traces0 = makeBreachTraceSystem(signals);
Traces1 = makeBreachTraceSystem(signals);
Traces0_test = makeBreachTraceSystem(signals);
Traces1_test = makeBreachTraceSystem(signals);

options.numSignatureTraces = 4; 
options.numParamSamples = 5; 
options.discrepancyTolerance = 1e-3;
numTraces = 100; 
yapp = YAP(signals, numTraces, options); 

%% traces for training
i=1:2:121;
j=2:2:122;
tspan=0:60;
for k=1:100
    
    t=tspan';
    x=navalData(k,i)';
    y=navalData(k,j)';
    trace = [t y x];
    BrTrace = BreachTraceSystem({'y','x'}, trace);
    ro1= BrTrace.CheckSpec('alw_[0,60] (x[t] > 30)'); 
    ro2=  BrTrace.CheckSpec('ev_[0,60] (y[t] < 22)'); 
    yapp.addTrace(k,trace);

    if ro1>0
        Traces1.AddTrace(trace);
    elseif ro2>0
        Traces0.AddTrace(trace);
    else 
        Traces0.AddTrace(trace);
    end 
end

%% traces for testing
i=1:2:121;
j=2:2:122;
tspan=0:60;
for k=101:200
    
    t=tspan';
    x=navalData(k,i)';
    y=navalData(k,j)';
    trace = [t y x];
    BrTrace = BreachTraceSystem({'y','x'}, trace);
    ro1= BrTrace.CheckSpec('alw_[0,60] (x[t] > 30)'); 
    ro2=  BrTrace.CheckSpec('ev_[0,60] (y[t] < 22)'); 
    yapp.addTrace(k,trace);

    if ro1>0
        Traces1_test.AddTrace(trace);
    elseif ro2>0
        Traces0_test.AddTrace(trace);
    else 
        Traces0_test.AddTrace(trace);
    end 
end

%% learning STL classifier with optimization
j=1;
done=0;
f = formulaIterator(10, signals);
clc
fprintf('running with optimization...\n')
tic
while (1)
        
    formula = f.nextFormula();
    yapp.addTimeParams(formula); 
    % check the equivalence of formulas
    if (yapp.isNew(formula))
                 
        params = fieldnames(get_params(formula));
        numparam=length(params);
        paramranges = zeros(numparam,2);
        paramSamples=[];
        % set parameter ranges
        for i=1:numparam
            if string(params(i,1)) == "valx"
                paramranges (i,:)=[0, 81];
            elseif string(params(i,1)) == "valy"
                paramranges (i,:)=[15, 46];
            elseif string(params(i,1)) == "tau_1"
                paramranges (i,:)=[0,60];
            elseif string(params(i,1)) == "tau_2"
                paramranges (i,:)=[0,60];
            elseif string(params(i,1)) == "tau_3"
                paramranges (i,:)=[0,60];
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
                monoDir1=1;
            case 2
                monoDir1=0;
            case 3
                monoDir1=1;
            case 4
                monoDir1=0;
            case 5
                monoDir1=0;
            case 6
                monoDir1=1;
            case 7
                monoDir1=0;
            case 8
                monoDir1=1;
            case 9
                monoDir1=[1,0];
            case 10
                monoDir1=[0,0];
            case 11
                monoDir1=[1,0];
            case 12
                monoDir1=[0,0];
            case 13
                monoDir1=[1,1];
            case 14
                monoDir1=[0,1];
            case 15
                monoDir1=[1,1];
            case 16
                monoDir1=[0,1];   
            case 17
                monoDir1=[0,0];
            case 18
                monoDir1=[1,0];
            case 19
                monoDir1=[0,0];
            case 20
                monoDir1=[1,0];
            case 21
                monoDir1=[1,1,0];
            case 22
                monoDir1=[0,1,0];
            case 23
                monoDir1=[1,1,0];
            case 24
                monoDir1=[0,1,0];
            case 25
                monoDir1=[0,1,0];
            case 26
                monoDir1=[1,1];
            case 27
                monoDir1=[0,1];
            case 28
                monoDir1=[1,1];
            case 29
                monoDir1=[1,0,1];
            case 30
                monoDir1=[0,0,1];
            case 31
                monoDir1=[1,0,1];
            case 32
                monoDir1=[0,0,1];
            case 33
                monoDir1=1;
            case 34
                monoDir1=[1,1];
            case 35
                monoDir1=[1,0];
            case 36
                monoDir1=[0,1];
            case 37
                monoDir1=[0,0];
            case 38
                monoDir1=1;
            case 39
                monoDir1=0;
            case 40
                monoDir1=[1,1];
            case 41
                monoDir1=[1,0];
            case 42
                monoDir1=[0,1];
            case 43
                monoDir1=[0,0];
            case 44
                monoDir1=1;
            case 45
                monoDir1=0;
            case 46
                monoDir1=[0,1];
            case 47
                monoDir1=[0,0];
            case 48
                monoDir1=1;
            case 49
                monoDir1=[1,1];
            case 50
                monoDir1=[1,0];
            case 51
                monoDir1=[0,1];
            case 52
                monoDir1=[0,0];
            case 53
                monoDir1=0;
            case 54
                monoDir1=[1,1];
            case 55
                monoDir1=[1,0];
            case 56
                monoDir1=1;
            case 57
                monoDir1=[1,1];
            case 58
                monoDir1=[1,1,1];
            case 59
                monoDir1=[1,0,1];
            case 60
                monoDir1=[0,1];
            case 61
                monoDir1=[0,1,1];
            case 62
                monoDir1=[0,0,1];
            case 63
                monoDir1=[1,1,1];
            case 64
                monoDir1=[1,0,1];
            case 65
                monoDir1=[1,1];
            case 66
                monoDir1=[0,1,1];
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
            if done == 1
                break;
            end
        end
    end
    j=j+1;
end
%% learning STL classifier without optimization
fprintf('***************************************************\n');
j=1;
done=0;
f = formulaIterator(10, signals);
fprintf('running without optimization...\n')
tic
while (1)
        
    formula = f.nextFormula();           
    params = fieldnames(get_params(formula));
    numparam=length(params);
    paramranges = zeros(numparam,2);
    paramSamples=[];

    %set parameter ranges
    for i=1:numparam
        if string(params(i,1)) == "valx"
            paramranges (i,:)=[0, 81];
        elseif string(params(i,1)) == "valy"
            paramranges (i,:)=[15, 46];
        elseif string(params(i,1)) == "tau_1"
            paramranges (i,:)=[0,60];
        elseif string(params(i,1)) == "tau_2"
            paramranges (i,:)=[0,60];
        elseif string(params(i,1)) == "tau_3"
            paramranges (i,:)=[0,60];
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
            monoDir1=1;
        case 2
            monoDir1=0;
        case 3
            monoDir1=1;
        case 4
            monoDir1=0;
        case 5
            monoDir1=0;
        case 6
            monoDir1=1;
        case 7
            monoDir1=0;
        case 8
            monoDir1=1;
        case 9
            monoDir1=[1,0];
        case 10
            monoDir1=[0,0];
        case 11
            monoDir1=[1,0];
        case 12
            monoDir1=[0,0];
        case 13
            monoDir1=[1,1];
        case 14
            monoDir1=[0,1];
        case 15
            monoDir1=[1,1];
        case 16
            monoDir1=[0,1];   
        case 17
            monoDir1=[0,0];
        case 18
            monoDir1=[1,0];
        case 19
            monoDir1=[0,0];
        case 20
            monoDir1=[1,0];
        case 21
            monoDir1=[1,1,0];
        case 22
            monoDir1=[0,1,0];
        case 23
            monoDir1=[1,1,0];
        case 24
            monoDir1=[0,1,0];
        case 25
            monoDir1=[0,1,0];
        case 26
            monoDir1=[1,1];
        case 27
            monoDir1=[0,1];
        case 28
            monoDir1=[1,1];
        case 29
            monoDir1=[1,0,1];
        case 30
            monoDir1=[0,0,1];
        case 31
            monoDir1=[1,0,1];
        case 32
            monoDir1=[0,0,1];
        case 33
            monoDir1=1;
        case 34
            monoDir1=[1,1];
        case 35
            monoDir1=[1,0];
        case 36
            monoDir1=[0,1];
        case 37
            monoDir1=[0,0];
        case 38
            monoDir1=1;
        case 39
            monoDir1=0;
        case 40
            monoDir1=[1,1];
        case 41
            monoDir1=[1,0];
        case 42
            monoDir1=[0,1];
        case 43
            monoDir1=[0,0];
        case 44
            monoDir1=1;
        case 45
            monoDir1=0;
        case 46
            monoDir1=[0,1];
        case 47
            monoDir1=[0,0];
        case 48
            monoDir1=1;
        case 49
            monoDir1=[1,1];
        case 50
            monoDir1=[1,0];
        case 51
            monoDir1=[0,1];
        case 52
            monoDir1=[0,0];
        case 53
            monoDir1=0;
        case 54
            monoDir1=[1,1];
        case 55
            monoDir1=[1,0];
        case 56
            monoDir1=1;
        case 57
            monoDir1=[1,1];
        case 58
            monoDir1=[1,1,1];
        case 59
            monoDir1=[1,0,1];
        case 60
            monoDir1=[0,1];
        case 61
            monoDir1=[0,1,1];
        case 62
            monoDir1=[0,0,1];
        case 63
            monoDir1=[1,1,1];
        case 64
            monoDir1=[1,0,1];
        case 65
            monoDir1=[1,1];
        case 66
            monoDir1=[0,1,1];
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
                    done=1;
                    break;
                end
            end


        end
        if done == 1
            break;
        end
    end 
    j=j+1;
end
    
%% comuting testing MCR based on the learned STL classifier by our tool  

pos = Traces1_test.CheckSpec('alw_[0,60] (x[t] > 36.3260)');
neg = Traces0_test.CheckSpec('alw_[0,60] (x[t] > 36.3260)');
mcr_test = (size(find (pos < 0),1) + size(find (neg > 0),1))/100;
fprintf('test MCR = %f\n',mcr_test);
    
    
