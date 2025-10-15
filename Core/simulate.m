function S = simulate_digital_twin_conveyor_pickplace(belt_v, spawn, opts)
% SIMULATE_DIGITAL_TWIN_CONVEYOR_PICKPLACE – Hauptszenario (Twin)
% Aufruf: S = simulate_digital_twin_conveyor_pickplace(0.30, 0.6, struct('Tsim',60,'showPlots',true,'show3D',false))

arguments
    belt_v double
    spawn  double
    opts.Tsim double = 60
    opts.showPlots logical = true
    opts.show3D    logical = false
end

% --- Config ---
C = config('Tsim',opts.Tsim, 'belt_speed',belt_v, 'spawn_rate',spawn, ...
           'showPlots',opts.showPlots, 'show3D',opts.show3D);

% --- Modelle (aus Core/) ---
src   = material_source(C.spawn_rate);
inBuf = buffer_store(inf,"in");
outBuf= buffer_store(inf,"out");
belt  = conveyor_model(C.belt_len, C.belt_speed, C.stations_pos);
M1    = fsm_machine(1, C.machine_Tproc(1));
M2    = fsm_machine(2, C.machine_Tproc(2));
R1    = fsm_robot("R1", C);
R2    = fsm_robot("R2", C);
R3    = fsm_robot("R3", C);
SCH   = scheduler(C, inBuf, outBuf, belt, M1, M2);

% --- Visualisierung (aus viz/) ---
viz = [];
if C.showPlots
    viz = draw_scene_2d(C);
    if opts.show3D, draw_scene_3d(C); end
end

% --- KPI (aus kpi/) ---
k = kpi_init();

% --- Simulationsloop ---
t = 0; dt = C.dt;
while t < C.Tsim
    [src, SCH.inBuf] = material_source_step(src, SCH.inBuf, dt);
    [SCH, envR1, envR2, envR3, Menv1, Menv2] = SCH.step(SCH, dt);

    SCH.M1 = SCH.M1.tick(SCH.M1, Menv1, dt);
    SCH.M2 = SCH.M2.tick(SCH.M2, Menv2, dt);

    [R1, ev1] = R1.tick(R1, envR1, dt);
    [R2, ev2] = R2.tick(R2, envR2, dt);
    [R3, ev3] = R3.tick(R3, envR3, dt);

    k = kpi_update(k, ev1, ev2, ev3, R1, R2, R3, SCH.M1, SCH.M2, SCH, dt, t);

    if C.showPlots
        animate_step(viz, C, SCH.belt, SCH.M1, SCH.M2, R1, R2, R3, SCH.inBuf, SCH.outBuf, SCH.shipped, t);
    end
    t = t + dt;
end

K = kpi_finalize(k);

% --- Export + Rückgabe ---
outDir = fullfile(fileparts(mfilename('fullpath')), 'out');
if ~exist(outDir,'dir'), mkdir(outDir); end
paths = export_kpi(K, outDir, 'twin');

S = struct('kpi',K,'paths',paths);   % kompatibel mit run_sim.m
end