local _, J = ...
local function validMinutes(n)
    return J.Finite(n, 1, 600) and n == math.floor(n)
end
J.ValidMinutes = validMinutes

function J.FormatTime(seconds)
    seconds = math.max(0, math.ceil(tonumber(seconds) or 0))
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    if h > 0 then return string.format("%02d:%02d:%02d", h, m, s) end
    return string.format("%02d:%02d", m, s)
end

function J.TimerRemaining()
    if not J.session then return 0 end
    if J.session.state == "RUNNING" and J.startedAt then
        return math.max(0, J.baseRemaining - math.max(0, J.Now() - J.startedAt))
    end
    return J.session.remaining
end

function J.TimerSave()
    local s = J.session
    if s.state == "RUNNING" then s.remaining = J.TimerRemaining() end
    s.exitEpoch = J.Epoch()
    s.reloadIntent = J.reloadRequested
    -- SavedVariables themselves flush only on logout/reload, not continuously.
end

function J.TimerRestore()
    local s = J.session
    if s.state == "RUNNING" or s.state == "PAUSED" then
        local gap = J.Epoch() - s.exitEpoch
        -- ReloadUI hook is authoritative when invoked; a short gap also covers
        -- interface reloads triggered by console or other addons. Short relogs
        -- may be mistaken for reloads: documented in README.
        local reloading = s.reloadIntent or
            (s.exitEpoch > 0 and gap >= 0 and gap <= 15)
        if not reloading and not J.settings.resumeOnLogin then
            s.state, s.remaining = "IDLE", 0
        elseif s.state == "RUNNING" then
            J.baseRemaining, J.startedAt = s.remaining, J.Now()
        end
    end
    s.exitEpoch, s.reloadIntent = 0, false
end

function J.TimerStart(minutes)
    minutes = tonumber(minutes)
    if not validMinutes(minutes) then
        J.Print(J.T("ERR_DURATION"))
        return false
    end
    if J.session.state == "RUNNING" or J.session.state == "PAUSED" then
        J.Print(J.T("ALREADY_RUNNING"))
        return false
    end
    local s = J.session
    s.state, s.remaining, s.duration, s.fired = "RUNNING", minutes * 60, minutes * 60, {}
    J.baseRemaining, J.startedAt = s.remaining, J.Now()
    J.widgetManuallyHidden = false
    if J.HideFinish then J.HideFinish() end
    J.settings.lastMinutes = minutes
    J.profile.minutes = minutes
    J.Notify("start")
    J.Refresh()
    return true
end

function J.TimerPause()
    if J.session.state ~= "RUNNING" then return false end
    J.session.remaining = J.TimerRemaining()
    J.session.state = "PAUSED"
    J.startedAt = nil
    J.Notify("pause")
    J.Refresh()
    return true
end

function J.TimerResume()
    if J.session.state ~= "PAUSED" then return false end
    J.baseRemaining, J.startedAt = J.session.remaining, J.Now()
    J.session.state = "RUNNING"
    J.Notify("resume")
    J.Refresh()
    return true
end

function J.TimerStop(silent)
    local s = J.session
    s.state, s.remaining, s.fired = "IDLE", 0, {}
    J.startedAt = nil
    if not silent then J.Notify("stop") end
    if J.HideFinish then J.HideFinish() end
    J.Refresh()
    return true
end

function J.TimerReset()
    J.TimerStop(true)
    J.session.duration = J.EffectiveMinutes() * 60
    J.Refresh()
end

function J.TimerAdd(minutes)
    minutes = tonumber(minutes)
    if not validMinutes(minutes) then
        J.Print(J.T("ERR_DURATION"))
        return false
    end
    local s = J.session
    if s.state == "IDLE" then
        J.Print(J.T("NOT_RUNNING"))
        return false
    end
    local remaining = J.TimerRemaining()
    if remaining + minutes * 60 > 36000 then
        J.Print(J.T("ERR_MAX_REMAINING"))
        return false
    end
    s.remaining = remaining + minutes * 60
    s.duration = math.max(s.duration, s.remaining)
    if s.state == "RUNNING" or s.state == "EXPIRED" then
        s.state = "RUNNING"
        J.baseRemaining, J.startedAt = s.remaining, J.Now()
    end
    if s.fired then s.fired["0"] = false end
    J.HideFinish()
    J.Notify("extend", minutes)
    J.Refresh()
    return true
end

function J.TimerPoll()
    local s = J.session
    if s.state ~= "RUNNING" then return end
    local previous = s.remaining
    local current = J.TimerRemaining()
    s.remaining = current
    if current <= 0 then
        s.remaining, s.state = 0, "EXPIRED"
        J.startedAt = nil
        J.NotificationsCheck(previous, 0)
    else
        J.NotificationsCheck(previous, current)
    end
    J.RefreshUI()
end

function J.TimerStatus()
    local state = J.T("STATE_" .. J.session.state)
    return string.format("%s: %s (%s)", J.T("TIME_REMAINING"),
        J.FormatTime(J.TimerRemaining()), state)
end
