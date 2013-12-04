
function statePrime =  armODE(t,state, params, control)
%Control is a 3x1 optional input of torques as a function of time (for now)
statePrime = zeros(6,1);
%Position derivatives are velocities
statePrime(1) = state(4);
statePrime(2) = state(5);
statePrime(3) = state(6);

% %Get feedforward control
% tau = Tau(t, params);
%Try zero torque:
tau = zeros(3,1);
%Get EOM
B = inertiaMatrix(state, params);
BInv = inertiaMatrixInv(state, params);
C = coriolisMatrix(state, params);
G = gravityVector(state, params);

%Pull out friction terms
Fs = [params.muS1; params.muS2; params.muS3];
Fv = [params.muD1; params.muD2; params.muD3];

qdot = [state(4); state(5); state(6)];
signQDot = [sign(state(4)); sign(state(5)); sign(state(6))];

% if nargin == 3
%     %Calculate accelerations
%     %B*acc + C*qdot + Fv*qdot + Fs*sgn(qdot) + G = Tau - J'ExternalForces
%     %acc = B\(tau - C*[state(4); state(5); state(6)] - G);
%     %Ignore external forces for now, include friction terms
%     acc = B\(tau - C*qdot - Fv*qdot - Fs*sign(qdot) - G);
% else
%     B*acc + C*qdot + Fv*qdot + Fs*sgn(qdot) + G = Tau - J'ExternalForces
%     acc = B\(control(t) - C*qdot - G);
    % Add in friction
%     acc = B\(control(t) - C*qdot - G - Fv*qdot - Fs*sign(qdot));
    acc = BInv*(control(t) - C*qdot - G - Fv.*qdot - Fs.*signQDot);
% end
%Velocity derivatives are accelerations
statePrime(4) = acc(1);
statePrime(5) = acc(2);
statePrime(6) = acc(3);
end

function B = inertiaMatrix(state, params)
    L1 = params.L1; L2 = params.L2; L3 = params.L3; mm2 = params.mm2;
    mm3 = params.mm3; m1 = params.m1; m2 = params.m2; m3 = params.m3;
    I1 = params.I1; I2 = params.I2; I3 = params.I3;
    J1 = params.J14; J2 = params.J11; J3 = params.J8;
    %th1 = state(1);
    th2 = state(2);
    %th3 = state(3);
    B = zeros(3,3);
    B(1,1) = I1 + I2 + I3 + L2^2*(m2/4 + m3 + mm3) + ...
        L1^2*(m1/4+m2+m3+mm2+mm3) + J1 + J2 + J3 + ...
        L1*L2*(m2+2*(m3 + mm3))*cos(th2);
    B(1,2) = I2 + I3 + L2^2*(m2/4 + m3 + mm3) + J2 + J3 + ...
        0.5*L1*L2*(m2 + 2*m3 + 2*mm3)*cos(th2);
    B(2,1) = B(1,2);
    B(1,3) = J3 + I3;
    B(3,1) = B(1,3);
    B(2,3) = B(1,3);
    B(3,2) = B(1,3);
    B(2,2) = I2 + I3 + L2^2*(m2/4+m3+mm3) + J2 + J3;
    B(3,3) = B(1,3);
end

