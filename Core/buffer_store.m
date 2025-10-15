function B = buffer_store(capacity, name)
% BUFFER_STORE – einfacher FIFO-Puffer (Queue) für Teile
%   B = buffer_store(capacity, name)
%
% Methoden:
%   B2           = B.push(B, item)
%   [B2,it,ok]   = B.pop(B)
%   [B2,it,ok]   = B.peek(B)
%   n            = B.len(B)
%   tf           = B.is_empty(B)
%   tf           = B.is_full(B)
%
% Autor: Hamza Mehmalat
% Datum: 2025-10-14

if nargin < 1 || isempty(capacity), capacity = inf; end
if nargin < 2, name = "buf"; end

B.name     = string(name);
B.capacity = capacity;
B.q        = {};   % interne Queue (Zellarray)

% Methoden
B.push      = @push;
B.pop       = @pop;
B.peek      = @peek;
B.len       = @len;
B.count     = @count;
B.is_empty  = @is_empty;
B.is_full   = @is_full;

    function B2 = push(B1, item)
        if is_full(B1)
            warning('buffer_store:%s full – drop item id=%s', B1.name, get_id(item));
            B2 = B1; 
            return;
        end
        B1.q{end+1} = item; %#ok<AGROW>
        B2 = B1;
    end

    function [B2, item, ok] = pop(B1)
        if isempty(B1.q)
            item = []; ok = false; B2 = B1; 
            return;
        end
        item = B1.q{1};
        B1.q(1) = [];
        ok = true;
        B2 = B1;
    end

    function [B2, item, ok] = peek(B1)
        if isempty(B1.q)
            item = []; ok = false; B2 = B1; 
            return;
        end
        item = B1.q{1};
        ok = true;
        B2 = B1;
    end

    function n = len(B1)
        n = numel(B1.q);
    end

    function n = count(B1)
        n = len(B1);
    end

    function tf = is_empty(B1)
        tf = isempty(B1.q);
    end

    function tf = is_full(B1)
        tf = isfinite(B1.capacity) && numel(B1.q) >= B1.capacity;
    end
end

% --- Hilfsfunktion für Logging ---
function s = get_id(item)
try
    if isfield(item,'id')
        s = string(item.id);
    else
        s = "<noid>";
    end
catch
    s = "<noid>";
end
end