function viz3d = draw_scene_3d(C)
% DRAW_SCENE_3D – einfache 3D-Vorschau (Platzhalterarme + Layout)
% Gut für Screenshots. Kein Update zwingend nötig, aber optional möglich.

if nargin<1, error('draw_scene_3d: config C fehlt'); end

viz3d.fig = figure('Name','Digital Twin – 3D','NumberTitle','off','Color','w','Visible','on');
viz3d.ax  = axes('Parent',viz3d.fig); hold(viz3d.ax,'on');
grid(viz3d.ax,'on'); view(viz3d.ax, 45, 25);
xlabel(viz3d.ax,'X [m]'); ylabel(viz3d.ax,'Y [m]'); zlabel(viz3d.ax,'Z [m]');
xlim(viz3d.ax,[-1, C.belt_len+1]); ylim(viz3d.ax,[-0.8, 1.2]); zlim(viz3d.ax,[0, 0.8]);

% „Förderband" Ebene
[X,Y] = meshgrid(linspace(0,C.belt_len,20), linspace(-0.1,0.1,2));
Z = 0*X;
surf(viz3d.ax, X,Y,Z,'FaceAlpha',0.4,'EdgeColor','none','FaceColor',[0.7 0.7 0.7]);

% Stationen als Blöcke
for k=1:numel(C.stations_pos)
    px = C.stations_pos(k);
    patch(viz3d.ax, 'XData',[px-0.15 px+0.15 px+0.15 px-0.15], ...
                      'YData',[0.25 0.25 0.55 0.55], ...
                      'ZData',[0 0 0 0], ...
          'FaceColor',[0.85 0.93 1.0],'EdgeColor',[0.2 0.3 0.6],'FaceAlpha',0.9);
end

% Drei „Roboterarme" als einfache Linien im Plan z=0.02
viz3d.R = struct([]);
baseZ = 0.02;
baseY = [0.8, 0.9, 0.8];
baseX = [-0.2, mean(C.stations_pos), C.belt_len+0.2];
L = [0.25 0.20 0.15];

for r=1:3
    t = [0, 0, 0];   % Startwinkel
    [~, joints] = kinematics_3R_planar(t, L);
    Xr = joints(:,1) + baseX(r);
    Yr = joints(:,2) + baseY(r);
    Zr = baseZ * ones(size(Xr));
    viz3d.R(r).ln = plot3(viz3d.ax, Xr, Yr, Zr, '-o', 'LineWidth',2);
    viz3d.R(r).txt= text(baseX(r), baseY(r)+0.25, baseZ+0.02, sprintf('R%d',r),'Parent',viz3d.ax);
end

title(viz3d.ax,'Fertigungsstation (3D Vorschau)');
drawnow;
end