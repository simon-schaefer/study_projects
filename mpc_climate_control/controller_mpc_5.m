%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MPC 5 controller
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INPUT:
%   T: Measured system temperatures, dimension (3,1)
% OUTPUT:
%   p: Cooling power, dimension (2,1)

% Recitation 9 for observer layout
function p = controller_mpc_5(T)
% controller variables
persistent param
persistent x_hat
persistent d_hat
persistent yalmip_optimizer

% initialize controller, if not done already
if isempty(param)
    param = compute_controller_base_parameters;
    % reinitialize controller. 
    yalmip_optimizer  = init(param, param.T_sp, param.p_sp);
    % initialize x_hat and d_hat (estimates) and counter
    x_hat = T;
    d_hat = param.d;
end
% control variable
x = T; 

% determine new set point from offset in last step. 
Hsp = [1 0 0; 0 1 0]; 
Asp = [param.A - eye(3), param.B; Hsp, zeros(2,2)]; 
bsp = [-param.Bd*d_hat; param.T_sp(1:2)]; 
sp  = Asp\bsp; 
T_sp = sp(1:3); 
p_sp = sp(4:5);

% compute control action.
[u_mpc,errorcode] = yalmip_optimizer([x_hat;d_hat],T_sp,p_sp); 
if (errorcode ~= 0)
      warning('MPC infeasible');
end

% estimate state and disturbance
dummy = param.Aaug*[x_hat;d_hat] ...
        + param.Baug*u_mpc(:,1)...
        + param.L*(x-param.Caug*[x_hat;d_hat])
x_hat = dummy(1:3);
d_hat = dummy(4:6);

% denormalize control input.
p = u_mpc(:,1);
end

function [yalmip_optimizer] = init(param, T_sp, p_sp)
% initializes the controller on first call and returns parameters and
% Yalmip optimizer object
N = 30;
A = param.Aaug; 
B = param.Baug; 
Q = param.Q; 
R = param.R; 
nx = size(A,1);
nu = size(B,2);
Ucons = param.Pcons; 
Xcons = param.Tcons;
% compute feasibe set
[A_x, b_x] = compute_X_LQR; 
% initialize objective function and constraints (state constraint in the 
% k=0 step is not enforced due to numerical reasons). 
U = sdpvar(repmat(nu,1,N-1),repmat(1,1,N-1),'full'); %#ok<REPMAT>
X = sdpvar(repmat(nx,1,N),repmat(1,1,N),'full'); %#ok<REPMAT>
T_sp = sdpvar(nx/2,1,'full');
p_sp = sdpvar(nu,1,'full');
X{2} = A*X{1} + B*U{1};
constraints = [Ucons(:,1)<=U{1}<=Ucons(:,2)];
objective =  (X{1}(1:3,:)-T_sp)'*Q*(X{1}(1:3,:)-T_sp) + (U{1}-p_sp)'*R*(U{1}-p_sp);
for k = 2:N-1  
    X{k+1} = A*X{k} + B*U{k};
    constraints = [constraints; 
                   Ucons(:,1)<=U{k}<=Ucons(:,2); 
                   Xcons(:,1)<=X{k}(1:3,:)<=Xcons(:,2)]; %#ok<AGROW>
               
    objective = objective + (X{k}(1:3,:)-T_sp)'*Q*(X{k}(1:3,:)-T_sp) + (U{k}-p_sp)'*R*(U{k}-p_sp);
end
P_inf=1e8*diag([1,1,0]);
objective = objective + (X{N}(1:3,:)-T_sp)'*P_inf*(X{N}(1:3,:)-T_sp);
constraints = [constraints; A_x*(X{N}(1:3,:)-T_sp)<=b_x];
% initialize (yalmip) mpc problem. 
ops = sdpsettings('verbose',0,'solver','quadprog');
yalmip_optimizer = optimizer(constraints,objective,ops,{X{1},T_sp,p_sp},[U{:}]);
end