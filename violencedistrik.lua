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
        Hook = { Color = Color3.fromRGB(132, 255, 169) }
    },
    TriggerbotEnabled = false,
    HitboxEnabled = true,
    HitboxSize = 30,
    -- Auto Sword (klik kanan otomatis ke musuh terdekat)
    AutoSwordEnabled = true,
    AutoSwordRange = 3       -- jarak maksimal (studs)
}

local MaskNames = {
    ["Richard"] = "Rooster",
    ["Tony"] = "Tiger",
    ["Brandon"] = "Panther",
    ["Cobra"] = "Cobra",
    ["Richter"] = "Rat",
    ["Rabbit"] = "Rabbit",
    ["Alex"] = "Chainsaw"
}

local MaskColors = {
    ["Richard"] = Color3.fromRGB(255, 0, 0),
    ["Tony"] = Color3.fromRGB(255, 255, 0),
    ["Brandon"] = Color3.fromRGB(160, 32, 240),
    ["Cobra"] = Color3.fromRGB(0, 255, 0),
    ["Richter"] = Color3.fromRGB(0, 0, 0),
    ["Rabbit"] = Color3.fromRGB(255, 105, 180),
    ["Alex"] = Color3.fromRGB(255, 255, 255)
}

-- ================================
-- SERVICE & VARIABEL GLOBAL
-- ================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
local TPS = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ActiveGenerators = {}
local LastUpdateTick = 0
local LastFullESPRefresh = 0
local lastClickTime = 0
local lastRightClickTime = 0
local IndicatorGui = nil

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
    local h = object:FindFirstChild("H") or Instance.new("Highlight")
    h.Name = "H"
    h.Adornee = object
    h.FillColor = color
    h.OutlineColor = color
    h.FillTransparency = 0.8
    h.OutlineTransparency = 0.3
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = object
end

local function CreateBillboardTag(text, color, size, textSize, offset)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "BitchHook"
    billboard.AlwaysOnTop = true
    billboard.Size = size or UDim2.new(0, 120, 0, 30)
    if offset then
        billboard.StudsOffset = offset
    end
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
    IndicatorGui.Parent = PlayerGui
end

-- ================================
-- PLAYER NAMETAG & ESP
-- ================================
local function updatePlayerNametag(player)
    if not IndicatorGui or not IndicatorGui.Parent then return end
    if not player.Character then
        local names = { player.Name, player.Name .. "_Chased", player.Name .. "_Killer" }
        for _, n in ipairs(names) do
            local obj = IndicatorGui:FindFirstChild(n)
            if obj then obj:Destroy() end
        end
        return
    end
    local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not rootPart then return end

    local teamName = (player.Team and player.Team.Name:lower()) or ""
    local selectedKillerAttr = GetGameValue(player, "SelectedKiller")
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
        billboard = CreateBillboardTag(nameText, color, nil, nil, Vector3.new(0, 3.5, 0))
        billboard.Adornee = rootPart
        billboard.Parent = rootPart
    else
        local lbl = billboard:FindFirstChild("BitchHook") or billboard:FindFirstChildOfClass("TextLabel")
        if lbl then
            lbl.Text = nameText
            lbl.TextColor3 = color
        end
    end

    ApplyHighlight(player.Character, color)

    local maskHook = rootPart:FindFirstChild("MaskHook")
    if maskHook then maskHook:Destroy() end

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
    else
        if killerLabel2D then killerLabel2D:Destroy() end
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
        billboard = CreateBillboardTag(percentStr, finalColor, nil, nil, Vector3.new(0, 2, 0))
        billboard.Name = "GenBitchHook"
        billboard.Adornee = generator:FindFirstChild("defaultMaterial", true) or generator
        billboard.Parent = generator
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
    else
        if label then label:Destroy() end
    end
end

