function f = dir_last(pattern, varargin)
% DIR_LAST  Liefert den Pfad der neuesten Datei, die auf pattern passt.
%   f = dir_last('out\run_*\.mat')
% Optional: dir_last(pattern, 'errorIfEmpty', false)

p = inputParser;
addParameter(p, 'errorIfEmpty', true, @(x)islogical(x)||isscalar(x));
parse(p, varargin{:});
opts = p.Results;

d = dir(pattern);
if isempty(d)
    if opts.errorIfEmpty
        error('dir_last: Keine Dateien für Pattern: %s', pattern);
    else
        f = ''; return;
    end
end
[~,i] = max([d.datenum]);
f = fullfile(d(i).folder, d(i).name);
end