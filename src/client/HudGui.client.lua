-- HudGui.client.lua
-- Mining Sim style HUD: depth counter, coin display, backpack bar, side buttons
-- Based on reference images from popular mining games

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GetPlayerDataFunc = ReplicatedStorage:WaitForChild("GetPlayerData")
local PrestigeEvent = ReplicatedStorage:WaitForChild("Prestige")
local SellOresEvent = ReplicatedStorage:WaitForChild("SellOres")
local TeleportToHubEvent = ReplicatedStorage:WaitForChild("TeleportToHub")

------------------------------------------------------------------------
-- MAIN HUD SCREEN GUI
------------------------------------------------------------------------
local hudGui = Instance.new("ScreenGui")
hudGui.Name = "HudGui"
hudGui.ResetOnSpawn = false
hudGui.Parent = playerGui

-- ===== DEPTH DISPLAY (top center) =====
local depthFrame = Instance.new("Frame")
depthFrame.Name = "DepthDisplay"
depthFrame.Size = UDim2.new(0, 250, 0, 70)
depthFrame.Position = UDim2.new(0.5, -125, 0, 5)
depthFrame.BackgroundTransparency = 1
depthFrame.Parent = hudGui

local depthLabel = Instance.new("TextLabel")
depthLabel.Name = "DepthLabel"
depthLabel.Size = UDim2.new(1, 0, 0, 25)
depthLabel.BackgroundTransparency = 1
depthLabel.Text = "Depth"
depthLabel.TextColor3 = Color3.new(1, 1, 1)
depthLabel.TextScaled = true
depthLabel.Font = Enum.Font.GothamBold
depthLabel.TextStrokeTransparency = 0.3
depthLabel.Parent = depthFrame

local depthValue = Instance.new("TextLabel")
depthValue.Name = "DepthValue"
depthValue.Size = UDim2.new(1, 0, 0, 35)
depthValue.Position = UDim2.new(0, 0, 0, 25)
depthValue.BackgroundTransparency = 1
depthValue.Text = "0 Blocks"
depthValue.TextColor3 = Color3.new(1, 1, 1)
depthValue.TextScaled = true
depthValue.Font = Enum.Font.GothamBlack
depthValue.TextStrokeTransparency = 0
depthValue.Parent = depthFrame

-- ===== LEFT SIDE: Currency + Backpack =====
local leftPanel = Instance.new("Frame")
leftPanel.Name = "LeftPanel"
leftPanel.Size = UDim2.new(0, 220, 0, 180)
leftPanel.Position = UDim2.new(0, 10, 0.3, 0)
leftPanel.BackgroundTransparency = 1
leftPanel.Parent = hudGui

-- Coins display
local coinFrame = Instance.new("Frame")
coinFrame.Size = UDim2.new(1, 0, 0, 40)
coinFrame.BackgroundColor3 = Color3.fromRGB(0, 150, 220)
coinFrame.BackgroundTransparency = 0.2
coinFrame.BorderSizePixel = 0
coinFrame.Parent = leftPanel
Instance.new("UICorner", coinFrame).CornerRadius = UDim.new(0, 20)

local coinIcon = Instance.new("TextLabel")
coinIcon.Size = UDim2.new(0, 35, 0, 35)
coinIcon.Position = UDim2.new(0, 5, 0, 2)
coinIcon.BackgroundTransparency = 1
coinIcon.Text = "💰"
coinIcon.TextScaled = true
coinIcon.Parent = coinFrame

local coinLabel = Instance.new("TextLabel")
coinLabel.Name = "CoinLabel"
coinLabel.Size = UDim2.new(1, -50, 1, 0)
coinLabel.Position = UDim2.new(0, 40, 0, 0)
coinLabel.BackgroundTransparency = 1
coinLabel.Text = "0"
coinLabel.TextColor3 = Color3.new(1, 1, 1)
coinLabel.TextScaled = true
coinLabel.Font = Enum.Font.GothamBold
coinLabel.TextXAlignment = Enum.TextXAlignment.Left
coinLabel.Parent = coinFrame

-- Backpack capacity bar
local bpFrame = Instance.new("Frame")
bpFrame.Size = UDim2.new(1, 0, 0, 40)
bpFrame.Position = UDim2.new(0, 0, 0, 45)
bpFrame.BackgroundColor3 = Color3.fromRGB(0, 150, 220)
bpFrame.BackgroundTransparency = 0.2
bpFrame.BorderSizePixel = 0
bpFrame.Parent = leftPanel
Instance.new("UICorner", bpFrame).CornerRadius = UDim.new(0, 20)

