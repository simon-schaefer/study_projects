%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MPC 2 controller
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT:
%   T: Measured system temperatures, dimension (3,1)
% OUTPUT:
%   p: Cooling power, dimension (2,1)
function p = controller_mpc_2(T)
% controller variables
persistent param yalmip_optimizer
% initialize controller, if not done already
is_first_step = false; 
if isempty(param)
    [param, yalmip_optimizer] = init();
    is_first_step = true; 
end
% normalize state. 
x = T - param.T_sp; 
% compute control action.
[u_mpc,errorcode] = yalmip_optimizer(x); 
if (errorcode ~= 0)
      warning('MPC infeasible');
end
% determine cost. 
if is_first_step
    J = compute_mpc_cost(x, u_mpc, zeros(3,3), param); 
    disp(["J(x(0)) = ", num2str(J)]); 
end
% denormalize control input.
p = u_mpc(:,1) + param.p_sp;
end

function [param, yalmip_optimizer] = init()
% initializes the controller on first call and returns parameters and
% Yalmip optimizer object
param = compute_controller_base_parameters;
N = 30;
A = param.A; B = param.B; Q = param.Q; R = param.R; 
nx = size(A,1); nu = size(B,2);
Ucons = param.Ucons; Xcons = param.Xcons; 
% initialize objective function and constraints (state constraint in the 
% k=0 step is not enforced due to numerical reasons). 
U = sdpvar(repmat(nu,1,N-1),repmat(1,1,N-1),'full'); %#ok<REPMAT>
X = sdpvar(repmat(nx,1,N),repmat(1,1,N),'full'); %#ok<REPMAT>
X{2} = A*X{1} + B*U{1};
constraints = [Ucons(:,1)<=U{1}<=Ucons(:,2)];
objective =  X{1}'*Q*X{1} + U{1}'*R*U{1};
for k = 2:N-1  
    X{k+1} = A*X{k} + B*U{k};
    constraints = [constraints; 
                   Ucons(:,1)<=U{k}<=Ucons(:,2); 
                   Xcons(:,1)<=X{k}<=Xcons(:,2)]; %#ok<AGROW>
    objective = objective + X{k}'*Q*X{k} + U{k}'*R*U{k};
end 
constraints = [constraints; X{N} == 0];
% initialize (yalmip) mpc problem. 
ops = sdpsettings('verbose',0,'solver','quadprog');
yalmip_optimizer = optimizer(constraints,objective,ops,X{1},[U{:}]);
% initialize helper vars. 
param.is_first_step = true; 
end

% Given that x(0) is in the feasible set, initialized with x(0) the closed-
% loop system will end up in x_30 = 0, as it is constrained to do. As can 
% be shown from the system equation x(k+1) = Ax(k) + Bu(k) without input 
% the system will stay at the origin (system is itself linear !). 

% For initial condition TO2 the system is not feasible although it is in  
% the region of attraction of the MPC2 controller, as it in the long-term 
% can converge to the origin (asym. stable) but a horizon of 30 steps is
% just not long enough to do so (while satisfying the constraints). 
