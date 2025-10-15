function make_overview_illustrated(outDir, snapshotPng, outPng, SHOW_LAST_N_DEMO)
% make_overview_illustrated.m
% Ein Bild im Querformat:
%   - links groß: 3D-Snapshot (Roboter & Bahn)
%   - rechts oben: Twin-Balken (picked/placed/missed)
%   - rechts unten: Twin-Kennzahlen
%   - unten über gesamte Breite: Demo-Throughput
%
% Aufrufe:
%   make_overview_illustrated()
%   make_overview_illustrated(outDir)
%   make_overview_illustrated(outDir, snapshotPng)
%   make_overview_illustrated(outDir, snapshotPng, outPng)
%   make_overview_illustrated(outDir, snapshotPng, outPng, SHOW_LAST_N_DEMO)

% -------- Defaults ----------
if nargin < 1 || isempty(outDir)
    outDir = find_out_dir(pwd);
end
if nargin < 2 || isempty(snapshotPng)
    snapshotPng = pick_last_any({ ...
        fullfile(outDir,'scene_snapshot_*.png'), ...
        fullfile(outDir,'*snapshot*.png'), ...
        fullfile(outDir,'*scene*.png') ...
    });
end
if nargin < 4 || isempty(SHOW_LAST_N_DEMO)
    SHOW_LAST_N_DEMO = 3;
end
if nargin < 3 || isempty(outPng)
    ts = char(datetime("now","Format","yyyyMMdd_HHmmss"));
    outPng = fullfile(outDir, ['overview_illustrated_' ts '.png']);
end

% -------- Daten laden ----------
twinCsv = pick_last(fullfile(outDir, 'twin_summary_*.csv'));
T_twin  = table(); if ~isempty(twinCsv), try, T_twin = readtable(twinCsv); end, end

demoCsv = pick_last(fullfile(outDir, 'demo_summary_*.csv'));
T_demo  = table(); if ~isempty(demoCsv), try, T_demo = readtable(demoCsv); end, end

% -------- Figure ----------
oldVis = get(0,'DefaultFigureVisible'); set(0,'DefaultFigureVisible','off');
fig = figure('Units','pixels','Position',[80 80 1600 900],'Color','w');
tl  = tiledlayout(fig, 2, 3, 'Padding','compact','TileSpacing','compact');
title(tl, sprintf('Digital Twin – Szene & Kennzahlen (%s)', datestr(now,'yyyy-mm-dd HH:MM')));

% (1) Szene links
ax1 = nexttile(tl, [2 2]); axis(ax1,'off');
if ~isempty(snapshotPng) && isfile(snapshotPng)
    try
        I = imread(snapshotPng); image(ax1, I);
        axis(ax1,'image'); axis(ax1,'off');
        title(ax1, sprintf('3D-Szene (Roboter & Bahn)\n%s', basename(snapshotPng)), 'Interpreter','none');
    catch
        text(0.5,0.5,'Snapshot konnte nicht gelesen werden','HorizontalAlignment','center'); axis(ax1,'off');
    end
else
    text(0.5,0.5,'(kein Snapshot gefunden)','HorizontalAlignment','center'); axis(ax1,'off');
end

% (2) Twin KPI Balken
ax2 = nexttile(tl, 3);
if ~isempty(T_twin)
    p  = pickVar(T_twin, {'picked'}); pl = pickVar(T_twin, {'placed'});
    mi = pickVar(T_twin, {'missed','pickMiss'});
    bar(ax2, [nz(p), nz(pl), nz(mi)]); set(ax2,'XTickLabel',{'picked','placed','missed'});
    ylabel(ax2,'Anzahl'); title(ax2,'Twin: Pick/Place/Miss'); grid(ax2,'on');
else, axis(ax2,'off'); text(0.5,0.5,'Keine Twin-CSV','HorizontalAlignment','center'); end

