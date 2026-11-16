-- Violation District / SmugLib V2 / 2026-11-09.6
-- Executor client. All active features start disabled. See README.md for controls and feature scope.
local source = game:HttpGet("https://raw.githubusercontent.com/Xa3ro5/LifeIsRoblox/refs/heads/main/SmugLibCoreV2.lua")
local factory, compileError = loadstring(source, "SmugLibCoreV2")
assert(factory, compileError)
local Library = factory()
assert(type(Library) == "table" and type(Library.CreateWindow) == "function", "Could not load SmugLib V2.")

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
local Tags = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local PathfindingService = game:GetService("PathfindingService")
local LocalPlayer = Players.LocalPlayer
local env = getgenv()
if env.SmugVD and type(env.SmugVD.Unload) == "function" then env.SmugVD:Unload() end
assert(game.GameId == 6739698191, "This adapter is intended for Violation District.")

local A = {alive=true, version="2026-11-09.6", connections={}, changes={}, entries={}, failures={},
    generation=0, controls={}, adapter={}, points={}, generators={}, pumpkins={}, blacklist={}, heldKeys={},clickLeases={},
    status={action="Disabled", target="None", result="No confirmed result yet", waiting="None"},
    metrics={skillInputs=0, parryRequests=0, parrySuccess=0, repairGain=0, pumpkinAttempts=0, pumpkinsConfirmed=0, recoveryStarts=0,equipmentWrites=0},
    config={esp=false, objectESP=false, aim=false, flashlightAim=false, autoQTE=false,
        autoRepair=false, autoParry=false, selfRecover=false, pumpkinFarm=false,
        lowGraphics=false, fullbright=false, customFOV=false, fov=80, aimRadius=220,
        smooth=16, prediction=0.1, ballistic=false, projectileSpeed=165, projectileGravity=98.1,
        parryRange=0,equipmentRole="Survivor",perkSlot=1,selectedPerk="",selectedItem="",
        forceSpeed=false,forceMovement=false,forceSlow=false,forcedSpeed=40,
        forceBonuses=false,bonusSpeed=1.5,bonusWalk=1.2,bonusVault=1.15,bonusCrouch=2,
        unlockCursor=false,allPerkBoosts=false,perkStacks=1,speedBoost=1,
        noItemCooldowns=false,infiniteItems=false,antiRubber=false,instantFlick=false,freeCamera=false,silentAim=false,
        selfHeal=false,selfHealHandoff=93,cameraSensitivity=.18}}



env.SmugVD = A
local C = A.config
local PerkBoosts
local Motion,CameraControl,Items,SelfHeal
local function playerRole(player)
    local name=player.Team and player.Team.Name
    if name=="Survivors" then return "Survivor" end
    if name=="Killer" then return "Killer" end
    return "Spectator"
end
local function finiteNumber(value,fallback,minimum)
    value=tonumber(value)
    if not value or value~=value or math.abs(value)==math.huge then return fallback end
    return math.max(value,minimum or 0)
end
local function connect(signal, fn)
    local c=signal:Connect(fn); table.insert(A.connections,c); return c
end
local function notify(s) if A.window then A.window:Notify(tostring(s),4) end end
local function character()
    local ch=LocalPlayer.Character
    local h=ch and ch:FindFirstChildOfClass("Humanoid")
    local root=ch and ch:FindFirstChild("HumanoidRootPart")
    if ch and h and root and h.Health>0 then return ch,h,root end
end
local function property(obj,key) return obj[key] end
local function assign(obj,key,value) obj[key]=value end
-- Remember the most recent external value, and restore only values still owned here.
local function own(group,obj,key,value)
    local list=A.changes[group]
    if not list then list={rows={},index={}}; A.changes[group]=list end
    local keys=list.index[obj]
    if not keys then keys={}; list.index[obj]=keys end
    local row=keys[key]
    local ok,current=pcall(property,obj,key)
    if not ok then return end
    if not row then row={obj=obj,key=key,original=current}; table.insert(list.rows,row); keys[key]=row
    elseif current~=row.last then row.original=current end
    if pcall(assign,obj,key,value) then row.last=value end
end
local function restore(group)
    local list=A.changes[group]; A.changes[group]=nil
    if not list then return end
    for i=#list.rows,1,-1 do
        local r=list.rows[i]
        pcall(function() if r.obj[r.key]==r.last then r.obj[r.key]=r.original end end)
    end
end
local function observedAttribute(object,key)
    local current=object:GetAttribute(key)
    local force=A.force
    if force then for _,objects in force.attributes do
        local keys=objects[object]; local row=keys and keys[key]
        if row and current==row.last then return row.original end
    end end
    return current
end

-- FEATURE_GUARD_BEGIN
-- Failure ownership follows the worker/resource, never the whole application.
function A:ClearFailure(key)
    self.failures=self.failures or {}
    for id,failure in self.failures do
        if key==nil or id==key or table.find(failure.keys,key) then self.failures[id]=nil end
    end
    if next(self.failures)==nil then self.lastError=nil end
end
function A:RunFeature(id,keys,callback,cleanup,retryDelay)
    self.failures=self.failures or {}
    local previous=self.failures[id]
    if previous and (not previous.retryAt or os.clock()<previous.retryAt) then return false end
    local good,problem=xpcall(callback,debug.traceback)
    if good then
        if previous then self.failures[id]=nil; if next(self.failures)==nil then self.lastError=nil end end
        return true
    end
    local failure={keys=keys or {},message=tostring(problem),retryAt=retryDelay and os.clock()+retryDelay}
    self.failures[id]=failure; self.lastError=id..": "..failure.message
    for _,key in failure.keys do
        C[key]=key=="speedBoost" and 1 or false
        if self.controls and self.controls[key] then pcall(function() self.controls[key]:Set(false) end) end
        if key=="speedBoost" and self.speedControl then pcall(function() self.speedControl:Set(1) end) end
    end
    if cleanup then
        local cleaned,cleanupError=pcall(cleanup)
        if not cleaned then failure.cleanupError=tostring(cleanupError) end
    end
    self.status.waiting="Error in "..id.."; other features remain enabled. See Settings."
    if not previous then pcall(notify,"Error in "..id..". Other features remain enabled; details in Settings.") end
    return false
end
-- FEATURE_GUARD_END

-- CURSOR_CONTROLLER_BEGIN
local Cursor={menuSuppressed=false,focused=true}
function Cursor:Desired()
    if not self.focused then return false end
    return C.unlockCursor or (not self.menuSuppressed and A.window and A.window:GetGui().Enabled and not A.window:IsMinimized())
end
function Cursor:Step()
    if not A.alive or not self:Desired() then self:Stop(); return end
    if not self.original then
        self.original={behavior=UIS.MouseBehavior,icon=UIS.MouseIconEnabled}
        local good,mouse=pcall(function() return LocalPlayer:GetMouse() end)
        if good and mouse then self.mouse=mouse; self.original.image=mouse.Icon end
    end
    if self.modal then self.modal.Visible=true end
    UIS.MouseBehavior=Enum.MouseBehavior.Default
    UIS.MouseIconEnabled=true
    if self.mouse then self.mouse.Icon="" end
end
function Cursor:Stop()
    if self.modal then self.modal.Visible=false end
    local original=self.original; self.original=nil
    if original then
        local ch=LocalPlayer.Character
        local nativeCamera=ch and ch:GetAttribute("RoundScriptsActive")==true
            and (ch:FindFirstChild("SmoothCamera") or ch:FindFirstChild("Firstperson"))
        UIS.MouseBehavior=nativeCamera and Enum.MouseBehavior.LockCenter or original.behavior
        if nativeCamera then UIS.MouseIconEnabled=false else UIS.MouseIconEnabled=original.icon end
        if self.mouse and self.mouse.Icon=="" then self.mouse.Icon=original.image or "" end
    end
    self.mouse=nil
end
function Cursor:Reset()
    C.unlockCursor=false; self.menuSuppressed=true; self:Stop()
    if A.controls.unlockCursor then A.controls.unlockCursor:Set(false) end
end
A.cursor=Cursor
-- CURSOR_CONTROLLER_END

local Adapter={}
-- RULES_BEGIN: pure gates derived from the inspected native client handlers.
local Rules={}
function Rules.canAct(s,allowDowned)
    if not s.alive then return false,"Waiting for a live character" end
    if s.role~="Survivors" then return false,"Requires a survivor" end
    if not s.roundActive then return false,"Waiting for an active round" end
    if s.lock then return false,s.lock end
    if not allowDowned and s.health<=50 then return false,"Character is downed" end
    return true
end
function Rules.canRecover(s)
    local ok,why=Rules.canAct(s,true)
    if not ok then return false,why end
    if s.health>50 then return false,"Native self-recovery is available only while downed" end
    if s.healLocked then return false,"The native healing action is locked" end
    if s.busy then return false,"Another native action is active" end
    if not s.selfTarget then return false,"Wait for the native self-recovery prompt while stationary" end
    return true
end
function Rules.canHarvest(s)
    local ok,why=Rules.canAct(s,false)
    if not ok then return false,why end
    if s.busy then return false,"Another native action is active" end
    if not s.tagged or not s.nativeTarget then return false,"Native pumpkin prompt is unavailable" end
    if not s.distance or s.distance>4 then return false,"Pumpkin is outside the native 4-stud range" end
    return true
end
function Rules.canSprint(s)
    local ok,why=Rules.canAct(s,false)
    if not ok then return false,why end
    if s.busy or s.aiming or s.crouching then return false,"Native action, aiming, or crouching prevents sprint assistance" end
    return true
end
function Rules.canWalk(s)
    if not s.alive then return false,"Waiting for a live character" end
    if s.role~="Survivors" and s.role~="Killer" then return false,"Navigation requires an active player role" end
    if not s.roundActive then return false,"Waiting for an active round" end
    if s.lock then return false,s.lock end
    if s.role=="Survivors" and s.health<=50 then return false,"Character is downed" end
    if s.busy then return false,"Another native action is active" end
    return true
end
function Rules.canEquip(owned,slot,equipped,name)
    if not owned then return false,"This perk is not owned" end
    if type(slot)~="number" or slot%1~=0 or slot<1 or slot>3 then return false,"Select one of the three native perk slots" end
    for key,entry in equipped do
        local index=type(key)=="number" and key or tonumber(tostring(key):match("%d+"))
        if type(entry)=="table" and entry.name==name and index~=slot then return false,"This perk is already equipped in another slot" end
    end
    return true
end
-- RULES_END

function Adapter.State()
    local ch,h,root=character()
    local ctx=A.adapter.repair
    if ctx and ctx.character~=ch then ctx=nil end
    local state={alive=ch~=nil,health=h and h.Health or 0,role=LocalPlayer.Team and LocalPlayer.Team.Name,
        roundActive=ch and ch:GetAttribute("RoundScriptsActive")==true,
        busy=ctx and (ctx.state.activeMouseAction~=nil or ctx.script:GetAttribute("isVaulting")==true),
        aiming=ch and ch:GetAttribute("Aiming"),crouching=ch and ch:GetAttribute("Crouching"),
        healLocked=ch and ch:GetAttribute("lock_heal")==true}
    if ch then
        for _,name in {"Trapped","Chained","IsCarried","IsHooked","IsStunned","Rooted","Immobile","MovementLocked"} do
            if observedAttribute(ch,name) then state.lock=name; break end
        end
        if LocalPlayer:GetAttribute("IsDead") then state.lock="Player is dead" end
        if (ch:GetAttribute("HookCount") or 0)>=3 then state.lock="The native interaction hook limit was reached" end
    end
    state.selfTarget=ctx and ctx.proximity and ctx.proximity.state.healTarget==root
    return state,ch,h,root,ctx
end
function Adapter.RefreshRuntime()
    A.adapter={}
    if type(getgc)~="function" then return end
    local ch=LocalPlayer.Character
    if not ch then return end
    for _,t in getgc(true) do
        if type(t)=="table" and rawget(t,"character")==ch then
            if rawget(t,"normalWalkSpeed") and rawget(t,"_movement") then A.adapter.movement=t end
            if rawget(t,"prompts") and rawget(t,"state") and rawget(t,"script") then A.adapter.repair=t end
            if rawget(t,"parryEvent") and rawget(t,"tool") then A.adapter.parry=t end
            local config=rawget(t,"config")
            if rawget(t,"tool") and type(config)=="table" and config.minHealth and config.maxHealth
                and type(t._canUse)=="function" and type(t._setAiming)=="function" then A.adapter.bandage=t end
            if rawget(t,"vmAnimations") and rawget(t,"config") and rawget(t,"state") then A.adapter.killer=t end
        end
    end
    local good,actions=pcall(require,RS.Modules.Survivors.SurvivorActions)
    if good then A.adapter.actions=actions end
end
function Adapter.RefreshWorld()
    A.points={}; A.generators={}; A.pumpkins={}
    local map=workspace:FindFirstChild("Map")
    local seen={}
    for _,name in {"Generator","Generators"} do
        local folder=map and map:FindFirstChild(name)
        if folder then for _,g in folder:GetChildren() do
            if g:IsA("Model") then table.insert(A.generators,g); seen[g]=true end
        end end
    end
    for _,p in Tags:GetTagged("GeneratorPoint") do
        if p:IsA("BasePart") and map and p:IsDescendantOf(map) then
            table.insert(A.points,p)
            if p.Parent:IsA("Model") and not seen[p.Parent] then table.insert(A.generators,p.Parent); seen[p.Parent]=true end
        end
    end
    for _,p in Tags:GetTagged("pumpkin") do
        if map and p:IsA("BasePart") and p:IsDescendantOf(map) then table.insert(A.pumpkins,p) end
    end
end
function Adapter.CanAct(allowDowned)
    local state,ch,h,root=Adapter.State()
    local ok,why=Rules.canAct(state,allowDowned)
    return ok,why,ch,h,root
end
local function los(origin,part)
    local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances={LocalPlayer.Character,workspace.CurrentCamera}
    local hit=workspace:Raycast(origin,part.Position-origin,params)
    return not hit or hit.Instance==part or hit.Instance:IsDescendantOf(part.Parent)
end
function Adapter.NearbyRepairPoint()
    local ctx=A.adapter.repair
    if not ctx or ctx.character~=LocalPlayer.Character then return end
    local ok=Adapter.CanAct()
    if not ok or ctx.state.activeMouseAction or ctx.humanoidRootPart.Anchored then return end
    if ctx.character:GetAttribute("lock_repair")==true then return end
    local p=ctx.proximity and ctx.proximity.state.generatorPoint
    if p and p.Parent and Tags:HasTag(p,"GeneratorPoint") and not Tags:HasTag(p.Parent,"Blocked")
        and p:GetAttribute("IsRepairing")~=true and (p.Position-ctx.humanoidRootPart.Position).Magnitude<=4
        and los(ctx.humanoidRootPart.Position,p) then return p,ctx end
end

local interactionInput
local function stopRepair()
    local r=A.repair; A.repair=nil
    if not r then return end
    if interactionInput then pcall(interactionInput,false,"repair") end
end
local function repairStep()
    if not C.autoRepair then stopRepair(); return end
    if A.move or A.pumpkinAttempt or A.recovery or A.bindHeal then
        stopRepair(); A.status.waiting="Navigation, pumpkin farming, or self-recovery has priority"; return
    end
    local r=A.repair
    if r then
        local allowed,why=Adapter.CanAct()
        if allowed and r.ctx.character==LocalPlayer.Character and not r.ctx.script:GetAttribute("isRepairing") and os.clock()-r.sentAt<0.8 then return end
        if not allowed or r.ctx.character~=LocalPlayer.Character or not r.point.Parent
            or r.ctx.state.currentRepairPoint~=r.point or not r.ctx.script:GetAttribute("isRepairing") then
            stopRepair(); A.status.waiting=why or "Repair ended"; A.repairRetry=os.clock()+2; return
        end
        local g=r.point.Parent
        local progress=g:GetAttribute("RepairProgress")
        if type(progress)=="number" and progress>r.progress then
            A.metrics.repairGain=A.metrics.repairGain+progress-r.progress
            A.status.result=string.format("Replicated generator progress %.1f -> %.1f",r.progress,progress)
            r.progress=progress; r.lastProgress=os.clock()
        end
        A.status.action="Repairing generator"; A.status.target=string.format("%.1f %%",progress or 0)
        A.status.waiting="Native repair / skillcheck"
        if (progress and progress>=100) or os.clock()-r.lastProgress>15 then
            stopRepair(); A.repairRetry=os.clock()+3
            A.status.waiting="Completed or no progress for 15 seconds"
        end
        return
    end
    if os.clock()<(A.repairRetry or 0) then return end
    local point,ctx=Adapter.NearbyRepairPoint()
    if not point then A.status.waiting="Walk to an available generator point (within 4 studs)"; return end
    if not point.Parent or not Tags:HasTag(point,"GeneratorPoint") or not Adapter.NearbyRepairPoint() then return end
    A.repair={ctx=ctx,point=point,sentAt=os.clock(),progress=point.Parent:GetAttribute("RepairProgress") or 0,lastProgress=os.clock()}
    local started,why=interactionInput(true,"repair")
    if not started then A.repair=nil; A.status.waiting=why end
end

-- Feed the game's real key handler. No fabricated skillcheck IDs or remote payloads.
local VIM
pcall(function() VIM=game:GetService("VirtualInputManager") end)
local function worldInputPoint()
    local camera=workspace.CurrentCamera
    local size=camera and camera.ViewportSize or Vector2.new(1280,720)
    -- Use a world-side position, rather than clicking the toggle that armed the feature.
    for _,fraction in {Vector2.new(0.88,0.42),Vector2.new(0.12,0.42),Vector2.new(0.88,0.25)} do
        local point=Vector2.new(math.floor(size.X*fraction.X),math.floor(size.Y*fraction.Y))
        local blocked=false
        for _,gui in LocalPlayer.PlayerGui:GetGuiObjectsAtPosition(point.X,point.Y) do
            if gui:IsA("GuiButton") or gui:IsA("TextBox") then blocked=true; break end
        end
        if not blocked then return point end
    end
    return nil,"No clear game-input position; move or hide the menu to resume this action"
end
local function sendBinding(name,down,position)
    if not VIM then error("VirtualInputManager is unavailable") end
    if name=="MouseButton1" or name=="MouseButton2" then
        local point=position or worldInputPoint()
        if not point then error("No clear game-input position is available",0) end
        if down then VIM:SendMouseMoveEvent(point.X,point.Y,game) end
        VIM:SendMouseButtonEvent(point.X,point.Y,name=="MouseButton1" and 0 or 1,down,game,0)
    else
        local ok,key=pcall(function() return Enum.KeyCode[name] end)
        if not ok then error("Unsupported input binding: "..tostring(name)) end
        VIM:SendKeyEvent(down,key,false,game)
    end
end
local function releaseClick(lease)
    if lease.released then return end
    lease.released=true
    if A.clickLeases[lease.name]==lease then A.clickLeases[lease.name]=nil end
    -- An old delayed release must never release a newer owner's input.
    if A.clickLeases[lease.name] and A.clickLeases[lease.name]~=lease then return end
    pcall(sendBinding,lease.name,false,lease.position)
end
local function pressBinding(action)
    local name=LocalPlayer:GetAttribute("kb_"..action) or (action=="item" and "MouseButton2" or "Space")
    local point=(name=="MouseButton1" or name=="MouseButton2") and worldInputPoint() or nil
    if (name=="MouseButton1" or name=="MouseButton2") and not point then return false,"Move or hide the menu to allow game input" end
    if point then
        if A.clickLeases[name] or (A.interactionLease and A.interactionLease.name==name) then return false,"Another action owns this input" end
        local lease={name=name,position=point}; A.clickLeases[name]=lease
        sendBinding(name,true,point)
        task.delay(0.06,function() releaseClick(lease) end)
    else sendBinding(name,true); sendBinding(name,false) end
    return true
