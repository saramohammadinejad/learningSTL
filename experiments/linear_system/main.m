%% Clear
clc;
clear all;
%% close all opened files
close all;
%% set a random seed
seed=0;
rng(seed);

%% Initialize breach tool box
InitBreach;
S = BreachSimulinkSystem('linear_system');

numCP = 3;
inputGen.type = 'VarStep';
inputGen.cp = numCP;
S.SetInputGen(inputGen);
params = cell(2,numCP);
for jj = 1:numCP
    params{1,jj} = sprintf('attack_u%d',jj-1);
    params{2,jj} = sprintf('vin_u%d',jj-1);
end
endTime = 3;
tspan=0:0.2:endTime;
%% Set Breach Parameters to generate normal traces for train and test
S.SetTime(tspan);
AttackParamRanges = repmat([-1 0], numCP, 1); % Use [0 1] for attack (anomaly), [-1 0] for no attack (normal)
NoiseParamRanges = repmat([-0.04 0.04], numCP, 1);
ParamRangesMatrix = InterleaveMatrices(AttackParamRanges, NoiseParamRanges);
S.SetParamRanges(params, ParamRangesMatrix);
S.PrintParams;

%% Simulate
numSimulations = 100;
S.QuasiRandomSample(numSimulations);
S.Sim;

%% applying enumerative solver 
% set this directory to the place where contains EnumerativeSolver
cd ('/Users/saramohamadi/Desktop/RE_HSCC/EnumerativeSolver')   
traceTimeBegin = 0;
traceTimeHorizon = 3;   
timeRange = [traceTimeBegin, traceTimeHorizon];  
s1 = struct('name', 'x', ...
            'ops', {{'>','<'}}, ...
            'params', {{'valx'}}, ...
            'timeRange', timeRange, ...
            'range', [0.85, 1.15]);     
signals = {s1}; 
Traces0 = makeBreachTraceSystem(signals);%anomalous
Traces0_test = makeBreachTraceSystem(signals);
Traces1 = makeBreachTraceSystem(signals);%normal 
Traces1_test = makeBreachTraceSystem(signals);


options.numSignatureTraces = 2; 
numTraces = 2; 
yapp = YAP(signals, numTraces, options); 

%% Plot Signals
signalValues = S.GetSignalValues({'x'});
figure;
for jj = 1:50
    hold all;
    trace_normal = signalValues{jj};
    plot(tspan, awgn(trace_normal(1,:),40,'measured'), 'g','LineWidth',0.8);
    title('linear system case study');
    t=tspan';
    x=awgn(trace_normal(1,:),40,'measured')';
    trace = [t x];
    %normal traces for train 
    Traces1.AddTrace(trace);
    yapp.addTrace(jj,trace);
    BrTrace = BreachTraceSystem({'x'}, trace);
    Robustness_normal(jj,1) = BrTrace.CheckSpec('alw_[0,3](x[t] > 0.9902)'); %testing the learned formula
end
%% normal traces for test 
for jj = 51:numSimulations
    trace_normal = signalValues{jj};
    t=tspan';
    x=awgn(trace_normal(1,:),40,'measured')';
    trace = [t x];
    Traces1_test.AddTrace(trace);
end

%% Set Breach Parameters to generate anomalous traces for train and test
S.SetTime(tspan);
AttackParamRanges = repmat([0 1], numCP, 1); % Use [0 1] for attack => anomaly, [-1 0] for no attack => normal
VelocityParamRanges = repmat([-0.04 0.04], numCP, 1); 
ParamRangesMatrix = InterleaveMatrices(AttackParamRanges, VelocityParamRanges);
S.SetParamRanges(params, ParamRangesMatrix);
S.PrintParams;

%% Simulate
numSimulations = 100;
S.QuasiRandomSample(numSimulations);
S.Sim;

%% Plot Signals
signalValues = S.GetSignalValues({'x'});

for jj = 1:50
    hold all;
    trace_anomalous = signalValues{jj};
    plot(tspan, awgn(trace_anomalous(1,:),40,'measured'), 'r','LineWidth',0.8);
    title('linear system case study');
    t=tspan';
    x=awgn(trace_anomalous(1,:),40,'measured')';
    % anomalous traces for train 
    trace = [t x];
    Traces0.AddTrace(trace);
    BrTrace = BreachTraceSystem({'x'}, trace);
    Robustness_anomalous(jj,1) = BrTrace.CheckSpec('alw_[0,3](x[t] > 0.9902)');%testing the learned formula
end

%% anomalous traces for test 
for jj = 51:numSimulations
    trace_anomalous = signalValues{jj};
    t=tspan';
    x=awgn(trace_anomalous(1,:),40,'measured')';
    trace = [t x];
    Traces0_test.AddTrace(trace);
end

%% learning STL classifier with signature

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
             
        % set parameter ranges
        params = fieldnames(get_params(formula));
        numparam=length(params);
        paramranges = zeros(numparam,2);
        for i=1:numparam
            if string(params(i,1)) == "valx"
                paramranges (i,:)=[0.85, 1.15];
            elseif string(params(i,1)) == "tau_1"
                paramranges (i,:)=[0,3];
            elseif string(params(i,1)) == "tau_2"
                paramranges (i,:)=[0,3];
            elseif string(params(i,1)) == "tau_3"
                paramranges (i,:)=[0,3];
            end
        end
            
        % Monotonic_Bipartition function parameters
        uncertainty=10e-3;
        num_steps = 4; 
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
                    %plot the learned thresholds by our tool
                    y=[];
                    y(1,1:size(tspan,2))=c1(i,1);
                    plot(tspan,y,'b--','LineWidth',2);
                    xlabel('t');
                    ylabel('x(t)');
                    done=1;
                    break; 
                else

                    TruePos=size(find (robustness1(i,:) > 0 == 1),2);
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

                        %plot the learned thresholds by our tool
                        y=[];
                        y(1,1:size(tspan,2))=c1(i,1);
                        plot(tspan,y,'b--','LineWidth',2);
                        xlabel('t');
                        ylabel('x(t)');
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



%% learning STL classifier without signature
fprintf('***************************************************\n');
j=1;
done=0;
f = formulaIterator(10, signals);
fprintf('running without optimization ...\n')
tic
while (1)
    formula = f.nextFormula();      
    params = fieldnames(get_params(formula));
    numparam=length(params);
    paramranges = zeros(numparam,2);

    %set parameter ranges
    for i=1:numparam
        if string(params(i,1)) == "valx"
            paramranges (i,:)=[0.85, 1.15];
        elseif string(params(i,1)) == "tau_1"
            paramranges (i,:)=[0,3];
        elseif string(params(i,1)) == "tau_2"
            paramranges (i,:)=[0,3];
        elseif string(params(i,1)) == "tau_3"
            paramranges (i,:)=[0,3];
        end
    end

    % Monotonic_Bipartition function parameters
    uncertainty=10e-3;
    num_steps = 4; 
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
                done=1;

                break; 
            else

                TruePos=size(find (robustness1(i,:) > 0 == 1),2);
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
        if done==1
            break;
        end
         
    end
    j=j+1;
end

%% comuting testing MCR based on the learned STL classifier by our tool

pos = Traces1_test.CheckSpec('alw_[0,3] (x[t] > 0.9736)');
neg = Traces0_test.CheckSpec('alw_[0,3] (x[t] > 0.9736)');
mcr_test = (size(find (pos < 0),1) + size(find (neg > 0),1))/100;
fprintf('test MCR = %f\n',mcr_test);