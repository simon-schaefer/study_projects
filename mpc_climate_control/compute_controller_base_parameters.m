function param = compute_controller_base_parameters
    % load truck parameters
    load('system/parameters_truck');
    
    % (2) discretization
    Ts = 60;
    
    Ac = zeros(3); 
    Ac(1,1) = -1/truck.m1*(truck.a12+truck.a1o); 
    Ac(1,2) = truck.a12/truck.m1; 
    Ac(1,3) = 0.0; 
    Ac(2,1) = truck.a12/truck.m2; 
    Ac(2,2) = -1/truck.m2*(truck.a12+truck.a23+truck.a2o); 
    Ac(2,3) = truck.a23/truck.m2;
    Ac(3,1) = 0; 
    Ac(3,2) = truck.a23/truck.m3; 
    Ac(3,3) = -1/truck.m3*(truck.a23+truck.a3o); 
    A = expm(Ac*Ts);  %eye(3) - Ts*Ac
    
    Bc = zeros(3,2); 
    Bc(1,1) = 1/truck.m1; 
    Bc(2,2) = 1/truck.m2; 
    B = inv(Ac)*(A-eye(3))*Bc; %Ts*Bc; %asdf warum?
    
    Bcd = zeros(3,3); 
    Bcd(1,1) = 1/truck.m1; 
    Bcd(2,2) = 1/truck.m2; 
    Bcd(3,3) = 1/truck.m3; 
    Bd = inv(Ac)*(A-eye(3))*Bcd;
    d = [truck.a1o;truck.a2o;truck.a3o]*truck.To + truck.w;
    param.Bd = Bd;
    
    % (3) set point computation. 
    T_sp = zeros(3,1); 
    T_sp(1) = -20; 
    T_sp(2) = 0.25; 
    x = -inv([Bc,Ac(:,3)])*(Ac(:,1:2)*T_sp(1:2) + Bcd*d); %asdf
    T_sp(3) = x(3);
    p_sp = x(1:2); 
    
    % (4) system constraints
    Pcons = truck.InputConstraints;
    Tcons = truck.StateConstraints;
    
    % (4) constraints for delta formulation
    Ucons = [Pcons(1,:)-p_sp(1); Pcons(2,:)-p_sp(2)]; 
    Xcons = [Tcons(1,:)-T_sp(1);Tcons(2,:)-T_sp(2);Tcons(3,:)-T_sp(3)];  
    
    % (20) Augmented system (constant disturbance). 
    Aaug = [A Bd; zeros(3) eye(3)]; 
    Baug = [B;zeros(3,2)]; 
    Caug = [eye(3) zeros(3)];
    
    Daug = zeros(3,2); 
    
    % cost parameters. 
    Q = diag([8000,24000,0]); %state weight. 
    R = 0.1*diag([1,1]); %input weight. 
    L = (place(Aaug',Caug',[0.05,-0.05,0.04,-0.04,0.03,-0.03]))'; %observer weight.  
    eig(Aaug - L*Caug)
    % put everything together
    param.Ac = Ac;
    param.Bc = Bc;
    param.A = A;
    param.B = B;
    param.Aaug = Aaug;
    param.Baug = Baug;
    param.Caug = Caug;
    param.Daug = Daug;
    param.Q = Q;
    param.R = R; 
    param.L = L;
    param.T_sp = T_sp;
    param.p_sp = p_sp;
    param.Ucons = Ucons;
    param.Xcons = Xcons;
    param.Tcons = Tcons;
    param.Pcons = Pcons;
    param.d = d;
end

