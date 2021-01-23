function P = ComputeTransitionProbabilities( stateSpace, controlSpace, map, gate, mansion, cameras )
%COMPUTETRANSITIONPROBABILITIES Compute transition probabilities.
% 	Compute the transition probabilities between all states in the state
%   space for all control inputs.
%
%   P = ComputeTransitionProbabilities(stateSpace, controlSpace,
%   map, gate, mansion, cameras) computes the transition probabilities
%   between all states in the state space for all control inputs.
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
%       P:
%           A (K x K x L)-matrix containing the transition probabilities
%           between all states in the state space for all control inputs.
%           The entry P(i, j, l) represents the transition probability
%           from state i to state j if control input l is applied.
K = size(stateSpace,1); 
L = size(controlSpace,1); 
M = size(map,1);
N = size(map,2);
F = size(mansion,1); 
H = size(cameras,1); 
global p_c;
global gamma_p;
global states; 
global pool_num_time_steps; 
states = stateSpace; 
% Initialise transition probability matrix. 
P = zeros(K,K,L); 
% Find gate index. 
[~,g] = ismember(gate, stateSpace, 'rows');
% Find the area observed by the cameras - Iterate over all cameras, for 
% every camera iterate in cardinal directions and set probabilites 
% (if not already larger probability at state) until obstacle or border. 
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
    % Visualization. 
    % figure
    % camera_map = zeros(N,M); 
    % for i = 1:K
    %     pos = stateSpace(i,:); 
    %     camera_map(pos(1),pos(2)) = det_probs(i,c); 
    % end
    % heatmap(flipud(camera_map')); 
end
% Determine success rates of photographs, in dependence of whether 
% mansion is in field of view and on the distance to the mansion. 
photo_probs = p_c*ones(K,1);
for m = 1:F
    mansion_pos = mansion(m,:); 
    mx = mansion_pos(1);
    my = mansion_pos(2);
    photo = [mx, my, gamma_p]; 
    photo_probs = updatePhotoArea(photo, mx-1:-1:1, 'x', photo_probs); 
    photo_probs = updatePhotoArea(photo, mx+1:+1:N, 'x', photo_probs);
    photo_probs = updatePhotoArea(photo, my-1:-1:1, 'y', photo_probs);
    photo_probs = updatePhotoArea(photo, my+1:+1:M, 'y', photo_probs);
end
% Visualization. 
% figure
% photo_map = zeros(N,M); 
% for i = 1:K
%     pos = stateSpace(i,:); 
%     photo_map(pos(1),pos(2)) = photo_probs(i); 
% end
% heatmap(flipud(photo_map')); 
% Iterate over state space and look at every possible state combination 
% independently (not performant, but simplifying the problem). 
for i = 1:K
    pos = stateSpace(i,:); 
    % Set transition probabilities depending on control input. In
    % general the transitions are deterministic (except of camera case
    % which is treated later on).
    for u = 1:L
        control = controlSpace(u); 
        % First find index of next state, by "translating" control 
        % commands to new position. Additional, success probability 
        % is only greater zero when picture ('p') is inputted. 
        dx = 0; dy = 0; 
        success_prob = 0; 
        switch control
            case 'n'
                dy = 1; 
            case 'w'
                dx = -1; 
            case 's'
                dy = -1;
            case 'e'
                dx = 1; 
            case 'p'
                success_prob = photo_probs(i);  
        end
        % Find new state index based on deltas. When new position is not 
        % a member of stateSpace it is inaccessible, thereby inaccessible
        % state probability are intrinsically filtered out.
        pos_next = [pos(1)+dx, pos(2)+dy]; 
        if ismember(pos_next, stateSpace, 'rows')
            [~, j] = ismember(pos_next, stateSpace, 'rows'); 
        else
            continue;
        end
        % MOVING into water increase the probability to be catched as 
        % the camera have multiple chances. 
        pool_exponent = 1; 
        if (map(pos_next(2),pos_next(1)) < 0 && not(control=='p'))
            pool_exponent = pool_num_time_steps; 
        end
        % Compute transition probability based on success and detection 
        % probability, other than that the transition is deterministic.
        % The probability to be detected by at least one camera 
        % 1 - Pr(not be detected) with Pr(not be detected) =
        % prod(1-P_i(detected)) assuming independence. 
        not_detected = 1; 
        for c = 1:H
            not_detected = not_detected*(1-det_probs(j,c)); 
        end
        detecting_prob = 1 - not_detected;  
        % Camera spotting - Check whether next state is part of 
        % camera observated area. In case there is a probability != 0 to
        % be detected and therefore return to the gate. 
        if j ~= g
            if (pool_exponent==1)
                P(i,g,u) = detecting_prob*(1-success_prob); 
            elseif (pool_exponent==4)
                P(i,g,u) = (detecting_prob + ...
                    (1-detecting_prob)*detecting_prob +...
                    (1-detecting_prob)^2*detecting_prob + ...
                    (1-detecting_prob)^3*detecting_prob)*(1-success_prob);
            end
            P(i,j,u) = (1 - detecting_prob)^pool_exponent*(1-success_prob); 
        else
            P(i,j,u) = 1 - success_prob;
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

function out = updatePhotoArea(photo, range, coord, in)
    global states;
    out = in; 
    for k = range
        if coord == 'x'
            point = [k, photo(2)];
        else
            point = [photo(1), k];
        end
        % Get position state space index. 
        if ~ismember(point, states, 'rows')
            break; 
        else
            [~, idx] = ismember(point, states, 'rows'); 
        end
        % Determine detection probability. 
        if coord == 'x'
            prob = photo(3)/abs(k - photo(1)); 
        else
            prob = photo(3)/abs(photo(2) - k); 
        end
        % Update camera area matrix. 
        out(idx) = max(out(idx), prob);
    end
end