function parameters = loadParameters(ds)
% Load parameters for each dataset (0: KITTI, 1: Malaga, 2: parking).
parameters = containers.Map;  

parameters('harris_r')              = 9;    % Harris Gaussian filter size (radius).  
parameters('harris_kappa')          = 0.08; % Harris keypoint extraction parameter. 
parameters('harris_r_sup')          = 8;    % radius of suppressing adjacent keypoints. 
parameters('harris_r_desc')         = 9;    % radius of patch descriptor. 

parameters('fund_num_iter')         = 200;  % max #iterations ransac for fundamental matrix estimation. 
parameters('fund_max_error')        = 1;    % max reprojection error for fundamental matrix estimation.

parameters('counter_max')           = 10;   % maximal counter value to keep correspondence. 
parameters('counter_cand_max')      = 10;   % maximal counter value to keep candidate. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% KITTI  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ds == 0
parameters('bootstrap_frames')      = [1 3]; 
parameters('init_num_kps')          = 1000; % #keypoints for initialization. 
parameters('cont_num_kps')          = 200;  % #keypoints for candidate search in contop.
parameters('reinit_min_kps')        = 40;   % below #keypoints reinitialize.  
parameters('reinit_counter')        = 10;   % maximal frames without reinit due to scale drift. 

parameters('match_lambda')          = 5;    % matching threshold (multiplier of smallest SSD match). 

parameters('klt_max_bierror')       = inf;  % max. bidirectional error for KLT.                        
                                         
parameters('p3p_min_num')           = 6;    % minimal # of RANSAC inliers to be valid pose estimate.                               
parameters('p3p_num_iter')          = 90;   % #iterations ransac for p3p.                                      
parameters('p3p_max_error')         = 5;    % max reprojection error to be p3p ransac inlier. 

parameters('select_min_counter')    = 3;    % minimal counter for keypoint selection. 
parameters('search_min_dis')        = 10;   % minimal distance from new kp candidates to existing kps. 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Malaga %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif ds == 1
parameters('bootstrap_frames')      = [1 3]; 
parameters('init_num_kps')          = 1000; % #keypoints for initialization. 
parameters('cont_num_kps')          = 550;  % #keypoints for candidate search in contop.
parameters('reinit_min_kps')        = 30;   % below #keypoints reinitialize.  
parameters('reinit_counter')        = 10;   % maximal frames without reinit due to scale drift. 

parameters('match_lambda')          = 5;    % matching threshold (multiplier of smallest SSD match). 

parameters('klt_max_bierror')       = inf;  % max. bidirectional error for KLT.                        
                                         
parameters('p3p_min_num')           = 6;    % minimal # of RANSAC inliers to be valid pose estimate.                               
parameters('p3p_num_iter')          = 600;  % #iterations ransac for p3p.                                      
parameters('p3p_max_error')         = 5;    % max reprojection error to be p3p ransac inlier. 

parameters('select_min_counter')    = 3;    % minimal counter for keypoint selection. 
parameters('search_min_dis')        = 30;   % minimal distance from new kp candidates to existing kps.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Parking %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif ds == 2
parameters('bootstrap_frames')      = [1 3];
parameters('init_num_kps')          = 1000; % #keypoints for initialization. 
parameters('cont_num_kps')          = 550;  % #keypoints for candidate search in contop.
parameters('reinit_min_kps')        = 30;   % below #keypoints reinitialize.  
parameters('reinit_counter')        = 10;   % maximal frames without reinit due to scale drift. 

parameters('match_lambda')          = 6;    % matching threshold (multiplier of smallest SSD match). 

parameters('klt_max_bierror')       = inf;  % max. bidirectional error for KLT.                        
                                         
parameters('p3p_min_num')           = 6;    % minimal # of RANSAC inliers to be valid pose estimate.                               
parameters('p3p_num_iter')          = 600;  % #iterations ransac for p3p.                                      
parameters('p3p_max_error')         = 6;    % max reprojection error to be p3p ransac inlier. 

parameters('select_min_counter')    = 3;    % minimal counter for keypoint selection. 
parameters('search_min_dis')        = 30;   % minimal distance from new kp candidates to existing kps. 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% ETH APRIL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif ds == 3
parameters('bootstrap_frames')      = [242 244]; 
parameters('init_num_kps')          = 150;  % #keypoints for initialization. 
parameters('cont_num_kps')          = 100;  % #keypoints for candidate search in contop.
parameters('reinit_min_kps')        = 30;   % below #keypoints reinitialize.  
parameters('reinit_counter')        = 10;   % maximal frames without reinit due to scale drift. 

parameters('match_lambda')          = 5;    % matching threshold (multiplier of smallest SSD match). 

parameters('klt_max_bierror')       = inf;  % max. bidirectional error for KLT.                        
                                         
parameters('p3p_min_num')           = 6;    % minimal # of RANSAC inliers to be valid pose estimate.                               
parameters('p3p_num_iter')          = 90;   % #iterations ransac for p3p.                                      
parameters('p3p_max_error')         = 5;    % max reprojection error to be p3p ransac inlier. 

parameters('select_min_counter')    = 3;    % minimal counter for keypoint selection. 
parameters('search_min_dis')        = 10;   % minimal distance from new kp candidates to existing kps. 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% ETH LONG %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif ds == 4
parameters('bootstrap_frames')      = [280 283]; 
parameters('init_num_kps')          = 500;  % #keypoints for initialization. 
parameters('cont_num_kps')          = 200;  % #keypoints for candidate search in contop.
parameters('reinit_min_kps')        = 30;   % below #keypoints reinitialize.  
parameters('reinit_counter')        = 8;    % maximal frames without reinit due to scale drift. 

parameters('match_lambda')          = 5;    % matching threshold (multiplier of smallest SSD match). 

parameters('klt_max_bierror')       = inf;  % max. bidirectional error for KLT.                        
                                         
parameters('p3p_min_num')           = 6;    % minimal # of RANSAC inliers to be valid pose estimate.                               
parameters('p3p_num_iter')          = 80;   % #iterations ransac for p3p.                                      
parameters('p3p_max_error')         = 5;    % max reprojection error to be p3p ransac inlier. 

parameters('select_min_counter')    = 3;    % minimal counter for keypoint selection. 
parameters('search_min_dis')        = 10;   % minimal distance from new kp candidates to existing kps. 

else 
    assert(false)
end