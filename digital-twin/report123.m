function report123(K, C, csvPath, outDir)
% REPORT123 – Erstellt automatisch einen PDF-Bericht der Simulationsergebnisse

ts = char(datetime("now","Format","yyyyMMdd_HHmmss"));
pdfFile = fullfile(outDir, ['report123_' ts '.pdf']);

fig = figure('Visible','off','Position',[100 100 900 600]);

subplot(2,2,1);
bar([K.util_robot(1), K.util_robot(2), K.util_robot(3)]);
title('Roboter-Auslastung [%]');
xlabel('Roboter'); ylabel('Prozent [%]');
set(gca,'XTickLabel',{'R1','R2','R3'});

subplot(2,2,2);
bar(K.util_machine*100);
title('Maschinen-Auslastung [%]');
xlabel('Maschine'); ylabel('Prozent [%]');
set(gca,'XTickLabel',{'M1','M2'});

subplot(2,2,3);
text(0,0.8,sprintf('Durchsatz: %.2f Teile/min',K.throughputPM),'FontSize',11);
text(0,0.6,sprintf('Erfolgsrate: %.1f %%',K.successRate*100),'FontSize',11);
text(0,0.4,sprintf('Verfügbarkeit: %.1f %%',K.availability*100),'FontSize',11);
text(0,0.2,sprintf('Simulationszeit: %.1f s',C.Tsim),'FontSize',11);
axis off; title('Kennzahlenübersicht');

subplot(2,2,4);
plot(K.throughput_ts(:,1), K.throughput_ts(:,2));
title('Ausgelieferte Teile über Zeit');
xlabel('Zeit [s]'); ylabel('Teile gesamt');
grid on;

sgtitle('📊 Digital Twin Factory Line – Simulation Report');

exportgraphics(fig, pdfFile, 'ContentType', 'vector');
close(fig);

fprintf('📄 Bericht gespeichert unter: %s\n', pdfFile);
end