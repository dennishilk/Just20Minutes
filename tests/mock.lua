-- A strict, inspectable subset of the legacy UI API used by this addon.
-- Unknown methods are errors. This harness is not evidence of client support.
local M = {objects = {}}
local function create(kind, name, parent)
    local f = {kind = kind or "Frame", name = name, parent = parent,
        visible = true, scripts = {}, value = "", checked = false, enabled = true,
        width = 0, height = 0, scale = 1, alpha = 1, level = parent and parent.level + 1 or 0}
    table.insert(M.objects, f)
    if name then _G[name] = f end
    function f:SetSize(w, h) self.width, self.height = w, h end
    function f:SetWidth(w) self.width = w end
    function f:SetHeight(h) self.height = h end
    function f:GetWidth() return self.width end
    function f:GetHeight() return self.height end
    function f:SetScale(v) self.scale = v end
    function f:GetEffectiveScale() return self.scale * (self.parent and self.parent:GetEffectiveScale() or 1) end
    function f:SetAlpha(v) self.alpha = v end
    function f:SetPoint(point, relative, relativePoint, x, y)
        self.anchor = {point, relative or self.parent, relativePoint or point, x or 0, y or 0}
    end
    function f:ClearAllPoints() self.anchor = nil end
    function f:Rect()
        local scale = self:GetEffectiveScale()
        if self == UIParent then return 0, 0, self.width, self.height end
        local w, h = self.width * scale, self.height * scale
        local a = self.anchor
        if not a then return 0, 0, w, h end
        local rx, ry, rw, rh = a[2]:Rect()
        local function offset(point, width, height)
            return point:find("LEFT") and 0 or point:find("RIGHT") and width or width / 2,
                point:find("BOTTOM") and 0 or point:find("TOP") and height or height / 2
        end
        local ox, oy = offset(a[1], w, h)
        local tx, ty = offset(a[3], rw, rh)
        return rx + tx + a[4] * scale - ox, ry + ty + a[5] * scale - oy, w, h
    end
    function f:GetCenter()
        local x, y, w, h = self:Rect()
        local scale = self:GetEffectiveScale()
        return (x + w / 2) / scale, (y + h / 2) / scale
    end
    function f:GetFrameLevel() return self.level end
    function f:SetFrameLevel(v) self.level = v end
    function f:SetFrameStrata(v) self.strata = v end
    function f:SetScript(k, fn) self.scripts[k] = fn end
    function f:SetText(v) self.value = tostring(v); if self.label then self.label.value = self.value end end
    function f:GetText() return self.value end
    function f:SetChecked(v) self.checked = v end
    function f:GetChecked() return self.checked end
    function f:SetShown(v) self.visible = v end
    function f:Show() self.visible = true end
    function f:Hide() self.visible = false end
    function f:IsShown() return self.visible end
    function f:Enable() self.enabled = true end
    function f:Disable() self.enabled = false end
    function f:IsEnabled() return self.enabled end
    function f:SetFontString(v) self.label = v end
    function f:GetFont() return "MockFont", self.fontSize or 13, "" end
    function f:SetFont(_, size) self.fontSize = size end
    function f:SetTextColor(...) self.textColor = {...} end
    function f:SetColorTexture(...) self.fill = {...} end
    function f:SetBackdropColor(...) self.fill = {...} end
    function f:SetBackdropBorderColor(...) self.border = {...} end
    function f:SetJustifyH(v) self.justify = v end
    function f:SetScrollChild(v) self.scrollChild = v end
    function f:SetVerticalScroll(v) self.scrollOffset = v end
    function f:SetFocus() self.focused = true; if self.scripts.OnEditFocusGained then self.scripts.OnEditFocusGained(self) end end
    function f:ClearFocus() self.focused = false end
    function f:HighlightText() self.highlighted = true end
    function f:SetHighlightTexture() self.highlight = create("Texture", nil, self) end
    function f:GetHighlightTexture() return self.highlight end
    function f:CreateFontString(name) return create("FontString", name, self) end
    function f:CreateTexture(name) return create("Texture", name, self) end
    for _, key in ipairs({"SetClampedToScreen", "SetMovable", "EnableMouse", "RegisterForDrag",
        "SetBackdrop", "SetJustifyV", "SetAutoFocus", "SetMaxLetters", "SetNumeric", "SetWordWrap",
        "SetFontObject", "StartMoving", "StopMovingOrSizing", "RegisterEvent", "SetTexture",
        "SetTexCoord", "RegisterForClicks", "SetVertexColor"}) do
        f[key] = function() end
    end
    return f
end
M.create = create
return M
