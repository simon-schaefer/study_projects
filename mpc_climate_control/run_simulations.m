%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Simulation - Main. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Unconstrained Optimal Control
%% Task 5 - LQR - Scene1 - T01
[T0_1, T0_2, scen1, scen2, scen3] = setup();
[T, ~] = simulate_truck(T0_1, @controller_lqr,scen1);
sgtitle("Task 5 - LQR - Scen1 - T01")
print('outs/task_5_lqr_scen1_to1','-dpng')

% check relation between norm(Tsp-T(30)) and norm(x0)
param = compute_controller_base_parameters;
rel = norm(param.T_sp(1:2)-T(1:2,30))/norm(T0_1(1:2));
if (rel < 0.2)
    disp(['Requirement is fulfilled, as ', num2str(rel), ' is smaller than 0.2'])
    disp('System approaches reference (more than) reasonably fast.')
    disp('Input constraints are met, as it can also be seen in the graphs.')
end
%% First MP Controller
%% Task 7 - LQR simulation - Scenario one - T02
%% Task 7
%% Task 7 - LQR - Scen1 - T02
[T0_1, T0_2, scen1, scen2, scen3] = setup();
[~, ~] = simulate_truck(T0_2, @controller_lqr,scen1);
sgtitle("Task 7 - LQR - Scen1 - T02")
print('outs/task_7_lqr_scen1_to2','-dpng')

%% Task 8 - LQR - Invariant set. 
[A_x, b_x] = compute_X_LQR(); 
%% Task 9 - MPC 1 - Scen1 - T01
[T0_1, T0_2, scen1, scen2, scen3] = setup();
[~, ~] = simulate_truck(T0_1, @controller_mpc_1,scen1);
sgtitle("Task 9 - MPC 1 - Scene 1 - T01")
print('outs/task_9_MPC1_scen1_to1','-dpng')
%% Task 9 - MPC 1 - Scen1 - T02
[T0_1, T0_2, scen1, scen2, scen3] = setup();
[~, ~] = simulate_truck(T0_2, @controller_mpc_1,scen1);
sgtitle("Task 9 - MPC 1 - Scene 1 - T02")
print('outs/task_9_MPC1_scen1_to2','-dpng')
%% Task 12 - MPC 2 - Scen1 - T01
[T0_1, T0_2, scen1, scen2, scen3] = setup();
[~, ~] = simulate_truck(T0_1, @controller_mpc_2,scen1);
sgtitle("Task 12 - MPC 2 - Scene 1 - T01")
print('outs/task_12_MPC2_scen1_to1','-dpng')
%% Task 12 - MPC 2 - Scen1 - T02 (this is for task 16)
[T0_1, T0_2, scen1, scen2, scen3] = setup();
[~, ~] = simulate_truck(T0_2, @controller_mpc_2,scen1);
sgtitle("Task 16 - MPC 2 - Scene 1 - T02")
print('outs/task_16_MPC2_scen1_to2','-dpng')
%% Task 15 - MPC 3 - Scen1 - T01
[T0_1, T0_2, scen1, scen2, scen3] = setup();
[~, ~] = simulate_truck(T0_1, @controller_mpc_3,scen1);
sgtitle("Task 15 - MPC 3 - Scen1 - T01")
print('outs/task_15_MPC3_scen1_to1','-dpng')
%% Task 15 - MPC 3 - Scen1 - T02
[T0_1, T0_2, scen1, scen2, scen3] = setup();
[~, ~] = simulate_truck(T0_2, @controller_mpc_3,scen1);
sgtitle("Task 15 - MPC 3 - Scen1 - T02")
print('outs/task_15_MPC3_scen1_to2','-dpng')
%% Task 17 - MPC 3 - Scen2 - T02
[T0_1, T0_2, scen1, scen2, scen3] = setup();
[~, ~] = simulate_truck(T0_2, @controller_mpc_3,scen2);
sgtitle("Task 17 - MPC 3 - Scen2 - T02")
print('outs/task_17_MPC3_scen2_to2','-dpng')
%% Task 18 - MPC 4 - Scen2 - T02
[T0_1, T0_2, scen1, scen2, scen3] = setup();
[~, ~] = simulate_truck(T0_2, @controller_mpc_4,scen2);
sgtitle("Task 18 - MPC 4 - Scen2 - T02")
print('outs/task_18_MPC4_scen2_to2','-dpng')
%% Task 19 - MPC 3 - Scen1 - T02
[T0_1, T0_2, scen1, scen2, scen3] = setup();
[~, ~] = simulate_truck(T0_2, @controller_mpc_3,scen1);
sgtitle("Task 19 - MPC 3 - Scen1 - T02")
print('outs/task_19_MPC3_scen1_to2','-dpng')
%% Task 19 - MPC 4 - Scene1 - T02
[T0_1, T0_2, scen1, scen2, scen3] = setup();
[~, ~] = simulate_truck(T0_2, @controller_mpc_4,scen1);
sgtitle("Task 19 - MPC 4 - Scen1 - T02")
print('outs/task_19_MPC4_scen1_to2','-dpng')
%% Task 22 - MPC 5 - Scen3 - T01
[T0_1, T0_2, scen1, scen2, scen3] = setup();
[~, ~] = simulate_truck(T0_1, @controller_mpc_5,scen3);
sgtitle("Task 22 - MPC 5 - Scen3 - T01")
print('outs/task_22_MPC5_scen3_to1','-dpng')
%% Task 22 - MPC 5 - Scen3 - T02
[T0_1, T0_2, scen1, scen2, scen3] = setup();
[~, ~] = simulate_truck(T0_1, @controller_mpc_3,scen3);
sgtitle("Task 22 - MPC 3 - Scen3 - T01")
print('outs/task_22_MPC3_scen3_to1','-dpng')
%% Task 23 - MPC 1 - Scen3 - T02 - FORCES
[T0_1, T0_2, scen1, scen2, scen3] = setup();
mex -setup
[~,~] = simulate_truck(T0_2, @controller_mpc_1_forces, scen1);
sgtitle("Task 23 - MPC 1 - Scen1 - T02")
print('outs/task_23_MPC1forces_scen1_to2','-dpng')
%% Task 23 - MPC 1 - Scen3 - T02 - NORMAL
[T0_1, T0_2, scen1, scen2, scen3] = setup();
[~,~,t_sim] = simulate_truck(T0_2, @controller_mpc_1, scen1);
sgtitle("Task 23 - MPC 1 - Scen1 - T02")
print('outs/task_23_MPC1_scen1_to2','-dpng')