-- ================================
-- REFRESH ESP OBJEK
-- ================================
local function RefreshESP()
    ActiveGenerators = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "Window" then
            ApplyHighlight(obj, Config.Objects.Window.Color)
        end
    end
    local Map = workspace:FindFirstChild("Map")
    if not Map then return end
    for _, obj in ipairs(Map:GetDescendants()) do
        if obj.Name == "Generator" then
            ApplyHighlight(obj, Config.Objects.Generator.Color)
            table.insert(ActiveGenerators, obj)
        elseif obj.Name == "Hook" then
            local m = obj:FindFirstChild("Model")
            if m then
                for _, p in ipairs(m:GetDescendants()) do
                    if p:IsA("MeshPart") then
                        ApplyHighlight(p, Config.Objects.Hook.Color)
                    end
                end
            end
        elseif obj.Name == "Palletwrong" or obj.Name == "Pallet" then
            ApplyHighlight(obj, Config.Objects.Pallet.Color)
        elseif obj.Name == "Gate" then
            ApplyHighlight(obj, Config.Objects.Gate.Color)
        end
    end
end

-- ================================
-- AUTO SKILL CHECK
-- ================================
local function StartSkillCheckLogic()
    local function ConnectUI()
        local CheckGui = PlayerGui:WaitForChild("SkillCheckPromptGui", 10)
        if not CheckGui then return end
        local Check = CheckGui:WaitForChild("Check")
        local Line = Check:WaitForChild("Line")
        local Goal = Check:WaitForChild("Goal")
        local HeartbeatConn = nil
        Check:GetPropertyChangedSignal("Visible"):Connect(function()
            if Check.Visible and LocalPlayer.Team and LocalPlayer.Team.Name:lower():find("survivor") then
                if HeartbeatConn then HeartbeatConn:Disconnect() end
                HeartbeatConn = RunService.Stepped:Connect(function()
                    if not Check.Visible then
                        if HeartbeatConn then HeartbeatConn:Disconnect(); HeartbeatConn = nil end
                        return
                    end
                    if not Line or not Goal or not Line.Parent or not Goal.Parent then return end
                    local lr, gr = Line.Rotation % 360, Goal.Rotation % 360
                    local gs, ge = (gr + 104) % 360, (gr + 114) % 360
                    local isInside = (gs > ge) and (lr >= gs or lr <= ge) or (lr >= gs and lr <= ge)
                    if isInside then
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                        if HeartbeatConn then HeartbeatConn:Disconnect(); HeartbeatConn = nil end
                    end
                end)
            elseif HeartbeatConn then
                HeartbeatConn:Disconnect(); HeartbeatConn = nil
            end
        end)
    end
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(2)
        ConnectUI()
    end)
    ConnectUI()
end

-- ================================
-- CROSSHAIR & NOTIFIKASI
-- ================================
local function CreateCrosshair()
    if IndicatorGui:FindFirstChild("Crosshair") then return end
    local cross = Instance.new("Frame")
    cross.Name = "Crosshair"
    cross.Size = UDim2.new(0, 6, 0, 6)
    cross.Position = UDim2.new(0.5, -3, 0.5, -3)
    cross.BackgroundColor3 = Color3.new(1, 1, 1)
    cross.BorderSizePixel = 0
    cross.BackgroundTransparency = 0
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = cross
    cross.Parent = IndicatorGui
end

local function ShowNotification(text, color, duration)
    if not IndicatorGui then return end
    local notif = Instance.new("TextLabel")
    notif.Name = "Notif"
    notif.Size = UDim2.new(0, 200, 0, 30)
    notif.Position = UDim2.new(0.5, -100, 0, 80)
    notif.BackgroundTransparency = 0.5
    notif.BackgroundColor3 = Color3.new(0, 0, 0)
    notif.TextColor3 = color or Color3.new(1, 1, 1)
    notif.Font = Enum.Font.GothamBold
    notif.TextSize = 14
    notif.RichText = true
    notif.Text = text
    notif.Parent = IndicatorGui
    task.delay(duration or 1.5, function()
        if notif then notif:Destroy() end
    end)
end

local function ToggleTriggerbot()
    Config.TriggerbotEnabled = not Config.TriggerbotEnabled
    local status = Config.TriggerbotEnabled and "ON" or "OFF"
    local color = Config.TriggerbotEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    ShowNotification("Triggerbot: " .. status, color, 1.5)
