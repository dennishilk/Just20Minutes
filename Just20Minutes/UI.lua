local _, J = ...
local UI = {}
J.ui = UI
local function skin(frame)
    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false, edgeSize = 15,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        frame:SetBackdropColor(0.035, 0.055, 0.075, 0.95)
        frame:SetBackdropBorderColor(0.45, 0.57, 0.65, 0.95)
    end
end
J.Skin = skin

function J.MakeText(parent, size, width, height)
    local text = parent:CreateFontString(nil, "OVERLAY",
        size == "large" and "GameFontNormalHuge" or
        size == "medium" and "GameFontNormalLarge" or "GameFontHighlight")
    text:SetSize(width, height)
    text:SetJustifyH("CENTER")
    text:SetJustifyV("MIDDLE")
    return text
end

function J.MakeButton(parent, label, width, height, action)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width, height)
    b:SetText(label)
    b:SetScript("OnClick", action)
    return b
end

local function window(width, height, titleKey)
    local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    f:SetFrameStrata("DIALOG")
    f:SetSize(width, height)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    skin(f)
    local title = J.MakeText(f, "medium", width - 80, 30)
    title:SetPoint("TOP", f, "TOP", 0, -17)
    title:SetText(J.T(titleKey))
    local close = J.MakeButton(f, "X", 28, 23, function() f:Hide() end)
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -12, -12)
    f:Hide()
    return f, title
end
J.MakeWindow = window

local function createWidget()
    local w = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    w:SetFrameStrata("MEDIUM")
    w:SetSize(244, 116)
    w:SetClampedToScreen(true)
    w:SetMovable(true)
    w:EnableMouse(true)
    w:RegisterForDrag("LeftButton")
    skin(w)
    w:SetScript("OnDragStart", function(self)
        if not J.settings.locked then self:StartMoving() end
    end)
    w:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if not J.settings.locked then
            local cx, cy = self:GetCenter()
            local px, py = UIParent:GetCenter()
            if cx and cy and px and py then
                J.SavePosition((cx - px) / self:GetEffectiveScale() * UIParent:GetEffectiveScale(),
                    (cy - py) / self:GetEffectiveScale() * UIParent:GetEffectiveScale())
            end
        end
    end)
    local title = J.MakeText(w, "small", 198, 21)
    title:SetPoint("TOPLEFT", w, "TOPLEFT", 12, -11)
    title:SetJustifyH("LEFT")
    local gear = J.MakeButton(w, "...", 30, 23, function() J.OpenMain() end)
    gear:SetPoint("TOPRIGHT", w, "TOPRIGHT", -9, -9)
    gear:SetScript("OnEnter", function(self)
        if GameTooltip then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(J.T("OPEN_MAIN"))
            GameTooltip:Show()
        end
    end)
    gear:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    local count = J.MakeText(w, "large", 220, 36)
    count:SetPoint("TOP", w, "TOP", 0, -33)
    local bg = w:CreateTexture(nil, "ARTWORK")
    bg:SetColorTexture(0.13, 0.16, 0.19, 0.98)
    bg:SetSize(214, 8)
    bg:SetPoint("TOP", w, "TOP", 0, -79)
    local bar = w:CreateTexture(nil, "OVERLAY")
    bar:SetColorTexture(0.35, 0.83, 0.47, 1)
    bar:SetSize(214, 8)
    bar:SetPoint("LEFT", bg, "LEFT", 0, 0)
    local status = J.MakeText(w, "small", 220, 20)
    status:SetPoint("BOTTOM", w, "BOTTOM", 0, 8)
    UI.widget, UI.widgetTitle, UI.count, UI.bg, UI.bar, UI.status =
        w, title, count, bg, bar, status
end

