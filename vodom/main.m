%##########################################################################
% vodom - Visual Odometry Pipeline
% Nikhilesh Alatur, Simon Schaefer
%##########################################################################
clear all; close all; clc;  %#ok<CLALL>

addpath(genpath('functions/'));

disp("################################")
disp("vodom - Visual Odometry Pipeline")
disp("Nikhilesh Alatur, Simon Schaefer")
disp("################################")
%% Choose and load dataset. 
ds = 1; % 0: KITTI, 1: Malaga, 2: parking, 3: ETH April, 4: ETH Long

% Parameters. 
p = loadParameters(ds); 

% Load dataset - Images and ground truth. 
ground_truth = NaN; 
imgs_bootstrap = []; 
imgs_contop = [];
disp("Loading dataset images ..."); 
if ds == 0
    ground_truth = load(['datasets/kitti/' '/poses/00.txt']);
    ground_truth = ground_truth(:, [end-8 end]);
    last_frame = 1000; %4540;   
    K = [7.188560000000e+02 0 6.071928000000e+02
        0 7.188560000000e+02 1.852157000000e+02
        0 0 1];
    % Load bootstrap images. 
    bootstrap_frames = p('bootstrap_frames'); 
    img0 = imread(['datasets/kitti/00/image_0/' ...
        sprintf('%06d.png',bootstrap_frames(1))]);
    img1 = imread(['datasets/kitti/00/image_0/' ...
        sprintf('%06d.png',bootstrap_frames(2))]);
    imgs_bootstrap = [img0; img1]; 
    % Load continous operation images. 
    imgs_contop = uint8(zeros(size(img0,1), size(img0,2), ...
                        last_frame-bootstrap_frames(2))); 
    k = 1; 
    for i = (bootstrap_frames(2)+1):last_frame
        img = imread(['datasets/kitti/00/image_0/' sprintf('%06d.png',i)]);
        imgs_contop(:,:,k) = img; 
        k = k + 1; 
    end   
    % Adapt ground truth to initialization. 
        ground_truth = ground_truth(bootstrap_frames(2)+1:last_frame, :);
elseif ds == 1
    images = dir(['datasets/malaga/' ...
        '/malaga-urban-dataset-extract-07_rectified_800x600_Images']);
    left_images = images(3:2:end);
    last_frame = length(left_images);
    K = [621.18428 0 404.0076
        0 621.18428 309.05989
        0 0 1];
    % Load bootstrap images. 
    bootstrap_frames = p('bootstrap_frames'); 
    img0 = rgb2gray(imread(['datasets/malaga/' ...
        '/malaga-urban-dataset-extract-07_rectified_800x600_Images/' ...
        left_images(bootstrap_frames(1)).name]));
    img1 = rgb2gray(imread(['datasets/malaga/' ...
        '/malaga-urban-dataset-extract-07_rectified_800x600_Images/' ...
        left_images(bootstrap_frames(2)).name]));
    imgs_bootstrap = [img0; img1]; 
    % Load continous operation images. 
    imgs_contop = uint8(zeros(size(img0,1), size(img0,2), ...
                        last_frame-bootstrap_frames(2))); 
    k = 1; 
    for i = (bootstrap_frames(2)+1):last_frame
        img = rgb2gray(imread(['datasets/malaga/' ...
            '/malaga-urban-dataset-extract-07_rectified_800x600_Images/' ...
            left_images(i).name]));
        imgs_contop(:,:,k) = img; 
        k = k + 1; 
    end
elseif ds == 2
    last_frame = 249; 
    K = load('datasets/parking/K.txt');
    ground_truth = load('datasets/parking/poses.txt');
    ground_truth = ground_truth(:, [end-8 end]);
    % Load bootstrap images. 
    bootstrap_frames = p('bootstrap_frames'); 
    img0 = rgb2gray(imread(['datasets/parking/' ...
        sprintf('/images/img_%05d.png',bootstrap_frames(1))]));
    img1 = rgb2gray(imread(['datasets/parking/' ...
        sprintf('/images/img_%05d.png',bootstrap_frames(2))]));
    imgs_bootstrap = [img0; img1]; 
    % Load continous operation images. 
    imgs_contop = uint8(zeros(size(img0,1), size(img0,2), ...
                        last_frame-bootstrap_frames(2))); 
    k = 1; 
    for i = (bootstrap_frames(2)+1):last_frame    
        img = im2uint8(rgb2gray(imread(['datasets/parking/' ...
            sprintf('/images/img_%05d.png',i)])));
        imgs_contop(:,:,k) = img; 
        k = k + 1; 
    end
    % Adapt ground truth to initialization. 
    ground_truth = ground_truth(bootstrap_frames(2)+1:last_frame, :);
