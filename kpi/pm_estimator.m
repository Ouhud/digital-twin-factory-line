function pm = pm_estimator(kpi, varargin)
% PM_ESTIMATOR – einfache Heuristik für einen Health-Score (0..100)
%   pm = pm_estimator(kpi, 'targets', struct('throughputPM',X,'successRate',Y))
%
% Eingabe (kpi): Felder wie von kpi_finalize:
%   successRate, throughputPM, outputRatePS, pickMiss, picked, placed, shipped, availability
%   util_robot(1x3), util_machine(1x2), throughput_ts(:,2)
%
% Ausgabe (pm):
%   pm.health_score   – 0..100
%   pm.metrics        – struct mit berechneten Werten
%   pm.notes          – string-Array mit Hinweisen/Warnungen

% Ziele (optional)
p = inputParser;
addParameter(p, 'targets', struct('throughputPM',10, 'successRate',0.95, 'util_robot',[0.4 0.4 0.4]));
parse(p, varargin{:});
targets = p.Results.targets;

notes = strings(0,1);

% Basiswerte
sr   = safeget(kpi,'successRate', 0);
tpm  = safeget(kpi,'throughputPM', 0);
utilR= safeget(kpi,'util_robot', [0 0 0]);
utilM= safeget(kpi,'util_machine', [0 0]);

% Komponenten-Scores (0..100)
score_sr  = clamp01(sr / max(1e-9, targets.successRate)) * 100;
score_tpm = clamp01(tpm / max(1e-9, targets.throughputPM)) * 100;

% Roboterauslastung: Ziel ~ targets.util_robot (Mittel)
ur_target = mean(targets.util_robot(:));
ur_actual = mean(utilR(:));
score_ur  = 100 - 100*abs(ur_actual - ur_target) / max(1e-9, ur_target); % symmetrisch um Ziel
score_ur  = max(0, min(100, score_ur));

% Maschinen: je höher desto besser (bis 1.0)
um_actual = mean(utilM(:));
score_um  = clamp01(um_actual / 0.85) * 100; % 85% ~ gut ausgelastet

% Gesamtscore (gewichtetes Mittel)
w = [0.4, 0.35, 0.15, 0.10]; % [SR, TPM, UR, UM]
health = w(1)*score_sr + w(2)*score_tpm + w(3)*score_ur + w(4)*score_um;

% Notizen/Warnings
if sr < 0.9,      notes(end+1) = "Warnung: Erfolgsrate < 90%"; end
if tpm < 5,       notes(end+1) = "Hinweis: Niedriger Durchsatz (<5 Teile/min)"; end
if ur_actual < 0.2, notes(end+1) = "Robo-Auslastung sehr niedrig – evtl. Wartezeiten"; end
if um_actual < 0.3, notes(end+1) = "Maschinenauslastung niedrig – Zuführung bottleneck?"; end

pm.health_score = round(health);
pm.metrics = struct( ...
    'successRate', sr, ...
    'throughputPM', tpm, ...
    'outputRatePS', safeget(kpi,'outputRatePS',0), ...
    'util_robot', utilR, ...
    'util_machine', utilM ...
);
pm.notes = notes;

end

% ---------- Helper ----------
function x = safeget(S, f, d)
if isfield(S,f), x = S.(f); else, x = d; end
end
function y = clamp01(x)
y = max(0, min(1, x));
end