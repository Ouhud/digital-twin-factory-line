function paths = export_kpi(kpi, outDir, prefix)
% EXPORT_KPI – schreibt Summary/Zeitreihen als CSV, plus MAT & JSON
%   paths = export_kpi(kpi, outDir, prefix)
%
% kpi    : Resultat aus kpi_finalize(...)
% outDir : Ausgabeverzeichnis (z. B. fullfile(root,'out'))
% prefix : Dateipräfix (z. B. 'twin' oder 'factory_3r2m')
%
% Rückgabe:
%   paths.summary_csv
%   paths.throughput_csv
%   paths.mat
%   paths.json

if nargin < 3 || isempty(prefix), prefix = 'kpi'; end
if nargin < 2 || isempty(outDir), outDir = 'out'; end
if ~exist(outDir,'dir'), mkdir(outDir); end

ts = char(datetime("now","Format","yyyyMMdd_HHmmss"));

% ---- Summary CSV (eine Zeile) ----
summary_tbl = table( ...
    kpi.picked, kpi.placed, kpi.pickMiss, ...
    kpi.successRate, kpi.throughputPM, kpi.outputRatePS, ...
    safeget(kpi,'availability',NaN), ...
    cellstr(sprintf_vec(safeget(kpi,'util_robot',[NaN NaN NaN]))), ...
    cellstr(sprintf_vec(safeget(kpi,'util_machine',[NaN NaN]))), ...
    'VariableNames', {'picked','placed','missed','success','throughputPM','outputRatePS','availability','util_robot','util_machine'} ...
);

paths.summary_csv = fullfile(outDir, sprintf('%s_summary_%s.csv', prefix, ts));
writetable(summary_tbl, paths.summary_csv);

% ---- Zeitreihe: shipped über Zeit ----
if isfield(kpi,'throughput_ts') && ~isempty(kpi.throughput_ts)
    tt = array2table(kpi.throughput_ts, 'VariableNames', {'t_s','shipped'});
else
    tt = array2table(zeros(0,2), 'VariableNames', {'t_s','shipped'});
end
paths.throughput_csv = fullfile(outDir, sprintf('%s_throughput_ts_%s.csv', prefix, ts));
writetable(tt, paths.throughput_csv);

% ---- MAT-Datei ----
paths.mat = fullfile(outDir, sprintf('%s_kpi_%s.mat', prefix, ts));
save(paths.mat, 'kpi', '-v7');

% ---- JSON-Datei ----
try
    J = kpi_to_json(kpi);
    paths.json = fullfile(outDir, sprintf('%s_kpi_%s.json', prefix, ts));
    fid = fopen(paths.json,'w');
    fwrite(fid, J, "char"); fclose(fid);
catch E
    warning('export_kpi: JSON konnte nicht geschrieben werden: %s', E.message);
    paths.json = "";
end
end

% -------- Helper --------
function s = sprintf_vec(v)
if isstring(v) || ischar(v), s = string(v); return; end
if isempty(v), s = ""; return; end
s = "[" + strjoin(string(compose('%.3f', v)), ", ") + "]";
end

function J = kpi_to_json(kpi)
% strukturiert & numerikfreundlich
K = kpi;
if isfield(K,'meta')
    try, K.meta.created   = char(K.meta.created);   end
    try, K.meta.finalized = char(K.meta.finalized); end
end
J = jsonencode(K, 'ConvertInfAndNaN', true, 'PrettyPrint', true);
end

function x = safeget(S, f, d)
if isfield(S,f), x = S.(f); else, x = d; end
end