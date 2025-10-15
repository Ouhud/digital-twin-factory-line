function S = simulate_factory_line_2belts(opts)
% SIMULATE_FACTORY_LINE_2BELTS – 2 Förderbänder, 2 Maschinen, 3 Roboter
% Band A: allgemeiner Zuführer, Band B: Zusatzlinie (z.B. andere Teile)

arguments
    opts.Tsim double = 60
    opts.dt   double = 0.05
    opts.showPlots logical = true
    opts.show3D    logical = false
    opts.spawn_rate_A double = 0.5
    opts.spawn_rate_B double = 0.4
    opts.belt_speed_A double = 0.30
    opts.belt_speed_B double = 0.25
    opts.machine_Tproc (1,2) double = [4.0 5.0]
    opts.outDir = []
end

% Konfiguration (wir nutzen C für Layout/Zeiten; zwei Bänder separat)
C = config('Tsim',opts.Tsim,'dt',opts.dt, ...
           'spawn_rate',opts.spawn_rate_A, 'belt_speed',opts.belt_speed_A, ...
           'machine_Tproc',opts.machine_Tproc, 'showPlots',opts.showPlots, 'show3D',opts.show3D);

root = fileparts(mfilename('fullpath')); proj = fileparts(root);
outDir = opts.outDir; if isempty(outDir), outDir = fullfile(proj,'out'); end
if ~exist(outDir,'dir'), mkdir(outDir); end

% Quellen/Bänder
srcA = material_source(opts.spawn_rate_A);
srcB = material_source(opts.spawn_rate_B);
inA  = buffer_store(inf,"inA"); inB = buffer_store(inf,"inB");
beltA= conveyor_model(C.belt_len, opts.belt_speed_A, C.stations_pos);
beltB= conveyor_model(C.belt_len, opts.belt_speed_B, C.stations_pos);

% Maschinen/Roboter
M1 = fsm_machine(1, C.machine_Tproc(1));
M2 = fsm_machine(2, C.machine_Tproc(2));
R1 = fsm_robot("R1", C);  % bedient A/B → legt auf A oder B (simple Policy)
R2 = fsm_robot("R2", C);
R3 = fsm_robot("R3", C);

% Einfacher Scheduler für 2 Bänder (wir "multiplexen" band_arrivals)
SCH = scheduler(C, buffer_store(inf,"in"), buffer_store(inf,"out"), beltA, M1, M2);
% zweites Band legen wir in SCH2 (nur für Arrivals)
SCH2= scheduler(C, buffer_store(inf,"in2"), buffer_store(inf,"out2"), beltB, M1, M2);

% Visualisierung (wir verwenden die gleiche 2D-Szene)
viz = [];
if C.showPlots
    viz = draw_scene_2d(C);
    if C.show3D, draw_scene_3d(C); end
end

k = kpi_init(); t=0; dt=C.dt;
while t < C.Tsim
    % Spawns
    [srcA, inA] = material_source_step(srcA, inA, dt);
    [srcB, inB] = material_source_step(srcB, inB, dt);

    % R1 verteilt abwechselnd auf A/B zu Bandstart
    if ~inA.is_empty(inA)
        [inA, partA, ok] = inA.pop(inA); if ok, beltA = beltA.load(beltA, partA); end
    end
    if ~inB.is_empty(inB)
        [inB, partB, ok] = inB.pop(inB); if ok, beltB = beltB.load(beltB, partB); end
    end

    % Beide Bänder updaten → Arrivals sammeln
    [beltA, arrA] = beltA.step(beltA, dt);
    [beltB, arrB] = beltB.step(beltB, dt);
    SCH.band_arrivals = arrA; SCH.belt = beltA;
    SCH2.band_arrivals= arrB; SCH2.belt= beltB;

    % Maschinen laden, wenn Ready (aus A oder B, Priorität A)
    Menv1 = struct('part_loaded', false, 'part_removed', false);
    Menv2 = struct('part_loaded', false, 'part_removed', false);
    if M1.state=="Ready" && (~isempty(arrA{1}) || ~isempty(arrB{1})), Menv1.part_loaded=true; end
    if M2.state=="Ready" && (~isempty(arrA{2}) || ~isempty(arrB{2})), Menv2.part_loaded=true; end

    % Maschinen ticken
    M1 = M1.tick(M1, Menv1, dt); M2 = M2.tick(M2, Menv2, dt);

    % R2 sammelt fertige von M1/M2 → wir simulieren Platzieren in out
    envR2 = struct('role',"collect",'can_pick',(M1.state=="Done"&&M1.has_part)||(M2.state=="Done"&&M2.has_part),'can_place',true);
    envR2.on_pick = @() pick_from_machines();
    envR2.on_place= @(p) true; %#ok<NASGU>
    [R2, ev2] = R2.tick(R2, envR2, dt);

    % R3 shipped (hier: shipped = Anzahl ev2.placed kumulativ)
    % Für Demo: R3-Events nur „kosmetisch"
    envR3 = struct('role',"ship",'can_pick',false,'can_place',true);
    [R3, ev3] = R3.tick(R3, envR3, dt); %#ok<NASGU>

    % R1 kosmetisch:
    envR1 = struct('role',"supply",'can_pick',false,'can_place',true);
    [R1, ev1] = R1.tick(R1, envR1, dt); %#ok<NASGU>

    % KPI (schätzen shipped als Summe Placed von R2)
    persistent shipped; if isempty(shipped), shipped = 0; end
    if ev2.placed, shipped = shipped + 1; end
    SCH.shipped = shipped; SCH.M1=M1; SCH.M2=M2;
    k = kpi_update(k, ev1, ev2, ev3, R1, R2, R3, M1, M2, SCH, dt, t);

    if C.showPlots
        % wir zeigen nur Band A Items
        SCH.belt = beltA;
        animate_step(viz, C, SCH.belt, M1, M2, R1, R2, R3, SCH.inBuf, SCH.outBuf, shipped, t);
    end
    t=t+dt;
end

K = kpi_finalize(k);

% Demo-CSV
T_demo = table( K.throughputPM, C.Tsim, K.util_robot(1), K.util_robot(2), K.util_robot(3), ...
   'VariableNames', {'throughput','Tsim','util_R1','util_R2','util_R3'} );
ts = char(datetime("now","Format","yyyyMMdd_HHmmss"));
demoCsv = fullfile(outDir, ['factory2belts_kpi_' ts '.csv']);
writetable(T_demo, demoCsv);

paths = export_kpi(K, outDir, 'factory2belts');
S = struct('kpi',K,'paths',paths,'demoCsv',demoCsv);

    function part = pick_from_machines()
        if M1.state=="Done" && M1.has_part, M1.has_part=false; part=struct('id',-1); return; end
        if M2.state=="Done" && M2.has_part, M2.has_part=false; part=struct('id',-2); return; end
        part = false;
    end
end