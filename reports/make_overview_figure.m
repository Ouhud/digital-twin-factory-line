function make_overview_figure(outDir, outPng, SHOW_LAST_N_DEMO)
% make_overview_figure.m
% Baut EIN Übersichtsbild (Figure) mit Twin-/Demo-KPIs
% und (falls vorhanden) einen Simulations-Snapshot (Roboter + Bahn).
%
% Aufruf:
%   make_overview_figure()
%   make_overview_figure(outDir)
%   make_overview_figure(outDir, outPng)
%   make_overview_figure(outDir, outPng, SHOW_LAST_N_DEMO)

% -------- robuste Defaults ----------
if nargin < 1 || isempty(outDir)
    outDir = find_out_dir(pwd);
end
if nargin < 3 || isempty(SHOW_LAST_N_DEMO)
    SHOW_LAST_N_DEMO = 3;
end
if nargin < 2 || isempty(outPng)
    ts = char(datetime("now","Format","yyyyMMdd_HHmmss"));
    outPng = fullfile(outDir, ['overview_' ts '.png']);
end

% ---------- Daten einsammeln ----------
twinCsv = pick_last(fullfile(outDir, 'twin_summary_*.csv'));
T_twin  = table(); if ~isempty(twinCsv), try, T_twin = readtable(twinCsv); end, end

demoCsv = pick_last(fullfile(outDir, 'demo_summary_*.csv'));
T_demo  = table(); if ~isempty(demoCsv), try, T_demo = readtable(demoCsv); end, end

snapPng = pick_last_any({ ...
    fullfile(outDir,'scene_snapshot_*.png'), ...
    fullfile(outDir,'*snapshot*.png'), ...
    fullfile(outDir,'*scene*.png') ...
});
hasSnap = ~isempty(snapPng) && isfile(snapPng);

% ---------- Figure bauen ----------
oldVis = get(0,'DefaultFigureVisible'); set(0,'DefaultFigureVisible','off');

if hasSnap
    % ====== Layout mit Szene (2x3) ======
    fig = figure('Units','pixels','Position',[100 100 1600 900],'Color','w');
    tl  = tiledlayout(fig, 2, 3, 'Padding','compact','TileSpacing','compact');
    title(tl, sprintf('Digital Twin – Szene & Kennzahlen (%s)', datestr(now,'yyyy-mm-dd HH:MM')));

    % Szene links (2x2 Tiles)
    axScene = nexttile(tl, [2 2]); axis(axScene,'off');
    try
        I = imread(snapPng); image(axScene, I);
        axis(axScene,'image'); axis(axScene,'off');
        title(axScene, sprintf('3D-Szene (Roboter & Bahn)\n%s', basename(snapPng)), 'Interpreter','none');
    catch
        text(0.5,0.5,'Snapshot konnte nicht gelesen werden','HorizontalAlignment','center'); axis(axScene,'off');
    end

    % Twin KPI Balken (rechts oben)
    axBar = nexttile(tl, 3);
    if ~isempty(T_twin)
        p  = pickVar(T_twin, {'picked'}); pl = pickVar(T_twin, {'placed'});
        mi = pickVar(T_twin, {'missed','pickMiss'});
        bar(axBar, [nz(p), nz(pl), nz(mi)]); set(axBar,'XTickLabel',{'picked','placed','missed'});
        ylabel(axBar,'Anzahl'); title(axBar,'Twin: Pick/Place/Miss'); grid(axBar,'on');
    else, axis(axBar,'off'); text(0.5,0.5,'Keine Twin-CSV','HorizontalAlignment','center');
    end

    % Twin Kennzahlen (rechts unten)
    axTxt = nexttile(tl, 6); axis(axTxt,'off');
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
        text(axTxt, 0.02,0.95, txt, 'Interpreter','tex','VerticalAlignment','top');
    else, text(axTxt,0.5,0.5,'(keine Twin-Kennzahlen)','HorizontalAlignment','center');
    end

    % Demos unten über gesamte Breite
    axBottom = axes('Parent', fig);
    posRight = get(axTxt,'Position'); posLeft  = get(axScene,'Position');
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
    else, axis(axBottom,'off'); text(axBottom,0.5,0.5,'Keine Demo-CSV','HorizontalAlignment','center');
    end

