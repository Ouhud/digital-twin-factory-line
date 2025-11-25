function S = simulate_factory_line_3R2M_pflichtenheft(varargin)
% SIMULATE_FACTORY_LINE_3R2M_PFLICHTENHEFT – Simulation gemäß Pflichtenheft
% 
% Ablauf gemäß Pflichtenheft Abschnitt 2.1:
% 1. Roboter 1 liefert Material aus Eingangslager auf die Förderbänder
% 2. Die Maschinen bearbeiten parallel die Werkstücke (von den Bändern)
% 3. Roboter 2 entnimmt bearbeitete Werkstücke und legt sie in Zwischenlager
% 4. Roboter 3 belädt Transportmittel aus dem Zwischenlager
%
% Komponenten:
% - 3 Roboter (R1, R2, R3)
% - 2 Maschinen (M1, M2)
% - 2 Förderbänder (Band1, Band2)
% - Eingangslager, Zwischenlager, Transportmittel
%
% Autor: AI Assistant
% Datum: 2025
% Version: Pflichtenheft-konform

%% Standardwerte
defaults = struct( ...
    'Tsim', 120, ...
    'dt', 0.05, ...
    'spawn_rate', 0.5, ...
    'belt_speed', 0.3, ...
    'machine_Tproc', [5.0 6.0], ...
    'showPlots', true, ...
    'show3D', false, ...
    'transport_interval', 20.0, ...
    'transport_hold_time', 5.0 ...
);

%% Eingaben verarbeiten
args = varargin;
if nargin == 1 && isstruct(args{1})
    opts = args{1};
else
    opts = defaults;
    for k = 1:2:numel(args)
        name = args{k};
        value = args{k+1};
        opts.(name) = value;
    end
end

%% Konfiguration
C = config( ...
    'Tsim', opts.Tsim, ...
    'dt', opts.dt, ...
    'spawn_rate', opts.spawn_rate, ...
    'belt_speed', opts.belt_speed, ...
    'machine_Tproc', opts.machine_Tproc, ...
    'showPlots', opts.showPlots, ...
    'show3D', opts.show3D ...
);

C.transport_interval = opts.transport_interval;
C.transport_hold_time = opts.transport_hold_time;

% Layout-Positionen für 2 Bänder
C.belt_len = 3.0;
C.stations_pos = [0.5, 1.5, 2.5];  % Positionen entlang der Bänder

%% Modelle erstellen

% Materialquelle und Eingangslager
src = material_source(C.spawn_rate);
inBuf = buffer_store(inf, "Eingangslager");

% 2 Förderbänder (gemäß Pflichtenheft!)
belt1 = conveyor_model(C.belt_len, C.belt_speed, C.stations_pos);
belt2 = conveyor_model(C.belt_len, C.belt_speed, C.stations_pos);

% Zwischenlager
intermediateBuf = buffer_store(inf, "Zwischenlager");

% 2 Maschinen
M1 = fsm_machine(1, C.machine_Tproc(1));
M2 = fsm_machine(2, C.machine_Tproc(2));

% 3 Roboter
R1 = fsm_robot("R1", C);
R2 = fsm_robot("R2", C);
R3 = fsm_robot("R3", C);

%% KPI & Laufvariablen
k = kpi_init();
t = 0;
dt = C.dt;
shipped = 0;
transport_next = C.transport_interval;
transport_arrived = false;
transport_depart_time = 0;

% Statistiken
stats = struct();
stats.parts_to_belt1 = 0;
stats.parts_to_belt2 = 0;
stats.parts_to_M1 = 0;
stats.parts_to_M2 = 0;
stats.parts_from_M1 = 0;
stats.parts_from_M2 = 0;

% R1 wechselt zwischen Band 1 und Band 2
r1_next_belt = 1;  % 1 = Belt1, 2 = Belt2

%% Visualisierung
viz = [];
if C.showPlots
    viz = draw_scene_2d_pflichtenheft(C);
    if C.show3D, draw_scene_3d(C); end