end

local function ToggleAutoSword()
    Config.AutoSwordEnabled = not Config.AutoSwordEnabled
    local status = Config.AutoSwordEnabled and "ON" or "OFF"
    local color = Config.AutoSwordEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    ShowNotification("Auto Sword: " .. status, color, 1.5)
end

local function Rejoin()
    if game.JobId then
        TPS:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    else
        TPS:Teleport(game.PlaceId)
    end
end

-- ================================
-- HITBOX (DIPERBAIKI - TIDAK MENDORONG)
-- ================================
local function AddHitboxToCharacter(character)
    if not character then return end
    if not Config.HitboxEnabled then return end

    if character:FindFirstChild("HitboxPart") then
        return
    end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then
        task.wait(1)
        root = character:FindFirstChild("HumanoidRootPart")
        if not root then return end
    end

    local size = Config.HitboxSize or 30
    local part = Instance.new("Part")
    part.Name = "HitboxPart"
    part.Size = Vector3.new(size, size, size)
    part.Transparency = 1
    part.CanCollide = false
    part.CanTouch = false
    part.Anchored = false
    part.Massless = true
    part.Parent = character

    local success, err = pcall(function()
        local weld = Instance.new("Weld")
        weld.Part0 = root
        weld.Part1 = part
        weld.C0 = CFrame.new(0, 0, 0)
        weld.Parent = part
    end)

    if not success then
        warn("Gagal memasang weld pada hitbox: " .. tostring(err))
        part:Destroy()
        return
    end
end

-- ================================
-- TRIGGERBOT (KLIK KIRI)
-- ================================
local function PerformClick(x, y)
    local success = false
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game)
        task.wait(0.02)
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game)
        success = true
    end)
    if not success and mouse1click then
        pcall(function()
            mouse1click()
            success = true
        end)
    end
    if not success then
        pcall(function()
            UIS:SendMouseButtonEvent(x, y, 0, true, game)
            task.wait(0.02)
            UIS:SendMouseButtonEvent(x, y, 0, false, game)
            success = true
        end)
    end
    return success
end

local function tryTriggerbotClick()
    if not Config.TriggerbotEnabled then return end
    if tick() - lastClickTime < 0.2 then return end

    local myChar = LocalPlayer.Character
    if not myChar then return end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end

    local cam = workspace.CurrentCamera
    if not cam then return end

    local viewportSize = cam.ViewportSize
    local centerX = viewportSize.X / 2
    local centerY = viewportSize.Y / 2

    local bestTarget = nil
    local bestAngle = math.rad(15)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local myTeam = LocalPlayer.Team
            local targetTeam = player.Team
            if not myTeam or not targetTeam or myTeam == targetTeam then
                continue
            end
            local char = player.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if root and humanoid and humanoid.Health > 0 then
                    local screenPos, onScreen = cam:WorldToScreenPoint(root.Position)
                    if onScreen then
                        local dx = screenPos.X - centerX
                        local dy = screenPos.Y - centerY
                        local dist = math.sqrt(dx*dx + dy*dy)
                        local fov = math.rad(70)
                        local screenAngle = (dist / viewportSize.X) * fov * 2
                        if screenAngle < bestAngle then
                            bestAngle = screenAngle
                            bestTarget = {
                                player = player,
                                screenX = screenPos.X,
                                screenY = screenPos.Y,
                                distance = (root.Position - myRoot.Position).Magnitude
                            }
                        end
                    end
                end
            end
        end
    end

    if bestTarget then
        local clickX = math.clamp(bestTarget.screenX, 0, viewportSize.X)
        local clickY = math.clamp(bestTarget.screenY, 0, viewportSize.Y)
        if PerformClick(clickX, clickY) then
            lastClickTime = tick()
        end
    end
end

