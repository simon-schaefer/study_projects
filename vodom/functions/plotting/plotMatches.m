function plotMatches(kps1, kps0, img1, img0)
% Plot features matches in between two images. 
% @param[in]    kps1    matched query keypoints [2,L]. 
% @param[in]    kps0    matched database keypoints [2,L]. 
% @param[in]    img1 	query image. 
% @param[in]    img0    database image. 
kps0 = flipud(kps0);
kps1 = flipud(kps1);
showMatchedFeatures(img0, img1, fliplr(kps0'), fliplr(kps1'));
end