local function createMain()
    local f, title = window(525, 498, "APP_TITLE")
    UI.main, UI.mainTitle = f, title
    local info = J.MakeText(f, "small", 480, 47)
    info:SetPoint("TOP", f, "TOP", 0, -53)
    UI.info = info
    local presets = {}
    for index, minutes in ipairs(J.presets) do
        local b = J.MakeButton(f, tostring(minutes) .. "m", 101, 28, function()
            UI.selectedMinutes = minutes
            J.RefreshUI()
        end)
        local col = (index - 1) % 4
        local row = math.floor((index - 1) / 4)
        b:SetPoint("TOPLEFT", f, "TOPLEFT", 40 + col * 113, -117 - row * 36)
        presets[index] = b
    end
    UI.presets = presets
    UI.selectedMinutes = J.EffectiveMinutes()
    local customLabel = J.MakeText(f, "small", 175, 25)
    customLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 42, -202)
    customLabel:SetText(J.T("CUSTOM_MINUTES"))
    local entry = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    entry:SetSize(72, 27)
    entry:SetAutoFocus(false)
    entry:SetMaxLetters(3)
    entry:SetNumeric(true)
    entry:SetPoint("LEFT", customLabel, "RIGHT", 8, 0)
    entry:SetScript("OnEnterPressed", function(self)
        local n = tonumber(self:GetText())
        if J.ValidMinutes(n) then
            UI.selectedMinutes = n
            J.RefreshUI()
        else
            J.Print(J.T("ERR_DURATION"))
        end
        self:ClearFocus()
    end)
    UI.custom = entry
    local selected = J.MakeText(f, "small", 480, 25)
    selected:SetPoint("TOP", f, "TOP", 0, -243)
    UI.selected = selected

    local actions = {
        {"START", function()
            if J.TimerStart(UI.selectedMinutes) then
                J.db.welcomeShown, UI.welcome = true, false
                J.RefreshUI()
            end
        end},
        {"PAUSE", function() J.TimerPause() end},
        {"RESUME", function() J.TimerResume() end},
        {"STOP", function() J.TimerStop() end},
        {"RESET", function() J.TimerReset() end}
    }
    for i, item in ipairs(actions) do
        local b = J.MakeButton(f, J.T(item[1]), 94, 29, item[2])
        b:SetPoint("TOPLEFT", f, "TOPLEFT", 17 + (i-1)*99, -282)
        UI["action"..i] = b
    end
    local plusTitle = J.MakeText(f, "small", 455, 20)
    plusTitle:SetPoint("TOP", f, "TOP", 0, -322)
    plusTitle:SetText(J.T("EXTEND_TIME"))
    for i, minutes in ipairs({5,10,15}) do
        local b = J.MakeButton(f, "+"..minutes.."m", 88, 26,
            function() J.TimerAdd(minutes) end)
        b:SetPoint("TOPLEFT", f, "TOPLEFT", 47 + (i-1)*104, -347)
    end
    local ext = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    ext:SetSize(52, 25)
    ext:SetAutoFocus(false)
    ext:SetMaxLetters(3)
    ext:SetNumeric(true)
    ext:SetPoint("TOPLEFT", f, "TOPLEFT", 365, -348)
    UI.addCustom = ext
    local plus = J.MakeButton(f, "+", 33, 25, function()
        J.TimerAdd(tonumber(ext:GetText()))
        ext:ClearFocus()
    end)
    plus:SetPoint("LEFT", ext, "RIGHT", 5, 0)
    local config = J.MakeButton(f, J.T("SETTINGS"), 185, 29, function()
        f:Hide()
        J.db.welcomeShown, UI.welcome = true, false
        J.OpenSettings()
    end)
    config:SetPoint("BOTTOM", f, "BOTTOM", 0, 49)
    local later = J.MakeButton(f, J.T("MAYBE_LATER"), 185, 25, function()
        J.db.welcomeShown = true
        UI.welcome = false
        f:Hide()
    end)
    later:SetPoint("BOTTOM", f, "BOTTOM", 0, 15)
    UI.later = later
end

local function createFinish()
    local f, title = window(455, 224, "FINISH_TITLE")
    UI.finish, UI.finishTitle = f, title
    local desc = J.MakeText(f, "small", 406, 75)
    desc:SetPoint("TOP", f, "TOP", 0, -57)
    desc:SetText(J.T("FINISH_DESC"))
    UI.finishDesc = desc
    for i, minutes in ipairs({5,10,15}) do
        local b = J.MakeButton(f, "+"..minutes.."m", 100, 29,
            function() J.TimerAdd(minutes) end)
        b:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 53+(i-1)*116, 60)
    end
    local endButton = J.MakeButton(f, J.T("FINISH_TODAY"), 240, 29, function()
        J.TimerStop()
        f:Hide()
    end)
    endButton:SetPoint("BOTTOM", f, "BOTTOM", 0, 21)
end

local function createConfirm()
    local f = window(430, 180, "CONFIRM_TITLE")
    UI.confirm = f
    local desc = J.MakeText(f, "small", 390, 74)
    desc:SetPoint("TOP", f, "TOP", 0, -46)
    UI.confirmDesc = desc
    local yes = J.MakeButton(f, J.T("YES"), 130, 28, function()
        f:Hide()
        local callback = UI.confirmCallback
        UI.confirmCallback = nil
        if callback then callback() end
    end)
    yes:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 66, 19)
    local no = J.MakeButton(f, J.T("CANCEL"), 130, 28, function() f:Hide() end)
    no:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -66, 19)
