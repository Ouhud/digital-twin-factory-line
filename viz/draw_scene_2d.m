function viz = draw_scene_2d(C)
% DRAW_SCENE_2D – einfache 2D-Szene (Förderband, Maschinen, Puffer, Roboter)
% Rückgabe:
%   viz: Struct mit Handles (ax, fig, patches, texts, usw.)

if nargin<1, error('draw_scene_2d: config C fehlt'); end

% Figure erzwingen (auch wenn DefaultFigureVisible='off' gesetzt wurde)
viz.fig = figure('Name','Digital Twin – 2D','NumberTitle','off','Color','w','Visible','on');
viz.ax  = axes('Parent',viz.fig); hold(viz.ax,'on'); axis(viz.ax,'equal');
title(viz.ax,'Fertigungsstation (2D)');
xlabel(viz.ax,'x [m]'); ylabel(viz.ax,'y [m]');
xlim(viz.ax,[-0.5, C.belt_len+0.8]); ylim(viz.ax,[-0.6, 1.2]);
grid(viz.ax,'on');

% Förderband (als Rechteck)
beltY = 0.0; beltH = 0.2;
viz.band.rect = rectangle(viz.ax,'Position',[0, beltY, C.belt_len, beltH], ...
    'FaceColor',[0.9 0.9 0.9],'EdgeColor',[0.3 0.3 0.3]);

% Stationen (Maschinen) als Kästen oberhalb des Bandes
stY = beltY + beltH + 0.05; stW = 0.3; stH = 0.25;
viz.stations = struct([]);
for k = 1:numel(C.stations_pos)
    px = C.stations_pos(k)-stW/2;
    viz.stations(k).rect = rectangle(viz.ax,'Position',[px, stY, stW, stH], ...
        'FaceColor',[0.85 0.93 1.0],'EdgeColor',[0.2 0.3 0.6],'LineWidth',1.2);
    viz.stations(k).txt  = text(px+stW/2, stY+stH+0.03, sprintf('M%d: Ready',k), ...
        'HorizontalAlignment','center','FontSize',9);
end

% Items auf dem Band (Platzhalter, wird dynamisch befüllt)
viz.items.h = gobjects(0,1);

% Eingangs-/Ausgangspuffer Indikatoren
viz.inbuf  = struct();
viz.outbuf = struct();
viz.inbuf.marker  = rectangle(viz.ax,'Position',[-0.35, beltY, 0.25, beltH], ...
    'FaceColor',[0.95 1.0 0.95],'EdgeColor',[0.2 0.5 0.2]);
viz.outbuf.marker = rectangle(viz.ax,'Position',[C.belt_len+0.1, beltY, 0.25, beltH], ...
    'FaceColor',[1.0 0.95 0.9],'EdgeColor',[0.7 0.3 0.1]);

viz.inbuf.txt  = text(-0.22, beltY + beltH + 0.03, 'IN: 0','HorizontalAlignment','center','FontSize',9);
viz.outbuf.txt = text(C.belt_len+0.22, beltY + beltH + 0.03, 'OUT: 0','HorizontalAlignment','center','FontSize',9);

% Roboter-„Marker" (nur Positionen/Labels, keine echte Kinematik)
% R1 links (Supply), R2 mittig (Collect), R3 rechts (Ship)
viz.R = struct([]);
viz.R(1).pt = plot(viz.ax, -0.2, 0.7, 'o','MarkerSize',8, 'MarkerFaceColor',[0.2 0.6 1.0], 'MarkerEdgeColor','k');
viz.R(1).tx = text(-0.2, 0.85, 'R1: Idle','HorizontalAlignment','center');

viz.R(2).pt = plot(viz.ax, mean(C.stations_pos), 0.85, 'o','MarkerSize',8, 'MarkerFaceColor',[1.0 0.6 0.2], 'MarkerEdgeColor','k');
viz.R(2).tx = text(mean(C.stations_pos), 1.0, 'R2: Idle','HorizontalAlignment','center');

viz.R(3).pt = plot(viz.ax, C.belt_len+0.2, 0.7, 'o','MarkerSize',8, 'MarkerFaceColor',[0.5 0.8 0.5], 'MarkerEdgeColor','k');
viz.R(3).tx = text(C.belt_len+0.2, 0.85, 'R3: Idle','HorizontalAlignment','center');

% KPI-Texte
viz.kpi.txt = text(0.02, 1.12, 'picked=0 | placed=0 | shipped=0 | t=0.0 s', ...
    'Units','normalized','HorizontalAlignment','left','FontWeight','bold');

% Hinweis zur Geschwindigkeit/Spawn
annotation(viz.fig,'textbox',[0.70 0.93 0.28 0.06], ...
    'String',sprintf('belt=%.2f m/s | spawn=%.2f 1/s', C.belt_speed, C.spawn_rate), ...
    'EdgeColor',[0.8 0.8 0.8],'BackgroundColor',[1 1 1],'HorizontalAlignment','right');

drawnow;
end