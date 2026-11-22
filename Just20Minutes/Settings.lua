local _, J = ...
local S = {}
J.settingUI = S
local C = J.colors
local WIDTH = 506

local function textAt(parent, key, x, y, width, height, gold)
    local t = J.MakeText(parent, "small", width, height or 26)
    t:SetJustifyH("LEFT")
    t:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    t:SetTextColor(unpack(gold and C.gold or C.muted))
    local function update() t:SetText(J.T(key)) end
    update(); table.insert(S.refreshers, update)
    return t
end
local function endSection(page)
    if page.card then page.card:SetHeight(page.cursor - page.cardStart + 10) end
end
local function section(page, key)
    endSection(page)
    page.cursor = page.cursor + (page.card and 24 or 0)
    page.cardStart = page.cursor
    local card = CreateFrame("Frame", nil, page, "BackdropTemplate")
    card:SetSize(WIDTH, 40)
    card:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -page.cursor)
    card:SetFrameLevel(math.max(0, page:GetFrameLevel() - 1))
    J.Skin(card, true)
    page.card = card
    textAt(page, key, 14, -page.cursor - 8, WIDTH - 28, 26, true)
    page.cursor = page.cursor + 43
end
local function description(page, key, height)
    height = height or 54
    textAt(page, key, 15, -page.cursor, WIDTH - 30, height)
    page.cursor = page.cursor + height + 8
end
local function check(page, key, getter, setter, hint)
    local b = CreateFrame("CheckButton", nil, page, "UICheckButtonTemplate")
    b:SetSize(26, 26)
    b:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -page.cursor)
    local label = textAt(page, key, 46, -page.cursor, WIDTH - 62, 30)
    label:SetTextColor(unpack(C.text))
    b:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        setter(checked == true or checked == 1)
        J.RefreshSettings()
    end)
    table.insert(S.refreshers, function() b:SetChecked(getter() == true) end)
    if hint then J.Tooltip(b, hint) end
    page.cursor = page.cursor + 36
    return b
end
local function action(page, key, handler, tone)
    local b = J.MakeButton(page, J.T(key), WIDTH - 28, 34, handler, tone)
    b:SetPoint("TOPLEFT", page, "TOPLEFT", 14, -page.cursor)
    table.insert(S.refreshers, function() b:SetText(J.T(key)) end)
    page.cursor = page.cursor + 43
    return b
