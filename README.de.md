# Just 20 Minutes

**Dein freundlicher Spielzeit-Timer für WoW.** *Enjoy Azeroth. Remember real life.*

**Autor:** Dennis Hilk | **Version:** 1.0.0 | **WoW Forever:** Interface 16001 | **Lizenz:** MIT

[English](README.md) · [Downloads](https://github.com/dennishilk/Just20Minutes/releases) · [Fehler melden](https://github.com/dennishilk/Just20Minutes/issues)

**Just 20 Minutes** hilft dir, deine Zeit in Azeroth bewusst einzuteilen: Spielzeit wählen, Countdown starten und vor dem Ende in Ruhe verkaufen, reparieren, Quests abschließen oder einen schönen Ausloggplatz suchen. **Keine Kindersicherung:** Der Timer ist freiwillig; er kann niemanden ausloggen oder überwachen.

## Funktionen

- Fertige Spielzeiten 10/15/20/30/45/60/90/120 Minuten, frei wählbar 1–600, Standard 20 Minuten.
- Start, Pause, Fortsetzen, Beenden, Zurücksetzen, Verlängerung +5/+10/+15 oder frei; Stundenanzeige.
- Verschiebbares Widget mit Positionssperre, Skalierung 70–150 %, Transparenz, Kompaktmodus, Fortschrittsleiste, Farbstilen und zusätzlichem Warnstatus als Text.
- Einmalige Erinnerungen bei 10, 5, 2 und 0 Minuten, einzeln schaltbar; Chat-/Bildschirmhinweise, beide, nur Farbwechsel oder aus; optionaler Ton und Kampfaufschub.
- Freundliche Feierabendtipps, Family Mode sowie freiwilliges Abschlussfenster mit Verlängerung.
- Komplett Deutsch und Englisch, auch Hilfetexte, Fehler und Einstellungen.
- Accountweite Einstellungen, charakterbezogene Dauer/Position, Charakterprofile übernehmen und bestätigte Rücksetzung.
- Ohne Bibliotheken, Webzugriff, Registrierung, Werbung, Telemetrie oder Tracking.

## Installation

Das **Just20Minutes-v1.0.0.zip** von [GitHub Releases](https://github.com/dennishilk/Just20Minutes/releases) herunterladen, entpacken und den darin liegenden Ordner **Just20Minutes** hierher kopieren:

    World of Warcraft/
      _forever_/
        Interface/
          AddOns/
            Just20Minutes/
              Just20Minutes.toc
              Core.lua
              Database.lua
              Timer.lua
              Notifications.lua
              UI.lua
              Settings.lua
              Commands.lua
              Locales/
                deDE.lua
                enUS.lua

Unter Windows häufig: C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns. Unter Linux mit Lutris/Wine den WoW-Installationsordner im Wine-Prefix öffnen und dort den entsprechenden _forever_/Interface/AddOns-Ordner verwenden. Wichtig: keine doppelte Just20Minutes/Just20Minutes-Verschachtelung. Spiel neu starten oder /reload und Addon aktivieren.

## Nutzung

Mit **/j20** das Hauptfenster öffnen, Dauer wählen (bei eigenen Minuten Enter drücken) und Start klicken. Das Widget ist per linker Maustaste verschiebbar, solange nicht gesperrt. Die drei Punkte öffnen das Hauptfenster.

| Befehl | Bedeutung |
| --- | --- |
| /j20 oder /just20minutes | Hauptfenster |
| /j20 start | Mit Standarddauer starten |
| /j20 start 60 | 60 Minuten starten |
| /j20 pause, /j20 resume | Pause/Fortsetzen |
| /j20 stop, /j20 reset | Beenden/Zurücksetzen |
| /j20 add 10 | Zehn Minuten verlängern |
| /j20 status | Restzeit in Chat |
| /j20 config | Einstellungen |
| /j20 lock, /j20 unlock | Widget sperren/entsperren |
| /j20 help | Hilfe |

Die Einstellungsseiten heißen **Allgemein** (Dauer, Login), **Darstellung** (Größe, Transparenz, Kompakt, Farben, Position), **Benachrichtigungen** (Kanäle, Zeiten, Ton, Kampf), **Spielerlebnis** (Family Mode, Tipps, Abschluss, Sprache), **Profile** (Charakterdauer und Position, Übernahme, Reset) und **Über**.

## Speicherung und technische Grenzen

Die Restzeit wird anhand von GetTime() und echter Spielzeit berechnet, nicht durch Zählen von Bildern pro Sekunde. Während Pause oder Offline-Zeit läuft nichts weiter. Normaler Logout beendet die Sitzung standardmäßig; mit aktivierter Wiederaufnahme bleibt die Restzeit erhalten.

Ein /reload soll den Timer erhalten. Allerdings unterscheidet WoW bei SavedVariables nicht zuverlässig zwischen Logout und Reload. Deshalb benutzt das Addon ReloadUI() und zusätzlich eine 15-Sekunden-Heuristik. Bei sehr schnellem Aus- und Einloggen kann daher trotz deaktivierter Wiederaufnahme der Timer weiterlaufen. **Nach einem Clientabsturz können die letzten Änderungen verloren gehen**, weil SavedVariables nicht laufend auf die Festplatte geschrieben werden.

Warnungen erscheinen je Sitzung nur einmal pro Schwelle. Werden mehrere übersprungen, kommt nur die dringendste noch aktive. Eine Verlängerung wiederholt alte 10/5/2-Minuten-Warnungen nicht, kann aber einen weiteren Ablaufhinweis auslösen. Bei kurzen Sitzungen erscheint keine 10-Minuten-Warnung gleich beim Start. Im Kampf lassen sich Hinweise und Abschlussfenster zurückhalten; der Timer zählt weiter, ohne Spielaktionen auszuführen.

Der **Family Mode** ändert nur die freundliche Ansprache, nicht die Berechtigungen. Es gibt keine PIN, kein Elterntracking und keinen automatischen Logout.

## Tests, Mitmachen und Datenschutz

Lokale Prüfung mit Lua 5.1 und Python 3:

    lua5.1 tests/run.lua
    python3 scripts/package.py

GitHub Actions prüft außerdem Syntax, Tests, TOC und Installations-ZIP. **Ein erfolgreicher echter WoW-Forever-Ingame-Test wird nicht behauptet.** Die [manuelle Testliste](docs/MANUAL_TESTING.md) beschreibt die Abnahme. Echte Screenshots erst nach einem Test.

Daten bleiben lokal in WoWs SavedVariables. Keine externen Dienste, Konten, Werbung oder Telemetrie. Feedback über [Issues](https://github.com/dennishilk/Just20Minutes/issues). Siehe [CHANGELOG](CHANGELOG.md) und die unveränderte [MIT-Lizenz](LICENSE).
