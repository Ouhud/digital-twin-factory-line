# 🏭 Digital Twin Factory Line  
**Simulations-Framework einer digitalen Fertigungslinie in MATLAB**

---

## 📘 Projektbeschreibung

Dieses MATLAB-Projekt modelliert und simuliert eine **digitale Fertigungslinie (Digital Twin Factory Line)** mit Förderbändern, Maschinen und kollaborierenden Robotern gemäß **Pflichtenheft**.

Das Projekt dient sowohl der **industriellen Weiterentwicklung** als auch der **wissenschaftlichen Analyse** im Rahmen von Hochschulprojekten.

---

## 🎯 Workflow (Pflichtenheft-konform)

```
Eingangslager → R1 → [Belt1 → M1]
                  ↘  [Belt2 → M2] → R2 → Zwischenlager → R3 → Transport
```

**Ablauf:**
1. **Eingangslager** generiert kontinuierlich neue Teile
2. **Roboter R1** entnimmt Teile und verteilt sie **abwechselnd** auf Förderband 1 und 2
3. **Förderband 1** transportiert Teile zu **Maschine M1**
4. **Förderband 2** transportiert Teile zu **Maschine M2**
5. **Maschinen M1/M2** bearbeiten Teile **parallel**
6. **Roboter R2** entnimmt fertige Teile und legt sie ins **Zwischenlager**
7. **Roboter R3** verlädt Teile auf den **Transport** (wenn anwesend)
8. **Transport** kommt periodisch und nimmt verladene Teile mit

### ✅ Komponenten

| Komponente | Anzahl | Status |
|------------|--------|--------|
| **Roboter** | 3 (R1, R2, R3) | ✅ |
| **Maschinen** | 2 (M1, M2) | ✅ |
| **Förderbänder** | 2 (Belt1, Belt2) | ✅ |
| **Eingangslager** | 1 | ✅ |
| **Zwischenlager** | 1 | ✅ |
| **Transportmittel** | 1 (periodisch) | ✅ |

---

## 🚀 Quickstart

### 1. Projekt initialisieren

```matlab
cd digital-twin-factory-line
startup_project
```

**Was passiert:**
- Alle Unterordner werden zum MATLAB-Pfad hinzugefügt
- Konfigurationsdateien werden geladen
- System ist bereit für Simulation

---

### 2. Standardsimulation starten

```matlab
% Simulation mit Standardparametern (120 Sekunden)
S = simulate_factory_line_3R2M_pflichtenheft();
```

**Ausgabe:**
```
=== Simulation abgeschlossen (Pflichtenheft-konform) ===
Versendete Teile: 45
Teile auf Belt1: 30, zu M1: 28, von M1: 27
Teile auf Belt2: 30, zu M2: 27, von M2: 26
Erfolgsrate: 92.50%
```

---

### 3. Ergebnisse analysieren

```matlab
% Statistiken anzeigen
fprintf('Versendete Teile: %d\n', S.stats.parts_from_M1 + S.stats.parts_from_M2);
fprintf('Erfolgsrate: %.2f%%\n', S.kpi.successRate * 100);

% KPIs anzeigen
disp(S.kpi);
```

---

### 4. Vollständigen Test ausführen

```matlab
% Automatischer Test mit Validierung
test_pflichtenheft
```

**Testet:**
- ✅ Alle Komponenten funktionieren
- ✅ Materialfluss korrekt
- ✅ Erfolgsquote ≥ 90%
- ✅ Stabilität bei 1000+ Teilen

---

## ⚙️ Parameter anpassen

### Verfügbare Parameter

| Parameter | Beschreibung | Standardwert | Einheit |
|-----------|--------------|--------------|---------|
| `Tsim` | Simulationszeit | 120 | Sekunden |
| `dt` | Zeitschrittweite | 0.05 | Sekunden |
| `spawn_rate` | Materialzufuhr | 0.5 | Teile/s |
| `belt_speed` | Bandgeschwindigkeit | 0.3 | m/s |
| `machine_Tproc` | Bearbeitungszeiten | [5.0, 6.0] | Sekunden |
| `transport_interval` | Transport-Intervall | 20.0 | Sekunden |
| `transport_hold_time` | Transport-Haltezeit | 5.0 | Sekunden |
| `showPlots` | Visualisierung | true | boolean |
| `show3D` | 3D-Visualisierung | false | boolean |

