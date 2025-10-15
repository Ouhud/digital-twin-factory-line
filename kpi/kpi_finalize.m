function kout = kpi_finalize(k)
% KPI_FINALIZE – fasst alle KPI-Daten nach der Simulation zusammen
% Kompatibel mit erweitertem KPI-System (R1–R3, Maschinen, Durchsatz)
%
% Autor: Hamza Mehmalat
% Version: 1.0
% Datum: 2025-10-14

% -------------------------------------------------------------------------
% 1. Basis: Gesamtlaufzeit (Sekunden)
% -------------------------------------------------------------------------
T = max(1e-6, k.t);  % Schutz gegen Division durch 0

% -------------------------------------------------------------------------
% 2. Basisdaten
% -------------------------------------------------------------------------
kout = struct();
kout.picked   = k.picked;
kout.placed   = k.placed;
kout.shipped  = k.shipped;
kout.pickMiss = k.pickMiss;

% -------------------------------------------------------------------------
% 3. Erfolgsrate & Durchsatz
% -------------------------------------------------------------------------
kout.successRate  = k.placed / max(1, k.picked);   % Verhältnis Place/Pick
kout.outputRatePS = kout.shipped / T;              % Teile pro Sekunde
kout.throughputPM = kout.outputRatePS * 60;        % Teile pro Minute

% -------------------------------------------------------------------------
% 4. Roboter- und Maschinen-Auslastung
% -------------------------------------------------------------------------
% Gesamtzeitliche Duty-Cycles (0–1)
if isfield(k,'util_robot')
    kout.util_robot = k.util_robot ./ T;
else
    kout.util_robot = [NaN NaN NaN];
end

if isfield(k,'idle_robot')
    kout.idle_robot = k.idle_robot ./ T;
else
    kout.idle_robot = [NaN NaN NaN];
end

if isfield(k,'util_machine')
    kout.util_machine = k.util_machine ./ T;
else
    kout.util_machine = [NaN NaN];
end

% -------------------------------------------------------------------------
% 5. Detaillierte Roboteranalyse (R1–R3)
% -------------------------------------------------------------------------
for i = 1:3
    name = sprintf('R%d', i);
    actField  = [name '_active'];
    idleField = [name '_idle'];

    if isfield(k, actField) && isfield(k, idleField)
        act  = k.(actField);
        idle = k.(idleField);
        total = act + idle;
        if total > 0
            kout.([name '_util']) = 100 * act / total; % Prozent
        else
            kout.([name '_util']) = NaN;
        end
        kout.([name '_active']) = act;
        kout.([name '_idle'])   = idle;
    else
        kout.([name '_util']) = NaN;
        kout.([name '_active']) = 0;
        kout.([name '_idle']) = 0;
    end
end

% -------------------------------------------------------------------------
% 6. Verfügbarkeit (Heuristik)
% -------------------------------------------------------------------------
busy = nansum(kout.util_robot);
nrobots = sum(~isnan(kout.util_robot));
if nrobots > 0
    kout.availability = busy / nrobots;  % Durchschnittliche Aktivität
else
    kout.availability = NaN;
end

% -------------------------------------------------------------------------
% 7. Zeitreihe & Meta-Daten
% -------------------------------------------------------------------------
if isfield(k,'throughput_ts')
    kout.throughput_ts = k.throughput_ts;
else
    kout.throughput_ts = [];
end

if isfield(k,'meta')
    kout.meta = k.meta;
else
    kout.meta = struct();
end
kout.meta.finalized = datetime('now','Format','yyyy-MM-dd HH:mm:ss');
kout.meta.totalTime_s = T;

end