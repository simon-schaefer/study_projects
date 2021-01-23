function [P,P_cand,P_cand_orig,T_cand_orig,X,counter,counter_cand] = ...
    postProcessing(P, P_cand, P_cand_orig, T_cand_orig, X, ...
    counter, counter_cand, max_counter, max_cand_counter)
% Discard landmarks that are behind the camera as they are surely outliers.
counter(X(3,:) < 0) = inf; 
% Increment non-selected as keypoint candidates counter.
counter_cand = counter_cand + 1; 
% Delete correspondences and candidates with too large counter. 
keep = counter <= max_counter;  
if sum(keep) < 10
    m = length(keep); 
    rand_idx = datasample(1:m, min(10, m), 'Replace', false);
    keep(rand_idx) = true; 
    fprintf('ERROR: TOO FEW VALID CORRESPONENCES TO REMOVE!\n');
end
P = P(:, keep); 
X = X(:, keep); 
counter = counter(keep); 
keep = counter_cand <= max_cand_counter; 
P_cand = P_cand(:, keep); 
P_cand_orig = P_cand_orig(:, keep); 
T_cand_orig = T_cand_orig(:, keep); 
counter_cand = counter_cand(keep); 
end