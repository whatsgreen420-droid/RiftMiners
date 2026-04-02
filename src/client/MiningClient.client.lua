-- MiningClient.client.lua
-- Handles click-to-mine, UI notifications, and interaction detection

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

-- Remote events
local MineBlockEvent = ReplicatedStorage:WaitForChild("MineBlock")
local SellOresEvent = ReplicatedStorage:WaitForChild("SellOres")
local NotifyEvent = ReplicatedStorage:WaitForChild("Notify")

------------------------------------------------------------------------
-- MINING SYSTEM (click to mine)
------------------------------------------------------------------------
local MINE_RANGE = 20
local miningCooldown = 0.3 -- seconds between hits
local lastMineTime = 0

local function getTargetBlock()
	local ray = camera:ScreenPointToRay(mouse.X, mouse.Y)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { player.Character }

	local result = workspace:Raycast(ray.Origin, ray.Direction * MINE_RANGE, raycastParams)
	if result and result.Instance then
		local block = result.Instance
		if block:GetAttribute("OreType") then
			return block
		end
	end
	return nil
end

-- Mining on click
mouse.Button1Down:Connect(function()
	local now = tick()
	if now - lastMineTime < miningCooldown then return end
	lastMineTime = now

	local block = getTargetBlock()
	if block then
		MineBlockEvent:FireServer(block)

		-- Visual feedback: flash the block
		local originalColor = block.Color
		block.Color = Color3.new(1, 1, 1)
		task.delay(0.1, function()
			if block and block.Parent then
				block.Color = originalColor
			end
		end)
	end
end)

-- Hold to continuously mine
local isHolding = false

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isHolding = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isHolding = false
	end
end)

RunService.Heartbeat:Connect(function()
	if isHolding then
		local now = tick()
		if now - lastMineTime >= miningCooldown then
			lastMineTime = now
			local block = getTargetBlock()
			if block then
				MineBlockEvent:FireServer(block)

				local originalColor = block.Color
				block.Color = Color3.new(1, 1, 1)
				task.delay(0.1, function()
					if block and block.Parent then
						block.Color = originalColor
					end
				end)
			end
		end
	end
end)

------------------------------------------------------------------------
-- BLOCK HIGHLIGHT (hover effect)
------------------------------------------------------------------------
local highlight = Instance.new("Highlight")
highlight.FillTransparency = 0.8
highlight.OutlineTransparency = 0
highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
highlight.Parent = nil

local lastHighlighted = nil

RunService.Heartbeat:Connect(function()
	local block = getTargetBlock()
	if block and block ~= lastHighlighted then
		highlight.Adornee = block
		highlight.Parent = block

		-- Color the outline based on rarity
		local rarity = block:GetAttribute("OreRarity")
		if rarity == "Common" then
			highlight.OutlineColor = Color3.fromRGB(180, 180, 180)
		elseif rarity == "Uncommon" then
			highlight.OutlineColor = Color3.fromRGB(30, 200, 30)
		elseif rarity == "Rare" then
			highlight.OutlineColor = Color3.fromRGB(30, 144, 255)
		elseif rarity == "Epic" then
			highlight.OutlineColor = Color3.fromRGB(163, 53, 238)
		elseif rarity == "Legendary" then
			highlight.OutlineColor = Color3.fromRGB(255, 165, 0)
		elseif rarity == "Mythical" then
			highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
		end

		lastHighlighted = block
	elseif not block and lastHighlighted then
		highlight.Adornee = nil
		highlight.Parent = nil
		lastHighlighted = nil
	end
end)

------------------------------------------------------------------------
-- NOTIFICATION SYSTEM
------------------------------------------------------------------------
local notifGui = Instance.new("ScreenGui")
notifGui.Name = "NotificationGui"
notifGui.ResetOnSpawn = false
notifGui.Parent = player.PlayerGui

local notifFrame = Instance.new("Frame")
notifFrame.Name = "NotifContainer"
notifFrame.Size = UDim2.new(0, 195, 1, 0)
notifFrame.Position = UDim2.new(1, -202, 0, 8)
notifFrame.BackgroundTransparency = 1
notifFrame.Parent = notifGui

local notifLayout = Instance.new("UIListLayout")
notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
notifLayout.Padding = UDim.new(0, 5)
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Top
notifLayout.Parent = notifFrame

NotifyEvent.OnClientEvent:Connect(function(data)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 42)
	card.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	card.BackgroundTransparency = 0.2
	card.BorderSizePixel = 0
	card.Parent = notifFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = data.Color or Color3.new(1, 1, 1)
	stroke.Thickness = 2
	stroke.Parent = card

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -10, 0, 25)
	title.Position = UDim2.new(0, 5, 0, 5)
	title.BackgroundTransparency = 1
	title.Text = data.Title or ""
	title.TextColor3 = data.Color or Color3.new(1, 1, 1)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = card

	local msg = Instance.new("TextLabel")
	msg.Size = UDim2.new(1, -10, 0, 20)
	msg.Position = UDim2.new(0, 5, 0, 30)
	msg.BackgroundTransparency = 1
	msg.Text = data.Message or ""
	msg.TextColor3 = Color3.fromRGB(200, 200, 200)
	msg.TextScaled = true
	msg.Font = Enum.Font.Gotham
	msg.TextXAlignment = Enum.TextXAlignment.Left
	msg.Parent = card

	-- Slide in
	card.Position = UDim2.new(1, 0, 0, 0)
	local tweenIn = TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		Position = UDim2.new(0, 0, 0, 0)
	})
	tweenIn:Play()

	-- Auto remove
	local duration = data.Duration or 3
	task.delay(duration, function()
		local tweenOut = TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
			Position = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
		})
		tweenOut:Play()
		tweenOut.Completed:Wait()
		card:Destroy()
	end)
end)

------------------------------------------------------------------------
-- CROSSHAIR
------------------------------------------------------------------------
local crosshair = Instance.new("Frame")
crosshair.Name = "Crosshair"
crosshair.Size = UDim2.new(0, 4, 0, 4)
crosshair.Position = UDim2.new(0.5, -2, 0.5, -2)
crosshair.BackgroundColor3 = Color3.new(1, 1, 1)
crosshair.BorderSizePixel = 0
crosshair.Parent = notifGui

local crossCorner = Instance.new("UICorner")
crossCorner.CornerRadius = UDim.new(1, 0)
crossCorner.Parent = crosshair

print("[RiftMiners] Mining client loaded! ⛏️")
