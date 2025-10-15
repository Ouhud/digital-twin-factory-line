function plot_source_buffer()
% PLOT_SOURCE_BUFFER – Visualisiert die Teileerzeugung im Eingangspuffer
%
% Simuliert material_source + buffer_store über eine feste Zeitspanne
% und zeichnet den Verlauf der Pufferfüllung.
%
% Autor: Hamza Mehmalat
% Datum: 2025-10-14
%
% Ausgabe:
%   - Live-Plot der Puffergröße über Zeit
%   - Automatischer PNG-Export in /out
%

%% ------------------------------------------------------------------------
% 1. Parameter
% -------------------------------------------------------------------------
rate   = 0.6;        % Teile pro Sekunde
Tsim   = 20;         % Simulationszeit [s]
dt     = 0.05;       % Zeitschritt [s]
nSteps = Tsim / dt;  % Anzahl Zeitschritte

%% ------------------------------------------------------------------------
% 2. Initialisierung
% -------------------------------------------------------------------------
S   = material_source(rate);
buf = buffer_store(100, "in");

tVec   = zeros(1, nSteps);
lenVec = zeros(1, nSteps);

%% ------------------------------------------------------------------------
% 3. Simulation
% -------------------------------------------------------------------------
for i = 1:nSteps
    [S, buf] = material_source_step(S, buf, dt);
    tVec(i)  = i * dt;
    lenVec(i) = buf.len(buf);
end

%% ------------------------------------------------------------------------
% 4. Plot
% -------------------------------------------------------------------------
figure('Name','Bufferfüllung','Color','w');
plot(tVec, lenVec, 'LineWidth', 2);
grid on;
xlabel('Zeit [s]');
ylabel('Anzahl Teile im Eingangspuffer');
title(sprintf('Materialfluss: %.2f Teile/s – Gesamtdauer %.1f s', rate, Tsim));
xlim([0 Tsim]);

%% ------------------------------------------------------------------------
% 5. Export
% -------------------------------------------------------------------------
root = fileparts(mfilename('fullpath'));
outDir = fullfile(root, 'out');
if ~exist(outDir, 'dir'), mkdir(outDir); end

fileName = fullfile(outDir, sprintf('buffer_plot_%s.png', ...
    datestr(now,'yyyymmdd_HHMMSS')));
saveas(gcf, fileName);

fprintf('✅ Diagramm gespeichert: %s\n', fileName);

end