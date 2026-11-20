-- ================================
-- KONFIGURASI WARNA & NAMA
-- ================================
local Config = {
    Players = {
        Killer = { Color = Color3.fromRGB(255, 93, 108) },
        Survivor = { Color = Color3.fromRGB(64, 224, 255) }
    },
    Objects = {
        Generator = { Color = Color3.fromRGB(150, 0, 200) },
        Gate = { Color = Color3.fromRGB(255, 255, 255) },
        Pallet = { Color = Color3.fromRGB(74, 255, 181) },
        Window = { Color = Color3.fromRGB(74, 255, 181) },
        Hook = { Color = Color3.fromRGB(132, 255, 169) },
        Pumpkin = { Color = Color3.fromRGB(255, 150, 40) },
        Trap = { Color = Color3.fromRGB(255, 215, 0) } -- Emas/Kuning untuk Trap
    }
}

local MaskNames = {
    ["Richard"] = "Rooster", ["Tony"] = "Tiger", ["Brandon"] = "Panther",
    ["Cobra"] = "Cobra", ["Richter"] = "Rat", ["Rabbit"] = "Rabbit", ["Alex"] = "Chainsaw"
}

local MaskColors = {
    ["Richard"] = Color3.fromRGB(255, 0, 0), ["Tony"] = Color3.fromRGB(255, 255, 0),
    ["Brandon"] = Color3.fromRGB(160, 32, 240), ["Cobra"] = Color3.fromRGB(0, 255, 0),
    ["Richter"] = Color3.fromRGB(0, 0, 0), ["Rabbit"] = Color3.fromRGB(255, 105, 180),
    ["Alex"] = Color3.fromRGB(255, 255, 255)
}

-- ================================
-- SERVICE & VARIABEL GLOBAL
-- ================================
local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local Lighting            = game:GetService("Lighting")
local UserInputService    = game:GetService("UserInputService")
local Workspace           = game:GetService("Workspace")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService     = game:GetService("TeleportService")
local Teams               = game:GetService("Teams")
local StarterGui          = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local env         = getgenv and getgenv() or _G
if type(env.ViolenceDistrictUnload) == "function" then
    pcall(env.ViolenceDistrictUnload)
end

local ActiveGenerators = {}
local LastUpdateTick = 0
local LastFullESPRefresh = 0
local IndicatorGui = nil
local hidden = env.VD_HiddenState or false

local cfg = {
    PumpkinESP    = true,
    TrapESP       = true,
    AutoGenerator = true,
    AutoSolveTrap = true,
    KillAura      = true,
    SmartHitbox   = true,
}

local ESPObjects = setmetatable({}, { __mode = "k" })

local function registerESPObject(obj)
    if obj then ESPObjects[obj] = true end
end

-- ================================
-- FUNGSI UTILITY
-- ================================

local function GetGameValue(obj, name)
    if not obj then return nil end
    local attr = obj:GetAttribute(name)
    if attr ~= nil then return attr end
    local child = obj:FindFirstChild(name)
    if child then
        local success, val = pcall(function() return child.Value end)
        if success then return val end
    end
    return nil
end

local function ApplyHighlight(object, color)
    local h = object:FindFirstChild("H")
    if not h then
        h = Instance.new("Highlight")
        h.Name = "H"
        h.Adornee = object
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = object
        registerESPObject(object)
    end
    if h.FillColor ~= color then
        h.FillColor = color
        h.OutlineColor = color
        h.FillTransparency = 0.8
        h.OutlineTransparency = 0.3
        h.Enabled = not hidden
    end
end

local function CreateBillboardTag(text, color, size, textSize)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "BitchHook"
    billboard.AlwaysOnTop = true
    billboard.Size = size or UDim2.new(0, 120, 0, 30)
    billboard.Enabled = not hidden

    local label = Instance.new("TextLabel")
    label.Name = "BitchHook"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.Font = Enum.Font.GothamBold
    label.TextSize = textSize or 10
    label.TextWrapped = true
    label.RichText = true
    label.Parent = billboard

    return billboard
end

-- ================================
-- GUI SETUP
-- ================================

