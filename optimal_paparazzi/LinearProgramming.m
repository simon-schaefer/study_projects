function [ J_opt, u_opt_ind ] = LinearProgramming( P, G )
%LINEARPROGRAMMING Value iteration
%   Solve a stochastic shortest path problem by Linear Programming.
%
%   [J_opt, u_opt_ind] = LinearProgramming(P, G) computes the optimal cost
%   and the optimal control input for each state of the state space.
%
%   Input arguments:
%
%       P:
%           A (K x K x L)-matrix containing the transition probabilities
%           between all states in the state space for all control inputs.
%           The entry P(i, j, l) represents the transition probability
%           from state i to state j if control input l is applied.
%
%       G:
%           A (K x L)-matrix containing the stage costs of all states in
%           the state space for all control inputs. The entry G(i, l)
%           represents the cost if we are in state i and apply control
%           input l.
%
%   Output arguments:
%
%       J_opt:
%       	A (K x 1)-matrix containing the optimal cost-to-go for each
%       	element of the state space.
%
%       u_opt_ind:
%       	A (K x 1)-matrix containing the index of the optimal control
%       	input for each element of the state space.

% put your code here
K = size(G,1); 
L = size(G,2); 
% 1.) Set up LP: Bring theorem 5.2 into "linprog" format.
% LINPROG: min_V f'V, subject to A*V <= b
f = -ones(K,1); % "-" because we want the resulting V to be maximum, but LINPROG is a minimizer.

% Iterate through all K*L combinations of state "i" and input "u" to setup
% inequality constraints:
A_ineq = [];
b_ineq = [];
for i=1:K
   for u=1:L
       if G(i,u)==inf
           % Don't consider movements, that are linked to infinite
           % costs (infeasible moves). This is consistent with the LP from
           % Theorem 5.2 as we only consider feasible moves!
           continue;
       else
           d = zeros(1,K);
           d(i) = 1;
           A_ineq = [A_ineq;d - P(i,:,u)];
           b_ineq = [b_ineq;G(i,u)];
       end
       
   end
end

% 2.) Solve LP.
J_opt = linprog(f,A_ineq,b_ineq);

% 3.) Find optimal inputs.
u_opt_ind = [];
for i=1:K
    u_min = -1;  % For each state "i", check which input u will yield the "best" equality of the bellman equation.
    delta_BE = inf;
    for u=1:L
        delta_BE_runner = abs(J_opt(i) - (G(i,u)+P(i,:,u)*J_opt));
        if delta_BE_runner < delta_BE
            u_min = u;
            delta_BE = delta_BE_runner; 
        end           
    end
    u_opt_ind = [u_opt_ind;u_min];
end
fprintf("LP: Found optimal solution\n"); 
end

