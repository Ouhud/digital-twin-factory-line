function C = config(varargin)
% CONFIG – zentrale Parameter für den Digital Twin
% Beispiel:
%   C = config('Tsim', 90, 'belt_speed', 0.4);
%
% Alle Parameter sind überschreibbar (Name/Value).

p = inputParser;

% Simulationszeit/-schritt
addParameter(p,'Tsim', 60);          % s
addParameter(p,'dt', 0.05);          % s
addParameter(p,'seed', 42);

% Materialquelle & Förderband
addParameter(p,'spawn_rate', 0.5);   % Teile pro Sekunde
addParameter(p,'belt_speed', 0.30);  % m/s
addParameter(p,'belt_len', 2.0);     % m
addParameter(p,'stations_pos', [0.8, 1.4]);  % Positionen der Maschinen (m entlang Band)

% Maschinen-Prozesszeiten
addParameter(p,'machine_Tproc', [4.0, 5.5]); % s (2 Maschinen)

% Roboter-Aktionszeiten (einfaches Timing-Modell)
addParameter(p,'rob_move_time', 0.8);   % s pro Bewegung (Pick/Place Weg)
addParameter(p,'rob_action_time', 0.3); % s für Pick/Place Aktion

% Sichtbarkeit
addParameter(p,'showPlots', true);
addParameter(p,'show3D', false);

parse(p, varargin{:});
C = p.Results;

rng(C.seed);
end