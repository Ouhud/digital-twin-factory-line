function S = simulate_factory_line_3R2M(varargin)
% SIMULATE_FACTORY_LINE_3R2M – Simulation mit 3 Robotern, 2 Maschinen, 2D/3D-Szene
% INBUF → R1 → BAND → R2 → (M1/M2) → OUTBUF → R3 (Ship)
% Autor : Mohamad Hamza Mehmalat

% --- Standardwerte ---
defaults = struct( ...
    'Tsim', 90, ...
    'dt', 0.05, ...
    'showPlots', true, ...
    'show3D', true, ...
    'spawn_rate', 0.6, ...
    'belt_speed', 0.30, ...
    'machine_Tproc', [5.0 6.0], ...
    'outDir', [] ...
);

% --- Eingaben verarbeiten ---
args = varargin;   % Kopie von varargin machen (Pflicht in MATLAB)
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

% --- Konfiguration laden ---
C = config( ...
    'Tsim', opts.Tsim, ...
    'dt', opts.dt, ...
    'spawn_rate', opts.spawn_rate, ...
    'belt_speed', opts.belt_speed, ...
    'machine_Tproc', opts.machine_Tproc, ...
    'showPlots', opts.showPlots, ...
    'show3D', opts.show3D ...
);

% --- Sicherheitsprüfung ---
if ~isstruct(C) || ~isfield(C,'dt')
    error('Config file did not return expected parameters. Prüfe Pfad zu config.m!');
end

%% ------------------------------------------------------------------------
% 3. Szenen-Layout / Geometrie definieren
% ------------------------------------------------------------------------
if ~isfield(C,'belt_len'),     C.belt_len     = 2.0;             end
if ~isfield(C,'stations_pos'), C.stations_pos = [0.5 1.2 1.8];   end
if ~isfield(C,'machine_pos'),  C.machine_pos  = [1.4 1.6];       end
if ~isfield(C,'in_buf_pos'),   C.in_buf_pos   = 0.1;             end
if ~isfield(C,'out_buf_pos'),  C.out_buf_pos  = 1.9;             end

% --- ab hier folgt dein bisheriger Simulationscode ---

%% --- Ausgabeverzeichnis --------------------------------------------------
root  = fileparts(mfilename('fullpath'));
proj  = fileparts(root);
outDir = opts.outDir;
if isempty(outDir), outDir = fullfile(proj,'out'); end
if ~exist(outDir,'dir'), mkdir(outDir); end

%% --- Modelle erstellen ---------------------------------------------------
src    = material_source(C.spawn_rate);
inBuf  = buffer_store(inf,"in");
outBuf = buffer_store(inf,"out");
belt   = conveyor_model(C.belt_len, C.belt_speed, C.stations_pos);
M1     = fsm_machine(1, C.machine_Tproc(1));
M2     = fsm_machine(2, C.machine_Tproc(2));
R1     = fsm_robot("R1", C);
R2     = fsm_robot("R2", C);
R3     = fsm_robot("R3", C);

% Maschinen robust initialisieren (fehlende Felder absichern)
M1 = init_machine(M1);
M2 = init_machine(M2);

%% --- KPI & Laufvariablen -------------------------------------------------
k   = kpi_init();

% 🩹 Fallback für alte KPI-Strukturen (verhindert "rob_action_time"-Fehler)
if ~isfield(k, 'rob_action_time')
    k.rob_action_time = 0;
end

t   = 0;
dt  = C.dt;
shipped = 0;

%% --- Visualisierung vorbereiten -----------------------------------------
viz = [];
if C.showPlots
    viz = draw_scene_2d(C);
    if C.show3D, draw_scene_3d(C); end
end

%% --- Hauptschleife -------------------------------------------------------
while t < C.Tsim
    % 1) Quelle → Eingangs-Puffer
    [src, inBuf] = material_source_step(src, inBuf, dt);

    % 2) Bandbewegung
    belt = belt.step(belt, dt);

    % 3) Maschinen ticken (interne Zustände fortschreiben)
    M1 = M1.tick(M1, struct(), dt);
    M2 = M2.tick(M2, struct(), dt);

    % 4) Roboter-Umgebungen bauen
