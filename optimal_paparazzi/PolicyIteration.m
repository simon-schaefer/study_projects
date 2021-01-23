function [ J_opt, u_opt_ind ] = PolicyIteration( P, G )
%POLICYITERATION Value iteration
%   Solve a stochastic shortest path problem by Policy Iteration.
%
%   [J_opt, u_opt_ind] = PolicyIteration(P, G) computes the optimal cost and
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
K = size(G,1); 

% Initialize u_opt_ind_loop with an proper policy (there is a non-zero
% probability to get to the end state when always taking a picture). 
u_opt_ind = 5*ones(K,1);
J_opt = ones(K,1); 

% Iterative policy evaluation and improvement. 
diff = Inf; 
J_last = zeros(K,1); 
iterations = 0; 
while diff > 1e-6
    J_opt = policyEvaluation(P, G, u_opt_ind);
    u_opt_ind = policyImprovement(P, G, J_opt);  
    diff = max(abs(J_last - J_opt)); 
    J_last = J_opt; 
    iterations = iterations + 1; 
end
fprintf("PI: Converged after %d iterations\n", iterations); 
end

% Computes the corresponding cost2go vector satisfying the B.E from Theorem
% 5.1, given a admissible policy mu_h.
function J_mu_h = policyEvaluation(P, G, mu_h)
    K = size(G,1); 
    % Least Squares approach to solve underlying linear systems of
    % equations. -> Bring eq. 5.1 into form A*x = b and solve for x.
    % J_mu_h = q_tilde_vec + P_tilde*J_mu_h => (I - P_tilde)*J_mu_h = q_tilde_vec
    P_tilde = [];
    q_tilde_vec = [];
    for i=1:K
        P_tilde = [P_tilde;P(i,:,mu_h(i))];    
        q_tilde_vec = [q_tilde_vec;G(i,mu_h(i))];
    end
    % Linear systems of equation: A*x=b
    A = (eye(K) - P_tilde);
    b = q_tilde_vec;
    J_mu_h = linsolve(A,b);
end 

function mu_next = policyImprovement(P, G, J)
    K = size(G,1);
    L = size(G,2); 
    mu_next = zeros(K,1); 
    for i = 1:K
        best_value = Inf;
        for u = 1:L
            value = G(i,u) + P(i,:,u)*J; 
            if value < best_value
               best_value = value; 
               mu_next(i) = u; 
            end
        end
    end
end
