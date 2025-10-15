function S = material_source(rate)
% MATERIAL_SOURCE – einfacher Teile-Generator (Eingangslager)
%   S = material_source(rate)   % rate [Teile/s]
%
% Felder:
%   .rate    – Spawn-Rate [1/s]
%   .acc     – interner Zähler für fraktionelle Ankünfte
%   .next_id – laufende ID-Vergabe
%   .name    – Label (optional)

if nargin < 1 || isempty(rate), rate = 0.5; end  % Default 0.5 Teile/s

S = struct();
S.rate    = double(rate);
S.acc     = 0.0;          % <— jetzt identisch zu material_source_step
S.next_id = uint64(1);
S.name    = "SRC";
end