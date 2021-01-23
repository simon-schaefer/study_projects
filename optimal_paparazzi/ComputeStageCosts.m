function G = ComputeStageCosts( stateSpace, controlSpace, map, gate, mansion, cameras )
%COMPUTESTAGECOSTS Compute stage costs.
% 	Compute the stage costs for all states in the state space for all
%   control inputs.
%
%   G = ComputeStageCosts(stateSpace, controlSpace, map, gate, mansion,
%   cameras) computes the stage costs for all states in the state space
%   for all control inputs.
%
%   Input arguments:
%
%       stateSpace:
%           A (K x 2)-matrix, where the i-th row represents the i-th
%           element of the state space.
%
%       controlSpace:
%           A (L x 1)-matrix, where the l-th row represents the l-th
%           element of the control space.
%
%       map:
%           A (M x N)-matrix describing the terrain of the estate map.
%           Positive values indicate cells that are inaccessible (e.g.
%           trees, bushes or the mansion) and negative values indicate
%           ponds or pools.
%
%   	gate:
%          	A (1 x 2)-matrix describing the position of the gate.
%
%    	mansion:
%          	A (F x 2)-matrix indicating the position of the cells of the
%           mansion.
%
%    	cameras:
%          	A (H x 3)-matrix indicating the positions and quality of the
%           cameras.
%
%   Output arguments:
%
%       G:
%           A (K x L)-matrix containing the stage costs of all states in
%           the state space for all control inputs. The entry G(i, l)
%           represents the expected stage cost if we are in state i and
%           apply control input l.

% put your code here
% The papparazzi wants to minimize his time spent
% Each action at each stage will have a expected stage cost (the randomness
% is due to the probability of getting caught on camera and have to return
% to gate).
% All possible outcomes at each admissible state for each control action:
% * Move N/S/E/W to acc. state in pond and get caught: 10 (4 + 6)
% * Move N/S/E/W to acc. state in pond and don't get caught: 4
% * Move N/S/E/W to acc. state not in pond and get caught: 6
% * Move N/S/E/W to acc. state not in pond and don't get caught: 1
% * Move N/S/E/W to inacc. state: Inf
% * Take photo succesfully: 1
% * Fail at taking photo and get caught: 7 (1+6)
% * Fail at taking photo and don't get caught: 1
% * Be at termination state and do whatever you want: 0
% Note: Mansion, Cameras and Bushes aren't accessible states!

% Init
K = size(stateSpace,1);
L = size(controlSpace,1);
M = size(map,1);
N = size(map,2);
F = size(mansion,1);
H = size(cameras,1);

G = zeros(K,L);
% Find gate index.
[~,g] = ismember(gate, stateSpace, 'rows');

global p_c;
global gamma_p;
global pool_num_time_steps;
global detected_additional_time_steps;


% Get the transition probability matrix.%
P = ComputeTransitionProbabilities( stateSpace, controlSpace,...
    map, gate, mansion, cameras );
% Compute detection probabilities.
det_probs = zeros(K,H);
for c = 1:H
    camera_pos = cameras(c,1:2);
    cx = camera_pos(1);
    cy = camera_pos(2);
    det_probs(:,c) = zeros(K,1);
    det_probs(:,c) = updateCameraArea(cameras(c,:), cx-1:-1:1, 'x', det_probs(:,c));
    det_probs(:,c) = updateCameraArea(cameras(c,:), cx+1:+1:N, 'x', det_probs(:,c));
    det_probs(:,c) = updateCameraArea(cameras(c,:), cy-1:-1:1, 'y', det_probs(:,c));
    det_probs(:,c) = updateCameraArea(cameras(c,:), cy+1:+1:M, 'y', det_probs(:,c));
end


for i = 1:K
    % Look through all states in the state space (-> Can be a current state).
    curr_state_ss = stateSpace(i,:); % ss: StateSpace ordering.
    for l = 1:L
        % Consider all inputs.
        control_input = controlSpace(l);
        dm = 0;
        dn = 0;
        switch control_input
            case 'n'
                dm = 1;
            case 'w'
                dn = -1;
            case 's'
                dm = -1;
            case 'e'
                dn = 1;
            case 'p'
                dm = 0;
                dn = 0;
        end
        
        next_state_ss = [curr_state_ss(1)+dn, curr_state_ss(2)+dm];
        
        if not(ismember(next_state_ss, stateSpace, 'rows'))
            % Catch infeasible moves.
            G(i,l) = inf;
        else
            % Only feasible moves left!
            exp_stage_cost = 0;
            
            % Compute stage cost for movement if everything was deterministic.
            if (control_input=='p' && not(isequal(next_state_ss,gate)))
                % Tried to take a photo!
                pr_success = 1 - sum(P(i,:,l));
                pr_caught = P(i,g,l);
                exp_stage_cost = pr_success*(1) + pr_caught*(1 + 6) + (1 - pr_success - pr_caught)*(1);    % Be either succesful, get caught or just wasted a shot.
            else
                if (isequal(next_state_ss,gate))
                    % Get detection probability.
                    [~,g] = ismember(gate, stateSpace, 'rows');
                    not_detected = 1;
                    for c = 1:H
                        not_detected = not_detected*(1-det_probs(g,c));
                    end
                    pr_detected = 1 - not_detected;
                    % Catching the case, where moving to gate intentionally!
                    if (isequal(curr_state_ss,gate))
                        % Catching the case, where we are on the gate and
                        % are trying to take a photo.
                        pr_success = 1 - sum(P(i,:,l));
                        pr_fail_and_caught = (1 - pr_success)*pr_detected;
                        pr_fail_not_caught = (1 - pr_success)*(1 - pr_detected);
                        exp_stage_cost = pr_success*(1) + pr_fail_and_caught*(1+6) + pr_fail_not_caught*(1);
                    else
                        exp_stage_cost = pr_detected*(1 + 6) + (1 - pr_detected)*(1);
                    end
                elseif (map(next_state_ss(2),next_state_ss(1))<0)
                    % Moving into pond!
                    pr_success = 1 - sum(P(i,:,l));  
                    pr_caught = P(i,g,l);
                    exp_stage_cost = pr_success*(1) + pr_caught*(4 + 6) + (1 - pr_success - pr_caught)*(4);
                else
                    % Moving to a normal square.
                    pr_success = 1 - sum(P(i,:,l));  
                    pr_caught = P(i,g,l);
                    exp_stage_cost = pr_success*(1) + pr_caught*(1 + 6) + (1 - pr_success - pr_caught)*(1);
                end
            end
            G(i,l) = exp_stage_cost;
        end
    end
end

end

function out = updateCameraArea(camera, range, coord, in)
global states;
K = size(states,1);
out = in;
for k = range
    if coord == 'x'
        point = [k, camera(2)];
    else
        point = [camera(1), k];
    end
    % Get position state space index.
    if ~ismember(point, states, 'rows')
        break;
    else
        [~, idx] = ismember(point, states, 'rows');
    end
    % Determine detection probability.
    if coord == 'x'
        prob = camera(3)/abs(k - camera(1));
    else
        prob = camera(3)/abs(camera(2) - k);
    end
    % Update camera area matrix.
    out(idx) = prob;
end
end

