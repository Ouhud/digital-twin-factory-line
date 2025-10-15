function [log, closeLog] = logger(filename)
% LOGGER – sehr einfacher Logger (Datei + Konsole)
% Nutzung:
%   [log, closeLog] = logger('out/run_XXXX/run_sim_XXXX.txt');
%   log('INFO','Text %s', 'abc');
%   closeLog();

fid = fopen(filename, 'a');
if fid == -1
    error('logger:FileError', 'Konnte Logdatei %s nicht öffnen.', filename);
end

% Startzeile
fprintf(fid, '[%s] INFO  | Log gestartet\n', datestr(now,'yyyy-mm-dd HH:MM:SS'));
fprintf('[%s] INFO  | Log gestartet: %s\n', datestr(now,'HH:MM:SS'), filename);

% Rückgabefunktions-Handles
log = @(level, varargin) writeLog(fid, level, varargin{:});
closeLog = @() fclose(fid);
end

function writeLog(fid, level, msg, varargin)
timestamp = datestr(now,'yyyy-mm-dd HH:MM:SS');
line = sprintf('[%s] %-6s| %s\n', timestamp, upper(level), sprintf(msg, varargin{:}));
fprintf(fid, '%s', line);
fprintf('%s', line);  % auch in MATLAB-Konsole zeigen
end