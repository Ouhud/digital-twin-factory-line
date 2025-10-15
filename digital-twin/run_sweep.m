function run_sweep()
% RUN_SWEEP – Parameter-Sweep über Förderbandgeschwindigkeit
%
% Führt mehrere Simulationen mit unterschiedlichen Belt-Speeds durch
% und speichert die wichtigsten Kennzahlen in einer CSV-Datei.
%
% Autor: Mohamad Hamza Mehmalat
% Datum: 2025-10-15
% -------------------------------------------------------------------------

%% ------------------------------------------------------------------------
% 1. Parameter
% -------------------------------------------------------------------------
belt_speeds = 0.20:0.05:0.50;  % [m/s]
spawn_rate  = 0.60;             % [Teile/s]
Tsim        = 45;               % [s]

%% ------------------------------------------------------------------------
% 2. Setup
% -------------------------------------------------------------------------
root   = fileparts(mfilename('fullpath'));
outDir = fullfile(root, 'out');
if ~exist(outDir, 'dir'), mkdir(outDir); end

ts = char(datetime("now", "Format", "yyyyMMdd_HHmmss"));

res = table('Size',[numel(belt_speeds),6], ...
    'VariableTypes', {'double','double','double','double','double','double'}, ...
    'VariableNames', {'belt_speed','picked','placed','success','throughputPM','outputRatePS'});

%% ------------------------------------------------------------------------
% 3. Simulationen
% -------------------------------------------------------------------------
for i = 1:numel(belt_speeds)
    b = belt_speeds(i);
    fprintf('\n🔹 SWEEP: belt_speed = %.2f m/s\n', b);

    % --- Optionen vorbereiten ---
    opts = struct( ...
        'Tsim', Tsim, ...
        'dt', 0.05, ...
        'belt_speed', b, ...
        'spawn_rate', spawn_rate, ...
        'machine_Tproc', [5.0 6.0], ...
        'showPlots', false, ...
        'show3D', false, ...
        'outDir', outDir ...
    );

    % --- Sicherstellen, dass alle Felder vorhanden sind ---
    if ~isfield(opts, 'dt'), opts.dt = 0.05; end
    if ~isfield(opts, 'Tsim'), opts.Tsim = 90; end
    if ~isfield(opts, 'spawn_rate'), opts.spawn_rate = spawn_rate; end
    if ~isfield(opts, 'belt_speed'), opts.belt_speed = b; end
    if ~isfield(opts, 'machine_Tproc'), opts.machine_Tproc = [5.0 6.0]; end
    if ~isfield(opts, 'outDir'), opts.outDir = outDir; end

    % --- Simulation starten ---
    try
        S = simulate_factory_line_3R2M(opts);
        K = S.kpi;
        res(i,:) = {b, K.picked, K.placed, K.successRate, K.throughputPM, K.outputRatePS};
    catch E
        warning(E.identifier, 'Sweep-Fehler: %s', E.message);
        res(i,:) = {b, NaN, NaN, NaN, NaN, NaN};
    end
end

%% ------------------------------------------------------------------------
% 4. Export
% -------------------------------------------------------------------------
csvFile = fullfile(outDir, ['sweep_results_' ts '.csv']);
writetable(res, csvFile);
fprintf('\n✅ run_sweep OK -> %s\n', csvFile);
end