end

%% Hauptschleife
while t < C.Tsim
    % 1) Quelle → Eingangs-Puffer
    [src, inBuf] = material_source_step(src, inBuf, dt);

    % 2) Förderbänder bewegen
    belt1 = belt1.step(belt1, dt);
    belt2 = belt2.step(belt2, dt);

    % 3) Maschinen ticken
    M1 = M1.tick(M1, struct(), dt);
    M2 = M2.tick(M2, struct(), dt);

    % 4) Transport-Logik
    if t >= transport_next && ~transport_arrived
        transport_arrived = true;
        transport_depart_time = t + C.transport_hold_time;
        fprintf('[t=%.1f] Transport angekommen\n', t);
    end
    if transport_arrived && t >= transport_depart_time
        transport_arrived = false;
        transport_next = t + C.transport_interval;
        fprintf('[t=%.1f] Transport abgefahren (shipped=%d)\n', t, shipped);
    end

    % 5) R1: Eingangslager → Förderbänder (abwechselnd)
    envR1.dt = C.dt;
    envR1.can_pick = inBuf.count(inBuf) > 0;
    envR1.can_place = true;
    envR1.on_pick = @pop_from_inBuf;
    envR1.on_place = @place_to_belt_R1;

    % 6) Maschinen nehmen von Bändern (automatisch)
    % M1 nimmt von Belt1, M2 nimmt von Belt2
    if strcmp(M1.state, "idle") && belt1.can_pick(belt1, C.stations_pos(2))
        [belt1, part] = belt1.take(belt1, C.stations_pos(2));
        if ~isempty(part)
            [M1, ok] = M1.load(M1, part);
            if ok
                stats.parts_to_M1 = stats.parts_to_M1 + 1;
                fprintf('[t=%.1f] M1 ← Belt1 (Teil #%d)\n', t, part.id);
            end
        end
    end
    
    if strcmp(M2.state, "idle") && belt2.can_pick(belt2, C.stations_pos(2))
        [belt2, part] = belt2.take(belt2, C.stations_pos(2));
        if ~isempty(part)
            [M2, ok] = M2.load(M2, part);
            if ok
                stats.parts_to_M2 = stats.parts_to_M2 + 1;
                fprintf('[t=%.1f] M2 ← Belt2 (Teil #%d)\n', t, part.id);
            end
        end
    end

    % 7) R2: M1/M2 → Zwischenlager
    envR2.dt = C.dt;
    envR2.can_pick = M1.has_done(M1) || M2.has_done(M2);
    envR2.can_place = true;
    envR2.on_pick = @pick_from_machine_R2;
    envR2.on_place = @place_to_intermediate_R2;

    % 8) R3: Zwischenlager → Transport
    envR3.dt = C.dt;
    envR3.can_pick = intermediateBuf.count(intermediateBuf) > 0 && transport_arrived;
    envR3.can_place = transport_arrived;
    envR3.on_pick = @pop_from_intermediateBuf;
    envR3.on_place = @ship_part_R3;

    % 9) Roboter-FSMs ausführen
    [R1, ev1] = R1.tick(R1, envR1, dt);
    [R2, ev2] = R2.tick(R2, envR2, dt);
    [R3, ev3] = R3.tick(R3, envR3, dt);

    % 10) KPIs aktualisieren - Events manuell tracken
    if contains(ev1, "pick_done"), k.picked = k.picked + 1; end
    if contains(ev2, "pick_done"), k.picked = k.picked + 1; end
    if contains(ev3, "pick_done"), k.picked = k.picked + 1; end
    
    if contains(ev1, "place_done"), k.placed = k.placed + 1; end
    if contains(ev2, "place_done"), k.placed = k.placed + 1; end
    if contains(ev3, "place_done"), k.placed = k.placed + 1; end
    
    k = kpi_update(k, ev1, ev2, ev3, R1, R2, R3, M1, M2, struct('shipped', shipped), dt, t);

    % 11) Visualisierung
    if C.showPlots && mod(round(t/dt), 5) == 0
        animate_step_pflichtenheft(viz, C, belt1, belt2, M1, M2, R1, R2, R3, ...
            inBuf, intermediateBuf, shipped, t, transport_arrived, stats);
    end

    % 12) Zeit fortschreiben
    t = t + dt;