end

function J.BuildUI()
    createWidget()
    createMain()
    createFinish()
    createConfirm()
    J.ApplyAppearance()
end

function J.Confirm(message, callback)
    UI.confirmDesc:SetText(message)
    UI.confirmCallback = callback
    UI.confirm:Show()
end

function J.ShowWelcome()
    J.db.welcomeShown = false
    UI.welcome = true
    UI.selectedMinutes = J.EffectiveMinutes()
    UI.main:Show()
    J.RefreshUI()
end

function J.OpenMain()
    if UI.main:IsShown() then UI.main:Hide() else UI.main:Show() end
    J.RefreshUI()
end

function J.HideFinish()
    if UI.finish then UI.finish:Hide() end
    J.pendingFinish = false
end

function J.ShowFinish()
    if UI.finish and J.session and J.session.state == "EXPIRED" then
        UI.finishTitle:SetText(J.T("FINISH_TITLE"))
        UI.finishDesc:SetText(J.T("FINISH_DESC"))
        UI.finish:Show()
    end
end

function J.ApplyAppearance()
    if not UI.widget then return end
    local s, w = J.settings, UI.widget
    w:SetScale(s.scale)
    w:SetAlpha(s.alpha)
    w:SetHeight(s.compact and 74 or 116)
    w:ClearAllPoints()
    local pos = J.Position()
    w:SetPoint("CENTER", UIParent, "CENTER", pos.x, pos.y)
    UI.widgetTitle:SetShown(not s.compact)
    UI.bg:SetShown(not s.compact and s.progress)
    UI.bar:SetShown(not s.compact and s.progress)
    UI.status:SetShown(not s.compact)
    UI.count:ClearAllPoints()
    UI.count:SetPoint("TOP", w, "TOP", 0, s.compact and -17 or -33)
    J.RefreshUI()
end

local function currentColor(remaining, duration, theme)
    local warning = math.min(600, duration * 0.5)
    local danger = math.min(300, duration * 0.25)
    local r,g,b, stage
    if remaining <= 0 then r,g,b,stage = 0.95,0.42,0.42,"STAGE_DONE"
    elseif remaining <= danger then r,g,b,stage = 0.95,0.42,0.32,"STAGE_SOON"
    elseif remaining <= warning then r,g,b,stage = 0.99,0.82,0.28,"STAGE_WINDDOWN"
    else r,g,b,stage = 0.35,0.83,0.47,"STAGE_ENJOY" end
    if theme == "blue" and stage == "STAGE_ENJOY" then r,g,b=0.42,0.72,1 end
    if theme == "gold" and stage == "STAGE_ENJOY" then r,g,b=0.96,0.75,0.38 end
    return r,g,b,stage
end

function J.RefreshUI()
    if not J.session or not UI.widget then return end
    local s, settings = J.session, J.settings
    local remaining = J.TimerRemaining()
    local r,g,b,stage = currentColor(remaining, s.duration, settings.theme)
    local state = s.state
    local shown = (settings.widgetAlways or state ~= "IDLE")
        and not J.widgetManuallyHidden
    UI.widget:SetShown(shown)
    UI.count:SetText(J.FormatTime(state == "IDLE" and J.EffectiveMinutes()*60 or remaining))
    UI.count:SetTextColor(r,g,b)
    UI.widgetTitle:SetText(J.T("APP_TITLE"))
    UI.status:SetText(J.T(settings.colorBlind and stage or ("STATE_"..state)))
    UI.bar:SetColorTexture(r,g,b,1)
    UI.bar:SetWidth(math.max(0.01, 214 * math.min(1, remaining / math.max(1,s.duration))))
    if UI.main and UI.main:IsShown() then
        local intro = UI.welcome and J.T("WELCOME_DESC") or J.TimerStatus()
        UI.info:SetText(intro)
        UI.mainTitle:SetText(J.T(UI.welcome and "WELCOME_TITLE" or "APP_TITLE"))
        UI.later:SetShown(UI.welcome)
        UI.selected:SetText(J.T("SELECTED_MINUTES", UI.selectedMinutes))
        for i, minutes in ipairs(J.presets) do
            UI.presets[i]:SetText((UI.selectedMinutes == minutes and "[" or "")
                .. minutes .. "m" .. (UI.selectedMinutes == minutes and "]" or ""))
        end
        UI.action1:SetText(J.T(UI.welcome and "START_ADVENTURE" or "START"))
        for i=2,5 do
            UI["action"..i]:SetShown(not UI.welcome)
        end
    end
end
