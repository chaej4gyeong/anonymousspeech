local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Configuration Settings (ubah di sini untuk mengubah pengaturan)
local Config = {
    -- Timing dan Kecepatan
    CastHoldTime = 1.0,  -- Waktu hold untuk cast (detik)
    AutoSellIntervalMinutes = 1,  -- Interval auto sell (menit)
    FishClickDelay = 0.5,  -- Delay antara klik ikan (detik)
    BarBurstDelay = 0.05,  -- Delay burst bar (detik)
    
    -- Delay lainnya
    RodEquipWait = 0.2,  -- Wait setelah equip rod
    GuiWaitStep = 0.1,  -- Step wait untuk gui
    GuiTimeout = 8,  -- Timeout untuk gui muncul
    FishingTimeout = 22,  -- Timeout fishing
    FishClickWait = 0.6,  -- Wait sebelum klik ikan
    BarClickInterval = 0.025,  -- Interval klik bar
    LoopWaitAutoFish = 1,  -- Wait di loop auto fish
    LoopWaitAutoSell = 5,  -- Wait di loop auto sell
    HookDelay = 3,  -- Delay sebelum hook
    StatusUpdateInterval = 10  -- Interval update status (detik)
}

-- Keybind Configuration (ubah di sini untuk mengubah keybind)
local Keybinds = {
    ToggleAutoFish = Enum.KeyCode.F,
    ToggleAutoSell = Enum.KeyCode.G,
    SellNow = Enum.KeyCode.H,
    ToggleLockPosition = Enum.KeyCode.L,
    SpectateNext = Enum.KeyCode.K,
    StopSpectating = Enum.KeyCode.J,
    ManualFishOnce = Enum.KeyCode.P  -- Tambahan dari ori.lua
}

-- State variables
local AutoFishEnabled = false
local AutoSellEnabled = false
local LastSellTime = 0
local LockPositionEnabled = false
local LockedCFrame = nil
local SpectateTarget = nil
local SpectateIndex = 1
local SpectatePlayers = {}
local WebhookEnabled = true
local WebhookUrl = "https://discord.com/api/webhooks/1490797198894436473/qYqFgia-PRNhJkNZO1zntBxFHeCy5f8e7R33a-6BoqCbqwxCUvymKArVhjNoffgedJg7"
local FishingBusy = false
local AntiAfkEnabled = false

-- Mobile detection
local IS_MOBILE = UserInputService.TouchEnabled
local IS_DESKTOP = UserInputService.KeyboardEnabled

-- Notification helpers
local NotificationPrefixes = {
    info = "",
    success = "✅ ",
    error = "⚠️ ",
    loaded = "🚀 ",
    sold = "💰 ",
    spectating = "👁️ ",
    toggle = "auto"
}

local function getNotificationPrefix(message, style)
    style = style or "auto"
    if style == true then
        style = "auto"
    end

    if style == "auto" then
        local lowerMsg = string.lower(message)
        if string.find(lowerMsg, "on") or string.find(lowerMsg, "enabled") or string.find(lowerMsg, "aktif") then
            return NotificationPrefixes.success
        elseif string.find(lowerMsg, "off") or string.find(lowerMsg, "disabled") or string.find(lowerMsg, "nonaktif") then
            return NotificationPrefixes.error
        elseif string.find(lowerMsg, "loaded") or string.find(lowerMsg, "ready") then
            return NotificationPrefixes.loaded
        elseif string.find(lowerMsg, "sold") or string.find(lowerMsg, "success") then
            return NotificationPrefixes.sold
        elseif string.find(lowerMsg, "failed") or string.find(lowerMsg, "error") then
            return NotificationPrefixes.error
        elseif string.find(lowerMsg, "spectating") then
            return NotificationPrefixes.spectating
        end
        return NotificationPrefixes.info
    end
    return NotificationPrefixes[style] or NotificationPrefixes.info
end

local function Notify(message, duration, style)
    duration = duration or 3
    local prefix = getNotificationPrefix(message, style)
    local displayMessage = prefix .. message

    print("[anonymaous] " .. displayMessage)

    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "anonymaous",
            Text = displayMessage,
            Duration = duration,
            Icon = "rbxthumb://type=Asset&id=74300779922746&w=150&h=150"
        })
    end)
end

-- Print status function (from ori.lua)
local function printStatus(message)
    local timestamp = os.date("%H:%M:%S")
    print("[" .. timestamp .. "] " .. message)
end

-- Print keybinds (only for desktop)
if IS_DESKTOP then
    print("╔════════════════════════════════════╗")
    print("║         anonymaous Keybinds        ║")
    print("╠════════════════════════════════════╣")
    print("║ F  - Toggle Auto Fish              ║")
    print("║ G  - Toggle Auto Sell              ║")
    print("║ H  - Sell All Now                  ║")
    print("║ L  - Toggle Lock Position          ║")
    print("║ K  - Spectate Next Player          ║")
    print("║ J  - Stop Spectating               ║")
    print("║ P  - Manual Fish Once              ║")
    print("╚════════════════════════════════════╝")
end

Notify("Ultimate Combined Script Loaded Successfully!", 5, "loaded")

-- Fungsi klik yang kompatibel untuk PC dan Mobile
local function clickAtPosition(x, y)
    if IS_MOBILE then
        -- Untuk mobile, gunakan Touch event
        pcall(function()
            VirtualInputManager:SendTouchEvent(x, y, true)
            task.wait(0.05)
            VirtualInputManager:SendTouchEvent(x, y, false)
        end)
    else
        -- Untuk PC, gunakan Mouse event
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
        end)
    end
