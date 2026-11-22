local _, J = ...

function J.InCombat()
    return type(UnitAffectingCombat) == "function" and not not UnitAffectingCombat("player")
end

function J.NotificationsAllowed()
    return J.settings.mode ~= "off" and J.settings.mode ~= "color"
end

-- Frozen at Start, persisted across reloads. Extensions never move the original
-- halfway point or re-arm consumed warnings; only expiry may be re-armed.
function J.ReminderPlan()
    local s = J.session
    if s.reminderType == "adaptive" then
        local duration = s.planDuration
        local final = duration <= 60 and 10 or (duration <= 120 and 30 or 60)
        return {{key = "half", at = duration / 2}, {key = "final", at = final}}
    end
    return {{key = "600", at = 600}, {key = "300", at = 300}, {key = "120", at = 120}}
end

function J.NotificationsInit(restoring)
    local s = J.session
    s.planDuration = s.planDuration or s.duration
    s.reminderType = s.reminderType or
        (J.settings.adaptive and s.planDuration <= 300 and "adaptive" or "classic")
    s.fired = s.fired or {}
    -- No replay of passed thresholds when upgrading schema 1 or restoring.
    if restoring then
        for _, item in ipairs(J.ReminderPlan()) do
            if item.at >= s.planDuration or item.at >= s.remaining then
                s.fired[item.key] = true
            end
        end
    end
end

function J.ClearNotifications()
    J.deferred, J.pendingFinish = nil, false
    if J.HideToast then J.HideToast() end
end

function J.NotificationMessage(kind, value)
    local settings = J.settings
    if kind == "remaining" or kind == "half" or kind == "final" then
        local remaining = J.TimerRemaining()
        local clock = J.FormatTime(remaining)
        if kind == "half" and not settings.family and settings.windDown then
            return J.T("MSG_HALF", clock)
        end
        local key = settings.family and "FAMILY_REMAINING" or
            (settings.windDown and "MSG_REMAINING" or "SHORT_REMAINING")
        if settings.family and remaining == 60 then return J.T("FAMILY_ONE_MINUTE") end
        if remaining <= 60 and remaining == math.floor(remaining) then
            key = settings.family and "FAMILY_SECONDS" or
                (settings.windDown and "MSG_SECONDS" or "SHORT_SECONDS")
            return J.T(key, remaining)
        end
        return J.T(key, clock)
    end
    local key = ({start = "MSG_START", pause = "MSG_PAUSE", resume = "MSG_RESUME",
        stop = "MSG_STOP", extend = "MSG_EXTEND", expired = "MSG_EXPIRED",
        ["600"] = "MSG_600", ["300"] = "MSG_300", ["120"] = "MSG_120"})[kind]
    if not key then return nil end
    if settings.family and (kind == "expired" or tonumber(kind)) then
        key = kind == "expired" and "FAMILY_EXPIRED" or "FAMILY_" .. kind
    elseif not settings.windDown and tonumber(kind) then
        key = "SHORT_" .. kind
    end
    return J.T(key, value)
end

local function deliver(kind, value)
    if not J.NotificationsAllowed() then return end
    local message = J.NotificationMessage(kind, value)
    if not message then return end
    local mode = J.settings.mode
    if mode == "chat" or mode == "both" then J.Print(message) end
    if (mode == "screen" or mode == "both") and not J.InCombat() then
        if J.settings.toast and J.ShowToast then
            J.ShowToast(message, kind)
        elseif UIErrorsFrame and UIErrorsFrame.AddMessage then
            UIErrorsFrame:AddMessage(message, 0.89, 0.74, 0.41, 1, 5)
        end
    end
    if J.settings.sound and type(PlaySound) == "function" then
        -- The legacy name is supported by older clients without SOUNDKIT.
        local sound = type(SOUNDKIT) == "table" and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
            or "igMainMenuOptionCheckBoxOn"
        pcall(PlaySound, sound)
    end
end

function J.Notify(kind, value, source)
    if not J.NotificationsAllowed() then return end
    local warning = kind == "remaining" or kind == "half" or kind == "final" or kind == "expired" or tonumber(kind)
    if J.InCombat() and (J.settings.deferCombat or J.settings.mode ~= "chat") then
        if warning then J.deferred = {kind, value, source or kind} end
        -- User actions need no delayed replay; screen UI never interrupts combat.
        if not warning and J.settings.mode == "chat" and not J.settings.deferCombat then
            deliver(kind, value)
        end
        return
    end
    deliver(kind, value)
end

function J.DeliverDeferred()
    if J.InCombat() then return end
    local item = J.deferred
    J.deferred = nil
    local enabled = item and (item[3] == "half" or item[3] == "final") and J.settings.adaptive
        or item and tonumber(item[3]) and J.settings.warnings[tonumber(item[3])]
        or item and item[3] == "expired" and J.settings.warnings[0]
    if item and enabled and J.NotificationsAllowed() then
        if J.session.state == "EXPIRED" then
            if J.settings.warnings[0] then deliver("expired") end
        elseif J.session.state == "RUNNING" or J.session.state == "PAUSED" then
            -- A fight may last minutes: describe current time, never a stale threshold.
            deliver("remaining")
        end
    end
    if J.pendingFinish then
        J.pendingFinish = false
        if J.settings.closingPopup and J.NotificationsAllowed() then J.ShowFinish() end
    end
end

function J.NotificationsCheck(previous, current)
    local s, settings = J.session, J.settings
    local chosen
    for _, item in ipairs(J.ReminderPlan()) do
        if item.at < s.planDuration and previous > item.at and current <= item.at
            and not s.fired[item.key] then
            s.fired[item.key] = true
            local enabled = s.reminderType == "adaptive" and settings.adaptive
                or s.reminderType == "classic" and settings.warnings[item.at]
            if enabled then chosen = item end
        end
    end
    if current <= 0 and not s.fired["0"] then
        s.fired["0"] = true
        if settings.warnings[0] then J.Notify("expired") end
        if settings.closingPopup and J.NotificationsAllowed() then
            if J.InCombat() then J.pendingFinish = true else J.ShowFinish() end
        end
    elseif chosen then
        -- A delayed update must not announce e.g. "2 minutes" with 40 seconds left.
        local kind = chosen.key
        if current < chosen.at - 1 then kind = "remaining" end
        J.Notify(kind, nil, chosen.key)
    end
end