-- ================================
-- AUTO SWORD (KLIK KANAN) - TARGET SEMUA MUSUH
-- ================================
local function PerformRightClick()
    local cam = workspace.CurrentCamera
    if not cam then return false end
    local viewportSize = cam.ViewportSize
    local centerX = viewportSize.X / 2
    local centerY = viewportSize.Y / 2

    local success = false
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 1, true, game)
        task.wait(0.02)
        VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 1, false, game)
        success = true
    end)
    if not success then
        pcall(function()
            UIS:SendMouseButtonEvent(centerX, centerY, 1, true, game)
            task.wait(0.02)
            UIS:SendMouseButtonEvent(centerX, centerY, 1, false, game)
            success = true
        end)
    end
    if not success and mouse2click then
        pcall(function()
            mouse2click()
            success = true
        end)
    end
    return success
end

local function tryAutoSword()
    if not Config.AutoSwordEnabled then return end
    if tick() - lastRightClickTime < 0.2 then return end

    local myChar = LocalPlayer.Character
    if not myChar then return end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    local myHumanoid = myChar:FindFirstChildOfClass("Humanoid")
    if not myRoot or not myHumanoid or myHumanoid.Health <= 0 then return end

    local myTeam = LocalPlayer.Team
    if not myTeam then return end

    local range = Config.AutoSwordRange

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        -- Lewati jika tidak memiliki tim atau tim sama
        local targetTeam = player.Team
        if not targetTeam or targetTeam == myTeam then
            continue
        end

        local char = player.Character
        if not char then continue end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not root or not hum or hum.Health <= 0 then continue end

        local distance = (root.Position - myRoot.Position).Magnitude
        if distance <= range then
            -- Musuh dalam jarak, lakukan klik kanan
            if PerformRightClick() then
                lastRightClickTime = tick()
                -- Opsional: notifikasi cepat
                -- ShowNotification("⚔️", Color3.fromRGB(255,200,0), 0.3)
            end
            break -- cukup satu musuh per frame
        end
    end
end

-- ================================
-- EVENT HANDLER & MAIN LOOP
-- ================================
workspace.ChildAdded:Connect(function(c)
    if c.Name == "Map" then
        task.wait(1)
        RefreshESP()
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    SetupGui()
    CreateCrosshair()
    task.wait(1)
end)

RunService.Heartbeat:Connect(function()
    local now = tick()
    if now - LastUpdateTick < 0.05 then return end
    LastUpdateTick = now

    Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    Lighting.Brightness = 2
    Lighting.ClockTime = 14
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9

    if now - LastFullESPRefresh > 5 then
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
                warn = CreateBillboardTag("!", Color3.fromRGB(255, 0, 0), UDim2.new(0, 50, 0, 50), 40, Vector3.new(0, 4, 0))
                warn.Name = "KillerWarn"
                warn.Adornee = myRoot
                warn.Parent = myRoot
            end
        else
            if warn then warn:Destroy() end
        end
    end

    tryTriggerbotClick()
    tryAutoSword()

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
-- SETUP HITBOX UNTUK SEMUA PEMAIN
-- ================================
local function SetupHitboxForPlayer(plr)
    if plr == LocalPlayer then return end
    if not Config.HitboxEnabled then return end

    if plr.Character then
        AddHitboxToCharacter(plr.Character)
    end

    plr.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        AddHitboxToCharacter(char)
    end)
end

for _, plr in ipairs(Players:GetPlayers()) do
    SetupHitboxForPlayer(plr)
end

Players.PlayerAdded:Connect(function(plr)
    SetupHitboxForPlayer(plr)
end)

-- ================================
-- KEYBINDS
-- ================================
UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.T then
        ToggleTriggerbot()
    elseif input.KeyCode == Enum.KeyCode.G then
        ToggleAutoSword()
    elseif input.KeyCode == Enum.KeyCode.R then
        Rejoin()
    end
end)

-- ================================
-- INISIALISASI AWAL
-- ================================
SetupGui()
RefreshESP()
StartSkillCheckLogic()
CreateCrosshair()

print("Script loaded! Press T for Triggerbot, G for Auto Sword, R for Rejoin.")
