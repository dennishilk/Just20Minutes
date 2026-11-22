# Changelog

## [1.0.4] - 2026-11-22

- Remove the Buy Me a Coffee link and donation labels from the in-game About page.
- Keep the optional support link on the English and German README pages only.
- Retain the existing website, YouTube and GitHub links and all timer features.

## [1.0.3] - 2026-11-22

- Add Dennis's optional Buy Me a Coffee link to About, with localized German/English labels and the same selectable, keyboard-accessible URL fields.
- Add the support link to both READMEs; preserve previous releases.

## [1.0.2] - 2026-11-22

- Introduce a shared slate/gold UI, semantic action colors, readable countdown, explicit idle/paused states and a full neutral idle progress bar.
- Group all six settings pages into scrollable sections with a highlighted navigation selection, live appearance changes and usable disabled controls.
- Add persisted adaptive reminder plans for 1–5-minute sessions: halfway plus a final reminder; retain classic warnings for longer sessions.
- Consume each threshold once, collapse lag/combat crossings into truthful current-time reminders, preserve plans through reloads, and prevent halfway replay after extensions.
- Add five-second screen reminder toasts, optional native-notice fallback, default-off built-in sound and family-specific short-session/closing text.
- Refine the completion dialog, minimap status tooltip, window placement, scaling and display-change clamping.
- Add localized player details (Dennis Hilk, Normal PvE, Ostfriesen Raid) and selectable website/YouTube/project URLs to About.
- Migrate schema-1 SavedVariables without losing account preferences, character profiles, minimap position or opt-in login behavior.
- Expand automated Lua 5.1 regression coverage and strict UI mocks; validate deterministic addon ZIPs and version consistency. Publish releases only after the validation job succeeds; never overwrite an existing release.
- v1.0.2 real-client in-game validation remains pending.

## [1.0.1] - 2026-11-22

- Add a dependency-free pocket-watch minimap button to open the timer (left-click) or Settings (right-click).
- Drag and remember the minimap icon's position; add visibility toggle and reset button.
- Confirm login auto-start is off by default and requires explicit activation in Settings.
- Add regression tests for the minimap button and login auto-start.

## [1.0.0] - 2026-11-22

- Initial implementation of Just 20 Minutes for WoW Forever (Interface 16001).
- Time-accurate session timer, presets, custom durations and extensions.
- Native movable widget, compact display, scale, opacity, color and text statuses.
- Individual reminders, combat deferral, optional Family Mode and ending dialog.
- German and English localization, commands, settings and character profiles.
- SavedVariables validation, mocked Lua tests, CI and install-ZIP builder.
- Real-client in-game validation pending.
