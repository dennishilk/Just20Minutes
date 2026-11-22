local _, J = ...
local UI = {windows = {}, buttons = {}}
J.ui = UI
J.colors = {
    background = {0.063, 0.082, 0.110}, surface = {0.106, 0.141, 0.188},
    border = {0.212, 0.267, 0.325}, gold = {0.890, 0.741, 0.408},
    primary = {0.247, 0.537, 0.392}, neutral = {0.204, 0.275, 0.345},
    warning = {0.898, 0.722, 0.310}, danger = {0.843, 0.416, 0.341},
    text = {0.945, 0.933, 0.906}, muted = {0.745, 0.776, 0.804},
    blue = {0.44, 0.69, 0.87}, green = {0.43, 0.76, 0.55},
}
local C = J.colors
local function skin(frame, surface)
    if not frame.SetBackdrop then return end
    frame:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1}})
    local c = surface and C.surface or C.background
    frame:SetBackdropColor(c[1], c[2], c[3], 0.97)
    frame:SetBackdropBorderColor(C.border[1], C.border[2], C.border[3], 1)
end
J.Skin = skin

function J.MakeText(parent, size, width, height)
    local text = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    local font = text:GetFont()
    if font then text:SetFont(font, size == "large" and 32 or size == "medium" and 18 or 14, "") end
    text:SetSize(width, height)
    text:SetJustifyH("CENTER")
    text:SetJustifyV("MIDDLE")
    text:SetTextColor(unpack(C.text))
    text:SetWordWrap(true)
    return text
end

function J.SetButtonStyle(button, tone, selected)
    button.tone, button.selected = tone or button.tone or "neutral", selected == true
    local c = button.selected and C.gold or C[button.tone] or C.neutral
    button:SetBackdropColor(c[1], c[2], c[3], button.selected and 0.27 or 0.85)
    button:SetBackdropBorderColor(c[1], c[2], c[3], 1)
    if button.label then button.label:SetTextColor(unpack(button.selected and C.gold or C.text)) end
end

function J.MakeButton(parent, label, width, height, action, tone)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(width, height)
    skin(b, true)
    local text = J.MakeText(b, "small", width - 12, height - 4)
    text:SetPoint("CENTER", b, "CENTER")
    b:SetFontString(text)
    b.label = text
    b:SetText(label)
    b:SetScript("OnClick", action)
    b:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
    local highlight = b:GetHighlightTexture()
    if highlight then highlight:SetVertexColor(1, 1, 1, 0.08) end
    J.SetButtonStyle(b, tone or "neutral")
    table.insert(UI.buttons, b)
    return b
end

function J.SetButtonEnabled(button, enabled)
    if enabled then button:Enable() else button:Disable() end
    button:SetAlpha(enabled and 1 or 0.35)
end

function J.Tooltip(frame, key)
    frame:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(J.T(key), nil, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
end

function J.SaveFramePosition(frame, pos)
    local cx, cy = frame:GetCenter()
    local px, py = UIParent:GetCenter()
    if not cx or not cy or not px or not py then return end
    local ratio = UIParent:GetEffectiveScale() / frame:GetEffectiveScale()
    local x, y = cx - px * ratio, cy - py * ratio
    if J.Finite(x, -10000, 10000) and J.Finite(y, -10000, 10000) then
        pos.x, pos.y = x, y
    end
end

function J.PlaceFrame(frame, pos)
    local ratio = UIParent:GetEffectiveScale() / frame:GetEffectiveScale()
    local maxX = math.max(0, (UIParent:GetWidth() * ratio - frame:GetWidth()) / 2 - 12)
    local maxY = math.max(0, (UIParent:GetHeight() * ratio - frame:GetHeight()) / 2 - 12)
    pos.x = math.max(-maxX, math.min(maxX, pos.x))
    pos.y = math.max(-maxY, math.min(maxY, pos.y))
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", pos.x, pos.y)
end

local function window(width, height, titleKey, positionKey)
    local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    f:SetFrameStrata("DIALOG")
    f:SetSize(width, height)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if positionKey then J.SaveFramePosition(self, J.settings[positionKey]) end
    end)
    skin(f)
    local accent = f:CreateTexture(nil, "ARTWORK")
    accent:SetColorTexture(C.gold[1], C.gold[2], C.gold[3], 0.8)
    accent:SetSize(width - 2, 2)
    accent:SetPoint("TOP", f, "TOP", 0, -1)
    local title = J.MakeText(f, "medium", width - 90, 48)
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -9)
    title:SetJustifyH("LEFT")
    title:SetTextColor(unpack(C.gold))
    title:SetText(J.T(titleKey))
    local close = J.MakeButton(f, "X", 26, 26, function() f:Hide() end)
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -14, -15)
    f.positionKey = positionKey
    table.insert(UI.windows, f)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:Hide()
    return f, title
