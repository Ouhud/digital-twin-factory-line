function S = simulate_factory_line_2stores(opts)
% SIMULATE_FACTORY_LINE_2STORES – 1 Band, 2 Maschinen, 3 Roboter, 2 Ausgangslager

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

C = config('Tsim',opts.Tsim,'dt',opts.dt, ...
           'spawn_rate',opts.spawn_rate, 'belt_speed',opts.belt_speed, ...
           'machine_Tproc',opts.machine_Tproc, 'showPlots',opts.showPlots, 'show3D',opts.show3D);

root = fileparts(mfilename('fullpath')); proj = fileparts(root);
outDir = opts.outDir; if isempty(outDir), outDir = fullfile(proj,'out'); end
if ~exist(outDir,'dir'), mkdir(outDir); end

src   = material_source(C.spawn_rate);
inBuf = buffer_store(inf,"in"); outA = buffer_store(inf,"outA"); outB = buffer_store(inf,"outB");
belt  = conveyor_model(C.belt_len, C.belt_speed, C.stations_pos);
M1    = fsm_machine(1, C.machine_Tproc(1));
M2    = fsm_machine(2, C.machine_Tproc(2));
R1    = fsm_robot("R1", C); R2 = fsm_robot("R2", C); R3 = fsm_robot("R3", C);

viz = []; if C.showPlots, viz = draw_scene_2d(C); if C.show3D, draw_scene_3d(C); end, end

k = kpi_init(); t=0; dt=C.dt; shippedA=0; shippedB=0;

while t < C.Tsim
    [src, inBuf] = material_source_step(src, inBuf, dt);
    belt = belt.load(belt, try_pop(inBuf)); % lege Teil (falls vorhanden) auf

    [belt, arr] = belt.step(belt, dt);
    Menv1 = struct('part_loaded', false, 'part_removed', false);
    Menv2 = struct('part_loaded', false, 'part_removed', false);
    if M1.state=="Ready" && ~isempty(arr{1}), Menv1.part_loaded=true; end
    if M2.state=="Ready" && ~isempty(arr{2}), Menv2.part_loaded=true; end

    M1 = M1.tick(M1, Menv1, dt); M2 = M2.tick(M2, Menv2, dt);

    % R2 nimmt fertige: M1 → outA, M2 → outB
    envR2 = struct('role',"collect",'can_pick',(M1.state=="Done"&&M1.has_part)||(M2.state=="Done"&&M2.has_part),'can_place',true);
    envR2.on_pick = @() pick_from_machines();
    envR2.on_place= @(part) place_by_origin(part);
    [R2, ev2] = R2.tick(R2, envR2, dt);

    % R3 versendet alternierend aus A und B (hier: Summe für shipped)
    envR3 = struct('role',"ship",'can_pick',~outA.is_empty(outA) || ~outB.is_empty(outB), 'can_place',true);
    envR3.on_pick = @() pick_from_outs();
    envR3.on_place= @(p) true;
    [R3, ev3] = R3.tick(R3, envR3, dt); %#ok<NASGU>

    envR1 = struct('role',"supply",'can_pick',false,'can_place',true);
    [R1, ev1] = R1.tick(R1, envR1, dt); %#ok<NASGU>

    % KPI: shippedA/B addieren
    SCH = struct('shipped', shippedA+shippedB, 'M1', M1, 'M2', M2, 'belt', belt, 'inBuf', inBuf, 'outBuf', outA); %#ok<NASGU>
    k = kpi_update(k, ev1, ev2, ev3, R1, R2, R3, M1, M2, SCH, dt, t);

    if C.showPlots
        tmpOut = buffer_store(inf,"tmp"); % für Anzeige egal
        animate_step(viz, C, belt, M1, M2, R1, R2, R3, inBuf, tmpOut, shippedA+shippedB, t);
    end
    t=t+dt;
end

K = kpi_finalize(k);
T_demo = table( K.throughputPM, C.Tsim, K.util_robot(1), K.util_robot(2), K.util_robot(3), ...
   'VariableNames', {'throughput','Tsim','util_R1','util_R2','util_R3'} );
ts = char(datetime("now","Format","yyyyMMdd_HHmmss"));
demoCsv = fullfile(outDir, ['factory_2stores_kpi_' ts '.csv']);
writetable(T_demo, demoCsv);

paths = export_kpi(K, outDir, 'factory_2stores');
S = struct('kpi',K,'paths',paths,'demoCsv',demoCsv);

    % --- lokale Helfer ---
    function part = try_pop(buf)
        [buf2, part, ok] = buf.pop(buf); inBuf = buf2; if ~ok, part=[]; end %#ok<NASGU>
    end
    function part = pick_from_machines()
        if M1.state=="Done" && M1.has_part, M1.has_part=false; part = struct('id',-1,'origin','M1'); return; end
        if M2.state=="Done" && M2.has_part, M2.has_part=false; part = struct('id',-2,'origin','M2'); return; end
        part = false;
    end
    function ok = place_by_origin(part)
        if ~isstruct(part), ok=false; return; end
        if isfield(part,'origin') && strcmp(part.origin,'M1')
            outA = outA.push(outA, part); ok=true;
        elseif isfield(part,'origin') && strcmp(part.origin,'M2')
            outB = outB.push(outB, part); ok=true;
        else
            ok=false;
        end
    end
    function part = pick_from_outs()
        persistent sel; if isempty(sel), sel = 0; end
        sel = 1 - sel; % alterniere A/B
        if sel==0 && ~outA.is_empty(outA)
            [outA, part, ok] = outA.pop(outA); if ok, shippedA=shippedA+1; return; end
        end
        if ~outB.is_empty(outB)
            [outB, part, ok] = outB.pop(outB); if ok, shippedB=shippedB+1; return; end
        end
        part = false;
    end
end