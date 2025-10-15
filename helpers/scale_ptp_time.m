function T = scale_ptp_time(q0, q1, speed_scale, Tmin, Tmax)
% SCALE_PTP_TIME  Grobe PTP-Zeitabschätzung mit Skalierung und Clamping.
%   T = scale_ptp_time(q0, q1, speed_scale, Tmin, Tmax)
% q0,q1: Gelenkwinkelvektoren (rad)
% speed_scale: >0, je größer desto schneller (kürzere Zeit)
% Tmin/Tmax: Grenzwerte für die resultierende Zeit

arguments
    q0 double
    q1 double
    speed_scale (1,1) double {mustBePositive}
    Tmin (1,1) double {mustBeNonnegative} = 0
    Tmax (1,1) double {mustBePositive} = inf
end

dq = q1 - q0;
d = norm(dq, 2);                % „Weglänge"
raw = d / max(speed_scale, 1e-9);
if ~isfinite(raw), raw = Tmax; end
T = min(max(raw, Tmin), Tmax);
end