end
J.MakeWindow = window

function J.FitWindows()
    for _, frame in ipairs(UI.windows) do
        local scale = math.min(1, (UIParent:GetWidth() - 24) / frame:GetWidth(),
            (UIParent:GetHeight() - 24) / frame:GetHeight())
        frame:SetScale(math.max(0.5, scale))
        if frame.positionKey then J.PlaceFrame(frame, J.settings[frame.positionKey]) end
    end
end

local function createWidget()
    local w = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    w:SetFrameStrata("MEDIUM")
    w:SetSize(244, 124)
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
        if not J.settings.locked then J.SaveFramePosition(self, J.Position()) end
    end)
    local title = J.MakeText(w, "small", 178, 21)
    title:SetPoint("TOPLEFT", w, "TOPLEFT", 14, -10)
    title:SetJustifyH("LEFT")
    title:SetTextColor(unpack(C.gold))
    local gear = J.MakeButton(w, "...", 28, 23, function() J.OpenMain() end)
    gear:SetPoint("TOPRIGHT", w, "TOPRIGHT", -10, -9)
    J.Tooltip(gear, "OPEN_MAIN")
    local count = J.MakeText(w, "large", 212, 40)
    count:SetPoint("TOP", w, "TOP", 0, -32)
    local bg = w:CreateTexture(nil, "ARTWORK")
    bg:SetColorTexture(C.surface[1], C.surface[2], C.surface[3], 1)
    bg:SetSize(214, 6)
    bg:SetPoint("TOP", w, "TOP", 0, -80)
    local bar = w:CreateTexture(nil, "OVERLAY")
    bar:SetSize(214, 6)
    bar:SetPoint("LEFT", bg, "LEFT", 0, 0)
    local status = J.MakeText(w, "small", 220, 27)
    status:SetPoint("BOTTOM", w, "BOTTOM", 0, 9)
    UI.widget, UI.widgetTitle, UI.count, UI.bg, UI.bar, UI.status = w, title, count, bg, bar, status
end

