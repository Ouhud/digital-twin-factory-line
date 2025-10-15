function b = util_basename(p)
% UTIL_BASENAME  Datei-Name inkl. Extension aus Pfad extrahieren
[~,name,ext] = fileparts(p);
b = [name ext];
end