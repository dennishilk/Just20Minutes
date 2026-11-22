local _, J = ...
local THRESHOLDS = {600, 300, 120}
local function inCombat()
    return type(UnitAffectingCombat) == "function" and UnitAffectingCombat("player")
end

local function deliver(kind, minutes)
    local settings = J.settings
    if settings.mode == "off" or settings.mode == "color" then return end
    local key = ({
        start = "MSG_START", pause = "MSG_PAUSE", resume = "MSG_RESUME",
        stop = "MSG_STOP", extend = "MSG_EXTEND",
        expired = settings.family and "FAMILY_EXPIRED" or "MSG_EXPIRED",
        ["600"] = settings.family and "FAMILY_600" or "MSG_600",
        ["300"] = settings.family and "FAMILY_300" or "MSG_300",
        ["120"] = settings.family and "FAMILY_120" or "MSG_120",
    })[kind]
    if not key then return end
    if not settings.windDown and (kind == "600" or kind == "300" or kind == "120") then
        key = "SHORT_" .. kind
    end
    local message = J.T(key, minutes)
    if settings.mode == "chat" or settings.mode == "both" then
        J.Print(message)
    end
    if (settings.mode == "screen" or settings.mode == "both")
        and UIErrorsFrame and UIErrorsFrame.AddMessage then
        UIErrorsFrame:AddMessage(message, 1, 0.85, 0.35, 1, 5)
    elseif settings.mode == "screen" and (not UIErrorsFrame or not UIErrorsFrame.AddMessage) then
        J.Print(message)
    end
    if settings.sound and type(PlaySound) == "function" and
        type(SOUNDKIT) == "table" and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end
end

function J.Notify(kind, minutes)
    if J.settings.deferCombat and inCombat()
        and (kind == "600" or kind == "300" or kind == "120" or kind == "expired") then
        J.deferred = {kind, minutes}
        return
    end
    deliver(kind, minutes)
end

function J.DeliverDeferred()
    if J.deferred then
        local item = J.deferred
        J.deferred = nil
        deliver(item[1], item[2])
    end
    if J.pendingFinish then
        J.pendingFinish = false
        J.ShowFinish()
    end
end

function J.NotificationsCheck(previous, current)
    local s, settings = J.session, J.settings
    local chosen
    -- Mark all crossed thresholds, but display only the most urgent one.
    -- Never re-arm a warning in this session after an extension.
    for _, threshold in ipairs(THRESHOLDS) do
        local key = tostring(threshold)
        if s.duration > threshold and previous > threshold and current <= threshold
            and not s.fired[key] then
            s.fired[key] = true
            if settings.warnings[threshold] then chosen = key end
        end
    end
    if current <= 0 and not s.fired["0"] then
        s.fired["0"] = true
        if settings.warnings[0] then J.Notify("expired") end
        if settings.closingPopup then
            if inCombat() then J.pendingFinish = true else J.ShowFinish() end
        end
    elseif chosen then
        J.Notify(chosen)
    end
end
