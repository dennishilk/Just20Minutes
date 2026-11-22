local _, J = ...

-- Self-contained minimap button: no LibStub, LibDataBroker or LibDBIcon required.
local function angleFromOffset(x, y)
    if x == 0 then return y >= 0 and 90 or 270 end
    local degrees = math.deg(math.atan(y / x))
    if x < 0 then
        degrees = degrees + 180
    elseif y < 0 then
        degrees = degrees + 360
    end
    return degrees % 360
end

function J.UpdateMinimapButton()
    local button = J.minimapButton
    if not button or not J.settings then return end
    local minimap = Minimap
    if not minimap then return end
    local angle = math.rad(J.settings.minimapAngle)
    local radius = (minimap:GetWidth() or 140) / 2 + 10
    button:ClearAllPoints()
    button:SetPoint("CENTER", minimap, "CENTER",
        math.cos(angle) * radius, math.sin(angle) * radius)
    button:SetShown(J.settings.showMinimapButton)
end

local function updateDrag(button)
    if not Minimap or type(GetCursorPosition) ~= "function" then return end
    local x, y = GetCursorPosition()
    local mx, my = Minimap:GetCenter()
    local scale = Minimap:GetEffectiveScale()
    if not x or not y or not mx or not my or not scale or scale <= 0 then return end
    local dx, dy = x / scale - mx, y / scale - my
    if dx * dx + dy * dy < 16 then return end
    local angle = angleFromOffset(dx, dy)
    if angle ~= J.settings.minimapAngle then
        button.movedDuringDrag = true
        J.settings.minimapAngle = angle
        J.UpdateMinimapButton()
    end
end

function J.BuildMinimapButton()
    if J.minimapButton or not Minimap then return end
    local button = CreateFrame("Button", "Just20MinutesMinimapButton", Minimap)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel((Minimap:GetFrameLevel() or 0) + 8)
    button:SetSize(31, 31)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetSize(20, 20)
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetPoint("TOPLEFT", button, "TOPLEFT", 7, -5)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01")
    icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
    icon:SetPoint("TOPLEFT", button, "TOPLEFT", 7, -5)

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetPoint("TOPLEFT", button, "TOPLEFT")

    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    button:SetScript("OnClick", function(self, mouseButton)
        if self.movedDuringDrag then
            self.movedDuringDrag = false
            return
        end
        if mouseButton == "RightButton" then
            J.OpenSettings()
        else
            J.OpenMain()
        end
    end)
    button:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(J.T("APP_TITLE"))
        if GameTooltip.AddLine then
            GameTooltip:AddLine(J.session.state == "IDLE" and J.T("NO_TIMER") or J.TimerStatus(),
                0.94, 0.93, 0.91, true)
            GameTooltip:AddLine(J.T("MINIMAP_TOOLTIP"), 0.95, 0.84, 0.5, true)
        end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
    button:SetScript("OnDragStart", function(self)
        self.movedDuringDrag = false
        self:SetScript("OnUpdate", updateDrag)
        if GameTooltip then GameTooltip:Hide() end
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)
    J.minimapButton = button
    J.UpdateMinimapButton()
end