---

### Beispiele für Parameteranpassung

#### Beispiel 1: Längere Simulation mit höherer Materialzufuhr

```matlab
S = simulate_factory_line_3R2M_pflichtenheft( ...
    'Tsim', 300, ...              % 5 Minuten Simulation
    'spawn_rate', 0.8, ...        % 0.8 Teile pro Sekunde
    'showPlots', true ...
);
```

**Effekt:**
- Mehr Teile werden produziert
- Höhere Auslastung der Maschinen
- Längere Warteschlangen möglich

---

#### Beispiel 2: Schnellere Produktion

```matlab
S = simulate_factory_line_3R2M_pflichtenheft( ...
    'belt_speed', 0.5, ...        % Schnellere Bänder (0.5 m/s)
    'machine_Tproc', [3.0, 3.5], ... % Kürzere Bearbeitungszeiten
    'transport_interval', 10.0 ... % Häufigerer Transport
);
```

**Effekt:**
- Höherer Durchsatz
- Kürzere Zykluszeiten
- Bessere Erfolgsquote

---

#### Beispiel 3: Engpass-Analyse

```matlab
S = simulate_factory_line_3R2M_pflichtenheft( ...
    'spawn_rate', 1.0, ...        % Hohe Materialzufuhr
    'machine_Tproc', [8.0, 10.0], ... % Lange Bearbeitungszeiten
    'transport_interval', 30.0 ... % Seltener Transport
);
```

**Effekt:**
- Puffer füllen sich
- Maschinen werden zum Engpass
- Niedrigere Erfolgsquote
- Gut für Optimierungsanalysen

---

#### Beispiel 4: Ohne Visualisierung (schneller)

```matlab
S = simulate_factory_line_3R2M_pflichtenheft( ...
    'Tsim', 600, ...              % 10 Minuten
    'showPlots', false ...        % Keine Visualisierung
);
```

**Effekt:**
- Simulation läuft deutlich schneller
- Gut für Batch-Analysen
- Ideal für Design of Experiments (DoE)

---

## 📊 KPI-Erklärung (Key Performance Indicators)

### Übersicht der KPIs

Nach jeder Simulation erhalten Sie eine Struktur `S.kpi` mit folgenden Kennzahlen:

```matlab
S.kpi
```

---

### 1. **successRate** (Erfolgsquote)

**Bedeutung:** Anteil der erfolgreich versendeten Teile an allen erzeugten Teilen

**Formel:**
```
successRate = versendete_Teile / erzeugte_Teile
```

**Interpretation:**
- **≥ 90%** = ✅ Sehr gut (Pflichtenheft-Ziel erreicht)
- **70-90%** = ⚠️ Akzeptabel (Optimierung möglich)
- **< 70%** = ❌ Problematisch (Engpässe vorhanden)

**Beispiel:**
```matlab
fprintf('Erfolgsquote: %.2f%%\n', S.kpi.successRate * 100);
% Ausgabe: Erfolgsquote: 92.50%
```

**Einflussfaktoren:**
- Materialzufuhr (`spawn_rate`)
- Bearbeitungszeiten (`machine_Tproc`)
- Transport-Intervall (`transport_interval`)
- Simulationszeit (`Tsim`)

---

### 2. **throughput** (Durchsatz)

**Bedeutung:** Anzahl der versendeten Teile pro Zeiteinheit

**Formel:**
```
throughput = versendete_Teile / Simulationszeit [Teile/Minute]
```

**Interpretation:**
- Höherer Durchsatz = Effizientere Produktion
- Vergleich mit Ziel-Durchsatz möglich

