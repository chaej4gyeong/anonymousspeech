-- Pumpkin ESP (standalone)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LP = Players.LocalPlayer

local ESP_FOLDER = Instance.new("Folder")
ESP_FOLDER.Name = "PumpkinESP"
ESP_FOLDER.Parent = (gethui and gethui()) or game:GetService("CoreGui")

local draws = {} -- [model] = {hl, bill, box}

local function getPart(m)
	if m:IsA("BasePart") then return m end
	return m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart", true)
end

local function clearOne(m)
	local d = draws[m]
	if not d then return end
	for _, x in pairs(d) do
		pcall(function() x:Destroy() end)
	end
	draws[m] = nil
end

local function clearAll()
	for m in pairs(draws) do clearOne(m) end
	for _, c in ipairs(ESP_FOLDER:GetChildren()) do
		pcall(function() c:Destroy() end)
	end
end

local function addESP(model)
	if draws[model] then return end
	local part = getPart(model)
	if not part then return end

	local hl = Instance.new("Highlight")
	hl.Name = "PumpkinHL"
	hl.Adornee = model
	hl.FillColor = Color3.fromRGB(255, 140, 0)
	hl.OutlineColor = Color3.fromRGB(255, 220, 80)
	hl.FillTransparency = 0.55
	hl.OutlineTransparency = 0
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Parent = ESP_FOLDER

	local bill = Instance.new("BillboardGui")
	bill.Name = "PumpkinTag"
	bill.Adornee = part
	bill.Size = UDim2.fromOffset(120, 28)
	bill.StudsOffset = Vector3.new(0, 2.5, 0)
	bill.AlwaysOnTop = true
	bill.Parent = ESP_FOLDER

	local lab = Instance.new("TextLabel")
	lab.Size = UDim2.fromScale(1, 1)
	lab.BackgroundTransparency = 1
	lab.Text = model.Name
	lab.TextColor3 = Color3.fromRGB(255, 200, 60)
	lab.TextStrokeTransparency = 0.3
	lab.Font = Enum.Font.GothamBold
	lab.TextSize = 14
	lab.Parent = bill

	draws[model] = {hl = hl, bill = bill}
end

local function scan()
	local map = Workspace:FindFirstChild("Map")
	local folder = map and map:FindFirstChild("Pumpkins")
	if not folder then
		-- fallback: any descendant named like pumpkin
		for _, d in ipairs(Workspace:GetDescendants()) do
			if d:IsA("Model") or d:IsA("BasePart") then
				local n = string.lower(d.Name)
				if string.find(n, "pumpkin") then
					addESP(d)
				end
			end
		end
		return
	end
	for _, ch in ipairs(folder:GetChildren()) do
		if ch:IsA("Model") or ch:IsA("BasePart") then
			addESP(ch)
		end
	end
	-- cleanup removed
	for m in pairs(draws) do
		if not m.Parent then clearOne(m) end
	end
end

scan()
Workspace.DescendantAdded:Connect(function(d)
	task.defer(function()
		local n = string.lower(d.Name)
		if string.find(n, "pumpkin") then
			addESP(d:IsA("Model") and d or d)
		end
	end)
end)

RunService.Heartbeat:Connect(function()
	if tick() % 1.5 > 0.05 then return end
	scan()
end)

-- stop: clearAll()
_G.PumpkinESP_Stop = clearAll
print("[PumpkinESP] on | stop: _G.PumpkinESP_Stop()")
