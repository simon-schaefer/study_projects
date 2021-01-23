function [ J_opt, u_opt_ind ] = ValueIteration( P, G )
%VALUEITERATION Value iteration
%   Solve a stochastic shortest path problem by Value Iteration.
%
%   [J_opt, u_opt_ind] = ValueIteration(P, G) computes the optimal cost and
%   the optimal control input for each state of the state space.
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
K = size(P,1); 
L = size(G,2); 
% Initialize cost vector arbitrarily. 
J_opt = zeros(K,1); 
u_opt_ind = zeros(K,1); 
% Recursion step - Update cost vector recursively following update equation
% Vl+1(i)=min q(i,u)+ sum_j Pij(u)Vl(j) 
% until the cost-to-go vector has converged, i.e. does not change anymore.
% Implementation would be more efficient using matlab vector notation, 
% i.e. find minimum min(G(i,:)+P*J_prev) but more intuitiv using for loops.
converged_max_diff = 1e-10; 
is_converged = false; 
iterations = 0; 
while ~is_converged
    J_prev = J_opt; 
    % Find the input with minimal cost u_opt for every possible state i. 
    for i = 1:K
        min_cost = inf; 
        for u = 1:L
            cost = G(i,u); 
            for j = 1:K
                cost = cost + P(i,j,u)*J_prev(j); 
            end
            if cost < min_cost
                min_cost = cost; 
                u_opt_ind(i) = u;
                J_opt(i) = cost; 
            end
        end
    end
    % Check whether cost-to-go vector already has converged. 
    is_converged = sum(abs(J_opt - J_prev)) < converged_max_diff; 
    % Update number of iterations.
    iterations = iterations + 1; 
end
fprintf("VI: Converged after %d iterations\n", iterations); 
end