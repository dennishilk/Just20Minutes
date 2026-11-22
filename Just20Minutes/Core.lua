local addonName, J = ...
J.name, J.version = addonName, "1.0.1"
J.presets = {10, 15, 20, 30, 45, 60, 90, 120}
J.reloadRequested = false

function J.T(key, ...)
    local language = J.settings and J.settings.language or "auto"
    if language == "auto" then
        language = GetLocale() == "deDE" and "deDE" or "enUS"
    end
    local text = (J.locales[language] and J.locales[language][key])
        or J.locales.enUS[key] or key
    if select("#", ...) > 0 then
        local ok, formatted = pcall(string.format, text, ...)
        return ok and formatted or text
    end
    return text
end

function J.Now()
    return GetTime()
end

function J.Epoch()
    if type(time) == "function" then
        local ok, value = pcall(time)
        if ok and type(value) == "number" then return value end
    end
    return 0
end

function J.Print(message)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cffb7db76[Just 20 Minutes]|r " .. tostring(message))
    end
end

function J.Refresh()
    if J.RefreshUI then J.RefreshUI() end
    if J.RefreshSettings then J.RefreshSettings() end
end

function J.ShouldAutoStart()
    -- Only the user can enable automatic login start in Settings.
    return J.db and J.db.welcomeShown == true and J.settings
        and J.settings.autoStart == true and J.session
        and J.session.state == "IDLE"
end

function J.OnLogin()
    J.DBInit()
    J.TimerRestore()
    J.widgetManuallyHidden = not J.settings.showAtLogin
    J.BuildUI()
    J.BuildSettings()
    J.RegisterCommands()
    J.BuildMinimapButton()
    if J.settings.showAtLogin and (J.settings.widgetAlways or J.session.state ~= "IDLE") then
        J.RefreshUI()
    end
    if not J.db.welcomeShown then
        J.ShowWelcome()
    elseif J.ShouldAutoStart() then
        J.TimerStart(J.EffectiveMinutes())
    end
    J.Refresh()
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_LOGOUT")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        J.OnLogin()
    elseif event == "PLAYER_LOGOUT" then
        if J.session then J.TimerSave() end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if J.DeliverDeferred then J.DeliverDeferred() end
    end
end)

-- A throttle, not a frame-dependent countdown: elapsed time always comes from GetTime().
local accumulator = 0
events:SetScript("OnUpdate", function(_, elapsed)
    if not J.session or J.session.state ~= "RUNNING" then return end
    accumulator = accumulator + elapsed
    if accumulator >= 0.20 then
        accumulator = 0
        J.TimerPoll()
    end
end)
if type(hooksecurefunc) == "function" and type(ReloadUI) == "function" then
    hooksecurefunc("ReloadUI", function() J.reloadRequested = true end)
end
