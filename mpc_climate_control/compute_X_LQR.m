%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Computation of explicit invariant set
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OUTPUT:
%   A_x, b_x: Describes polytopic X_LQR = {x| A_x * x <= b_x}
% NOTE: As the invariantSet() function does not work properly (i.e. runs 
% infinitely) on our MacOs systems we precomputed the invariant set for 
% our final parameters and load it. However the used code to compute can be 
% found below.
function [A_x, b_x] = compute_X_LQR
%     % get basic controller parameters
%     param = compute_controller_base_parameters;
%     % Lecture 5 Slide 43 / Recitation 6
%     % compute invariant set using MPT toolbox. 
%     A = param.A;
%     B = param.B;
%     Q = param.Q;
%     R = param.R;
%     K = -dlqr(A,B,Q,R);
%     systemLQR = LTISystem('A', A+B*K);
%     Xp = Polyhedron('A', [eye(3); -1*eye(3); K; -1*K], ... 
%                     'b', [param.Xcons(:,2);-1*param.Xcons(:,1); ...
%                           param.Ucons(:,2);-1*param.Ucons(:,1)]);
%     systemLQR.x.with('setConstraint');
%     systemLQR.x.setConstraint = Xp;
%     % determine invariant set from given LQR. 
%     inv_set = systemLQR.invariantSet();
%     inv_set.plot() 
%     save('inv_set.mat', 'inv_set'); 
% 
    load('inv_set.mat', 'inv_set'); 
    %inv_set.plot()
    %title("Approximate Invariant Set")
    %print('outs/invariant_set_task','-dpng')
    A_x = inv_set.A; 
    b_x = inv_set.b;
end

