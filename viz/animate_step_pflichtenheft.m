function animate_step_pflichtenheft(viz, C, belt1, belt2, M1, M2, R1, R2, R3, inBuf, intermediateBuf, shipped, t, transport_arrived, stats)
% ANIMATE_STEP_PFLICHTENHEFT – Aktualisiert die 2D-Visualisierung (Pflichtenheft)
%
% Autor: AI Assistant
% Datum: 2025

if isempty(viz) || ~isfield(viz,'ax') || ~isvalid(viz.ax)
    return;
end

%% Eingangslager
if isfield(viz,'inbuf') && isfield(viz.inbuf,'txt') && isvalid(viz.inbuf.txt)
    count = inBuf.count(inBuf);
    set(viz.inbuf.txt, 'String', sprintf('Eingangslager\n(%d)', count));
    if count > 5
        set(viz.inbuf.rect, 'FaceColor', [0.95 0.85 0.85]);
    else
        set(viz.inbuf.rect, 'FaceColor', [0.85 0.95 0.85]);
    end
end

%% Roboter R1
if isfield(viz,'R1') && isfield(viz.R1,'txt') && isvalid(viz.R1.txt)
    state_str = string(R1.state);
    set(viz.R1.txt, 'String', sprintf('R1\n%s', state_str));
    if R1.hasPart
        set(viz.R1.pt, 'MarkerFaceColor', [0.1 0.4 0.9]);
    else
        set(viz.R1.pt, 'MarkerFaceColor', [0.2 0.6 1.0]);
    end
end

%% Förderband 1 - Items visualisieren
if isfield(viz,'belt1') && isfield(viz.belt1,'items')
    % Alte Items löschen
    try
        ok = arrayfun(@isvalid, viz.belt1.items);
        delete(viz.belt1.items(ok));
    catch
    end
    viz.belt1.items = gobjects(0,1);
    
    % Neue Items zeichnen
    if ~isempty(belt1) && isfield(belt1,'items') && ~isempty(belt1.items)
        for i=1:numel(belt1.items)
            % Position auf Band 1 (y = 1.2)
            x = 2.5 + belt1.items(i).pos;  % Offset für Bandstart
            y = 1.2;
            viz.belt1.items(end+1,1) = rectangle(viz.ax, ...
                'Position',[x-0.05, y-0.08, 0.1, 0.16], ...
                'FaceColor',[0.2 0.6 0.9], 'EdgeColor','k','LineWidth',1);
        end
    end
end

%% Förderband 2 - Items visualisieren
if isfield(viz,'belt2') && isfield(viz.belt2,'items')
    % Alte Items löschen
    try
        ok = arrayfun(@isvalid, viz.belt2.items);
        delete(viz.belt2.items(ok));
    catch
    end
    viz.belt2.items = gobjects(0,1);
    
    % Neue Items zeichnen
    if ~isempty(belt2) && isfield(belt2,'items') && ~isempty(belt2.items)
        for i=1:numel(belt2.items)
            % Position auf Band 2 (y = -0.8)
            x = 2.5 + belt2.items(i).pos;  % Offset für Bandstart
            y = -0.8;
            viz.belt2.items(end+1,1) = rectangle(viz.ax, ...
                'Position',[x-0.05, y-0.08, 0.1, 0.16], ...
                'FaceColor',[0.9 0.4 0.2], 'EdgeColor','k','LineWidth',1);
        end
    end
end

%% Maschine M1
if isfield(viz,'M1') && isfield(viz.M1,'txt') && isvalid(viz.M1.txt)
    state_str = string(M1.state);
    set(viz.M1.txt, 'String', sprintf('M1\n%s', state_str));
    if strcmp(M1.state, "processing")
        set(viz.M1.rect, 'FaceColor', [1.0 0.9 0.7]);
    elseif strcmp(M1.state, "done")
        set(viz.M1.rect, 'FaceColor', [0.7 1.0 0.7]);
    else
        set(viz.M1.rect, 'FaceColor', [0.85 0.93 1.0]);
    end
end

%% Maschine M2
if isfield(viz,'M2') && isfield(viz.M2,'txt') && isvalid(viz.M2.txt)
    state_str = string(M2.state);
    set(viz.M2.txt, 'String', sprintf('M2\n%s', state_str));
    if strcmp(M2.state, "processing")
        set(viz.M2.rect, 'FaceColor', [1.0 0.9 0.7]);
    elseif strcmp(M2.state, "done")
        set(viz.M2.rect, 'FaceColor', [0.7 1.0 0.7]);
    else
        set(viz.M2.rect, 'FaceColor', [0.85 0.93 1.0]);
    end
end

%% Roboter R2
if isfield(viz,'R2') && isfield(viz.R2,'txt') && isvalid(viz.R2.txt)
    state_str = string(R2.state);
    set(viz.R2.txt, 'String', sprintf('R2\n%s', state_str));
    if R2.hasPart
        set(viz.R2.pt, 'MarkerFaceColor', [0.9 0.4 0.1]);
    else
        set(viz.R2.pt, 'MarkerFaceColor', [1.0 0.6 0.2]);
    end
end

%% Zwischenlager
if isfield(viz,'intbuf') && isfield(viz.intbuf,'txt') && isvalid(viz.intbuf.txt)
    count = intermediateBuf.count(intermediateBuf);
    set(viz.intbuf.txt, 'String', sprintf('Zwischenlager\n(%d)', count));
    if count > 5
        set(viz.intbuf.rect, 'FaceColor', [1.0 0.85 0.75]);
    else
        set(viz.intbuf.rect, 'FaceColor', [1.0 0.95 0.85]);
    end
end

%% Roboter R3
if isfield(viz,'R3') && isfield(viz.R3,'txt') && isvalid(viz.R3.txt)
    state_str = string(R3.state);
    set(viz.R3.txt, 'String', sprintf('R3\n%s', state_str));
    if R3.hasPart
        set(viz.R3.pt, 'MarkerFaceColor', [0.3 0.6 0.3]);
    else
        set(viz.R3.pt, 'MarkerFaceColor', [0.5 0.8 0.5]);
    end
end

%% Transport
if isfield(viz,'transport') && isfield(viz.transport,'txt') && isvalid(viz.transport.txt)
    if transport_arrived
        status_str = sprintf('Transport\n(Hier)');
        set(viz.transport.txt, 'String', status_str, 'Color', [0.1 0.5 0.1]);
        set(viz.transport.rect, 'FaceColor', [0.7 1.0 0.7]);
    else
        status_str = sprintf('Transport\n(Weg)');
        set(viz.transport.txt, 'String', status_str, 'Color', [0.5 0.5 0.5]);
        set(viz.transport.rect, 'FaceColor', [0.9 0.9 1.0]);
    end
end

%% KPI-Anzeige
if isfield(viz,'kpi') && isfield(viz.kpi,'txt') && isvalid(viz.kpi.txt)
    if nargin >= 14 && isstruct(stats)
        kpi_str = sprintf('Zeit: %.1fs | Versendet: %d | Belt1: %d | Belt2: %d | M1: %d→%d | M2: %d→%d', ...
            t, shipped, stats.parts_to_belt1, stats.parts_to_belt2, ...
            stats.parts_to_M1, stats.parts_from_M1, stats.parts_to_M2, stats.parts_from_M2);
    else
        kpi_str = sprintf('Zeit: %.1fs | Versendet: %d', t, shipped);
    end
    set(viz.kpi.txt, 'String', kpi_str);
end

drawnow limitrate;
end
