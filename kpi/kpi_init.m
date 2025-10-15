function k = kpi_init()
% KPI_INIT – Initialisiert alle Kennzahlenfelder für den Digital Twin
% Kompatibel mit erweitertem kpi_update.m (inkl. R1–R3-Details)

% -------------------------------------------------------------------------
% 1. Basiswerte
% -------------------------------------------------------------------------
k = struct();
k.t = 0;             % Simulationszeit (Sekunden)
k.picked   = 0;      % Anzahl aufgenommener Teile
k.placed   = 0;      % Anzahl abgelegter Teile
k.shipped  = 0;      % Anzahl ausgelieferter Teile
k.pickMiss = 0;      % Fehlgriffe (optional)

% -------------------------------------------------------------------------
% 2. Zeitreihen
% -------------------------------------------------------------------------
k.throughput_ts = zeros(0,2);  % [Zeit, Ausgelieferte Teile]

% -------------------------------------------------------------------------
% 3. Maschinen und Roboter – Busy-Zeiten
% -------------------------------------------------------------------------
k.util_robot   = [0 0 0];  % Sekunden aktiv (R1..R3)
k.idle_robot   = [0 0 0];  % Sekunden im Idle
k.util_machine = [0 0];    % Sekunden aktiv (M1..M2)

% -------------------------------------------------------------------------
% 4. Detaillierte Kennzahlen für jeden Roboter
% -------------------------------------------------------------------------
k.R1_active = 0; k.R1_idle = 0; k.R1_util = 0;
k.R2_active = 0; k.R2_idle = 0; k.R2_util = 0;
k.R3_active = 0; k.R3_idle = 0; k.R3_util = 0;

% -------------------------------------------------------------------------
% 5. Metadaten (optional)
% -------------------------------------------------------------------------
k.meta = struct( ...
    'created', datetime('now','Format','yyyy-MM-dd HH:mm:ss'), ...
    'author', 'Hamza Mehmalat', ...
    'version', '1.0', ...
    'source', 'Digital Twin – KPI System' ...
);

% 🩹 Fallback für alte Simulationen
if ~isfield(k, 'rob_action_time')
    k.rob_action_time = 0;
end

end