local function createMain()
    local f, title = window(550, 510, "APP_TITLE", "mainPosition")
    UI.main, UI.mainTitle = f, title
    local info = J.MakeText(f, "small", 486, 44)
    info:SetPoint("TOP", f, "TOP", 0, -62)
    info:SetTextColor(unpack(C.muted))
    UI.info = info
    UI.presets = {}
    for index, minutes in ipairs(J.presets) do
        local b = J.MakeButton(f, J.T("MINUTES_SHORT", minutes), 112, 32, function()
            UI.selectedMinutes = minutes
            UI.custom:SetText("")
            J.RefreshUI()
        end)
        b:SetPoint("TOPLEFT", f, "TOPLEFT", 33 + ((index - 1) % 4) * 124,
            -122 - math.floor((index - 1) / 4) * 40)
        UI.presets[index] = b
    end
    UI.selectedMinutes = J.EffectiveMinutes()
    local customLabel = J.MakeText(f, "small", 215, 28)
    customLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 33, -214)
    customLabel:SetJustifyH("LEFT")
    UI.customLabel = customLabel
    local entry = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    entry:SetSize(90, 28)
    entry:SetAutoFocus(false)
    entry:SetMaxLetters(3)
    entry:SetNumeric(true)
    entry:SetPoint("LEFT", customLabel, "RIGHT", 12, 0)
    entry:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    entry:SetScript("OnEnterPressed", function(self)
        local n = tonumber(self:GetText())
        if J.ValidMinutes(n) then UI.selectedMinutes = n; J.RefreshUI()
        else J.Print(J.T("ERR_DURATION")) end
        self:ClearFocus()
    end)
    UI.custom = entry
    local selected = J.MakeText(f, "small", 490, 25)
    selected:SetPoint("TOP", f, "TOP", 0, -254)
    selected:SetTextColor(unpack(C.gold))
    UI.selected = selected
    local actions = {
        {"START", function()
            if J.TimerStart(UI.selectedMinutes) then
                J.db.welcomeShown, UI.welcome = true, false
                f:Hide()
                J.RefreshUI()
            end
        end, "primary"},
        {"PAUSE", function() J.TimerPause() end},
        {"RESUME", function() J.TimerResume() end},
        {"STOP", function() J.TimerStop() end},
        {"RESET", function() J.TimerReset() end},
    }
    for i, item in ipairs(actions) do
        local b = J.MakeButton(f, J.T(item[1]), 96, 34, item[2], item[3])
        b:SetPoint("TOPLEFT", f, "TOPLEFT", 19 + (i - 1) * 104, -290)
        UI["action" .. i] = b
    end
    local plusTitle = J.MakeText(f, "small", 490, 24)
    plusTitle:SetPoint("TOPLEFT", f, "TOPLEFT", 33, -341)
    plusTitle:SetJustifyH("LEFT")
    UI.plusTitle, UI.extensions = plusTitle, {}
    for i, minutes in ipairs({5, 10, 15}) do
        local b = J.MakeButton(f, "+" .. J.T("MINUTES_SHORT", minutes), 100, 30,
            function() J.TimerAdd(minutes) end)
        b:SetPoint("TOPLEFT", f, "TOPLEFT", 33 + (i - 1) * 113, -373)
        UI.extensions[i] = b
    end
    local ext = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    ext:SetSize(55, 28)
    ext:SetAutoFocus(false)
    ext:SetMaxLetters(3)
    ext:SetNumeric(true)
    ext:SetPoint("TOPLEFT", f, "TOPLEFT", 381, -374)
    ext:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    UI.addCustom = ext
    local function addCustom() J.TimerAdd(tonumber(ext:GetText())); ext:ClearFocus() end
    ext:SetScript("OnEnterPressed", addCustom)
    local plus = J.MakeButton(f, "+", 34, 28, addCustom)
    plus:SetPoint("LEFT", ext, "RIGHT", 10, 0)
    UI.addButton = plus
    entry:SetScript("OnTabPressed", function(self) self:ClearFocus(); ext:SetFocus() end)
    ext:SetScript("OnTabPressed", function(self) self:ClearFocus(); entry:SetFocus() end)
    local config = J.MakeButton(f, "", 220, 31, function()
        J.db.welcomeShown, UI.welcome = true, false
        J.OpenSettings()
    end)
    config:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 33, 34)
    UI.config = config
    local later = J.MakeButton(f, "", 220, 31, function()
        J.db.welcomeShown, UI.welcome = true, false
        f:Hide()
    end)
    later:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -33, 34)
    UI.later = later
end

local function createFinish()
    local f, title = window(500, 342, "FINISH_TITLE")
    UI.finish, UI.finishTitle = f, title
    local desc = J.MakeText(f, "small", 440, 58)
    desc:SetPoint("TOP", f, "TOP", 0, -67)
    desc:SetTextColor(unpack(C.muted))
    UI.finishDesc = desc
    local more = J.MakeText(f, "small", 440, 24)
    more:SetPoint("TOPLEFT", f, "TOPLEFT", 30, -143)
    more:SetJustifyH("LEFT")
    more:SetTextColor(unpack(C.gold))
    UI.finishMore, UI.finishExtensions = more, {}
    for i, minutes in ipairs({5, 10, 15}) do
        local b = J.MakeButton(f, "", 136, 33, function() J.TimerAdd(minutes) end)
        b:SetPoint("TOPLEFT", f, "TOPLEFT", 30 + (i - 1) * 152, -178)
        UI.finishExtensions[i] = b
    end
    local done = J.MakeText(f, "small", 440, 24)
    done:SetPoint("TOPLEFT", f, "TOPLEFT", 30, -237)
    done:SetJustifyH("LEFT")
    done:SetTextColor(unpack(C.gold))
    UI.finishDone = done
    local endButton = J.MakeButton(f, "", 440, 35, function() J.TimerStop(); f:Hide() end, "primary")
    endButton:SetPoint("BOTTOM", f, "BOTTOM", 0, 23)
    UI.finishEnd = endButton
end

local function createConfirm()
    local f, title = window(460, 210, "CONFIRM_TITLE")
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    UI.confirm, UI.confirmTitle = f, title
    local desc = J.MakeText(f, "small", 400, 78)
    desc:SetPoint("TOP", f, "TOP", 0, -57)
    UI.confirmDesc = desc
    local yes = J.MakeButton(f, "", 178, 32, function()
        f:Hide()
        local callback = UI.confirmCallback
        UI.confirmCallback = nil
        if callback then callback() end
    end, "danger")
    yes:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 30, 23)
    local no = J.MakeButton(f, "", 178, 32, function() UI.confirmCallback = nil; f:Hide() end)
    no:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 23)
    UI.confirmYes, UI.confirmNo = yes, no
