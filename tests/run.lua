-- Lua 5.1 regression tests with mock WoW client objects (not an ingame test).
local now,wall,combat=0,1900000000,false
local lines,character={},"Player-1"
local screenLines,sounds,tooltipLines={},{},{}
function GetTime() return now end
function time() return wall end
function UnitGUID() return character end
function UnitName() return character end
function GetLocale() return "enUS" end
function UnitAffectingCombat() return combat end
function ReloadUI() end
function hooksecurefunc() end
function PlaySound(sound) sounds[#sounds+1]=sound end
SOUNDKIT={IG_MAINMENU_OPTION_CHECKBOX_ON=1}
SlashCmdList={}
DEFAULT_CHAT_FRAME={AddMessage=function(_,x) lines[#lines+1]=x end}
UIErrorsFrame={AddMessage=function(_,x) screenLines[#screenLines+1]=x end}
GameTooltip={AddLine=function(_,line) tooltipLines[#tooltipLines+1]=line end,SetOwner=function()end,SetText=function()end,Show=function()end,Hide=function()end}
local Mock = dofile("tests/mock.lua")
function CreateFrame(kind, name, parent) return Mock.create(kind, name, parent or UIParent) end
UIParent = Mock.create("Frame")
UIParent:SetSize(1920, 1080)
Minimap = Mock.create("Frame", nil, UIParent)
Minimap:SetSize(140, 140)
Minimap:SetPoint("CENTER", UIParent, "BOTTOMLEFT", 500, 400)
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
 tick(600);tick(300);tick(180);tick(1)
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
local function fresh()
 combat=false;now=0;wall=1900000000;character="Player-1"
 J.TimerStop(true);Just20MinutesDB=nil;J.DBInit();J.TimerRestore()
 J.settings.mode="chat";J.ui.welcome=false;J.ui.selectedMinutes=20
 J.widgetManuallyHidden=false;J.ui.main:Hide();J.settingUI.frame:Hide()
 J.ApplyAppearance();lines={};screenLines={};sounds={};tooltipLines={}
end
for _, item in ipairs({{1,30,10},{2,60,30},{3,90,60},{5,150,60}}) do
 test(item[1].."m adaptive start, halfway, final and expiry",function()
  fresh();assert(J.TimerStart(item[1]));eq(#lines,1);lines={}
  local plan=J.ReminderPlan();eq(plan[1].at,item[2]);eq(plan[2].at,item[3])
  tick(0.2);eq(#lines,0);tick(item[1]*60-item[2]-0.2);eq(#lines,1)
  assert(lines[1]:find(J.FormatTime(item[2]),1,true))
  tick(item[2]-item[3]);eq(#lines,2)
  tick(item[3]);eq(#lines,3);eq(J.session.state,"EXPIRED")
  tick(100);eq(#lines,3)
 end)
end
for _, duration in ipairs({10,20}) do
 test(duration.."m retains classic scheduling and no warning at Start",function()
  fresh();start(duration);eq(J.session.reminderType,"classic");lines={};tick(0.1);eq(#lines,0)
  local previous=duration*60-0.1
  for _, threshold in ipairs({600,300,120,0}) do
   if threshold<duration*60 then tick(previous-threshold);previous=threshold end
  end
  eq(#lines,duration==10 and 3 or 4)
 end)
end
test("adaptive disabled uses classic plan",function()
 fresh();J.settings.adaptive=false;start(2);lines={};eq(J.session.reminderType,"classic")
 tick(60);tick(30);eq(#lines,0);tick(30);eq(#lines,1)
end)
test("adaptive setting change keeps plan stable but mutes reminders",function()
 fresh();start(5);J.settings.adaptive=false;lines={};tick(150);eq(#lines,0)
 J.settings.adaptive=true;tick(1);eq(#lines,0);tick(89);eq(#lines,1)
 assert(J.session.fired.half)
end)
test("large adaptive jump consumes crossed warnings and tells actual time",function()
 fresh();start(2);lines={};tick(105);eq(#lines,1)
 assert(lines[1]:find("15 seconds",1,true))
 assert(J.session.fired.half and J.session.fired.final)
 tick(0.2);eq(#lines,1)
end)
test("large classic jump tells actual time",function()
 fresh();start(20);lines={};tick(1160);eq(#lines,1)
 assert(lines[1]:find("40 seconds",1,true))
 assert(J.session.fired["600"] and J.session.fired["300"] and J.session.fired["120"])
end)
test("jump directly to expiry emits only expiry",function()
 fresh();start(2);lines={};tick(900);eq(#lines,1);eq(J.TimerRemaining(),0)
 assert(J.ui.finish:IsShown());assert(not lines[1]:find("Half",1,true))
end)
test("pause just before adaptive boundary",function()
 fresh();start(2);tick(59.8);J.TimerPause();local remaining=J.TimerRemaining()
 lines={};tick(100);near(J.TimerRemaining(),remaining);eq(#lines,0)
 J.TimerResume();lines={};tick(0.21);eq(#lines,1);tick(0.1);eq(#lines,1)
end)
test("pause samples pending warning before freezing",function()
 fresh();start(2);now=60;lines={};J.TimerPause()
 eq(J.session.state,"PAUSED");assert(J.session.fired.half);eq(#lines,2)
end)
test("pause cannot trap an already expired timer",function()
 fresh();start(1);now=61;assert(not J.TimerPause());eq(J.session.state,"EXPIRED")
end)
test("extension after halfway never repeats halfway",function()
 fresh();start(2);tick(60);assert(J.TimerAdd(5));eq(J.session.planDuration,120)
 lines={};tick(300);eq(#lines,0);tick(30);eq(#lines,1)
 assert(not lines[1]:find("Half",1,true));tick(30);eq(#lines,2)
end)
test("extension before halfway retires original halfway",function()
 fresh();start(2);tick(10);J.TimerAdd(5);lines={};tick(350);eq(#lines,0)
 assert(J.session.fired.half);tick(30);eq(#lines,1)
end)
test("expiry extension permits exactly one new end reminder",function()
 fresh();start(1);tick(60);J.TimerAdd(5);lines={}
 tick(290);eq(#lines,0);tick(10);eq(#lines,1);tick(1);eq(#lines,1)
end)
test("paused extension stays paused",function()
 fresh();start(2);tick(15);J.TimerPause();J.TimerAdd(5)
 eq(J.session.state,"PAUSED");near(J.TimerRemaining(),405);tick(100);near(J.TimerRemaining(),405)
end)
test("reload just before threshold and after warning",function()
 fresh();start(2);tick(59);J.TimerSave();wall=wall+2;now=0
 J.DBInit();J.TimerRestore();lines={};eq(J.session.planDuration,120)
 tick(1);eq(#lines,1);J.TimerSave();wall=wall+2;now=0
 J.DBInit();J.TimerRestore();lines={};tick(1);eq(#lines,0)
 assert(J.session.fired.half);eq(J.session.reminderType,"adaptive")
end)
test("reload after extension keeps original plan and consumed warnings",function()
 fresh();start(2);tick(60);J.TimerAdd(5);J.TimerSave();wall=wall+2;now=0
 J.DBInit();J.TimerRestore();eq(J.session.planDuration,120);assert(J.session.fired.half)
 lines={};tick(300);eq(#lines,0)
end)
test("saving samples the exact current time before persisting",function()
 fresh();start(2);now=60;J.TimerSave();assert(J.session.fired.half);eq(J.session.remaining,60)
end)
test("classic individual warnings disabled",function()
 fresh();for key in pairs(J.settings.warnings) do J.settings.warnings[key]=false end
 start(20);lines={};tick(600);tick(300);tick(180);tick(120);eq(#lines,0)
end)
for _, mode in ipairs({"off","color"}) do
 test(mode.." suppresses messages, sound and automatic end popup",function()
  fresh();J.settings.mode=mode;J.settings.sound=true;start(2)
  tick(60);tick(30);tick(30);eq(#lines,0);eq(#screenLines,0);eq(#sounds,0)
  assert(not J.ui.toast:IsShown());assert(not J.ui.finish:IsShown())
 end)
end
for _, lang in ipairs({"enUS","deDE"}) do
 test("family short reminders and finish in "..lang,function()
  fresh();J.settings.family=true;J.settings.language=lang;start(2);lines={};tick(60)
  assert(lines[1]:find(J.T("FAMILY_ONE_MINUTE"),1,true));tick(30)
  assert(lines[2]:find(lang=="deDE" and "30 Sekunden" or "30 seconds",1,true))
  tick(30);assert(lines[3]:find(J.T("FAMILY_EXPIRED"),1,true))
  eq(J.ui.finishTitle:GetText(),J.T("FAMILY_FINISH_TITLE"))
 end)
end
test("wind-down text can be disabled in adaptive mode",function()
 fresh();J.settings.windDown=false;start(2);lines={};tick(60)
 assert(not lines[1]:find("Half",1,true));assert(lines[1]:find("60 seconds",1,true))
end)
test("combat summary uses actual time and one reminder",function()
 fresh();start(2);combat=true;lines={};tick(60);tick(30);tick(15)
 eq(#lines,0);assert(J.deferred);combat=false;J.DeliverDeferred();eq(#lines,1)
 assert(lines[1]:find("15 seconds",1,true));J.DeliverDeferred();eq(#lines,1)
end)
test("combat expiry supersedes earlier warnings",function()
 fresh();start(2);combat=true;lines={};tick(60);tick(60)
 assert(J.pendingFinish);assert(not J.ui.finish:IsShown());combat=false
 J.DeliverDeferred();eq(#lines,1);assert(J.ui.finish:IsShown())
end)
test("stop and new timer discard combat backlog",function()
 fresh();start(2);combat=true;tick(60);J.TimerStop(true);assert(not J.deferred)
 combat=false;lines={};J.DeliverDeferred();eq(#lines,0);assert(not J.pendingFinish)
end)
test("extension discards stale combat expiry",function()
 fresh();start(1);combat=true;tick(60);assert(J.pendingFinish)
 J.TimerAdd(5);combat=false;lines={};J.DeliverDeferred();eq(#lines,0)
 assert(not J.pendingFinish);assert(not J.ui.finish:IsShown())
end)
test("disabling delivery or warning while fighting suppresses backlog",function()
 fresh();start(2);combat=true;tick(60);J.settings.adaptive=false;combat=false
 lines={};J.DeliverDeferred();eq(#lines,0)
 fresh();start(2);combat=true;tick(60);J.settings.mode="off";combat=false
 lines={};J.DeliverDeferred();eq(#lines,0)
end)
test("screen-only and both use toast exactly once",function()
 for _, mode in ipairs({"screen","both"}) do
  fresh();J.settings.mode=mode;start(2);eq(#lines,mode=="both" and 1 or 0)
  eq(#screenLines,0);assert(J.ui.toast:IsShown());eq(J.ui.toastText:GetText(),J.T("MSG_START"))
 end
end)
test("chat-only never opens toast",function()
 fresh();start(2);eq(#lines,1);assert(not J.ui.toast:IsShown());eq(#screenLines,0)
end)
test("disabled toast falls back to client screen area without chat duplicate",function()
 fresh();J.settings.mode="screen";J.settings.toast=false;start(2)
 eq(#screenLines,1);eq(#lines,0);assert(not J.ui.toast:IsShown())
end)
test("toast fades then hides and respects combat",function()
 fresh();J.settings.mode="screen";start(2)
 now=0.1;J.ui.toast.scripts.OnUpdate(J.ui.toast);near(J.ui.toast.alpha,0.5)
 now=6;J.ui.toast.scripts.OnUpdate(J.ui.toast);assert(not J.ui.toast:IsShown())
 J.ShowToast("test","start");combat=true;J.ui.toast.scripts.OnUpdate(J.ui.toast)
 assert(not J.ui.toast:IsShown());combat=false
end)
test("screen popup waits for combat even if chat deferral is off",function()
 fresh();J.settings.mode="screen";J.settings.deferCombat=false;start(2);J.HideToast()
 combat=true;tick(60);assert(not J.ui.toast:IsShown());assert(J.deferred)
 combat=false;J.DeliverDeferred();assert(J.ui.toast:IsShown())
end)
test("optional built-in sound, including legacy fallback",function()
 fresh();eq(J.settings.sound,false);start(2);eq(#sounds,0)
 J.settings.sound=true;tick(60);eq(#sounds,1)
 local saved=SOUNDKIT;SOUNDKIT=nil;tick(30);eq(sounds[2],"igMainMenuOptionCheckBoxOn");SOUNDKIT=saved
end)
test("idle and pause have distinct colors and explicit statuses",function()
 fresh();local idle,key,ratio=J.StatePresentation("IDLE",0,1200,"classic")
 eq(idle,J.colors.gold);eq(key,"CONTEXT_IDLE");eq(ratio,1)
 start(2);J.TimerPause();eq(J.ui.status:GetText(),J.T("CONTEXT_PAUSED"))
 local paused=J.StatePresentation("PAUSED",60,120,"classic");eq(paused,J.colors.blue)
 J.settings.compact=true;J.ApplyAppearance();assert(J.ui.status:IsShown())
end)
test("main controls follow actual state",function()
 fresh();J.ui.main:Show();J.RefreshUI();assert(J.ui.action1:IsEnabled())
 assert(not J.ui.action2:IsEnabled());assert(not J.ui.extensions[1]:IsEnabled())
 start(2);J.RefreshUI();assert(not J.ui.action1:IsEnabled());assert(J.ui.action2:IsEnabled())
 assert(not J.ui.action3:IsEnabled());assert(J.ui.extensions[1]:IsEnabled())
 J.TimerPause();assert(J.ui.action3:IsEnabled());assert(not J.ui.action2:IsEnabled())
 J.TimerResume();tick(120);J.ui.main:Show();J.RefreshUI()
 assert(J.ui.action1:IsEnabled());assert(not J.ui.action2:IsEnabled())
end)
test("scaled drag preserves widget coordinates and saved settings",function()
 fresh();J.settings.scale=1.5;J.settings.position={x=25,y=-30};J.ApplyAppearance()
 J.ui.widget.scripts.OnDragStop(J.ui.widget);near(J.Position().x,25);near(J.Position().y,-30)
 J.DBInit();near(J.Position().x,25);near(J.settings.scale,1.5)
end)
test("window offsets persist and offscreen widget is clamped",function()
 fresh();J.settings.mainPosition={x=100,y=-80};J.FitWindows()
 J.ui.main.scripts.OnDragStop(J.ui.main);near(J.settings.mainPosition.x,100)
 near(J.settings.mainPosition.y,-80);J.DBInit();eq(J.settings.mainPosition.x,100)
 J.settings.position={x=9999,y=-9999};J.ApplyAppearance()
 local x,y,w,h=J.ui.widget:Rect();assert(x>=0 and y>=0 and x+w<=1920 and y+h<=1080)
end)
test("windows fit 1080p and ultrawide including UI scale changes",function()
 fresh();for _, size in ipairs({{1920,1080},{3440,1440},{1100,650}}) do
  UIParent:SetSize(size[1],size[2]);J.FitWindows();J.ApplyAppearance()
  for _, frame in ipairs({J.ui.main,J.settingUI.frame,J.ui.finish}) do
   local x,y,w,h=frame:Rect();assert(x>=0 and y>=0 and x+w<=size[1] and y+h<=size[2])
  end
 end
 UIParent:SetSize(1920,1080);J.FitWindows()
end)
test("main and settings do not stack",function()
 fresh();J.OpenMain();assert(J.ui.main:IsShown());J.OpenSettings()
 assert(not J.ui.main:IsShown());J.OpenMain();assert(not J.settingUI.frame:IsShown())
end)
test("all settings pages scroll and active category is marked",function()
 fresh();for i, page in ipairs(J.settingUI.pages) do
  assert(page.scrollChild);assert(page.content:GetHeight()>=490)
  local button=J.settingUI.tabs[i];button.scripts.OnClick(button)
  eq(J.settingUI.active,i);assert(button.selected)
 end
end)
test("links remain selectable, unmodified and keyboard-accessible",function()
 fresh();local expected={"https://www.dennishilk.com","https://www.youtube.com/@dennis_hilk",
 "https://github.com/dennishilk/Just20Minutes"}
 eq(#J.settingUI.links,#expected)
 for i,edit in ipairs(J.settingUI.links) do
  eq(edit:GetText(),expected[i]);edit:SetFocus();assert(edit.highlighted)
  edit:SetText("altered");edit.scripts.OnTextChanged(edit);eq(edit:GetText(),expected[i])
  edit.scripts.OnTabPressed(edit);assert(J.settingUI.links[i%#expected+1].focused)
 end
end)
test("minimap tooltip reflects state without starting timer",function()
 fresh();J.minimapButton.scripts.OnEnter(J.minimapButton)
 eq(tooltipLines[1],J.T("NO_TIMER"));eq(J.session.state,"IDLE")
 tooltipLines={};start(2);tick(15);J.minimapButton.scripts.OnEnter(J.minimapButton)
 assert(tooltipLines[1]:find("01:45",1,true));near(J.TimerRemaining(),105)
end)
test("schema-1 migration preserves profile and consumes past thresholds",function()
 fresh();Just20MinutesDB={schema=1,welcomeShown=true,settings={scale=0.7,autoStart=true},
 profiles={["Player-1"]={name="Dennis",minutes=42,position={x=8,y=9}}},
 sessions={["Player-1"]={state="RUNNING",remaining=500,duration=1200,fired={['600']=true},exitEpoch=wall,reloadIntent=true}}}
 J.DBInit();J.TimerRestore();eq(J.db.schema,2);eq(J.settings.autoStart,true)
 eq(J.settings.scale,0.7);eq(J.profile.minutes,42);eq(J.profile.position.y,9)
 assert(J.session.fired['600']);eq(J.session.reminderType,"classic")
 lines={};tick(1);eq(#lines,0)
end)
test("corrupt plan and nested settings sanitize without losing valid preferences",function()
 fresh();local s=J.CleanSession({state="RUNNING",remaining=120,duration=120,
 planDuration=math.huge,reminderType="invalid",fired={half=true,final="yes"}})
 eq(s.planDuration,120);eq(s.reminderType,nil);assert(s.fired.half);assert(not s.fired.final)
 local settings=J.CleanSettings({adaptive=false,toast=false,mainPosition={x=45,y=math.huge}})
 eq(settings.adaptive,false);eq(settings.toast,false);eq(settings.mainPosition.x,45)
 eq(settings.mainPosition.y,0);eq(settings.autoStart,false)
end)
test("first-login welcome and widget visibility never imply auto-start",function()
 fresh();J.settings.showAtLogin=true;J.settings.widgetAlways=true;J.ShowWelcome()
 eq(J.session.state,"IDLE");eq(J.TimerRemaining(),0);eq(J.settings.autoStart,false)
 J.db.welcomeShown=true;J.settings.showAtLogin=false;assert(not J.ShouldAutoStart())
end)
test("jittered frames cannot duplicate adaptive warnings",function()
 for _, duration in ipairs({1,2,3,5}) do
  fresh();start(duration);lines={};local elapsed=0
  while elapsed<duration*60+1 do tick(0.17);elapsed=elapsed+0.17 end
  eq(#lines,3)
 end
end)
-- Verify every literal translation lookup actually has both locales, including
-- labels assembled from the finite state/threshold enums.
test("all source translation keys and format placeholders match",function()
 for _, name in ipairs({"Core","Database","Timer","Notifications","UI","Minimap","Settings","Commands"}) do
  local file=assert(io.open("Just20Minutes/"..name..".lua"));local source=file:read("*a");file:close()
  for key in source:gmatch('J%.T%("([A-Z_0-9]+)"%)') do
   assert(J.locales.enUS[key],"missing English "..key);assert(J.locales.deDE[key],"missing German "..key)
  end
 end
 for key, text in pairs(J.locales.enUS) do
  local function placeholders(s) local t={} for x in s:gmatch('%%[ds]') do t[#t+1]=x end;return table.concat(t) end
  eq(placeholders(text),placeholders(assert(J.locales.deDE[key])))
 end
end)

test("legacy numeric combat state still defers screen UI",function()
 fresh();local saved=UnitAffectingCombat;UnitAffectingCombat=function() return 1 end
 assert(J.InCombat());J.settings.mode="screen";start(1);tick(60)
 assert(J.pendingFinish);assert(not J.ui.finish:IsShown());UnitAffectingCombat=saved
end)
test("all generated UI translation keys resolve in both languages",function()
 fresh();local translate=J.T
 J.T=function(key,...)
  assert(J.locales.enUS[key],"missing English "..key)
  assert(J.locales.deDE[key],"missing German "..key)
  return translate(key,...)
 end
 for _,lang in ipairs({"deDE","enUS"}) do
  J.settings.language=lang;J.RefreshSettings();J.ui.main:Show()
  for _,state in ipairs({"IDLE","RUNNING","PAUSED","EXPIRED"}) do
   J.session.state=state;J.RefreshUI()
  end
  J.settings.family=true;J.RefreshUI();J.settings.family=false
 end
 J.T=translate
end)
test("a successful slash start completes the first welcome",function()
 fresh();J.ShowWelcome();assert(J.ui.welcome);J.HandleCommand("start 2")
 assert(J.db.welcomeShown);assert(not J.ui.welcome);eq(J.session.state,"RUNNING")
end)
print(string.format("All %d mocked-client tests passed.",total))
