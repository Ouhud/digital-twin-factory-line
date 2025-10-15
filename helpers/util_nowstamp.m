function s = util_nowstamp()
% UTIL_NOWSTAMP  Zeitstempel yyyyMMdd_HHmmss
s = char(datetime("now","Format","yyyyMMdd_HHmmss"));
end