end
interactionInput=function(down,owner)
    local lease=A.interactionLease
    if not down then
        if lease and lease.owner==owner then
            A.interactionLease=nil
            sendBinding(lease.name,false,lease.position)
            if lease.ctx and lease.ctx.character==LocalPlayer.Character then
                local actions=lease.actions
                if actions then
                    if owner=="repair" and lease.ctx.state.activeMouseAction=="repairing" then actions.stopRepair(lease.ctx)
                    elseif owner=="recovery" and lease.ctx.state.activeMouseAction=="healing" then actions.stopHeal(lease.ctx) end
                end
            end
        end
        return
    end
    if lease then if lease.owner~=owner then error("Another feature owns native interaction input") end; return end
    if A.clickLeases[LocalPlayer:GetAttribute("kb_interact") or "MouseButton1"] then return false,"Another action owns interaction input" end
    local name=LocalPlayer:GetAttribute("kb_interact") or "MouseButton1"
    local point=(name=="MouseButton1" or name=="MouseButton2") and worldInputPoint() or nil
    if (name=="MouseButton1" or name=="MouseButton2") and not point then return false,"Move or hide the menu to allow interaction input" end
    A.interactionLease={owner=owner,name=name,position=point,ctx=A.adapter.repair,actions=A.adapter.actions}
    sendBinding(name,true,point)
    return true
end
local function qteStep()
    if not C.autoQTE or UIS:GetFocusedTextBox() or A.move then return end
    local gui=LocalPlayer.PlayerGui:FindFirstChild("SkillCheckPromptGui")
    local check=gui and gui:FindFirstChild("Check")
    local line=check and check:FindFirstChild("Line")
    local goal=check and check:FindFirstChild("Goal")
    if not (gui and gui.Enabled and check and check.Visible and line and goal) then A.qteLatch=nil; return end
    local ch=LocalPlayer.Character
    local controller=ch and ch:FindFirstChild("CheckInterractable")
    if not controller or not (controller:GetAttribute("isRepairing") or controller:GetAttribute("isHealing")) then return end
    if A.qteLatch and os.clock()-A.qteLatch<0.2 then return end
    local rotation=line.Rotation-goal.Rotation


    if rotation>=104 and rotation<=114 then
        local sent,why=pressBinding("skillcheck")
        if not sent then A.status.waiting=why; return end
        A.qteLatch=os.clock(); A.metrics.skillInputs=A.metrics.skillInputs+1
        A.status.result="Skillcheck input sent inside the perfect window; server acceptance is unconfirmed"
    end
end



-- BALLISTICS_BEGIN: solve the native trajectory, including the spear's forward spawn offset.
local Ballistics={}
function Ballistics.Solve(origin,position,velocity,speed,gravity,offset,maxTime,lead)
    if speed<=0 or speed~=speed then return end
    offset=offset or 0; lead=lead or 0
    local function sample(t)
        local displacement=position+velocity*(t+lead)-origin-gravity*(.5*t*t)
        return displacement.Magnitude-speed*t-offset,displacement
    end
    local previousTime=.001; local previous=sample(previousTime)
    for i=1,128 do
        local time=(maxTime or 4)*i/128; local value=sample(time)
        if previous>0 and value<=0 then
            local lo,hi=previousTime,time
            for _=1,24 do local mid=(lo+hi)*.5; if sample(mid)>0 then lo=mid else hi=mid end end
            local flight=(lo+hi)*.5; local _,delta=sample(flight)
            if delta.Magnitude>.001 then return delta.Unit,flight end
            return
        end
        previousTime=time; previous=value
    end
end
A.ballistics=Ballistics
-- BALLISTICS_END
local function aimTarget(partName)
    local camera=workspace.CurrentCamera
    local _,_,root=character()
    if not camera or not root then return end
    if playerRole(LocalPlayer)=="Spectator" then return end
    local best,score=nil,C.aimRadius
    local mouse=UIS:GetMouseLocation()-game:GetService("GuiService"):GetGuiInset()
    for _,p in Players:GetPlayers() do
        if p~=LocalPlayer and p.Team and (p.Team.Name=="Survivors" or p.Team.Name=="Killer")
            and playerRole(p)~=playerRole(LocalPlayer) and p.Character and not p:GetAttribute("IsDead") then
            local ch=p.Character; local h=ch:FindFirstChildOfClass("Humanoid")
            local part=ch:FindFirstChild(partName or "Head") or ch:FindFirstChild("HumanoidRootPart")
            if partName=="HumanoidRootPart" and part and not los(camera.CFrame.Position,part) then
                for _,name in {"Torso","UpperTorso","Head"} do
                    local candidate=ch:FindFirstChild(name)
                    if candidate and los(camera.CFrame.Position,candidate) then part=candidate; break end
                end
            end
            if h and h.Health>0 and part and not ch:GetAttribute("IsHooked") and not ch:GetAttribute("IsCarried")
                and not ch:GetAttribute("Knocked") and not ch:GetAttribute("Iframes")
                then
                local xy,visible=camera:WorldToViewportPoint(part.Position)
                local distance=(Vector2.new(xy.X,xy.Y)-mouse).Magnitude
                if visible and distance<score and los(camera.CFrame.Position,part) then best=part; score=distance end
            end
        end
    end
    return best
end
local function aimStep(dt)
    if not (C.aim or C.flashlightAim) or A.move or Cursor:Desired() or not Cursor.focused or UIS:GetFocusedTextBox() then return end
    local active=C.aim and UIS:IsKeyDown(Enum.KeyCode.LeftAlt)
    local ch=LocalPlayer.Character
    if C.flashlightAim and ch and ch:FindFirstChild("Flashlight") then
        local key=A.flashlightBind and A.flashlightBind:GetKey() or Enum.UserInputType.MouseButton2
        if key.EnumType==Enum.KeyCode then active=active or UIS:IsKeyDown(key)
        else active=active or UIS:IsMouseButtonPressed(key) end
    end
    if not active then return end
    local spear=ch and ch:GetAttribute("MorphedKiller")=="Veil" and ch:GetAttribute("spearmode")==true
    local target=aimTarget(spear and "HumanoidRootPart" or "Head")
    if not target then return end
    local cam=workspace.CurrentCamera
    local position=target.Position+target.AssemblyLinearVelocity*C.prediction
    if spear then
        local mathModule=Items:SpearMath()
        local charge=Items.charge
        local seconds=charge and charge.character==ch and workspace:GetServerTimeNow()-charge.time or 1
        local direction=Ballistics.Solve(cam.CFrame.Position,target.Position,target.AssemblyLinearVelocity,
            mathModule.power(seconds),mathModule.Gravity,mathModule.SpawnOffset,mathModule.MaxLife,C.prediction)
        if not direction then A.status.waiting="Charge the spear longer or select a closer target"; return end
        position=cam.CFrame.Position+direction*100
    elseif C.ballistic and not C.flashlightAim then
        local origin=cam.CFrame.Position
        local speed=C.projectileSpeed
        local delta=position-origin
        local flat=Vector3.new(delta.X,0,delta.Z).Magnitude
        local gravity=C.projectileGravity
        if flat>0.01 and gravity>0 then
            local discriminant=speed^4-gravity*(gravity*flat^2+2*delta.Y*speed^2)
            if discriminant<0 then A.status.waiting="Target is outside the configured ballistic range"; return end
            local tangent=(speed^2-math.sqrt(discriminant))/(gravity*flat)
            local time=flat/(speed/math.sqrt(1+tangent*tangent))
            position=target.Position+target.AssemblyLinearVelocity*(time+C.prediction)
            -- Recompute the low arc after leading a moving target.
            delta=position-origin; flat=Vector3.new(delta.X,0,delta.Z).Magnitude
            discriminant=speed^4-gravity*(gravity*flat^2+2*delta.Y*speed^2)
            if flat<0.01 or discriminant<0 then return end
            position=origin+Vector3.new(delta.X,flat*(speed^2-math.sqrt(discriminant))/(gravity*flat),delta.Z)
        end
    end
    A.status.target=target.Parent.Name
    A.status.action="Camera aim"
    local wanted=CFrame.lookAt(cam.CFrame.Position,position)
    cam.CFrame=cam.CFrame:Lerp(wanted,C.instantFlick and 1 or 1-math.exp(-C.smooth*dt))
end

local function parryStep()
    if not C.autoParry or os.clock()<(A.parryPendingUntil or 0) or A.move then return end
    local allowed,why,ch,_,root=Adapter.CanAct()
    if not allowed then A.status.waiting=why; return end
    local item=A.adapter.parry
    if not item or item.character~=ch or not item.tool:IsDescendantOf(ch) then
        A.status.waiting="Equip an item that uses ParryClient"; return
    end
    if not item:CanUse() then A.status.waiting="Native parry cooldown or item state"; return end
    local threat
    for _,p in Players:GetPlayers() do
        local other=p.Character
        local h=other and other:FindFirstChildOfClass("Humanoid")
        local r=other and other:FindFirstChild("HumanoidRootPart")
        if p.Team and p.Team.Name=="Killer" and h and h.Health>0 and r then
            local offset=root.Position-r.Position
            if offset.Magnitude>0.1 and (C.parryRange<=0 or offset.Magnitude<=C.parryRange) and r.CFrame.LookVector:Dot(offset.Unit)>0.15 then
                local animator=h:FindFirstChildOfClass("Animator")
                if animator then for _,track in animator:GetPlayingAnimationTracks() do
                    local anim=track.Animation
                    -- Most attack assets are created at runtime with the generic name Animation.
                    -- Action priority + facing + distance is a heuristic, not proof of a hit window.
                    if anim and track.Priority.Value>=Enum.AnimationPriority.Action.Value
                        and track.WeightCurrent>0.05 and track.TimePosition<0.35 then threat=p; break end
                end end
            end
        end
        if threat then break end
    end
    if not threat then A.status.waiting="Waiting for a nearby Action animation to start"; return end
    local sent,reason=pressBinding("item")
    if not sent then A.status.waiting=reason; return end
    A.parryPendingUntil=os.clock()+0.8; A.metrics.parryRequests=A.metrics.parryRequests+1
    A.status.action="Parry"; A.status.target=threat.Name
end

-- ESP_CONTROLLER_BEGIN
local ESP={options={names=true,roles=true,health=true,distance=true,status=true,healthBar=true,
    highlight=true,fill=true,outline=true,labels=true,throughWalls=true,survivors=true,killers=true,
    generatorProgress=true,generatorRepairers=true,completedGenerators=false,
    maxDistance=0,textSize=13,fillTransparency=.8,outlineTransparency=0,labelHeight=3,
    survivorColor=Color3.fromRGB(80,225,175),killerColor=Color3.fromRGB(255,83,92),generatorColor=Color3.fromRGB(255,208,82)}}
A.espOptions=ESP.options
function ESP:InRange(distance) return self.options.maxDistance<=0 or distance<=self.options.maxDistance end
function ESP:PlayerText(player,role,humanoid,distance,ch)
    local o=self.options; local fields={}
    if o.names then table.insert(fields,player.DisplayName) end
    if o.roles then table.insert(fields,role) end
    if o.health then table.insert(fields,string.format("%.0f / %.0f HP",humanoid.Health,humanoid.MaxHealth)) end
    if o.distance then table.insert(fields,string.format("%.0f studs",distance)) end
    if o.status then
        local state=ch:GetAttribute("IsHooked") and "HOOKED" or ch:GetAttribute("IsCarried") and "CARRIED"
            or ch:GetAttribute("Knocked") and "DOWN" or ch:GetAttribute("IsBeingHealed") and "HEALING"
            or ch:GetAttribute("IsChased") and "CHASED" or ch:GetAttribute("IsStunned") and "STUNNED"
        if state then table.insert(fields,state) end
    end
    return table.concat(fields," | ")
end
local function clearESP()
    for _,e in A.entries do e.highlight:Destroy(); e.gui:Destroy() end
    A.entries={}
end
local function espEntry(obj,part,color,text,healthRatio)
    local e=A.entries[obj]
    if not e then
        local h=Instance.new("Highlight"); h.Name="SmugVD_Highlight"; h.Adornee=obj
        h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; h.FillTransparency=0.8; h.Parent=A.overlay
        local b=Instance.new("BillboardGui"); b.Name="SmugVD_Label"; b.Adornee=part
        b.AlwaysOnTop=true; b.Size=UDim2.fromOffset(420,54); b.StudsOffset=Vector3.new(0,3,0); b.Parent=A.overlay
        local label=Instance.new("TextLabel"); label.Size=UDim2.new(1,0,1,-12); label.BackgroundTransparency=1
        label.TextStrokeTransparency=0.2; label.Font=Enum.Font.GothamSemibold; label.TextSize=13; label.Parent=b
        local bar=Instance.new("Frame"); bar.Name="HealthBar"; bar.Size=UDim2.fromOffset(90,4)
        bar.Position=UDim2.new(.5,-45,1,-9); bar.BorderSizePixel=0; bar.BackgroundColor3=Color3.fromRGB(25,25,30); bar.Parent=b
        local fill=Instance.new("Frame"); fill.BorderSizePixel=0; fill.Size=UDim2.fromScale(1,1); fill.Parent=bar
        e={highlight=h,gui=b,label=label,bar=bar,barFill=fill}; A.entries[obj]=e
    end
    local o=ESP.options
    e.highlight.FillColor=color; e.highlight.OutlineColor=color; e.label.TextColor3=color
    e.highlight.Enabled=o.highlight and (o.fill or o.outline)
    e.highlight.FillTransparency=o.fill and o.fillTransparency or 1
    e.highlight.OutlineTransparency=o.outline and o.outlineTransparency or 1
    e.highlight.DepthMode=o.throughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    e.gui.AlwaysOnTop=o.throughWalls; e.gui.StudsOffset=Vector3.new(0,o.labelHeight,0)
    e.label.Text=text; e.label.TextSize=o.textSize; e.label.Visible=o.labels
    e.bar.Visible=o.healthBar and healthRatio~=nil
    if healthRatio then
        local ratio=math.clamp(healthRatio,0,1)
        e.barFill.Size=UDim2.fromScale(ratio,1); e.barFill.BackgroundColor3=Color3.fromRGB(255,83,92):Lerp(Color3.fromRGB(80,225,175),ratio)
    end
    e.gui.Adornee=part; e.seen=true
end
local function espStep()
    for _,e in A.entries do e.seen=false end
    local ch=LocalPlayer.Character
    local root=ch and ch:FindFirstChild("HumanoidRootPart")
    local camera=workspace.CurrentCamera
    local origin=root and root.Position or camera and camera.CFrame.Position
    if origin then
        local bonuses=PerkBoosts and PerkBoosts:Targets() or {}
        if C.esp or bonuses.players then for _,p in Players:GetPlayers() do
            local ch=p.Character; local h=ch and ch:FindFirstChildOfClass("Humanoid")
            local r=ch and ch:FindFirstChild("HumanoidRootPart")
            local role=playerRole(p)
            if p~=LocalPlayer and role~="Spectator" and not p:GetAttribute("IsDead") and h and h.Health>0 and r then
                local d=(r.Position-origin).Magnitude
                local shown=C.esp and ESP:InRange(d) and (role=="Killer" and ESP.options.killers or role=="Survivor" and ESP.options.survivors)
                if shown or PerkBoosts:CanReveal(p,d,bonuses) then
                    local killer=role=="Killer"
                    local color=killer and ESP.options.killerColor or ESP.options.survivorColor
                    espEntry(ch,r,color,ESP:PlayerText(p,role,h,d,ch),h.Health/math.max(h.MaxHealth,1))
                end
            end
        end end
        if C.objectESP or bonuses.generators or next(bonuses.generatorSet or {}) then for _,g in A.generators do
            if g.Parent then
                local part=g.PrimaryPart or g:FindFirstChildWhichIsA("BasePart",true)
                local d=part and (part.Position-origin).Magnitude or math.huge
                local completed=g:GetAttribute("Completed")==true or (g:GetAttribute("RepairProgress") or 0)>=100
                if part and ((C.objectESP and ESP:InRange(d) and (not completed or ESP.options.completedGenerators)) or bonuses.generators or bonuses.generatorSet[g]) then
                    local progress=g:GetAttribute("RepairProgress")
                    local fields={"Generator"}
                    if ESP.options.generatorProgress and type(progress)=="number" then table.insert(fields,string.format("%.1f %%",progress)) end
                    if ESP.options.generatorRepairers then table.insert(fields,string.format("%d repairing",g:GetAttribute("PlayersRepairingCount") or 0)) end
                    if ESP.options.distance then table.insert(fields,string.format("%.0f studs",d)) end
                    if ESP.options.status then
                        if completed then table.insert(fields,"DONE") elseif g:GetAttribute("Regressing") then table.insert(fields,"REGRESSING") end
                    end
                    espEntry(g,part,ESP.options.generatorColor,table.concat(fields," | "))
                end
            end
        end end
        if bonuses.obstacles then
            for _,tag in {"window","pallet"} do
                for _,obj in Tags:GetTagged(tag) do
                    local part=obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart",true)
                    if part and (part.Position-origin).Magnitude<=bonuses.obstacleRange then espEntry(obj,part,Color3.fromRGB(150,175,255),tag) end
                end
            end
        end
    end
    for obj,e in A.entries do if not e.seen then e.highlight:Destroy(); e.gui:Destroy(); A.entries[obj]=nil end end
end
A.espController=ESP
-- ESP_CONTROLLER_END

local function reduce(obj)
    if obj:IsA("BasePart") then own("graphics",obj,"CastShadow",false)
    elseif obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then own("graphics",obj,"Enabled",false)
    elseif obj:IsA("PostEffect") then own("graphics",obj,"Enabled",false) end
end
local function graphics(enabled)
    A.graphicsGeneration=(A.graphicsGeneration or 0)+1
    local token=A.graphicsGeneration
    if not enabled then restore("graphics"); return end
    own("graphics",Lighting,"GlobalShadows",false)
    task.spawn(function()
        A:RunFeature("graphics",{"lowGraphics"},function()
        for _,container in {workspace,Lighting} do
            for i,obj in container:GetDescendants() do
                if not A.alive or not C.lowGraphics or token~=A.graphicsGeneration then return end
                reduce(obj)
                if i%250==0 then task.wait() end
            end
        end
        end,function() A.graphicsGeneration=A.graphicsGeneration+1; restore("graphics") end)
    end)
end

local function holdKey(name,down)
    if A.heldKeys[name]==down or (not down and not A.heldKeys[name]) then return end
    if not VIM then error("VirtualInputManager is unavailable") end
    local key=Enum.KeyCode[name]
    VIM:SendKeyEvent(down,key,false,game)
    A.heldKeys[name]=down or nil
end
local function releaseWalking()
    for _,key in {"W","A","S","D"} do
        local good,problem=pcall(holdKey,key,false)
        if not good then A.status.waiting="Could not release a navigation key: "..tostring(problem); A.heldKeys[key]=nil end
    end
end
function A:CancelMove(reason,success)
    self.moveSerial=(self.moveSerial or 0)+1
    local move=self.move; self.move=nil
    releaseWalking()
    if move then
        self.moveResult={owner=move.owner,success=success==true,reason=reason or "Navigation cancelled"}
        if move.owner~="pumpkin" then self.manualPauseUntil=os.clock()+2 end
    end
    if reason then self.status.waiting=reason end
end
function A:Travel(position,owner)
    if owner~="pumpkin" then self:ClearFailure("navigation") end
    self:CancelMove(); stopRepair()
    if Motion and Motion:ShouldYield() then self.status.waiting="Movement stabilization: "..Motion.reason; return false end
    local state,ch,h,root=Adapter.State()
    local allowed,why=Rules.canWalk(state)
    if not allowed then self.status.waiting=why; return false end
    if root.Anchored then self.status.waiting="Native movement is anchored"; return false end
    local move={character=ch,root=root,owner=owner or "manual",position=position,phase="planning",serial=self.moveSerial,
        deadline=os.clock()+math.max((position-root.Position).Magnitude/math.max(h.WalkSpeed,1)*3+12,20),
        lastPosition=root.Position,lastProgress=os.clock()}
    self.move=move; self.moveResult=nil; self.status.action="Walking: "..move.owner
    local generation=self.generation
    task.spawn(function()
        local good,result=pcall(function()
            local path=PathfindingService:CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=false,AgentCanClimb=false})
            path:ComputeAsync(root.Position,position)
            if path.Status~=Enum.PathStatus.Success then return nil end
            return path:GetWaypoints()
        end)
        if not self.alive or self.generation~=generation or self.move~=move or self.moveSerial~=move.serial then return end
        if not good or not result or #result==0 then self:CancelMove("No walkable path was found"); return end
        move.waypoints=result; move.index=math.min(2,#result); move.phase="walking"; move.lastProgress=os.clock()
    end)
    return true
