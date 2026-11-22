local _, J = ...
local S = {}
J.settingUI = S

local function textAt(parent, key, x, y, width, height)
    local t = J.MakeText(parent, "small", width, height or 24)
    t:SetJustifyH("LEFT")
    t:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    t:SetText(J.T(key))
    table.insert(S.refreshers, function() t:SetText(J.T(key)) end)
    return t
end

local function check(page, key, row, getter, setter)
    local y = -10 - row * 39
    local b = CreateFrame("CheckButton", nil, page, "UICheckButtonTemplate")
    b:SetSize(26,26)
    b:SetPoint("TOPLEFT", page, "TOPLEFT", 7, y)
    textAt(page, key, 43, y, 480, 27)
    b:SetScript("OnClick", function(self)
        setter(self:GetChecked() == true)
        J.RefreshSettings()
    end)
    table.insert(S.refreshers, function() b:SetChecked(getter() == true) end)
end

local function cycle(page, key, row, options, getter, setter)
    local y = -10 - row * 39
    textAt(page, key, 6, y, 240, 28)
    local b = J.MakeButton(page, "", 243, 27, function()
        local current = getter()
        local index = 0
        for i, option in ipairs(options) do
            if option[1] == current then index = i; break end
        end
        local nextOption = options[index % #options + 1]
        setter(nextOption[1])
        J.RefreshSettings()
    end)
    b:SetPoint("TOPLEFT", page, "TOPLEFT", 259, y)
    table.insert(S.refreshers, function()
        local current = getter()
        for _, option in ipairs(options) do
            if option[1] == current then b:SetText(J.T(option[2])); return end
        end
        b:SetText("?")
    end)
end

local function stepper(page, key, row, getter, setter, delta, lo, hi, format)
    local y = -10 - row * 39
    textAt(page, key, 6, y, 246, 28)
    local minus = J.MakeButton(page, "-", 38, 26, function()
        setter(math.max(lo, math.floor((getter() - delta) * 1000 + 0.5) / 1000))
        J.RefreshSettings()
    end)
    minus:SetPoint("TOPLEFT", page, "TOPLEFT", 267, y)
    local value = J.MakeText(page, "small", 121, 26)
    value:SetPoint("LEFT", minus, "RIGHT", 4, 0)
    local plus = J.MakeButton(page, "+", 38, 26, function()
        setter(math.min(hi, math.floor((getter() + delta) * 1000 + 0.5) / 1000))
        J.RefreshSettings()
    end)
    plus:SetPoint("LEFT", value, "RIGHT", 5, 0)
    table.insert(S.refreshers, function() value:SetText(format(getter())) end)
end

local function action(page, key, row, handler)
    local y = -10 - row * 39
    local b = J.MakeButton(page, J.T(key), 485, 29, handler)
    b:SetPoint("TOPLEFT", page, "TOPLEFT", 11, y)
    table.insert(S.refreshers, function() b:SetText(J.T(key)) end)
end

local function bool(key)
    return function() return J.settings[key] end,
        function(value)
            J.settings[key] = value
            if J.ApplyAppearance then J.ApplyAppearance() end
        end
end
local function enum(key)
    return function() return J.settings[key] end,
        function(value)
            J.settings[key] = value
            if J.ApplyAppearance then J.ApplyAppearance() end
        end
end

local function buildGeneral(page)
    local get, set = enum("defaultMinutes")
    stepper(page, "DEFAULT_DURATION", 0, get, set, 5, 1, 600,
        function(v) return J.T("MINUTES_COUNT", v) end)
    get, set = bool("showAtLogin"); check(page,"SHOW_AT_LOGIN",1,get,set)
    get, set = bool("rememberLast"); check(page,"REMEMBER_LAST",2,get,set)
    get, set = bool("autoStart"); check(page,"AUTO_START",3,get,set)
    get, set = bool("resumeOnLogin"); check(page,"RESUME_LOGIN",4,get,set)
    action(page,"RESTART_DEFAULT",6,function()
        J.TimerStop(true)
        J.TimerStart(J.settings.defaultMinutes)
    end)
    textAt(page,"LOGOUT_INFO",9,-308,495,76)
end

local function buildAppearance(page)
    local get,set = enum("scale")
    stepper(page,"SCALE",0,get,set,0.1,0.7,1.5,
        function(v) return string.format("%d%%",math.floor(v*100+0.5)) end)
    get,set = enum("alpha")
    stepper(page,"OPACITY",1,get,set,0.1,0.3,1,
        function(v) return string.format("%d%%",math.floor(v*100+0.5)) end)
    get,set = bool("compact"); check(page,"COMPACT",2,get,set)
    get,set = bool("progress"); check(page,"PROGRESS",3,get,set)
    get,set = bool("colorBlind"); check(page,"COLORBLIND",4,get,set)
    get,set = bool("locked"); check(page,"LOCK_POSITION",5,get,set)
    get,set = bool("widgetAlways"); check(page,"ALWAYS_VISIBLE",6,get,set)
    get,set = enum("theme")
    cycle(page,"COLOR_THEME",7,{{"classic","THEME_CLASSIC"},{"blue","THEME_BLUE"},{"gold","THEME_GOLD"}},get,set)
    action(page,"RESET_POSITION",9,function()
        local p = J.Position()
        p.x,p.y=0,-180
        J.ApplyAppearance()
    end)
end

local function buildNotifications(page)
    local get,set = enum("mode")
    cycle(page,"NOTIFICATION_TYPE",0,{
        {"screen","SCREEN"},{"chat","CHAT"},{"both","BOTH"},
        {"color","COLOR_ONLY"},{"off","OFF"}
    },get,set)
    get,set = bool("sound"); check(page,"SOUND",1,get,set)
    get,set = bool("deferCombat"); check(page,"DEFER_COMBAT",2,get,set)
    for i, threshold in ipairs({600,300,120,0}) do
        check(page,"WARN_"..threshold,i+2,
            function() return J.settings.warnings[threshold] end,
            function(value) J.settings.warnings[threshold]=value end)
    end
    textAt(page,"NOTIFY_INFO",9,-311,496,72)
end

local function buildExperience(page)
    local get,set = bool("family"); check(page,"FAMILY_MODE",0,get,set)
    get,set = bool("windDown"); check(page,"WINDDOWN_TIPS",1,get,set)
    get,set = bool("closingPopup"); check(page,"CLOSING_WINDOW",2,get,set)
    get,set = enum("language")
    cycle(page,"LANGUAGE",3,{{"auto","LANG_AUTO"},{"deDE","LANG_DE"},{"enUS","LANG_EN"}},get,set)
    textAt(page,"PHILOSOPHY",9,-191,488,90)
end

local function buildProfiles(page)
    local get,set = bool("characterMinutes")
    check(page,"CHAR_DURATION",0,get,set)
    stepper(page,"CHAR_DEFAULT_DURATION",1,
        function() return J.profile.minutes end,
        function(v) J.profile.minutes=v end,
        5,1,600,function(v) return J.T("MINUTES_COUNT",v) end)
    get,set = bool("characterPosition")
    check(page,"CHAR_POSITION",2,get,set)
    action(page,"COPY_ACCOUNT_POSITION",3,function()
        J.profile.position = J.Copy(J.settings.position)
        J.ApplyAppearance()
    end)
    local source, sourceLabel
    local sources = {}
    for key, profile in pairs(J.db.profiles) do
        if key ~= J.charKey and type(profile) == "table" then
            table.insert(sources, {key=key, name=profile.name})
        end
    end
    table.sort(sources, function(a,b) return a.name<b.name end)
    local index = 0
    sourceLabel = textAt(page,"COPY_FROM_CHARACTER",7,-181,242,28)
    local choose = J.MakeButton(page,"",247,28,function()
        if #sources>0 then index=index%#sources+1 end
        J.RefreshSettings()
    end)
    choose:SetPoint("TOPLEFT",page,"TOPLEFT",259,-181)
    table.insert(S.refreshers,function()
        choose:SetText(#sources>0 and (index>0 and sources[index].name or J.T("SELECT_CHARACTER"))
            or J.T("NO_CHARACTERS"))
    end)
    action(page,"COPY_CHARACTER",6,function()
        local item=sources[index]
        if not item then J.Print(J.T("SELECT_CHARACTER"));return end
        J.Confirm(J.T("COPY_CONFIRM",item.name),function()
            local src=J.db.profiles[item.key]
            J.profile.minutes=src.minutes
            J.profile.position=J.Copy(src.position)
            J.ApplyAppearance()
            J.RefreshSettings()
        end)
    end)
    action(page,"RESET_CHARACTER",7,function()
        J.Confirm(J.T("RESET_CHARACTER_CONFIRM"),function()
            J.profile.minutes=J.settings.defaultMinutes
            J.profile.position={x=0,y=-180}
            J.TimerStop(true)
            J.ApplyAppearance()
        end)
    end)
    action(page,"RESET_ALL",9,function()
        J.Confirm(J.T("RESET_ALL_CONFIRM"),function()
            J.ResetSettings()
        end)
    end)
end

local function buildAbout(page)
    textAt(page,"ABOUT_BODY",10,-18,490,345)
    local b = J.MakeButton(page,"GitHub",210,29,function()
        J.Print("https://github.com/dennishilk/Just20Minutes")
    end)
    b:SetPoint("TOPLEFT",page,"TOPLEFT",11,-361)
end

local descriptions = {
    {"GENERAL",buildGeneral},{"APPEARANCE",buildAppearance},
    {"NOTIFICATIONS",buildNotifications},{"EXPERIENCE",buildExperience},
    {"PROFILES",buildProfiles},{"ABOUT",buildAbout}
}

function J.BuildSettings()
    S.refreshers = {}
    local frame = J.MakeWindow(780, 578, "SETTINGS")
    S.frame, S.pages, S.tabs = frame, {}, {}
    for i, spec in ipairs(descriptions) do
        local page = CreateFrame("Frame",nil,frame)
        page:SetSize(538,474)
        page:SetPoint("TOPLEFT",frame,"TOPLEFT",219,-71)
        page:Hide()
        S.pages[i]=page
        local tab = J.MakeButton(frame,J.T(spec[1]),187,37,function()
            S.active=i
            for k,p in ipairs(S.pages) do p:SetShown(k==i) end
            J.RefreshSettings()
        end)
        tab:SetPoint("TOPLEFT",frame,"TOPLEFT",16,-78-(i-1)*59)
        S.tabs[i]=tab
        spec[2](page)
    end
    S.active=1
    S.pages[1]:Show()
    J.RefreshSettings()
end

function J.RefreshSettings()
    if not S.frame then return end
    for _, update in ipairs(S.refreshers) do update() end
    for i,spec in ipairs(descriptions) do
        S.tabs[i]:SetText((i==S.active and "• " or "")..J.T(spec[1]))
    end
end
function J.OpenSettings()
    S.frame:Show()
    J.RefreshSettings()
end