elseif ds == 3
    last_frame = 331; 
    K = load('datasets/eth_april/K.txt');
    ground_truth = load('datasets/eth_april/poses.txt');
    % Load bootstrap images. 
    bootstrap_frames = p('bootstrap_frames'); 
    img0 = imread(['datasets/eth_april/' ...
        sprintf('/frames/%d.png',bootstrap_frames(1))]);
    img1 = imread(['datasets/eth_april/' ...
        sprintf('/frames/%d.png',bootstrap_frames(2))]);
    imgs_bootstrap = [img0; img1]; 
    % Load continous operation images. 
    imgs_contop = uint8(zeros(size(img0,1), size(img0,2), ...
                        last_frame-bootstrap_frames(2))); 
    k = 1; 
    for i = (bootstrap_frames(2)+1):last_frame    
        img = im2uint8(imread(['datasets/eth_april/' ...
            sprintf('/frames/%d.png',i)]));
        imgs_contop(:,:,k) = img; 
        k = k + 1; 
    end
    % Adapt ground truth to initialization. 
    ground_truth = ground_truth(bootstrap_frames(2)+1:last_frame, :);    
elseif ds == 4
    last_frame = 900; 
    K = load('datasets/eth_long/K.txt');
    % Load bootstrap images. 
    bootstrap_frames = p('bootstrap_frames'); 
    img0 = imread(['datasets/eth_long/' ...
        sprintf('/frames/%d.png',bootstrap_frames(1))]);
    img1 = imread(['datasets/eth_long/' ...
        sprintf('/frames/%d.png',bootstrap_frames(2))]);
    imgs_bootstrap = [img0; img1]; 
    % Load continous operation images. 
    imgs_contop = uint8(zeros(size(img0,1), size(img0,2), ...
                        last_frame-bootstrap_frames(2))); 
    k = 1; 
    for i = (bootstrap_frames(2)+1):last_frame    
        img = im2uint8(imread(['datasets/eth_long/' ...
            sprintf('/frames/%d.png',i)]));
        imgs_contop(:,:,k) = img; 
        k = k + 1; 
    end  
    
else
    assert(false);
end

K_matlab = [K(1,1),0,0;0,K(2,2),0;K(1,3),K(2,3),1]; 
K_matlab = cameraParameters('IntrinsicMatrix', K_matlab);

%% Bootstrap Initialization.
disp("Starting bootstrapping initialization ..."); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Bootstrap Initialization %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[P, Pdb] = harrisMatching(img1, img0, ...
           p('init_num_kps'),p('harris_r'),p('harris_kappa'),...
           p('harris_r_sup'),p('harris_r_desc'),p('match_lambda'));
fprintf('... number of matches: %d\n', size(P,2)); 
 
% Estimate the F by ransac, extract the correct transformation as well 
% as triangulated point cloud. 
[R_CW, t3_CW, X, P] = estimateTrafoFund(Pdb, P, ...
                      K, p('fund_num_iter'), p('fund_max_error'));
                  
% Post Processing. 
P_cand       = zeros(2,0);
P_cand_orig  = zeros(2,0); 
T_cand_orig  = zeros(16,0); 
counter      = zeros(size(P,2),1); 
counter_cand = zeros(0,1);
[P,P_cand,P_cand_orig,T_cand_orig,X,counter,counter_cand] = ...
    postProcessing(P, P_cand, P_cand_orig, T_cand_orig, X, ...
    counter, counter_cand, p('counter_max'), p('counter_cand_max'));

% Assign initial state. 
state = struct; 
state.T            = inv([R_CW t3_CW; [0,0,0,1]]); 
state.P            = P;
state.P_cand       = P_cand;   
state.P_cand_orig  = P_cand_orig; 
state.T_cand_orig  = T_cand_orig; 
state.counter      = counter;
state.counter_cand = counter_cand; 
state.X            = X;
state.last_reinit  = 0; 
trajectory = [state];  %#ok<NBRAK>

% Plotting. 
%figure
%plotPointCloud(X, P, img1); 

disp("Initial transformation: "); 
disp([R_CW t3_CW]); 
fprintf('Initial number of matches: %d\n', size(P,2)); 