end

-- Fishing Functions
local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getRodTool()
    local character = getCharacter()
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") and string.find(string.lower(child.Name), "rod") then
            return child
        end
    end
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, child in ipairs(backpack:GetChildren()) do
            if child:IsA("Tool") and string.find(string.lower(child.Name), "rod") then
                return child
            end
        end
    end
    return nil
end

local function ensureRodEquipped()
    local character = getCharacter()
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    local tool = getRodTool()
    if tool and backpack and tool.Parent == backpack then
        tool.Parent = character
    end
    return getRodTool()
end

local function getFishingGui()
    for _, child in ipairs(PlayerGui:GetChildren()) do
        if child:IsA("ScreenGui") then
            local pre = child:FindFirstChild("PreFishingHolder", true)
            local holder = child:FindFirstChild("FishingHolder", true)
            if pre or holder then
                return child
            end
        end
    end
    return nil
end

local function clickGuiObject(obj)
    if not obj or not obj:IsA("GuiObject") then
        return
    end
    local pos = obj.AbsolutePosition
    local size = obj.AbsoluteSize
    local x = pos.X + size.X * 0.5
    local y = pos.Y + size.Y * 0.5
    clickAtPosition(x, y)
end

local function holdMouseCenter(duration)
    local camera = workspace.CurrentCamera
    if not camera then
        return
    end
    local viewport = camera.ViewportSize
    local x = viewport.X * 0.5
    local y = viewport.Y * 0.5
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
    end)
    task.wait(duration)
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
    end)
end

local function ancestorNameContains(object, term)
    term = string.lower(term)
    local current = object.Parent
    while current do
        local n = string.lower(current.Name)
        if string.find(n, term) then
            return true
        end
        current = current.Parent
    end
    return false
end

local function stageStillActive(gui)
    if not gui or gui.Parent == nil then
        return false
    end
    local pre = gui:FindFirstChild("PreFishingHolder", true)
    local holder = gui:FindFirstChild("FishingHolder", true)
    if pre and pre:IsA("GuiObject") and pre.Visible then
        return true
    end
    if holder and holder:IsA("GuiObject") and holder.Visible then
        return true
    end
    return false
end

local function isStopPhase(gui)
    if not gui then
        return false
    end
    for _, child in ipairs(gui:GetDescendants()) do
        if (child:IsA("TextLabel") or child:IsA("TextButton")) and child.Visible then
            local text = child.Text
            if typeof(text) == "string" and text ~= "" then
                local lower = string.lower(text)
                if string.find(lower, "stop") and (string.find(lower, "click") or string.find(lower, "tap")) then
                    return true
                end
            end
        end
    end
    return false
end

local function isFishImageButton(obj)
    if not obj or not obj:IsA("ImageButton") then
        return false
    end
    if not obj.Visible then
        return false
    end
    if obj.Active == false then
        return false
    end
    local nameLower = string.lower(obj.Name)
    if string.find(nameLower, "stop") or string.find(nameLower, "cancel") or string.find(nameLower, "fail") then
        return false
    end
    if string.find(nameLower, "fish") then
        return true
    end
    if ancestorNameContains(obj, "fishcontainer") or ancestorNameContains(obj, "fishicon") or ancestorNameContains(obj, "fish") then
        return true
    end
    return false
end

local lastFishClickTime = -math.huge
local fishClickDelay = Config.FishClickDelay