local function SetupGui()
    if PlayerGui:FindFirstChild("ChasedInds") then
        PlayerGui:FindFirstChild("ChasedInds"):Destroy()
    end
    IndicatorGui = Instance.new("ScreenGui")
    IndicatorGui.Name = "ChasedInds"
    IndicatorGui.IgnoreGuiInset = true
    IndicatorGui.DisplayOrder = 999
    IndicatorGui.Enabled = not hidden
    IndicatorGui.Parent = PlayerGui

    local crosshair = Instance.new("Frame")
    crosshair.Name = "Crosshair"
    crosshair.Size = UDim2.new(0, 6, 0, 6)
    crosshair.Position = UDim2.new(0.5, -3, 0.5, -3)
    crosshair.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    crosshair.BackgroundTransparency = 0
    crosshair.BorderSizePixel = 0
    crosshair.ZIndex = 9999
    crosshair.Parent = IndicatorGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = crosshair
end

-- ================================
-- PLAYER NAMETAG & ESP
-- ================================

local function updatePlayerNametag(player)
    if not IndicatorGui or not IndicatorGui.Parent then return end
    if not player.Character then return end

    local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not rootPart then return end

    local teamName = (player.Team and player.Team.Name:lower()) or ""
    local selectedKillerAttr = GetGameValue(player, "SelectedKiller")
    local rawMask = GetGameValue(player, "Mask") or GetGameValue(player.Character, "Mask")
    local isKnocked = GetGameValue(player.Character, "Knocked")
    local isHooked = GetGameValue(player.Character, "IsHooked")
    local isChased = GetGameValue(player.Character, "IsChased")
    local isKiller = teamName:find("killer") ~= nil

    local color = isKiller and Config.Players.Killer.Color or Config.Players.Survivor.Color
    if isHooked then
        color = Color3.fromRGB(255, 182, 193)
    elseif humanoid and humanoid.Health < humanoid.MaxHealth then
        color = isKnocked and Color3.fromRGB(200, 100, 0) or Color3.fromRGB(200, 200, 0)
    end

    local distance = 0
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        distance = math.floor((rootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude)
    end

    local displayName
    if isKiller then
        local killerName = selectedKillerAttr and tostring(selectedKillerAttr) or "Unknown"
        displayName = player.Name .. ":" .. killerName
    else
        displayName = player.Name
    end

    local billboard = rootPart:FindFirstChild("BitchHook")
    local nameText = displayName .. "\n[" .. distance .. " studs]"
    if not billboard then
        billboard = CreateBillboardTag(nameText, color)
        billboard.Adornee = rootPart
        billboard.Parent = rootPart
        registerESPObject(rootPart)
    else
        local lbl = billboard:FindFirstChild("BitchHook") or billboard:FindFirstChildOfClass("TextLabel")
        if lbl then
            lbl.Text = nameText
            lbl.TextColor3 = color
        end
    end

    ApplyHighlight(player.Character, color)

    local hasMask = false
    if isKiller and selectedKillerAttr and string.match(tostring(selectedKillerAttr):lower(), "masked") and rawMask then
        local searchMask = tostring(rawMask):lower()
        for key, name in pairs(MaskNames) do
            if key:lower() == searchMask then
                hasMask = true
                local maskBillboard = rootPart:FindFirstChild("MaskHook")
                if not maskBillboard then
                    maskBillboard = CreateBillboardTag(name, MaskColors[key] or Color3.new(1,1,1), UDim2.new(0, 100, 0, 20), 12)
                    maskBillboard.Name = "MaskHook"
                    maskBillboard.StudsOffset = Vector3.new(0, 3, 0)
                    maskBillboard.Adornee = rootPart
                    maskBillboard.Parent = rootPart
                    registerESPObject(rootPart)
                else
                    local lbl = maskBillboard:FindFirstChild("BitchHook") or maskBillboard:FindFirstChildOfClass("TextLabel")
                    if lbl then
                        lbl.Text = name
                        lbl.TextColor3 = MaskColors[key] or Color3.new(1,1,1)
                    end
                end
                break
            end
        end
    end
    if not hasMask then
        local maskBillboard = rootPart:FindFirstChild("MaskHook")
        if maskBillboard then maskBillboard:Destroy() end
    end

    local chasedLabel2D = IndicatorGui:FindFirstChild(player.Name .. "_Chased")
    if isChased then
        local ct3 = billboard:FindFirstChild("ChasedLabel")
        if not ct3 then
            ct3 = Instance.new("TextLabel", billboard)
            ct3.Name = "ChasedLabel"
            ct3.Size = UDim2.new(1, 0, 1, 0)
            ct3.Position = UDim2.new(0, 0, -1.2, 0)
            ct3.BackgroundTransparency = 1
            ct3.Font = Enum.Font.GothamBold
            ct3.TextSize = 24
        end
        ct3.Text = "!!"
        ct3.TextColor3 = color
        ct3.TextStrokeTransparency = 0

        if not chasedLabel2D then
            chasedLabel2D = Instance.new("TextLabel", IndicatorGui)
            chasedLabel2D.Name = player.Name .. "_Chased"
            chasedLabel2D.BackgroundTransparency = 1
            chasedLabel2D.Font = Enum.Font.GothamBold
            chasedLabel2D.TextSize = 24
            chasedLabel2D.TextStrokeTransparency = 0
            chasedLabel2D.AnchorPoint = Vector2.new(0.5, 0.5)
        end
        chasedLabel2D.Text = "!!"
        chasedLabel2D.TextColor3 = color

        local screenPos, onScreen = workspace.CurrentCamera:WorldToScreenPoint(rootPart.Position)
        if onScreen then
            chasedLabel2D.Visible = false
        else
            chasedLabel2D.Visible = true
            local viewportCenter = workspace.CurrentCamera.ViewportSize / 2
            local direction = Vector2.new(screenPos.X, screenPos.Y) - viewportCenter
            if screenPos.Z < 0 then direction = -direction end
            local maxScale = math.max(math.abs(direction.X) / (viewportCenter.X - 30), math.abs(direction.Y) / (viewportCenter.Y - 30))
            chasedLabel2D.Position = UDim2.new(0, viewportCenter.X + direction.X / (maxScale == 0 and 1 or maxScale),
                                                0, viewportCenter.Y + direction.Y / (maxScale == 0 and 1 or maxScale))
        end
    else
        if chasedLabel2D then chasedLabel2D:Destroy() end
        local ct3 = billboard:FindFirstChild("ChasedLabel")
        if ct3 then ct3:Destroy() end
    end

    local killerLabel2D = IndicatorGui:FindFirstChild(player.Name .. "_Killer")
    if isKiller then
        if not killerLabel2D then
            killerLabel2D = Instance.new("TextLabel", IndicatorGui)
            killerLabel2D.Name = player.Name .. "_Killer"
            killerLabel2D.BackgroundTransparency = 1
            killerLabel2D.Font = Enum.Font.GothamBold
            killerLabel2D.TextSize = 10
            killerLabel2D.TextStrokeTransparency = 0
            killerLabel2D.Size = UDim2.new(0, 120, 0, 30)
            killerLabel2D.RichText = true
            killerLabel2D.AnchorPoint = Vector2.new(0.5, 0.5)
        end
        killerLabel2D.Text = displayName .. "\n[" .. distance .. " studs]"
        killerLabel2D.TextColor3 = color

        local screenPos, onScreen = workspace.CurrentCamera:WorldToScreenPoint(rootPart.Position)
        if not onScreen then
            killerLabel2D.Visible = true
            local viewportCenter = workspace.CurrentCamera.ViewportSize / 2
            local direction = Vector2.new(screenPos.X, screenPos.Y) - viewportCenter
            if screenPos.Z < 0 then direction = -direction end
            local maxScale = math.max(math.abs(direction.X) / (viewportCenter.X - 30), math.abs(direction.Y) / (viewportCenter.Y - 30))
            killerLabel2D.Position = UDim2.new(0, viewportCenter.X + direction.X / (maxScale == 0 and 1 or maxScale),
                                                0, viewportCenter.Y + direction.Y / (maxScale == 0 and 1 or maxScale))
        else
            killerLabel2D.Visible = false
        end
    elseif killerLabel2D then
        killerLabel2D:Destroy()
    end
end

-- ================================
-- GENERATOR PROGRESS
-- ================================

local function updateGeneratorProgress(generator)
    if not generator or not generator.Parent then return true end
    local percent = GetGameValue(generator, "RepairProgress") or GetGameValue(generator, "Progress") or 0

    local billboard = generator:FindFirstChild("GenBitchHook")
    if percent >= 100 then
        if billboard then billboard:Destroy() end
        local h = generator:FindFirstChild("H")
        if h then h:Destroy() end
        return true
    end

    local cp = math.clamp(percent, 0, 100)
    local finalColor = cp < 50 and Config.Objects.Generator.Color:Lerp(Color3.fromRGB(180, 180, 0), cp / 50)
                               or Color3.fromRGB(180, 180, 0):Lerp(Color3.fromRGB(0, 150, 0), (cp - 50) / 50)

    local percentStr = string.format("[%.2f%%]", percent)
    if not billboard then
        billboard = CreateBillboardTag(percentStr, finalColor)
        billboard.Name = "GenBitchHook"
        billboard.StudsOffset = Vector3.new(0, 2, 0)
        billboard.Adornee = generator:FindFirstChild("defaultMaterial", true) or generator
        billboard.Parent = generator
        registerESPObject(generator)
    else
        local lbl = billboard:FindFirstChild("BitchHook") or billboard:FindFirstChildOfClass("TextLabel")
        if lbl then
            lbl.Text = percentStr
            lbl.TextColor3 = finalColor
        end
    end
    return false
end

-- ================================
-- PREDIKSI NEXT KILLER
-- ================================

local function updateNextKillerDisplay()
    if not IndicatorGui or not IndicatorGui.Parent then return end
    local label = IndicatorGui:FindFirstChild("NextKillerDisplay")
    local teamName = (LocalPlayer.Team and LocalPlayer.Team.Name:lower()) or ""

    if teamName:find("spectator") or teamName:find("lobby") then
        if not label then
            label = Instance.new("TextLabel", IndicatorGui)
            label.Name = "NextKillerDisplay"
            label.Size = UDim2.new(0, 220, 0, 30)
            label.Position = UDim2.new(0.5, 0, 0, 45)
            label.AnchorPoint = Vector2.new(0.5, 0)
            label.BackgroundTransparency = 0.5
            label.BackgroundColor3 = Color3.new(0, 0, 0)
            label.TextColor3 = Color3.new(1, 1, 1)
            label.Font = Enum.Font.GothamBold
            label.TextSize = 14
            label.RichText = true
            label.Text = "Next Killer: Calculating..."
        end

        local players = Players:GetPlayers()
        table.sort(players, function(a, b)
            local aA = GetGameValue(a, "AllowKiller") or false
            local bA = GetGameValue(b, "AllowKiller") or false
            if aA ~= bA then return aA == true end
            return (GetGameValue(a, "KillerChance") or 0) > (GetGameValue(b, "KillerChance") or 0)
        end)

        local nk = players[1]
        if nk then
            local playerName = nk == LocalPlayer and "YOU" or nk.Name
            local killerName = GetGameValue(nk, "SelectedKiller")
            local displayText = playerName
            if killerName and tostring(killerName) ~= "" then
                displayText = displayText .. " (" .. tostring(killerName) .. ")"
            end
            label.Text = "Next Killer: <font color=\"rgb(255,0,0)\">" .. displayText .. "</font>"
        end
    elseif label then
        label:Destroy()
    end
end

-- ================================
-- REFRESH ESP OBJEK (CHARM ONLY)
-- ================================

local isRefreshing = false
local function RefreshESP()
    if isRefreshing then return end
    isRefreshing = true

    task.spawn(function()
        local newGenerators = {}
        local Map = workspace:FindFirstChild("Map")
        
        if Map then
            -- Scan semua objek termasuk yang ada di dalam folder
            for _, obj in ipairs(Map:GetDescendants()) do
                if obj.Name == "Generator" then
                    table.insert(newGenerators, obj)
                    ApplyHighlight(obj, Config.Objects.Generator.Color)
                elseif obj.Name == "Gate" then
                    ApplyHighlight(obj, Config.Objects.Gate.Color)
                elseif obj.Name == "Palletwrong" or obj.Name == "Pallet" then
                    ApplyHighlight(obj, Config.Objects.Pallet.Color)
                elseif obj.Name == "Window" then
                    ApplyHighlight(obj, Config.Objects.Window.Color)
                elseif obj.Name == "Hook" then
                    local m = obj:FindFirstChild("Model")
                    if m then
                        for _, p in ipairs(m:GetChildren()) do
                            if p:IsA("MeshPart") then ApplyHighlight(p, Config.Objects.Hook.Color) end
                        end
                    end
                -- TRAP: Hanya kasih Highlight (Charm)
                elseif cfg.TrapESP and obj.Name == "BearTrap" then
                    ApplyHighlight(obj, Config.Objects.Trap.Color)
                end
            end
            
            -- PUMPKIN: Hanya kasih Highlight (Charm)
            if cfg.PumpkinESP then
                local folder = Map:FindFirstChild("Pumpkins")
                if folder then
                    for _, pumpkin in ipairs(folder:GetChildren()) do
                        if pumpkin:IsA("PVInstance") then
                            -- Cek apakah pumpkin masih ada (tidak transparan)
                            local available = false
                            for _, part in ipairs(pumpkin:GetChildren()) do
                                if (part.Name == "shell" or part.Name == "inside")
                                    and part:IsA("BasePart") and part.Transparency < 1 then
                                    available = true
                                    break
                                end
                            end
                            if available then
                                ApplyHighlight(pumpkin, Config.Objects.Pumpkin.Color)
                            end
                        end
                    end
                end
            end
        end
        
        ActiveGenerators = newGenerators
        isRefreshing = false
    end)
end

-- ================================
-- AUTO SKILL CHECK
-- ================================

local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
local function getRemote(...)
    local inst = Remotes
    for _, name in ipairs({ ... }) do
        inst = inst and inst:FindFirstChild(name)
    end
    return inst
end

local function fire(remote, ...)
    if remote then pcall(remote.FireServer, remote, ...) end
end

-- ================================
-- AUTO SLASH (LEGIT ONLY)
-- ================================

local AuraConfig = {
    LungeDelay = 0.21,
    AuraCooldown = 1.1,
    LegitReach = 9,
    ServerReach = 4.2,
    LegitAngle = 0.5,
}

local AuraState = {
    Character = LocalPlayer.Character,
    Humanoid = nil,
    Root = nil,
    LastSwing = 0,
}

if AuraState.Character then
    AuraState.Humanoid = AuraState.Character:FindFirstChildOfClass("Humanoid")
    AuraState.Root = AuraState.Character:FindFirstChild("HumanoidRootPart")
end

LocalPlayer.CharacterAdded:Connect(function(character)
    AuraState.Character = character
    AuraState.Humanoid = character:WaitForChild("Humanoid", 10)
    AuraState.Root = character:WaitForChild("HumanoidRootPart", 10)
end)

local function AuraFindRemote(...)
    local node = ReplicatedStorage:FindFirstChild("Remotes")
    if not node then return nil end
    for _, name in ipairs({ ... }) do
        node = node and node:FindFirstChild(name)
    end
    return node
end

local AuraRemote = {
    Lunge = AuraFindRemote("Attacks", "Lunge"),
    Attack = AuraFindRemote("Attacks", "BasicAttack"),
}

local function AuraRole()
    local team = LocalPlayer.Team
    return team and team.Name or nil
end

local function AuraInFront()
    local root = AuraState.Root
    if not root then return nil end

    local team = Teams:FindFirstChild("Survivors")
    if not team then return nil end

    local look = root.CFrame.LookVector
    for _, player in ipairs(team:GetPlayers()) do
        if player == LocalPlayer then continue end
        local character = player.Character
        if not character then continue end

        local targetRoot = character:FindFirstChild("HumanoidRootPart")
        if not targetRoot then continue end
        if character:GetAttribute("Knocked")
            or character:GetAttribute("IsHooked")
            or character:GetAttribute("IsCarried") then
            continue
        end

        local offset = targetRoot.Position - root.Position
        if offset.Magnitude <= AuraConfig.LegitReach
            and look:Dot(offset.Unit) >= AuraConfig.LegitAngle then
            return character
        end
    end
    return nil
end

local function AuraSwing(target)
    local targetRoot = target.HumanoidRootPart

    local function Close()
        local root = AuraState.Root
        if not (cfg.SmartHitbox and root and targetRoot.Parent) then return end

        local offset = targetRoot.Position - root.Position
        if offset.Magnitude <= AuraConfig.ServerReach then return end

        local spot = targetRoot.Position - offset.Unit * AuraConfig.LegitReach
        root.CFrame = CFrame.lookAt(
            Vector3.new(spot.X, root.Position.Y, spot.Z),
            Vector3.new(targetRoot.Position.X, root.Position.Y, targetRoot.Position.Z)
        )
        root.AssemblyLinearVelocity = Vector3.zero
    end

    Close()
    if AuraRemote.Lunge then AuraRemote.Lunge:FireServer() end
    task.wait(AuraConfig.LungeDelay)
    Close()
    if AuraRemote.Attack then AuraRemote.Attack:FireServer() end
end

local function KillAuraStep()
    if not cfg.KillAura or AuraRole() ~= "Killer" then return end

    local humanoid = AuraState.Humanoid
    local root = AuraState.Root
    if not humanoid or humanoid.Health <= 0 or not root or not root.Parent then return end
    if not (AuraRemote.Lunge and AuraRemote.Attack) then return end
    if os.clock() - AuraState.LastSwing < AuraConfig.AuraCooldown then return end

    local target = AuraInFront()
    if not target then return end
    AuraState.LastSwing = os.clock()
    AuraSwing(target)
end

local lastCheck = { source = nil, args = nil }

for _, source in ipairs({ "Generator", "Healing" }) do
    local ev = getRemote(source, "SkillCheckEvent")
    if ev then
        ev.OnClientEvent:Connect(function(args)
            lastCheck.source = source
            lastCheck.args = args
        end)
    end
end

local function inWindow(line, goal)
    local diff = (line.Rotation - goal.Rotation) % 360
    return diff >= 102 and diff <= 116
end

local function pressSpace()
    task.spawn(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        task.wait(0.04)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
    end)
end

local lastFire = 0

RunService.RenderStepped:Connect(function()
    if not (cfg.AutoGenerator or cfg.AutoSolveTrap) then return end
    if tick() - lastFire < 0.3 then return end

    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local prompt = pg and pg:FindFirstChild("SkillCheckPromptGui")
    local check = prompt and prompt:FindFirstChild("Check")
    if not check or not check.Visible then return end

    local line = check:FindFirstChild("Line")
    if not line then return end

    local trapGoal    = check:FindFirstChild("TrapGoal")
    local trapPerfect = check:FindFirstChild("TrapPerfect")
    local perfectOn   = trapPerfect and trapPerfect.Visible
    local trapOn      = perfectOn or (trapGoal and trapGoal.Visible)

    if trapOn then
        if not cfg.AutoSolveTrap then return end
        local target = perfectOn and trapPerfect or trapGoal
        if inWindow(line, target) then
            lastFire = tick()
            fire(getRemote("Killers", "Butcher", "TrapSkillResult"), "success")
            fire(getRemote("Killers", "Butcher", "FreeTrap"))
            pressSpace()
        end
    else
        if not cfg.AutoGenerator then return end
        local goal = check:FindFirstChild("Goal")
        if goal and inWindow(line, goal) then
            lastFire = tick()
            local src = lastCheck.source
            if src then
                fire(getRemote(src, "SkillCheckResultEvent"), "success", 1, lastCheck.args)
            else
                fire(getRemote("Generator", "SkillCheckResultEvent"), "success", 1, lastCheck.args)
                fire(getRemote("Healing", "SkillCheckResultEvent"), "success", 1, lastCheck.args)
            end
            pressSpace()
        end
    end
end)

-- ================================
-- PANIC KEY & REJOIN HELPER
-- ================================

local function SetESPVisible(state)
    hidden = not state
    if IndicatorGui then IndicatorGui.Enabled = state end

    for obj in pairs(ESPObjects) do
        if obj and obj.Parent then
            local h = obj:FindFirstChild("H")
            if h then h.Enabled = state end
            for _, child in ipairs(obj:GetChildren()) do
                if child:IsA("BillboardGui") then
                    child.Enabled = state
                end
            end
        end
    end
    env.VD_HiddenState = hidden
end

-- ================================
-- HOTKEYS (RightCtrl = Hide/Unhide, R = Rejoin)
-- ================================

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end

    if input.KeyCode == Enum.KeyCode.G then
        cfg.KillAura = not cfg.KillAura
        pcall(StarterGui.SetCore, StarterGui, "SendNotification", {
            Title = "MURTHEHELP",
            Text = "Auto Slash: " .. (cfg.KillAura and "ON" or "OFF"),
            Duration = 4,
        })
    elseif input.KeyCode == Enum.KeyCode.J then
        cfg.SmartHitbox = not cfg.SmartHitbox
        pcall(StarterGui.SetCore, StarterGui, "SendNotification", {
            Title = "MURTHEHELP",
            Text = "Reach Assist: " .. (cfg.SmartHitbox and "ON" or "OFF"),
            Duration = 4,
        })

    -- PANIC KEY
    elseif input.KeyCode == Enum.KeyCode.RightControl then
        SetESPVisible(hidden)
        
    -- REJOIN HOTKEY
    elseif input.KeyCode == Enum.KeyCode.R then
        if env.LastRejoin and tick() - env.LastRejoin < 5 then return end
        env.LastRejoin = tick()
        
        local notify = Instance.new("ScreenGui")
        notify.Name = "RejoinNotify"
        notify.DisplayOrder = 9999
        notify.Parent = LocalPlayer:WaitForChild("PlayerGui")
        
        local text = Instance.new("TextLabel")
        text.Size = UDim2.new(1, 0, 0, 50)
        text.Position = UDim2.new(0, 0, 0.4, 0)
        text.BackgroundTransparency = 1
        text.Text = "Rejoining same server..."
        text.TextColor3 = Color3.fromRGB(255, 255, 0)
        text.Font = Enum.Font.GothamBold
        text.TextSize = 24
        text.TextStrokeTransparency = 0
        text.Parent = notify
        
        task.spawn(function()
            task.wait(1.5)
            pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
            end)
        end)
    end
