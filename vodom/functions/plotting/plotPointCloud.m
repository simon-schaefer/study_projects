function plotPointCloud(cloud, kps, img)
% Plot triangulated feature point cloud. 
% @param[in]    cloud       triangulated feature world points [3,L].
subplot(2,1,1); 
plotKPs(kps, img); 
subplot(2,1,2); 
scatter3((cloud(1,:))',(cloud(2,:))',(cloud(3,:))','rx');
hold on;
set(gca,'CameraUpVector',[0 -1 0]); % Make the y-axis point down.
xlabel('X');
ylabel('Y');
zlabel('Z');
axis equal; 
view(2,-18); 
end

