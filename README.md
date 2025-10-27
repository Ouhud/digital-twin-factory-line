# 🏭 Digital Twin Factory Line  
**Simulations-Framework einer digitalen Fertigungslinie in MATLAB**

---

## 📘 Projektbeschreibung

Dieses MATLAB-Projekt modelliert und simuliert eine **digitale Fertigungslinie (Digital Twin Factory Line)** mit Förderbändern, Maschinen und kollaborierenden Robotern.  
Es dient sowohl der **industriellen Weiterentwicklung** (für Entwicklerteams) als auch der **wissenschaftlichen Analyse** im Rahmen von Hochschulprojekten.

Ziel des Projekts ist die Abbildung einer realen Produktionsumgebung als **Digital Twin** zur Untersuchung von:
- Material- und Informationsflüssen,  
- Prozesszeiten und Zykluszeiten,  
- Ressourcenauslastungen und Effizienz (KPIs),  
- sowie zur **Visualisierung** und **Optimierung** komplexer Fertigungssysteme.

Das Projekt ist modular aufgebaut: jede Funktion, jeder Roboter, jede Maschine und jedes Förderband ist als eigenständiges MATLAB-Modul implementiert.

---

## 📂 Verzeichnisstruktur

| Ordner | Beschreibung |
|--------|---------------|
| **Core/** | Kernmodule der Simulation: Maschinen, Roboter, Förderband, Puffer, Konfiguration und Basissimulation. |
| **digital-twin/** | Steuerlogik, Hauptsimulationen und Datenanalyse der digitalen Zwillinge. |
| **helpers/** | Hilfsfunktionen wie Pfad-Management, Snapshot-Erstellung, Namens- und Zeitformatierung. |
| **io/** | Kommunikationsschnittstellen (OPC UA, ROS, Logging). |
| **kpi/** | Kennzahlen-Berechnung (Durchsatz, Auslastung, Verfügbarkeit, Performance). |
| **viz/** | Visualisierung (2D- und 3D-Szenen, Animationen). |
| **reports/** | Automatische Berichtserstellung mit KPI-Grafiken und Übersichten. |
| **demos/** | Beispielsimulationen für verschiedene Layouts (1 Band, 2 Bänder, 2 Lager usw.). |
| **out/** | Ausgabeordner für CSV-, MAT- und Grafikdateien. |
| **startup_project.m** | Initialisiert das Projekt (Pfad-Setup, Standardparameter, Addpath-Konfiguration). |

---

## ⚙️ Hauptskripte und ihre Funktion

| Datei | Funktion |
|-------|-----------|
| `startup_project.m` | Initialisiert das MATLAB-Projekt, fügt alle Unterordner dem Pfad hinzu und überprüft Abhängigkeiten. |
| `digital-twin/run_all.m` | Führt alle Simulationen sequentiell aus (Benchmark- oder Vergleichsläufe). |
| `digital-twin/run_sim.m` | Startet eine Einzelsimulation mit Standardparametern. |
| `digital-twin/run_doe.m` | Führt ein **Design-of-Experiments (DoE)** durch, um Einflussgrößen systematisch zu variieren. |
| `demos/simulate_factory_line.m` | Simulation einer Standardlinie mit einem Förderband, zwei Maschinen und drei Robotern. |
| `demos/simulate_factory_line_2belts.m` | Simulation mit zwei parallelen Förderbändern und drei Robotern. |
| `demos/simulate_factory_line_2stores.m` | Simulation mit zwei separaten Ausgangslagern für Materialtrennung. |
| `Core/simulate.m` | Zentrales Simulations-Framework: verwaltet Hauptschleife, Ereignisse und Zustandsfortschreibung. |

---

## 🧩 Wichtige Funktionsmodule (Core)

| Datei | Beschreibung |
|--------|---------------|
| **config.m** | Erstellt die vollständige Simulationskonfiguration (Zeitschritt `dt`, Laufzeit `Tsim`, Bandgeschwindigkeit, Prozesszeiten usw.). |
| **fsm_machine.m** | Zustandsmaschine einer Maschine – steuert Phasen *Idle → Processing → Done*. |
| **fsm_robot.m** | Zustandsmaschine eines Roboters – definiert Rollen wie *Supply*, *Collect*, *Ship* und deren Übergänge. |
| **buffer_store.m** | FIFO-Speicher für Material zwischen Prozessen; stellt Methoden `.push`, `.pop`, `.is_empty` bereit. |
| **conveyor_model.m** | Simuliert ein Förderband mit Bewegung der Werkstücke entlang vordefinierter Stationen. |
| **material_source.m / material_source_step.m** | Erzeugt neue Teile (Spawn-Rate) und legt sie im Eingabepuffer ab. |
| **kinematics_3R_planar.m** | Beispiel einer 3R-Planar-Roboterkinematik zur Positionierung. |
| **plot_source_buffer.m** | Visualisiert aktuelle Zustände von Quellen und Puffern im Diagramm. |
| **simulate.m** | Übergeordnete Steuerung der Simulationsschleife – Verwaltung von Zeit, Ereignissen und Zuständen. |

---

## 📊 KPI-Module (Key Performance Indicators)

| Datei | Beschreibung |
|--------|---------------|
| `kpi_init.m` | Initialisiert alle Kennzahlenstrukturen (Durchsatz, Bearbeitungszeit, Auslastung). |
| `kpi_update.m` | Aktualisiert KPI-Werte pro Simulationsschritt basierend auf Robotik- und Maschinenereignissen. |
| `kpi_finalize.m` | Berechnet aggregierte KPIs (z. B. durchschnittlicher Durchsatz pro Minute). |
| `export_kpi.m` | Exportiert KPI-Daten als `.csv`, `.mat` und `.json`. |
| `pm_estimator.m` | Optionale Schätzung von Wartungsintervallen (Predictive Maintenance). |

---

## 🖼️ Visualisierung (viz/)

| Datei | Beschreibung |
|--------|---------------|
| `draw_scene_2d.m` | Zeichnet eine zweidimensionale Ansicht der Fertigungslinie (Bänder, Maschinen, Roboter). |
| `draw_scene_3d.m` | Erstellt eine dreidimensionale Szene zur erweiterten Visualisierung. |
| `animate_step.m` | Führt die Animation schrittweise aus und zeigt aktuelle Positionen und Zustände. |

---

## 🔌 I/O und Kommunikation (io/)

| Datei | Beschreibung |
|--------|---------------|
| `opcua_write.m` | Überträgt Simulationsdaten an eine OPC UA-Schnittstelle (z. B. Siemens MindSphere / TwinCAT). |
| `ros_publish.m` | Publiziert Nachrichten über ROS 1 oder ROS 2 zur Integration mit realen Robotern. |
| `logger.m` | Universelles Logging-System für Status- und Ereignisprotokolle. |

---

## 🧠 Hilfsfunktionen (helpers/)

| Datei | Beschreibung |
|--------|---------------|
| `capture_sim_snapshot.m` | Speichert einen Schnappschuss des aktuellen Simulationszustands. |
| `dir_last.m` | Gibt den zuletzt erstellten Unterordner eines Verzeichnisses zurück. |
| `eta_in_window.m` | Berechnet die geschätzte Restzeit für laufende Simulationen. |
| `scale_ptp_time.m` | Skaliert Bewegungszeiten zwischen Punkten (PTP-Profile). |
| `util_nowstamp.m` | Erzeugt Zeitstempel (`yyyyMMdd_HHmmss`) für Dateibenennung. |
| `util_basename.m` | Entfernt Pfadanteile aus Dateinamen. |
| `util_find_out_dir.m` | Sucht automatisch das Ausgabeverzeichnis. |

---

## 📈 Berichtserstellung (reports/)

| Datei | Beschreibung |
|--------|---------------|
| `make_overview_figure.m` | Erstellt eine grafische Übersicht der Produktionslinie und KPIs. |
| `make_overview_illustrated.m` | Generiert bebilderte Reports mit Diagrammen, Layout und Ergebniswerten. |

---

## 🚀 Simulation starten

### Option 1 – Interaktiv (MATLAB GUI)
```matlab
>> startup_project
>> run_all




## ⚙️ Ordner: Core/
### Zweck
Der Ordner **`Core/`** enthält die zentralen Basiskomponenten der digitalen Fabriklinie.  
Alle dynamischen Entitäten wie Roboter, Maschinen, Förderbänder oder Puffer werden hier modelliert.  
Diese Module sind unabhängig voneinander getestet und folgen einem einheitlichen API-Design mit klaren Methodenaufrufen (`.tick`, `.load`, `.unload`, `.push`, `.pop` etc.).

Sie bilden das Fundament der gesamten Simulation und werden von fast allen anderen Modulen (z. B. `scheduler`, `kpi_update`, `simulate_factory_line_3R2M`) verwendet.

---

### 🔹 Datei: `buffer_store.m`

**Funktion:**  
Implementiert einen **FIFO-Pufferspeicher** („First In – First Out“) für Werkstücke.  
Er dient als Zwischenlager zwischen Materialquelle, Förderband und Maschine.

**Aufbau & Methoden:**
| Methode | Beschreibung |
|----------|---------------|
| `B.push(item)` | Fügt ein neues Element am Ende der Warteschlange hinzu. |
| `B.pop()` | Entfernt und liefert das erste Element. |
| `B.peek()` | Gibt das erste Element zurück, ohne es zu entfernen. |
| `B.len()` / `B.count()` | Gibt die aktuelle Anzahl der gespeicherten Teile zurück. |
| `B.is_empty()` | Prüft, ob der Puffer leer ist. |
| `B.is_full()` | Prüft, ob der Puffer die maximale Kapazität erreicht hat. |

**Parameter:**
- `capacity` → maximale Anzahl gespeicherter Teile (`inf` = unbegrenzt)  
- `name` → optionaler Name des Puffers (z. B. `"in"`, `"outA"`)

**Rückgabe:**  
Struktur `B` mit Queue-internen Daten (`.q`) und Methoden.

**Verwendung:**  
- Materialzufuhr (`material_source`) legt Teile ab.  
- Roboter oder Maschinen entnehmen Teile über `pop()`.

**Weiterentwicklung:**  
- Erweiterbar mit Prioritäten oder FIFO/LIFO-Umschaltung.  
- Logging-Optionen könnten integriert werden (z. B. Zeitstempel beim Push).  

---

### 🔹 Datei: `config.m`

**Funktion:**  
Zentrale Erzeugung der **Simulationsparameter (Konfiguration)**.  
Definiert Standardwerte für Zeit, Geschwindigkeit, Prozessparameter und Layout.

**Parameter (Auszug):**
| Parameter | Bedeutung | Standardwert |
|------------|------------|--------------|
| `Tsim` | Gesamte Simulationszeit [s] | 60 |
| `dt` | Zeitschrittweite [s] | 0.05 |
| `spawn_rate` | Materialzufuhr (Teile pro Sekunde) | 0.5 |
| `belt_speed` | Geschwindigkeit des Förderbands [m/s] | 0.30 |
| `belt_len` | Länge des Förderbands [m] | 2.0 |
| `stations_pos` | Positionen der Maschinen entlang des Bands [m] | `[0.8, 1.4]` |
| `machine_Tproc` | Bearbeitungszeit jeder Maschine [s] | `[4.0, 5.5]` |
| `rob_move_time` | Dauer einer Roboterbewegung [s] | 0.8 |
| `rob_action_time` | Dauer einer Pick/Place-Aktion [s] | 0.3 |
| `showPlots` | 2D-Visualisierung aktivieren | true |
| `show3D` | 3D-Visualisierung aktivieren | false |

**Rückgabe:**  
Struktur `C` mit allen Konfigurationsfeldern (direkt über `config(...)` abrufbar).

**Verwendung:**  
- Wird in jeder Simulation (`simulate_factory_line`, `scheduler`, `fsm_robot`) aufgerufen.  
- Alle Submodule greifen auf dieselbe Struktur `C` zu.  

**Weiterentwicklung:**  
- Erweiterbar um zufällige Taktzeiten oder stochastische Modelle.  
- Kann um Produktionslinienparameter (z. B. Energieverbrauch, Wartungsintervalle) ergänzt werden.

---

### 🔹 Datei: `conveyor_model.m`

**Funktion:**  
Modelliert das **Förderband** zwischen den Stationen.  
Es bewegt Werkstücke entlang definierter Positionen (`stations_pos`) und erlaubt das **Auflegen (load)** und **Entnehmen (take)** durch Roboter.

**Parameter:**
| Parameter | Bedeutung |
|------------|------------|
| `L` | Länge des Bands [m] |
| `v` | Geschwindigkeit des Bands [m/s] |
| `stations_pos` | Positionen der Stationen (Roboter/Maschinen) |

**Hauptmethoden:**
| Methode | Beschreibung |
|----------|---------------|
| `B.step(dt)` | Bewegt alle Teile entlang des Bands um `v * dt`. |
| `B.can_pick(x_at)` | Prüft, ob an der Position `x_at` ein Teil liegt. |
| `[B, part] = B.take(x_at)` | Entnimmt ein Teil an der Station `x_at`. |
| `[B, ok] = B.load(part, x_at)` | Legt ein neues Teil auf das Band. |

**Innere Logik:**  
- Verwaltet alle Teile als Strukturarray (`B.items`).  
- Jedes Teil besitzt Attribute: `id`, `pos`, `created_s`, `src`, `meta`.  
- Toleranzbereich für Positionserkennung beträgt 3 cm (`tol = 0.03`).

**Lokale Hilfsfunktionen:**
- `normalize_item()` – Normalisiert Strukturen (id, pos, src).  
- `align_fields()` – Stellt gleiche Feldreihenfolge zwischen Objekten sicher.

**Verwendung:**  
- Wird in allen Demo-Simulationen verwendet (1–2 Bänder).  
- Roboter (R1–R3) greifen über `can_pick` und `take` auf Bandteile zu.  

**Weiterentwicklung:**  
- Integration von Bandstörungen oder Sensorverzögerungen.  
- Erweiterung um mehrspurige Bänder oder Rückläufe.  
- Unterstützung für mehrere parallele Bänder (Multi-Line).

---

### 🔹 Datei: `fsm_machine.m`

**Funktion:**  
Definiert den **Zustandsautomaten einer Maschine** (Finite State Machine).  
Die Maschine durchläuft die Phasen:  
`idle → processing → done → idle`

**Parameter:**
| Parameter | Bedeutung |
|------------|------------|
| `id` | Maschinen-ID |
| `Tproc` | Bearbeitungszeit [s] |

**Wichtige Felder:**
| Feld | Bedeutung |
|-------|------------|
| `state` | aktueller Zustand (`idle`, `processing`, `done`) |
| `is_busy` | true, wenn Maschine belegt |
| `done_flag` | true, wenn Bearbeitung abgeschlossen |
| `part` | aktuell bearbeitetes Teil |
| `stats.active` / `stats.idle` | kumulierte Zeitanteile |

**Methoden:**
| Methode | Beschreibung |
|----------|---------------|
| `M = M.tick(M, env, dt)` | Zeitfortschritt und Zustandswechsel. |
| `[M, ok] = M.load(M, part)` | Neues Teil übernehmen und Bearbeitung starten. |
| `[M, part] = M.unload(M)` | Fertiges Teil abgeben, Zustand wieder `idle`. |
| `M.has_done(M)` | Prüft, ob Maschine fertig ist. |

**Ablauf:**
1. **Idle:** wartet auf ein neues Teil.  
2. **Processing:** Bearbeitung läuft; Timer wird reduziert.  
3. **Done:** Teil fertig, wartet auf Abholung.  

**Verwendung:**  
- Wird durch Roboter oder Scheduler angesteuert.  
- Rückgabeobjekt enthält stets aktualisierte Stati.

**Weiterentwicklung:**  
- Einbindung von Qualitätsprüfungen oder Ausschussquote.  
- Erweiterung um mehrere Prozessmodi (z. B. Warm-up, Fehlerzustand).  

---

### 🔹 Datei: `fsm_robot.m`

**Funktion:**  
Zustandsautomat für **Roboter** mit erweitertem Scheduler-Interface (`on_pick` / `on_place`).  
Unterstützt verschiedene Rollen:  
- **R1:** Supply (Einspeisung)  
- **R2:** Collect (Maschinenentladung)  
- **R3:** Ship (Versand)

**Parameter:**  
| Parameter | Bedeutung |
|------------|------------|
| `name` | Robotername (z. B. `"R1"`, `"R2"`, `"R3"`) |
| `C` | Konfiguration (aus `config.m`) |

**Zustände:**
`idle → move_in → pick → move_to_target → place → idle`

**Ablaufbeschreibung:**
1. **Idle:** Roboter prüft, ob er ein Teil aufnehmen kann (`can_pick`).  
2. **Move_in:** fährt zur Aufnahmeposition (Timer `t_move`).  
3. **Pick:** nimmt Teil auf (`on_pick()`).  
4. **Move_to_target:** fährt zur Ablageposition.  
5. **Place:** legt Teil ab (`on_place()`), kehrt danach in `idle` zurück.  

**Events:**  
- `"move_in"`, `"pick_start"`, `"pick_done"`, `"arrived_target"`, `"place_done"`, `"place_retry"`  

**Statistiken:**  
- `R.stats.active` – kumulierte aktive Zeit  
- `R.stats.idle` – kumulierte Wartezeit  

**Verwendung:**  
- Wird von Scheduler oder Simulationsskripten (z. B. `simulate_factory_line`) aufgerufen.  
- Nutzt Environment-Strukturen (`envR1`, `envR2`, `envR3`) mit `on_pick`/`on_place`.  

**Weiterentwicklung:**  
- Erweiterung auf kollaborative Roboterstrategien (z. B. Shared Buffer).  
- Integration mit realen ROS-Nachrichten für Online-Betrieb.  
- Erweiterbar für Roboterarme mit inverse Kinematik (`kinematics_3R_planar.m`).  

---

## 🧩 Zusammenfassung der Architektur (Core)

| Komponente | Typ | Hauptverantwortung |
|-------------|-----|--------------------|
| `buffer_store` | Datenstruktur | Verwaltung von Zwischenpuffern |
| `config` | Konfiguration | zentrale Parametrierung der Simulation |
| `conveyor_model` | Physikalisches Modell | Materialtransport entlang des Bandes |
| `fsm_machine` | Zustandsautomat | Steuerung einer Maschine |
| `fsm_robot` | Zustandsautomat | Steuerung eines Roboters |

---

## 💡 Entwicklerhinweise

- Alle Core-Komponenten sind **zustandsbehaftete Strukturen mit Methoden**,  
  kompatibel mit der MATLAB-OOP-Syntax, aber leichtgewichtig.  
- Jeder Zustand (`R.state`, `M.state`) wird in jedem Zeitschritt aktualisiert.  
- Für Debugging kann `disp(R)` oder `disp(M)` genutzt werden, um Statusänderungen zu verfolgen.
- `Core/` bildet die Grundlage für Simulationen in `/digital-twin` und `/demos`.  



## ⚙️ Core/ (Teil 2) – Erweiterte Kernmodule

Der zweite Teil der Core-Komponenten ergänzt die physikalische Simulation um Robotik, Materialerzeugung und Bewegungsmodelle.  
Diese Module bilden das Bindeglied zwischen Simulation (z. B. `simulate_digital_twin_conveyor_pickplace`) und den realitätsnahen Produktionsmodellen.

---

### 🔹 Datei: `kinematics_3R_planar.m`

**Funktion:**  
Berechnet die **Vorwärtskinematik eines 3R-Planarroboters** (3 Gelenke, 3 Längen).  
Der Roboter bewegt sich in einer Ebene (x–y), wodurch alle Gelenkpositionen exakt bestimmt werden können.

**Parameter:**
| Parameter | Bedeutung |
|------------|------------|
| `theta` | Gelenkwinkel [rad], Vektor `[t1 t2 t3]` |
| `L` | Gliederlängen [m], Vektor `[l1 l2 l3]` |

**Rückgabe:**
| Variable | Beschreibung |
|-----------|---------------|
| `P` | Endeffektorposition `[x y]` |
| `joints` | Koordinaten aller Gelenke `[(0,0); (x1,y1); (x2,y2); (x3,y3)]` |

**Mathematisches Modell:**
\[
x_3 = L_1 \cos(t_1) + L_2 \cos(t_1+t_2) + L_3 \cos(t_1+t_2+t_3)
\]
\[
y_3 = L_1 \sin(t_1) + L_2 \sin(t_1+t_2) + L_3 \sin(t_1+t_2+t_3)
\]

**Verwendung:**  
- Visualisierung und inverse Kinematik im Rahmen der Robotik-Simulation.  
- Referenzmodell für Planar-Manipulatoren im Modul Robotiksysteme.  

**Weiterentwicklung:**  
- Erweiterbar zu 6-DOF-Robotern (seriell oder SCARA).  
- Integrierbar in reale Steuerungssoftware (ROS/MoveIt).  

---

### 🔹 Datei: `material_source.m`

**Funktion:**  
Definiert eine **Materialquelle (Eingangslager)**, die neue Teile generiert.  
Das System arbeitet deterministisch mit einer festen **Spawn-Rate**.

**Parameter:**
| Parameter | Bedeutung |
|------------|------------|
| `rate` | Anzahl erzeugter Teile pro Sekunde (Standard = 0.5 1/s) |

**Rückgabe:**  
Struktur `S` mit Feldern:
| Feld | Bedeutung |
|-------|------------|
| `.rate` | Spawn-Rate [1/s] |
| `.acc` | interner Akkumulator für Teil-Generierung |
| `.next_id` | eindeutige ID-Zählung |
| `.name` | Name der Quelle (z. B. `"SRC"`) |

**Verwendung:**  
- Wird von `material_source_step` zyklisch aufgerufen.  
- Stellt sicher, dass alle Teile eindeutige IDs besitzen.  

---

### 🔹 Datei: `material_source_step.m`

**Funktion:**  
Erzeugt neue Teile im Eingangspuffer (`buffer_store`) auf Basis der eingestellten Spawn-Rate.  
Das Modul implementiert den eigentlichen **Zufluss der Materialteile** während der Simulation.

**Parameter:**
| Parameter | Bedeutung |
|------------|------------|
| `S` | Materialquelle (aus `material_source`) |
| `buf` | Pufferspeicher (aus `buffer_store`) |
| `dt` | Zeitschritt [s] |

**Ablaufbeschreibung:**
1. Akkumulation `S.acc += rate * dt`  
2. Wenn `S.acc ≥ 1.0`, wird ein neues Teil erstellt:  
   ```matlab
   part = struct('id', S.next_id, 't_created', datetime("now"), 'pos', 0.0);






