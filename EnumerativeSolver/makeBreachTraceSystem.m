function [T, TR] = makeBreachTraceSystem(signals)
    signalNames = {};
    for j=1:length(signals)
        signalNames{end+1} = signals{j}.name;
        if (j==1) % TR and tspan just for first signal
            TR = signals{j}.timeRange;
            tspan = max(TR);            
        end
    end
    T = BreachTraceSystem(signalNames);
    T.SetTime(tspan);
end