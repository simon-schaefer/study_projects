%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MPC 4 controller
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT:
%   T: Measured system temperatures, dimension (3,1)
% OUTPUT:
%   p: Cooling power, dimension (2,1)
function p = controller_mpc_4(T)
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
    J = compute_mpc_cost(x, u_mpc, param.P_inf, param); 
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
% compute feasibe set
[A_x, b_x] = compute_X_LQR;
% initialize objective function and constraints (state constraint in the 
% k=0 step is not enforced due to numerical reasons). 
U = sdpvar(repmat(nu,1,N-1),repmat(1,1,N-1),'full'); %#ok<REPMAT>
X = sdpvar(repmat(nx,1,N),repmat(1,1,N),'full'); %#ok<REPMAT>
e = sdpvar(repmat(nx*2,1,N),repmat(1,1,N),'full'); %#ok<REPMAT>
X{2} = A*X{1} + B*U{1};
constraints = [Ucons(:,1)<=U{1}<=Ucons(:,2)];
objective =  X{1}'*Q*X{1} + U{1}'*R*U{1};
for k = 2:N-1  
    X{k+1} = A*X{k} + B*U{k};
    constraints = [constraints; 
                   Ucons(:,1)<=U{k}<=Ucons(:,2); 
                   Xcons(:,1)<=X{k}+e{k}(1:3,1);
                   X{k}<=(Xcons(:,2)+e{k}(4:6,1));
                   e{k}>=0]; %#ok<AGROW>
    objective = objective + X{k}'*Q*X{k} + U{k}'*R*U{k}+e{k}'*e{k}*1e5+sum(abs(e{k}))*1e5;
end
P_inf = zeros(3);
objective = objective + X{N}'*P_inf*X{N};
param.P_inf = P_inf; 
constraints = [constraints; A_x*X{N}<=b_x];
% initialize (yalmip) mpc problem. 
ops = sdpsettings('verbose',0,'solver','quadprog');
yalmip_optimizer = optimizer(constraints,objective,ops,X{1},[U{:}]);
end

% Having hard constraints only due to unknown disturbances the optimization
% problem might not be solvable anymore in 30 steps (i.e. the end state 
% x_30 in X_LQR not reachable without violating other constraints).
% Therefore these hard MPC controllers fail. In opposite introducing soft 
% constraints the optimization problem remains solvable, even in presence
% of unknown disturbances, the controller can recover. 