**Beispiel:**
```matlab
fprintf('Durchsatz: %.2f Teile/min\n', S.kpi.throughput);
% Ausgabe: Durchsatz: 22.50 Teile/min
```

**Optimierung:**
- Erhöhen: Schnellere Bänder, kürzere Bearbeitungszeiten
- Senken: Längere Bearbeitungszeiten, seltener Transport

---

### 3. **utilization** (Auslastung)

**Bedeutung:** Prozentuale Auslastung der Maschinen und Roboter

**Struktur:**
```matlab
S.kpi.utilization.M1    % Auslastung Maschine 1
S.kpi.utilization.M2    % Auslastung Maschine 2
S.kpi.utilization.R1    % Auslastung Roboter 1
S.kpi.utilization.R2    % Auslastung Roboter 2
S.kpi.utilization.R3    % Auslastung Roboter 3
```

**Formel:**
```
utilization = aktive_Zeit / Gesamtzeit
```

**Interpretation:**
- **> 80%** = ✅ Hohe Auslastung (effizient)
- **50-80%** = ⚠️ Mittlere Auslastung (Optimierung möglich)
- **< 50%** = ❌ Niedrige Auslastung (Ressourcen ungenutzt)

**Beispiel:**
```matlab
fprintf('M1 Auslastung: %.1f%%\n', S.kpi.utilization.M1 * 100);
fprintf('M2 Auslastung: %.1f%%\n', S.kpi.utilization.M2 * 100);
% Ausgabe: M1 Auslastung: 85.3%
%          M2 Auslastung: 82.7%
```

**Analyse:**
- Niedrige Maschinen-Auslastung → Materialzufuhr erhöhen
- Niedrige Roboter-Auslastung → Bearbeitungszeiten verkürzen

---

### 4. **cycleTime** (Zykluszeit)

**Bedeutung:** Durchschnittliche Zeit von Teilerzeugung bis Versand

**Formel:**
```
cycleTime = Σ(Versandzeit - Erzeugungszeit) / Anzahl_Teile
```

**Interpretation:**
- Kürzere Zykluszeit = Schnellere Produktion
- Wichtig für Just-in-Time-Produktion

**Beispiel:**
```matlab
fprintf('Durchschnittliche Zykluszeit: %.1f s\n', S.kpi.cycleTime);
% Ausgabe: Durchschnittliche Zykluszeit: 45.3 s
```

**Optimierung:**
- Reduzieren: Schnellere Bänder, kürzere Bearbeitungszeiten
- Erhöhen: Längere Bearbeitungszeiten, langsamere Bänder

---

### 5. **picked** und **placed** (Roboter-Aktionen)

**Bedeutung:** Anzahl der Pick- und Place-Operationen aller Roboter

**Beispiel:**
```matlab
fprintf('Picks: %d, Places: %d\n', S.kpi.picked, S.kpi.placed);
% Ausgabe: Picks: 135, Places: 135
```

**Interpretation:**
- Sollten idealerweise gleich sein
- Differenz zeigt Teile in Bearbeitung

---

### 6. **Statistiken** (S.stats)

Zusätzlich zu KPIs gibt es detaillierte Statistiken:

```matlab
S.stats.parts_to_belt1      % Teile auf Belt1 gelegt
S.stats.parts_to_belt2      % Teile auf Belt2 gelegt
S.stats.parts_to_M1         % Teile zu M1 transportiert
S.stats.parts_to_M2         % Teile zu M2 transportiert
S.stats.parts_from_M1       % Fertige Teile von M1
S.stats.parts_from_M2       % Fertige Teile von M2
```

**Beispiel:**
```matlab
fprintf('Belt1: %d → M1: %d → fertig: %d\n', ...
    S.stats.parts_to_belt1, S.stats.parts_to_M1, S.stats.parts_from_M1);
% Ausgabe: Belt1: 30 → M1: 28 → fertig: 27
```

**Analyse:**
- Differenzen zeigen Teile in Warteschlangen oder Bearbeitung
- Hilft bei Engpass-Identifikation