%    Hilfsprüfung: kann an Station X geladen werden (wenn API vorhanden)
canLoadBeltAt = @(pos) (isfield(belt,'can_load') && isa(belt.can_load,'function_handle') ...
                      && belt.can_load(belt,pos)) || ~isfield(belt,'can_load');

% --- R1: nimmt von IN und legt am Station-1 aufs Band
envR1.dt         = C.dt;
envR1.can_pick   = safe_bool(@() inBuf.count(inBuf) > 0, false);
envR1.can_place  = canLoadBeltAt(C.stations_pos(1));
envR1.on_pick    = @() local_pop_inbuf();
envR1.on_place   = @(part) local_put_belt(1, part);

% --- R2: nimmt am Station-2 vom Band und belädt freie Maschine (M1→M2)
envR2.dt         = C.dt;
envR2.can_pick   = safe_bool(@() belt.can_pick(belt, C.stations_pos(2)), false);
envR2.can_place  = strcmpi(string(M1.state),"Idle") || strcmpi(string(M2.state),"Idle");
envR2.on_pick    = @() local_take_belt(2);
envR2.on_place   = @(part) local_place_machine(part);

% --- R3: holt fertige Teile (M1/M2) und shipped → OUT
envR3.dt         = C.dt;
envR3.can_pick   = M1.has_done(M1) || M2.has_done(M2);
envR3.can_place  = true; % Out-Buffer nimmt immer
envR3.on_pick    = @() local_take_machine();
envR3.on_place   = @(part) local_ship(part);



    % 5) Roboter-FSMs tick
    [R1, ev1] = R1.tick(R1, envR1, dt);
    [R2, ev2] = R2.tick(R2, envR2, dt);
    [R3, ev3] = R3.tick(R3, envR3, dt);

    % 6) KPIs
    k = kpi_update(k, ev1, ev2, ev3, R1, R2, R3, M1, M2, belt, dt, t);

    % 7) Visualisierung
    if C.showPlots
        animate_step(viz, C, belt, M1, M2, R1, R2, R3, inBuf, outBuf, shipped, t);
    end

    % 8) Zeit fortschreiben
    t = t + dt;
end

%% --- KPI-Abschluss -------------------------------------------------------
K = kpi_finalize(k);

%% --- Export: CSV + Report -----------------------------------------------
ts = char(datetime("now","Format","yyyyMMdd_HHmmss"));
csvPath = fullfile(outDir, ['factory_3r2m_kpi_' ts '.csv']);

% Minimal robuste Tabelle (Feldnamen aus deinem kpi_finalize)
T = table( ...
    K.throughputPM, K.successRate, K.availability, ...
    K.util_robot(1), K.util_robot(2), K.util_robot(3), ...
    'VariableNames', {'throughputPM','successRate','availability','util_R1','util_R2','util_R3'} ...
);
writetable(T, csvPath);

% PDF Report
try
    report123(K, C, csvPath, outDir);
catch err
    % sicheres Logging von MException-Objekt
    warning(err.identifier, 'Report-Erzeugung fehlgeschlagen: %s', err.message);
end

% Rückgabe
S = struct('kpi', K, 'csv', csvPath);
fprintf('✅ Simulation abgeschlossen | CSV: %s\n', csvPath);

