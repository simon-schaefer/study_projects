% BRIEF:
%   Controller function template. This function can be freely modified but
%   input and output dimension MUST NOT be changed.
% INPUT:
%   T: Measured system temperatures, dimension (3,1)
% OUTPUT:
%   p: Cooling power, dimension (2,1)
function p = controller_mpc_1_forces(T)
% controller variables
persistent param forces_optimizer
% initialize controller, if not done already
if isempty(param)
    [param, forces_optimizer] = init();
end
% normalize state. 
x = T - param.T_sp; 
% compute control action.
[u_mpc,errorcode] = forces_optimizer{x}; 
if (errorcode ~= 0)
      warning('MPC infeasible');
end
% denormalize control input.
p = u_mpc(:,1) + param.p_sp;
end

function [param, forces_optimizer] = init()
% initializes the controller on first call and returns parameters and

param = compute_controller_base_parameters;
N = 30;
A = param.A; B = param.B; Q = param.Q; R = param.R; 
nx = size(A,1); nu = size(B,2);
Ucons = param.Ucons; Xcons = param.Xcons; 
% initialize objective function and constraints (state constraint in the 
% k=0 step is not enforced due to numerical reasons). 
U = sdpvar(repmat(nu,1,N-1),repmat(1,1,N-1),'full'); %#ok<REPMAT>
X = sdpvar(repmat(nx,1,N),repmat(1,1,N),'full'); %#ok<REPMAT>
objective = 0;
constraints = [X{:,2} == A * X{:,1} + B * U{:,1}, 
               Ucons(:,1) <= U{:,1} <= Ucons(:,2)];
for k = 2:N-1
  constraints = [constraints, X{:,k+1} == A * X{:,k} + B * U{:,k}];
  constraints = [constraints, Xcons(:,1) <= X{:,k} <= Xcons(:,2)];
  constraints = [constraints, Ucons(:,1) <= U{:,k} <= Ucons(:,2)];
  objective = objective + X{:,k}.' * param.Q * X{:,k} + U{:,k}.' * R * U{:,k};
end
[~,P_inf,~] = dlqr(A,B,Q,R);
objective = objective + X{:,N}.'*P_inf*X{:,N};
param.P_inf = P_inf; 
x0 = sdpvar(nx,1);
constraints = [constraints, X{:,1} == x0];
%ops = getOptions('simpleMPC_solver');
codeoptions.BuildSimulinkBlock = 0;
codeoptions.name               = 'mpc_1_forces';
codeoptions.printlevel         = 0;
codeoptions.cleanup            = 0;
forces_optimizer = optimizerFORCES(constraints,objective,codeoptions,x0,[U{:}]);
end