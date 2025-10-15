function R = fsm_robot(name, C)
% FSM_ROBOT – Zustandsautomat für Roboter mit neuer Scheduler-API (on_pick/on_place)
%
%   R = fsm_robot("R1", C)
%
% Autor: Mohamad Hamza Mehmalat
% Stand: 2025-10-15

%% Initialisierung
R.name         = string(name);
R.state        = "idle";
R.timer        = 0.0;
R.hasPart      = false;
R.part         = [];
R.t_action     = C.rob_action_time;
R.t_move       = C.rob_move_time;
R.stats.active = 0;
R.stats.idle   = 0;

%% Methode
R.tick = @tick;

    function [R2, event] = tick(R1, env, dt)
        event = "";

        switch R1.state

            % ============================================================
            % IDLE
            % ============================================================
            case "idle"
                canPickNow = false;

                % --- ⚡ Flexible Prüfung auf Input ---
                if isfield(env, 'can_pick')
                    canPickNow = logical(env.can_pick);
                elseif isfield(env, 'inBuf')
                    try
                        if isfield(env.inBuf,'count') && isa(env.inBuf.count,'function_handle')
                            canPickNow = env.inBuf.count(env.inBuf) > 0;
                        elseif isfield(env.inBuf,'q') && iscell(env.inBuf.q)
                            canPickNow = ~isempty(env.inBuf.q);
                        elseif isfield(env.inBuf,'data') && iscell(env.inBuf.data)
                            canPickNow = ~isempty(env.inBuf.data);
                        end
                    catch
                        canPickNow = false;
                    end
                end

                % --- ⚡ Verbesserte Startbedingung ---
                if canPickNow || (strcmp(R1.name,"R1") && rand < 0.05)
                    R1.state = "move_in";
                    R1.timer = R1.t_move;
                    event = sprintf("[%s] move_in", R1.name);
                end


            % ============================================================
            % MOVE_IN
            % ============================================================
            case "move_in"
                R1.timer = R1.timer - dt;
                if R1.timer <= 0
                    part = [];

                    % ⚡ Primäre API
                    if isfield(env, 'on_pick') && isa(env.on_pick, 'function_handle')
                        part = env.on_pick();
                    elseif isfield(env,'inBuf')
                        try
                            if isfield(env.inBuf,'pop')
                                [env.inBuf, part, ok] = env.inBuf.pop(env.inBuf);
                                if ~ok, part = []; end
                            elseif isfield(env.inBuf,'q') && ~isempty(env.inBuf.q)
                                part = env.inBuf.q{1};
                                env.inBuf.q(1) = [];
                            end
                        catch
                            part = [];
                        end
                    end

                    % ⚡ Falls kein Teil vorhanden, trotzdem weiter versuchen
                    if ~isempty(part)
                        R1.part = part;
                        R1.hasPart = true;
                        R1.state = "pick";
                        R1.timer = R1.t_action;
                        event = sprintf("[%s] pick_start", R1.name);
                    else
                        R1.state = "idle";
                    end
                end


            % ============================================================
            % PICK
            % ============================================================
            case "pick"
                R1.timer = R1.timer - dt;
                if R1.timer <= 0
                    R1.state = "move_to_target";
                    R1.timer = R1.t_move;
                    event = sprintf("[%s] pick_done", R1.name);
                end


            % ============================================================
            % MOVE_TO_TARGET
            % ============================================================
            case "move_to_target"
                R1.timer = R1.timer - dt;
                if R1.timer <= 0
                    R1.state = "place";
                    R1.timer = R1.t_action;
                    event = sprintf("[%s] arrived_target", R1.name);
                end


            % ============================================================
            % PLACE
            % ============================================================
            case "place"
                R1.timer = R1.timer - dt;
                if R1.timer <= 0 && R1.hasPart
                    ok = false;
                    try
                        if isfield(env, 'on_place') && isa(env.on_place,'function_handle')
                            ok = logical(env.on_place(R1.part));
                        end
                    catch
                        ok = false;
                    end

                    if ok
                        event      = sprintf("[%s] place_done", R1.name);
                        R1.hasPart = false;
                        R1.part    = [];
                        R1.state   = "idle";
                    else
                        event    = sprintf("[%s] place_retry", R1.name);
                        R1.state = "place";
                        R1.timer = R1.t_action;
                    end
                end
        end

        % ============================================================
        % Statistik aktualisieren
        % ============================================================
        if R1.state == "idle"
            R1.stats.idle = R1.stats.idle + dt;
        else
            R1.stats.active = R1.stats.active + dt;
        end

        R2 = R1;
    end
end