% (3) Twin Kennzahlen
ax3 = nexttile(tl, 6); axis(ax3,'off');
if ~isempty(T_twin)
    succ = 100 * nz(pickVar(T_twin, {'success','successRate'}));
    thrm = nz(pickVar(T_twin, {'throughputPM'}));
    rps  = nz(pickVar(T_twin, {'outputRatePS','rate','outputRate'}));
    avail= 100 * nz(pickVar(T_twin, {'availability'}));
    txt = {'\bfTwin – Kennzahlen', ...
           sprintf('Erfolgsrate: %.1f %%', succ), ...
           sprintf('Throughput: %.2f Teile/min', thrm), ...
           sprintf('Rate: %.3f Teile/s', rps), ...
           sprintf('Verfügbarkeit: %.1f %%', avail)};
    text(ax3, 0.02,0.95, txt, 'Interpreter','tex','VerticalAlignment','top');
else, text(ax3,0.5,0.5,'(keine Twin-Kennzahlen)','HorizontalAlignment','center'); end

% (4) Demos – Throughput (eigene Achse über gesamte Breite unten)
axBottom = axes('Parent', fig);
posRight = get(ax3,'Position'); posLeft  = get(ax1,'Position');
left   = posLeft(1); right  = posRight(1) + posRight(3);
bottom = posRight(2) - 0.04; height = posRight(4) + 0.02;
set(axBottom, 'Position', [left, bottom, right-left, height]);

if ~isempty(T_demo)
    demos = unique(string(T_demo.demo)); names = strings(0); thrpt = [];
    for i = 1:numel(demos)
        Ti = T_demo(string(T_demo.demo)==demos(i),:);
        [~, idx] = sort(cellfun(@datenumFromName, cellstr(Ti.file)), 'descend');
        Ti = Ti(idx,:); Ti = Ti(1:min(SHOW_LAST_N_DEMO,height(Ti)), :);
        names(end+1) = demos(i); thrpt(end+1) = nz(Ti.throughput(1));
    end
    bar(axBottom, thrpt); set(axBottom,'XTick',1:numel(names),'XTickLabel',names,'XTickLabelRotation',10);
    ylabel(axBottom,'Teile / Simulationsfenster'); title(axBottom,'Demos – Throughput (neuester Run je Demo)'); grid(axBottom,'on');
else, axis(axBottom,'off'); text(axBottom,0.5,0.5,'Keine Demo-CSV','HorizontalAlignment','center'); end

% -------- Speichern ----------
exportgraphics(fig, outPng, 'Resolution', 180);
close(fig); set(0,'DefaultFigureVisible', oldVis);
fprintf('Illustriertes Übersichtsbild gespeichert: %s\n', outPng);

end % ===== function =====


% ================== Helper (lokal) ==================
function f = pick_last(pattern)
d = dir(pattern); if isempty(d), f = ''; return; end
[~,i] = max([d.datenum]); f = fullfile(d(i).folder, d(i).name);
end

function f = pick_last_any(patterns)
f = ''; best = -inf;
for i=1:numel(patterns)
    d = dir(patterns{i}); if isempty(d), continue; end
    [~,idx] = max([d.datenum]); if d(idx).datenum > best
        best = d(idx).datenum; f = fullfile(d(idx).folder, d(idx).name);
    end
end
end

function x = pickVar(T, names)
x = NaN;
for k=1:numel(names)
    n = names{k};
    if ismember(n, T.Properties.VariableNames)
        v = T.(n); if iscell(v), v = v{1}; end
        if isstring(v) || ischar(v), v = str2double(v); end
        if isscalar(v), x = v; else, try, x = v(1); end, end
        return;
    end
end
end

function y = nz(x), if isempty(x) || isnan(x), y = 0; else, y = x; end, end

function dn = datenumFromName(p)
try
    [~, base, ext] = fileparts(p); s = [base ext];
    m = regexp(s, '(\d{8}_\d{6})', 'tokens', 'once');
    if ~isempty(m), dn = datenum(datetime(m{1}, 'InputFormat','yyyyMMdd_HHmmss')); return; end
    info = dir(p); if ~isempty(info), dn = info.datenum; else, dn = now; end
catch, dn = now; end
end

function b = basename(p), [~,n,e] = fileparts(p); b=[n e]; end

function outDir = find_out_dir(startDir)
p = startDir;
while true
    cand = fullfile(p, 'out'); if exist(cand,'dir'), outDir=cand; return; end
    [p2,~,~] = fileparts(p); if strcmp(p2,p), error('Kein "out" unter %s gefunden.', startDir); end
    p = p2;
end
end