---

## 📈 KPI-Optimierung

### Ziel: Erfolgsquote ≥ 90%

**Strategie 1: Materialzufuhr anpassen**
```matlab
% Zu niedrig → Maschinen warten
S = simulate_factory_line_3R2M_pflichtenheft('spawn_rate', 0.3);

% Optimal → Gute Balance
S = simulate_factory_line_3R2M_pflichtenheft('spawn_rate', 0.5);

% Zu hoch → Puffer füllen sich
S = simulate_factory_line_3R2M_pflichtenheft('spawn_rate', 1.0);
```

---

**Strategie 2: Bearbeitungszeiten optimieren**
```matlab
% Schnelle Maschinen → Höherer Durchsatz
S = simulate_factory_line_3R2M_pflichtenheft('machine_Tproc', [3.0, 3.5]);

% Langsame Maschinen → Engpass
S = simulate_factory_line_3R2M_pflichtenheft('machine_Tproc', [8.0, 10.0]);
```

---

**Strategie 3: Transport-Frequenz erhöhen**
```matlab
% Häufiger Transport → Bessere Erfolgsquote
S = simulate_factory_line_3R2M_pflichtenheft('transport_interval', 10.0);

% Seltener Transport → Zwischenlager füllt sich
S = simulate_factory_line_3R2M_pflichtenheft('transport_interval', 30.0);
```

---

## 📂 Projektstruktur

```
digital-twin-factory-line/
├── startup_project.m              # Projekt-Initialisierung
├── test_pflichtenheft.m           # Automatischer Test
├── README.md                      # Diese Dokumentation
│
├── Core/                          # Kernmodule (9 Dateien)
│   ├── buffer_store.m             # Pufferverwaltung
│   ├── config.m                   # Konfiguration
│   ├── conveyor_model.m           # Förderband-Modell
│   ├── fsm_machine.m              # Maschinen-Zustandsautomat
│   ├── fsm_robot.m                # Roboter-Zustandsautomat
│   ├── material_source.m          # Materialquelle
│   ├── material_source_step.m     # Material-Generierung
│   ├── kinematics_3R_planar.m     # Roboterkinematik (optional)
│   └── plot_source_buffer.m       # Visualisierung (optional)
│
├── digital-twin/                  # Hauptsimulation (4 Dateien)
│   ├── simulate_factory_line_3R2M_pflichtenheft.m  # HAUPTSIMULATION
│   ├── logger.m                   # Logging
│   ├── log_event.m                # Event-Logging
│   ├── run_doe.m                  # Design of Experiments (optional)
│   └── out/                       # Ausgabeordner
│
├── viz/                           # Visualisierung (2 Dateien)
│   ├── draw_scene_2d_pflichtenheft.m    # 2D-Visualisierung
│   └── animate_step_pflichtenheft.m     # Animation
│
├── kpi/                           # KPI-Berechnung (5 Dateien)
│   ├── kpi_init.m                 # KPI-Initialisierung
│   ├── kpi_update.m               # KPI-Aktualisierung
│   ├── kpi_finalize.m             # KPI-Finalisierung
│   ├── export_kpi.m               # KPI-Export
│   └── pm_estimator.m             # Predictive Maintenance (optional)
│
└── io/                            # Schnittstellen (3 Dateien)
    ├── logger.m                   # Logging
    ├── opcua_write.m              # OPC UA Integration (optional)
    └── ros_publish.m              # ROS Integration (optional)
 

**Gesamt: ~44 relevante Dateien** (aufgeräumt, keine veralteten Versionen)

---

## 🔧 Erweiterte Nutzung

### Design of Experiments (DoE)

Systematische Parametervariation für Optimierung:

```matlab
% DoE-Analyse durchführen
run_doe
```

**Testet automatisch:**
- Verschiedene Materialzufuhrraten
- Verschiedene Bearbeitungszeiten
- Verschiedene Transport-Intervalle
- Erstellt CSV-Datei mit Ergebnissen

---

### Datenexport

KPIs werden automatisch exportiert nach `digital-twin/out/`:

```matlab
% Manuelle KPI-Export
export_kpi(S.kpi, 'digital-twin/out', 'meine_simulation');
```

**Erstellt:**
- `meine_simulation_kpi.csv` - KPI-Daten
- `meine_simulation_kpi.mat` - MATLAB-Daten
- `meine_simulation_kpi.json` - JSON-Daten

---

### OPC UA Integration (optional)

Daten an OPC UA Server senden:

```matlab
% Nach Simulation
opcua_write(S.kpi, 'opc.tcp://localhost:4840');
```

---

### ROS Integration (optional)

Daten an ROS publizieren:

```matlab
% Nach Simulation
ros_publish(S.kpi, '/factory/kpi');
```

---

## 🎓 Für Studierende

### Typische Aufgaben

1. **Engpass-Analyse:**
   - Verschiedene Parameter testen
   - KPIs vergleichen
   - Optimale Konfiguration finden

2. **Optimierung:**
   - Erfolgsquote maximieren
   - Durchsatz erhöhen
   - Zykluszeit minimieren

3. **Erweiterungen:**
   - Zusätzliche Maschine hinzufügen
   - Qualitätskontrolle implementieren
   - Wartungsintervalle einbauen

---

### Hilfreiche Befehle

```matlab
% Projekt-Status prüfen
which config -all

