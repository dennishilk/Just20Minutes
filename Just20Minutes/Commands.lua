local _, J = ...
local function usage()
    for _, key in ipairs({
        "HELP_1", "HELP_2", "HELP_3", "HELP_4", "HELP_5", "HELP_6"
    }) do J.Print(J.T(key)) end
end
local function handle(input)
    local command, arg = tostring(input or ""):match("^%s*(%S*)%s*(.-)%s*$")
    command = (command or ""):lower()
    if command == "" then J.OpenMain()
    elseif command == "start" then
        local minutes = arg == "" and J.EffectiveMinutes() or tonumber(arg)
        J.TimerStart(minutes)
    elseif command == "pause" then
        if not J.TimerPause() then J.Print(J.T("NOT_RUNNING")) end
    elseif command == "resume" then
        if not J.TimerResume() then J.Print(J.T("NOT_PAUSED")) end
    elseif command == "stop" then J.TimerStop()
    elseif command == "reset" then J.TimerReset()
    elseif command == "add" then J.TimerAdd(tonumber(arg))
    elseif command == "status" then J.Print(J.TimerStatus())
    elseif command == "config" or command == "settings" then J.OpenSettings()
    elseif command == "lock" then
        J.settings.locked = true; J.RefreshSettings(); J.Print(J.T("LOCKED"))
    elseif command == "unlock" then
        J.settings.locked = false; J.RefreshSettings(); J.Print(J.T("UNLOCKED"))
    elseif command == "help" then usage()
    else J.Print(J.T("UNKNOWN_COMMAND")); usage() end
end
J.HandleCommand = handle
function J.RegisterCommands()
    SLASH_JUST20MINUTES1 = "/j20"
    SLASH_JUST20MINUTES2 = "/just20minutes"
    SlashCmdList.JUST20MINUTES = handle
end