local function clickFishButtons(gui)
    if not gui then
        return
    end
    if isStopPhase(gui) then
        return
    end
    if tick() - lastFishClickTime < fishClickDelay then
        return
    end
    local buttons = {}
    for _, obj in ipairs(gui:GetDescendants()) do
        if isFishImageButton(obj) then
            table.insert(buttons, obj)
        end
    end
    if #buttons == 0 then
        return
    end
    table.sort(buttons, function(a, b)
        local pa = a.AbsolutePosition
        local pb = b.AbsolutePosition
        if pa.Y == pb.Y then
            return pa.X < pb.X
        else
            return pa.Y < pb.Y
        end
    end)
    local maxClicks = math.min(3, #buttons)
    task.wait(Config.FishClickWait)
    for i = 1, maxClicks do
        clickGuiObject(buttons[i])
        lastFishClickTime = tick()
        if i < maxClicks then
            task.wait(1.0)
        end
    end
end

local lastBarBurstTime = 0
local barBurstDelay = Config.BarBurstDelay

local function getFishingFrame(gui)
    if not gui then
        return nil
    end
    local fishingFrame = gui:FindFirstChild("FishingFrame", true)
    if fishingFrame and fishingFrame.Visible then
        return fishingFrame
    end
    local holder = gui:FindFirstChild("FishingHolder", true)
    if holder and holder.Visible then
        return holder
    end
    return nil
end

local function spamBarWhenAllowed(gui)
    if not gui then
        return
    end
    if isStopPhase(gui) then
        return
    end
    local fishingFrame = getFishingFrame(gui)
    if not fishingFrame then
        return
    end
    local barContainer = fishingFrame:FindFirstChild("BarContainer", true)
    if not barContainer or not barContainer.Visible then
        return
    end
    local bar = barContainer:FindFirstChild("Bar")
    if not bar or not bar.Visible then
        return
    end
    local color = bar.BackgroundColor3
    local isGreen = color.G >= color.R and color.G >= color.B and color.G > 0.3
    if not isGreen then
        return
    end
    if tick() - lastBarBurstTime < barBurstDelay then
        return
    end
    lastBarBurstTime = tick()
    for i = 1, 7 do
        clickGuiObject(bar)
        task.wait(Config.BarClickInterval)
    end
end

local function legitFishingRun()
    if FishingBusy then
        return
    end
    FishingBusy = true
    pcall(function()
        local character = getCharacter()
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then
            return
        end
        local rod = ensureRodEquipped()
        if not rod then
            return
        end
        task.wait(Config.RodEquipWait)
        holdMouseCenter(Config.CastHoldTime)
        local gui
        local startTime = tick()
        while tick() - startTime < Config.GuiTimeout do
            gui = getFishingGui()
            if gui then
                break
            end
            task.wait(Config.GuiWaitStep)
        end
        if not gui then
            return
        end
        local timeout = tick() + Config.FishingTimeout
        while stageStillActive(gui) and tick() < timeout do
            clickFishButtons(gui)
            spamBarWhenAllowed(gui)
            task.wait(0.07)
        end
    end)
    FishingBusy = false
end

-- Webhook Functions dengan embed dan warna berdasarkan rarity
local function sendHttpRequest(url, method, headers, body)
    local success, result = pcall(function()
        -- Coba berbagai metode HTTP
        if syn and syn.request then
            return syn.request({
                Url = url,
                Method = method,
                Headers = headers,
                Body = body
            })
        elseif request then
            return request({
                Url = url,
                Method = method,
                Headers = headers,
                Body = body
            })
        elseif http and http.request then
            return http.request({
                Url = url,
                Method = method,
                Headers = headers,
                Body = body
            })
        elseif http_request then
            return http_request({
                Url = url,
                Method = method,
                Headers = headers,
                Body = body
            })
        else
            return nil
        end
    end)
    
    return success, result
end

-- Fungsi untuk mendapatkan warna berdasarkan rarity
local function getRarityColor(rarity)
    local rarityLower = string.lower(rarity)
    
    if string.find(rarityLower, "mythic") then
        return 0xFF00FF  -- Magenta/Pink
    elseif string.find(rarityLower, "legend") or string.find(rarityLower, "legendary") then
        return 0xFFD700  -- Gold
    elseif string.find(rarityLower, "epic") then
        return 0x800080  -- Purple
    elseif string.find(rarityLower, "rare") then
        return 0x0000FF  -- Blue
    elseif string.find(rarityLower, "uncommon") then
        return 0x00FF00  -- Green
    elseif string.find(rarityLower, "common") then
        return 0x808080  -- Gray
    else
        return 0xFFFFFF  -- White (default)
    end
end

local function sendDiscordWebhook(fishData, username)
    if not WebhookEnabled or WebhookUrl == "" then
        return false
    end
    
    -- Dapatkan warna berdasarkan rarity
    local embedColor = getRarityColor(fishData.Rarity)
    
    -- Buat deskripsi yang menarik berdasarkan rarity
    local rarityLower = string.lower(fishData.Rarity)
    local description = ""
    if string.find(rarityLower, "mythic") then
        description = "🌟 **MYTHIC CATCH!** 🌟\nWow! You caught a legendary " .. fishData.Name .. "! This is extremely rare! 🏆"
    elseif string.find(rarityLower, "legend") or string.find(rarityLower, "legendary") then
        description = "✨ **LEGENDARY FISH!** ✨\nIncredible! A legendary " .. fishData.Name .. " has been caught! 🎉"
    elseif string.find(rarityLower, "epic") then
        description = "💜 **EPIC CATCH!** 💜\nAmazing! You reeled in an epic " .. fishData.Name .. "! 🌈"
    elseif string.find(rarityLower, "rare") then
        description = "🔵 **RARE FIND!** 🔵\nGreat job! A rare " .. fishData.Name .. " is now yours! 🎯"
    elseif string.find(rarityLower, "uncommon") then
        description = "🟢 **UNCOMMON CATCH!** 🟢\nNice! You caught an uncommon " .. fishData.Name .. "! 👍"
    else
        description = "🐟 **FISH CAUGHT!** 🐟\nYou successfully caught a " .. fishData.Name .. "! Keep fishing! 🎣"
    end
    
    -- Buat embed yang lebih menarik
    local embed = {
        {
            title = string.format("%s %s", (string.find(rarityLower, "mythic") and "🚀 MYTHIC CATCH!" or string.find(rarityLower, "legend") and "🏆 LEGENDARY CATCH!" or string.find(rarityLower, "epic") and "💎 EPIC CATCH!" or string.find(rarityLower, "rare") and "🎯 RARE CATCH!" or "🎣 FISH CAUGHT!"), fishData.Name),
            description = description,
            color = embedColor,
            fields = {
                {
                    name = "🐟 **Fish Name**",
                    value = "**" .. fishData.Name .. "**",
                    inline = true
                },
                {
                    name = "✨ **Rarity**",
                    value = "**" .. fishData.Rarity .. "**",
                    inline = true
                },
                {
                    name = "⚖️ **Weight**",
                    value = "**" .. fishData.Weight .. " kg**",
                    inline = true
                },
                {
                    name = "💰 **Price**",
                    value = "**" .. fishData.Price .. "** 💎",
                    inline = true
                },
                {
                    name = "🆔 **Fish ID**",
                    value = "**" .. (fishData.FishID or "Unknown") .. "**",
                    inline = true
                },
                {
                    name = "📍 **Location**",
                    value = "**" .. fishData.Location .. "**",
                    inline = false
                },
                {
                    name = "⏱️ **Catch Time**",
                    value = "**" .. fishData.CatchTime .. "**",
                    inline = true
                }
            },
            author = {
                name = username .. " caught this fish!",
                icon_url = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. 
                          (Players:GetUserIdFromNameAsync(username) or 1) .. 
                          "&width=150&height=150&format=png"
            },
            footer = {
                text = "anonymaous Ultimate Fishing Bot | Keep catching those fish! 🐠",
                icon_url = "https://i.imgur.com/WQqYhGH.png"
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            thumbnail = {
                url = "https://i.imgur.com/WQqYhGH.png"  -- Placeholder, bisa diganti dengan gambar ikan
            }
        }
    }
    
    local payload = {
        content = "🎉 **FISH CAUGHT ALERT!** 🎉 @" .. username .. " just caught something amazing!",
        username = "anonymaous Ultimate Fishing Bot",
        avatar_url = "https://i.imgur.com/WQqYhGH.png",
        embeds = embed
    }
    
    local headers = {
        ["Content-Type"] = "application/json"
    }
    
    local body = HttpService:JSONEncode(payload)
    
    local success, response = sendHttpRequest(WebhookUrl, "POST", headers, body)
    
    if success and response then
        print("[Webhook] Success! Status:", response.StatusCode)
        return true
    else
        print("[Webhook] Failed:", response)
        return false
    end
end

-- Fish Reward Hook
local giveFishConnections = {}

local function onFishReward(...)
    print("[DEBUG] Fish reward event received!")
    
    local args = { ... }
    
    -- DEBUG: Tampilkan semua argumen
    for i = 1, #args do
        print(string.format("[DEBUG] Arg %d: %s (type: %s)", i, tostring(args[i]), typeof(args[i])))
    end
    
    local fishData = {
        Name = "Unknown",
        Rarity = "Unknown",
        Weight = 0,
        Price = 0,
        FishID = "Unknown",
        Location = "Unknown",
        CatchTime = os.date("%H:%M:%S")
    }
    
    -- Analisis berdasarkan script IndoVoice
    local info = args[1]
    
    if type(info) == "table" then
        -- Coba dapatkan data dari table langsung
        fishData.Name = tostring(info.Name or info.FishName or info.name or "Unknown")
        fishData.Rarity = tostring(info.Rarity or info.rarity or "Unknown")
        fishData.Weight = tonumber(info.Weight or info.weight) or 0
        fishData.Price = tonumber(info.Price or info.EstimatedPrice or info.Value or info.value) or 0
        fishData.FishID = tostring(info.fishId or info.FishId or info.FishID or info.id or info.ID or info.idValue or fishData.FishID)
        
        if fishData.Name == "Unknown" and fishData.FishID ~= "Unknown" then
            print("[DEBUG] Found fish ID:", fishData.FishID)
            fishData.Name = "Fish ID: " .. fishData.FishID
        end
    elseif typeof(info) == "string" then
        -- Jika info adalah string, mungkin itu nama ikan
        fishData.Name = info
    elseif typeof(info) == "number" then
        -- Jika info adalah number, mungkin itu ID ikan
        fishData.FishID = tostring(info)
        fishData.Name = "Fish ID: " .. fishData.FishID
    end
    
    -- Cek argumen tambahan untuk weight, price, dan nama
    for i = 2, #args do
        local arg = args[i]
        if type(arg) == "number" then
            if fishData.Weight == 0 then
                fishData.Weight = arg
            elseif fishData.Price == 0 then
                fishData.Price = arg
            elseif fishData.FishID == "Unknown" then
                fishData.FishID = tostring(arg)
            end
        elseif type(arg) == "string" then
            if fishData.Name == "Unknown" then
                fishData.Name = arg
            elseif fishData.FishID == "Unknown" and tonumber(arg) then
                fishData.FishID = arg
            end
        elseif type(arg) == "table" then
            fishData.FishID = tostring(arg.fishId or arg.FishId or arg.FishID or arg.id or fishData.FishID)
        end
    end

    -- Dapatkan lokasi pemain jika tersedia
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        fishData.Location = string.format("%.0f, %.0f, %.0f", hrp.Position.X, hrp.Position.Y, hrp.Position.Z)
    end
    
    -- Format harga
    local formattedPrice = ""
    if fishData.Price > 0 then
        formattedPrice = tostring(fishData.Price)
        -- Format dengan koma untuk ribuan
        formattedPrice = formattedPrice:reverse():gsub("(%d%d%d)", "%1,"):reverse()
        formattedPrice = formattedPrice:gsub("^,", "")
    else
        formattedPrice = "?"
    end
    
    -- Format berat
    local formattedWeight = ""
    if fishData.Weight > 0 then
        formattedWeight = string.format("%.2f", fishData.Weight)
    else
        formattedWeight = "?"
    end
    
    -- Final data untuk webhook
    local finalFishData = {
        Name = fishData.Name,
        Rarity = fishData.Rarity,
        Weight = formattedWeight,
        Price = formattedPrice,
        FishID = fishData.FishID,
        Location = fishData.Location,
        CatchTime = fishData.CatchTime
    }
    
    -- Tampilkan di console
    print("[FISH CAUGHT]")
    print("Name:", finalFishData.Name)
    print("Rarity:", finalFishData.Rarity)
    print("Weight:", finalFishData.Weight, "kg")
    print("Price:", finalFishData.Price)
    
    -- Status print (from ori.lua)
    printStatus("FISH CAUGHT: " .. finalFishData.Name .. " (" .. finalFishData.Rarity .. ") - " .. finalFishData.Weight .. "kg - $" .. finalFishData.Price)
    
    local function buildFishNotification(data)
        local lines = {
            "🐟 " .. data.Name,
            "✨ " .. data.Rarity
        }

        if data.Weight ~= "?" then
            table.insert(lines, "⚖️ " .. data.Weight .. " kg")
        end
        if data.Price ~= "?" then
            table.insert(lines, "💰 " .. data.Price)
        end

        return table.concat(lines, "\n")
    end
    
    Notify(buildFishNotification(finalFishData), 5)
    
    -- Kirim ke Discord webhook dengan username
    if WebhookEnabled then
        local username = LocalPlayer.Name
        local success = sendDiscordWebhook(finalFishData, username)
        if success then
            print("[Webhook] Fish data sent to Discord!")
        else
            print("[Webhook] Failed to send to Discord")
        end
    end
end

-- Hook untuk fishing rewards
local function hookFishingRewards()
    print("[Hook] Searching for fishing reward remotes...")
    
    local hooked = 0
    
    -- Cari remote dengan nama yang mirip
    local remoteNames = {
        "GiveFishReward",
        "FishReward",
        "RewardFish",
        "OnFishCaught",
        "FishingReward",
        "GiveReward"
    }
    
    local function tryHookRemote(remote)
        if remote:IsA("RemoteEvent") then
            for _, name in ipairs(remoteNames) do
                if string.find(remote.Name:lower(), name:lower()) then
                    if not giveFishConnections[remote] then
                        local conn = remote.OnClientEvent:Connect(onFishReward)
                        giveFishConnections[remote] = conn
                        hooked = hooked + 1
                        print(string.format("[Hook] Successfully hooked: %s", remote:GetFullName()))
                    end
                    break
                end
            end
        end
    end
    
    -- Scan semua tempat
    local locationsToScan = {
        ReplicatedStorage,
        workspace,
        LocalPlayer:FindFirstChildOfClass("Backpack"),
        LocalPlayer.Character
    }
    
    for _, location in ipairs(locationsToScan) do
        if location then
            for _, obj in ipairs(location:GetDescendants()) do
                tryHookRemote(obj)
            end
        end
    end
    
    -- Hook untuk objek baru
    game.DescendantAdded:Connect(function(obj)
        tryHookRemote(obj)
    end)
    
    Notify(string.format("Hooked %d fishing reward remotes", hooked), 3, "info")
    
    -- Jika tidak ada yang terhook, coba hook semua RemoteEvent untuk debugging
    if hooked == 0 then
        print("[Hook] No specific fishing remotes found, hooking all RemoteEvents for debugging...")
        
        for _, remote in ipairs(game:GetDescendants()) do
            if remote:IsA("RemoteEvent") and not giveFishConnections[remote] then
                local conn = remote.OnClientEvent:Connect(function(...)
                    print(string.format("[DEBUG] RemoteEvent fired: %s", remote:GetFullName()))
                    onFishReward(...)
                end)
                giveFishConnections[remote] = conn
                hooked = hooked + 1
            end
        end
        
        print(string.format("[Hook] Hooked %d total RemoteEvents for debugging", hooked))
    end
end

-- Sell Functions
local function sellAllFishRemote()
    local folder = ReplicatedStorage:FindFirstChild("GameRemoteFunctions")
    if not folder then
        return false
    end
    local rf = folder:FindFirstChild("SellAllFishFunction")
    if not rf or not rf:IsA("RemoteFunction") then
        return false
    end
    local ok = pcall(function()
        return rf:InvokeServer()
    end)
    if ok then
        Notify("All fish sold successfully!", 3, "sold")
        printStatus("All fish sold successfully!")
        return true
    else
        Notify("Failed to sell fish", 3, "error")
        printStatus("Failed to sell fish")
        return false
    end
end

-- Spectate Functions
local function updateSpectatePlayers()
    SpectatePlayers = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(SpectatePlayers, plr)
        end
    end
    table.sort(SpectatePlayers, function(a, b)
        return a.Name < b.Name
    end)
end

local function spectateNextPlayer()
    updateSpectatePlayers()
    
    if #SpectatePlayers == 0 then
        Notify("No other players to spectate", 3, "info")
        printStatus("No other players to spectate")
        return
    end
    
    SpectateIndex = SpectateIndex + 1
    if SpectateIndex > #SpectatePlayers then
        SpectateIndex = 1
    end
    
    SpectateTarget = SpectatePlayers[SpectateIndex]
    if SpectateTarget and SpectateTarget.Character then
        local hum = SpectateTarget.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            workspace.CurrentCamera.CameraSubject = hum
            Notify("Spectating: " .. SpectateTarget.Name, 3, "spectating")
            printStatus("Spectating: " .. SpectateTarget.Name)
        end
    end
end

local function stopSpectating()
    SpectateTarget = nil
    local char = getCharacter()
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        workspace.CurrentCamera.CameraSubject = hum
        Notify("Stopped spectating", 3, "info")
        printStatus("Stopped spectating")
    end
end

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    if AntiAfkEnabled then
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(0.1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end
end)

-- Lock Position
RunService.Heartbeat:Connect(function()
    if LockPositionEnabled and LockedCFrame then
        local character = getCharacter()
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = LockedCFrame
            hrp.Velocity = Vector3.new()
            hrp.AssemblyLinearVelocity = Vector3.new()
            hrp.AssemblyAngularVelocity = Vector3.new()
        end
    end
end)

-- Keybind Handlers (only for desktop)
if IS_DESKTOP then
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Keybinds.ToggleAutoFish then
            AutoFishEnabled = not AutoFishEnabled
            Notify("Auto Fish: " .. (AutoFishEnabled and "ON" or "OFF"), 3, "toggle")
            printStatus("AUTO FISH " .. (AutoFishEnabled and "ENABLED" or "DISABLED"))
            
        elseif input.KeyCode == Keybinds.ToggleAutoSell then
            AutoSellEnabled = not AutoSellEnabled
            Notify("Auto Sell: " .. (AutoSellEnabled and "ON" or "OFF"), 3, "toggle")
            printStatus("AUTO SELL " .. (AutoSellEnabled and "ENABLED - Next sell in " .. Config.AutoSellIntervalMinutes .. " minutes" or "DISABLED"))
            if AutoSellEnabled then
                LastSellTime = tick()
            end
            
        elseif input.KeyCode == Keybinds.SellNow then
            printStatus("Manual sell triggered...")
            sellAllFishRemote()
            
        elseif input.KeyCode == Keybinds.ToggleLockPosition then
            LockPositionEnabled = not LockPositionEnabled
            if LockPositionEnabled then
                local character = getCharacter()
                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    LockedCFrame = hrp.CFrame
                end
            end
            Notify("Lock Position: " .. (LockPositionEnabled and "ON" or "OFF"), 3, "toggle")
            printStatus("LOCK POSITION " .. (LockPositionEnabled and "ENABLED" or "DISABLED"))
            
        elseif input.KeyCode == Keybinds.SpectateNext then
            spectateNextPlayer()
            
        elseif input.KeyCode == Keybinds.StopSpectating then
            stopSpectating()
            
        elseif input.KeyCode == Keybinds.ManualFishOnce then
            if not FishingBusy then
                printStatus("Manual fishing started...")
                task.spawn(legitFishingRun)
            end
        end
    end)
end

-- Auto Fish Loop
task.spawn(function()
    while true do
        if AutoFishEnabled then
            legitFishingRun()
            task.wait(Config.LoopWaitAutoFish)
        else
            task.wait(0.5)
        end
    end
end)

-- Auto Sell Loop
task.spawn(function()
    while true do
        if AutoSellEnabled then
            local now = tick()
            local interval = Config.AutoSellIntervalMinutes * 60
            if LastSellTime == 0 then
                LastSellTime = now
            end
            if now - LastSellTime >= interval then
                sellAllFishRemote()
                LastSellTime = now
            end
            task.wait(Config.LoopWaitAutoSell)
        else
            task.wait(1)
        end
    end
end)

-- Status Update Loop (from ori.lua)
task.spawn(function()
    while true do
        task.wait(Config.StatusUpdateInterval)
        if AutoFishEnabled or AutoSellEnabled then
            local status = ""
            if AutoFishEnabled then
                status = status .. "FISHING: ON "
            end
            if AutoSellEnabled then
                local timeLeft = math.max(0, (Config.AutoSellIntervalMinutes * 60) - (tick() - LastSellTime))
                local minutesLeft = math.floor(timeLeft / 60)
                status = status .. "| SELL: ON (" .. minutesLeft .. "m left)"
            end
            if status ~= "" then
                printStatus("Status: " .. status)
            end
        end
    end
end)

-- Mobile GUI
if IS_MOBILE then
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "anonymaousUltimateMobileGUI"
    screenGui.Parent = PlayerGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 170, 0, 300)
    mainFrame.Position = UDim2.new(0, 10, 0.5, -150)
    mainFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    mainFrame.BackgroundTransparency = 0.35
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 34)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    title.Text = "anonymaous"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 17
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = title

    local function createButton(text, posY)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0.9, 0, 0, 32)
        button.Position = UDim2.new(0.05, 0, 0, posY)
        button.BackgroundColor3 = Color3.fromRGB(66, 66, 66)
        button.Text = text
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextSize = 14
        button.Font = Enum.Font.Gotham
        button.Parent = mainFrame

        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 6)
        buttonCorner.Parent = button
        return button
    end

    local autoFishButton = createButton("Auto Fish: OFF", 46)
    local autoSellButton = createButton("Auto Sell: OFF", 86)
    local sellNowButton = createButton("Sell All Now", 126)
    local lockPosButton = createButton("Lock Position: OFF", 166)
    local spectateNextButton = createButton("Spectate Next", 206)
    local stopSpectateButton = createButton("Stop Spectating", 246)

    autoFishButton.MouseButton1Click:Connect(function()
        AutoFishEnabled = not AutoFishEnabled
        autoFishButton.Text = "Auto Fish: " .. (AutoFishEnabled and "ON" or "OFF")
        autoFishButton.BackgroundColor3 = AutoFishEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(66, 66, 66)
        Notify("Auto Fish: " .. (AutoFishEnabled and "ON" or "OFF"), 3, "toggle")
        printStatus("AUTO FISH " .. (AutoFishEnabled and "ENABLED" or "DISABLED"))
    end)

    autoSellButton.MouseButton1Click:Connect(function()
        AutoSellEnabled = not AutoSellEnabled
        autoSellButton.Text = "Auto Sell: " .. (AutoSellEnabled and "ON" or "OFF")
        autoSellButton.BackgroundColor3 = AutoSellEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(66, 66, 66)
        Notify("Auto Sell: " .. (AutoSellEnabled and "ON" or "OFF"), 3, "toggle")
        printStatus("AUTO SELL " .. (AutoSellEnabled and "ENABLED - Next sell in " .. Config.AutoSellIntervalMinutes .. " minutes" or "DISABLED"))
        if AutoSellEnabled then
            LastSellTime = tick()
        end
    end)

    sellNowButton.MouseButton1Click:Connect(function()
        printStatus("Manual sell triggered...")
        sellAllFishRemote()
    end)

    lockPosButton.MouseButton1Click:Connect(function()
        LockPositionEnabled = not LockPositionEnabled
        lockPosButton.Text = "Lock Position: " .. (LockPositionEnabled and "ON" or "OFF")
        lockPosButton.BackgroundColor3 = LockPositionEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(66, 66, 66)
        if LockPositionEnabled then
            local character = getCharacter()
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            if hrp then
                LockedCFrame = hrp.CFrame
            end
        end
        Notify("Lock Position: " .. (LockPositionEnabled and "ON" or "OFF"), 3, "toggle")
        printStatus("LOCK POSITION " .. (LockPositionEnabled and "ENABLED" or "DISABLED"))
    end)

    spectateNextButton.MouseButton1Click:Connect(function()
        spectateNextPlayer()
    end)

    stopSpectateButton.MouseButton1Click:Connect(function()
        stopSpectating()
    end)

    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 34, 0, 34)
    closeButton.Position = UDim2.new(1, -38, 0, 3)
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 18
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = mainFrame

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton

    closeButton.MouseButton1Click:Connect(function()
        screenGui.Enabled = false
    end)

    local dragging
    local dragInput
    local dragStart
    local startPos

    local function update(input)
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end

    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    mainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- Desktop GUI