end

local function createToast()
    local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    f:SetFrameStrata("HIGH")
    f:SetSize(404, 112)
    f:SetPoint("TOP", UIParent, "TOP", 0, -110)
    f:SetClampedToScreen(true)
    f:EnableMouse(false)
    skin(f)
    local title = J.MakeText(f, "small", 360, 24)
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -12)
    title:SetJustifyH("LEFT")
    title:SetTextColor(unpack(C.gold))
    local text = J.MakeText(f, "small", 360, 64)
    text:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -37)
    text:SetJustifyH("LEFT")
    f:SetScript("OnUpdate", function(self)
        if J.InCombat() or not J.NotificationsAllowed() then self:Hide(); return end
        local elapsed = J.Now() - (self.started or 0)
        if elapsed >= 5.5 then self:Hide(); return end
        self:SetAlpha(math.min(1, elapsed / 0.2, (5.5 - elapsed) / 0.5))
    end)
    f:Hide()
    UI.toast, UI.toastTitle, UI.toastText = f, title, text
end

function J.ShowToast(message, kind)
    if not UI.toast or J.InCombat() then return end
    local color = J.StatePresentation(J.session.state, J.TimerRemaining(), J.session.duration, J.settings.theme)
    UI.toast:SetBackdropBorderColor(color[1], color[2], color[3], 1)
    UI.toastTitle:SetTextColor(unpack(color))
    UI.toastTitle:SetText(J.T(kind == "expired" and "TOAST_COMPLETE" or "TOAST_TITLE"))
    UI.toastText:SetText(message)
    UI.toast.started = J.Now()
    UI.toast:SetAlpha(0)
    UI.toast:Show()
end
function J.HideToast() if UI.toast then UI.toast:Hide() end end

function J.BuildUI()
    createWidget(); createMain(); createFinish(); createConfirm(); createToast()
    J.FitWindows()
    J.ApplyAppearance()
end
function J.Confirm(message, callback)
    UI.confirmDesc:SetText(message)
    UI.confirmCallback = callback
    UI.confirm:Show()
end
function J.ShowWelcome()
    J.db.welcomeShown, UI.welcome = false, true
    UI.selectedMinutes = J.EffectiveMinutes()
    if J.settingUI and J.settingUI.frame then J.settingUI.frame:Hide() end
    UI.main:Show()
    J.RefreshUI()
end
function J.OpenMain()
    J.FitWindows()
    if UI.main:IsShown() then UI.main:Hide()
    else
        if J.settingUI and J.settingUI.frame then J.settingUI.frame:Hide() end
        UI.main:Show()
    end
    J.RefreshUI()
end
function J.HideFinish()
    if UI.finish then UI.finish:Hide() end
    J.pendingFinish = false
end
function J.ShowFinish()
    J.FitWindows()
    if J.InCombat() then J.pendingFinish = true; return end
    if UI.finish and J.session and J.session.state == "EXPIRED" then
        UI.main:Hide()
        if J.settingUI and J.settingUI.frame then J.settingUI.frame:Hide() end
        J.RefreshUI()
        UI.finish:Show()
    end
end

function J.ApplyAppearance()
    if not UI.widget then return end
    local s, w = J.settings, UI.widget
    w:SetScale(s.scale)
    w:SetAlpha(s.alpha)
    w:SetHeight(s.compact and 78 or 124)
    J.PlaceFrame(w, J.Position())
    UI.widgetTitle:SetShown(not s.compact)
    UI.bg:SetShown(not s.compact and s.progress)
    UI.bar:SetShown(not s.compact and s.progress)
    UI.status:Show()
    UI.count:ClearAllPoints()
    UI.count:SetPoint("TOP", w, "TOP", s.compact and -8 or 0, s.compact and -5 or -32)
    J.RefreshUI()
end

-- Pure state presentation shared by widget, tooltip tests and accessibility.
function J.StatePresentation(state, remaining, duration, theme)
    if state == "IDLE" then return C.gold, "CONTEXT_IDLE", 1 end
    if state == "PAUSED" then return C.blue, "CONTEXT_PAUSED", remaining / math.max(1, duration) end
    if state == "EXPIRED" then return C.danger, "CONTEXT_DONE", 0 end
    local ratio = remaining / math.max(1, duration)
    if remaining <= math.min(120, duration * 0.25) then return C.danger, "CONTEXT_SOON", ratio end
    if remaining <= math.min(600, duration * 0.5) then return C.warning, "CONTEXT_WINDDOWN", ratio end
    return theme == "blue" and C.blue or theme == "gold" and C.gold or C.green, "STAGE_ENJOY", ratio
