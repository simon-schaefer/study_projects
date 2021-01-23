function [T_WC, counter] = ransacLocalization(P, X, counter,... 
                           K, min_num_inliers, num_iter, pixel_tolerance)
% RANSAC-supported P3P localization algorithm based on given
% 2D-3D-correspondences. 
% @param[in]    P               image keypoints [2,L]. 
% @param[in]    X               corresponding landmarks [3,L]. 
% @param[in]    K               camera intrinsics matrix [3,3].
% @param[in]    counter         counter counter array for each corresp.. 
% @param[in]    min_num_inlier  minimal number of RANSAC inliers. 
% @param[in]    num_iter        #RANSAC iterations. 
% @param[in]    pixel_tolerance max. reprojection error to be inlier.

% Merely take most current tracked 2D-3D-correspondences. 
P = P(:, counter==0); 
X = X(1:3, counter==0); 

% Worst case scenario. 
if size(X,2) < 3
    T_WC = inv([eye(3), zeros(3,1); 0 0 0 1]);
    fprintf('ERROR: TOO FEW VALID CORRESPONENCES TO P3P!\n');
else
    % Initialize RANSAC.
    best_inlier_mask = zeros(1, size(P, 2));
    max_num_inliers = 0;

    % RANSAC
    for i = 1:num_iter
        % Model from k samples (DLT or P3P)
        [landmark_sample, idx] = datasample(X, 3, 2, 'Replace', false);
        keypoint_sample = P(:, idx);
        % Backproject keypoints to unit bearing vectors.
        normalized_bearings = K\[keypoint_sample; ones(1, 3)];
        for ii = 1:3
            normalized_bearings(:, ii) = normalized_bearings(:, ii) / ...
                norm(normalized_bearings(:, ii), 2);
        end

        poses = p3p(landmark_sample, normalized_bearings);

        % Decode p3p output
        R_C_W_guess = zeros(3, 3, 2);
        t_C_W_guess = zeros(3, 1, 2);
        for ii = 0:1
            R_W_C_ii = real(poses(:, (2+ii*4):(4+ii*4)));
            t_W_C_ii = real(poses(:, (1+ii*4)));
            R_C_W_guess(:,:,ii+1) = R_W_C_ii';
            t_C_W_guess(:,:,ii+1) = -R_W_C_ii'*t_W_C_ii;
        end

        % Count inliers: First guess.
        projected_points = projectPoints(...
            (R_C_W_guess(:,:,1) * X) + ...
            repmat(t_C_W_guess(:,:,1), [1 size(X, 2)]), K);
        difference = P - projected_points;
        errors = sum(difference.^2, 1);
        is_inlier = errors < pixel_tolerance^2;
        % Count inliers: Second guess.
        projected_points = projectPoints(...
            (R_C_W_guess(:,:,2) * X) + ...
            repmat(t_C_W_guess(:,:,2), [1 size(X, 2)]), K);
        difference = P - projected_points;
        errors = sum(difference.^2, 1);
        alternative_is_inlier = errors < pixel_tolerance^2;
        % Choose best inlier. 
        choice = 1; 
        if nnz(alternative_is_inlier) > nnz(is_inlier)
            is_inlier = alternative_is_inlier;
            choice = 2; 
        end

        if nnz(is_inlier) > max_num_inliers && nnz(is_inlier) >= min_num_inliers
            max_num_inliers = nnz(is_inlier);        
            best_inlier_mask = is_inlier;
            if(choice == 1)
                best_R = R_C_W_guess(:,:,1);
                best_t = t_C_W_guess(:,:,1);
            elseif(choice == 2)
                best_R = R_C_W_guess(:,:,2);
                best_t = t_C_W_guess(:,:,2);
            end
        end
    end
    % Compute transformation matrix. 
    if max_num_inliers == 0
        R_CW = eye(3);
        t_CW = zeros(3,1);
    else
        R_CW = best_R;
        t_CW = best_t;
    end
    T_WC = inv([R_CW, t_CW; 0 0 0 1]); 
    counter(~best_inlier_mask) = inf; 
    fprintf('... number of p3p inliers: %d\n', max_num_inliers);
end
end

