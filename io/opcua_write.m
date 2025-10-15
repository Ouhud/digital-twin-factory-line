function opcua_write(kpi, serverUrl, nodeMap, varargin)
% OPCUA_WRITE  Schreibt KPI-Werte auf einen OPC UA Server (Industrial Communication Toolbox)
%
% opcua_write(kpi, 'opc.tcp://localhost:4840', nodeMap, 'ClientName','DTwin', 'Timeout',5, 'dryRun',false)
%
% nodeMap: struct mit NodeIds (oder Browse-Nodes) z.B.:
%   nodeMap.picked         = 'ns=2;s=DTwin/picked';
%   nodeMap.placed         = 'ns=2;s=DTwin/placed';
%   nodeMap.successRate    = 'ns=2;s=DTwin/success';
%   nodeMap.throughputPM   = 'ns=2;s=DTwin/throughputPM';
%   nodeMap.outputRatePS   = 'ns=2;s=DTwin/outputRatePS';
%   nodeMap.util_robot_1   = 'ns=2;s=DTwin/util_r1';  ... etc.
%
% Doku:
%   OPC UA in MATLAB: Client, Nodes, writeValue.  [oai_citation:9‡mathworks.com](https://www.mathworks.com/help/icomm/ug/opc-ua-components.html?utm_source=chatgpt.com)

p = inputParser;
addParameter(p,'ClientName','DTwinClient');
addParameter(p,'Timeout',5);
addParameter(p,'dryRun',false);
parse(p, varargin{:});
opt = p.Results;

% Toolbox vorhanden?
if ~license('test','Industrial_Comms_Toolbox')
    warning('opcua_write: Industrial Communication Toolbox nicht gefunden -> DryRun');
    opt.dryRun = true;
end

% Werte vorbereiten (nur vorhandene schreiben)
KV = struct();
KV.picked       = safe(kpi,'picked');
KV.placed       = safe(kpi,'placed');
KV.pickMiss     = safe(kpi,'pickMiss');
KV.successRate  = safe(kpi,'successRate');
KV.throughputPM = safe(kpi,'throughputPM');
KV.outputRatePS = safe(kpi,'outputRatePS');
KV.availability = safe(kpi,'availability');
KV.util_robot_1 = vecget(kpi,'util_robot',1);
KV.util_robot_2 = vecget(kpi,'util_robot',2);
KV.util_robot_3 = vecget(kpi,'util_robot',3);
KV.util_machine_1 = vecget(kpi,'util_machine',1);
KV.util_machine_2 = vecget(kpi,'util_machine',2);

% Nur vorhandene NodeIds verwenden
fields = fieldnames(KV);
nodes = {};
vals  = {};
for i=1:numel(fields)
    fn = fields{i};
    if isfield(nodeMap, fn) && ~isempty(nodeMap.(fn))
        nodes{end+1} = nodeMap.(fn); %#ok<AGROW>
        vals{end+1}  = KV.(fn);      %#ok<AGROW>
    end
end
if isempty(nodes)
    warning('opcua_write: nodeMap leer – nichts zu schreiben.');
    return;
end

if opt.dryRun
    fprintf('[OPC UA] DRYRUN %s -> %d Knoten\n', serverUrl, numel(nodes));
    for i=1:numel(nodes)
        fprintf('  %s = %s\n', toStr(nodes{i}), num2str(vals{i}));
    end
    return;
end

% Verbindung herstellen und schreiben
uaClient = opcua(serverUrl, 'ClientName', opt.ClientName);   % Client anlegen.  [oai_citation:10‡mathworks.com](https://www.mathworks.com/help/icomm/ug/opc-ua-components.html?utm_source=chatgpt.com)
connect(uaClient, 'Timeout', opt.Timeout);

try
    % Node-Objekte erzeugen (Strings → Node handles)
    nodeObjs = cell(size(nodes));
    for i=1:numel(nodes)
        if ischar(nodes{i}) || isstring(nodes{i})
            nodeObjs{i} = opcuanode(uaClient, char(nodes{i}));
        else
            nodeObjs{i} = nodes{i}; % bereits Node-Objekt
        end
    end
    % Schreiben
    writeValue(uaClient, [nodeObjs{:}], vals);               % writeValue.  [oai_citation:11‡mathworks.com](https://www.mathworks.com/help/icomm/ug/opc.ua.client.writevalue.html?utm_source=chatgpt.com)
catch E
    warning('opcua_write: writeValue fehlgeschlagen: %s', E.message);
end

disconnect(uaClient);
end

% --- Helper ---
function x = safe(S,f); if isfield(S,f), x = double(S.(f)); else, x = NaN; end; end
function v = vecget(S,f,i)
if isfield(S,f) && numel(S.(f))>=i, v = double(S.(f)(i));
else, v = NaN; end
end
function s = toStr(x)
if ischar(x) || isstring(x), s = char(x);
else, s = '(nodeObj)'; end
end