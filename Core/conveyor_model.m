function B = conveyor_model(L, v, stations_pos)
% CONVEYOR_MODEL – Förderband-Modell mit mehreren Stationen (kompatibel mit FSM-Robot)
%
%   B = conveyor_model(L, v, stations_pos)
%
% Beschreibung:
%   Simuliert ein Förderband mit mehreren Stationen, an denen Roboter Teile
%   auflegen oder entnehmen können. Das Modell ist kompatibel mit der FSM-
%   Robot-Logik (z. B. fsm_robot, scheduler, simulate_factory_line_3R2M).
%
% Parameter:
%   L             – Bandlänge in Metern (Standard: 2.2)
%   v             – Bandgeschwindigkeit [m/s] (Standard: 0.3)
%   stations_pos  – Array mit x-Positionen der Stationen [m]
%
% Felder:
%   .L, .v, .stations  – Länge, Geschwindigkeit, Positionen der Stationen
%   .items             – Liste der auf dem Band befindlichen Teile
%
% Methoden:
%   B = B.step(B, dt)                  → Bewegung der Teile entlang des Bandes
%   tf = B.can_pick(B [, x_at])        → prüft, ob an Position x_at ein Teil liegt
%   [B, part] = B.take(B [, x_at])     → entnimmt Teil an Position x_at
%   [B, ok]   = B.load(B, part [, x])  → legt Teil auf das Band (optional x)
%
% Autor: Mohamad Hamza Mehmalat
% Stand: 2025-10-15
% -------------------------------------------------------------------------

%% Standardwerte
if nargin < 1, L = 2.2; end
if nargin < 2, v = 0.30; end
if nargin < 3, stations_pos = [0.8, 1.3, 1.9]; end  % drei Stationen: R1, R2, R3

%% Struktur initialisieren
B.L = L;
B.v = v;
B.stations = stations_pos(:).';  % Zeilenvektor

% Leeres Struct-Array mit definierter Struktur
B.items = struct( ...
    'id',        uint64([]), ...
    'pos',       [], ...
    'created_s', [], ...
    'src',       strings(0,1), ...
    'meta',      [] );

%% Methoden zuweisen
B.step     = @step;
B.can_pick = @can_pick;
B.take     = @take;
B.load     = @load;

% ============================================================
% STEP – bewegt alle Teile entlang des Bandes
% ============================================================
    function B2 = step(B1, dt)
        if isempty(B1.items)
            B2 = B1;
            return;
        end

        % Positionen aktualisieren
        for k = 1:numel(B1.items)
            B1.items(k).pos = B1.items(k).pos + B1.v * dt;
        end

        % Teile entfernen, die das Ende des Bandes überschritten haben
        B1.items = B1.items([B1.items.pos] <= B1.L);
        B2 = B1;
    end

% ============================================================
% CAN_PICK – prüft, ob an einer Station ein Teil liegt
% ============================================================
    function tf = can_pick(B1, x_at)
        if nargin < 2
            % Standard: erste Station
            if isfield(B1, 'stations') && ~isempty(B1.stations)
                x_at = B1.stations(1);
            else
                x_at = 0.8;
            end
        elseif isstruct(x_at)
            % Sicherheitsprüfung
            warning('⚠️ can_pick(): x_at war struct – setze auf 0.0');
            x_at = 0.0;
        end

        if isempty(B1.items)
            tf = false;
            return;
        end

        tol = 0.03;  % Toleranz (3 cm)
        pos = [B1.items.pos];
        tf = any(abs(pos - x_at) <= tol);
    end

% ============================================================
% TAKE – entnimmt ein Teil an einer Station
% ============================================================
    function [B2, part] = take(B1, x_at)
        if nargin < 2
            if isfield(B1, 'stations') && ~isempty(B1.stations)
                x_at = B1.stations(1);
            else
                x_at = 0.8;
            end
        elseif isstruct(x_at)
            warning('⚠️ take(): x_at war struct – setze auf 0.0');
            x_at = 0.0;
        end

        part = [];
        if isempty(B1.items)
            B2 = B1;
            return;
        end

        tol = 0.03;
        pos = [B1.items.pos];
        idx = find(abs(pos - x_at) <= tol, 1, 'first');

        if ~isempty(idx)
            part = B1.items(idx);
            B1.items(idx) = []; % Teil entfernen
        end
        B2 = B1;
    end

% ============================================================
% LOAD – legt neues Teil auf das Band (z. B. von R1, R2, R3)
% ============================================================
    function [B2, ok] = load(B1, part_in, x_at)
        ok = false;

        if nargin < 2 || isempty(part_in)
            B2 = B1;
            return;
        end

        % Standardposition
        if nargin < 3
            x_at = 0.0;  % Anfang des Bandes
        elseif isstruct(x_at)
            warning('⚠️ load(): x_at war struct – setze auf 0.0');
            x_at = 0.0;
        end

        % Robust normalisieren
        part = normalize_item(part_in);

        % Teilposition angeben
        part.pos = x_at;

        % Teil hinzufügen
        if isempty(B1.items)
            B1.items = part;
        else
            part = align_fields(part, B1.items(1));
            B1.items(end+1,1) = part; %#ok<AGROW>
        end

        ok = true;
        B2 = B1;
    end
end

% =================== Lokale Helper ===================
function s = normalize_item(s)
% Akzeptiert flexible Eingangsstrukturen und erzwingt Standardfelder
if ~isfield(s,'id'), s.id = uint64(0); end
if ~isa(s.id,'uint64')
    try, s.id = uint64(s.id); catch, s.id = uint64(0); end
end
if ~isfield(s,'pos'), s.pos = 0.0; end
if isfield(s,'t_created') && ~isfield(s,'created_s')
    s.created_s = s.t_created;
elseif ~isfield(s,'created_s')
    s.created_s = NaN;
end
if ~isfield(s,'src'), s.src = ""; end
if ~(isstring(s.src) || ischar(s.src)), s.src = string(s.src); end
if ~isfield(s,'meta'), s.meta = []; end
if isfield(s,'t_created'), s = rmfield(s,'t_created'); end
end

function s = align_fields(s, template)
% Erzwingt gleiche Feldreihenfolge und Datentypen
tfn = fieldnames(template);
sfn = fieldnames(s);
for i = 1:numel(tfn)
    f = tfn{i};
    if ~isfield(s,f)
        s.(f) = template.(f);
    end
end
extra = setdiff(sfn, tfn);
if ~isempty(extra)
    s = rmfield(s, extra);
end
s = orderfields(s, template);
end