end)

-- ================================
-- EVENT HANDLER & MAIN LOOP
-- ================================

workspace.ChildAdded:Connect(function(c)
    if c.Name == "Map" then
        task.wait(1)
        if not hidden then RefreshESP() end
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    SetupGui()
    task.wait(1)
    SetESPVisible(not (env.VD_HiddenState or false))
end)

RunService.Heartbeat:Connect(function()
    KillAuraStep()

    local now = tick()
    if now - LastUpdateTick < 0.05 then return end
    LastUpdateTick = now

    Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    Lighting.Brightness = 2
    Lighting.ClockTime = 14
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9

    if hidden then return end

    if now - LastFullESPRefresh > 10 then
        LastFullESPRefresh = now
        RefreshESP()
    end

    updateNextKillerDisplay()

    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local killerNearby = false

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            updatePlayerNametag(p)
            local pTeam = p.Team and p.Team.Name:lower() or ""
            if pTeam:find("killer") and myRoot and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                if (p.Character.HumanoidRootPart.Position - myRoot.Position).Magnitude < 99 then
                    killerNearby = true
                end
            end
        end
    end

    if myRoot then
        local warn = myRoot:FindFirstChild("KillerWarn")
        if killerNearby then
            if not warn then
                warn = CreateBillboardTag("!", Color3.fromRGB(255, 0, 0), UDim2.new(0, 50, 0, 50), 40)
                warn.Name = "KillerWarn"
                warn.StudsOffset = Vector3.new(0, 4, 0)
                warn.Adornee = myRoot
                warn.Parent = myRoot
                registerESPObject(myRoot)
            end
        elseif warn then
            warn:Destroy()
        end
    end

    for i = #ActiveGenerators, 1, -1 do
        local g = ActiveGenerators[i]
        if g and g.Parent then
            if updateGeneratorProgress(g) then
                table.remove(ActiveGenerators, i)
            end
        else
            table.remove(ActiveGenerators, i)
        end
    end
end)

Players.PlayerRemoving:Connect(function(p)
    if not IndicatorGui then return end
    local names = { p.Name .. "_Chased", p.Name .. "_Killer", p.Name }
    for _, n in ipairs(names) do
        local obj = IndicatorGui:FindFirstChild(n)
        if obj then obj:Destroy() end
    end
end)

-- ================================
-- INISIALISASI AWAL
-- ================================
SetupGui()
if not hidden then RefreshESP() end

env.ViolenceDistrictUnload = function()
    cfg.KillAura = false
    cfg.SmartHitbox = false
    env.ViolenceDistrictUnload = nil
end

pcall(StarterGui.SetCore, StarterGui, "SendNotification", {
    Title = "MURTHEHELP",
    Text = "Loaded — G: Auto Slash | J: Reach Assist",
    Duration = 4,
})
