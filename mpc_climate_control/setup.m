function [T0_1, T0_2, scen1, scen2, scen3] = setup()
    clc; clear all; close all; %#ok<CLALL>
    addpath(genpath(cd));
    load('system/parameters_scenarios.mat');

    % Load system. 
    system_params = compute_controller_base_parameters;

    % Initial conditions. 
    T0_1 = system_params.T_sp + [3;1;0]; 
    T0_2 = system_params.T_sp + [-1.0;-0.1;-4.5]; 
end