else
    % ====== Fallback: 2x2 nur KPIs ======
    fig = figure('Units','pixels','Position',[100 100 1400 900],'Color','w');
    tl  = tiledlayout(fig, 2, 2, 'Padding','compact','TileSpacing','compact');
    title(tl, sprintf('Digital Twin – Gesamtübersicht (%s)', datestr(now,'yyyy-mm-dd HH:MM')));

    nexttile;
    if ~isempty(T_twin)
        p  = pickVar(T_twin, {'picked'}); pl = pickVar(T_twin, {'placed'});
        mi = pickVar(T_twin, {'missed','pickMiss'});
        bar([nz(p), nz(pl), nz(mi)]); set(gca,'XTickLabel',{'picked','placed','missed'});
        ylabel('Anzahl'); title('Twin: Pick/Place/Miss'); grid on;
    else, text(0.5,0.5,'Keine Twin-CSV gefunden','HorizontalAlignment','center'); axis off; end

    nexttile; axis off;
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
        text(0.02,0.95, txt, 'Interpreter','tex','VerticalAlignment','top');
    else, text(0.5,0.5,'(keine Twin-Kennzahlen)','HorizontalAlignment','center');
    end

    nexttile;
    if ~isempty(T_demo)
        demos = unique(string(T_demo.demo)); names = strings(0); thrpt = [];
        for i = 1:numel(demos)
            Ti = T_demo(string(T_demo.demo)==demos(i),:);
            [~, idx] = sort(cellfun(@datenumFromName, cellstr(Ti.file)), 'descend');
            Ti = Ti(idx,:); Ti = Ti(1:min(SHOW_LAST_N_DEMO,height(Ti)), :);
            names(end+1) = demos(i); thrpt(end+1) = nz(Ti.throughput(1));
        end
        bar(thrpt); set(gca,'XTick',1:numel(names),'XTickLabel',names,'XTickLabelRotation',15);
        ylabel('Teile / Simulationsfenster'); title('Demos – Throughput (neuester Run je Demo)'); grid on;
    else, text(0.5,0.5,'Keine Demo-CSV gefunden','HorizontalAlignment','center'); axis off; end

    nexttile;
    if ~isempty(T_demo)
        demos = unique(string(T_demo.demo));
        U = nan(numel(demos),3);
        for i = 1:numel(demos)
            Ti = T_demo(string(T_demo.demo)==demos(i),:);
            U(i,1) = meanSafe(Ti, 'util_R1'); U(i,2) = meanSafe(Ti, 'util_R2'); U(i,3) = meanSafe(Ti, 'util_R3');
        end
        bar(U,'grouped'); legend({'R1','R2','R3'}, 'Location','bestoutside');
        set(gca,'XTick',1:numel(demos),'XTickLabel',demos,'XTickLabelRotation',15);
        ylabel('Auslastung (0..1)'); title('Demos – Roboterauslastung'); grid on;
    else, text(0.5,0.5,'(keine Demo-Daten für Utilization)','HorizontalAlignment','center'); axis off; end
end

% ---------- Speichern ----------
exportgraphics(fig, outPng, 'Resolution', 180);
close(fig); set(0,'DefaultFigureVisible', oldVis);
fprintf('Übersichtsbild gespeichert: %s\n', outPng);

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

function m = meanSafe(T, col)
if ismember(col, T.Properties.VariableNames)
    v = T.(col); try, m = mean(v(~isnan(v))); if isnan(m), m = NaN; end
    catch, m = NaN; end
else, m = NaN; end
end

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