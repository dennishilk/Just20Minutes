# Just 20 Minutes

[![Release](https://img.shields.io/badge/Release-v1.0.2-1E90FF?style=flat-square)](https://github.com/dennishilk/Just20Minutes/releases/tag/v1.0.2) [![WoW Forever](https://img.shields.io/badge/WoW-Forever-8A2BE2?style=flat-square)](https://github.com/dennishilk/Just20Minutes) ![Interface](https://img.shields.io/badge/Interface-16001-F59E0B?style=flat-square) ![Lua](https://img.shields.io/badge/Lua-5.1-2C2D72?style=flat-square&logo=lua&logoColor=white) [![CI](https://github.com/dennishilk/Just20Minutes/actions/workflows/release.yml/badge.svg)](https://github.com/dennishilk/Just20Minutes/actions/workflows/release.yml) [![MIT License](https://img.shields.io/badge/License-MIT-22A06B?style=flat-square)](LICENSE) ![Languages](https://img.shields.io/badge/Languages-DE%20%7C%20EN-0EA5E9?style=flat-square)

**Your friendly WoW session timer.** *Enjoy Azeroth. Remember real life.*

**Author:** Dennis Hilk | **Version:** 1.0.2 | **WoW Forever interface:** 16001 | **License:** MIT

[Deutsch](README.de.md) · [Download releases](https://github.com/dennishilk/Just20Minutes/releases) · [Report an issue](https://github.com/dennishilk/Just20Minutes/issues)

Choose your playtime, enjoy Azeroth and get gentle reminders before it's time to finish. **This addon is voluntary, not parental control.** It never logs you out, touches your character, tracks other people or accesses the network.

## Features

- Eight presets (10/15/20/30/45/60/90/120 minutes), custom 1–600 minutes, a default of 20 minutes.
- Timer: start, pause, resume, stop, reset, +5/+10/+15/custom extension. HH:MM:SS for long sessions.
- Draggable, position-lockable widget with 70–150% scale, opacity, compact mode, progress bar, selectable themes and optional colorblind-friendly text status.
- Adaptive halfway/final reminders for 1–5-minute sessions, and one-time classic warnings at 10/5/2/0 minutes for longer adventures, individually configurable, including chat/screen/both/color-only/off, optional sound and defer-until-combat-ends.
- Readable five-second reminder toasts, calm gold/slate styling, grouped scrollable settings, clear enabled/disabled actions and explicit idle/paused statuses.
- Friendly wind-down guidance, optional Family Mode and end-of-session dialog with manual extensions.
- Full English and German UI, slash help and errors.
- Account settings plus per-character duration/position, profile copying and confirmed reset. Local SavedVariables only.
- A pocket-watch minimap icon: left-click opens the timer, right-click opens Settings; drag to move and toggle visibility in Appearance.
- Automatic session start on login is **off by default**. Enable it explicitly in General settings if you want it. The minimap icon never starts the timer itself.
- No required libraries, telemetry, advertising, accounts or external services.

## Installation

Download **Just20Minutes-v1.0.2.zip** from [GitHub Releases](https://github.com/dennishilk/Just20Minutes/releases). Extract its single **Just20Minutes** folder to the Forever AddOns directory:

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
                enUS.lua
                deDE.lua

Common Windows path: C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns. Under Linux/Lutris/Wine, find the game folder in your Wine prefix and use the corresponding _forever_/Interface/AddOns location. Restart or /reload; enable the addon in WoW's addon menu.

## Controls

Type **/j20** to open the window; select a preset or enter a custom minute value and press Enter, then Start. Drag the widget with the left mouse button (when unlocked); click its three-dot button to reopen the window.

| Slash command | What it does |
| --- | --- |
| /j20 or /just20minutes | Open timer |
| /j20 start | Start with default duration |
| /j20 start 60 | Start 60 minutes |
| /j20 pause, /j20 resume | Pause/resume |
| /j20 stop, /j20 reset | Stop/reset |
| /j20 add 10 | Extend ten minutes |
| /j20 status | Show remaining time |
| /j20 config | Settings |
| /j20 lock, /j20 unlock | Lock/unlock widget position |
| /j20 help | Command help |

All entered durations must be whole numbers from 1 to 600. At most 600 minutes of remaining time can be held after an extension. Start never silently replaces an already-running session.

Settings are divided into **General** (duration, start/login behavior), **Appearance** (scale, opacity, compact mode, progress, theme and position), **Notifications** (channels, sound, fight deferral, individual alerts), **Experience** (Family Mode, guidance, end dialog, language), **Profiles** (individual character duration/position, copying and reset) and **About**.

## Timer behavior and limitations

The countdown is based on elapsed GetTime(), not frame count. No time is consumed during a pause or while offline. By default a normal logout ends a session; enabling resume-on-login keeps the remaining time. /reload attempts to preserve the session.

**Caveat:** WoW's SavedVariables mechanism does not unambiguously distinguish logout from UI reload. The addon hooks ReloadUI() and uses a 15-second threshold as a fallback. A very fast relog can thus be treated like a reload even with resume disabled. A crash can lose recent updates because the game writes SavedVariables at logout/reload, not continuously.

### Short sessions that remember real life

Adaptive reminders are enabled by default for **new sessions of 1–5 minutes**:

| Session | First reminder | Final reminder | End |
| --- | --- | --- | --- |
| 1 minute | 0:30 | 0:10 | 0:00 |
| 2 minutes | 1:00 | 0:30 | 0:00 |
| 3 minutes | 1:30 | 1:00 | 0:00 |
| 5 minutes | 2:30 | 1:00 | 0:00 |
| 20 minutes | 10:00 and 5:00 | 2:00 | 0:00 |

For example, a two-minute adventure gets a friendly start, a halfway reminder, a final 30-second reminder and a closing message. Family Mode uses gentler wording. Longer sessions retain the individually configured classic warnings. A timer starting exactly at a threshold never warns immediately.

The plan is fixed when you press Start. Switch adaptive scheduling off under Notifications for future sessions; switching it off also mutes remaining adaptive reminders in a current session. Each scheduled warning is consumed once, even if muted. Pausing and reloading preserve the plan. Extensions retire the original halfway reminder and never re-arm consumed warnings, while allowing a new end reminder.

If a delayed update skips several thresholds, only the most urgent enabled reminder appears, with the actual remaining time. Combat deferral collapses reminders into one current-time summary. Screen notifications and the closing dialog always wait until combat ends; chat reminders can be immediate if combat deferral is disabled.

Choose **Screen**, **Chat**, **Both**, **Color only** or **Off**. Color only and Off suppress messages, sounds and automatic closing dialogs. Disabling the toast uses the client's native notice area for screen messages. Sound is off by default. The closing dialog and expiry reminder also have separate switches.

### A calmer interface

Ready is gold with a full bar, running uses your selected accent, approaching the end turns amber then coral, and pause is blue. Text describes the state too, including compact mode. Start/Pause/Resume/Extend availability follows the timer. The settings keep one stable size with scrollable, grouped pages. Widget, main-window and settings-window positions survive reload and are kept reachable after display changes.

About includes Dennis Hilk's personal **Normal (PvE)** realm and **Ostfriesen Raid** guild, plus selectable website, YouTube and project links. Click a URL and use **Ctrl+C**; open it in your browser.

**Family Mode changes language, not enforcement.** The addon cannot force a rest or act as a child safety lock.

## Tests, privacy and contributions

Run locally with Lua 5.1 and Python 3:

    lua5.1 tests/run.lua
    python3 scripts/package.py

GitHub Actions also performs syntax, mock-API regression and TOC/ZIP checks before publication. The author tested v1.0.1 in the real client on 22 November 2026. **The new v1.0.2 has automated mock-client validation only; its in-game acceptance test is still pending.** Follow the [manual in-game checklist](docs/MANUAL_TESTING.md). Mock layouts are not game screenshots.

There are no network calls, telemetry, ads or registration; preferences remain in WoW's local SavedVariables. Report defects and propose changes using [Issues](https://github.com/dennishilk/Just20Minutes/issues). See [CHANGELOG](CHANGELOG.md) and the preserved [MIT LICENSE](LICENSE).

More from Dennis: [Website](https://www.dennishilk.com) · [YouTube — Dennis Hilk](https://www.youtube.com/@dennis_hilk)