function BInv = inertiaMatrixInv(state, params)
    L1 = params.L1; L2 = params.L2; L3 = params.L3; mm2 = params.mm2;
    mm3 = params.mm3; m1 = params.m1; m2 = params.m2; m3 = params.m3;
    I1 = params.I1; I2 = params.I2; I3 = params.I3;
    J1 = params.J14; J2 = params.J11; J3 = params.J8;
    %th1 = state(1);
    th2 = state(2);
    %th3 = state(3);
    BInv = zeros(3,3);
    
    BInv(1,1) = (4*(4*I2 + L2^2 * (m2 + 4*m3 + 4*mm3) + 4*J2)) / (4*I1* ...
        (4*I2 + L2^2*(m2 + 4*m3+4*mm3) + 4*J2) + L1^2*(L2^2 * ...
        (m1*(m2+4*m3+4*mm3) + 2*(m2^2 + 4*(m3 + mm3)*(m3 + 2*mm2 + mm3) + ...
        2*m2*(3*m3 + mm2 + 3*mm3))) + 4*(m1 + 4*(m2 + m3 + mm2 + mm3))*J2 ) +...
        4*(L2^2*(m2 + 4*m3 + 4*mm3) + 4*J2)*J1 + ...
        4*I2*(L1^2*(m1+4*(m2 + m3 + mm2 + mm3)) + 4*J1) - ...
        2*L1^2*L2^2*(m2 + 2*m3 + 2*mm3)^2*cos(th2));
    BInv(2,1) = (-4*(4*I2 + L2^2*(m2 + 4*(m3 + mm3)) + 4*J2) - ...
        8*L1*L2*(m2 + 2*(m3 + mm3))*cos(th2)) / ...
        (4*I1*(4*I2 + L2^2*(m2 + 4*(m3 + mm3)) + 4*J2) + ...
        L1^2*(L2^2*(m1*(m2 + 4*(m3 + mm3)) + ...
        2*(m2^2  + 4*(m3 + mm3)*(m3 + 2*mm2 + mm3) + ...
        2*m2*(3*m3 + mm2 + 3*mm3))) + ...
        4*(m1 + 4*(m2 + m3 + mm2 + mm3))*J2) + ...
        4*(L2^2*(m2 + 4*(m3 + mm3)) + 4*J2)*J1 + ...
        4*I2*(L1^2*(m1 + 4*(m2 + m3 + mm2 + mm3)) + 4*J1) - ...
        2*L1^2*L2^2*(m2 + 2*(m3 + mm3))^2*cos(th2));
    BInv(3,1) = (8*L1*L2*(m2 + 2*(m3 + mm3))*cos(th2)) / ...
        (4*I1*(4*I2 + L2^2*(m2 + 4*(m3 + mm3)) + 4*J2) + ...
        L1^2*(L2^2*(m1*(m2 + 4*(m3 + mm3)) + ...
        2*(m2^2  + 4*(m3 + mm3)*(m3 + 2*mm2 + mm3) + ...
        2*m2*(3*m3 + mm2 + 3*mm3))) + ...
        4*(m1 + 4*(m2 + m3 + mm2 + mm3))*J2) + ...
        4*(L2^2*(m2 + 4*(m3 + mm3)) + 4*J2)*J1 + ...
        4*I2*(L1^2*(m1 + 4*(m2 + m3 + mm2 + mm3)) + 4*J1) - ...
        2*L1^2*L2^2*(m2 + 2*(m3 + mm3))^2*cos(th2));
    BInv(1,2) = BInv(2,1);
    BInv(2,2) = (4*(4*I1 + 4*I2 + L2^2*(m2 + 4*(m3 + mm3)) + ...
        L1^2*(m1 + 4*(m2 + m3 + mm2 + mm3)) + 4*(J2 + J1) + ...
        4*L1*L2*(m2 + 2*(m3 + mm3))*cos(th2))) / ...
        (4*I1*(4*I2 + L2^2*(m2 + 4*(m3 + mm3)) + 4*J2) + ...
        L1^2*(L2^2*(m1*(m2 + 4*(m3 + mm3)) + ...
        2*(m2^2  + 4*(m3 + mm3)*(m3 + 2*mm2 + mm3) + ...
        2*m2*(3*m3 + mm2 + 3*mm3))) + ...
        4*(m1 + 4*(m2 + m3 + mm2 + mm3))*J2) + ...
        4*(L2^2*(m2 + 4*(m3 + mm3)) + 4*J2)*J1 + ...
        4*I2*(L1^2*(m1 + 4*(m2 + m3 + mm2 + mm3)) + 4*J1) - ...
        2*L1^2*L2^2*(m2 + 2*(m3 + mm3))^2*cos(th2));
    BInv(2,3) = (-4*(4*I1 + L1^2*(m1 + 4*(m2 + m3 + mm2 + mm3)) + 4*J1) - ...
		8*L1*L2*(m2 + 2*(m3 + mm3))*cos(th2)) / ...
		(4*I1*(4*I2 + L2^2*(m2 + 4*(m3 + mm3)) + 4*J2) + ...
		L1^2*(L2^2*(m1*(m2 + 4*(m3 + mm3)) + ...
		2*(m2^2  + 4*(m3 + mm3)*(m3 + 2*mm2 + mm3) + ...
		2*m2*(3*m3 + mm2 + 3*mm3))) + ...
		4*(m1 + 4*(m2 + m3 + mm2 + mm3))*J2) + ...
		4*(L2^2*(m2 + 4*(m3 + mm3)) + 4*J2)*J1 + ...
		4*I2*(L1^2*(m1 + 4*(m2 + m3 + mm2 + mm3)) + 4*J1) - ...
		2*L1^2*L2^2*(m2 + 2*(m3 + mm3))^2*cos(th2));
    BInv(1,3) = BInv(3,1);
    BInv(3,2) = BInv(2,3);
    BInv(3,3) = ((4*I1 + L1^2*(m1 + 4*(m2 + m3 + mm2 + mm3)) + 4*J1)* ...
		(4*I2 + 4*I3 + L2^2*(m2 + 4*(m3 + mm3)) + 4*(J2 + J3)) - ...
		4*L1^2*L2^2*(m2 + 2*(m3 + mm3))^2*cos(th2)^2 ) / ...
		((I3 + J3)*((4*I2 + L2^2*(m2 + 4*(m3 + mm3)) + 4*J2)* ... 
		(4*I1 + L1^2*(m1 + 4*(m2 + m3 + mm2 + mm3)) + 4*J1) - ...
		4*L1^2*L2^2*(m2 + 2*(m3 + mm3))^2*cos(th2)^2 ));
