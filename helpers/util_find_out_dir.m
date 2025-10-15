function outDir = util_find_out_dir(startDir)
% UTIL_FIND_OUT_DIR  Sucht vom Startordner aufwärts nach einem "out"-Ordner.
if nargin<1 || isempty(startDir), startDir = pwd; end
p = startDir;
while true
    cand = fullfile(p, 'out');
    if exist(cand, 'dir'), outDir = cand; return; end
    [p2,~,~] = fileparts(p);
    if strcmp(p2, p), error('util_find_out_dir: Kein "out" ab %s gefunden.', startDir); end
    p = p2;
end
end