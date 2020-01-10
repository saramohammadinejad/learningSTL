%% Clear
% ccc;

%% Global variables
global v vmin vmax i vstate bstate ret nfail N attack
attack = [];

%% Initialize
% Set velocities

vmax = 28.5;
vmin = 20;
v = [];
v(1) = randi([0, 30]);

% Number of train cars
N = 3;

% Number of brakes engaged
i = 0;
ti = i;

% Initialize velocity and braking states
vstate = 1;
bstate = ones(1, N);

% Noise variables
n1 = randn;
n2 = 0.1 * randn;
n3 = 0.5 * randn;
n4 = 3 * randn;
n5 = 3 * randn;

% Simulation time
endTime = 100;
dt = 1;

%% Main program
c1 = zeros(1, N)-5;
c2 = zeros(1, N)-5;
nfail  = 0;
for tt = 1:dt:endTime
    velocity_subsystem(tt,n1,n2,n3);
    for nc = 1:N
        [c1(nc), c2(nc), ret] = ecp_braking_system(tt,n4,n5,c1(nc),c2(nc),nc);
        nfail = nfail + ret;
        if (nfail == N)
            %             disp('Fail');
            break;
        end
    end
    ti = [ti, i];
    if (nfail == N)
        break;
    end
end

%% Velocity Subsystem
function velocity_subsystem(k,n1,n2,n3)
global v i vmax vstate N
% qv_1
if (vstate == 1)
    %     disp('qv_1');
    v(k+1) = 0.1353*v(k)+0.8647*(25+2.5*sin(k))+n1;
    v(k+1) = v(k+1) + n3;
    if (v(k+1) > vmax)
        vstate = 2;
    end
    % end
    % qv_2
elseif (vstate == 2)
    %     disp('qv_2');
    v(k+1) = v(k)-0.5*max(0,i-floor(N/3))+n2;
    v(k+1) = v(k+1) + n3;
    if (i > 0)
        vstate = 3;
    end
    % end
    % qv_3
elseif (vstate == 3)
    %         disp('qv_3');
    v(k+1) = v(k)-0.5*max(0,i-floor(N/3))+n3;
    v(k+1) = v(k+1) + n3;
    if (i == 0)
        vstate = 1;
    end
end
end

%% ECP Braking System
function [c1, c2, ret] = ecp_braking_system(k,n4,n5,c1,c2,nc)
global v vmin vmax i bstate attack
ret = 0;
% q1_1
if (bstate(nc) == 1)
    %     disp('qb1_1');
    c1 = n4;
    if (v(k) > vmax)
        c1 = -abs(c1);
        bstate(nc) = 2;
    end
end
% q1_2
if (bstate(nc) == 2)
    %     disp('qb1_2');
    c1 = c1 + 1;
    if (c1 > 1)
        p = randi(10) > 0;
        if ((p == 0) && (k < 10))
            bstate(nc) = 5;
        else
            i = i + 1;
            bstate(nc) = 3;
        end
    end
end
% q1_3
if (bstate(nc) == 3)
    %     disp('qb1_3');
    c2 = n5;
    if (v(k) < vmin)
        c2 = -abs(c2);
        bstate(nc) = 4;
    end
end
% q1_4
if (bstate(nc) == 4)
    %     disp('qb1_4');
    c2 = c2 + 1;
    if (c2 > 1)
        i = i - 1;
        bstate(nc) = 1;
    end
end
% q1_fail
if (bstate(nc) == 5)
    attack = [attack, i+1]
    ret = 1;
    %     return;
end
end