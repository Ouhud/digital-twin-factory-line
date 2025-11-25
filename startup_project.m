function startup_project()
% STARTUP_PROJECT – Initialisiert alle Pfade des Ouhud Digital Twin Factory Projekts
%
% Lädt alle relevanten Projektmodule:
% Core, digital-twin, io, kpi, viz, demos, helpers, reports, out

disp('🚀 Starte Ouhud Digital Twin Factory Projekt...');
root = fileparts(mfilename('fullpath'));

% --- Pfade definieren ---
folders = { ...
    fullfile(root, 'Core'), ...
    fullfile(root, 'digital-twin'), ...
    fullfile(root, 'io'), ...
    fullfile(root, 'kpi'), ...
    fullfile(root, 'viz'), ...
};

% --- Alle Unterordner hinzufügen ---
for i = 1:length(folders)
    if isfolder(folders{i})
        addpath(genpath(folders{i}));
        fprintf('📂 Pfad hinzugefügt: %s\n', folders{i});
    else
        fprintf('⚠️  Ordner nicht gefunden: %s\n', folders{i});
    end
end

% --- Pfade speichern und Cache neu laden ---
savepath;
rehash toolboxcache;

% --- config.m prüfen ---
configs = which('config','-all');
disp(' ');
disp('[CONFIG] Gefundene config.m:');
disp(strjoin(configs, newline));

if numel(configs) > 1
    warning('⚠️  Falsche config.m im Pfad! Bitte doppelte Datei löschen.');
else
    disp('✅ config.m eindeutig gefunden.');
end

disp(' ');
disp('✅ Alle Projektpfade geladen.');
disp('   Du kannst jetzt run_all oder simulate_factory_line_3R2M ausführen.');
end