%% ========================================================================
%% Lokale Hilfsfunktionen
%% ========================================================================
    function M = init_machine(M)
        % Fehlende Felder ergänzen + sinnvolle Defaults
        if ~isfield(M,'state'),     M.state = "Idle";     end
        if ~isfield(M,'is_busy'),   M.is_busy = false;    end
        if ~isfield(M,'done_flag'), M.done_flag = false;  end
        if ~isfield(M,'has_done') || ~isa(M.has_done,'function_handle')
            M.has_done = @(MM) (isfield(MM,'done_flag') && MM.done_flag) || strcmpi(string(MM.state),"Done");
        end
        if ~isfield(M,'start_proc') || ~isa(M.start_proc,'function_handle')
            % Fallback: akzeptiere Teil, setze busy/Process
            M.start_proc = @(MM,part) start_proc_fallback(MM, part);
        end
        if ~isfield(M,'unload') || ~isa(M.unload,'function_handle')
            % Fallback: gebe leeres struct zurück
            M.unload = @(MM) deal(setfield(MM,'done_flag',false), struct()); %#ok<SFLD>
        end
        if ~isfield(M,'tick') || ~isa(M.tick,'function_handle')
            % Fallback: simple Taktung (für Sicherheit)
            M.tick = @(MM,~,dtt) tick_fallback(MM, dtt);
        end
    end

    function [MM2, ok] = start_proc_fallback(MM, part)
        ok = false;
        if ~strcmpi(string(MM.state),"Idle")
            MM2 = MM; return;
        end
        MM.is_busy   = true;
        MM.done_flag = false;
        MM.state     = "Process";
        if ~isfield(MM,'timer'), MM.timer = 0; end
        if ~isfield(MM,'Tproc'), MM.Tproc = 5.0; end
        MM.timer     = MM.Tproc;
        MM.current   = part;
        ok = true;
        MM2 = MM;
    end

    function MM2 = tick_fallback(MM, dtt)
        % sehr einfache Prozesslogik, falls echte tick() fehlt
        if strcmpi(string(MM.state),"Process")
            if ~isfield(MM,'timer'), MM.timer = 0; end
            MM.timer = MM.timer - dtt;
            if MM.timer <= 0
                MM.state     = "Done";
                MM.is_busy   = false;
                MM.done_flag = true;
            end
        end
        MM2 = MM;
    end

    function part = local_pop_inbuf()
        % robustes Pop aus inBuf
        part = [];
        try
            [inBuf, part, ok] = inBuf.pop(inBuf);
            if ~ok, part = []; end
        catch
            % falls API abweicht, versuche generisch
            if isfield(inBuf,'items') && ~isempty(inBuf.items)
                part = inBuf.items(1);
                inBuf.items(1) = [];
            end
        end
    end

    function ok = local_put_belt(idx, part)
        % Wichtig: Signatur belt.load(belt, part, x_at)
        ok = false;
        try
            if ~isfield(part,'pos') || ~isnumeric(part.pos)
                part.pos = 0.0;
            end
            x_at = C.stations_pos(idx);
            [belt, ok] = belt.load(belt, part, x_at);
        catch err
            warning('Belt-Load fehlgeschlagen (idx=%d): %s', idx, err.message);
            ok = false;
        end
    end

    function part = local_take_belt(idx)
        part = [];
        try
            [belt, part] = belt.take(belt, C.stations_pos(idx));
        catch
            % Fallback: naive Entnahme (wenn API abweicht)
            if isfield(belt,'items') && ~isempty(belt.items)
                part = belt.items(1);
                belt.items(1) = [];
            end
        end
    end

    function ok = local_place_machine(part)
        ok = false;
        % M1 hat Priorität, sonst M2
        if strcmpi(string(M1.state),"Idle")
            [M1, ok] = M1.start_proc(M1, part);
            return
        end
        if strcmpi(string(M2.state),"Idle")
            [M2, ok] = M2.start_proc(M2, part);
        end
    end

    function part = local_take_machine()
        part = [];
        if M1.has_done(M1)
            try
                [M1, part] = M1.unload(M1);
            catch
                % Fallback falls API anders ist
                part = safe_getfield(M1,'current',struct());
                M1.done_flag = false; M1.state = "Idle"; M1.current = [];
            end
            return
        end
        if M2.has_done(M2)
            try
                [M2, part] = M2.unload(M2);
            catch
                part = safe_getfield(M2,'current',struct());
                M2.done_flag = false; M2.state = "Idle"; M2.current = [];
            end
        end
    end

    function ok = local_ship(part)
        ok = false;
        try
            [outBuf, ok] = outBuf.push(outBuf, part);
            if ok, shipped = shipped + 1; end
        catch
            if isfield(outBuf,'items')
                outBuf.items(end+1,1) = part; %#ok<AGROW>
                ok = true; shipped = shipped + 1;
            end
        end
    end

    function v = safe_getfield(S, name, default)
        if isstruct(S) && isfield(S,name)
            v = S.(name);
        else
            v = default;
        end
    end

    function b = safe_bool(f, def)
        % führt f() sicher aus und erzwingt boolean-Rückgabe
        try
            b = logical(f());
        catch
            b = def;
        end
    end
end