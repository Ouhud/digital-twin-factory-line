function viz = draw_scene_2d_pflichtenheft(C)
% DRAW_SCENE_2D_PFLICHTENHEFT – 2D-Visualisierung gemäß Pflichtenheft
% Layout: Eingangslager → R1 → 2 Förderbänder → M1/M2 → R2 → Zwischenlager → R3 → Transport
%
% Komponenten:
% - Eingangslager
% - Roboter R1 (verteilt auf Bänder)
% - Förderband 1 (zu M1)
% - Förderband 2 (zu M2)
% - Maschine M1
% - Maschine M2
% - Roboter R2 (sammelt von Maschinen)
% - Zwischenlager
% - Roboter R3 (verlädt auf Transport)
% - Transport
%
% Autor: AI Assistant
% Datum: 2025

viz.fig = figure('Name','Digital Twin Factory Line – Pflichtenheft-konform','NumberTitle','off',...
    'Color','w','Visible','on','Position',[50 50 1400 600]);
viz.ax = axes('Parent',viz.fig); 
hold(viz.ax,'on'); 
axis(viz.ax,'equal');
title(viz.ax,'Fertigungslinie (Pflichtenheft): Eingangslager → R1 → 2 Förderbänder → M1/M2 → R2 → Zwischenlager → R3 → Transport',...
    'FontSize',12,'FontWeight','bold');
xlabel(viz.ax,'Position [m]'); 
ylabel(viz.ax,'');
xlim(viz.ax,[0, 10]); 
ylim(viz.ax,[-1.5, 2.5]);
grid(viz.ax,'on');
set(viz.ax,'YTick',[]);

%% Layout-Positionen
x_inbuf = 0.8;
x_R1 = 1.8;
x_belt_start = 2.5;
x_belt_end = 5.5;
x_M1 = 6.0;
x_M2 = 6.0;
x_R2 = 7.0;
x_intbuf = 8.0;
x_R3 = 8.8;
x_transport = 9.5;

y_belt1 = 1.2;
y_belt2 = -0.8;
y_center = 0.2;

boxW = 0.4;
boxH = 0.5;
robotSize = 14;

%% 1) Eingangslager
viz.inbuf.rect = rectangle(viz.ax,'Position',[x_inbuf-boxW/2, y_center-boxH/2, boxW, boxH], ...
    'FaceColor',[0.85 0.95 0.85],'EdgeColor',[0.2 0.6 0.2],'LineWidth',2);
viz.inbuf.txt = text(x_inbuf, y_center+boxH/2+0.2, 'Eingangslager\n(0)', ...
    'HorizontalAlignment','center','FontSize',10,'FontWeight','bold');

%% 2) Roboter R1
viz.R1.pt = plot(viz.ax, x_R1, y_center, 'o','MarkerSize',robotSize, ...
    'MarkerFaceColor',[0.2 0.6 1.0], 'MarkerEdgeColor','k','LineWidth',2);
viz.R1.txt = text(x_R1, y_center+0.6, 'R1\nidle','HorizontalAlignment','center','FontSize',9);

%% 3) Förderband 1 (oben, zu M1)
viz.belt1.rect = rectangle(viz.ax,'Position',[x_belt_start, y_belt1-0.1, x_belt_end-x_belt_start, 0.2], ...
    'FaceColor',[0.85 0.85 0.85],'EdgeColor',[0.3 0.3 0.3],'LineWidth',1.5);
viz.belt1.txt = text((x_belt_start+x_belt_end)/2, y_belt1+0.3, 'Förderband 1 →', ...
    'HorizontalAlignment','center','FontSize',9,'FontWeight','bold','Color',[0.3 0.3 0.3]);
viz.belt1.items = gobjects(0,1);

%% 4) Förderband 2 (unten, zu M2)
viz.belt2.rect = rectangle(viz.ax,'Position',[x_belt_start, y_belt2-0.1, x_belt_end-x_belt_start, 0.2], ...
    'FaceColor',[0.85 0.85 0.85],'EdgeColor',[0.3 0.3 0.3],'LineWidth',1.5);
viz.belt2.txt = text((x_belt_start+x_belt_end)/2, y_belt2-0.4, 'Förderband 2 →', ...
    'HorizontalAlignment','center','FontSize',9,'FontWeight','bold','Color',[0.3 0.3 0.3]);
viz.belt2.items = gobjects(0,1);

