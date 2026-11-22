local _, J = ...
local DEFAULTS = {
    defaultMinutes = 20, lastMinutes = 20, rememberLast = true,
    showAtLogin = true, autoStart = false, resumeOnLogin = false,
    showMinimapButton = true, minimapAngle = 225,
    widgetAlways = false, compact = false, progress = true, scale = 1,
    alpha = 0.90, locked = false, colorBlind = false, theme = "classic",
    mode = "screen", sound = false, deferCombat = true,
    family = false, windDown = true, closingPopup = true,
    language = "auto", characterMinutes = false, characterPosition = false,
    warnings = { [600] = true, [300] = true, [120] = true, [0] = true },
    position = { x = 0, y = -180 },
}
J.defaults = DEFAULTS

local function finite(n, lo, hi)
    return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
        and n >= lo and n <= hi
end
J.Finite = finite

local function copy(source)
    local target = {}
    for k, v in pairs(source) do
        target[k] = type(v) == "table" and copy(v) or v
    end
    return target
end
J.Copy = copy

local enumValues = {
    theme = { classic = true, blue = true, gold = true },
    mode = { screen = true, chat = true, both = true, color = true, off = true },
    language = { auto = true, deDE = true, enUS = true },
}
local function cleanSettings(input)
    local out = copy(DEFAULTS)
    if type(input) ~= "table" then return out end
    for key, val in pairs(DEFAULTS) do
        local given = input[key]
        if type(val) == "boolean" and type(given) == "boolean" then
            out[key] = given
        elseif type(val) == "number" then
            local lo, hi = 1, 600
            if key == "minimapAngle" then lo, hi = 0, 360 end
            if key == "scale" then lo, hi = 0.7, 1.5 end
            if key == "alpha" then lo, hi = 0.3, 1 end
            if finite(given, lo, hi) then
                out[key] = (key == "scale" or key == "alpha") and given or math.floor(given)
            end
        elseif type(val) == "string" and enumValues[key] and enumValues[key][given] then
            out[key] = given
        end
    end
    if type(input.warnings) == "table" then
        for _, threshold in ipairs({600, 300, 120, 0}) do
            if type(input.warnings[threshold]) == "boolean" then
                out.warnings[threshold] = input.warnings[threshold]
            end
        end
    end
    if type(input.position) == "table" then
        for _, axis in ipairs({"x", "y"}) do
            if finite(input.position[axis], -10000, 10000) then
                out.position[axis] = input.position[axis]
            end
        end
    end
    return out
end
J.CleanSettings = cleanSettings

local function cleanProfile(input, display)
    input = type(input) == "table" and input or {}
    return {
        name = type(input.name) == "string" and input.name:sub(1, 100) or display,
        minutes = finite(input.minutes, 1, 600) and math.floor(input.minutes) or 20,
        position = {
            x = type(input.position) == "table" and finite(input.position.x, -10000, 10000) and input.position.x or 0,
            y = type(input.position) == "table" and finite(input.position.y, -10000, 10000) and input.position.y or -180,
        }
    }
end

local function cleanSession(input)
    input = type(input) == "table" and input or {}
    local state = input.state
    if state ~= "RUNNING" and state ~= "PAUSED" and state ~= "EXPIRED" then
        state = "IDLE"
    end
    local validRemaining = finite(input.remaining, 0, 36000)
    local validDuration = finite(input.duration, 60, 36000)
    local remaining = validRemaining and input.remaining or 0
    local duration = validDuration and input.duration or 1200
    if not validRemaining or not validDuration then
        state = "IDLE"
    elseif remaining <= 0 and (state == "RUNNING" or state == "PAUSED") then
        state = "EXPIRED"
    end
    local fired = {}
    if type(input.fired) == "table" then
        for _, k in ipairs({"600", "300", "120", "0"}) do
            fired[k] = input.fired[k] == true
        end
    end
    return {
        state = state, remaining = remaining, duration = duration, fired = fired,
        exitEpoch = finite(input.exitEpoch, 0, 9999999999) and input.exitEpoch or 0,
        reloadIntent = input.reloadIntent == true,
    }
end
J.CleanSession = cleanSession

function J.DBInit()
    local old = type(Just20MinutesDB) == "table" and Just20MinutesDB or {}
    -- Schema 1: all keys are validated; unknown future fields are deliberately ignored.
    local new = {
        schema = 1, settings = cleanSettings(old.settings),
        profiles = {}, sessions = {}, welcomeShown = old.welcomeShown == true
    }
    if type(old.profiles) == "table" then
        for key, value in pairs(old.profiles) do
            if type(key) == "string" and #key <= 150 then
                new.profiles[key] = cleanProfile(value, key)
            end
        end
    end
    if type(old.sessions) == "table" then
        for key, value in pairs(old.sessions) do
            if type(key) == "string" and #key <= 150 then
                new.sessions[key] = cleanSession(value)
            end
        end
    end
    Just20MinutesDB, J.db, J.settings = new, new, new.settings
    local id = type(UnitGUID) == "function" and UnitGUID("player")
    local name = type(UnitName) == "function" and UnitName("player") or "Character"
    J.charKey = type(id) == "string" and id or tostring(name or "Character")
    J.charName = tostring(name or "Character")
    J.profile = cleanProfile(new.profiles[J.charKey], J.charName)
    J.profile.name = J.charName
    new.profiles[J.charKey] = J.profile
    J.session = cleanSession(new.sessions[J.charKey])
    new.sessions[J.charKey] = J.session
end

function J.EffectiveMinutes()
    if J.settings.characterMinutes then return J.profile.minutes end
    if J.settings.rememberLast then return J.settings.lastMinutes end
    return J.settings.defaultMinutes
end

function J.Position()
    return J.settings.characterPosition and J.profile.position or J.settings.position
end

function J.SavePosition(x, y)
    local pos = J.Position()
    if finite(x, -10000, 10000) and finite(y, -10000, 10000) then
        pos.x, pos.y = x, y
    end
end

function J.ResetSettings()
    J.db.settings = cleanSettings(nil)
    J.settings = J.db.settings
    J.db.profiles[J.charKey] = cleanProfile(nil, J.charName)
    J.profile = J.db.profiles[J.charKey]
    J.TimerStop(true)
    if J.ApplyAppearance then J.ApplyAppearance() end
    if J.UpdateMinimapButton then J.UpdateMinimapButton() end
    J.Refresh()
end
