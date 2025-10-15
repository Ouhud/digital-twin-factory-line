function k = kpi_update(k, ev1, ev2, ev3, R1, R2, R3, M1, M2, SCH, dt, t)
% KPI_UPDATE – sammelt und aktualisiert Kennzahlen je Simulationsschritt
%
% Autor: Hamza Mehmalat
% Version: 1.0
% Datum: 2025-10-14
%
% Aufgaben:
%   - Zählt Picks / Places / Shipped Teile
%   - Summiert aktive & Idle-Zeiten der Roboter (R1–R3)
%   - Erfasst Maschinen-Auslastung
%   - Berechnet aktuelle prozentuale Utilization je Roboter

% -------------------------------------------------------------------------
% 1. Initialisierung (falls k leer ist)
% -------------------------------------------------------------------------
if ~isstruct(k) || ~isfield(k,'t')
    k = kpi_init();
end

% Zeitschritt hochzählen
k.t = k.t + dt;

% -------------------------------------------------------------------------
% 2. Picks / Places zählen
% -------------------------------------------------------------------------
events = {ev1, ev2, ev3};
for i = 1:3
    evi = events{i};
    if isstruct(evi)
        if isfield(evi,'picked') && evi.picked, k.picked = k.picked + 1; end
        if isfield(evi,'placed') && evi.placed, k.placed = k.placed + 1; end
    end
end

% -------------------------------------------------------------------------
% 3. Shipped-Status aus Scheduler übernehmen
% -------------------------------------------------------------------------
if isstruct(SCH) && isfield(SCH,'shipped')
    k.shipped = SCH.shipped;
else
    k.shipped = k.placed;
end
k.throughput_ts(end+1,:) = [t, k.shipped]; %#ok<AGROW>

% -------------------------------------------------------------------------
% 4. Maschinen-Auslastung
% -------------------------------------------------------------------------
if isstruct(M1) && isfield(M1,'state') && M1.state == "Process"
    k.util_machine(1) = k.util_machine(1) + dt;
end
if isstruct(M2) && isfield(M2,'state') && M2.state == "Process"
    k.util_machine(2) = k.util_machine(2) + dt;
end

% -------------------------------------------------------------------------
% 5. Roboter-Auslastung (bestehend + erweitert)
% -------------------------------------------------------------------------
robots = {'R1','R2','R3'};
R = {R1, R2, R3};

for i = 1:3
    name = robots{i};
    Ri   = R{i};

    % Sicherheitscheck
    if ~isstruct(Ri) || ~isfield(Ri,'state'), continue; end

    % Initialisiere Felder bei Bedarf
    if ~isfield(k,[name '_active']), k.([name '_active']) = 0; end
    if ~isfield(k,[name '_idle']),   k.([name '_idle'])   = 0; end

    % Zähle aktive / Idle-Zeit
    switch string(Ri.state)
        case {"Pick","Place","MovePick","MovePlace"}
            k.([name '_active']) = k.([name '_active']) + dt;
        otherwise
            k.([name '_idle'])   = k.([name '_idle'])   + dt;
    end

    % Summiere auch im klassischen Format
    if i <= numel(k.util_robot)
        if Ri.state ~= "Idle"
            k.util_robot(i) = k.util_robot(i) + dt;
        end
    end
end

% -------------------------------------------------------------------------
% 6. Berechne aktuelle Utilization [%] pro Roboter
% -------------------------------------------------------------------------
for i = 1:3
    name = robots{i};
    if isfield(k,[name '_active']) && isfield(k,[name '_idle'])
        total = k.([name '_active']) + k.([name '_idle']);
        if total > 0
            k.([name '_util']) = 100 * k.([name '_active']) / total;
        else
            k.([name '_util']) = NaN;
        end
    else
        k.([name '_util']) = NaN;
    end
end

% -------------------------------------------------------------------------
% 7. Optionale Miss-Zählung (noch nicht aktiv)
% -------------------------------------------------------------------------
% k.pickMiss = k.pickMiss + ...
end