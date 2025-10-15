function [logf, closef] = logger(logFile, varargin)
% LOGGER  Strukturierter Logger (Konsole + Datei, Zeitstempel, Level)
%   [logf, closef] = logger(logFile, 'level','INFO')
%   logf(level, fmt, varargin...)
%
% Beispiel:
%   [log, closeLog] = logger(fullfile('out','run.log'));
%   log('INFO','Starte Sim T=%.1fs', 60);
%   closeLog();

p = inputParser;
addParameter(p,'level','INFO');       % Mindest-Level: DEBUG < INFO < WARN < ERROR
parse(p, varargin{:});
minLevel = levelToNum(upper(string(p.Results.level)));

fid = -1;
if nargin>=1 && ~isempty(logFile)
    [fid,msg] = fopen(logFile,'a');
    if fid<0, warning('logger: %s (nur Konsole)', msg); end
end

logf = @writeLog;
closef = @() closeFile(fid);

    function writeLog(level, fmt, varargin)
        lvl = levelToNum(upper(string(level)));
        if lvl < minLevel, return; end
        ts  = datestr(now,'yyyy-mm-dd HH:MM:SS.FFF');
        line = sprintf('[%s] %-5s | %s', ts, upper(string(level)), sprintf(fmt, varargin{:}));
        % Konsole
        fprintf('%s\n', line);
        % Datei
        if fid>0
            fprintf(fid, '%s\n', line);
            % sofort flushen (nützlich bei Crash)
            try, fflush(fid); end %#ok<FFLUS>
        end
    end
end

function closeFile(fid)
if fid>0
    try, fclose(fid); end
end
end

function n = levelToNum(s)
switch s
    case "DEBUG", n=10;
    case "INFO" , n=20;
    case "WARN" , n=30;
    case "ERROR", n=40;
    otherwise,   n=20;
end
end