end

%% Abschluss
K = kpi_finalize(k);
S = struct('kpi', K, 'config', C, 'stats', stats);
fprintf('\n=== Simulation abgeschlossen (Pflichtenheft-konform) ===\n');
fprintf('Versendete Teile: %d\n', shipped);
fprintf('Teile auf Belt1: %d, zu M1: %d, von M1: %d\n', stats.parts_to_belt1, stats.parts_to_M1, stats.parts_from_M1);
fprintf('Teile auf Belt2: %d, zu M2: %d, von M2: %d\n', stats.parts_to_belt2, stats.parts_to_M2, stats.parts_from_M2);
fprintf('Erfolgsrate: %.2f%%\n', K.successRate * 100);

%% Lokale Funktionen

    % R1: Nimmt aus Eingangslager
    function part = pop_from_inBuf()
        [inBuf, part, ok] = inBuf.pop(inBuf);
        if ~ok, part = []; end
    end

    % R1: Legt auf Förderband 1 oder 2 (abwechselnd)
    function ok = place_to_belt_R1(part)
        ok = false;
        if isempty(part), return; end
        
        % Abwechselnd auf Belt1 und Belt2 legen
        if r1_next_belt == 1
            [belt1, ok] = belt1.load(belt1, part, C.stations_pos(1));
            if ok
                stats.parts_to_belt1 = stats.parts_to_belt1 + 1;
                fprintf('[t=%.1f] R1 → Belt1 (Teil #%d)\n', t, part.id);
                r1_next_belt = 2;  % Nächstes Mal Belt2
            end
        else
            [belt2, ok] = belt2.load(belt2, part, C.stations_pos(1));
            if ok
                stats.parts_to_belt2 = stats.parts_to_belt2 + 1;
                fprintf('[t=%.1f] R1 → Belt2 (Teil #%d)\n', t, part.id);
                r1_next_belt = 1;  % Nächstes Mal Belt1
            end
        end
    end

    % R2: Nimmt aus M1 oder M2 (wenn fertig)
    function part = pick_from_machine_R2()
        part = [];
        if M1.has_done(M1)
            [M1, part] = M1.unload(M1);
            if ~isempty(part)
                stats.parts_from_M1 = stats.parts_from_M1 + 1;
                fprintf('[t=%.1f] R2 ← M1 (Teil #%d)\n', t, part.id);
            end
        elseif M2.has_done(M2)
            [M2, part] = M2.unload(M2);
            if ~isempty(part)
                stats.parts_from_M2 = stats.parts_from_M2 + 1;
                fprintf('[t=%.1f] R2 ← M2 (Teil #%d)\n', t, part.id);
            end
        end
    end

    % R2: Legt in Zwischenlager
    function ok = place_to_intermediate_R2(part)
        ok = false;
        if isempty(part), return; end
        intermediateBuf = intermediateBuf.push(intermediateBuf, part);
        ok = true;
        fprintf('[t=%.1f] R2 → Zwischenlager (Teil #%d)\n', t, part.id);
    end

    % R3: Nimmt aus Zwischenlager
    function part = pop_from_intermediateBuf()
        [intermediateBuf, part, ok] = intermediateBuf.pop(intermediateBuf);
        if ~ok, part = []; end
    end

    % R3: Verlädt auf Transport
    function ok = ship_part_R3(part)
        ok = false;
        if isempty(part), return; end
        shipped = shipped + 1;
        ok = true;
        fprintf('[t=%.1f] R3 → Transport (Teil #%d, gesamt: %d)\n', t, part.id, shipped);
    end
end
