function S = simulate_factory_line(opts)
% SIMULATE_FACTORY_LINE – 1 Förderband, 2 Maschinen, 3 Roboter
% Outputs:
%   - out/factory_kpi_<ts>.csv
%   - out/factory_throughput_ts_<ts>.csv
%   - out/factory_kpi_<ts>.mat/.json

arguments
    opts.Tsim double = 60
    opts.dt   double = 0.05
    opts.showPlots logical = true
    opts.show3D    logical = false
    opts.spawn_rate double = 0.6
    opts.belt_speed double = 0.30
    opts.machine_Tproc (1,2) double = [4.0 5.5]
    opts.outDir = []
end

% --- Konfiguration laden ---
C = config('Tsim',opts.Tsim,'dt',opts.dt, ...
           'spawn_rate',opts.spawn_rate, 'belt_speed',opts.belt_speed, ...
           'machine_Tproc',opts.machine_Tproc, 'showPlots',opts.showPlots, 'show3D',opts.show3D);

root = fileparts(mfilename('fullpath')); proj = fileparts(root);
outDir = opts.outDir; if isempty(outDir), outDir = fullfile(proj,'out'); end
if ~exist(outDir,'dir'), mkdir(outDir); end

% --- Modelle ---
src   = material_source(C.spawn_rate);
inBuf = buffer_store(inf,"in"); outBuf = buffer_store(inf,"out");
belt  = conveyor_model(C.belt_len, C.belt_speed, C.stations_pos);
M1    = fsm_machine(1, C.machine_Tproc(1));
M2    = fsm_machine(2, C.machine_Tproc(2));
R1    = fsm_robot("R1", C); R2 = fsm_robot("R2", C); R3 = fsm_robot("R3", C);
SCH   = scheduler(C, inBuf, outBuf, belt, M1, M2);

% --- Visualisierung ---
viz = [];
if C.showPlots
    viz = draw_scene_2d(C);
    if C.show3D, draw_scene_3d(C); end
end

% --- KPI init ---
k = kpi_init();

% --- Loop ---
t=0; dt=C.dt;
while t < C.Tsim
    [src, SCH.inBuf] = material_source_step(src, SCH.inBuf, dt);
    [SCH, envR1, envR2, envR3, Menv1, Menv2] = SCH.step(SCH, dt);

    SCH.M1 = SCH.M1.tick(SCH.M1, Menv1, dt);
    SCH.M2 = SCH.M2.tick(SCH.M2, Menv2, dt);

    [R1, ev1] = R1.tick(R1, envR1, dt);
    [R2, ev2] = R2.tick(R2, envR2, dt);
    [R3, ev3] = R3.tick(R3, envR3, dt);

    % KPI
    k = kpi_update(k, ev1, ev2, ev3, R1, R2, R3, SCH.M1, SCH.M2, SCH, dt, t);

    if C.showPlots
        animate_step(viz, C, SCH.belt, SCH.M1, SCH.M2, R1, R2, R3, SCH.inBuf, SCH.outBuf, SCH.shipped, t);
    end
    t = t + dt;
end

K = kpi_finalize(k);

% --- Demo-CSV in erwarteter Form (für run_all Demo-Summary) ---
% Felder: throughput / Tsim / util_R1/2/3
T_demo = table( ...
    K.throughputPM, C.Tsim, ...
    K.util_robot(1), K.util_robot(2), K.util_robot(3), ...
    'VariableNames', {'throughput','Tsim','util_R1','util_R2','util_R3'} ...
);
ts = char(datetime("now","Format","yyyyMMdd_HHmmss"));
demoCsv = fullfile(outDir, ['factory_kpi_' ts '.csv']);
writetable(T_demo, demoCsv);

% --- Vollständigen KPI-Satz exportieren ---
paths = export_kpi(K, outDir, 'factory');

S = struct('kpi',K,'paths',paths,'demoCsv',demoCsv);
end