classdef TrajectoryHandler < BreachObject     
    properties
       numTraj
       trajs
       signalNames
    end
    
    methods
        function T = TrajectoryHandler(signalNames, trajectories)
            T@BreachObject;                        
            T.signalNames = signalNames;
            params = {'traj_num'};
            p0 = [1];
            simfn = @(Sys, tspan, p) T.TrajWrapper(T.Sys, tspan, p);
            T.Sys = CreateExternSystem('TrajGen', T.signalNames, params, p0, simfn);
            if (isempty(trajectories)) 
                T.numTraj = 0;
                return;
            else
                T.numTraj = length(trajectories);
            end               
            T.trajs = trajectories;
            traj1 = trajectories{1};
            times = traj1(:,1);
            tspan = [times(1) times(end)];
            T.Sys.tspan = tspan;           
            T.P = CreateParamSet(T.Sys);
        end
        
        
        function [t, X] = TrajWrapper(T, Sys, tspan, p)            
            if (T.numTraj==0)
                error('There are no trajectories to return!\n');
            end
            p = p(Sys.DimX+1:Sys.DimP);
            if (p > T.numTraj)
               error('There are only %d trajectories stored.\n', T.numTraj);
            end            
            s = T.trajs{p};
            t = s(:,1);
            X = s(:,2:size(s,2));
        end
    end
end
        

