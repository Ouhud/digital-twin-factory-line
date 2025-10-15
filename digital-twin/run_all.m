function run_all()

% RUN_ALL – Master-Orchestrierung für alle Demos/Experimente
% Erstellt das Out-Verzeichnis, führt Simulationen aus und speichert
% Reports (CSV, MAT, PNG).
%
% Autor: Hamza Mehmalat
% Datum: 2025-10-14

% -------------------------------------------------------------------------
% 1. Optionen
% -------------------------------------------------------------------------
QUIET_PLOTS   = true;   % true = keine Fenster (Headless)
MAKE_OVERVIEW = true;   % KPI-Übersicht erzeugen
MAKE_ILLUSTRATED_OVERVIEW = false; % alternative Visualisierung
OVERVIEW_MAX_DEMOS = 3; % max. Demo-Szenen in Übersicht

% -------------------------------------------------------------------------
% 2. Setup & Logging
% -------------------------------------------------------------------------
root   = fileparts(mfilename('fullpath'));
outDir = fullfile(root, 'out');
if ~exist(outDir, 'dir'), mkdir(outDir); end

if QUIET_PLOTS
    set(0,'DefaultFigureVisible','off');
else
    set(0,'DefaultFigureVisible','on');
end

logTxt = fullfile(outDir, 'run_all_log.txt');
[log, closeLog] = logger(logTxt);

fprintf('[%s] INFO  | RUN_ALL start\n', datestr(now,'yyyy-mm-dd HH:MM:SS.FFF'));
log('INFO', 'RUN_ALL start');

% -------------------------------------------------------------------------
% 2b. Alte Pfade ignorieren (Warnungen unterdrücken)
% -------------------------------------------------------------------------
warning('off', 'MATLAB:MKDIR:DirectoryExists'); % unnötige mkdir-Warnungen
warning('off', 'MATLAB:dispatcher:nameConflict');
warning('off', 'MATLAB:MKDIR:NonExistentDirectory');

% Prüfe, ob alte Laufordner in 'out/' existieren, andernfalls überspringen
try
    oldRuns = dir(fullfile(outDir, 'run_*'));
    for k = 1:numel(oldRuns)
        runPath = fullfile(outDir, oldRuns(k).name);
        if ~isfolder(runPath)
            fprintf('⚠️  Überspringe nicht vorhandenen Laufordner: %s\n', runPath);
        end
    end
catch E
    fprintf('Hinweis: Alte Laufordner konnten nicht geprüft werden: %s\n', E.message);
end

% -------------------------------------------------------------------------
% 3. Einzel-Simulationen (Standard, DOE, Sweep)
% -------------------------------------------------------------------------
try
    run_sim;
catch E
    warnAndLog('run_sim', E, log);
end

try
    run_doe;
catch E
    warnAndLog('run_doe', E, log);
end

try
    run_sweep;
catch E
    warnAndLog('run_sweep', E, log);
end

% -------------------------------------------------------------------------
% 4. Demo-Szenarien (z. B. Fabriklinien)
% -------------------------------------------------------------------------
demoFiles = {
    'simulate_factory_line_3R2M.m', ...
    'simulate_factory_line.m', ...
    'simulate_factory_line_2belts.m'
};

for i = 1:numel(demoFiles)
    f = findDemo(root, demoFiles{i}, MAKE_ILLUSTRATED_OVERVIEW);
    if isempty(f), continue; end

    try
        run(f); %#ok<RUN>
        fprintf('%s OK\n', demoFiles{i});
        log('INFO', '%s OK', demoFiles{i});
    catch E
        warnAndLog(demoFiles{i}, E, log);
    end
end

% -------------------------------------------------------------------------
% 5. Übersichtsgrafik erzeugen
% -------------------------------------------------------------------------
if MAKE_OVERVIEW
    try
        ts = datestr(now, 'yyyymmdd_HHMMSS');
        overviewPng = fullfile(outDir, ['overview_' ts '.png']);
        make_overview_figure(outDir, overviewPng, OVERVIEW_MAX_DEMOS);
        fprintf('Übersicht gespeichert: %s\n', overviewPng);
        log('INFO', 'Übersicht gespeichert: %s', overviewPng);
    catch E
        warnAndLog('make_overview_figure', E, log);
    end
end

closeLog();
fprintf('RUN_ALL abgeschlossen.\n');
end


% =========================================================================
% Hilfsfunktionen
% =========================================================================

function warnAndLog(name, E, log)
    msg = sprintf('[%s] %s ERROR: %s\n', datestr(now,'HH:MM:SS'), name, E.message);
    fprintf(2, '%s', msg);
    if ~isempty(log)
        log('ERROR', '%s: %s', name, E.message);
    end
end

function f = findDemo(root, fileName, ~)
    candidates = {
        fullfile(root, fileName), ...
        fullfile(root, 'demos', fileName)
    };
    f = '';
    for i = 1:numel(candidates)
        if exist(candidates{i}, 'file') == 2
            f = candidates{i};
            return;
        end
    end
end