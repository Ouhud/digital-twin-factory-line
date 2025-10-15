function S = simulate_digital_twin_conveyor_pickplace(belt_speed, spawn_rate, opts)
% SIMULATE_DIGITAL_TWIN_CONVEYOR_PICKPLACE – Simulation für DoE-Läufe
%
%   S = simulate_digital_twin_conveyor_pickplace(belt_speed, spawn_rate, opts)
%
% Beschreibung:
%   Führt eine vereinfachte Simulation mit 3 Robotern, 2 Maschinen
%   und Förderband durch (kompatibel mit run_doe).
%
% Autor: Mohamad Hamza Mehmalat
% Datum: 2025-10-15
% -------------------------------------------------------------------------

%% --- Konfiguration ---
C = config('Tsim',opts.Tsim, ...
           'dt',0.05, ...
           'belt_speed',belt_speed, ...
           'spawn_rate',spawn_rate, ...
           'machine_Tproc',[5.0 6.0], ...
           'showPlots',opts.showPlots, ...
           'show3D',opts.show3D);

C.belt_len      = 2.0;
C.stations_pos  = [0.8, 1.3, 1.9];

%% --- Modelle ---
src   = material_source(C.spawn_rate);
inBuf = buffer_store(inf,"in");
outBuf = buffer_store(inf,"out");
belt  = conveyor_model(C.belt_len, C.belt_speed, C.stations_pos);
M1    = fsm_machine(1, C.machine_Tproc(1));
M2    = fsm_machine(2, C.machine_Tproc(2));
R1    = fsm_robot("R1", C);
R2    = fsm_robot("R2", C);
R3    = fsm_robot("R3", C);

%% --- KPI & Init ---
k = kpi_init();
t = 0;
dt = C.dt;
shipped = 0;

%% --- Simulation ---
while t < C.Tsim
    [src, inBuf] = material_source_step(src, inBuf, dt);
    belt = belt.step(belt, dt);
    M1 = M1.tick(M1, struct(), dt);
    M2 = M2.tick(M2, struct(), dt);

    % --- Umgebung der Roboter ---
    envR1.can_pick = inBuf.count(inBuf) > 0;
    envR1.on_pick  = @() local_pop_inbuf();
    envR1.on_place = @(part) local_put_belt(part);

    envR2.can_pick = belt.can_pick(belt, C.stations_pos(2));
    envR2.on_pick  = @() local_take_belt(2);
    envR2.on_place = @(part) local_place_machine(part);

    % ✅ NEU: Funktionsaufruf von has_done(M)
    envR3.can_pick = M1.has_done(M1) || M2.has_done(M2);
    envR3.on_pick  = @() local_take_machine();
    envR3.on_place = @(part) local_ship(part);

    % --- Roboter ---
    [R1, ev1] = R1.tick(R1, envR1, dt);
    [R2, ev2] = R2.tick(R2, envR2, dt);
    [R3, ev3] = R3.tick(R3, envR3, dt);

    % --- KPIs ---
    k = kpi_update(k, ev1, ev2, ev3, R1, R2, R3, M1, M2, belt, dt, t);

    t = t + dt;
end

%% --- Abschluss ---
K = kpi_finalize(k);
S = struct('kpi',K,'config',C);

%% --- Lokale Helper ---
    function part = local_pop_inbuf()
        [inBuf, part, ~] = inBuf.pop(inBuf);
    end
    function ok = local_put_belt(part)
        [belt, ok] = belt.load(belt, part);
    end
    function part = local_take_belt(idx)
        [belt, part] = belt.take(belt, C.stations_pos(idx));
    end
    function ok = local_place_machine(part)
        ok = false;
        if ~M1.has_done(M1) && strcmp(M1.state,"idle")
            [M1, ok] = M1.start_proc(M1, part);
        elseif ~M2.has_done(M2) && strcmp(M2.state,"idle")
            [M2, ok] = M2.start_proc(M2, part);
        end
    end
    function part = local_take_machine()
        part = [];
        if M1.has_done(M1)
            [M1, part, ~] = M1.output(M1);
        elseif M2.has_done(M2)
            [M2, part, ~] = M2.output(M2);
        end
    end
    function ok = local_ship(part)
        shipped = shipped + 1;
        [outBuf, ok] = outBuf.push(outBuf, part);
    end
end