function plotTrajectoryGT(p_W_E, p_W_E_algined, p_W_GT)
% Plot aligned trajectory and ground truth trajectory. 
% @param[in]    p_W_E           estimated trajectory (x,z), [2,N]. 
% @param[in]    p_W_E_aligned   aligned estimated trajectory (x,z), [2,N]. 
% @param[in]    p_W_GT          groundtruth trajectory (x,z), [2,N]. 
hold on; 
plot(p_W_E_algined(1,:), p_W_E_algined(2,:)); 
plot(p_W_GT(1,:), p_W_GT(2,:)); 
hold off; 
legend('Trajectory aligned', 'Groundtruth'); 
xlabel('X'); 
ylabel('Z'); 
axis equal; 
end