% Alle Funktionen anzeigen
help simulate_factory_line_3R2M_pflichtenheft

% Visualisierung ohne Simulation
draw_scene_2d_pflichtenheft(config())

% Snapshot erstellen
capture_sim_snapshot(S, 'mein_snapshot')
```

---

## 📚 Weitere Dokumentation

- **AUFRÄUMPLAN.md** - Vollständige Dateianalyse
- **LÖSCHEMPFEHLUNG.md** - Aufräum-Anleitung
- **VALIDIERUNGSBERICHT.md** - Bestätigung der Änderungen
- **Hilfs-Dokumente/** - Zusätzliche Dokumentation

---

## ⚠️ Häufige Probleme

### Problem 1: "Undefined function 'config'"

**Lösung:**
```matlab
startup_project  % Pfade neu laden
```

---

### Problem 2: Niedrige Erfolgsquote (< 90%)

**Lösung:**
```matlab
% Längere Simulation
S = simulate_factory_line_3R2M_pflichtenheft('Tsim', 300);

% Oder häufigerer Transport
S = simulate_factory_line_3R2M_pflichtenheft('transport_interval', 10);
```

---

### Problem 3: Simulation zu langsam

**Lösung:**
```matlab
% Visualisierung ausschalten
S = simulate_factory_line_3R2M_pflichtenheft('showPlots', false);
```

---

## 🎯 Zusammenfassung

**Minimale Nutzung (3 Befehle):**
```matlab
startup_project
S = simulate_factory_line_3R2M_pflichtenheft();
test_pflichtenheft
```

**Mit Parametern:**
```matlab
S = simulate_factory_line_3R2M_pflichtenheft( ...
    'Tsim', 180, ...
    'spawn_rate', 0.8, ...
    'machine_Tproc', [4.0, 5.0] ...
);
```

**KPIs analysieren:**
```matlab
fprintf('Erfolgsquote: %.2f%%\n', S.kpi.successRate * 100);
fprintf('Durchsatz: %.2f Teile/min\n', S.kpi.throughput);
fprintf('M1 Auslastung: %.1f%%\n', S.kpi.utilization.M1 * 100);
```

---

**Viel Erfolg mit der Simulation! 🚀**

**Bei Fragen:** Siehe Dokumentation in `Hilfs-Dokumente/` oder `test_pflichtenheft.m` für Beispiele.

---

**Version:** 2.0 (Aufgeräumt)  
**Datum:** 2025-01-XX  
**Status:** ✅ Pflichtenheft-konform, teamfähig, vollständig dokumentiert