end

function C = coriolisMatrix(state, params)
    L1 = params.L1; L2 = params.L2; L3 = params.L3; mm2 = params.mm2;
    mm3 = params.mm3; m1 = params.m1; m2 = params.m2; m3 = params.m3;
    I1 = params.I1; I2 = params.I2; I3 = params.I3;
    J1 = params.J14; J2 = params.J11; J3 = params.J8;
    
    th1 = state(1); th2 = state(2); th3 = state(3);
    th1dot = state(4); th2dot = state(5); th3dot = state(6);
    
    C = zeros(3,3);
    
    C(1,1) = -L1*L2*(m2+2*m3+2*mm3)*sin(th2)*th2dot;
    C(2,1) =  L1*L2/4*(m2+2*m3+2*mm3)*sin(th2)*(2*th1dot - th2dot);
    C(1,2) = -L1*L2/2*(m2+2*m3+2*mm3)*sin(th2)*th2dot;
    C(2,2) =  L1*L2/4*(m2+2*m3+2*mm3)*sin(th2)*th1dot;

end

function G = gravityVector(state, params)
    L1 = params.L1; L2 = params.L2; L3 = params.L3; mm2 = params.mm2;
    mm3 = params.mm3; m1 = params.m1; m2 = params.m2; m3 = params.m3;
    I1 = params.I1; I2 = params.I2; I3 = params.I3;
    J1 = params.J14; J2 = params.J11; J3 = params.J8;
    
    th1 = state(1); th2 = state(2); th3 = state(3);
    th1dot = state(4); th2dot = state(5); th3dot = state(6);
    
    G = zeros(3,1);
    g = 9.81; %m/s^2
    
    
    G(1) = 1/2*g*(L1*(m1+2*(m2+m3+mm2+mm3))*sin(th1) + ...
        L2*(m2+2*(m3+mm3))*sin(th1+th2));
    G(2) = 1/2*g*L2*(m2+2*(m3+mm3))*sin(th1+th2);
end

function tau = Tau(t, params)
    L1 = params.L1; L2 = params.L2; L3 = params.L3; mm2 = params.mm2;
    mm3 = params.mm3; m1 = params.m1; m2 = params.m2; m3 = params.m3;
    I1 = params.I1; I2 = params.I2; I3 = params.I3;
    J1 = params.J14; J2 = params.J11; J3 = params.J8;
g = 9.81;
theta1 = 0; %fxn1(t);
theta2 = 0; %fxn2(t);
theta3 = 0; % fxn3(t);
theta1dot = 0; % fxnd1(t);
theta2dot = 0; % fxnd2(t);
theta3dot = 0; % fxnd3(t);
theta1ddot = 0; % fxndd1(t);
theta2ddot = 0; % fxndd2(t);
theta3ddot = 0; % fxndd3(t);
tau1 = 0.5*g*(L1*(m1 + 2*(m2 + m3 + mm2 + mm3))*sin(theta1) + ...
    L2*(m2 + 2*(m3 + mm3))*sin(theta1 + theta2)) - ...
    L1*L2*(m2 + 2*(m3 + mm3))*sin(theta2)*theta1dot*theta2dot - ...
    0.5*L1*L2*(m2 + 2*(m3 + mm3))*sin(theta2)*theta2dot^2 + ...
    (I1 + I2 + I3 + L2^2*(m2/4 + m3 + mm3) + L1^2*(m1/4 ...
    + m2 + m3 + mm2 + mm3) + J2 + J1 + J3 + ...
    L1*L2*(m2 + 2*(m3 + mm3))*cos(theta2))*theta1ddot + ...
    (I2 + I3 + L2^2*(m2/4 + m3 + mm3) + J2 + J3 + ... 
    0.5*L1*L2*(m2 + 2*(m3 + mm3))*cos(theta2))*theta2ddot ...
    + (I3 + J3)*theta3ddot;

tau2 = .25*(2*g*L2*(m2 + 2*(m3 + mm3))*sin(theta1+theta2) + ...
    2*L1*L2*(m2 + 2*(m3 + mm3))*sin(theta2)*theta1dot^2 + ...
    (4*I2 + 4*I3 + L2^2*(m2 + 4*(m3 + mm3)) + 4*(J2 + J3) + ...
    2*L1*L2*(m2 + 2*(m3+mm3))*cos(theta2))*theta1ddot + ...
    (4*I2+4*I3+L2^2*(m2+4*(m3+mm3)) + 4*(J2+J3))*theta2ddot + ...
    4*(I3 + J3)*theta3ddot);

tau3 = (J3 + I3)*(theta1ddot+theta2ddot+theta3ddot); 
tau = [tau1; tau2; tau3];
end