if IS_DESKTOP then
    -- Buat ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "anonymaousUltimateDesktopGUI"
    screenGui.Parent = PlayerGui
    
    -- Container utama
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 170, 0, 300)
    mainFrame.Position = UDim2.new(1, -180, 0.5, -150)  -- Right side
    mainFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
    mainFrame.BackgroundTransparency = 0.4
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    -- Judul
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 34)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    title.Text = "anonymaous"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 17
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = title
    
    -- Tombol Auto Fish
    local autoFishButton = Instance.new("TextButton")
    autoFishButton.Size = UDim2.new(0.9, 0, 0, 32)
    autoFishButton.Position = UDim2.new(0.05, 0, 0, 46)
    autoFishButton.BackgroundColor3 = Color3.fromRGB(66, 66, 66)
    autoFishButton.Text = "Auto Fish: OFF"
    autoFishButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoFishButton.TextSize = 14
    autoFishButton.Font = Enum.Font.Gotham
    autoFishButton.Parent = mainFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = autoFishButton
    
    autoFishButton.MouseButton1Click:Connect(function()
        AutoFishEnabled = not AutoFishEnabled
        autoFishButton.Text = "Auto Fish: " .. (AutoFishEnabled and "ON" or "OFF")
        autoFishButton.BackgroundColor3 = AutoFishEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60)
        Notify("Auto Fish: " .. (AutoFishEnabled and "ON" or "OFF"), 3, "toggle")
        printStatus("AUTO FISH " .. (AutoFishEnabled and "ENABLED" or "DISABLED"))
    end)
    
    -- Tombol Auto Sell
    local autoSellButton = Instance.new("TextButton")
    autoSellButton.Size = UDim2.new(0.9, 0, 0, 32)
    autoSellButton.Position = UDim2.new(0.05, 0, 0, 86)
    autoSellButton.BackgroundColor3 = Color3.fromRGB(66, 66, 66)
    autoSellButton.Text = "Auto Sell: OFF"
    autoSellButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoSellButton.TextSize = 14
    autoSellButton.Font = Enum.Font.Gotham
    autoSellButton.Parent = mainFrame
    autoSellButton.ZIndex = 2
    
    local buttonCorner2 = Instance.new("UICorner")
    buttonCorner2.CornerRadius = UDim.new(0, 6)
    buttonCorner2.Parent = autoSellButton
    
    autoSellButton.MouseButton1Click:Connect(function()
        AutoSellEnabled = not AutoSellEnabled
        autoSellButton.Text = "Auto Sell: " .. (AutoSellEnabled and "ON" or "OFF")
        autoSellButton.BackgroundColor3 = AutoSellEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60)
        Notify("Auto Sell: " .. (AutoSellEnabled and "ON" or "OFF"), 3, "toggle")
        printStatus("AUTO SELL " .. (AutoSellEnabled and "ENABLED - Next sell in " .. Config.AutoSellIntervalMinutes .. " minutes" or "DISABLED"))
        if AutoSellEnabled then
            LastSellTime = tick()
        end
    end)
    
    -- Tombol Sell Now
    local sellNowButton = Instance.new("TextButton")
    sellNowButton.Size = UDim2.new(0.9, 0, 0, 32)
    sellNowButton.Position = UDim2.new(0.05, 0, 0, 126)
    sellNowButton.BackgroundColor3 = Color3.fromRGB(66, 66, 66)
    sellNowButton.Text = "Sell All Now"
    sellNowButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    sellNowButton.TextSize = 14
    sellNowButton.Font = Enum.Font.Gotham
    sellNowButton.Parent = mainFrame
    
    local buttonCorner3 = Instance.new("UICorner")
    buttonCorner3.CornerRadius = UDim.new(0, 6)
    buttonCorner3.Parent = sellNowButton
    
    sellNowButton.MouseButton1Click:Connect(function()
        printStatus("Manual sell triggered...")
        sellAllFishRemote()
    end)
    
    -- Tombol Lock Position
    local lockPosButton = Instance.new("TextButton")
    lockPosButton.Size = UDim2.new(0.9, 0, 0, 32)
    lockPosButton.Position = UDim2.new(0.05, 0, 0, 166)
    lockPosButton.BackgroundColor3 = Color3.fromRGB(66, 66, 66)
    lockPosButton.Text = "Lock Position: OFF"
    lockPosButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    lockPosButton.TextSize = 14
    lockPosButton.Font = Enum.Font.Gotham
    lockPosButton.Parent = mainFrame
    
    local buttonCorner4 = Instance.new("UICorner")
    buttonCorner4.CornerRadius = UDim.new(0, 6)
    buttonCorner4.Parent = lockPosButton
    
    lockPosButton.MouseButton1Click:Connect(function()
        LockPositionEnabled = not LockPositionEnabled
        lockPosButton.Text = "Lock Position: " .. (LockPositionEnabled and "ON" or "OFF")
        lockPosButton.BackgroundColor3 = LockPositionEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(60, 60, 60)
        if LockPositionEnabled then
            local character = getCharacter()
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            if hrp then
                LockedCFrame = hrp.CFrame
            end
        end
        Notify("Lock Position: " .. (LockPositionEnabled and "ON" or "OFF"), 3, "toggle")
        printStatus("LOCK POSITION " .. (LockPositionEnabled and "ENABLED" or "DISABLED"))
    end)
    
    -- Tombol Spectate Next
    local spectateNextButton = Instance.new("TextButton")
    spectateNextButton.Size = UDim2.new(0.9, 0, 0, 32)
    spectateNextButton.Position = UDim2.new(0.05, 0, 0, 206)
    spectateNextButton.BackgroundColor3 = Color3.fromRGB(66, 66, 66)
    spectateNextButton.Text = "Spectate Next"
    spectateNextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    spectateNextButton.TextSize = 14
    spectateNextButton.Font = Enum.Font.Gotham
    spectateNextButton.Parent = mainFrame
    
    local buttonCorner5 = Instance.new("UICorner")
    buttonCorner5.CornerRadius = UDim.new(0, 6)
    buttonCorner5.Parent = spectateNextButton
    
    spectateNextButton.MouseButton1Click:Connect(function()
        spectateNextPlayer()
    end)
    
    -- Tombol Stop Spectating
    local stopSpectateButton = Instance.new("TextButton")
    stopSpectateButton.Size = UDim2.new(0.9, 0, 0, 32)
    stopSpectateButton.Position = UDim2.new(0.05, 0, 0, 246)
    stopSpectateButton.BackgroundColor3 = Color3.fromRGB(66, 66, 66)
    stopSpectateButton.Text = "Stop Spectating"
    stopSpectateButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    stopSpectateButton.TextSize = 14
    stopSpectateButton.Font = Enum.Font.Gotham
    stopSpectateButton.Parent = mainFrame

    local buttonCorner6 = Instance.new("UICorner")
    buttonCorner6.CornerRadius = UDim.new(0, 6)
    buttonCorner6.Parent = stopSpectateButton

    stopSpectateButton.MouseButton1Click:Connect(function()
        stopSpectating()
    end)

    -- Tombol Close (untuk minimize)
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 34, 0, 34)
    closeButton.Position = UDim2.new(1, -38, 0, 3)
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 18
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = mainFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        screenGui.Enabled = false
    end)
    
    -- Drag functionality for desktop (mouse)
    local dragging
    local dragInput
    local dragStart
    local startPos
    
    local function update(input)
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    
    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    mainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- Hook fishing rewards setelah delay
task.wait(Config.HookDelay)
hookFishingRewards()

-- Initial status print
printStatus("=== ULTIMATE FISHING SCRIPT LOADED ===")
printStatus("CONTROLS:")
printStatus("  F - Toggle Auto Fish")
printStatus("  G - Toggle Auto Sell")
printStatus("  H - Sell All Fish Now")
printStatus("  L - Toggle Lock Position")
printStatus("  K - Spectate Next Player")
printStatus("  J - Stop Spectating")
printStatus("  P - Manual Fish Once")
printStatus("================================")

-- Info script
Notify("Ultimate Script Ready!", 5, "loaded")
if IS_DESKTOP then
    Notify("Desktop GUI loaded on the right side! Use mouse to drag.", 5, "loaded")
else
    Notify("Mobile GUI loaded! Tap the Ultimate button to open controls.", 5, "loaded")
end