%% Continuous operation.
figure(2); 
for i = 2:size(imgs_contop,3)
    fprintf('\nProcessing frame %d\n=====================\n', i);
    img_prev = imgs_contop(:,:,i-1); 
    img = imgs_contop(:,:,i); 
    
    % Get last state information. 
    state_prev = trajectory(end); 
    T_prev           = state_prev.T; 
    P_prev           = state_prev.P;
    P_cand_prev      = state_prev.P_cand; 
    P_cand_orig_prev = state_prev.P_cand_orig; 
    T_cand_orig_prev = state_prev.T_cand_orig; 
    counter          = state_prev.counter; 
    counter_cand     = state_prev.counter_cand; 
    X_prev           = state_prev.X; 
    last_reinit_prev = state.last_reinit; 
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% KLT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Track keypoints using Matlab KLT algorithm. 
    disp("KL Tracking ...");   
    point_tracker = vision.PointTracker(...
        'MaxBidirectionalError', p('klt_max_bierror'));
    initialize(point_tracker, P_prev', img_prev);
    [points,validity] = point_tracker(img);
    counter(~validity) = inf; 
    P = points'; 
    fprintf('... number of tracked keypoints: %d\n', nnz(validity));
    % Track candidates using Matlab KLT algorithm. 
    P_cand = P_cand_prev; 
    P_cand_orig = P_cand_orig_prev; 
    T_cand_orig = T_cand_orig_prev; 
    if size(P_cand_prev,2) > 0
        point_tracker_cand = vision.PointTracker(...
        'MaxBidirectionalError', p('klt_max_bierror'));
        initialize(point_tracker_cand, P_cand_prev', img_prev);
        [points,validity] = point_tracker_cand(img);    % Bugfix
        counter_cand(~validity) = inf; 
        P_cand = points'; 
        fprintf('... number of tracked candidates: %d\n', nnz(validity));
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% P3P %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [T,counter] = ransacLocalization(P, X_prev, counter, K, ...
                  p('p3p_min_num'), p('p3p_num_iter'), p('p3p_max_error'));
                
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% Re-Initialization %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    do_reinit = false; 
    if sum(counter == 0) < p('reinit_min_kps')
        do_reinit = true; 
        fprintf('Number of keypoints below threshold, reinitializing ...\n');
    elseif last_reinit_prev > p('reinit_counter') 
        do_reinit = true; 
        fprintf('ReInit counter large, reinitializing ...\n');
    end
    if do_reinit
        % Feature matching using Harris corner detectionn 
        [P, Pdb] = harrisMatching(img, img_prev, ...
                   p('init_num_kps'),p('harris_r'),p('harris_kappa'),...
                   p('harris_r_sup'),p('harris_r_desc'),p('match_lambda'));
        fprintf('... number of matches: %d\n', size(P,2)); 

        % Estimate the F by ransac, extract the correct transformation 
        % as well as triangulated point cloud. 
        [R_CW, t3_CW, X, P] = estimateTrafoFund(Pdb, P, ...
                              K, p('fund_num_iter'), p('fund_max_error'));
        T = T_prev*inv([R_CW t3_CW; [0,0,0,1]]);
        
        % Reset candidates and counters. 
        P_cand       = zeros(2,0);
        P_cand_orig  = zeros(2,0); 
        T_cand_orig  = zeros(16,0); 
        counter      = zeros(size(P,2),1); 
        counter_cand = zeros(0,1);
        
        % Look for new candidates. 
        P_cand_new = selectKeypoints(...
                     harris(img, p('harris_r'), p('harris_kappa')), ...
                     p('cont_num_kps'), p('harris_r_sup'));
        P_cand_new = flipud(P_cand_new); 
        P_current  = [P(:,counter == 0) P_cand(:,counter_cand == 0)];
        P_cand_new = P_cand_new(:, ...
            min(pdist2(P_cand_new',P_current'),[],2) > p('search_min_dis'));
        P_cand_orig_new = P_cand_new; 
        T_cand_orig_new = repmat(T(:), 1, size(P_cand_new,2));
        fprintf('... number of new candidates: %d\n', size(P_cand_new,2)); 

        % Post Processing. 
        [P,P_cand,P_cand_orig,T_cand_orig,X,counter,counter_cand] = ...
            postProcessing(P, P_cand, P_cand_orig, T_cand_orig, X, ...
            counter, counter_cand, p('counter_max'), p('counter_cand_max'));
        fprintf('... number of valid correspondences: %d\n', size(P,2));
        
        % Renew state and add to trajectory.
        state = struct; 
        state.T            = T; 
        state.P            = P;
        state.P_cand       = [P_cand P_cand_new];  
        state.P_cand_orig  = [P_cand_orig P_cand_orig_new]; 
        state.T_cand_orig  = [T_cand_orig T_cand_orig_new]; 
        state.counter      = counter;
        state.counter_cand = [counter_cand; zeros(size(P_cand_new,2),1)]; 
        state.X            = T_prev*X;
        state.last_reinit  = 0; 
        trajectory = [trajectory; state];   %#ok<AGROW>
        
        % Plotting. 
        plotOverall(img, trajectory);
        %plotKPs(P, img); 
        %plotMatches(P, Pdb, img, img);

        fprintf('Position: x=%f, y=%f, z=%f\n', ...
                state.T(1,4),state.T(2,4),state.T(3,4));
        continue; 
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% Candidate Selection %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    P_new = [];
    X_new = [];
    if (~isempty(counter_cand))
        for k=1:size(counter_cand,1)
           if(counter_cand(k)<50&&counter_cand(k)>p('select_min_counter'))
               % Only take candidates from last ten frames.
               
               % Tringulate 3D point.
                 T_WC_cand_orig_loop = reshape(T_cand_orig(:,k),[4,4]);
                 T_CW_cand_orig_loop = inv(T_WC_cand_orig_loop);
                 M1_loop = K*T_CW_cand_orig_loop(1:3,:);
                 T_CW = inv(T);
                 M2_loop = K*T_CW(1:3,:);
                 p1_loop = [P_cand_orig(:,k);1];
                 p2_loop = [P_cand(:,k);1];
                 LM_triang = linearTriangulation(p1_loop,p2_loop,M1_loop,M2_loop);
                 LM_triang = T_CW_cand_orig_loop*LM_triang;
               % Do Sanity Check (in front of camera, reproj error
               % small)and add landmarks with keypoint location in current
               % image.
               if(LM_triang(3)>0)
                   P_new = [P_new,P_cand(:,k)];
                   X_new = [X_new,T_WC_cand_orig_loop*LM_triang];
                   % Also remove it from candidates.
                   counter_cand(k) = inf;
                   
               end
               
           end
        end
        
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% New Candidates Search %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    P_cand_new = selectKeypoints(...
                 harris(img, p('harris_r'), p('harris_kappa')), ...
                 p('cont_num_kps'), p('harris_r_sup'));
    P_cand_new = flipud(P_cand_new); 
    P_current  = [P(:,counter == 0) P_new P_cand(:,counter_cand == 0)];
    P_cand_new = P_cand_new(:, ...
        min(pdist2(P_cand_new',P_current'),[],2) > p('search_min_dis'));
    P_cand_orig_new = P_cand_new; 
    T_cand_orig_new = repmat(T(:), 1, size(P_cand_new,2));
    fprintf('... number of new candidates: %d\n', size(P_cand_new,2));

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% Post-Processing %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [P,P_cand,P_cand_orig,T_cand_orig,X,counter,counter_cand] = ...
        postProcessing(P, P_cand, P_cand_orig, T_cand_orig, X_prev, ...
        counter, counter_cand, p('counter_max'), p('counter_cand_max'));
    last_reinit = last_reinit_prev + 1; 
    fprintf('... number of valid correspondences: %d\n', size(P,2));

    % Renew state and add to trajectory.
    state              = struct; 
    state.T            = T;  
    state.P            = [P P_new]; 
    state.P_cand       = [P_cand P_cand_new];
	state.P_cand_orig  = [P_cand_orig P_cand_orig_new]; 
    state.T_cand_orig  = [T_cand_orig T_cand_orig_new]; 
    state.counter      = [counter; zeros(size(P_new,2),1)]; 
    state.counter_cand = [counter_cand; zeros(size(P_cand_new,2),1)]; 
    state.X            = [X X_new]; 
    state.last_reinit  = last_reinit; 
    trajectory = [trajectory; state]; %#ok<AGROW>
     
	% Plotting. 
    plotOverall(img, trajectory);
    %plotKPs(P, img); 
    %plotMatches(P, Pdb, img, img);
    
    fprintf('Position: x=%f, y=%f, z=%f\n', ...
            state.T(1,4),state.T(2,4),state.T(3,4));
    pause(0.01);
end

%% Post Bundle-Adjustment.
if isnan(ground_truth)
    disp("No groud_truth available !");
    figure(3)
    plotTrajectory(trajectory); 
else
    disp("Compare trajectory to ground_truth ..."); 
    num_points = size(trajectory,1); 
    % Determine groundtruth and trajectory positions. 
    p_W_GT = [ground_truth(1:num_points, :)'; zeros(1,num_points)]; 
    p_W_E  = zeros(3,num_points); 
    for i = 1:num_points
        p_W_E(:,i) = [trajectory(i).T(1,4); trajectory(i).T(3,4); 0.0];
    end
    % Align groundtruth and estimate to resolve scale and rotational errors. 
    p_W_E_aligned = alignEstimateToGroundTruth(p_W_GT, p_W_E);
    % Plot groundtruth vs aligned trajectory. 
    figure(3)
    plotTrajectoryGT(p_W_E, p_W_E_aligned, p_W_GT); 
end