local bpIcon = Instance.new("TextLabel")
bpIcon.Size = UDim2.new(0, 35, 0, 35)
bpIcon.Position = UDim2.new(0, 5, 0, 2)
bpIcon.BackgroundTransparency = 1
bpIcon.Text = "🎒"
bpIcon.TextScaled = true
bpIcon.Parent = bpFrame

local bpLabel = Instance.new("TextLabel")
bpLabel.Name = "BpLabel"
bpLabel.Size = UDim2.new(1, -50, 1, 0)
bpLabel.Position = UDim2.new(0, 40, 0, 0)
bpLabel.BackgroundTransparency = 1
bpLabel.Text = "0 / 15"
bpLabel.TextColor3 = Color3.new(1, 1, 1)
bpLabel.TextScaled = true
bpLabel.Font = Enum.Font.GothamBold
bpLabel.TextXAlignment = Enum.TextXAlignment.Left
bpLabel.Parent = bpFrame

-- Prestige level display
local prestFrame = Instance.new("Frame")
prestFrame.Size = UDim2.new(1, 0, 0, 40)
prestFrame.Position = UDim2.new(0, 0, 0, 90)
prestFrame.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
prestFrame.BackgroundTransparency = 0.2
prestFrame.BorderSizePixel = 0
prestFrame.Parent = leftPanel
Instance.new("UICorner", prestFrame).CornerRadius = UDim.new(0, 20)

local prestIcon = Instance.new("TextLabel")
prestIcon.Size = UDim2.new(0, 35, 0, 35)
prestIcon.Position = UDim2.new(0, 5, 0, 2)
prestIcon.BackgroundTransparency = 1
prestIcon.Text = "⭐"
prestIcon.TextScaled = true
prestIcon.Parent = prestFrame

local prestLabel = Instance.new("TextLabel")
prestLabel.Name = "PrestigeLabel"
prestLabel.Size = UDim2.new(1, -50, 1, 0)
prestLabel.Position = UDim2.new(0, 40, 0, 0)
prestLabel.BackgroundTransparency = 1
prestLabel.Text = "0"
prestLabel.TextColor3 = Color3.new(1, 1, 1)
prestLabel.TextScaled = true
prestLabel.Font = Enum.Font.GothamBold
prestLabel.TextXAlignment = Enum.TextXAlignment.Left
prestLabel.Parent = prestFrame

-- Left side action buttons (Sell, Prestige)
local sellBtn = Instance.new("TextButton")
sellBtn.Size = UDim2.new(0, 70, 0, 50)
sellBtn.Position = UDim2.new(0, 0, 0, 135)
sellBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
sellBtn.Text = "Sell"
sellBtn.TextColor3 = Color3.new(1,1,1)
sellBtn.TextScaled = true
sellBtn.Font = Enum.Font.GothamBold
sellBtn.BorderSizePixel = 0
sellBtn.Parent = leftPanel
Instance.new("UICorner", sellBtn).CornerRadius = UDim.new(0, 12)
sellBtn.MouseButton1Click:Connect(function() SellOresEvent:FireServer() end)

local rebBtn = Instance.new("TextButton")
rebBtn.Size = UDim2.new(0, 70, 0, 50)
rebBtn.Position = UDim2.new(0, 75, 0, 135)
rebBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0)
rebBtn.Text = "⭐\nPrestige"
rebBtn.TextColor3 = Color3.new(1,1,1)
rebBtn.TextScaled = true
rebBtn.Font = Enum.Font.GothamBold
rebBtn.BorderSizePixel = 0
rebBtn.Parent = leftPanel
Instance.new("UICorner", rebBtn).CornerRadius = UDim.new(0, 12)
rebBtn.MouseButton1Click:Connect(function() PrestigeEvent:FireServer() end)

------------------------------------------------------------------------
-- UPDATE HUD PERIODICALLY
------------------------------------------------------------------------
local function formatNum(n)
	if n >= 1000000 then return string.format("%.1fM", n/1000000)
	elseif n >= 1000 then return string.format("%.1fK", n/1000)
	end
	return tostring(n)
end

task.spawn(function()
	while true do
		task.wait(0.5)

		-- Depth from Y position
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local y = char.HumanoidRootPart.Position.Y
			local depth = math.max(0, math.floor(-y / 6))
			if y > -5 then depth = 0 end
			depthValue.Text = depth .. " Blocks"
		end

		-- Player data
		local ok, data = pcall(function() return GetPlayerDataFunc:InvokeServer() end)
		if ok and data then
			coinLabel.Text = formatNum(data.Cash or 0)
			bpLabel.Text = (data.InventoryCount or 0) .. " / " .. (data.BackpackCapacity or 15)
			prestLabel.Text = tostring(data.PrestigeLevel or 0)
		end
	end
end)

print("[RiftMiners] HUD loaded! ⛏️")
