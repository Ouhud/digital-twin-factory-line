function run_sim()
% RUN_SIM – Führt eine Einzelsimulation des Digital Twin aus
%
% Speichert Ergebnisse in:
%   - out/run_<timestamp>/digital_twin_run_<timestamp>.mat
%   - out/twin_summary_<timestamp>.csv
%
% Autor: Hamza Mehmalat
% Datum: 2025-10-14
% -------------------------------------------------------------------------

%% ------------------------------------------------------------------------
% 1. Parameter
% -------------------------------------------------------------------------
Tsim       = 120;     % längere Gesamtlaufzeit [s]
belt_speed = 0.15;    % Förderband langsamer -> realistische Zykluszeit
spawn_rate = 0.8;     % mehr Teile pro Sekunde -> höhere Auslastung
showPlots  = true;    % 2D-Plot aktivieren
show3D     = false;   % 3D-Ansicht deaktivieren

%% ------------------------------------------------------------------------
% 2. Setup & Logging
% -------------------------------------------------------------------------
root = fileparts(mfilename('fullpath'));
outDir = fullfile(root, 'out');
if ~exist(outDir, 'dir'), mkdir(outDir); end

ts = char(datetime("now","Format","yyyyMMdd_HHmmss"));
runDir = fullfile(outDir, ['run_' ts]);
mkdir(runDir);

logTxt = fullfile(runDir, ['run_sim_' ts '.txt']);
[log, closeLog] = logger(logTxt);
log('INFO','RUN_SIM start (%s)', ts);

%% ------------------------------------------------------------------------
% 3. Simulation ausführen
% -------------------------------------------------------------------------
opts = struct('Tsim', Tsim, 'showPlots', showPlots, 'show3D', show3D);

% --- Sicherstellen, dass opts-Felder existieren ---
if ~isfield(opts, 'dt'), opts.dt = 0.05; end
if ~isfield(opts, 'Tsim'), opts.Tsim = 90; end
if ~isfield(opts, 'spawn_rate'), opts.spawn_rate = spawn_rate; end
if ~isfield(opts, 'belt_speed'), opts.belt_speed = belt_speed; end
if ~isfield(opts, 'machine_Tproc'), opts.machine_Tproc = [5.0 6.0]; end
if ~isfield(opts, 'outDir'), opts.outDir = outDir; end

   try
    % 📌 Simulation starten
    S = simulate_factory_line_3R2M( ...
        'Tsim', opts.Tsim, ...
        'dt', opts.dt, ...
        'spawn_rate', opts.spawn_rate, ...
        'belt_speed', opts.belt_speed, ...
        'machine_Tproc', opts.machine_Tproc, ...
        'showPlots', opts.showPlots, ...
        'show3D', opts.show3D, ...
        'outDir', opts.outDir ...
    );

    K = S.kpi;
    log('INFO','Simulation erfolgreich abgeschlossen.');

catch E
    log('ERROR','Simulation fehlgeschlagen: %s', E.message);
    rethrow(E);
end

%% ------------------------------------------------------------------------
% 4. KPI speichern
% -------------------------------------------------------------------------
availability   = K.availability;
successRate    = K.successRate;
throughputPM   = K.throughputPM;
outputRatePS   = K.outputRatePS;

save(fullfile(runDir, ['digital_twin_run_' ts '.mat']), ...
     'K', 'availability', 'successRate', 'throughputPM', 'outputRatePS', '-v7');

export_kpi(K, outDir, 'twin');
log('INFO','MAT-Datei gespeichert.');

%% ------------------------------------------------------------------------
% 5. Ausgabe
% -------------------------------------------------------------------------
closeLog();

fprintf('\n--- Robot Utilization Summary ---\n');
robots = {'R1','R2','R3'};
for i = 1:3
    name = robots{i};
    if isfield(K,[name '_util'])
        fprintf('%s: Utilization = %.1f %% (active %.2fs / idle %.2fs)\n', ...
            name, K.([name '_util']), K.([name '_active']), K.([name '_idle']));
    else
        fprintf('%s: keine Daten verfügbar\n', name);
    end
end

fprintf('---------------------------------\n');
fprintf('Durchsatz: %.2f Teile/min | Erfolgsrate: %.1f %% | Verfügbarkeit: %.1f %%\n', ...
    K.throughputPM, K.successRate * 100, K.availability * 100);
fprintf('---------------------------------\n');

% 🔧 Sichere Abfrage des Simulationszeitraums
if isfield(S, 'config') && isfield(S.config, 'Tsim')
    simTime = S.config.Tsim;
else
    simTime = opts.Tsim;  % Fallback, falls config fehlt
end

fprintf('\n[OK] Simulation abgeschlossen: T=%.1fs, Teile=%d\n', ...
    simTime, K.shipped);
fprintf('---------------------------------\n');
end