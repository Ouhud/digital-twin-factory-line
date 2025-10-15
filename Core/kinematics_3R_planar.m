function [P, joints] = kinematics_3R_planar(theta, L)
% KINEMATICS_3R_PLANAR – Vorwärtstransformation für 3DOF-Planararm
%   theta: [t1 t2 t3] (rad)
%   L    : [l1 l2 l3] (m)
% Rückgabe:
%   P: Endeffektor-Position [x y]
%   joints: [ (0,0); (x1,y1); (x2,y2); (x3,y3) ]

if numel(theta)~=3 || numel(L)~=3
    error('Erwarte theta[1x3] und L[1x3].');
end
t1=theta(1); t2=theta(2); t3=theta(3);
x1 = L(1)*cos(t1);      y1 = L(1)*sin(t1);
x2 = x1 + L(2)*cos(t1+t2); y2 = y1 + L(2)*sin(t1+t2);
x3 = x2 + L(3)*cos(t1+t2+t3); y3 = y2 + L(3)*sin(t1+t2+t3);
P = [x3, y3];
joints = [0 0; x1 y1; x2 y2; x3 y3];
end