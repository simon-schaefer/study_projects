function plotTrajectory(trajectory)
num_points = size(trajectory,1); 
p_W_E  = zeros(3,num_points); 
for i = 1:num_points
    p_W_E(:,i) = [trajectory(i).T(1,4); trajectory(i).T(3,4); 0.0];
end
p_W_E(:,i) = [trajectory(i).T(1,4); trajectory(i).T(3,4); 0.0];
landmarks = [];
for i = 1:num_points
    for j = 1:size(trajectory(i).X,2)
        x = trajectory(i).X(:,j); 
        if abs(x(3)) < 1e3 && abs(x(1)) < 1e3
            landmarks = [landmarks trajectory(i).X(:,j)];
        end
    end
end
h(1)=plot(p_W_E(1,:), p_W_E(2,:), 'b-', 'LineWidth', 3); 
hold on; 
h(2)=plot(landmarks(1,:), landmarks(3,:), 'r*');
uistack(h(1),'top'); 
legend('Landmarks', 'Trajectory'); 
xlabel('X'); 
ylabel('Z'); 
axis equal; 
end