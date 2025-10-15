function animate_step(viz, C, belt, M1, M2, R1, R2, R3, inBuf, outBuf, shipped, t)
% ANIMATE_STEP – aktualisiert die 2D-Szene (und optional 3D)
% Minimale Annahmen:
%  - belt.items : struct-Array mit Feld .pos
%  - M1/M2.state : "Ready"|"Process"|"Done", M?.has_part bool
%  - R?.state : String-State
%  - inBuf/outBuf können verschiedene APIs haben (count/len/data/q/…)
%  - shipped : Gesamtzahl ausgelieferter Teile

if isempty(viz) || ~isfield(viz,'ax') || ~isvalid(viz.ax)
    return; % nichts zu tun
end

% --- Band-Items in 2D zeichnen/aktualisieren -----------------------------
if isfield(viz,'items')
    % Alte Items löschen
    if isfield(viz.items,'h') && ~isempty(viz.items.h)
        try
            ok = arrayfun(@isvalid, viz.items.h);
            delete(viz.items.h(ok));
        catch
            % ignore
        end
    end
    viz.items.h = gobjects(0,1);

    if ~isempty(belt) && isfield(belt,'items') && ~isempty(belt.items)
        for i=1:numel(belt.items)
            x = belt.items(i).pos;
            y = 0.0;
            viz.items.h(end+1,1) = rectangle(viz.ax, ...
                'Position',[x-0.03, y+0.02, 0.06, 0.16], ...
                'FaceColor',[0.2 0.6 0.9], 'EdgeColor','none'); %#ok<AGROW>
        end
    end
end

% --- Maschinenstatus updaten --------------------------------------------
if isfield(viz,'stations') && numel(viz.stations)>=2
    set(viz.stations(1).txt, 'String', sprintf('M1: %s%s', string(get_state(M1)), tern(get_has_part(M1),'*','')));
    set(viz.stations(2).txt, 'String', sprintf('M2: %s%s', string(get_state(M2)), tern(get_has_part(M2),'*','')));
end

% --- Pufferzähler --------------------------------------------------------
if isfield(viz,'inbuf') && isfield(viz.inbuf,'txt') && isvalid(viz.inbuf.txt)
    set(viz.inbuf.txt,  'String', sprintf('IN: %d', buf_count(inBuf)));
end
if isfield(viz,'outbuf') && isfield(viz.outbuf,'txt') && isvalid(viz.outbuf.txt)
    set(viz.outbuf.txt, 'String', sprintf('OUT: %d', buf_count(outBuf)));
end

% --- Roboterzustände (nur Textlabel) -------------------------------------
if isfield(viz,'R') && numel(viz.R)>=3
    set(viz.R(1).tx,'String',sprintf('R1: %s', string(get_state(R1))));
    set(viz.R(2).tx,'String',sprintf('R2: %s', string(get_state(R2))));
    set(viz.R(3).tx,'String',sprintf('R3: %s', string(get_state(R3))));
end

% --- KPI-Ticker ----------------------------------------------------------
if isfield(viz,'kpi') && isfield(viz.kpi,'txt') && isvalid(viz.kpi.txt)
    set(viz.kpi.txt, 'String', sprintf('shipped=%d | t=%.1f s', shipped, t));
end

drawnow limitrate;
end

function y = tern(cond,a,b)
if cond, y=a; else, y=b; end
end

% ---------- robuste Helper ----------
function n = buf_count(B)
% robustes Zählen für verschiedene Buffer-APIs
n = 0;
try
    if ~isstruct(B), return; end
    if isfield(B,'count')     && isa(B.count,'function_handle'), n = B.count(B);     return; end
    if isfield(B,'len')       && isa(B.len,'function_handle'),   n = B.len(B);       return; end
    if isfield(B,'is_empty')  && isa(B.is_empty,'function_handle'), n = ~B.is_empty(B); if n, n=1; end; return; end
    if isfield(B,'data'), n = numel(B.data); return; end
    if isfield(B,'q'),    n = numel(B.q);    return; end
catch
    % fallback unten
end
end

function s = get_state(S)
if isstruct(S) && isfield(S,'state')
    s = S.state;
else
    s = "Unknown";
end
end

function tf = get_has_part(S)
tf = false;
if isstruct(S) && isfield(S,'has_part')
    tf = logical(S.has_part);
end
end