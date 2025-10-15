function M = fsm_machine(id, Tproc)
% FSM_MACHINE – Zustandsautomat für Maschine (kompatibel mit FSM-Robot)
%
%   M = fsm_machine(id, Tproc)
%
% Zustände: "idle" -> "processing" -> "done"
% Robuste API (immer verfügbar):
%   M.is_busy          : logical
%   M.has_done(M)      : function_handle -> logical
%   [M, ok] = M.load(M, part)     % Teil annehmen/starten
%   [M, part] = M.unload(M)       % fertiges Teil ausgeben (nur wenn done)
%   M = M.tick(M, env, dt)        % Prozessschritt (env wird aktuell nicht genutzt)
%
% Autor: Mohamad Hamza Mehmalat
% Stand: 2025-10-15
% -------------------------------------------------------------------------

%% Grundzustand
M.id      = id;
M.state   = "idle";
M.timer   = 0.0;
M.part    = [];
M.Tproc   = Tproc;

% Flags
M.is_busy   = false;   % Maschine belegt?
M.done_flag = false;   % fertig zur Abgabe?

% Statistik
M.stats.active = 0;
M.stats.idle   = 0;

% Methoden (öffentliche API)
M.tick      = @tick;
M.has_done  = @(X) (isfield(X,'done_flag') && X.done_flag);
M.load      = @load_part;
M.unload    = @unload_part;

% =========================
% TICK – Zeitfortschritt
% =========================
    function M2 = tick(M1, ~, dt)
        % Prozessmodell
        switch M1.state
            case "idle"
                % nichts tun

            case "processing"
                M1.timer = M1.timer - dt;
                if M1.timer <= 0
                    M1.state     = "done";
                    M1.is_busy   = false;
                    M1.done_flag = true;
                    M1.timer     = 0.0;
                end

            case "done"
                % warten auf Abholung
        end

        % Statistik
        if M1.state == "idle"
            M1.stats.idle = M1.stats.idle + dt;
        else
            M1.stats.active = M1.stats.active + dt;
        end

        M2 = M1;
    end

% =========================================
% LOAD – Teil übernehmen & Bearbeitung starten
% =========================================
    function [M2, ok] = load_part(M1, part)
        ok = false;
        M2 = M1;
        if nargin < 2 || isempty(part), return; end
        if M1.state == "idle"
            M2.part      = part;
            M2.state     = "processing";
            M2.is_busy   = true;
            M2.done_flag = false;
            M2.timer     = M1.Tproc;
            ok = true;
        end
    end

% =========================================
% UNLOAD – fertiges Teil ausgeben (nur wenn done)
% =========================================
    function [M2, part] = unload_part(M1)
        part = [];
        M2 = M1;
        if M1.state == "done" && M1.done_flag
            part        = M1.part;
            M2.part     = [];
            M2.state    = "idle";
            M2.is_busy  = false;
            M2.done_flag= false;
            M2.timer    = 0.0;
        end
    end
end