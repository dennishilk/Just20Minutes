# WoW Forever in-game acceptance checklist

Real-client tests are required; mocks cannot count as an in-game pass. Record GetBuildInfo() and exact Lua errors if failures occur.

1. Unzip into the _forever_/Interface/AddOns folder. Enable Just 20 Minutes. Verify no loading error.
2. First login: welcome window, 20-minute default, Start/Settings/Maybe Later. Check the welcome does not recur after setup. The timer must not auto-start on future logins unless General > Auto-start is explicitly enabled.
3. Check minimap watch icon: left-click opens/closes the timer, right-click opens Settings. Drag it around the minimap and confirm position persists after /reload; hide/show it in Appearance, reset its position and ensure /j20 config can reopen settings even when the minimap icon is hidden. Then drag the countdown widget, lock it and test opacity/scale/compact/progress/theme/text state and position persistence after /reload.
4. Start 20 minutes, pause for 20 seconds, resume: verify no paused time was deducted. Test status, stop, reset and custom extension.
5. Start 1 minute. Check no already-passed reminder on start, 00:00 exact end, completion dialog, +5/+10/+15 and Finish for Today.
6. Verify 10/5/2 reminders on longer sessions and once-only behavior; test chat/screen/both/color-only/off, sound and Family Mode.
7. Enter combat near an alert and expiration. With combat deferral on, no interruption; dialog appears afterward. No automatic character action.
8. Try language auto, deDE and enUS; switch wind-down message option and completion modal preference.
9. Test /reload while running, paused and expired. Test logout >15 seconds with resume disabled, then with resume enabled. Offline time never counts.
10. Test a second character with unique duration/position, copy profile and reset with confirmation.
11. Try malformed commands: /j20 start -1, /j20 add 0, /j20 start 999999 and unknown commands. No Lua errors.
12. Back up WTF and test missing/corrupt SavedVariables, proper ZIP root folder, no network activity.

For bug reports include build number, enabled addons, reproduction steps and the actual error. Screenshots must come from a real game session.
