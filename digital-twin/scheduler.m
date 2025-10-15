function SCH = scheduler(C, inBuf, outBuf, belt, M1, M2)
% SCHEDULER – koppelt Quelle/Buffer/Band/Roboter/Maschinen
%   SCH = scheduler(C, inBuf, outBuf, belt, M1, M2)
%
%   Voll funktionsfähige Version für fsm_robot.m (R1, R2, R3 arbeiten korrekt)
%
% Autor: Mohamad Hamza Mehmalat
% Datum: 2025-10-15 (überarbeitet)

% --- Aggregat-Struct -----------------------------------------------------
SCH = struct();
SCH.inBuf   = inBuf;     % Eingangspuffer
SCH.outBuf  = outBuf;    % Ausgangspuffer
SCH.belt    = belt;      % Förderband
SCH.M1      = M1;        % Maschine 1
SCH.M2      = M2;        % Maschine 2
SCH.shipped = 0;         % Zähler versendeter Teile
SCH.step    = @step;

    function [SCH2, envR1, envR2, envR3, Menv1, Menv2] = step(SCH1, dt)
        SCH2 = SCH1;

        %% --- (1) Förderband-Update ------------------------------------
        if isfield(SCH2.belt,'step')
            SCH2.belt = SCH2.belt.step(SCH2.belt, dt);
        end

      %% --- (2) Maschinenumgebungen ----------------------------------
Menv1 = struct('role',"machine_1");
Menv2 = struct('role',"machine_2");

% ============================================================
% Maschine 1
% ============================================================
if ~isfield(SCH2.M1,'busy')
    SCH2.M1.busy = SCH2.M1.is_busy;
end

if ~isfield(SCH2.M1,'is_free')
    SCH2.M1.is_free = ~SCH2.M1.is_busy;
end

% ✅ has_done als Funktionshandle definieren (nicht als logischer Wert!)
if ~isfield(SCH2.M1,'has_done') || ~isa(SCH2.M1.has_done,'function_handle')
    SCH2.M1.has_done = @(M) (isfield(M,'done_flag') && M.done_flag);
end

% ============================================================
% Maschine 2
% ============================================================
if ~isfield(SCH2.M2,'busy')
    SCH2.M2.busy = SCH2.M2.is_busy;
end

if ~isfield(SCH2.M2,'is_free')
    SCH2.M2.is_free = ~SCH2.M2.is_busy;
end

% ✅ has_done als Funktionshandle definieren (nicht als logischer Wert!)
if ~isfield(SCH2.M2,'has_done') || ~isa(SCH2.M2.has_done,'function_handle')
    SCH2.M2.has_done = @(M) (isfield(M,'done_flag') && M.done_flag);
end
        %% --- (3) Dynamische Statuslogik -------------------------------
        x1 = C.stations_pos(1);

        has_part_on_belt = false;
        if isfield(SCH2.belt,'can_pick')
            has_part_on_belt = SCH2.belt.can_pick(SCH2.belt, x1);
        end

        is_M1_free = SCH2.M1.is_free;
        has_done_M2 = SCH2.M2.has_done;

        %% --- (4) Roboter-Umgebungen definieren ------------------------

        % 🔹 R1: Quelle -> Band
        envR1 = struct( ...
            'role',      "supply", ...
            'inBuf',     SCH2.inBuf, ...
            'can_pick',  has_any(SCH2.inBuf), ...
            'can_place', true, ...
            'on_pick',   @on_pick_from_inbuf, ...
            'on_place',  @on_place_to_belt_start);

        % 🔹 R2: Band -> Maschine 1
        envR2 = struct( ...
            'role',      "load_M1", ...
            'can_pick',  has_part_on_belt, ...
            'can_place', is_M1_free, ...
            'on_pick',   @() on_pick_from_belt_at(x1), ...
            'on_place',  @on_place_to_machine1);

        % 🔹 R3: Maschine 2 -> OutBuf
        envR3 = struct( ...
            'role',      "unload_M2", ...
            'can_pick',  has_done_M2, ...
            'can_place', true, ...
            'on_pick',   @on_pick_from_machine2, ...
            'on_place',  @on_place_to_outbuf);

        %% --- (5) Callbacks (Funktionen für Roboteraktionen) -----------

        % Quelle → Band
        function part = on_pick_from_inbuf()
            part = [];
            try
                if isfield(SCH2.inBuf,'pop')
                    [SCH2.inBuf, part, ok] = SCH2.inBuf.pop(SCH2.inBuf);
                    if ~ok, part = []; end
                elseif isfield(SCH2.inBuf,'q') && ~isempty(SCH2.inBuf.q)
                    part = SCH2.inBuf.q{1};
                    SCH2.inBuf.q(1) = [];
                end
            catch ME
                warning(ME.identifier, '%s', ME.message);
            end
        end

        function ok = on_place_to_belt_start(part)
            ok = false;
            try
                if isempty(part), return; end
                SCH2.belt = SCH2.belt.load(SCH2.belt, part);
                ok = true;
            catch ME
                warning(ME.identifier, '%s', ME.message);
            end
        end

        % Band → Maschine 1
        function part = on_pick_from_belt_at(x_at)
            part = [];
            try
                if SCH2.belt.can_pick(SCH2.belt, x_at)
                    [SCH2.belt, part] = SCH2.belt.take(SCH2.belt, x_at);
                end
            catch ME
                warning(ME.identifier, '%s', ME.message);
            end
        end

        function ok = on_place_to_machine1(part)
            ok = false;
            try
                if isempty(part), return; end
                if isfield(SCH2.M1,'load_part')
                    [SCH2.M1, ok] = SCH2.M1.load_part(SCH2.M1, part);
                end
            catch ME
                warning(ME.identifier, '%s', ME.message);
            end
        end

        % Maschine 2 → OutBuf
        function part = on_pick_from_machine2()
            part = [];
            try
                if isfield(SCH2.M2,'has_done') && SCH2.M2.has_done
                    [SCH2.M2, part] = SCH2.M2.unload_part(SCH2.M2);
                end
            catch ME
                warning(ME.identifier, '%s', ME.message);
            end
        end

        function ok = on_place_to_outbuf(part)
            ok = false;
            try
                if isempty(part), return; end
                if isfield(SCH2.outBuf,'push')
                    SCH2.outBuf = SCH2.outBuf.push(SCH2.outBuf, part);
                    SCH2.shipped = SCH2.shipped + 1;
                    ok = true;
                end
            catch ME
                warning(ME.identifier, '%s', ME.message);
            end
        end

    end % Ende Step
end % Ende Scheduler

% ---------------------- Helper ------------------------------------------
function tf = has_any(buf)
tf = false;
try
    if isfield(buf,'count') && isa(buf.count,'function_handle')
        tf = buf.count(buf) > 0;
    elseif isfield(buf,'q') && iscell(buf.q)
        tf = ~isempty(buf.q);
    elseif isfield(buf,'data') && iscell(buf.data)
        tf = ~isempty(buf.data);
    end
catch
    tf = false;
end
end