end
local function travelStep()
    local move=A.move
    if not move then return end
    if Motion and Motion:ShouldYield() then A:CancelMove("Movement stabilization: "..Motion.reason); return end
    local state,ch,_,root=Adapter.State()
    local allowed,why=Rules.canWalk(state)
    if not allowed or ch~=move.character or root.Anchored then A:CancelMove(why or "Native movement is locked"); return end
    if UIS:GetFocusedTextBox() then A:CancelMove("Text entry interrupted navigation"); return end
    if os.clock()>move.deadline then A:CancelMove("Navigation timed out"); return end
    if (root.Position-move.position).Magnitude<=3.25 then A:CancelMove("Walk destination reached",true); return end
    if move.phase~="walking" then return end
    if (root.Position-move.lastPosition).Magnitude>=0.4 then move.lastPosition=root.Position; move.lastProgress=os.clock() end
    if os.clock()-move.lastProgress>4 then A:CancelMove("Walking is blocked; navigation stopped"); return end
    local waypoint=move.waypoints[move.index]
    local offset=waypoint.Position-root.Position
    if Vector3.new(offset.X,0,offset.Z).Magnitude<1.5 and move.index<#move.waypoints then
        move.index=move.index+1; waypoint=move.waypoints[move.index]; offset=waypoint.Position-root.Position
    end
    if waypoint.Action==Enum.PathWaypointAction.Jump then A:CancelMove("Path requires a jump that this controller does not automate"); return end
    local direction=Vector3.new(offset.X,0,offset.Z)
    local camera=workspace.CurrentCamera
    if not camera or direction.Magnitude<0.01 then releaseWalking(); return end
    local forward=Vector3.new(camera.CFrame.LookVector.X,0,camera.CFrame.LookVector.Z)
    local right=Vector3.new(camera.CFrame.RightVector.X,0,camera.CFrame.RightVector.Z)
    if forward.Magnitude<0.01 or right.Magnitude<0.01 then releaseWalking(); return end
    local f=direction.Unit:Dot(forward.Unit); local r=direction.Unit:Dot(right.Unit)
    holdKey("W",f>0.3); holdKey("S",f< -0.3); holdKey("D",r>0.3); holdKey("A",r< -0.3)
end

local function stopRecovery()
    local recovery=A.recovery; A.recovery=nil
    if recovery then
        local good,problem=pcall(interactionInput,false,"recovery")
        if not good then A.status.waiting="Recovery stop failed: "..tostring(problem) end
    end
end
local function recoveryStep()
    if not C.selfRecover then stopRecovery(); return end
    if A.bindHeal or C.selfHeal then return end
    local state,ch,h,root,ctx=Adapter.State()
    local recovery=A.recovery
    if recovery then
        local allowed,why=Rules.canAct(state,true)
        if allowed and ch==recovery.character and ctx and not ctx.script:GetAttribute("isHealing") and os.clock()-recovery.sentAt<0.8 then return end
        if not allowed or ch~=recovery.character or h.Health>50 or not ctx or ctx.state.currentHealPoint~=root
            or not ctx.script:GetAttribute("isHealing") then
            stopRecovery(); A.status.waiting=why or "Native recovery ended"; A.recoveryRetry=os.clock()+2; return
        end
        local progress=ch:GetAttribute("HealProgress")
        if h.Health>recovery.health or (type(progress)=="number" and progress>recovery.progress) then
            A.status.result=string.format("Observed recovery: HP %.1f, progress %s",h.Health,tostring(progress))
            recovery.health=h.Health; recovery.progress=type(progress)=="number" and progress or recovery.progress
            recovery.lastProgress=os.clock()
        end
        A.status.action="Native self-recovery"; A.status.target=LocalPlayer.Name
        if os.clock()-recovery.lastProgress>10 then
            A:Set("selfRecover",false); A.status.waiting="No recovery progress for 10 seconds; the native cap or a rejection may apply"
        end
        return
    end
    if os.clock()<(A.recoveryRetry or 0) then return end
    local allowed,why=Rules.canRecover(state)
    if not allowed or not ctx or not ctx.proximity then A.status.waiting=why or "Native recovery controller unavailable"; return end
    A:CancelMove(); stopRepair()
    state=Adapter.State()
    if not Rules.canRecover(state) then return end
    A.recovery={ctx=ctx,root=root,character=ch,sentAt=os.clock(),health=h.Health,progress=ch:GetAttribute("HealProgress") or 0,lastProgress=os.clock()}
    local started,reason=interactionInput(true,"recovery")
    if not started then A.recovery=nil; A.status.waiting=reason; return end
    A.metrics.recoveryStarts=A.metrics.recoveryStarts+1
end

local function pumpkinStep()
    if not C.pumpkinFarm then return end
    local allowed,why,ch,_,root=Adapter.CanAct()
    if not allowed or A.recovery or A.bindHeal then
        if A.move and A.move.owner=="pumpkin" then A:CancelMove() end
        A.status.waiting=why or "Self-recovery has priority"; return
    end
    if A.move and A.move.owner~="pumpkin" then A.status.waiting="Manual navigation has priority"; return end
    if os.clock()<(A.manualPauseUntil or 0) then return end
    if A.repair then return end -- Finish an owned repair before acquiring movement.
    local attempt=A.pumpkinAttempt
    if attempt then
        -- The native stomp can destroy its target. Read the live tag list instead of
        -- dereferencing an executor handle after the engine has disposed that instance.
        local removed=table.find(Tags:GetTagged("pumpkin"),attempt.point)==nil
        local candy=LocalPlayer:GetAttribute("Candy")
        if removed and not attempt.removedAt then attempt.removedAt=os.clock() end
        if removed and type(candy)=="number" and type(attempt.candy)=="number" and candy>attempt.candy then
            A.metrics.pumpkinsConfirmed=A.metrics.pumpkinsConfirmed+1
            A.status.result=string.format("Pumpkin removed and Candy increased by %d",candy-attempt.candy)
            A.pumpkinAttempt=nil; A.pumpkinTarget=nil; A.pumpkinNext=math.max(A.pumpkinNext or 0,os.clock()+0.3)
        elseif (attempt.removedAt and os.clock()-attempt.removedAt>2) or os.clock()-attempt.started>5 then
            A.status.result=removed and "Pumpkin disappeared; own reward was not confirmed" or "Pumpkin action was not confirmed; target paused"
            A.blacklist[attempt.point]=os.clock()+30; A.pumpkinAttempt=nil; A.pumpkinTarget=nil; A.pumpkinNext=os.clock()+1
        end
        return
    end
    if os.clock()<(A.pumpkinNext or 0) then return end
    local target=A.pumpkinTarget
    if target and table.find(Tags:GetTagged("pumpkin"),target)==nil then A.pumpkinTarget=nil; target=nil end
    if not target then
        local bestDistance=math.huge
        for _,p in A.pumpkins do
            if p.Parent and Tags:HasTag(p,"pumpkin") and (A.blacklist[p] or 0)<=os.clock() and not Tags:HasTag(p.Parent,"Blocked") then
                local distance=(p.Position-root.Position).Magnitude
                if distance<bestDistance then target=p; bestDistance=distance end
            end
        end
        if not target then A.status.waiting="No loaded, available pumpkin"; return end
        A.pumpkinTarget=target; A.pumpkinWaitStarted=nil
    end
    if A.move then return end
    if A.moveResult and A.moveResult.owner=="pumpkin" and not A.moveResult.success then
        A.blacklist[target]=os.clock()+30; A.pumpkinTarget=nil; A.moveResult=nil; return
    end
    local distance=(target.Position-root.Position).Magnitude
    if distance>4 then A:Travel(target.Position,"pumpkin"); return end
    A.pumpkinWaitStarted=A.pumpkinWaitStarted or os.clock()
    local state,_,_,_,ctx=Adapter.State()
    state.tagged=Tags:HasTag(target,"pumpkin"); state.distance=distance
    state.nativeTarget=ctx and ctx.proximity and ctx.proximity.state.pumpkin==target
    if ctx and ctx.proximity then
        local prompts=ctx.proximity.state
        if prompts.generatorPoint or prompts.healTarget or prompts.exitPoint or prompts.unhookPoint or prompts.gift or state.aiming then
            state.nativeTarget=false
        end
    end
    local eligible,reason=Rules.canHarvest(state)
    if not eligible then
        A.status.waiting=reason
        if os.clock()-(A.pumpkinWaitStarted or 0)>8 then A.blacklist[target]=os.clock()+20; A.pumpkinTarget=nil end
        return
    end
    if ctx.proximity.state.pumpkin~=target or not Tags:HasTag(target,"pumpkin") or (target.Position-root.Position).Magnitude>4 then return end
    releaseWalking()
    local sent,inputWhy=pressBinding("interact")
    if not sent then A.status.waiting=inputWhy; return end
    A.pumpkinAttempt={point=target,candy=LocalPlayer:GetAttribute("Candy"),started=os.clock()}
    A.metrics.pumpkinAttempts=A.metrics.pumpkinAttempts+1
    A.pumpkinNext=os.clock()+1.6 -- Native animation is 1.3 seconds; no overlapping submissions.
    A.status.action="Native pumpkin interaction"; A.status.target=target.Name
end

local function perkDefinitions(role)
    local definitions={}
    if role=="Survivor" then
        for _,definition in RS.Perks:GetChildren() do if definition:IsA("Folder") then definitions[definition.Name]=definition end end
    else
        for _,killer in RS.Killers:GetChildren() do
            local folder=killer:FindFirstChild("Perks")
            if folder then for _,definition in folder:GetChildren() do if definition:IsA("Folder") then definitions[definition.Name]=definition end end end
        end
    end
    return definitions
end
local function readEquipment(role,name)
    if LocalPlayer:GetAttribute("PerksDataLoaded")~=true then error("Wait for the game's perk data to load") end
    local killer=LocalPlayer:GetAttribute("SelectedKiller")
    local definitions=perkDefinitions(role)
    local definition=definitions[name]
    local owned,equipped,info,shop
    if role=="Survivor" then
        shop=RS.Remotes.Shop
        owned=shop.GetOwnedPerks:InvokeServer()
        equipped=shop.GetEquippedPerks:InvokeServer()
        if definition then info=shop.GetPerkInfo:InvokeServer(name) end
    else
        shop=RS.Remotes.ShopKillers
        if type(killer)~="string" or killer=="" then error("No selected killer is available") end
        owned=shop.GetUnlockedPerks:InvokeServer()
        equipped=shop.GetEquippedKillerPerks:InvokeServer(killer)
        local entry=type(owned)=="table" and owned[name]
        local level=type(entry)=="table" and entry.level or entry
        local price=definition and definition:GetAttribute("cost")
        info={owned=type(level)=="number" and level>=1,level=level or 0,price=price,
            message=type(price)=="number" and ("Costs "..price.." Gears") or "Unlock this perk through the game's killer progression"}
    end
    if type(owned)~="table" or type(equipped)~="table" then error("The server did not return an equipment table") end
    return {role=role,killer=killer,name=name,owned=owned,equipped=equipped,info=info,definition=definition,shop=shop}
end
local function ownedPerk(snapshot,name)
    local entry=snapshot.owned[name]
    if snapshot.role=="Survivor" then return type(entry)=="table" and (tonumber(entry.level) or 0)>=1 end
    return (type(entry)=="table" and (tonumber(entry.level) or 0) or tonumber(entry) or 0)>=1
