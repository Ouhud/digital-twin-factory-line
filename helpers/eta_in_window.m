function [inside, phase, eta] = eta_in_window(belt_speed, part_pitch, cycle_time, window01)
% ETA_IN_WINDOW  Prüft, ob die "Ankunftsphase" in einem 0..1-Fenster liegt.
% Idee: Wie weit "wandert" ein Teil während eines Roboterzyklus relativ zur Teilteilung.
% phase = frac( (belt_speed * cycle_time) / part_pitch )
% inside: phase ∈ [window01(1), window01(2)]
% eta   : Breite des Fensters (als grobe "Wahrscheinlichkeit")
%
% Bsp: eta_in_window(0.30, 0.08, 0.5, [0.25 0.70])

arguments
    belt_speed  (1,1) double {mustBeFinite, mustBeNonnegative}
    part_pitch  (1,1) double {mustBeFinite, mustBePositive}
    cycle_time  (1,1) double {mustBeFinite, mustBeNonnegative}
    window01    (1,2) double {mustBeFinite, mustBeGreaterThanOrEqual(window01,0), mustBeLessThanOrEqual(window01,1)}
end

adv = (belt_speed * cycle_time) / part_pitch;  % relative Fortschritt pro Zyklus
phase = adv - floor(adv);                       % in [0,1)
w0 = min(window01); w1 = max(window01);
inside = (phase >= w0) && (phase <= w1);
eta = max(0, w1 - w0);                          % grob: Fensterausnutzung
end