end
local function cycle(page, key, options, getter, setter)
    textAt(page, key, 14, -page.cursor, 226, 32)
    local b = J.MakeButton(page, "", 242, 31, function()
        local index = 0
        for i, option in ipairs(options) do if option[1] == getter() then index = i; break end end
        setter(options[index % #options + 1][1]); J.RefreshSettings()
    end)
    b:SetPoint("TOPLEFT", page, "TOPLEFT", 250, -page.cursor)
    table.insert(S.refreshers, function()
        for _, option in ipairs(options) do
            if option[1] == getter() then b:SetText(J.T(option[2])); return end
        end
    end)
    J.Tooltip(b, "CYCLE_HINT")
    page.cursor = page.cursor + 40
end
local function stepper(page, key, getter, setter, delta, lo, hi, format)
    textAt(page, key, 14, -page.cursor, 245, 30)
    local minus = J.MakeButton(page, "-", 34, 29, function()
        setter(math.max(lo, math.floor((getter() - delta) * 1000 + 0.5) / 1000))
        J.RefreshSettings()
    end)
    minus:SetPoint("TOPLEFT", page, "TOPLEFT", 276, -page.cursor)
    local value = J.MakeText(page, "small", 128, 29)
    value:SetPoint("LEFT", minus, "RIGHT", 6, 0)
    local plus = J.MakeButton(page, "+", 34, 29, function()
        setter(math.min(hi, math.floor((getter() + delta) * 1000 + 0.5) / 1000))
        J.RefreshSettings()
    end)
    plus:SetPoint("LEFT", value, "RIGHT", 6, 0)
    table.insert(S.refreshers, function()
        value:SetText(format(getter()))
        J.SetButtonEnabled(minus, getter() > lo); J.SetButtonEnabled(plus, getter() < hi)
    end)
    page.cursor = page.cursor + 39
end
local function setting(key)
    return function() return J.settings[key] end, function(value)
        J.settings[key] = value
        J.ApplyAppearance(); J.UpdateMinimapButton()
        if not J.NotificationsAllowed() then J.ClearNotifications(); J.HideFinish() end
        if key == "toast" and not value then J.HideToast() end
    end
end
local function toggle(page, key, field, hint)
    local get, set = setting(field); return check(page, key, get, set, hint)
end
local function minutes(v) return J.T("MINUTES_COUNT", v) end
local function percent(v) return string.format("%d%%", math.floor(v * 100 + 0.5)) end

local function buildGeneral(page)
    section(page, "SECTION_PLAYTIME")
    local get, set = setting("defaultMinutes")
    stepper(page, "DEFAULT_DURATION", get, set, 1, 1, 600, minutes)
    toggle(page, "REMEMBER_LAST", "rememberLast")
    section(page, "SECTION_LOGIN")
    toggle(page, "SHOW_AT_LOGIN", "showAtLogin", "LOGIN_HINT")
    toggle(page, "AUTO_START", "autoStart", "AUTOSTART_HINT")
    toggle(page, "RESUME_LOGIN", "resumeOnLogin")
    description(page, "LOGIN_HINT", 56)
    section(page, "SECTION_ACTIONS")
    action(page, "RESTART_DEFAULT", function()
        local function restart() J.TimerStop(true); J.TimerStart(J.settings.defaultMinutes) end
        if J.session.state == "RUNNING" or J.session.state == "PAUSED" then
            J.Confirm(J.T("RESTART_CONFIRM"), restart)
        else restart() end
    end, "primary")
    description(page, "LOGOUT_INFO", 76)
end
local function buildAppearance(page)
    section(page, "SECTION_WIDGET")
    local get, set = setting("scale")
    stepper(page, "SCALE", get, set, 0.1, 0.7, 1.5, percent)
    get, set = setting("alpha")
    stepper(page, "OPACITY", get, set, 0.1, 0.3, 1, percent)
    toggle(page, "COMPACT", "compact")
    toggle(page, "PROGRESS", "progress")
    toggle(page, "COLORBLIND", "colorBlind")
    toggle(page, "ALWAYS_VISIBLE", "widgetAlways")
    description(page, "PREVIEW_HINT", 36)
    section(page, "SECTION_POSITION")
    toggle(page, "LOCK_POSITION", "locked")
    action(page, "RESET_POSITION", function()
        local p = J.Position(); p.x, p.y = 0, -180; J.ApplyAppearance()
    end)
    section(page, "SECTION_MINIMAP")
    toggle(page, "MINIMAP_BUTTON", "showMinimapButton")
    action(page, "RESET_MINIMAP_POSITION", function()
        J.settings.minimapAngle = 225; J.UpdateMinimapButton()
    end)
    section(page, "COLOR_THEME")
    get, set = setting("theme")
    cycle(page, "COLOR_THEME", {{"classic", "THEME_CLASSIC"}, {"blue", "THEME_BLUE"},
        {"gold", "THEME_GOLD"}}, get, set)
end
local function buildNotifications(page)
    section(page, "SECTION_CHANNEL")
    S.modeButtons = {}
    local modes = {{"screen", "SCREEN"}, {"chat", "CHAT"}, {"both", "BOTH"},
        {"color", "COLOR_ONLY"}, {"off", "OFF"}}
    for i, option in ipairs(modes) do
        local b = J.MakeButton(page, J.T(option[2]), 150, 32, function()
            local _, set = setting("mode"); set(option[1]); J.RefreshSettings()
        end)
        b:SetPoint("TOPLEFT", page, "TOPLEFT", 14 + ((i - 1) % 3) * 164,
            -page.cursor - math.floor((i - 1) / 3) * 40)
        S.modeButtons[i] = b
        table.insert(S.refreshers, function()
            b:SetText(J.T(option[2])); J.SetButtonStyle(b, "neutral", J.settings.mode == option[1])
        end)
    end
    page.cursor = page.cursor + 84
    toggle(page, "TOAST_ENABLE", "toast", "TOAST_HINT")
    toggle(page, "SOUND", "sound")
    toggle(page, "DEFER_COMBAT", "deferCombat", "COMBAT_HINT")
    section(page, "SECTION_ADAPTIVE")
    toggle(page, "ADAPTIVE_ENABLE", "adaptive", "ADAPTIVE_INFO")
    description(page, "ADAPTIVE_INFO", 86)
    section(page, "SECTION_CLASSIC")
    for _, threshold in ipairs({600, 300, 120, 0}) do
        check(page, "WARN_" .. threshold, function() return J.settings.warnings[threshold] end,
            function(value) J.settings.warnings[threshold] = value end)
    end
    description(page, "NOTIFY_INFO", 74)
end
local function buildExperience(page)
    section(page, "SECTION_GENTLE")
    toggle(page, "FAMILY_MODE", "family")
    description(page, "FAMILY_INFO", 45)
    toggle(page, "WINDDOWN_TIPS", "windDown")
    toggle(page, "CLOSING_WINDOW", "closingPopup")
    section(page, "LANGUAGE")
    local get, set = setting("language")
    cycle(page, "LANGUAGE", {{"auto", "LANG_AUTO"}, {"deDE", "LANG_DE"}, {"enUS", "LANG_EN"}}, get, set)
    section(page, "SECTION_PHILOSOPHY")
    description(page, "PHILOSOPHY", 91)
end
local function buildProfiles(page)
    section(page, "SECTION_CHARACTER")
    description(page, "PROFILE_INFO", 52)
    toggle(page, "CHAR_DURATION", "characterMinutes")
    stepper(page, "CHAR_DEFAULT_DURATION", function() return J.profile.minutes end,
        function(v) J.profile.minutes = v; J.RefreshUI() end, 1, 1, 600, minutes)
    toggle(page, "CHAR_POSITION", "characterPosition")
    action(page, "COPY_ACCOUNT_POSITION", function()
        J.profile.position = J.Copy(J.settings.position); J.ApplyAppearance()
    end)
    section(page, "SECTION_COPY")
    local sources, index = {}, 0
    for key, profile in pairs(J.db.profiles) do
        if key ~= J.charKey then table.insert(sources, {key = key, name = profile.name}) end
    end
    table.sort(sources, function(a, b) return a.name < b.name end)
    textAt(page, "COPY_FROM_CHARACTER", 14, -page.cursor, 230, 32)
    local choose = J.MakeButton(page, "", 242, 31, function()
        if #sources > 0 then index = index % #sources + 1 end
        J.RefreshSettings()
    end)
    choose:SetPoint("TOPLEFT", page, "TOPLEFT", 250, -page.cursor)
    page.cursor = page.cursor + 41
    local copy = action(page, "COPY_CHARACTER", function()
        local item = sources[index]; if not item then return end
        J.Confirm(J.T("COPY_CONFIRM", item.name), function()
            local src = J.db.profiles[item.key]
            J.profile.minutes, J.profile.position = src.minutes, J.Copy(src.position)
            J.ApplyAppearance(); J.RefreshSettings()
        end)
    end)
    table.insert(S.refreshers, function()
        choose:SetText(#sources > 0 and (index > 0 and sources[index].name or J.T("SELECT_CHARACTER"))
            or J.T("NO_CHARACTERS"))
        J.SetButtonEnabled(choose, #sources > 0); J.SetButtonEnabled(copy, index > 0)
    end)
    section(page, "SECTION_RESET")
    description(page, "RESET_INFO", 48)
    action(page, "RESET_CHARACTER", function()
        J.Confirm(J.T("RESET_CHARACTER_CONFIRM"), function()
            J.profile.minutes, J.profile.position = J.settings.defaultMinutes, {x = 0, y = -180}
            J.TimerStop(true); J.ApplyAppearance(); J.RefreshSettings()
        end)
    end, "danger")
    action(page, "RESET_ALL", function()
        J.Confirm(J.T("RESET_ALL_CONFIRM"), function() J.ResetSettings() end)
    end, "danger")
end
local function buildAbout(page)
    section(page, "APP_TITLE")
    description(page, "ABOUT_TAGLINE", 29)
    local version = textAt(page, "VERSION_LABEL", 14, -page.cursor, 476, 25)
    table.insert(S.refreshers, function() version:SetText(J.T("VERSION_LABEL") .. " " .. J.version) end)
    page.cursor = page.cursor + 30
    section(page, "ABOUT_PLAYER")
    for _, item in ipairs({{"AUTHOR_LABEL", "Dennis Hilk"}, {"REALM_LABEL", "Normal (PvE)"},
        {"GUILD_LABEL", "Ostfriesen Raid"}, {"LICENSE_LABEL", "MIT"},
        {"CLIENT_LABEL", "WoW Forever / Interface 16001"}}) do
        local t = textAt(page, item[1], 14, -page.cursor, 478, 24)
        table.insert(S.refreshers, function() t:SetText(J.T(item[1]) .. ": " .. item[2]) end)
        page.cursor = page.cursor + 27
    end
    section(page, "MORE_DENNIS")
    S.links = {}
    for _, item in ipairs({{"WEBSITE_LABEL", "https://www.dennishilk.com"},
        {"YOUTUBE_LABEL", "https://www.youtube.com/@dennis_hilk"},
        {"GITHUB_LABEL", "https://github.com/dennishilk/Just20Minutes"}}) do
        textAt(page, item[1], 14, -page.cursor, 100, 28)
        local edit = CreateFrame("EditBox", nil, page, "InputBoxTemplate")
        edit:SetSize(365, 28); edit:SetAutoFocus(false)
        edit:SetPoint("TOPLEFT", page, "TOPLEFT", 123, -page.cursor)
        edit:SetMaxLetters(160); edit:SetText(item[2])
        edit:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
        edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        edit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
        edit:SetScript("OnTextChanged", function(self)
            if self:GetText() ~= item[2] then self:SetText(item[2]); self:HighlightText() end
        end)
        J.Tooltip(edit, "COPY_LINK_HINT")
        table.insert(S.links, edit)
        page.cursor = page.cursor + 38
    end
    for i, edit in ipairs(S.links) do
        edit:SetScript("OnTabPressed", function(self)
            self:ClearFocus(); S.links[i % #S.links + 1]:SetFocus()
        end)
    end
    description(page, "COPY_LINK_HINT", 33)
    section(page, "SECTION_PRIVACY")
    description(page, "ABOUT_PRIVACY", 74)
end
local descriptions = {
    {"GENERAL", buildGeneral}, {"APPEARANCE", buildAppearance}, {"NOTIFICATIONS", buildNotifications},
    {"EXPERIENCE", buildExperience}, {"PROFILES", buildProfiles}, {"ABOUT", buildAbout},
}
function J.BuildSettings()
    S.refreshers = {}
    local frame, title = J.MakeWindow(790, 590, "SETTINGS", "settingsPosition")
    S.frame, S.title, S.pages, S.tabs = frame, title, {}, {}
    local brand = textAt(frame, "APP_TITLE", 22, -517, 190, 24, true)
    brand:SetTextColor(unpack(C.gold))
    textAt(frame, "SETTINGS_TAGLINE", 22, -545, 190, 24)
    for i, spec in ipairs(descriptions) do
        local scroll = CreateFrame("ScrollFrame", "Just20MinutesSettingsScroll" .. i,
            frame, "UIPanelScrollFrameTemplate")
        scroll:SetSize(WIDTH + 2, 490)
        scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 238, -75)
        scroll:Hide()
        S.pages[i] = scroll
        local page = CreateFrame("Frame", nil, scroll)
        page:SetSize(WIDTH, 490)
        page:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
        page:SetFrameLevel(scroll:GetFrameLevel() + 1)
        page.cursor = 0
        scroll:SetScrollChild(page)
        local tab = J.MakeButton(frame, J.T(spec[1]), 198, 42, function()
            S.active = i
            for k, p in ipairs(S.pages) do p:SetShown(k == i) end
            J.RefreshSettings()
        end)
        tab:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -80 - (i - 1) * 57)
        S.tabs[i] = tab
        spec[2](page); endSection(page)
        page:SetHeight(math.max(490, page.cursor + 18))
        scroll.content = page
    end
    S.active = 1; S.pages[1]:Show()
    J.FitWindows(); J.RefreshSettings()
end
function J.RefreshSettings()
    if not S.frame then return end
    for _, update in ipairs(S.refreshers) do update() end
    S.title:SetText(J.T("SETTINGS"))
    for i, spec in ipairs(descriptions) do
        S.tabs[i]:SetText(J.T(spec[1])); J.SetButtonStyle(S.tabs[i], "neutral", i == S.active)
    end
end
function J.OpenSettings()
    J.FitWindows()
    if J.ui and J.ui.main then J.ui.main:Hide() end
    S.frame:Show(); J.RefreshSettings()
end
