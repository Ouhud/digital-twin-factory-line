function n = buf_count(B)
% Robust zählen – unterstützt count/len/is_empty sowie data/q
n = 0;
if ~isstruct(B), return; end
if isfield(B,'count')    && isa(B.count,'function_handle'),    n = B.count(B);    return; end
if isfield(B,'len')      && isa(B.len,'function_handle'),      n = B.len(B);      return; end
if isfield(B,'is_empty') && isa(B.is_empty,'function_handle'), n = ~B.is_empty(B); n = double(n>0); return; end
if isfield(B,'data'), n = numel(B.data); return; end
if isfield(B,'q'),    n = numel(B.q);    return; end
end