end

function J.RefreshUI()
    if not J.session or not UI.widget then return end
    local s, settings = J.session, J.settings
    local remaining, state = J.TimerRemaining(), s.state
    local color, context, ratio = J.StatePresentation(state, remaining, s.duration, settings.theme)
    UI.widget:SetShown((settings.widgetAlways or state ~= "IDLE") and not J.widgetManuallyHidden)
    UI.count:SetText(J.FormatTime(state == "IDLE" and J.EffectiveMinutes() * 60 or remaining))
    UI.count:SetTextColor(unpack(color))
    UI.widgetTitle:SetText(J.T("APP_TITLE"))
    UI.status:SetText(J.T(settings.colorBlind and ("STATE_" .. state) or context))
    UI.bar:SetColorTexture(color[1], color[2], color[3], 1)
    UI.bar:SetWidth(math.max(0.01, 214 * math.min(1, math.max(0, ratio))))
    UI.finishTitle:SetText(J.T(settings.family and "FAMILY_FINISH_TITLE" or "FINISH_TITLE"))
    UI.finishDesc:SetText(J.T(settings.family and "FAMILY_FINISH_DESC" or "FINISH_DESC"))
    UI.finishMore:SetText(J.T("MORE_TIME")); UI.finishDone:SetText(J.T("DONE_TODAY"))
    UI.finishEnd:SetText(J.T("FINISH_TODAY"))
    UI.confirmTitle:SetText(J.T("CONFIRM_TITLE"))
    UI.confirmYes:SetText(J.T("YES")); UI.confirmNo:SetText(J.T("CANCEL"))
    for i, minutes in ipairs({5, 10, 15}) do
        UI.finishExtensions[i]:SetText("+" .. J.T("MINUTES_SHORT", minutes))
    end
    if UI.main and UI.main:IsShown() then
        UI.info:SetText(UI.welcome and J.T("WELCOME_DESC") or J.TimerStatus())
        UI.mainTitle:SetText(J.T(UI.welcome and "WELCOME_TITLE" or "APP_TITLE"))
        UI.later:SetShown(UI.welcome); UI.later:SetText(J.T("MAYBE_LATER"))
        UI.config:SetText(J.T("SETTINGS"))
        UI.config:ClearAllPoints()
        UI.config:SetPoint(UI.welcome and "BOTTOMLEFT" or "BOTTOM", UI.main,
            UI.welcome and "BOTTOMLEFT" or "BOTTOM", UI.welcome and 33 or 0, 34)
        UI.customLabel:SetText(J.T("CUSTOM_MINUTES"))
        UI.plusTitle:SetText(J.T("EXTEND_TIME"))
        UI.selected:SetText(J.T("SELECTED_MINUTES", UI.selectedMinutes))
        for i, minutes in ipairs(J.presets) do
            UI.presets[i]:SetText(J.T("MINUTES_SHORT", minutes))
            J.SetButtonStyle(UI.presets[i], "neutral", UI.selectedMinutes == minutes)
            J.SetButtonEnabled(UI.presets[i], state ~= "RUNNING" and state ~= "PAUSED")
        end
        local enabled = {state == "IDLE" or state == "EXPIRED", state == "RUNNING",
            state == "PAUSED", state ~= "IDLE", state ~= "RUNNING" and state ~= "PAUSED"}
        for i, key in ipairs({"START", "PAUSE", "RESUME", "STOP", "RESET"}) do
            local button = UI["action" .. i]
            button:SetText(J.T(i == 1 and UI.welcome and "START_ADVENTURE" or key))
            button:SetShown(not UI.welcome or i == 1)
            J.SetButtonEnabled(button, enabled[i])
        end
        UI.action1:SetWidth(UI.welcome and 220 or 96)
        if UI.action1.label then UI.action1.label:SetWidth(UI.welcome and 208 or 84) end
        for i, minutes in ipairs({5, 10, 15}) do
            UI.extensions[i]:SetText("+" .. J.T("MINUTES_SHORT", minutes))
            J.SetButtonEnabled(UI.extensions[i], state ~= "IDLE")
        end
        J.SetButtonEnabled(UI.addButton, state ~= "IDLE")
    end
end
