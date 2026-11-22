-- Lua 5.1 regression tests with mock WoW client objects (not an ingame test).
local now,wall,combat=0,1900000000,false
local lines,character={},"Player-1"
function GetTime() return now end
function time() return wall end
function UnitGUID() return character end
function UnitName() return character end
function GetLocale() return "enUS" end
function UnitAffectingCombat() return combat end
function ReloadUI() end
function hooksecurefunc() end
function PlaySound() end
SOUNDKIT={IG_MAINMENU_OPTION_CHECKBOX_ON=1}
SlashCmdList={}
DEFAULT_CHAT_FRAME={AddMessage=function(_,x) lines[#lines+1]=x end}
UIErrorsFrame={AddMessage=function(_,x) lines[#lines+1]=x end}
GameTooltip={SetOwner=function()end,SetText=function()end,Show=function()end,Hide=function()end}
local function fake()
 local f={visible=true,scripts={},value="",checked=false}
 for _,k in ipairs({"SetSize","SetPoint","SetClampedToScreen","SetMovable","EnableMouse",
 "RegisterForDrag","SetBackdrop","SetBackdropColor","SetBackdropBorderColor",
 "SetFrameStrata","SetJustifyH","SetJustifyV","SetAutoFocus","SetMaxLetters",
 "SetNumeric","SetAlpha","SetScale","SetHeight","SetWidth","ClearAllPoints",
 "SetColorTexture","SetTextColor","SetWordWrap","SetFontObject",
 "StartMoving","StopMovingOrSizing","RegisterEvent","SetTexture","SetTexCoord",
 "SetHighlightTexture","RegisterForClicks","SetFrameLevel"}) do f[k]=function()end end
 function f:SetScript(k,fn) self.scripts[k]=fn end
 function f:SetText(v) self.value=v end
 function f:GetText() return self.value end
 function f:SetChecked(v) self.checked=v end
 function f:GetChecked() return self.checked end
 function f:SetShown(v) self.visible=v end
 function f:Show() self.visible=true end
 function f:Hide() self.visible=false end
 function f:IsShown() return self.visible end
 function f:GetCenter() return 500,400 end
 function f:GetEffectiveScale() return 1 end
 function f:GetWidth() return 140 end
 function f:GetFrameLevel() return 0 end
 function f:CreateFontString() return fake() end
 function f:CreateTexture() return fake() end
 return f
end
function CreateFrame()return fake()end
UIParent=fake()
Minimap=fake()
function GetCursorPosition() return 650,400 end
local J={}
for _,name in ipairs({"Locales/enUS.lua","Locales/deDE.lua","Core.lua","Database.lua",
"Timer.lua","Notifications.lua","UI.lua","Minimap.lua","Settings.lua","Commands.lua"}) do
 assert(loadfile("Just20Minutes/"..name))("Just20Minutes",J)
end
J.DBInit();J.settings.mode="chat";J.BuildUI();J.BuildSettings();J.RegisterCommands()
local total=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if not ok then error("FAIL "..name..": "..tostring(err),0) end
 total=total+1;print("PASS "..name)
end
local function eq(a,b) assert(a==b,tostring(a).." ~= "..tostring(b)) end
local function near(a,b) assert(math.abs(a-b)<0.01,tostring(a).." ~= "..tostring(b)) end
local function tick(t)now=now+t;wall=wall+math.floor(t);J.TimerPoll()end
local function start(m)J.TimerStop(true);assert(J.TimerStart(m))end

test("UI + commands",function()
 eq(SLASH_JUST20MINUTES1,"/j20")
 eq(SLASH_JUST20MINUTES2,"/just20minutes")
 J.HandleCommand("config");assert(J.settingUI.frame:IsShown())
 J.HandleCommand("lock");assert(J.settings.locked)
 J.HandleCommand("unlock");assert(not J.settings.locked)
end)
test("20m precise countdown and zero",function()
 start(20);tick(31.3);near(J.TimerRemaining(),1168.7)
 tick(1168.7);eq(J.session.state,"EXPIRED")
 eq(J.FormatTime(J.TimerRemaining()),"00:00")
 tick(150);eq(J.FormatTime(J.TimerRemaining()),"00:00")
end)
test("hour formatting and custom minutes",function()
 start(60);eq(J.FormatTime(J.TimerRemaining()),"01:00:00")
 tick(1800);eq(J.FormatTime(J.TimerRemaining()),"30:00")
 for _,m in ipairs({1,600,47}) do start(m)end
end)
test("invalid duration and double start",function()
 start(20);assert(not J.TimerStart(20))
 for _,m in ipairs({0,-1,601,1.5,math.huge,-math.huge}) do
   assert(not J.TimerStart(m))
 end
 assert(not J.TimerStart(nil));assert(not J.TimerStart("abc"))
end)
test("pause/resume never consumes paused time",function()
 start(20);tick(90);assert(J.TimerPause());assert(not J.TimerPause())
 local left=J.TimerRemaining();tick(850);near(J.TimerRemaining(),left)
 assert(J.TimerResume());assert(not J.TimerResume())
 tick(30);near(J.TimerRemaining(),left-30)
end)
test("extension, cap, reset",function()
 start(20);tick(60)
 assert(J.TimerAdd(5));eq(J.FormatTime(J.TimerRemaining()),"24:00")
 assert(J.TimerAdd(10));eq(J.FormatTime(J.TimerRemaining()),"34:00")
 assert(not J.TimerAdd(600));J.TimerReset();eq(J.session.state,"IDLE")
end)
test("warning thresholds once only",function()
 start(20);lines={}
 tick(601);tick(301);tick(181);tick(1)
 local a,b,c=0,0,0
 for _,s in ipairs(lines) do
  if s:find("10 minutes left",1,true) then a=a+1 end
  if s:find("5 minutes left",1,true) then b=b+1 end
  if s:find("2 minutes left",1,true) then c=c+1 end
 end
 eq(a,1);eq(b,1);eq(c,1)
end)
test("short session no immediate warnings",function()
 start(5);lines={};tick(1);eq(#lines,0)
 tick(299);eq(J.session.state,"EXPIRED")
end)
test("expired extension and expiry again",function()
 start(20);tick(1200);eq(J.session.state,"EXPIRED")
 assert(J.TimerAdd(5));eq(J.session.state,"RUNNING")
 tick(300);eq(J.session.state,"EXPIRED");assert(J.session.fired["0"])
end)
test("combat deferral and popup",function()
 start(20);combat=true;lines={};tick(610)
 eq(#lines,0);assert(J.deferred)
 combat=false;J.DeliverDeferred();eq(#lines,1)
 combat=true;tick(590);assert(J.pendingFinish)
 combat=false;J.DeliverDeferred();assert(J.ui.finish:IsShown())
end)
test("off mode + character minutes",function()
 start(20);J.settings.mode="off";lines={};tick(610);eq(#lines,0)
 J.settings.mode="chat";J.settings.characterMinutes=true
 J.profile.minutes=42;eq(J.EffectiveMinutes(),42)
 J.settings.characterMinutes=false
end)
test("localization keys and fallback",function()
 for k in pairs(J.locales.enUS) do assert(J.locales.deDE[k],"missing German "..k)end
 for k in pairs(J.locales.deDE) do assert(J.locales.enUS[k],"missing English "..k)end
 J.settings.language="deDE"
 assert(J.T("MSG_START"):find("Abenteuer",1,true))
 J.settings.language="auto"
 assert(J.T("MSG_START"):find("Your adventure",1,true))
end)
test("reload preserves remaining without offline time",function()
 start(20);tick(111);J.TimerSave()
 local saved=J.TimerRemaining()
 wall=wall+3;now=2;J.DBInit();J.settings.resumeOnLogin=false
 J.TimerRestore();eq(J.session.state,"RUNNING")
 near(J.TimerRemaining(),saved);tick(4);near(J.TimerRemaining(),saved-4)
end)
test("normal logout ends session by default",function()
 start(20);tick(47);J.TimerSave()
 wall=wall+120;now=3;J.DBInit();J.settings.resumeOnLogin=false
 J.TimerRestore();eq(J.session.state,"IDLE")
end)
test("resume enabled; paused session",function()
 start(20);tick(11);J.TimerPause();J.TimerSave()
 wall=wall+600;now=1;J.DBInit();J.settings.resumeOnLogin=true
 J.TimerRestore();eq(J.session.state,"PAUSED")
 eq(J.FormatTime(J.TimerRemaining()),"19:49")
end)
test("character profile isolation",function()
 character="Player-2";J.DBInit();J.TimerRestore()
 eq(J.session.state,"IDLE");J.profile.minutes=35;J.profile.position.x=231
 character="Player-1";J.DBInit()
 eq(J.db.profiles["Player-2"].minutes,35)
 eq(J.db.profiles["Player-2"].position.x,231)
end)
test("corrupt persisted data and reset",function()
 Just20MinutesDB={settings={scale=math.huge,alpha=-7,defaultMinutes=-20},
 sessions={["Player-1"]={state="RUNNING",remaining=-500,duration="bad"}},
 profiles={["Player-1"]={minutes=999999}}}
 J.DBInit();eq(J.settings.scale,1);eq(J.settings.alpha,0.9)
 eq(J.settings.defaultMinutes,20);eq(J.profile.minutes,20)
 eq(J.session.state,"IDLE");J.ResetSettings()
end)
test("widget lock, placement, idle display",function()
 J.settings.compact=true;J.settings.scale=1.5
 J.settings.progress=false;J.settings.locked=true;J.ApplyAppearance()
 J.SavePosition(22,33);eq(J.Position().x,22)
 J.settings.widgetAlways=false;J.RefreshUI()
 assert(not J.ui.widget:IsShown())
 J.settings.widgetAlways=true;J.RefreshUI()
 assert(J.ui.widget:IsShown())
end)
test("minimap left/right clicks, drag, visibility and persistence",function()
 J.BuildMinimapButton()
 local b=J.minimapButton
 assert(b and b.scripts.OnClick and b.scripts.OnDragStart)
 local before=J.ui.main:IsShown()
 b.scripts.OnClick(b,"LeftButton")
 eq(J.ui.main:IsShown(),not before)
 J.settingUI.frame:Hide()
 b.scripts.OnClick(b,"RightButton")
 assert(J.settingUI.frame:IsShown())
 J.settings.minimapAngle=225
 b.scripts.OnDragStart(b)
 assert(b.scripts.OnUpdate)
 b.scripts.OnUpdate(b)
 b.scripts.OnDragStop(b)
 eq(J.settings.minimapAngle,0)
 J.settings.showMinimapButton=false
 J.UpdateMinimapButton()
 assert(not b:IsShown())
 J.DBInit()
 eq(J.settings.minimapAngle,0)
 eq(J.settings.showMinimapButton,false)
 J.settings.showMinimapButton=true
 J.UpdateMinimapButton()
 assert(b:IsShown())
end)
test("login never auto-starts without settings opt-in",function()
 eq(J.CleanSettings({}).autoStart,false)
 J.TimerStop(true)
 J.db.welcomeShown=true
 J.settings.autoStart=false
 assert(not J.ShouldAutoStart())
 eq(J.session.state,"IDLE")
 J.settings.autoStart=true
 assert(J.ShouldAutoStart())
 eq(J.session.state,"IDLE")
 J.settings.autoStart=false
end)
print(string.format("All %d mocked-client tests passed.",total))
