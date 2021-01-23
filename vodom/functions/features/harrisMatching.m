function [P1, P0] = harrisMatching(img0, img1, ...
                    num_kps,r_harris,kappa,r_sup,r_desc,lambda)
% Find feature matches based on Harris conrner detection algorithm. 
% @param[in]    img0        base image. 
% @param[in]    img1        target image. 
% @param[in]    num_kps     number of keypoints to match. 
% @param[in]    r_harris    Harris patch size (pixel radius). 
% @param[in]    kappa       Harris kappa. 
% @param[in]    r_sup       non-maximal suppression pixel radius. 
% @param[in]    r_desc      patch descriptor size. 
% @param[in]    lambda      matching (multiplier of smallest SSD match). 
% Detect and extract features in img0.
scores0 = harris(img0, r_harris, kappa);
kps0    = selectKeypoints(scores0, num_kps, r_sup);
descs0  = describeKeypoints(img0, kps0, r_desc);
% Detect and extract features in img1.
scores1 = harris(img1, r_harris, kappa);
kps1    = selectKeypoints(scores1, num_kps, r_sup);
descs1  = describeKeypoints(img1, kps1, r_desc);
% Match them!
matches = matchDescriptors(descs0, descs1, lambda);
[~, index0, index1] = find(matches);
kps0 = flipud(kps0);
kps1 = flipud(kps1);
P0 = kps0(:,index0);
P1 = kps1(:,index1);
end