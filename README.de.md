# Just 20 Minutes

[![Release](https://img.shields.io/badge/Release-v1.0.4-1E90FF?style=flat-square)](https://github.com/dennishilk/Just20Minutes/releases/tag/v1.0.4) [![WoW Forever](https://img.shields.io/badge/WoW-Forever-8A2BE2?style=flat-square)](https://github.com/dennishilk/Just20Minutes) ![Interface](https://img.shields.io/badge/Interface-16001-F59E0B?style=flat-square) ![Lua](https://img.shields.io/badge/Lua-5.1-2C2D72?style=flat-square&logo=lua&logoColor=white) [![CI](https://github.com/dennishilk/Just20Minutes/actions/workflows/release.yml/badge.svg)](https://github.com/dennishilk/Just20Minutes/actions/workflows/release.yml) [![MIT License](https://img.shields.io/badge/License-MIT-22A06B?style=flat-square)](LICENSE) ![Languages](https://img.shields.io/badge/Languages-DE%20%7C%20EN-0EA5E9?style=flat-square)

**Dein freundlicher Spielzeit-Timer für WoW.** *Enjoy Azeroth. Remember real life.*

**Autor:** Dennis Hilk | **Version:** 1.0.4 | **WoW Forever:** Interface 16001 | **Lizenz:** MIT

[English](README.md) · [Downloads](https://github.com/dennishilk/Just20Minutes/releases) · [Fehler melden](https://github.com/dennishilk/Just20Minutes/issues)

**Just 20 Minutes** hilft dir, deine Zeit in Azeroth bewusst einzuteilen: Spielzeit wählen, Countdown starten und vor dem Ende in Ruhe verkaufen, reparieren, Quests abschließen oder einen schönen Ausloggplatz suchen. **Keine Kindersicherung:** Der Timer ist freiwillig; er kann niemanden ausloggen oder überwachen.

## Funktionen

- Fertige Spielzeiten 10/15/20/30/45/60/90/120 Minuten, frei wählbar 1–600, Standard 20 Minuten.
- Start, Pause, Fortsetzen, Beenden, Zurücksetzen, Verlängerung +5/+10/+15 oder frei; Stundenanzeige.
- Verschiebbares Widget mit Positionssperre, Skalierung 70–150 %, Transparenz, Kompaktmodus, Fortschrittsleiste, Farbstilen und zusätzlichem Warnstatus als Text.
- Intelligente Halbzeit-/Abschlusserinnerungen für 1–5 Minuten; längere Sitzungen behalten die klassischen Warnungen bei 10, 5, 2 und 0 Minuten, einzeln schaltbar; Chat-/Bildschirmhinweise, beide, nur Farbwechsel oder aus; optionaler Ton und Kampfaufschub.
- Lesbare Hinweisboxen für etwa fünf Sekunden, ruhige Gold-/Schieferfarben, gruppierte scrollbare Einstellungen und klar erkennbare Bereitschafts-/Pausenzustände.
- Freundliche Feierabendtipps, Family Mode sowie freiwilliges Abschlussfenster mit Verlängerung.
- Komplett Deutsch und Englisch, auch Hilfetexte, Fehler und Einstellungen.
- Accountweite Einstellungen, charakterbezogene Dauer/Position, Charakterprofile übernehmen und bestätigte Rücksetzung.
- Kleine Taschenuhr an der Minimap: Linksklick öffnet den Timer, Rechtsklick die Einstellungen; Ziehen verschiebt das Symbol. In Darstellung ein-/ausschaltbar.
- **Kein automatischer Timerstart beim Login:** Standardmäßig ausgeschaltet; nur unter Allgemein ausdrücklich aktivierbar. Das Minimap-Symbol startet selbst keine Sitzung.
- Ohne Bibliotheken, Webzugriff, Registrierung, Werbung, Telemetrie oder Tracking.

## Installation

Das **Just20Minutes-v1.0.4.zip** von [GitHub Releases](https://github.com/dennishilk/Just20Minutes/releases) herunterladen, entpacken und den darin liegenden Ordner **Just20Minutes** hierher kopieren:

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
              Minimap.lua
              Settings.lua
              Commands.lua
              LICENSE
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

### Kurze Abenteuer mit sinnvollen Erinnerungen

Intelligente Erinnerungen sind für **neue Sitzungen von 1–5 Minuten** standardmäßig aktiv:

| Sitzung | Erster Hinweis | Letzter Hinweis | Abschluss |
| --- | --- | --- | --- |
| 1 Minute | 0:30 | 0:10 | 0:00 |
| 2 Minuten | 1:00 | 0:30 | 0:00 |
| 3 Minuten | 1:30 | 1:00 | 0:00 |
| 5 Minuten | 2:30 | 1:00 | 0:00 |
| 20 Minuten | 10:00 und 5:00 | 2:00 | 0:00 |

Ein Zwei-Minuten-Timer begrüßt dich beim Start, erinnert zur Halbzeit und bei 30 Sekunden und verabschiedet dich am Ende. Im Family Mode klingt das besonders freundlich. Längere Sitzungen verwenden weiterhin die einzeln schaltbaren klassischen Warnungen. Beginnt eine Sitzung genau auf einer Warnzeit, erscheint keine sofortige Warnung.

Der Erinnerungsplan steht ab Start fest. Unter Benachrichtigungen lässt sich die intelligente Planung für künftige Sitzungen ausschalten; die Abschaltung unterdrückt auch noch ausstehende intelligente Hinweise einer laufenden Sitzung. Jede erreichte Warnung wird einmal verbraucht, auch bei ausgeschalteter Ausgabe. Pause und Reload erhalten den Plan. Verlängerungen verwerfen die ursprüngliche Halbzeit und wiederholen keine verbrauchten Warnungen; ein neuer Ablaufhinweis bleibt möglich.

Bei großen Zeitsprüngen erscheint nur der dringendste aktive Hinweis mit der tatsächlichen Restzeit. Nach einem Kampf werden aufgeschobene Warnungen zu einem aktuellen Hinweis zusammengefasst. Bildschirmfenster und Abschlussdialog warten immer auf das Kampfende. Chatmeldungen können bei deaktiviertem Kampfaufschub sofort erscheinen.

Zur Auswahl stehen **Bildschirmmitte**, **Chat**, **Beide**, **Nur Farbwechsel** und **Aus**. Nur Farbwechsel und Aus unterdrücken Meldungen, Töne und automatische Abschlussfenster. Ohne Hinweisbox verwendet die Bildschirmausgabe den Hinweisbereich des Clients. Der Ton bleibt standardmäßig aus. Abschlussdialog und Ablaufhinweis sind zusätzlich einzeln schaltbar.

### Eine ruhigere Oberfläche

Bereit erscheint goldfarben mit vollem Balken, die laufende Sitzung in der Akzentfarbe, knappe Zeit gelb bis korallrot und Pause blau. Ein Text beschreibt den Zustand auch im Kompaktmodus. Start, Pause, Fortsetzen und Verlängern passen zum Timerzustand. Die Einstellungen behalten eine feste Größe mit gruppierten, scrollbaren Seiten. Widget, Hauptfenster und Einstellungen merken sich ihre Position und bleiben nach Auflösungsänderungen erreichbar.

Die Infoseite nennt Dennis Hilk als Spieler auf **Normal (PvE)** in der Gilde **Ostfriesen Raid**. Website, YouTube und Projektseite stehen als markierbare Links bereit: anklicken, **Strg+C** drücken und im eigenen Browser öffnen.

Der **Family Mode** ändert nur die freundliche Ansprache, nicht die Berechtigungen. Es gibt keine PIN, kein Elterntracking und keinen automatischen Logout.

## Tests, Mitmachen und Datenschutz

Lokale Prüfung mit Lua 5.1 und Python 3:

    lua5.1 tests/run.lua
    python3 scripts/package.py

GitHub Actions prüft außerdem Syntax, Tests, TOC und Installations-ZIP. Version 1.0.1 wurde vom Autor am 22. November 2026 im echten Client getestet. **Für die neue Version 1.0.4 liegen automatisierte Tests mit einem simulierten Client vor; die Ingame-Abnahme steht noch aus.** Die [manuelle Testliste](docs/MANUAL_TESTING.md) beschreibt die Prüfung. Simulierte Layouts sind keine Ingame-Screenshots.

Daten bleiben lokal in WoWs SavedVariables. Keine externen Dienste, Konten, Werbung oder Telemetrie. Feedback über [Issues](https://github.com/dennishilk/Just20Minutes/issues). Siehe [CHANGELOG](CHANGELOG.md) und die unveränderte [MIT-Lizenz](LICENSE).

Mehr von Dennis: [Webseite](https://www.dennishilk.com) · [YouTube — Dennis Hilk](https://www.youtube.com/@dennis_hilk) · [Kaffeekasse](https://buymeacoffee.com/dennishilk)
