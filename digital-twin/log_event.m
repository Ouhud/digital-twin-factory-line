function SCH = log_event(SCH, agent, event)
% LOG_EVENT – Einfache Protokollfunktion für Simulationsereignisse
%
%   SCH = log_event(SCH, agent, event)
%
%   agent : string ('R1', 'R2', 'R3', etc.)
%   event : string oder Struktur mit Ereignistext
%
% Erstellt ein einfaches Log im Speicher, das später exportiert werden kann.

    if nargin < 3 || isempty(event)
        return;
    end

    % Falls nicht initialisiert:
    if ~isfield(SCH, 'log')
        SCH.log = {};
        SCH.count = 0;
    end

    % Eintrag hinzufügen
    SCH.count = SCH.count + 1;
    SCH.log{SCH.count,1} = string(datetime("now","Format","HH:mm:ss.SSS"));
    SCH.log{SCH.count,2} = string(agent);
    SCH.log{SCH.count,3} = string(event);
end