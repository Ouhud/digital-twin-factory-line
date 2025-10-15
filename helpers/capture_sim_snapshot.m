function capture_sim_snapshot(simFcn, simArgs, outPng)
% CAPTURE_SIM_SNAPSHOT  Führt kurz eine Simulation mit sichtbaren Figures aus
% und speichert einen Screenshot der "besten" (typisch 3D) Figure.
%
% capture_sim_snapshot(@simulate_factory_line_3R2M, ...
%     {struct('Tsim',10,'show3D',true,'showPlots',true)}, 'out/scene_snapshot.png')

arguments
    simFcn (1,1) function_handle
    simArgs (1,:) cell = {}
    outPng (1,1) string
end

% Sichtbarkeit temporär aktivieren
oldVis = get(0,'DefaultFigureVisible');
set(0,'DefaultFigureVisible','on');
cleanup = onCleanup(@() set(0,'DefaultFigureVisible',oldVis));

% Vorher alles zu
close all force;

% Simulation ausführen
try
    simFcn(simArgs{:});
catch E
    warning('capture_sim_snapshot: Simulation schlug fehl: %s', E.message);
end
drawnow;

% Beste Figure auswählen
figs = findall(0,'Type','figure');
if isempty(figs)
    error('capture_sim_snapshot: Keine Figure gefunden.');
end

bestFig = figs(1); bestScore = -inf;
for f = figs.'
    score = 0;
    ax = findall(f,'Type','axes');
    for a = ax.'
        try
            v = get(a,'View');          % 3D-Hinweis
            if numel(v)==2 && abs(v(2))~=90, score = score + 2; end
        catch, end
        kids = get(a,'Children');
        for k = kids.'
            typ = get(k,'Type');
            if any(strcmpi(typ, {'patch','surface'})), score = score + 3; end
            if strcmpi(typ,'line'), score = score + 0.5; end
        end
    end
    score = score + 0.01 * double(f.Number); % neuere leicht bevorzugen
    if score > bestScore, bestScore = score; bestFig = f; end
end

% Export
try
    exportgraphics(bestFig, outPng, 'Resolution', 180);
catch
    fr = getframe(bestFig);
    imwrite(fr.cdata, outPng);
end

% Aufräumen
close all force;
end