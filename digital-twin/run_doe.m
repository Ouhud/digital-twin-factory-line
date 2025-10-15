function run_doe()
% RUN_DOE – Design of Experiments (DoE) für Belt-Speed × Spawn-Rate
%
% Führt Simulationen über ein Parameter-Gitter aus und speichert
% die wichtigsten KPIs (Durchsatz, Erfolgsrate, Picks/Places) als CSV.
%
% Autor: Mohamad Hamza Mehmalat
% Datum: 2025-10-15
% -------------------------------------------------------------------------

%% ------------------------------------------------------------------------
% 1. DOE-Parameter
% -------------------------------------------------------------------------
belt_speeds = [0.20 0.30 0.40];   % [m/s]
spawn_rates = [0.40 0.60 0.80];   % [Teile/s]
Tsim        = 45;                 % Simulationszeit [s]

%% ------------------------------------------------------------------------
% 2. Setup
% -------------------------------------------------------------------------
root   = fileparts(mfilename('fullpath'));
outDir = fullfile(root, 'out');
if ~exist(outDir, 'dir'), mkdir(outDir); end

ts = char(datetime("now", "Format", "yyyyMMdd_HHmmss"));

% Voralloziierung für Performance
numRuns = numel(belt_speeds) * numel(spawn_rates);
res = table('Size',[numRuns,7], ...
    'VariableTypes', {'double','double','double','double','double','double','double'}, ...
    'VariableNames', {'belt_speed','spawn_rate','picked','placed','success','throughputPM','outputRatePS'});

runIdx = 1;

%% ------------------------------------------------------------------------
% 3. Simulationen (Grid)
% -------------------------------------------------------------------------
for i = 1:numel(belt_speeds)
    for j = 1:numel(spawn_rates)
        b = belt_speeds(i);
        s = spawn_rates(j);

        fprintf('\n🔹 DOE: belt = %.2f m/s | spawn = %.2f parts/s\n', b, s);

        % --- Opts-Struktur vorbereiten ---
        opts = struct( ...
            'Tsim', Tsim, ...
            'dt', 0.05, ...
            'belt_speed', b, ...
            'spawn_rate', s, ...
            'machine_Tproc', [5.0 6.0], ...
            'showPlots', false, ...
            'show3D', false, ...
            'outDir', outDir ...
        );

        % --- Sicherstellen, dass alle Felder existieren ---
        if ~isfield(opts,'dt'), opts.dt = 0.05; end
        if ~isfield(opts,'Tsim'), opts.Tsim = 90; end
        if ~isfield(opts,'spawn_rate'), opts.spawn_rate = s; end
        if ~isfield(opts,'belt_speed'), opts.belt_speed = b; end
        if ~isfield(opts,'machine_Tproc'), opts.machine_Tproc = [5.0 6.0]; end
        if ~isfield(opts,'outDir'), opts.outDir = outDir; end

        % --- Simulation starten ---
        try
            S = simulate_factory_line_3R2M(opts);
            K = S.kpi;

            res(runIdx,:) = {b, s, K.picked, K.placed, K.successRate, K.throughputPM, K.outputRatePS};

        catch E
            warning(E.identifier, 'DOE-Fehler: %s', E.message);
            res(runIdx,:) = {b, s, NaN, NaN, NaN, NaN, NaN};
        end

        runIdx = runIdx + 1;
    end
end

%% ------------------------------------------------------------------------
% 4. Export
% -------------------------------------------------------------------------
csvFile = fullfile(outDir, ['doe_results_' ts '.csv']);
writetable(res, csvFile);

fprintf('\n✅ run_doe OK -> %s\n', csvFile);
end