function [R, t3, X, P] = estimateTrafoFund(P0, P1, K, ...
                                           num_iter, max_error)
% Estimate transformation between previous and current image using 
% fundamental matrix estimate and RANSAC. 
% @param[in]    P0              matched camera 0 keypoints [2,L]. 
% @param[in]    P1              matched camera 1 keypoints [2,L]. 
% @param[in]    K               camera intrinsics.
% @param[in]    num_iter        #RANSAC iterations. 
% @param[out]   R               rotation matrix from 0 to 1. 
% @param[out]   t3              translation vector from 0 to 1. 
% @param[out]   X               triangulated point cloud [3,L]. 
num_points_0 = size(P0,2);
num_points_1 = size(P1,2); 
p0 = [P0;ones(1,num_points_0)];
p1 = [P1;ones(1,num_points_1)];
% Estimate Fundamental matrix using RANSAC by randomly picking 
% eight points and applying the 8 point algorithm. 
max_num_inliers = 0; 
inliers = NaN; 
for i = 1:num_iter
    [~, idx] = datasample(1:num_points_0, 8, 2, 'Replace', false);
    ps0 = p0(:, idx);
    ps1 = p1(:, idx);
    F = fundamentalEightPoint_normalized(ps0, ps1);
    % Determine reprojection error (epipolar line error). 
    epil0 = F.'*p1; 
    epil1 = F*p0; 
    epils = [epil0, epil1]; 
    errors = (sum(epils.*[p0, p1],1).^2)./(epils(1,:).^2 + epils(2,:).^2); 
    errors = sqrt(errors(1:num_points_1)+errors(num_points_1+1:end));
    % Determine inliers. 
    is = errors < max_error^2; 
    if nnz(is) > max_num_inliers
        max_num_inliers = nnz(is); 
        inliers = is; 
    end
end
assert(max_num_inliers > 7); 
p0 = p0(:,inliers); 
p1 = p1(:,inliers); 
F = fundamentalEightPoint_normalized(p0,p1);
E = K'*F*K;
% Obtain extrinsic parameters (R,t) from E.
[Rots,u3] = decomposeEssentialMatrix(E);
% Disambiguate among the four possible configurations. 
[R,t3] = disambiguateRelativePose(Rots,u3,p0,p1,K,K);
% Triangulate a point cloud using the final transformation (R,T).
M0 = K * eye(3,4);
M1 = K * [R, t3];
X = linearTriangulation(p0,p1,M0,M1);
P = p1(1:2,:); 
end