end
local function renderEquipment(snapshot)
    if A.purchaseUncertain and A.purchaseUncertain.role==snapshot.role and A.purchaseUncertain.name==snapshot.name
        and ownedPerk(snapshot,snapshot.name) then A.purchaseUncertain=nil end
    local names={}
    for name,entry in snapshot.owned do
        local level=type(entry)=="table" and entry.level or entry
        if type(name)=="string" and (tonumber(level) or 0)>=1 then table.insert(names,name.." (level "..tostring(level)..")") end
    end
    table.sort(names)
    A.ownedLabel:SetText(#names>0 and table.concat(names,"\n") or "The server returned no owned perks for this category")
    local lines={"Category: "..snapshot.role..(snapshot.role=="Killer" and " / "..snapshot.killer or "")}
    for slot=1,3 do
        local entry=snapshot.equipped[snapshot.role=="Survivor" and slot or "perk"..slot]
        table.insert(lines,"Slot "..slot..": "..tostring(type(entry)=="table" and entry.name or "empty"))
    end
    A.equippedLabel:SetText(table.concat(lines,"\n"))
    local info=snapshot.info
    if type(info)=="table" then
        local description=snapshot.definition and snapshot.definition:GetAttribute("desc") or ""
        description=tostring(description):gsub("<br%s*/?>","\n"):gsub("<.->","")
        A.perkInfoLabel:SetText(snapshot.name.."\n"..tostring(info.message or "No server message").."\n"..description)
        A.perkQuote={role=snapshot.role,killer=snapshot.killer,name=snapshot.name,price=info.price,message=info.message,time=os.clock()}
    end
end
local function equipmentCurrent(generation,role,name,killer)
    return A.alive and A.generation==generation and C.equipmentRole==role and C.selectedPerk==name
        and (role~="Killer" or LocalPlayer:GetAttribute("SelectedKiller")==killer)
end
function A:EquipmentOperation(operation)
    if self.equipmentBusy then notify("The previous equipment request is still pending"); return end
    if operation~="inspect" and (not LocalPlayer.Team or LocalPlayer.Team.Name~="Spectator") then
        notify("This tool changes equipment and purchases perks only from the lobby"); return
    end
    local role,name,slot=C.equipmentRole,C.selectedPerk,C.perkSlot
    if not perkDefinitions(role)[name] then notify("Select a perk from the discovered catalog"); return end
    local quoted=self.perkQuote
    if operation=="buy" and (not quoted or quoted.name~=name or quoted.role~=role
        or (role=="Killer" and quoted.killer~=LocalPlayer:GetAttribute("SelectedKiller")) or os.clock()-quoted.time>30) then
        notify("Inspect the selected perk and its price before purchasing"); return
    end
    self.equipmentBusy=true
    local generation=self.generation
    local killer=LocalPlayer:GetAttribute("SelectedKiller")
    task.spawn(function()
        local good,problem=pcall(function()
            local snapshot=readEquipment(role,name)
            if not equipmentCurrent(generation,role,name,killer) then return end
            if operation=="equip" and C.perkSlot~=slot then return end
            renderEquipment(snapshot)
            if operation=="inspect" then return end
            if not LocalPlayer.Team or LocalPlayer.Team.Name~="Spectator" then error("The lobby state changed; no action was sent") end
            if operation=="equip" then
                local allowed,why=Rules.canEquip(ownedPerk(snapshot,name),slot,snapshot.equipped,name)
                if not allowed then error(why) end
            elseif operation=="buy" then
                if self.purchaseUncertain then error("A previous purchase is unresolved; wait for its server response or ownership confirmation") end
                local info=snapshot.info
                if type(info)~="table" or info.owned or ownedPerk(snapshot,name) then error("This perk is already owned or its ownership is unavailable") end
                if type(info.price)~="number" or info.price~=info.price or info.price<0 or info.price==math.huge then error("No supported purchase price is available") end
                if quoted.price~=info.price or quoted.message~=info.message then error("The purchase quote changed; inspect it again") end
                local currency=tostring(info.message):match("^Costs [%d%.]+ (%a+)")
                if currency~="Screws" and currency~="Gears" then error("The required currency or progression gate is unknown; use the native shop") end
                if (LocalPlayer:GetAttribute(currency) or 0)<info.price then error("Not enough "..currency) end
            else error("Unknown equipment action") end
            if not equipmentCurrent(generation,role,name,killer) then return end
            if operation=="equip" and C.perkSlot~=slot then return end
            self.metrics.equipmentWrites=self.metrics.equipmentWrites+1
            if operation=="equip" then
                if role=="Survivor" then snapshot.shop.EquipPerk:FireServer(name,slot)
                else snapshot.shop.EquipPerk:FireServer(killer,name,"perk"..slot) end
            else
                self.purchaseUncertain={role=role,name=name,killer=killer}
                if role=="Survivor" then snapshot.shop.PurchasePerk:FireServer(name)
                else snapshot.shop.PurchaseKillerPerk:FireServer(killer,name) end
            end
            for _=1,4 do
                task.wait(1)
                if not equipmentCurrent(generation,role,name,killer) then return end
                if operation=="equip" and C.perkSlot~=slot then return end
                local after=readEquipment(role,name)
                if not equipmentCurrent(generation,role,name,killer) then return end
                renderEquipment(after)
                local entry=after.equipped[role=="Survivor" and slot or "perk"..slot]
                local confirmed=operation=="buy" and ownedPerk(after,name) or operation=="equip" and type(entry)=="table" and entry.name==name
                if confirmed then
                    if operation=="buy" then self.purchaseUncertain=nil end
                    self.status.result="Server inventory confirmed "..operation..": "..name
                    notify(self.status.result); return
                end
                if operation=="buy" and not self.purchaseUncertain then return end
            end
            notify("The server result was not confirmed. The action will not be retried automatically.")
        end)
        self.equipmentBusy=false
        if not good and self.alive and generation==self.generation then notify(problem) end
    end)
end
function A:ReadOwnedPerks() self:EquipmentOperation("inspect") end
function A:EquipAvailablePerks()
    if self.equipmentBusy then notify("The previous equipment request is still pending"); return end
    if not LocalPlayer.Team or LocalPlayer.Team.Name~="Spectator" then notify("Equip perks from the lobby"); return end
    local role,killer=C.equipmentRole,LocalPlayer:GetAttribute("SelectedKiller")
    local generation=self.generation; self.equipmentBusy=true
    task.spawn(function()
        local good,problem=pcall(function()
            local snapshot=readEquipment(role,C.selectedPerk)
            local names={}
            for name in snapshot.owned do if ownedPerk(snapshot,name) then table.insert(names,name) end end
            table.sort(names)
            if #names==0 then error("The server returned no owned perks; no equip request was sent") end
            local filled=0
            for slot=1,3 do
                if not self.alive or generation~=self.generation or C.equipmentRole~=role
                    or (role=="Killer" and LocalPlayer:GetAttribute("SelectedKiller")~=killer) then return end
                if not LocalPlayer.Team or LocalPlayer.Team.Name~="Spectator" then return end
                snapshot=readEquipment(role,C.selectedPerk)
                if not self.alive or generation~=self.generation or C.equipmentRole~=role
                    or (role=="Killer" and LocalPlayer:GetAttribute("SelectedKiller")~=killer) then return end
                local slotKey=role=="Survivor" and slot or "perk"..slot
                local entry=snapshot.equipped[slotKey]
                if not (type(entry)=="table" and entry.name and entry.name~="") then
                    local candidate
                    for _,name in names do
                        if Rules.canEquip(ownedPerk(snapshot,name),slot,snapshot.equipped,name) then candidate=name; break end
                    end
                    if candidate then
                        if not LocalPlayer.Team or LocalPlayer.Team.Name~="Spectator" then return end
                        self.metrics.equipmentWrites=self.metrics.equipmentWrites+1
                        if role=="Survivor" then snapshot.shop.EquipPerk:FireServer(candidate,slot)
                        else snapshot.shop.EquipPerk:FireServer(killer,candidate,slotKey) end
                        task.wait(1)
                        if not self.alive or generation~=self.generation then return end
                        local after=readEquipment(role,C.selectedPerk)
                        if not self.alive or generation~=self.generation or C.equipmentRole~=role
                            or (role=="Killer" and LocalPlayer:GetAttribute("SelectedKiller")~=killer) then return end
                        local equipped=after.equipped[slotKey]
                        if not (type(equipped)=="table" and equipped.name==candidate) then
                            error("The server did not confirm slot "..slot.."; bulk equip stopped")
                        end
                        filled=filled+1
                    end
                end
            end
            if self.alive and generation==self.generation then notify("Server confirmed "..filled.." newly filled perk slots; the inspected layout has three slots") end
        end)
        self.equipmentBusy=false
        if not good and self.alive and generation==self.generation then notify(problem) end
    end)
end
function A:EquipOwnedItem()
    if self.equipmentBusy then notify("The previous equipment request is still pending"); return end
    if not LocalPlayer.Team or LocalPlayer.Team.Name~="Spectator" then notify("Equip items from the lobby"); return end
    if LocalPlayer:GetAttribute("ItemsDataLoaded")~=true then notify("Wait for item data to load"); return end
    local name=C.selectedItem
    local definition=RS.Items:FindFirstChild(name)
    if not definition or not definition:IsA("Decal") then notify("Select an item from the native catalog"); return end
    local generation=self.generation; self.equipmentBusy=true
    task.spawn(function()
        local good,problem=pcall(function()
            local owned=RS.Remotes.Shop.GetOwnedItems:InvokeServer()
            if not self.alive or generation~=self.generation or C.selectedItem~=name then return end
            if type(owned)~="table" or not owned[name] then error("This item is not owned; unlock it in the native shop first") end
            if not LocalPlayer.Team or LocalPlayer.Team.Name~="Spectator" then return end
            self.metrics.equipmentWrites=self.metrics.equipmentWrites+1
            RS.Remotes.Shop.EquipItem:FireServer(name)
            task.wait(0.5)
            if not self.alive or generation~=self.generation then return end
            local equipped=RS.Remotes.Shop.GetEquippedItems:InvokeServer()
            if not self.alive or generation~=self.generation then return end
            local entry=type(equipped)=="table" and equipped[1]
            notify(type(entry)=="table" and entry.name==name and "Server confirmed the equipped item: "..name or "Item equip was not confirmed; no automatic retry")
        end)
        self.equipmentBusy=false
        if not good and self.alive and generation==self.generation then notify(problem) end
    end)
end
local function visibleNativeButton(button)
    if not button:IsA("GuiButton") or not button.Active then return false end
    local parent=button
    while parent and parent~=LocalPlayer.PlayerGui do
        if parent:IsA("GuiObject") and not parent.Visible then return false end
        if parent:IsA("ScreenGui") and not parent.Enabled then return false end
        parent=parent.Parent
    end
    return parent==LocalPlayer.PlayerGui and button.AbsoluteSize.X>0 and button.AbsoluteSize.Y>0
end
function A:OpenNativeMenu(title)
    local matches={}
    for _,button in LocalPlayer.PlayerGui:GetDescendants() do
        if visibleNativeButton(button) then
            local text=button:IsA("TextButton") and button.Text or button.Name
            if text:lower()==title:lower() or button.Name:lower()==title:lower() then table.insert(matches,button) end
        end
    end
    if #matches~=1 or not VIM then notify("Open the game's "..title.." menu directly; no unique visible button was found"); return end
    local b=matches[1]; local point=b.AbsolutePosition+b.AbsoluteSize/2
    local screen=b:FindFirstAncestorOfClass("ScreenGui")
    if screen and not screen.IgnoreGuiInset then point=point+game:GetService("GuiService"):GetGuiInset() end
    VIM:SendMouseButtonEvent(point.X,point.Y,0,true,game,0); VIM:SendMouseButtonEvent(point.X,point.Y,0,false,game,0)
    notify("Native menu input sent. Ownership and slot restrictions remain in control of the game.")
end

-- PERK_BOOSTS_BEGIN
PerkBoosts={catalog={},byKey={},windows={},cooldowns={},tokens={},context={},vaultSerial=0}
local survivorEffects={
 ["Time To Grow Up"]={speed=.05,event="hit",duration=4},
 ["Great Collapse"]={speed=.5,event="stun",duration=3,winded=30},
 ["We're Stronger Together"]={speed=.06,when="nearSurvivor"},
 ["Left Behind"]={speed=.07,when="gates"},
 ["Snake Step"]={crouch=1,when="crouch"},
 ["Heads Up"]={speed=.2,players="Killer",event="killerApproach",duration=3,winded=40},
 ["Perfect Landing"]={speed=.4,event="landing",duration=3,winded=50},
 ["Born in Blood"]={speed=.3,event="healOther",duration=6},
 ["On Screen Fear"]={speed=.03,when="terror"},
 ["Quick Recovery"]={speed=.35,event="quickVault",duration=3,winded=60},
 ["Bounce Back"]={speed=.07,players="All",generators=true,event="unhooked",duration=30},
 ["Evasive Manoeuvre"]={speed=.15,vault=.15,when="evasive",duration=6,winded=40},
 ["No Way Back"]={speed=.07,players="Killer",event="windowBlocked",duration=4,cooldown=60,radiusTrigger=60},
 ["Break Free"]={speed=.1,players="All",event="chaseEscaped",duration=6,winded=30},
 ["Hyperactive"]={walk=.2,when="walk"},
 ["Flowstate"]={vault=.2,when="flow",cooldown=50},
 ["Nobody Left Behind"]={players="Survivor",when="gates"},
 ["On My Own"]={players="Killer",event="lastAlive",duration=10},
 ["Call Me Back"]={players="Survivor",event="healedTargetHit",duration=40,targetOnly=true},
 ["Last Stand"]={players="Killer",event="gates",duration=20},
 ["Against All Odds"]={players="Killer",when="dyingHeal"},
 ["Absolute confidence"]={players="Survivor",radius=180,when="chase"},
 ["Hearing Aid"]={players="Killer",event="loudKillerAction",duration=6,radiusTrigger=240},
 ["Eyes of Heaven"]={obstacles=true,radius=130,when="passive"},
 ["Familiar Soul"]={players="Survivor",radius=120,when="passive"},
 ["Perfectionist Planning"]={cluster=true,when="passive"},
 ["Debut Showcase"]={players="Killer",event="stunOrParry",duration=5},
 ["Visual Learner"]={players="Killer",when="visual",duration=5,cooldown=25},
 ["Abrasive"]={players="Killer",event="hit",duration=10},
 ["Carpenter"]={players="Killer",event="palletDropped",duration=2,cooldown=20},
}
local killerEffects={
 ["Predator"]={speed=.05,players="Survivor",targetOnly=true,event="survivorEscaped",duration=6,cooldown=30},
 ["Play With Your Food"]={speed=.03,when="tokens"},
 ["Excitement"]={speed=.15,when="carrying",duration=10},
 ["Offscreen Scare"]={speed=.12,when="offscreen"},
 ["Combo Streak"]={speed=.05,event="confirmedBasicHit",duration=13,stacked=true},
 ["Stage Fright"]={speed=.07,when="auraRevealed"},
 ["Surge of Power"]={speed=.06,when="generatorRange"},
 ["Dread Harvest"]={speed=.03,when="hookedRepairers"},
 ["Murderous Acrobatics"]={speed=.07,vault=.2,when="acrobatics",duration=4,cooldown=45},
 ["Touch Of Death"]={vault=.2,obstacles=true,when="markedWindow",duration=60},
 ["Eyes Of Hell"]={obstacles=true,radius=100,when="passive"},
 ["Echo Location"]={players="Survivor",radius=100,event="kick",duration=5},
 ["Enhanced Senses"]={auraExtension=2,when="passive"},
 ["Next in Line"]={players="Survivor",minRadius=120,event="hookOther",duration=8},
 ["Echo Of The Void"]={players="Survivor",targetOnly=true,event="spotted",duration=4,cooldown=30},
 ["Sustenance"]={players="Survivor",event="sustenance",duration=4},
 ["Desire For The Living"]={players="Survivor",targetOnly=true,event="auraReader",duration=4},
 ["Exposure Therapy"]={players="Survivor",event="exposure",duration=4,cooldown=30},
 ["Cold Blooded"]={players="Survivor",radius=60,event="survivorDowned",duration=4,cooldown=60},
 ["Visceral Drive"]={players="Survivor",radius=120,event="visceralKick",duration=5},
 ["Split The Pain"]={players="Survivor",event="killerStunned",duration=5,cooldown=30},
 ["Bloodhound"]={players="Survivor",targetOnly=true,event="bloodhound",duration=5,cooldown=45},
 ["Rotten Stench"]={players="Survivor",targetOnly=true,event="rottenSkillcheck",duration=6},
 ["Piercing Reverie"]={topGenerator=true,event="hookOther",duration=25},
 ["All Seeing Eye"]={cooperativeGenerators=true,when="passive"},
 ["King's Scourge"]={scourgeGenerators=true,when="passive"},
 ["Veiled Corruption"]={regressingGenerators=true,when="passive"},
}
local function perkKey(role,name) return "perk:"..role..":"..name end
function PerkBoosts:Refresh()
 self.catalog={}; self.byKey={}
 for _,role in {"Survivor","Killer"} do
  local effects=role=="Survivor" and survivorEffects or killerEffects
  for name,definition in perkDefinitions(role) do
   local key=perkKey(role,name); if C[key]==nil then C[key]=false end
   local description=tostring(definition:GetAttribute("desc") or "No description supplied by the game.")
   description=description:gsub("<br%s*/?>","\n"):gsub("<.->",""):gsub("\\n","\n")
   local effect=effects[name]
   local nativeOnly=effect and (name=="Time To Grow Up" or (effect.when=="auraRevealed" or effect.when=="markedWindow" or effect.when=="terror" or effect.when=="hookedRepairers")
    or ({confirmedBasicHit=true,spotted=true,sustenance=true,auraReader=true,exposure=true,visceralKick=true,bloodhound=true,rottenSkillcheck=true,survivorVault=true,palletDropped=true})[effect.event])
   local entry={key=key,name=name,role=role,effects=not nativeOnly and effect or nil,nativeOnly=nativeOnly,definition=definition,description=description}
   table.insert(self.catalog,entry); self.byKey[key]=entry
  end
 end
 table.sort(self.catalog,function(a,b) return a.role==b.role and a.name<b.name or a.role<b.role end)
end
function PerkBoosts:Reset()
 self.windows={}; self.cooldowns={}; self.tokens={}; self.context={}; self.previous=nil
 self.windedUntil=0; self.evasiveUntil=0; self.vaultSerial=0; self.lastObserve=0; self.gatesPowered=false
 self.foodReadyAt=0; self.surgeUntil=0; self.surgeSpeed=0; self.healedTarget=nil
 self.generatorState={}; self.vaultStartPosition=nil
end
function PerkBoosts:Enabled(entry)
 return entry and entry.effects and (C.allPerkBoosts or C[entry.key])
end
function PerkBoosts:Active()
 if C.allPerkBoosts then return true end
 for _,entry in self.catalog do if self:Enabled(entry) then return true end end
 return false
end
function PerkBoosts:Trigger(entry,now,target,duration)
 if not self:Enabled(entry) or (self.context.role and entry.role~=self.context.role) then return false end
 local effect=entry.effects
 if (self.cooldowns[entry.key] or 0)>now then return false end
 if effect.winded and ((self.windedUntil or 0)>now or self.context.winded) then return false end
 local prior=self.windows[entry.key]
 local stacks=effect.stacked and prior and prior.untilTime>now and prior.stacks+1 or 1
 local seconds=duration or effect.duration or 0
 if effect.players and seconds>0 and entry.name~="Visual Learner" then
  local extension=entry.role=="Survivor" and self.byKey[perkKey("Survivor","Visual Learner")] or self.byKey[perkKey("Killer","Enhanced Senses")]
  if self:Enabled(extension) then seconds=seconds+(entry.role=="Survivor" and 3 or 2) end
 end
 self.windows[entry.key]={untilTime=now+seconds,target=target,stacks=stacks,vaultSerial=self.vaultSerial}
 if effect.topGenerator then
  local top,progress
  for _,g in A.generators do if g.Parent then local value=g:GetAttribute("RepairProgress") or 0
   if value<100 and (not progress or value>progress) then top=g; progress=value end
  end end
  self.windows[entry.key].generator=top
 end
 self.cooldowns[entry.key]=now+(effect.cooldown or 0)
 if effect.winded then self.windedUntil=now+effect.winded end
 return true
end
function PerkBoosts:Event(event,data,now)
 data=data or {}; now=now or os.clock()
 local role=self.context.role or playerRole(LocalPlayer)
 if event=="gates" then self.gatesPowered=true end
 if event=="generatorDone" and self:Enabled(self.byKey[perkKey(role,"Visual Learner")]) then self.tokens.visual=(self.tokens.visual or 1)+1 end
 if event=="greatRepair" then self.tokens.flawless=(self.tokens.flawless or 0)+1 end
 if event=="missRepair" then self.tokens.flawless=0 end
 if event=="survivorEscaped" and role=="Killer" and self:Enabled(self.byKey[perkKey(role,"Play With Your Food")]) and now>=(self.foodReadyAt or 0) then
  self.tokens.food=math.min((self.tokens.food or 0)+1,3); self.foodReadyAt=now+10
 end
 if event=="attack" then self.tokens.food=math.max((self.tokens.food or 0)-1,0) end
 if event=="stun" or event=="parry" or event=="blind" then self:Event("stunOrParry",data,now) end
 if event=="vaultStart" then
  self.vaultSerial=self.vaultSerial+1
  local flow=self.byKey[perkKey(role,"Flowstate")]
  if data.tier=="fast" and flow then self:Trigger(flow,now,nil,10) end
  local acro=self.byKey[perkKey(role,"Murderous Acrobatics")]
  if self.context.chased and acro then self:Trigger(acro,now,nil,10) end
  local evasive=self.byKey[perkKey(role,"Evasive Manoeuvre")]
  if evasive and (self.evasiveUntil or 0)>now then
   if self:Trigger(evasive,now,nil,10) then self.evasiveUntil=0 end
  elseif evasive and self:Enabled(evasive) then self.evasiveUntil=now+15 end
 end
 if event=="vaultEnd" then
  if data.tier=="fast" or data.tier=="medium" then self:Event("quickVault",data,now) end
  for _,name in {"Evasive Manoeuvre","Murderous Acrobatics"} do
   local entry=self.byKey[perkKey(role,name)]; local w=entry and self.windows[entry.key]
   if w and w.vaultSerial==self.vaultSerial then w.untilTime=now+entry.effects.duration; w.landed=true end
  end
  local visual=self.byKey[perkKey(role,"Visual Learner")]
  if visual and data.tier=="fast" and (self.context.killerDistance or math.huge)<=150 and (self.tokens.visual or 1)>0 then
   if self:Trigger(visual,now,nil,8) then self.tokens.visual=(self.tokens.visual or 1)-1 end
  end
 end
 for _,entry in self.catalog do
  local e=entry.effects
  if e and entry.role==role and e.event==event and (not e.radiusTrigger or (data.distance or math.huge)<=e.radiusTrigger) then
   self:Trigger(entry,now,data.target)
  end
 end
end
function PerkBoosts:Observe(now)
 now=now or os.clock(); if now<(self.lastObserve or 0)+.05 then return end; self.lastObserve=now
 local ch,h,root=character(); if not ch then self:Reset(); return end
 local role=playerRole(LocalPlayer); local ctx=A.adapter.repair; local movement=A.adapter.movement
 if ctx and ctx.character~=ch then ctx=nil end
 if movement and movement.character~=ch then movement=nil end
 local killer=A.adapter.killer
 local state={role=role,character=ch,health=h.Health,round=ch:GetAttribute("RoundScriptsActive")==true,
  crouch=ch:GetAttribute("Crouching")==true,sprint=ch:GetAttribute("Sprinting")==true,
  chased=(role=="Killer" and ch:GetAttribute("IsChasing")==true) or ch:GetAttribute("IsChased")==true,
  hooked=observedAttribute(ch,"IsHooked")==true,
  carrying=ch:GetAttribute("IsCarrying")==true,falling=movement and movement.isSlowedFromFall==true,
  vaulting=movement and (movement.isVaulting or movement.isSlideingPallet)
    or (killer and killer.character==ch and killer.state.isVaulting) or ch:GetAttribute("isvaulting")==true,
  vaultTier=ch:GetAttribute("VaultTier"),winded=Tags:HasTag(ch,"Winded"),players={},living=0,
  killerDistance=math.huge,nearSurvivorDistance=math.huge,repairers=0,hookedCount=0,
  position=root.Position,attacking=killer and killer.character==ch and (killer.state.isAttacking or killer.state.isLunging),
  stunned=ch:GetAttribute("IsStunned")==true,healing=ctx and ctx.script:GetAttribute("isHealing")==true,
  repairing=ctx and ctx.script:GetAttribute("isRepairing")==true,healTarget=ctx and ctx.state.currentHealPoint}
 local healHum=state.healTarget and state.healTarget.Parent and state.healTarget.Parent:FindFirstChildOfClass("Humanoid")
 state.healTargetHealth=healHum and healHum.Health
 local point=ctx and ctx.state.currentRepairPoint
 state.generator=point and point.Parent
 if state.generator then state.repairers=state.generator:GetAttribute("PlayersRepairingCount") or 0 end
 -- Terror-radius perks require the game's explicit state rather than a guessed radius.
 state.terror=ch:GetAttribute("InTerrorRadius")==true and not state.chased
 for _,p in Players:GetPlayers() do
  local other=p.Character; local hum=other and other:FindFirstChildOfClass("Humanoid")
  local r=other and other:FindFirstChild("HumanoidRootPart"); local pr=playerRole(p)
  if hum and hum.Health>0 and r and not p:GetAttribute("IsDead") and pr~="Spectator" then
   local d=(r.Position-root.Position).Magnitude
   local row={player=p,role=pr,distance=d,health=hum.Health,hooked=other:GetAttribute("IsHooked")==true,
    chased=other:GetAttribute("IsChased")==true,vault=other:GetAttribute("VaultSfxToken")}
   table.insert(state.players,row)
   if pr=="Survivor" then
    state.living=state.living+1; if row.hooked then state.hookedCount=state.hookedCount+1 end
    if p~=LocalPlayer then state.nearSurvivorDistance=math.min(state.nearSurvivorDistance,d) end
   elseif p~=LocalPlayer then state.killerDistance=math.min(state.killerDistance,d) end
  end
 end
 local previous=self.previous
 self.context=state
 if not previous or previous.character~=ch or previous.role~=role then
  self.previous=state; self.tokens.visual=1; self.generatorState={}; return
 end
 if state.health<previous.health then self:Event("hit",{},now) end
 if previous.hooked and not state.hooked then self:Event("unhooked",{},now) end
 if previous.chased and not state.chased then self:Event("chaseEscaped",{},now) end
 if state.living==1 and previous.living~=1 then self:Event("lastAlive",{},now) end
 if previous.killerDistance>50 and state.killerDistance<=50 and not state.chased then self:Event("killerApproach",{},now) end
 if state.falling and not previous.falling then self:Event("landing",{},now) end
 if state.stunned and not previous.stunned then self:Event("killerStunned",{},now) end
 if state.attacking and not previous.attacking then self:Event("attack",{},now) end
 if state.vaulting and not previous.vaulting then self.vaultStartPosition=root.Position; self:Event("vaultStart",{tier=state.vaultTier},now) end
 if previous.vaulting and not state.vaulting and self.vaultStartPosition and (root.Position-self.vaultStartPosition).Magnitude>1 then
  self:Event("vaultEnd",{tier=previous.vaultTier},now)
 end
 if previous.healing and not state.healing and previous.healTarget and previous.healTarget~=root then
  local targetHum=previous.healTarget.Parent and previous.healTarget.Parent:FindFirstChildOfClass("Humanoid")
  if targetHum and previous.healTargetHealth and targetHum.Health>previous.healTargetHealth then
   self.healedTarget=Players:GetPlayerFromCharacter(previous.healTarget.Parent); self:Event("healOther",{},now)
  end
 end
 local priorPlayers={}; for _,row in previous.players do priorPlayers[row.player]=row end
 for _,row in state.players do
  local old=priorPlayers[row.player]
  if old then
   if old.chased and not row.chased and row.role=="Survivor" and row.health>50 then self:Event("survivorEscaped",{target=row.player},now) end
   if row.health<old.health and row.player==self.healedTarget then self:Event("healedTargetHit",{target=row.player},now) end
   if not old.hooked and row.hooked then self:Event("hookOther",{target=row.player},now) end
   if row.vault~=old.vault and row.distance<=100 then self:Event("survivorVault",{target=row.player},now) end
   if old.health>50 and row.health<=50 then self:Event("survivorDowned",{target=row.player},now) end
  end
 end
 if previous.carrying and not state.carrying and state.hookedCount>previous.hookedCount then
  local e=self.byKey[perkKey("Killer","Excitement")]; if e then self:Trigger(e,now) end
 end
 self.generatorState=self.generatorState or {}
 state.totalRepairers=0; local surge=0
 for _,g in A.generators do if g.Parent then
  local current={completed=g:GetAttribute("Completed")==true,kick=g:GetAttribute("kickcount") or 0}
  local old=self.generatorState[g]
  if old then
   if current.completed and not old.completed then self:Event("generatorDone",{target=g},now) end
   if current.kick>old.kick then
    local p=g.PrimaryPart or g:FindFirstChildWhichIsA("BasePart",true)
    self:Event("loudKillerAction",{distance=p and (p.Position-root.Position).Magnitude or math.huge},now)
    if role=="Killer" then self:Event("kick",{},now) end
   end
  end
  self.generatorState[g]=current
  state.totalRepairers=state.totalRepairers+(g:GetAttribute("PlayersRepairingCount") or 0)
  local part=g.PrimaryPart or g:FindFirstChildWhichIsA("BasePart",true)
  if part and (part.Position-root.Position).Magnitude<=70 then
   if current.completed then surge=math.max(surge,.06)
   elseif g:GetAttribute("Regressing") then surge=math.max(surge,.03) end
  end
 end end
 if surge>0 then self.surgeSpeed=surge; self.surgeUntil=now+3 end
 self.previous=state
end
function PerkBoosts:Rule(entry,now)
 local e=entry.effects; local c=self.context; local w=self.windows[entry.key]
 local timed=w and w.untilTime>now
 if not c.round then return false,0 end
 local rule=e.when
 if not rule then return timed,timed and w.stacks or 0 end
 if rule=="passive" then return true,1 end
 if rule=="walk" then return not c.sprint and not c.crouch,1 end
 if rule=="crouch" then return c.crouch,1 end
 if rule=="nearSurvivor" then return (c.nearSurvivorDistance or math.huge)<=30,1 end
 if rule=="gates" then return self.gatesPowered,1 end
 if rule=="chase" then return c.chased,1 end
 if rule=="terror" then return c.terror,1 end
 if rule=="dyingHeal" then return c.healing and c.healTargetHealth and c.healTargetHealth<=50,1 end
 if rule=="carrying" then return c.carrying or timed,1 end
 if rule=="offscreen" then return not c.chased and (c.nearSurvivorDistance or math.huge)>50,1 end
 if rule=="tokens" then return (self.tokens.food or 0)>0,self.tokens.food or 0 end
 if rule=="generatorRange" then return now<(self.surgeUntil or 0),(self.surgeSpeed or 0)/.06 end
 if rule=="hookedRepairers" then return (c.hookedCount or 0)>0,c.totalRepairers or 0 end
 if rule=="evasive" or rule=="acrobatics" then return timed,timed and 1 or 0 end
 if rule=="flow" then return timed and c.vaulting and w.vaultSerial==self.vaultSerial,1 end
 if rule=="visual" then return timed,1 end
 -- Unobservable server-specific triggers stay inactive instead of granting permanent bonuses.
 return false,0
end
function PerkBoosts:Targets(now)
 now=now or os.clock()
 local role=self.context.role or playerRole(LocalPlayer)
 local out={role=role,speed=1,walk=1,vault=1,crouch=1,count=0,reveals={},generatorSet={},obstacleRange=0,active={}}
 for _,entry in self.catalog do if entry.role==role and self:Enabled(entry) then
  local active,stacks=self:Rule(entry,now)
  if active then
   local e=entry.effects; local w=self.windows[entry.key]
   for _,kind in {"speed","walk","vault","crouch"} do
    local amount=e[kind] or 0
    if e.when=="evasive" or e.when=="acrobatics" then
     if kind=="vault" and (not self.context.vaulting or w.landed) then amount=0 end
     if kind=="speed" and not w.landed then amount=0 end
    end
    out[kind]=out[kind]+amount*(stacks or 1)
   end
   if e.players then
    table.insert(out.reveals,{role=e.players,radius=e.radius or math.huge,minRadius=e.minRadius or 0,target=e.targetOnly and w and w.target})
    out.players="All"
   end
   if e.generators then out.generators=true end
   if e.topGenerator and w and w.generator and w.generator.Parent then out.generatorSet[w.generator]=true end
   if e.obstacles then out.obstacles=true; out.obstacleRange=math.max(out.obstacleRange,e.radius or 100) end
   if e.cluster then
    local candidates={}
    for _,g in A.generators do if g.Parent and not g:GetAttribute("Completed") then
     local part=g.PrimaryPart or g:FindFirstChildWhichIsA("BasePart",true)
     if part then table.insert(candidates,{model=g,position=part.Position}) end
    end end
    local best,score
    for i=1,#candidates-2 do for j=i+1,#candidates-1 do for k=j+1,#candidates do
     local a,b,c=candidates[i],candidates[j],candidates[k]
     local d=(a.position-b.position).Magnitude+(a.position-c.position).Magnitude+(b.position-c.position).Magnitude
     if not score or d<score then best={a.model,b.model,c.model}; score=d end
    end end end
    for _,g in best or {} do out.generatorSet[g]=true end
   end
   if e.cooperativeGenerators or e.scourgeGenerators or e.regressingGenerators then
    for _,g in A.generators do if g.Parent then
     local n=g:GetAttribute("PlayersRepairingCount") or 0
     if (e.cooperativeGenerators and n>1) or (e.scourgeGenerators and (g:GetAttribute("RepairProgress") or 0)>=90)
      or (e.regressingGenerators and g:GetAttribute("Regressing")) then out.generatorSet[g]=true end
    end end
   end
   out.count=out.count+1; table.insert(out.active,entry.name)
  end
 end end
 return out
end
function PerkBoosts:CanReveal(player,distance,targets)
 for _,r in targets.reveals do
  if (r.role=="All" or r.role==playerRole(player)) and distance<=r.radius and distance>=r.minRadius
   and (not r.target or r.target==player) then return true end
 end
 return false
end
function PerkBoosts:Describe(entry) return entry.description end
A.perkBoosts=PerkBoosts
-- PERK_BOOSTS_END


-- FORCE_CONTROLLER_BEGIN
-- Local overrides are deliberately separate from server inventory and native action automation.
local Force={attributes={},patches={},vaultTracks={}}
local function vaultTrackSpeed(track)
    return track.CurrentSpeed or (track.Track and track.Track.Speed) or track.Speed
end
function Force:RestoreVaultTracks()
    for track,row in self.vaultTracks do
        pcall(function() if track.IsPlaying and math.abs(vaultTrackSpeed(track)-row.last)<.001 then track:AdjustSpeed(row.original) end end)
    end
    self.vaultTracks={}
end
function Force:VaultStep(movement,multiplier,killer)
    local track=movement and movement.isVaulting and movement.activeVaultTrack
    local killerTrack=killer and killer.state.isVaulting and killer.smartAnimations and killer.smartAnimations.Vault
    track=track or killerTrack
    for owned,row in self.vaultTracks do if owned~=track or multiplier<=1 then
        pcall(function() if owned.IsPlaying and math.abs(vaultTrackSpeed(owned)-row.last)<.001 then owned:AdjustSpeed(row.original) end end)
        self.vaultTracks[owned]=nil
    end end
    if not track or not track.IsPlaying or multiplier<=1 then return end
    local current=vaultTrackSpeed(track)
    if type(current)~="number" then return end
    local row=self.vaultTracks[track]
    if not row then row={original=current}; self.vaultTracks[track]=row
    elseif math.abs(current-row.last)>.001 then row.original=current end
    local tier=movement and movement.character:GetAttribute("VaultTier")
    local base=tier=="medium" and 1.7 or 1
    if movement and movement.smartAnimations and track==movement.smartAnimations.finessevault then base=.96 end
    if track==killerTrack then
        local vault=killer.config and killer.config.vault or {}
        base=(track.Length or 1.525)/(vault.duration or 1.525)*(killer.character:GetAttribute("swift") or 1)
    end
    local speed=math.clamp(math.max(row.original,base*multiplier),.1,4)
    if math.abs(current-speed)>.001 then track:AdjustSpeed(speed) end
    row.last=speed
end
local function forceTargetSpeed(native)
    local speed=tonumber(C.forcedSpeed)
    if not speed or speed~=speed or math.abs(speed)==math.huge then speed=40 end
    speed=math.max(speed,1)
    if Motion and C.antiRubber then
        native=finiteNumber(native,0)
        return native+(speed-native)*Motion.factor
    end
    return speed
end
local function forceAttribute(group,object,key,value,allowMissing)
    local current=object:GetAttribute(key)
    if current==nil then if not allowMissing then return end
    elseif type(current)~=type(value) then return end
    local objects=Force.attributes[group]
    if not objects then objects={}; Force.attributes[group]=objects end
    local keys=objects[object]
    if not keys then keys={}; objects[object]=keys end
    local row=keys[key]
    if not row then row={original=current}; keys[key]=row
    elseif current~=row.last then row.original=current end
    if current~=value then object:SetAttribute(key,value) end
    row.last=value
end
local function restoreAttributes(group)
    local objects=Force.attributes[group]; Force.attributes[group]=nil
    if not objects then return end
    for object,keys in objects do for key,row in keys do
        pcall(function() if object:GetAttribute(key)==row.last then object:SetAttribute(key,row.original) end end)
    end end
end
local function forceBonusFloor(object,key,target,allowMissing)
    local current=object:GetAttribute(key)
    if current==nil and allowMissing then
        if target>1 then forceAttribute("forceBonuses",object,key,target,true) end
        return
    end
    if type(current)~="number" then return end
    local objects=Force.attributes.forceBonuses
    local row=objects and objects[object] and objects[object][key]
    local baseline=current
    if row and current==row.last then baseline=row.original; if baseline==nil then baseline=1 end end
    if baseline~=baseline or math.abs(baseline)==math.huge then return end
    forceAttribute("forceBonuses",object,key,math.max(baseline,target))
end
local function bonusTarget(key,fallback)
    local value=tonumber(C[key])
    if not value or value~=value or math.abs(value)==math.huge then value=fallback end
    return math.max(value,1)
end
local function forceMethod(id,object,key,wrapper)
    local existing=Force.patches[id]
    if existing and existing.object==object then return end
    if existing and rawget(existing.object,existing.key)==existing.wrapper then rawset(existing.object,existing.key,existing.raw) end
    if type(object[key])~="function" then Force.patches[id]=nil; return end
    Force.patches[id]={object=object,key=key,raw=rawget(object,key),wrapper=wrapper}
    rawset(object,key,wrapper)
end
local function restoreMethods(group)
    local ids={}
    for id,patch in Force.patches do if id:sub(1,#group)==group then table.insert(ids,id) end end
    for _,id in ids do
        local patch=Force.patches[id]; Force.patches[id]=nil
        if rawget(patch.object,patch.key)==patch.wrapper then rawset(patch.object,patch.key,patch.raw) end
    end
end
function Force:Active() return C.forceSpeed or C.forceMovement or C.forceSlow or C.forceBonuses or (tonumber(C.speedBoost) or 1)>1 or (PerkBoosts and PerkBoosts:Active()) end
function Force:Release(group)
    if group=="forceBonuses" then self:RestoreVaultTracks() end
    restoreAttributes(group); restore(group); restoreMethods(group)
end
function Force:Stop()
    self:Release("forceSpeed"); self:Release("forceMovement"); self:Release("forceSlow")
    self:Release("forceBonuses")
    self.character=nil; self.movement=nil
end
function A:ForceKeys(bonusesOnly)
    local keys=bonusesOnly and {"forceBonuses","allPerkBoosts","speedBoost"} or {"forceSpeed","forceMovement","forceSlow","forceBonuses","allPerkBoosts","speedBoost"}
    for key in C do if key:sub(1,5)=="perk:" then table.insert(keys,key) end end
    return keys
end
function A:PerkKeys()
    local keys={"allPerkBoosts"}
    for key in C do if key:sub(1,5)=="perk:" then table.insert(keys,key) end end
    return keys
end
function Force:Step()
    if not A.alive or not self:Active() then self:Stop(); return end
    local ch,h,root=character()
    if not ch then self:Stop(); return end
    if self.character and self.character~=ch then self:Stop() end
    self.character=ch
    -- Every local movement override shares the same yield decision, including
    -- direct WalkSpeed, debuff removal and patches called by native controllers.
    if Motion and Motion:ShouldYield() then self:Stop(); return end
    local movement=A.adapter.movement
    if movement and movement.character~=ch then movement=nil end
    if self.movement and self.movement~=movement then
        restoreMethods("forceSpeed"); restoreMethods("forceMovement"); restoreMethods("forceSlow")
        restore("forceSlow"); restore("forceMovement")
        self:Release("forceBonuses")
    end
    self.movement=movement
    local targets=PerkBoosts and PerkBoosts:Targets() or {speed=1,walk=1,vault=1,crouch=1}
    local bonuses=C.forceBonuses or (tonumber(C.speedBoost) or 1)>1 or targets.count and targets.count>0
    local ctx=A.adapter.repair
    local nativeBusy=A.repair or A.recovery or A.bindHeal or (ctx and ctx.character==ch and (ctx.state.activeMouseAction or ctx.script:GetAttribute("isVaulting")))
        or (movement and (movement.isVaulting or movement.isSlideingPallet or movement.isHealingActive))
    local killer=A.adapter.killer
    nativeBusy=nativeBusy or (killer and killer.character==ch and killer.state and (killer.state.isVaulting or killer.state.isStunned or killer.state.isBreaking))
    local speedFloor=math.max((targets.speed or 1)*(tonumber(C.speedBoost) or 1),C.forceBonuses and bonusTarget("bonusSpeed",1.5) or 1,C.forceSlow and 1 or 0)
    local walkFloor=math.max(targets.walk or 1,C.forceBonuses and bonusTarget("bonusWalk",1.2) or 1)
    local vaultFloor=math.max(targets.vault or 1,C.forceBonuses and bonusTarget("bonusVault",1.15) or 1)
    local crouchFloor=math.max(targets.crouch or 1,C.forceBonuses and bonusTarget("bonusCrouch",2) or 1)
    if Motion and C.antiRubber then
        speedFloor=Motion:Multiplier(speedFloor)
        walkFloor=Motion:Multiplier(walkFloor)
        vaultFloor=Motion:Multiplier(vaultFloor)
        crouchFloor=Motion:Multiplier(crouchFloor)
    end
    A:RunFeature("perkBonuses",A:ForceKeys(true),function()
    self:VaultStep(movement,bonuses and vaultFloor or 1,killer)
    if bonuses and (movement or targets.role=="Killer") then
        restoreAttributes("forceSlow")
        -- These attributes are read by the inspected survivor movement controller.
        -- Floors reproduce local movement bonuses, not perk ownership or server effects.
        forceBonusFloor(ch,"speedboost",speedFloor,targets.role=="Killer")
        forceBonusFloor(ch,"walkboost",walkFloor)
        forceBonusFloor(ch,"vaultspeed",vaultFloor)
        if targets.role=="Killer" then forceBonusFloor(ch,"vaultspeedboost",vaultFloor,true) end
        local crouch=movement and movement.crouchSpeed
        if type(crouch)=="number" and crouch==crouch and math.abs(crouch)~=math.huge then
            local changes=A.changes.forceBonuses
            local row=changes and changes.index[movement] and changes.index[movement].crouchSpeed
            local baseline=row and crouch==row.last and row.original or crouch
            own("forceBonuses",movement,"crouchSpeed",math.max(baseline,6*crouchFloor))
        end
        if movement and not self.patches["forceBonuses:walk"] and type(movement._walkSpeed)=="function" then
            local originalWalk=movement._walkSpeed
            forceMethod("forceBonuses:walk",movement,"_walkSpeed",function(self,...)
                local value=originalWalk(self,...)
                local base=self.normalWalkSpeed
                if type(base)~="number" or base~=base or math.abs(base)==math.huge then base=10 end
                local activeTargets=PerkBoosts and PerkBoosts:Targets() or {}
                local floor=math.max(base,0)*math.max(activeTargets.walk or 1,C.forceBonuses and bonusTarget("bonusWalk",1.2) or 1)
                if Motion and C.antiRubber then
                    if Motion:ShouldYield() then return value end
                    floor=math.max(base,0)*Motion:Multiplier(math.max(activeTargets.walk or 1,C.forceBonuses and bonusTarget("bonusWalk",1.2) or 1))
                end
                if type(value)~="number" or value~=value or math.abs(value)==math.huge then return floor end
                return math.max(value,floor)
            end)
        end
    else self:Release("forceBonuses") end
    end,function() self:Release("forceBonuses") end)
    A:RunFeature("forceMovement",{"forceMovement"},function()
    if C.forceMovement and not nativeBusy and not (Motion and C.antiRubber and Motion.factor<.99) then
        for _,name in {"Rooted","Immobile","MovementLocked","IsStunned","Trapped","Chained","IsHooked","IsCarried","IsBeingHealed","Ragdolled","Knocked"} do
            forceAttribute("forceMovement",ch,name,false)
        end
        local ragdoll=ch:FindFirstChild("RagdollTrigger")
        if ragdoll and ragdoll:IsA("BoolValue") then own("forceMovement",ragdoll,"Value",false) end
        own("forceMovement",root,"Anchored",false)
        own("forceMovement",h,"PlatformStand",false)
        own("forceMovement",h,"AutoRotate",true)
        if movement then
            forceMethod("forceMovement:hardLock",movement,"_shouldHardLockSpeed",function() return false end)
            forceMethod("forceMovement:movementLock",movement,"_movementLocked",function() return false end)
            forceMethod("forceMovement:ragdoll",movement,"_isRagdolled",function() return false end)
        end
    else self:Release("forceMovement") end
    end,function() self:Release("forceMovement") end)
    A:RunFeature("forceSlow",{"forceSlow"},function()
    if C.forceSlow and not (Motion and C.antiRubber and Motion.factor<.99) then
        local boost=ch:GetAttribute("speedboost")
        if type(boost)=="number" and boost<1 then forceAttribute("forceSlow",ch,"speedboost",1) end
        if movement then
            local originalBoost=movement._getSpeedBoost
            local installed=self.patches["forceSlow:boost"]
            if installed and installed.object==movement then originalBoost=installed.original end
            if type(originalBoost)=="function" and not installed then
                forceMethod("forceSlow:boost",movement,"_getSpeedBoost",function(self,...)
                    local value=originalBoost(self,...)
                    if type(value)~="number" or value~=value or math.abs(value)==math.huge then return 1 end
                    return math.max(value,1)
                end)
                if self.patches["forceSlow:boost"] then self.patches["forceSlow:boost"].original=originalBoost end
            end
            if type(movement.PENALTY_ENABLED)=="boolean" then own("forceSlow",movement,"PENALTY_ENABLED",false) end
            if not self.patches["forceSlow:fall"] and type(movement._checkConditions)=="function" then
                local originalConditions=movement._checkConditions
                forceMethod("forceSlow:fall",movement,"_checkConditions",function(self,...)
                    if not C.forceSlow or not self.isSlowedFromFall then return originalConditions(self,...) end
                    local falling,walk,run,crouch=self.isSlowedFromFall,self.normalWalkSpeed,self.runSpeed,self.crouchSpeed
                    self.isSlowedFromFall=false
                    self.normalWalkSpeed=math.max(walk or 10,10); self.runSpeed=math.max(run or 17,17); self.crouchSpeed=math.max(crouch or 6,6)
                    local result=table.pack(pcall(originalConditions,self,...))
                    self.isSlowedFromFall=falling; self.normalWalkSpeed=walk; self.runSpeed=run; self.crouchSpeed=crouch
                    if not result[1] then error(result[2],0) end
                    return table.unpack(result,2,result.n)
                end)
            end
        end
    else self:Release("forceSlow") end
    end,function() self:Release("forceSlow") end)
    A:RunFeature("forceSpeed",{"forceSpeed"},function()
    if C.forceSpeed and not nativeBusy then
        local native=h.WalkSpeed
        local owned=A.changes.forceSpeed
        local row=owned and owned.index[h] and owned.index[h].WalkSpeed
        if row and native==row.last then native=row.original end
        local speed=forceTargetSpeed(native)
        own("forceSpeed",h,"WalkSpeed",speed)
        if movement then
            local originalSmooth=movement._setWalkSpeedSmooth
            local originalInstant=movement._setWalkSpeedInstant
            if not self.patches["forceSpeed:smooth"] and type(originalSmooth)=="function" then
                forceMethod("forceSpeed:smooth",movement,"_setWalkSpeedSmooth",function(self,value,...)
                    local active=C.forceSpeed and not (Motion and Motion:ShouldYield())
                    return originalSmooth(self,active and forceTargetSpeed(value) or value,...)
                end)
            end
            if not self.patches["forceSpeed:instant"] and type(originalInstant)=="function" then
                forceMethod("forceSpeed:instant",movement,"_setWalkSpeedInstant",function(self,value,...)
                    local active=C.forceSpeed and not (Motion and Motion:ShouldYield())
                    return originalInstant(self,active and forceTargetSpeed(value) or value,...)
                end)
            end
        end
    else self:Release("forceSpeed") end
    end,function() self:Release("forceSpeed") end)
    -- Gameplay workers own action diagnostics; force settings do not overwrite them every frame.
end
A.force=Force
-- FORCE_CONTROLLER_END

-- EXTRA_CONTROLLERS_BEGIN
-- MOTION_CONTROLLER_BEGIN
-- Observe position; never replay a rejected CFrame, suppress replication or
-- change network ownership. Residuals are evidence of discontinuity, not proof
-- that a server anti-cheat caused it.
Motion={factor=1,pauseUntil=0,corrections=0,history={},state="Disabled",reason="Disabled"}
function Motion:Stop()
 self.factor=1; self.pauseUntil=0; self.previous=nil; self.character=nil; self.root=nil
 self.lastCorrection=nil; self.windowStart=nil; self.windowCount=0; self.limitedUntil=0
 self.blockReason=nil; self.resumeUntil=0; self.netGeneration=nil
 self.state="Disabled"; self.reason="Disabled"; table.clear(self.history)
end
function Motion:ShouldYield()
 return C.antiRubber and (self.blockReason~=nil or os.clock()<self.pauseUntil or self.factor<=0)
end
function Motion:Multiplier(value)
 return 1+(value-1)*(C.antiRubber and self.factor or 1)
end
function Motion:Sample(position,velocity,now,blocked)
 local function valid(n) return type(n)=="number" and n==n and math.abs(n)<1e8 end
 if not position or not velocity or not valid(now) or not valid(position.X) or not valid(position.Y)
  or not valid(position.Z) or not valid(velocity.X) or not valid(velocity.Y) or not valid(velocity.Z) then
  self.previous=nil; table.clear(self.history); self.reason="Invalid motion sample"
  self.pauseUntil=math.max(self.pauseUntil,os.clock()+.35); return false
 end
 if blocked then self.previous=nil; table.clear(self.history); return false end
 local old=self.previous
 -- Horizontal evidence avoids treating gravity, jumps and landing as rollbacks.
 local p=Vector3.new(position.X,0,position.Z)
 local v=Vector3.new(velocity.X,0,velocity.Z)
 local sample={position=p,velocity=v,time=now}
 self.previous=sample
 if not old then table.clear(self.history); table.insert(self.history,sample); return false end
 local dt=now-old.time
 if dt<=0 or dt>.25 then
  table.clear(self.history); table.insert(self.history,sample)
  self.pauseUntil=math.max(self.pauseUntil,now+.35); self.reason="Resampling after a frame gap"; return false
 end
 local delta=p-old.position
 local expected=(old.velocity+v)*(.5*dt)
 local residual=(delta-expected).Magnitude
 local speed=math.max(old.velocity.Magnitude,v.Magnitude)
 local discontinuity=residual>math.max(6,speed*dt*2+3)
 local backward=old.velocity.Magnitude>2 and delta.Magnitude>1.25
  and delta:Dot(old.velocity)<-delta.Magnitude*old.velocity.Magnitude*.4
 -- A real turn normally changes both displacement and velocity. A snap back
 -- often retains the old forward velocity or returns to a recent pose.
 local rollback=backward and v:Dot(old.velocity)>=0 and residual>math.max(1.75,speed*dt*.6+.75)
 if backward and not rollback then
  for _,row in self.history do
   if now-row.time<=.65 and now-row.time>=.06 and (p-row.position).Magnitude<.65
    and (old.position-row.position).Magnitude>2.5 and residual>2.5 then rollback=true; break end
  end
 end
 local corrected=(discontinuity or rollback) and (not self.lastCorrection or now-self.lastCorrection>=.25)
 if corrected then
  if not self.windowStart or now-self.windowStart>8 then self.windowStart=now; self.windowCount=0 end
  self.windowCount=self.windowCount+1; self.corrections=self.corrections+1
  self.factor=self.factor*.7; self.pauseUntil=now+math.min(4,.8*2^(self.windowCount-1))
  self.lastCorrection=now; self.state="Settling"; self.reason="Position discontinuity"
  if self.windowCount>=3 then
   self.factor=0; self.limitedUntil=now+15; self.pauseUntil=self.limitedUntil
   self.state="Limited"; self.reason="Repeated corrections; native movement only"
  end
  table.clear(self.history)
 elseif now>=self.pauseUntil and now-(self.lastCorrection or now)>8 then
  self.factor=math.min(1,self.factor+dt*.015)
 end
 table.insert(self.history,sample)
 if #self.history>24 then table.remove(self.history,1) end
 return corrected
end
function Motion:ObservedProperty(object,key)
 local value=object[key]
 local list=A.changes.forceMovement
 local row=list and list.index[object] and list.index[object][key]
 if row and value==row.last then return row.original end
 return value
end
function Motion:NativeReason(ch,h,root)
 if self:ObservedProperty(root,"Anchored") then return "Anchored by native controller" end
 if h.Sit or self:ObservedProperty(h,"PlatformStand") then return "Seated or physics-controlled" end
 for _,key in {"AC_ServerAnchor","IsHooked","IsCarried","IsCarrying","Knocked","Ragdolled",
  "Rooted","Immobile","MovementLocked","IsStunned","Trapped","Chained","ChainReeling","donttrack","BypassNoclipAntiCheat"} do
  if observedAttribute(ch,key)==true then return key end
 end
 local m=A.adapter.movement
 if m and m.character==ch and (m.isVaulting or m.isSlideingPallet or m.isHealingActive) then return "Native traversal or healing" end
 local k=A.adapter.killer
 local s=k and k.character==ch and k.state
 if s and (s.isVaulting or s.isStunned or s.isBreaking) then return "Native killer action" end
 local ctx=A.adapter.repair
 if A.repair or A.recovery or A.bindHeal or (ctx and ctx.character==ch and ctx.state.activeMouseAction) then return "Native interaction" end
 local now=workspace:GetServerTimeNow()
 for _,key in {"ChainYankUntil","NetPalletApproachUntil","HiddenDashReplicationUntil","HiddenLeapReplicationUntil"} do
  local untilTime=observedAttribute(ch,key)
  if type(untilTime)=="number" and untilTime==untilTime and untilTime>now and untilTime<now+6 then return "Native traversal window" end
 end
end
function Motion:Step()
 if not C.antiRubber then if self.state~="Disabled" then self:Stop() end; return end
 local ch,h,root=character()
 if not ch then self:Stop(); self.state="Waiting"; self.reason="Waiting for character"; self.blockReason=self.reason; return end
 local now=os.clock()
 local generation=observedAttribute(ch,"NetGeneration")
 if self.character~=ch or self.root~=root or self.netGeneration~=generation then
  self:Stop(); self.character=ch; self.root=root; self.netGeneration=generation
  self.pauseUntil=now+.35; self.resumeUntil=self.pauseUntil
 end
 local why=self:NativeReason(ch,h,root)
 if why then
  self.blockReason=why; self.state="Yielding"; self.reason=why; self.resumeUntil=now+.35
  self:Sample(root.Position,root.AssemblyLinearVelocity,now,true)
  if A.move then A:CancelMove("Movement stabilization: "..why) end
  return
 end
 self.blockReason=nil
 if now<self.resumeUntil then
  self.pauseUntil=math.max(self.pauseUntil,self.resumeUntil)
  self.state="Settling"; self.reason="Native movement handoff"
  self:Sample(root.Position,root.AssemblyLinearVelocity,now,true); return
 end
 if self:Sample(root.Position,root.AssemblyLinearVelocity,now,false) then
  if A.move then A:CancelMove("Movement correction detected; waiting for position to settle") end
  A.status.result="Position discontinuity observed; local boost strength "..string.format("%.0f%%",self.factor*100)
 elseif now<self.pauseUntil then
  self.state=self.factor<=0 and "Limited" or "Settling"
 elseif self.factor<1 then self.state="Recovering"; self.reason="Gradual boost recovery"
 else self.state="Monitoring"; self.reason="Motion stable" end
end
function Motion:Snapshot()
 return {state=self.state,reason=self.reason,factor=self.factor,corrections=self.corrections,
  cooldown=math.max(0,self.pauseUntil-os.clock()),recentCorrections=self.windowCount or 0}
end
A.motion=Motion
-- MOTION_CONTROLLER_END

CameraControl={}
function CameraControl:Stop()
 restore("freeCamera"); restore("freeCameraInput")
 self.camera=nil; self.character=nil; self.yaw=nil; self.pitch=nil
end
function CameraControl:Step()
 if not C.freeCamera then self:Stop(); return end
 local ch,h,root=character(); local camera=workspace.CurrentCamera
 if not ch or not camera or playerRole(LocalPlayer)=="Spectator" or ch:GetAttribute("RoundScriptsActive")~=true then self:Stop(); return end
 if self.camera~=camera or self.character~=ch then
  self:Stop(); self.camera=camera; self.character=ch
  local look=camera.CFrame.LookVector
  self.yaw=math.atan2(-look.X,-look.Z); self.pitch=math.asin(math.clamp(look.Y,-1,1))
  self.distance=math.clamp((camera.CFrame.Position-camera.Focus.Position).Magnitude,.5,25)
 end
 local head=ch:FindFirstChild("Head")
 if not head then return end
 if not Cursor:Desired() and not UIS:GetFocusedTextBox() then
  own("freeCameraInput",UIS,"MouseBehavior",Enum.MouseBehavior.LockCenter)
  local delta=UIS:GetMouseDelta(); local scale=math.rad(C.cameraSensitivity)
  self.yaw=self.yaw-delta.X*scale; self.pitch=self.pitch-delta.Y*scale
 end
 local focus=head.Position
 local pose=CFrame.new(focus)*CFrame.fromOrientation(self.pitch,self.yaw,0)*CFrame.new(0,0,self.distance)
 own("freeCamera",camera,"CameraType",Enum.CameraType.Scriptable)
 camera.CFrame=pose; camera.Focus=CFrame.new(focus)
end
A.cameraControl=CameraControl

Items={reserves={},nextPulse=0,itemNames={}}
function Items:SpearMath()
 if not self.spearMath then self.spearMath=require(RS.Modules.Killers.Veil.SpearMath) end
 return self.spearMath
end
function Items:StopCooldowns() restoreAttributes("itemCooldown") end
function Items:StopReserves() restoreAttributes("itemReserve"); self.reserves={} end
function Items:Step()
 local ch=LocalPlayer.Character
 if not ch then self:StopCooldowns(); self:StopReserves(); return end
 if self.character~=ch then self:StopCooldowns(); self:StopReserves(); self.character=ch end
 if next(self.itemNames)==nil then for _,definition in RS.Items:GetChildren() do self.itemNames[definition.Name]=true end end
 if C.noItemCooldowns then
  if os.clock()>=self.nextPulse then
   local original=LocalPlayer:GetAttribute("BaseplateCooldownReset")
   forceAttribute("itemCooldown",LocalPlayer,"BaseplateCooldownReset",(type(original)=="number" and original or 0)+1,true)
   self.nextPulse=os.clock()+.25
  end
 else self:StopCooldowns() end
 if C.infiniteItems then
  -- Only attributes read by the inspected native item clients are retained.
  for _,obj in ch:GetDescendants() do
   local parent=obj
   local ownItem=false
   while parent and parent~=ch do
    if parent:IsA("Tool") or (parent.Parent==ch and self.itemNames[parent.Name]) then ownItem=true; break end
    parent=parent.Parent
   end
   if ownItem then for _,key in {"remaining","charge","shots"} do
    local value=obj:GetAttribute(key)
    if type(value)=="number" then
     local values=self.reserves[obj]; if not values then values={}; self.reserves[obj]=values end
     if values[key]==nil then values[key]=math.max(value,1) end
     forceAttribute("itemReserve",obj,key,math.max(value,values[key]))
    end
   end end
   if ownItem and obj:GetAttribute("usable")==false then forceAttribute("itemReserve",obj,"usable",true) end
  end
 else self:StopReserves() end
end
function Items:Stop() self:StopCooldowns(); self:StopReserves(); self.character=nil; self.charge=nil; self.veilShot=nil end

local function killerHead()
 if playerRole(LocalPlayer)~="Survivor" then return end
 local _,_,root=character(); if not root then return end
 local best,distance=nil,math.huge
 for _,p in Players:GetPlayers() do if p~=LocalPlayer and playerRole(p)=="Killer" and not p:GetAttribute("IsDead") then
  local ch=p.Character; local h=ch and ch:FindFirstChildOfClass("Humanoid")
  local head=ch and ch:FindFirstChild("Head")
  if h and h.Health>0 and head and not ch:GetAttribute("Iframes") and los(root.Position,head) then
   local d=(head.Position-root.Position).Magnitude; if d<distance then best=head; distance=d end
  end
 end end
 return best
end
function Items:Target() return killerHead() end
function Items:SpearTarget() return aimTarget("HumanoidRootPart") end
function Items:RewriteSpear(args)
 local ch=LocalPlayer.Character; local payload=args[1]
 if playerRole(LocalPlayer)~="Killer" or not ch or ch:GetAttribute("MorphedKiller")~="Veil"
  or type(payload)~="table" or typeof(payload.Origin)~="Vector3" or typeof(payload.Direction)~="Vector3"
  or type(payload.Sequence)~="number" or type(payload.ReleasedAt)~="number" then return args end
 local charge=self.charge
 if not charge or charge.character~=ch or charge.sequence~=payload.Sequence then
  A.status.waiting="Spear aim is waiting for a native charge sequence"; return args
 end
 local target=self:SpearTarget(); if not target then A.status.waiting="No visible survivor inside the aim radius"; return args end
 local mathModule=self:SpearMath()
 local seconds=math.max(0,payload.ReleasedAt-charge.time)
 local speed=mathModule.power(seconds)
 local direction,flight=Ballistics.Solve(payload.Origin,target.Position,target.AssemblyLinearVelocity,
  speed,mathModule.Gravity,mathModule.SpawnOffset,mathModule.MaxLife,C.prediction)
 if not direction then A.status.waiting="Native spear trajectory cannot reach this target"; return args end
 -- Verify the curved flight against the same world collision helper as the native client.
 local world=self.spearWorld or require(RS.Modules.Killers.Veil.SpearWorld); self.spearWorld=world
 local previous=payload.Origin
 for i=0,24 do
  local t=flight*i/24
  local position=payload.Origin+direction*(mathModule.SpawnOffset+speed*t)+mathModule.Gravity*(.5*t*t)
  if world.cast(previous,position,ch) then A.status.waiting="Spear trajectory is blocked"; return args end
  previous=position
 end
 local redirected=table.clone(payload); redirected.Direction=direction
 if self.projectileVisuals then redirected.ViewDelay=self.projectileVisuals.viewDelay(payload.Origin,direction) end
 args=table.clone(args); args[1]=redirected
 self.veilShot={character=ch,sequence=payload.Sequence,origin=payload.Origin,direction=direction,time=os.clock()}
 A.metrics.silentRedirects=(A.metrics.silentRedirects or 0)+1
 A.metrics.veilRedirects=(A.metrics.veilRedirects or 0)+1
 A.status.result="Spear direction submitted; waiting for the server projectile"
 return args
end
function Items:Rewrite(remote,args)
 if not C.silentAim or not A.alive then return args end
 if remote==self.veilRemote then return self:RewriteSpear(args) end
 if remote~=self.holyRemote and remote~=self.twistRemote then return args end
 if typeof(args[2])~="Vector3" then return args end
 local head=self:Target(); local ch,_,root=character()
 if not head or not ch then return args end
 local origin=root.Position+Vector3.new(0,1.373,0)
 if remote==self.holyRemote then
  if typeof(args[1])~="Instance" or not args[1]:IsDescendantOf(ch) then return args end
  local part=args[1]:IsA("BasePart") and args[1] or args[1]:FindFirstChildWhichIsA("BasePart",true)
  if part then origin=part.Position end
  local delta=head.Position+head.AssemblyLinearVelocity*C.prediction-origin
  local flat=Vector3.new(delta.X,0,delta.Z).Magnitude
  local speed,gravity=96,196.2
  if flat<.01 then return args end
  local discriminant=speed^4-gravity*(gravity*flat^2+2*delta.Y*speed^2)
  if discriminant<0 then return args end
  local tangent=(speed^2-math.sqrt(discriminant))/(gravity*flat)
  local direction=Vector3.new(delta.X,flat*tangent,delta.Z).Unit
  local t=.35*direction.Y+math.sqrt(1-.35^2+.35^2*direction.Y^2)
  args[2]=(direction*t-Vector3.new(0,.35,0)).Unit
 else
  if type(args[1])~="string" then return args end
  origin=(root.CFrame*CFrame.new(.7,1.373,-2.5)).Position
  local delta=head.Position-origin; if delta.Magnitude<.01 then return args end
  args[2]=delta.Unit
 end
 A.metrics.silentRedirects=(A.metrics.silentRedirects or 0)+1
 return args
end
function Items:InstallSilent()
 if self.namecall then return true end
 if type(hookmetamethod)~="function" or type(getnamecallmethod)~="function" then return false,"Silent aim requires namecall hooks in this runtime" end
 local folder=RS.Remotes.Items
 self.holyRemote=folder["Holy Water"].Throw; self.twistRemote=folder["Twist of Fate"].Fire
 self.veilRemote=RS.Remotes.Killers.Veil.Spearthrow
 self.spearStateRemote=RS.Remotes.Killers.Veil.SpearState
 self.projectileVisuals=require(RS.Modules.World.ProjectileVisualsClient)
 local predict=self.projectileVisuals.predict
 own("silentPrediction",self.projectileVisuals,"predict",function(ch,sequence,origin,direction,...)
  local shot=self.veilShot
  if C.silentAim and A.alive and shot and shot.character==ch and shot.sequence==sequence and os.clock()-shot.time<.25 then
   origin=shot.origin; direction=shot.direction
  end
  return predict(ch,sequence,origin,direction,...)
 end)
 -- In-place hook implementations keep the original function identity. Reuse a neutral
 -- dispatcher on those runtimes instead of stacking another hook after each toggle/reload.
 local router=env.SmugVD_NamecallRouter
 if router and router.protocol==1 then
  router.owner=A; router.items=self; router.perks=PerkBoosts; self.namecall=router
  return true
 end
 router={protocol=1,owner=A,items=self,perks=PerkBoosts}
 local function intercept(remote,...)
  local owner=router.owner; local item=router.items
  local method=getnamecallmethod()
  if owner and owner.alive and item and method=="FireServer" then
   if remote==item.spearStateRemote then
    local action,sequence,time=...
    if action=="charge" and type(sequence)=="number" and type(time)=="number" then
     item.charge={character=LocalPlayer.Character,sequence=sequence,time=time}
    elseif action=="cancel" then item.charge=nil end
   end
   if remote==RS.Remotes.Generator.SkillCheckResultEvent then
    local result=select(1,...)
    if result=="success" then router.perks:Event("greatRepair") elseif result=="fail" then router.perks:Event("missRepair") end
   end
   if owner.config.silentAim and (remote==item.veilRemote or remote==item.holyRemote or remote==item.twistRemote) then
    local args=table.pack(...)
    local good,rewrite=pcall(function() return item:Rewrite(remote,args) end)
    if good then
     -- Nested instance calls during target/trajectory inspection may change the VM namecall atom.
     if type(setnamecallmethod)=="function" then setnamecallmethod(method) end
     return router.original(remote,table.unpack(rewrite,1,rewrite.n))
    end
    owner.lastError="silentAim: "..tostring(rewrite); owner.config.silentAim=false
   end
  end
  if type(setnamecallmethod)=="function" then setnamecallmethod(method) end
  return router.original(remote,...)
 end
 local closure=type(newcclosure)=="function" and newcclosure(intercept) or intercept
 router.wrapper=closure
 router.original=hookmetamethod(game,"__namecall",closure)
 env.SmugVD_NamecallRouter=router; self.namecall=router
 return true
end
function Items:RemoveSilent()
 restore("silentPrediction"); self.charge=nil; self.veilShot=nil
 local hook=self.namecall
 self.namecall=nil
 if not hook then return end
 if hook.owner~=A then return end
 hook.owner=nil; hook.items=nil; hook.perks=nil
 -- Do not remove a hook installed by another script after this one.
 if type(getrawmetatable)=="function" then
  local good,mt=pcall(getrawmetatable,game)
  if good and mt.__namecall==hook.wrapper then
   local restored=pcall(hookmetamethod,game,"__namecall",hook.original)
   if restored and env.SmugVD_NamecallRouter==hook then env.SmugVD_NamecallRouter=nil end
  end
 end
end
A.items=Items

SelfHeal={}
function SelfHeal:Stop(reason)
 local record=A.bindHeal; A.bindHeal=nil; C.selfHeal=false
 if record and record.kind=="bandage" then
  local controller=record.controller
  if controller.character==LocalPlayer.Character and controller.isAiming then pcall(controller._setAiming,controller,false) end
 elseif record and record.ctx.character==LocalPlayer.Character and record.ctx.state.currentHealPoint==record.root
  and record.ctx.state.activeMouseAction=="healing" then
  local actions=record.actions; pcall(actions.stopHeal,record.ctx)
 end
 if reason then A.status.waiting=reason; notify(reason) end
end
function SelfHeal:Toggle()
 if C.selfHeal or A.bindHeal then self:Stop("Self-heal cancelled"); return end
 A:ClearFailure("selfHeal"); C.selfHeal=true
end
function SelfHeal:Step()
 if not C.selfHeal then if A.bindHeal then self:Stop() end; return end
 local state,ch,h,root,ctx=Adapter.State()
 local record=A.bindHeal
 if record and record.kind=="bandage" and state.alive and record.character==ch and h.Health>record.health then
  A.metrics.selfHealHealthGain=h.Health-record.health
  self:Stop("Healing confirmed while using bandage: "..tostring(h.Health).." HP"); return
 end
 if not state.alive or state.role~="Survivors" or not state.roundActive or state.lock or state.healLocked or h.Health>=h.MaxHealth then
  self:Stop(state.lock or (state.healLocked and "Native healing is locked") or "Self-heal requires an injured, active survivor"); return
 end
 if record then
  if record.character~=ch or h.MoveDirection.Magnitude>.05 then self:Stop("Self-heal interrupted by movement or respawn"); return end
  if record.kind=="bandage" then
   if not record.controller.tool:IsDescendantOf(ch) or not record.controller.isAiming then self:Stop("Bandage action ended without confirmed healing"); return end
   if os.clock()-record.started>25 then self:Stop("No server-confirmed bandage heal within 25 seconds"); return end
   A.status.action="Using equipped bandage"; return
  end
  local progress=ch:GetAttribute("HealProgress") or 0
  if progress>record.progress or h.Health>record.health then
   record.lastProgress=os.clock(); record.progress=progress; record.health=h.Health
   A.metrics.selfHealProgress=progress; A.status.result=string.format("Observed self-heal %.1f%%",progress)
  end
  if progress>=math.min(C.selfHealHandoff,93) then self:Stop("Recovery prepared — a teammate must finish the heal"); return end
  if os.clock()-record.lastProgress>3 then self:Stop("No server healing progress; self-heal was not accepted or has reached its native cap"); return end
  if not record.ctx.script:GetAttribute("isHealing") and os.clock()-record.started>.8 then self:Stop("Native self-heal ended"); return end
  A.status.action="Preparing self-heal"; return
 end
 if state.busy then A.status.waiting="Finish the current action before self-healing"; return end
 local bandage=A.adapter.bandage
 if bandage and bandage.character==ch and bandage.tool:IsDescendantOf(ch) and not bandage.isAiming
  and h.Health>=bandage.config.minHealth and h.Health<=bandage.config.maxHealth
  and (bandage.tool:GetAttribute("charge") or 0)>0 and bandage:_canUse() then
  A:CancelMove(); stopRepair(); stopRecovery()
  bandage:_setAiming(true)
  if bandage.isAiming then
   A.bindHeal={kind="bandage",character=ch,controller=bandage,started=os.clock(),health=h.Health}
   A.status.action="Using equipped bandage"; return
  end
 end
 if not ctx or not A.adapter.actions then Adapter.RefreshRuntime(); return end
 A:CancelMove(); stopRepair(); stopRecovery()
 local actions=A.adapter.actions
 A.bindHeal={character=ch,ctx=ctx,root=root,actions=actions,started=os.clock(),lastProgress=os.clock(),progress=ch:GetAttribute("HealProgress") or 0,health=h.Health}
 local action=actions.startHeal(ctx,root)
 if action~="healing" then self:Stop("Native self-heal could not start"); return end
 ctx.state.activeMouseAction=action
end
A.selfHeal=SelfHeal
-- EXTRA_CONTROLLERS_END


local function playerStep()
    A:RunFeature("fullbright",{"fullbright"},function()
        if C.fullbright then own("lighting",Lighting,"Brightness",2); own("lighting",Lighting,"Ambient",Color3.new(1,1,1)); own("lighting",Lighting,"FogEnd",100000) end
    end,function() restore("lighting") end)
    A:RunFeature("fov",{"customFOV"},function()
        local camera=workspace.CurrentCamera
        if C.customFOV and camera then own("fov",camera,"FieldOfView",C.fov) end
    end,function() restore("fov") end)
end


function A:Set(key,value)
    local previous=C[key]
    if previous==nil then return end
    if type(previous)=="boolean" then value=value==true end
    if key=="speedBoost" then value=finiteNumber(value,1,1) end
    C[key]=value
    if not value and PerkBoosts then
        if key=="allPerkBoosts" then PerkBoosts.windows={}
        elseif key:sub(1,5)=="perk:" then PerkBoosts.windows[key]=nil end
    end
    if value then self:ClearFailure(key) end
    if self.controls[key] and self.controls[key]:Get()~=value then self.controls[key]:Set(value) end
    if key=="forceSpeed" or key=="forceMovement" or key=="forceSlow" or key=="forceBonuses" or key=="allPerkBoosts" or key=="speedBoost" or key:sub(1,5)=="perk:" then
        if value then self:RunFeature("runtime",{},Adapter.RefreshRuntime,nil,4) end
        self:RunFeature("forceContext",self:ForceKeys(),function() Force:Step() end,function() Force:Stop() end)
    end
    if key=="unlockCursor" then Cursor.menuSuppressed=not value; Cursor:Step() end
    if key=="silentAim" then
        if value then local good,why=Items:InstallSilent(); if not good then C.silentAim=false; if self.controls.silentAim then self.controls.silentAim:Set(false) end; notify(why) end
        elseif not C.aim then Items:RemoveSilent() end
    end
    if key=="aim" then
        if value then local good,why=Items:InstallSilent(); if not good then A.status.waiting=why end
        elseif not C.silentAim then Items:RemoveSilent() end
    end
    if key=="noItemCooldowns" and not value then Items:StopCooldowns() end
    if key=="infiniteItems" and not value then Items:StopReserves() end
    if key=="freeCamera" and not value then CameraControl:Stop() end
    if key=="antiRubber" then
        Motion:Stop()
        if value then self:RunFeature("antiRubber",{"antiRubber"},function() Motion:Step() end,function() Motion:Stop() end) end
        self:RunFeature("forceContext",self:ForceKeys(),function() Force:Step() end,function() Force:Stop() end)
    end
    if key=="instantFlick" and not value then restore("flick") end
    if key=="selfHeal" and not value then SelfHeal:Stop() end
    if key=="autoRepair" and not value then stopRepair() end
    if key=="selfRecover" and not value then stopRecovery() end
    if key=="autoQTE" and not value then self.qteLatch=nil end
    if key=="pumpkinFarm" then
        self.pumpkinAttempt=nil; self.pumpkinTarget=nil; self.moveResult=nil
        if self.move and self.move.owner=="pumpkin" then self:CancelMove() end
    end
    if key=="lowGraphics" then graphics(value) end
    if key=="fullbright" and not value then restore("lighting") end
    if key=="customFOV" and not value then restore("fov") end
end
function A:StopAll()
    self.generation=self.generation+1
    for key,value in C do if type(value)=="boolean" then C[key]=false end end
    C.speedBoost=1; if self.speedControl then self.speedControl:Set(1) end
    Force:Stop()
    PerkBoosts:Reset(); SelfHeal:Stop(); Items:Stop(); Items:RemoveSilent(); CameraControl:Stop(); Motion:Stop()
    Cursor.menuSuppressed=true; Cursor:Stop()
    self:CancelMove(); stopRepair(); stopRecovery()
    if self.interactionLease then pcall(interactionInput,false,self.interactionLease.owner) end
    for _,lease in self.clickLeases do releaseClick(lease) end
    self.pumpkinAttempt=nil; self.pumpkinTarget=nil; self.qteLatch=nil
    self.graphicsGeneration=(self.graphicsGeneration or 0)+1
    for group in self.changes do restore(group) end
    clearESP(); self.status.action="Disabled"; self.status.waiting="Stop All"
    for _,control in self.controls do pcall(function() control:Set(false) end) end
    self:ClearFailure()
    if self.window and self.window:GetGui().Enabled then Cursor.menuSuppressed=false; Cursor:Step() end
end
function A:Unload()
    if not self.alive then return end
    self:StopAll(); self.alive=false
    Cursor:Stop()
    for _,c in self.connections do c:Disconnect() end
    self.connections={}
    if self.overlay then self.overlay:Destroy() end
    if self.cursorGui then self.cursorGui:Destroy() end
    if self.cursorBinding then Run:UnbindFromRenderStep(self.cursorBinding); self.cursorBinding=nil end
    if self.cursorEarlyBinding then Run:UnbindFromRenderStep(self.cursorEarlyBinding); self.cursorEarlyBinding=nil end
    if self.cameraBinding then Run:UnbindFromRenderStep(self.cameraBinding); self.cameraBinding=nil end
    if self.menuBinding then CAS:UnbindAction(self.menuBinding); self.menuBinding=nil end
    if env.SmugVD==self then env.SmugVD=nil end
    if self.window then local window=self.window; self.window=nil; window:Kill() end
end
function A:Refresh()
    self:ClearFailure()
    Adapter.RefreshWorld(); Adapter.RefreshRuntime()
end
function A:RestoreHeldSprint()
    -- Native InputEnded ignores processed input, so RightShift-up can cancel
    -- LeftShift sprint even though the menu consumed RightShift-down.
    local name=LocalPlayer:GetAttribute("kb_sprint") or "LeftShift"
    if name=="RightShift" then return end
    local valid,key=pcall(function() return Enum.KeyCode[name] end)
    if not valid or not UIS:IsKeyDown(key) then return end
    local state,ch=Adapter.State()
    if not Rules.canSprint(state) then return end
    local movement=self.adapter.movement
    if not movement or movement.character~=ch or movement.isShiftHeld then return end
    movement.isShiftHeld=true
    movement:_syncSprint()
    movement.runevent:FireServer(ch,true)
    movement:_checkConditions()
end
function A:Snapshot()
    local flags={} for key,value in C do if type(value)=="boolean" then flags[key]=value end end
    local targets=PerkBoosts:Targets()
    local perkSummary={role=targets.role,count=targets.count,speed=targets.speed,walk=targets.walk,vault=targets.vault,crouch=targets.crouch,active=table.clone(targets.active)}
    return {version=self.version,alive=self.alive,config=flags,status=table.clone(self.status),metrics=table.clone(self.metrics),
        generators=#self.generators,points=#self.points,pumpkins=#self.pumpkins,moving=self.move~=nil,
        heldKeys=table.clone(self.heldKeys),repairAdapter=self.adapter.repair~=nil,parryAdapter=self.adapter.parry~=nil,
        recovering=self.recovery~=nil,pumpkinPending=self.pumpkinAttempt~=nil,lastError=self.lastError,
        interactionHeld=self.interactionLease~=nil,clicksPending=next(self.clickLeases)~=nil,localForceActive=Force:Active(),
        role=playerRole(LocalPlayer),perkTargets=perkSummary,cursorUnlocked=Cursor.original~=nil,
        failures=self.failures,selfHealActive=self.bindHeal~=nil,corrections=Motion.corrections,speedBoost=C.speedBoost,motion=Motion:Snapshot()}
end


local ok,err=xpcall(function()
    A.overlay=Instance.new("Folder"); A.overlay.Name="SmugVD_Overlay"; A.overlay.Parent=workspace
    A:Refresh()
    PerkBoosts:Refresh()
    local win=Library:CreateWindow("Smug | Violence District",{Width=640,Height=560,ToggleKey=Enum.KeyCode.Insert,
        AccentColor=Color3.fromRGB(90,120,165),AccentLightColor=Color3.fromRGB(124,150,188),SectionHeaderColor=Color3.fromRGB(29,33,40),
        ConfigKey="SmugVD_supported_20261107",ConfigAutoSave=false,OnClose=function() A:Unload() end})
    A.window=win; win:SetConfig({},false)
    -- Sink RightShift before the native sprint binding; Insert remains a fallback.
    A.menuBinding="SmugVD_Menu_"..tostring(os.clock())
    CAS:BindActionAtPriority(A.menuBinding,function(_,state)
        if not A.alive or UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
        if state==Enum.UserInputState.Begin then win:GetGui().Enabled=not win:GetGui().Enabled end
        if state==Enum.UserInputState.End then task.defer(function()
            if A.alive then A:RunFeature("menuSprint",{},function() A:RestoreHeldSprint() end) end
        end) end
        return Enum.ContextActionResult.Sink
    end,false,Enum.ContextActionPriority.High.Value+1,Enum.KeyCode.RightShift)
    -- Only this gameplay window belongs in normal player UI. The shared library
    -- continues to own its bootstrap and licensing UI independently.
    win:GetGui().Parent=LocalPlayer.PlayerGui
    win:GetGui().ResetOnSpawn=false
    -- SmugLib sizes this window against the full camera viewport.
    win:GetGui().IgnoreGuiInset=true
    win:GetGui().DisplayOrder=100
    A.cursorGui=Instance.new("ScreenGui"); A.cursorGui.Name="SmugVD_Cursor"; A.cursorGui.ResetOnSpawn=false
    A.cursorGui.IgnoreGuiInset=true; A.cursorGui.Parent=LocalPlayer.PlayerGui
    local modal=Instance.new("TextButton"); modal.Name="CursorRelease"; modal.Text=""
    modal.Size=UDim2.fromOffset(1,1); modal.BackgroundTransparency=1; modal.Modal=true; modal.Visible=false
    modal.Parent=A.cursorGui; Cursor.modal=modal
    A.cursorBinding="SmugVD_Cursor_"..tostring(os.clock())
    A.cursorEarlyBinding=A.cursorBinding.."_BeforeCamera"
    Run:BindToRenderStep(A.cursorEarlyBinding,Enum.RenderPriority.Camera.Value-2,function()
        A:RunFeature("cursor",{"unlockCursor"},function() Cursor:Step() end,function() Cursor.menuSuppressed=true; Cursor:Stop() end)
    end)
    Run:BindToRenderStep(A.cursorBinding,Enum.RenderPriority.Last.Value+1,function()
        A:RunFeature("cursor",{"unlockCursor"},function() Cursor:Step() end,function() Cursor.menuSuppressed=true; Cursor:Stop() end)
    end)
    A.cameraBinding="SmugVD_Camera_"..tostring(os.clock())
    Run:BindToRenderStep(A.cameraBinding,Enum.RenderPriority.Last.Value-1,function(dt)
        if not A.alive then return end
        A:RunFeature("freeCamera",{"freeCamera"},function() CameraControl:Step() end,function() CameraControl:Stop() end)
        A:RunFeature("aim",{"aim","flashlightAim"},function() aimStep(dt) end)
    end)
    connect(win:GetGui():GetPropertyChangedSignal("Enabled"),function()
        if win:GetGui().Enabled then Cursor.menuSuppressed=false end
        A:RunFeature("cursor",{"unlockCursor"},function() Cursor:Step() end,function() Cursor.menuSuppressed=true; Cursor:Stop() end)
    end)
    connect(UIS.WindowFocusReleased,function() Cursor.focused=false; Cursor:Reset() end)
    connect(UIS.WindowFocused,function() Cursor.focused=true; Cursor:Step() end)
    -- PUBLIC_UI_BEGIN: ordering and names are shared with the release guide.
    A.ui={tabs={},sections={},controls={}}
    local currentFolder,currentPage,currentSection
    local function page(title)
        currentPage=title; currentFolder=win:Folder(title)
        table.insert(A.ui.tabs,title); A.ui.sections[title]={}
    end
    local function group(title)
        currentSection=title; table.insert(A.ui.sections[currentPage],title)
        return currentFolder:Section(title)
    end
    local function toggle(s,key,title)
        local control=s:Toggle(title,function(on)
            if A.ready and A.alive then
                if on then A:ClearFailure(key) end
                A:RunFeature("setting:"..key,{key},function() A:Set(key,on) end,function() A:Set(key,false) end)
            end
        end,false)
        A.controls[key]=control
        A.ui.controls[key]={page=currentPage,section=currentSection,label=title}
    end

    page("Assist")
    local section=group("Session")
    A.summaryLabel=section:Label("Ready — features start off")
    section:Button("Stop all",function() A:StopAll() end)
    section=group("Generators")
    toggle(section,"autoRepair","Repair nearby generators")
    toggle(section,"autoQTE","Auto skill checks")
    section=group("Recovery")
    A.healBind=section:Bind("Prepare self-heal / cancel",Enum.KeyCode.H,function()
        if A.ready and A.alive then SelfHeal:Toggle() end
    end)
    section:Label("Uses an equipped bandage when eligible. Otherwise prepares native recovery up to 93%; a teammate must finish.")
    toggle(section,"selfRecover","Auto recover when downed")
    section:Button("Cancel recovery",function() SelfHeal:Stop("Self-heal cancelled") end)
    section=group("Seasonal")
    toggle(section,"pumpkinFarm","Pumpkin farm")

    page("Player")
    section=group("Movement")
    A.speedControl=section:Slider("Speed multiplier",1,5,1,function(value)
        if A.ready and A.alive then A:Set("speedBoost",value) end
    end,.05)
    toggle(section,"instantFlick","Instant turn & aim")
    toggle(section,"antiRubber","Anti-rubberband stabilization")
    section:Label("Adapts all local movement overrides and yields to native locks. Server corrections may still occur.")
    A.motionLabel=section:Label("Stabilization: Disabled")
    A.movementLabel=section:Label("Speed x1.00")
    section=group("Camera")
    toggle(section,"freeCamera","Free camera rotation")
    toggle(section,"customFOV","Custom field of view")
    section:Slider("Field of view",50,110,C.fov,function(v) C.fov=v end,1)
    section=group("Cursor")
    toggle(section,"unlockCursor","Unlock cursor")
    section:Button("Restore cursor",function() A:Set("unlockCursor",false); Cursor.menuSuppressed=true; Cursor:Stop() end)
    section=group("Navigation")
    section:Button("Go to nearest generator",function()
        local _,_,root=character(); if not root then return end
        local target,distance
        for _,point in A.points do
            if point.Parent and point:GetAttribute("IsRepairing")~=true and not Tags:HasTag(point.Parent,"Blocked") then
                local d=(point.Position-root.Position).Magnitude
                if not distance or d<distance then target=point; distance=d end
            end
        end
        if target then A:Travel(target.Position) else notify("No available generator point") end
    end)
    section:Button("Save position",function() local _,_,root=character(); if root then A.savedPosition=root.Position; notify("Position saved") end end)
    section:Button("Return to saved position",function() if A.savedPosition then A:Travel(A.savedPosition) else notify("Save a position first") end end)
    section:Button("Cancel navigation",function() A:CancelMove("Cancelled") end)
    section=group("Local movement overrides")
    toggle(section,"forceMovement","Ignore local movement locks")
    toggle(section,"forceSlow","Reduce local movement debuffs")

    page("Combat")
    section=group("Flashlight")
    toggle(section,"flashlightAim","Head aim")
    A.flashlightBind=section:Bind("Hold key",Enum.UserInputType.MouseButton2,function() end)
    section=group("Camera aim")
    toggle(section,"aim","Aim assist — hold LeftAlt")
    section=group("Item aim")
    toggle(section,"silentAim","Silent item aim")
    section:Label("The Veil spear, Twist of Fate and Holy Water.\nSpear: equip with RMB, charge and release LMB.\nCamera aim: hold LeftAlt. Close or minimize the menu to aim.")
    section=group("Parry")
    toggle(section,"autoParry","Auto parry")
    section:Textbox("Threat range (studs; 0 = all)",function(value) C.parryRange=finiteNumber(value,C.parryRange,0) end,tostring(C.parryRange))
    section=group("Tracking")
    section:Slider("Aim radius (px)",30,600,C.aimRadius,function(v) C.aimRadius=v end,10)
    section:Slider("Tracking speed",1,40,C.smooth,function(v) C.smooth=v end,1)
    section:Slider("Lead time (s)",0,.5,C.prediction,function(v) C.prediction=v end,.01)
    section=group("Projectile tuning")
    toggle(section,"ballistic","Ballistic prediction")
    section:Slider("Projectile speed",25,300,C.projectileSpeed,function(v) C.projectileSpeed=v end,1)
    section:Slider("Gravity",0,196.2,C.projectileGravity,function(v) C.projectileGravity=v end,.1)

    page("Visuals")
    section=group("Overlays")
    toggle(section,"esp","Player ESP")
    toggle(section,"objectESP","Generator ESP")
    A.espControls={}
    local function displayToggle(s,key,title)
        local control=s:Toggle(title,function(on) if A.ready and A.alive then ESP.options[key]=on==true end end,ESP.options[key])
        A.espControls[key]=control
        local saved=control:Get(); if type(saved)=="boolean" then ESP.options[key]=saved end
    end
    section=group("ESP / Players")
    for _,row in {{"survivors","Show survivors"},{"killers","Show killer"},{"names","Names"},{"roles","Roles"},
        {"health","Health values"},{"healthBar","Health bars"},{"distance","Distance"},{"status","Action / status"}} do displayToggle(section,row[1],row[2]) end
    section=group("ESP / Generators")
    for _,row in {{"generatorProgress","Repair progress"},{"generatorRepairers","Repairer count"},{"completedGenerators","Show completed generators"}} do displayToggle(section,row[1],row[2]) end
    section=group("ESP / Appearance")
    for _,row in {{"highlight","Highlights"},{"fill","Highlight fill"},{"outline","Highlight outline"},{"labels","Text labels"},{"throughWalls","Visible through walls"}} do displayToggle(section,row[1],row[2]) end
    section:Textbox("Maximum distance (0 = unlimited)",function(v) ESP.options.maxDistance=finiteNumber(v,ESP.options.maxDistance,0) end,"0")
    section:Slider("Text size",10,24,ESP.options.textSize,function(v) ESP.options.textSize=v end,1)
    section:Slider("Fill transparency",0,1,ESP.options.fillTransparency,function(v) ESP.options.fillTransparency=v end,.05)
    section:Slider("Outline transparency",0,1,ESP.options.outlineTransparency,function(v) ESP.options.outlineTransparency=v end,.05)
    section:Slider("Label height",0,7,ESP.options.labelHeight,function(v) ESP.options.labelHeight=v end,.25)
    local colors={Red=Color3.fromRGB(255,83,92),Green=Color3.fromRGB(80,225,175),Gold=Color3.fromRGB(255,208,82),
        Blue=Color3.fromRGB(100,170,255),Purple=Color3.fromRGB(190,130,255),White=Color3.new(1,1,1)}
    for _,row in {{"survivorColor","Survivor color","Green"},{"killerColor","Killer color","Red"},{"generatorColor","Generator color","Gold"}} do
        local key=row[1]
        section:Dropdown(row[2],{"Red","Green","Gold","Blue","Purple","White"},function(v) ESP.options[key]=colors[v] or ESP.options[key] end,row[3])
    end
    section=group("Lighting & effects")
    toggle(section,"fullbright","Fullbright")
    toggle(section,"lowGraphics","Reduce visual effects")

    page("Perks")
    section=group("Timed effects")
    toggle(section,"allPerkBoosts","Enable supported perk effects")
    A.perkEffectsLabel=section:Label("Active effects: none")
    section=group("Perk library")
    local descriptions,descriptionEntries={},{}
    local defaultDescription
    local preferredRole=playerRole(LocalPlayer)=="Killer" and "Killer" or "Survivor"
    for _,entry in PerkBoosts.catalog do
        local title=entry.role.." / "..entry.name
        table.insert(descriptions,title); descriptionEntries[title]=entry
        if not defaultDescription and entry.role==preferredRole then defaultDescription=title end
    end
    defaultDescription=defaultDescription or descriptions[1]
    local selectedDescription
    local function showPerk(title)
        selectedDescription=descriptionEntries[title]
        if selectedDescription and A.perkDescriptionLabel then
            A.perkDescriptionLabel:SetText(selectedDescription.description.."\n\n"..
                (selectedDescription.effects and "Support: local component with native triggers." or "Support: native owned perk."))
        end
    end
    A.perkDescriptionDropdown=section:Dropdown("Browse perks",descriptions,showPerk,defaultDescription)
    A.perkDescriptionLabel=section:Label("")
    showPerk(defaultDescription)
    section:Button("Select for loadout",function()
        if not selectedDescription or not A.ready then return end
        A:SetEquipmentSelection(selectedDescription.role,selectedDescription.name)
        notify("Loadout selection: "..selectedDescription.name)
    end)
    section=group("Loadout")
    C.equipmentRole=preferredRole
    local function catalogNames()
        local names={} for name in perkDefinitions(C.equipmentRole) do table.insert(names,name) end
        table.sort(names); return names
    end
    local names=catalogNames(); C.selectedPerk=names[1] or ""
    local perkDropdown
    A.equipmentRoleDropdown=section:Dropdown("Role",{"Survivor","Killer"},function(role)
        C.equipmentRole=role; A.perkQuote=nil
        if perkDropdown then
            local options=catalogNames(); perkDropdown:SetOptions(options)
            C.selectedPerk=options[1] or ""; perkDropdown:Set(C.selectedPerk)
        end
    end,C.equipmentRole)
    perkDropdown=section:Dropdown("Perk",names,function(name) C.selectedPerk=name; A.perkQuote=nil end,C.selectedPerk)
    A.equipmentPerkDropdown=perkDropdown
    function A:SetEquipmentSelection(role,name)
        C.equipmentRole=role; self.perkQuote=nil
        self.equipmentRoleDropdown:Set(role)
        local options=catalogNames(); self.equipmentPerkDropdown:SetOptions(options)
        C.selectedPerk=table.find(options,name) and name or options[1] or ""
        self.equipmentPerkDropdown:Set(C.selectedPerk)
    end
    section:Dropdown("Slot",{"1","2","3"},function(slot) C.perkSlot=tonumber(slot) end,"1")
    A.equippedLabel=section:Label("Inspect to read the equipped slots")
    A.perkInfoLabel=section:Label("Inspect a perk for its price and ownership")
    section:Button("Inspect perk & price",function() A:EquipmentOperation("inspect") end)
    section:Button("Equip owned perk",function() A:EquipmentOperation("equip") end)
    section:Button("Fill empty slots",function() A:EquipAvailablePerks() end)
    section:Button("Buy quoted perk",function() A:EquipmentOperation("buy") end)
    section=group("Collection")
    A.ownedLabel=section:Label("Refresh to read owned perks")
    section:Button("Refresh owned perks",function() A:ReadOwnedPerks() end)
    for _,role in {"Survivor","Killer"} do
        for _,category in {"Movement","Awareness"} do
            section=group(role.." / "..category)
            for _,entry in PerkBoosts.catalog do
                local e=entry.effects
                if entry.role==role and e then
                    local movement=e.speed or e.walk or e.vault or e.crouch
                    if (category=="Movement" and movement) or (category=="Awareness" and not movement) then
                        toggle(section,entry.key,entry.name)
                    end
                end
            end
        end
    end

    page("Items")
    section=group("Equipment")
    local itemNames={}
    for _,definition in RS.Items:GetChildren() do if definition:IsA("Decal") then table.insert(itemNames,definition.Name) end end
    table.sort(itemNames); C.selectedItem=itemNames[1] or ""
    section:Dropdown("Item",itemNames,function(name) C.selectedItem=name end,C.selectedItem)
    section:Button("Equip owned item",function() A:EquipOwnedItem() end)
    section:Button("Use equipped item",function()
        local allowed,why,ch=Adapter.CanAct(true)
        if not allowed then notify(why); return end
        if not ch:FindFirstChildOfClass("Tool") and not ch:FindFirstChild("Flashlight") then notify("No item is equipped") return end
        A:RunFeature("manualItem",{},function()
            local sent,reason=pressBinding("item"); if not sent then notify(reason) end
        end)
    end)
    section:Button("Open game inventory",function() A:OpenNativeMenu("Inventory") end)
    section:Button("Open game shop",function() A:OpenNativeMenu("Shop") end)
    A.boostLabel=section:Label("XP boost: inactive")
    section=group("Local overrides")
    toggle(section,"noItemCooldowns","Reset client cooldowns")
    toggle(section,"infiniteItems","Keep client reserves")
    section:Label("Client only. Server cooldowns and consumption still apply.")

    page("Settings")
    section=group("Controls")
    section:Label("RightShift / Insert — menu\nF8 — cursor\nLeftAlt — camera aim\nEnd — stop all\nFlashlight and recovery keys can be changed in their categories.")
    section=group("Session")
    section:Button("Refresh game data",function() A:Refresh(); notify("Game data refreshed") end)
    section:Button("Stop all",function() A:StopAll() end)
    section:Button("Unload script",function() A:Unload() end)
    section=group("About")
    section:Label("Smug | Violence District\nVersion "..A.version)
    section=group("Diagnostics")
    A.statusLabel=section:Label("No activity")
    A.itemLabel=section:Label("No item redirects")
    A.errorLabel=section:Label("No errors")
    section:Button("Clear errors",function() A:ClearFailure(); notify("Errors cleared. Re-enable a paused feature to retry.") end)
    -- PUBLIC_UI_END

    connect(UIS.InputBegan,function(input,processed)
        if UIS:GetFocusedTextBox() then return end
        if input.KeyCode==Enum.KeyCode.End then A:StopAll()
        elseif input.KeyCode==Enum.KeyCode.F8 then
            local unlocked=Cursor.original~=nil
            A:Set("unlockCursor",not unlocked)
        elseif processed then return end
    end)
    local function reduceAdded(obj)
        if C.lowGraphics then A:RunFeature("graphics",{"lowGraphics"},function() reduce(obj) end,function() restore("graphics") end) end
    end
    connect(workspace.DescendantAdded,reduceAdded)
    connect(Lighting.DescendantAdded,reduceAdded)
    connect(LocalPlayer.CharacterRemoving,function()
        Force:Stop()
        PerkBoosts:Reset(); SelfHeal:Stop(); Items:Stop(); CameraControl:Stop(); Motion:Stop(); restore("flick")
        A.generation=A.generation+1; A:CancelMove(); stopRepair(); stopRecovery()
        A.pumpkinAttempt=nil; A.pumpkinTarget=nil; A.adapter={}; A.qteLatch=nil
        for _,lease in A.clickLeases do releaseClick(lease) end
    end)
    connect(LocalPlayer.CharacterAdded,function() A.adapter={}; A.nextRuntime=0 end)
    connect(LocalPlayer:GetPropertyChangedSignal("Team"),function()
        Force:Stop(); A.generation=A.generation+1
        PerkBoosts:Reset(); SelfHeal:Stop(); Items:Stop(); CameraControl:Stop(); Motion:Stop(); restore("flick")
        A:CancelMove(); stopRepair(); stopRecovery()
        A.pumpkinAttempt=nil; A.pumpkinTarget=nil; A.adapter={}; A.nextRuntime=0
    end)
    connect(RS.Remotes.Killers.Veil.SpearState.OnClientEvent,function(kind,packet)
        if type(packet)~="table" then return end
        if kind=="launch" and packet.Source==LocalPlayer.Character then
            A.metrics.veilLaunches=(A.metrics.veilLaunches or 0)+1
            A.status.result="Server confirmed spear projectile #"..tostring(packet.Sequence)
        elseif kind=="reject" and Items.charge and packet.Sequence==Items.charge.sequence then
            A.metrics.veilRejected=(A.metrics.veilRejected or 0)+1
            A.status.waiting="Spear request rejected by the game"
        end
    end)
    for _,entry in {{RS.Remotes.Shop,"PurchasePerk","Survivor"},{RS.Remotes.ShopKillers,"PurchaseKillerPerk","Killer"}} do
        local remote=entry[1]:FindFirstChild(entry[2]); local role=entry[3]
        if remote then connect(remote.OnClientEvent,function(success,message,name)
            local pending=A.purchaseUncertain
            if pending and pending.role==role and pending.name==name then
                if success==false then A.purchaseUncertain=nil; notify("Purchase rejected: "..tostring(message)) end
                A.status.result="Purchase response: "..tostring(message)
            end
        end) end
    end
    local parryResult=RS.Remotes.Items:FindFirstChild("Parrying Dagger")
    if parryResult and parryResult:FindFirstChild("parryResult") then
        connect(parryResult.parryResult.OnClientEvent,function(success,_,_,_,ch)
            if ch==LocalPlayer.Character and success==true then
                A.metrics.parrySuccess=A.metrics.parrySuccess+1; A.status.result="Server reported a successful parry result"
                PerkBoosts:Event("parry")
            end
        end)
    end
    local function listenEvent(parent,name,event,filter)
        local object=parent and parent:FindFirstChild(name)
        if object and object:IsA("BindableEvent") then connect(object.Event,function(...)
            if filter and not filter(...) then return end
            A:RunFeature("perkEvents",A:PerkKeys(),function() PerkBoosts:Event(event) end)
        end) end
    end
    listenEvent(RS.Remotes.Perks,"Great Collapse","stun")
    listenEvent(RS.Remotes.Generator,"allgendone","gates")
    connect(Tags:GetInstanceAddedSignal("Blocked"),function(obj)
        local window=Tags:HasTag(obj,"window") and obj or obj.Parent and Tags:HasTag(obj.Parent,"window") and obj.Parent
        if not window then for _,candidate in Tags:GetTagged("window") do
            if candidate:IsDescendantOf(obj) then window=obj; break end
        end end
        if not window then return end
        local _,_,root=character(); local part=window:IsA("BasePart") and window or window:FindFirstChildWhichIsA("BasePart",true)
        if root and part then PerkBoosts:Event("windowBlocked",{distance=(root.Position-part.Position).Magnitude}) end
    end)


    local accumulator=0
    connect(Run.PreSimulation,function()
        if not A.alive then return end
        A:RunFeature("perkEvents",A:PerkKeys(),function() PerkBoosts:Observe() end,function() PerkBoosts:Reset() end)
        A:RunFeature("antiRubber",{"antiRubber"},function() Motion:Step() end,function() Motion:Stop() end)
        A:RunFeature("forceContext",A:ForceKeys(),function() Force:Step() end,function() Force:Stop() end)
        A:RunFeature("instantFlick",{"instantFlick"},function()
            if C.instantFlick then
                A.turnModule=A.turnModule or require(RS.Modules.Survivors.SurvivorMovement)
                own("flick",A.turnModule,"BODY_TURN_TIME",.00001)
            end
        end,function() restore("flick") end)
    end)
    connect(Run.RenderStepped,function(dt)
        if not A.alive then return end
        A:RunFeature("autoQTE",{"autoQTE"},qteStep,function() A.qteLatch=nil end)
        playerStep()
        A:RunFeature("navigation",A.move and A.move.owner=="pumpkin" and {"pumpkinFarm"} or {},travelStep,function()
            A:CancelMove("Navigation failed; other features remain enabled")
        end)
        accumulator=accumulator+dt
        if accumulator<0.15 then return end
        accumulator=0
            if os.clock()>(A.nextWorld or 0) then
                A.nextWorld=os.clock()+2
                A:RunFeature("world",{},function()
                    Adapter.RefreshWorld()
                    for point,expires in A.blacklist do if expires<os.clock() or not table.find(A.pumpkins,point) then A.blacklist[point]=nil end end
                end,nil,2)
            end
            if os.clock()>(A.nextRuntime or 0) then
                A.nextRuntime=os.clock()+4
                A:RunFeature("runtime",{},function()
                local ctx=A.adapter.repair
                local movement=A.adapter.movement
                local survivor=LocalPlayer.Team and LocalPlayer.Team.Name=="Survivors"
                local killer=A.adapter.killer
                local needForce=Force:Active() and ((survivor and (not movement or movement.character~=LocalPlayer.Character))
                    or (playerRole(LocalPlayer)=="Killer" and (not killer or killer.character~=LocalPlayer.Character)))
                local needAction=(C.autoRepair or C.selfRecover or C.selfHeal or C.pumpkinFarm) and (not ctx or ctx.character~=LocalPlayer.Character)
                local parry=A.adapter.parry
                local needParry=C.autoParry and (not parry or parry.character~=LocalPlayer.Character)
                if needAction or needParry or needForce then Adapter.RefreshRuntime() end
                end,nil,4)
            end
            A:RunFeature("items",{"noItemCooldowns","infiniteItems"},function() Items:Step() end,function() Items:Stop() end)
            A:RunFeature("selfHeal",{"selfHeal"},function() SelfHeal:Step() end,function() SelfHeal:Stop() end)
            A:RunFeature("selfRecover",{"selfRecover"},recoveryStep,stopRecovery)
            A:RunFeature("pumpkinFarm",{"pumpkinFarm"},pumpkinStep,function()
                if A.move and A.move.owner=="pumpkin" then A:CancelMove() end
                A.pumpkinAttempt=nil; A.pumpkinTarget=nil
            end)
            A:RunFeature("autoRepair",{"autoRepair"},repairStep,stopRepair)
            A:RunFeature("autoParry",{"autoParry"},parryStep)
            A:RunFeature("esp",{"esp","objectESP"},espStep,clearESP)
            A:RunFeature("diagnostics",{},function()
            A.statusLabel:SetText(string.format("%s | %s\n%s\nWaiting: %s\nPumpkins: %d / %d | Skill checks: %d | Parries: %d / %d",
                A.status.action,A.status.target,A.status.result,A.status.waiting,A.metrics.pumpkinsConfirmed,A.metrics.pumpkinAttempts,
                A.metrics.skillInputs,A.metrics.parrySuccess,A.metrics.parryRequests))
            local enabled=0
            for key,control in A.controls do
                if key~="ballistic" and C[key]==true then enabled+=1 end
            end
            if C.speedBoost>1 then enabled+=1 end
            A.summaryLabel:SetText(string.format("%s | %d enabled",playerRole(LocalPlayer),enabled))
            local ch,h,root=character()
            if ch then
                local velocity=root.AssemblyLinearVelocity
                A.movementLabel:SetText(string.format("Speed x%.2f | Moving %.1f studs/s",C.speedBoost,
                    Vector3.new(velocity.X,0,velocity.Z).Magnitude))
            else
                A.movementLabel:SetText(string.format("Speed x%.2f | Waiting for character",C.speedBoost))
            end
            local motion=Motion:Snapshot()
            A.motionLabel:SetText(string.format("Stabilization: %s | Boost strength %.0f%% | Corrections %d\n%s%s",
                motion.state,motion.factor*100,motion.corrections,motion.reason,
                motion.cooldown>0 and string.format(" (%.1fs)",motion.cooldown) or ""))
            local boost=LocalPlayer:GetAttribute("XPBoostRemaining")
            A.boostLabel:SetText(type(boost)=="number" and boost>0 and
                string.format("XP boost: %dm %02ds",math.floor(boost/60),math.floor(boost%60)) or "XP boost: inactive")
            local targets=PerkBoosts:Targets()
            local active={}
            for i=1,math.min(#targets.active,3) do table.insert(active,targets.active[i]) end
            local effects=#active>0 and table.concat(active,", ") or "none"
            if #targets.active>3 then effects..=" +"..(#targets.active-3) end
            A.perkEffectsLabel:SetText(targets.role.." | Active effects: "..effects)
            A.itemLabel:SetText(string.format("Aim redirects: %d | Confirmed spears: %d | Rejected: %d\nMovement corrections: %d",
                A.metrics.silentRedirects or 0,A.metrics.veilLaunches or 0,A.metrics.veilRejected or 0,Motion.corrections or 0))
            local errors={}
            for id,failure in A.failures do table.insert(errors,id..": "..failure.message..(failure.cleanupError and "\nCleanup: "..failure.cleanupError or "")) end
            table.sort(errors)
            A.errorLabel:SetText(#errors>0 and table.concat(errors,"\n\n") or "No errors")
            end,nil,1)
    end)


    A.ready=true
    win:Notify("Ready. RightShift opens the menu. End stops all features.",5)
end,debug.traceback)
if not ok then A:Unload(); error(err,0) end
return A
