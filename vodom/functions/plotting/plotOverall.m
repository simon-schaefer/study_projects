function plotOverall(img, trajectory)
clf('reset');
n = size(trajectory, 1); 
if n < 2
    return
end
% PLOT: Tracked Features - Add pixel markers for tracked 
% and newly added features. 
subplot(2,3,[1,2,3]);
imshow(img); 
hold on;
P = trajectory(end).P; 
kps = flipud(P); 
plot((kps(2, :))', (kps(1, :))', 'rx');
P_cand = trajectory(end).P_cand; 
kps = flipud(P_cand); 
plot((kps(2, :))', (kps(1, :))', 'go'); 
hold off; 
legend('valid', 'candidates'); 

% PLOT: Tracked Keypoints
subplot(2,3,4);
num_valid = zeros(1,n); 
num_candi = zeros(1,n); 
num_hist_kps = 50; 
for i = 1:n
    num_valid(i) = size(trajectory(i).P, 2); 
    num_candi(i) = size(trajectory(i).P_cand, 2); 
end
if n > num_hist_kps
    plot(n-num_hist_kps:n, num_valid(end-num_hist_kps:end)); 
    hold on; 
    plot(n-num_hist_kps:n, num_candi(end-num_hist_kps:end)); 
else
    plot(1:n, num_valid);
    hold on; 
    plot(1:n, num_candi); 
end
xlabel('Frame index');
ylabel('# tracked keypoints');
axis([n-num_hist_kps n 0 400]); 
legend('valid', 'candidates'); 
title('# prev. tracked keypoints')

% PLOT: Trajectory, Camera and landmarks 
subplot(2,3,[5,6]);

positions = [];
for i=1:n
    positions = [positions;trajectory(i).T(1:3,4)'];
end
% NOTE: We are interested in X-Z (topview).
coord1 = 1; coord2 = 3; 
h(1)=plot(positions(:,coord1),positions(:,coord2),'-', 'Linewidth', 2); 
hold on; 
X_draw = trajectory(end).X; 
if size(X_draw,2) > 0
    h(2)=plot(X_draw(coord1,:)',X_draw(coord2,:)','*'); 
    uistack(h(1),'top'); 
end
hold off; 
xlabel('X^W_1 = X');
ylabel('X^W_2 = Z');
axis equal; 
end

% NEW (3D plot with trajectory, landmarks and camera).
% X_curr = trajectory(end).Xin;
% 
% positions = [];
% T_WC = [];
% pos = [];
% for i=1:n
%    T_CW = trajectory(i).T;
%    T_WC = inv(T_CW);
%    pos = T_WC*[0;0;0;1];
%    positions = [positions;(pos(1:3))']; 
% end
% 
% scatter3((X_curr(1,:))',(X_curr(2,:))',(X_curr(3,:))','rx');
% hold on;
% cam = plotCamera('Location',(pos(1:3))','Orientation',T_WC(1:3,1:3),'Opacity',0,'Color','g','Size',0.5);
% hold on;
% plot3(positions(:,1),positions(:,2),positions(:,3),'b')
% hold on;
% set(gca,'CameraUpVector',[0 -1 0]); % Make the y-axis point down.
% xlabel('X');
% ylabel('Y');
% zlabel('Z');    
% axis ([-10,10,-10,10,-10,10]);
% axis manual;
% title('Full Trajectory')

% Reset window position and size. 
%set(gcf,'units','points','position',[100,100,600,400])
