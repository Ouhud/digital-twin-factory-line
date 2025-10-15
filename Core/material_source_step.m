function [S, buf] = material_source_step(S, buf, dt)
% MATERIAL_SOURCE_STEP – erzeugt neue Teile im Eingangspuffer
%
%   [S, buf] = material_source_step(S, buf, dt)
%
% Beschreibung:
%   Fügt basierend auf der Spawn-Rate neue Teile in den Buffer ein.
%   Arbeitet robust auch bei kleinen Zeitschritten (dt) und nutzt
%   denselben FIFO-Puffer wie buffer_store.m (.q, .push).
%
% Autor: Hamza Mehmalat
% Datum: 2025-10-15

if nargin < 3 || isempty(dt)
    dt = 0.05;
end

% ============================================================
% 🔹 Eingabe prüfen und kompatibel zu beiden Varianten machen
% ============================================================
if ~isstruct(S) || ~(isfield(S, 'spawn_rate') || isfield(S, 'rate'))
    error('material_source_step:UngültigerSourceStruct', ...
        'Ungültiger Source-Struct. Bitte vorher material_source(rate) aufrufen.');
end

% --- Kompatibilität: beide Feldnamen akzeptieren ---
if isfield(S, 'spawn_rate')
    rate_val = S.spawn_rate;
else
    rate_val = S.rate;
end

% ============================================================
% 🔹 Akkumulator erhöhen (rate × dt)
% ============================================================
if ~isfield(S, 'acc')
    S.acc = 0.0;
end
S.acc = S.acc + rate_val * dt;

% ============================================================
% 🔹 deterministische Erzeugung
% ============================================================
while S.acc >= 1.0
    % Neues Teil erstellen
    part = struct( ...
        'id',        S.next_id, ...
        't_created', datetime("now"), ...
        'pos',       0.0, ...
        'meta',      [], ...
        'src',       S.name);

    % In Buffer schreiben
    if isfield(buf, 'push') && isa(buf.push, 'function_handle')
        buf = buf.push(buf, part);
    else
        if ~isfield(buf, 'q') || ~iscell(buf.q)
            buf.q = {};
        end
        buf.q{end+1} = part;
    end

    % IDs & Akkumulator aktualisieren
    S.next_id = S.next_id + 1;
    S.acc = S.acc - 1.0;

    fprintf('[SPAWN] Neues Teil id=%d (acc=%.2f)\n', S.next_id - 1, S.acc);
end

% ============================================================
% 🔹 optionale leichte Zufälligkeit
% ============================================================
if rand < (rate_val * dt * 0.2)
    part = struct( ...
        'id',        S.next_id, ...
        't_created', datetime("now"), ...
        'pos',       0.0, ...
        'meta',      [], ...
        'src',       S.name);
    if isfield(buf, 'push') && isa(buf.push, 'function_handle')
        buf = buf.push(buf, part);
    else
        if ~isfield(buf, 'q') || ~iscell(buf.q)
            buf.q = {};
        end
        buf.q{end+1} = part;
    end
    S.next_id = S.next_id + 1;
end

end