%% 5) Maschine M1 (oben)
viz.M1.rect = rectangle(viz.ax,'Position',[x_M1-boxW/2, y_belt1+0.2, boxW, boxH], ...
    'FaceColor',[0.85 0.93 1.0],'EdgeColor',[0.2 0.3 0.8],'LineWidth',2);
viz.M1.txt = text(x_M1, y_belt1+0.2+boxH/2+0.25, 'M1\nidle', ...
    'HorizontalAlignment','center','FontSize',10,'FontWeight','bold');

%% 6) Maschine M2 (unten)
viz.M2.rect = rectangle(viz.ax,'Position',[x_M2-boxW/2, y_belt2-0.2-boxH, boxW, boxH], ...
    'FaceColor',[0.85 0.93 1.0],'EdgeColor',[0.2 0.3 0.8],'LineWidth',2);
viz.M2.txt = text(x_M2, y_belt2-0.2-boxH/2-0.25, 'M2\nidle', ...
    'HorizontalAlignment','center','FontSize',10,'FontWeight','bold');

%% 7) Roboter R2
viz.R2.pt = plot(viz.ax, x_R2, y_center, 'o','MarkerSize',robotSize, ...
    'MarkerFaceColor',[1.0 0.6 0.2], 'MarkerEdgeColor','k','LineWidth',2);
viz.R2.txt = text(x_R2, y_center+0.6, 'R2\nidle','HorizontalAlignment','center','FontSize',9);

%% 8) Zwischenlager
viz.intbuf.rect = rectangle(viz.ax,'Position',[x_intbuf-boxW/2, y_center-boxH/2, boxW, boxH], ...
    'FaceColor',[1.0 0.95 0.85],'EdgeColor',[0.8 0.4 0.1],'LineWidth',2);
viz.intbuf.txt = text(x_intbuf, y_center+boxH/2+0.2, 'Zwischenlager\n(0)', ...
    'HorizontalAlignment','center','FontSize',10,'FontWeight','bold');

%% 9) Roboter R3
viz.R3.pt = plot(viz.ax, x_R3, y_center, 'o','MarkerSize',robotSize, ...
    'MarkerFaceColor',[0.5 0.8 0.5], 'MarkerEdgeColor','k','LineWidth',2);
viz.R3.txt = text(x_R3, y_center+0.6, 'R3\nidle','HorizontalAlignment','center','FontSize',9);

%% 10) Transport
viz.transport.rect = rectangle(viz.ax,'Position',[x_transport-boxW/2, y_center-boxH/2, boxW, boxH], ...
    'FaceColor',[0.9 0.9 1.0],'EdgeColor',[0.1 0.1 0.7],'LineWidth',2);
viz.transport.txt = text(x_transport, y_center+boxH/2+0.2, 'Transport\n(Weg)', ...
    'HorizontalAlignment','center','FontSize',10,'FontWeight','bold','Color',[0.5 0.5 0.5]);

%% Pfeile für Materialfluss
% R1 → Bänder
annotation('arrow',[0.18 0.24],[0.65 0.75],'Color',[0.2 0.7 0.2],'LineWidth',1.5);
annotation('arrow',[0.18 0.24],[0.35 0.25],'Color',[0.2 0.7 0.2],'LineWidth',1.5);

% Bänder → Maschinen
annotation('arrow',[0.42 0.48],[0.75 0.75],'Color',[0.2 0.7 0.2],'LineWidth',1.5);
annotation('arrow',[0.42 0.48],[0.25 0.25],'Color',[0.2 0.7 0.2],'LineWidth',1.5);

% Maschinen → R2
annotation('arrow',[0.52 0.56],[0.70 0.55],'Color',[0.2 0.7 0.2],'LineWidth',1.5);
annotation('arrow',[0.52 0.56],[0.30 0.45],'Color',[0.2 0.7 0.2],'LineWidth',1.5);

% R2 → Zwischenlager → R3 → Transport
annotation('arrow',[0.58 0.90],[0.50 0.50],'Color',[0.2 0.7 0.2],'LineWidth',2,'HeadLength',8,'HeadWidth',8);

%% KPI-Anzeige
viz.kpi.txt = text(0.5, 2.2, 'Zeit: 0.0s | Versendet: 0 | Belt1: 0 | Belt2: 0 | M1: 0→0 | M2: 0→0', ...
    'FontSize',11,'FontWeight','bold','Color',[0.1 0.1 0.1]);

%% Legende
text(0.3, -1.2, '✓ Pflichtenheft-konform: 3 Roboter, 2 Maschinen, 2 Förderbänder', ...
    'FontSize',9,'Color',[0 0.5 0],'FontWeight','bold');

drawnow;
end
