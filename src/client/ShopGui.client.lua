-- ShopGui.client.lua
-- Scrollable shop GUI for Pickaxes, Backpacks. Opens near shop zones.
-- NO upgrade buttons in the mine — players must return to surface.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local BuyPickaxeEvent = ReplicatedStorage:WaitForChild("BuyPickaxe")
local BuyBackpackEvent = ReplicatedStorage:WaitForChild("BuyBackpack")
local GetShopDataFunc = ReplicatedStorage:WaitForChild("GetShopData")
local GetPlayerDataFunc = ReplicatedStorage:WaitForChild("GetPlayerData")
local NotifyEvent = ReplicatedStorage:WaitForChild("Notify")
local SellOresEvent = ReplicatedStorage:WaitForChild("SellOres")
local TeleportToHubEvent = ReplicatedStorage:WaitForChild("TeleportToHub")
local PrestigeEvent = ReplicatedStorage:WaitForChild("Prestige")

------------------------------------------------------------------------
-- CREATE THE SHOP SCREEN GUI
------------------------------------------------------------------------
local shopGui = Instance.new("ScreenGui")
shopGui.Name = "ShopGui"
shopGui.ResetOnSpawn = false
shopGui.Enabled = false
shopGui.Parent = playerGui

-- Main frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 420, 0, 500)
mainFrame.Position = UDim2.new(0.5, -210, 0.5, -250)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = shopGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(138, 43, 226)
stroke.Thickness = 2
stroke.Parent = mainFrame

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, 0, 0, 50)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "SHOP"
titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainFrame

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -45, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = mainFrame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

closeBtn.MouseButton1Click:Connect(function()
	shopGui.Enabled = false
end)

-- Scroll frame for items
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "ItemList"
scrollFrame.Size = UDim2.new(1, -20, 1, -60)
scrollFrame.Position = UDim2.new(0, 10, 0, 55)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 6
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(138, 43, 226)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 6)
listLayout.Parent = scrollFrame

-- Auto-resize canvas
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end)

------------------------------------------------------------------------
-- RARITY COLORS
------------------------------------------------------------------------
local rarityColors = {
	Common = Color3.fromRGB(180, 180, 180),
	Uncommon = Color3.fromRGB(30, 200, 30),
	Rare = Color3.fromRGB(30, 144, 255),
	Epic = Color3.fromRGB(163, 53, 238),
	Legendary = Color3.fromRGB(255, 165, 0),
}

------------------------------------------------------------------------
-- POPULATE SHOP
------------------------------------------------------------------------
local function clearItems()
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
end

local function formatNumber(n)
	if n >= 1000000 then
		return string.format("%.1fM", n / 1000000)
	elseif n >= 1000 then
		return string.format("%.1fK", n / 1000)
	end
	return tostring(n)
end

local function openShop(shopType, title)
	clearItems()
	titleLabel.Text = title

	local items = GetShopDataFunc:InvokeServer(shopType)
	local pData = GetPlayerDataFunc:InvokeServer()
	if not items or not pData then return end

	for i, item in ipairs(items) do
		local card = Instance.new("Frame")
		card.Name = "Item_" .. (item.Name or i)
		card.Size = UDim2.new(1, 0, 0, 70)
		card.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
		card.BorderSizePixel = 0
		card.LayoutOrder = i
		card.Parent = scrollFrame

		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

		-- Color stripe on left
		local colorStripe = Instance.new("Frame")
		colorStripe.Size = UDim2.new(0, 4, 1, -8)
		colorStripe.Position = UDim2.new(0, 4, 0, 4)
		colorStripe.BackgroundColor3 = item.Color or rarityColors[item.Rarity or "Common"] or Color3.new(1,1,1)
		colorStripe.BorderSizePixel = 0
		colorStripe.Parent = card
		Instance.new("UICorner", colorStripe).CornerRadius = UDim.new(0, 2)

		-- Item name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.55, 0, 0, 25)
		nameLabel.Position = UDim2.new(0, 15, 0, 5)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = item.Name
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = card

		-- Stats line
		local statsText = ""
		if shopType == "Pickaxes" then
			statsText = "Power: " .. item.Power .. " | Speed: " .. item.Speed .. "x"
		elseif shopType == "Backpacks" then
			statsText = "Capacity: " .. formatNumber(item.Capacity)
		end

		local statsLabel = Instance.new("TextLabel")
		statsLabel.Size = UDim2.new(0.55, 0, 0, 18)
		statsLabel.Position = UDim2.new(0, 15, 0, 30)
		statsLabel.BackgroundTransparency = 1
		statsLabel.Text = statsText
		statsLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
		statsLabel.TextScaled = true
		statsLabel.Font = Enum.Font.Gotham
		statsLabel.TextXAlignment = Enum.TextXAlignment.Left
		statsLabel.Parent = card

		-- Check ownership
		local owned = false
		local equipped = false
		if shopType == "Pickaxes" then
			for _, o in ipairs(pData.OwnedPickaxes or {}) do
				if o == item.Name then owned = true end
			end
			equipped = pData.EquippedPickaxe == item.Name
		elseif shopType == "Backpacks" then
			for _, o in ipairs(pData.OwnedBackpacks or {}) do
				if o == item.Name then owned = true end
			end
			equipped = pData.EquippedBackpack == item.Name
		end

		-- Buy / Owned button
		local buyBtn = Instance.new("TextButton")
		buyBtn.Size = UDim2.new(0, 100, 0, 35)
		buyBtn.Position = UDim2.new(1, -110, 0.5, -17)
		buyBtn.BorderSizePixel = 0
		buyBtn.Font = Enum.Font.GothamBold
		buyBtn.TextScaled = true
		buyBtn.Parent = card
		Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 6)

		if equipped then
			buyBtn.Text = "✅ EQUIPPED"
			buyBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
			buyBtn.TextColor3 = Color3.new(1, 1, 1)
		elseif owned then
			buyBtn.Text = "OWNED"
			buyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
			buyBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
		else
			local price = item.Price or 0
			buyBtn.Text = "$" .. formatNumber(price)
			buyBtn.TextColor3 = Color3.new(1, 1, 1)
			if (pData.Cash or 0) >= price then
				buyBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
			else
				buyBtn.BackgroundColor3 = Color3.fromRGB(100, 40, 40)
			end

			buyBtn.MouseButton1Click:Connect(function()
				if shopType == "Pickaxes" then
					BuyPickaxeEvent:FireServer(item.Name)
				elseif shopType == "Backpacks" then
					BuyBackpackEvent:FireServer(item.Name)
				end
				-- Refresh after short delay
				task.wait(0.5)
				openShop(shopType, title)
			end)
		end
	end

	shopGui.Enabled = true
end

------------------------------------------------------------------------
-- DETECT SHOP ZONES (proximity-based, no buttons in mine)
------------------------------------------------------------------------
local currentShopZone = nil
local promptGui = Instance.new("ScreenGui")
promptGui.Name = "ShopPrompt"
promptGui.ResetOnSpawn = false
promptGui.Parent = playerGui

local promptLabel = Instance.new("TextLabel")
promptLabel.Size = UDim2.new(0, 300, 0, 40)
promptLabel.Position = UDim2.new(0.5, -150, 0.8, 0)
promptLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
promptLabel.BackgroundTransparency = 0.3
promptLabel.Text = ""
promptLabel.TextColor3 = Color3.new(1, 1, 1)
promptLabel.TextScaled = true
promptLabel.Font = Enum.Font.GothamBold
promptLabel.Visible = false
promptLabel.BorderSizePixel = 0
promptLabel.Parent = promptGui
Instance.new("UICorner", promptLabel).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", promptLabel).Color = Color3.fromRGB(138, 43, 226)

-- Check proximity to shop triggers
RunService.Heartbeat:Connect(function()
	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end
	local hrp = char.HumanoidRootPart

	local hubFolder = workspace:FindFirstChild("Hub")
	if not hubFolder then return end

	local nearestType = nil
	local nearestDist = 20

	for _, obj in ipairs(hubFolder:GetDescendants()) do
		if obj:GetAttribute("InteractionType") then
			local dist = (hrp.Position - obj.Position).Magnitude
			if dist < nearestDist then
				nearestDist = dist
				nearestType = obj:GetAttribute("InteractionType")
			end
		end
	end

	if nearestType == "PickaxeShop" then
		promptLabel.Text = "Press E — ⛏️ Pickaxe Shop"
		promptLabel.Visible = true
		currentShopZone = "Pickaxes"
	elseif nearestType == "BackpackShop" then
		promptLabel.Text = "Press E — 🎒 Backpack Shop"
		promptLabel.Visible = true
		currentShopZone = "Backpacks"
	elseif nearestType == "PrestigeAltar" then
		promptLabel.Text = "Press E — ⭐ Prestige"
		promptLabel.Visible = true
		currentShopZone = "Prestige"
	elseif nearestType == "SellPad" then
		promptLabel.Text = "Press E — 💰 Sell Ores"
		promptLabel.Visible = true
		currentShopZone = "Sell"
	else
		promptLabel.Visible = false
		currentShopZone = nil
	end
end)

-- E key to interact
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.E then
		if currentShopZone == "Pickaxes" then
			openShop("Pickaxes", "⛏️ PICKAXE SHOP")
		elseif currentShopZone == "Backpacks" then
			openShop("Backpacks", "🎒 BACKPACK SHOP")
		elseif currentShopZone == "Prestige" then
			PrestigeEvent:FireServer()
		elseif currentShopZone == "Sell" then
			SellOresEvent:FireServer()
		end
	end
end)

------------------------------------------------------------------------
-- RETURN TO HUB BUTTON (shows only when in mines)
------------------------------------------------------------------------
local hubBtnGui = Instance.new("ScreenGui")
hubBtnGui.Name = "HubButton"
hubBtnGui.ResetOnSpawn = false
hubBtnGui.Parent = playerGui

local hubBtn = Instance.new("TextButton")
hubBtn.Size = UDim2.new(0, 140, 0, 40)
hubBtn.Position = UDim2.new(0, 10, 0, 10)
hubBtn.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
hubBtn.Text = "🏠 Return to Hub"
hubBtn.TextColor3 = Color3.new(1, 1, 1)
hubBtn.TextScaled = true
hubBtn.Font = Enum.Font.GothamBold
hubBtn.BorderSizePixel = 0
hubBtn.Visible = false
hubBtn.Parent = hubBtnGui
Instance.new("UICorner", hubBtn).CornerRadius = UDim.new(0, 8)

hubBtn.MouseButton1Click:Connect(function()
	TeleportToHubEvent:FireServer()
end)

-- Show/hide based on Y position (below surface = in mine)
RunService.Heartbeat:Connect(function()
	local char = player.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		hubBtn.Visible = char.HumanoidRootPart.Position.Y < -5
	end
end)

------------------------------------------------------------------------
-- VOID SELLER BUTTON (shows in mine if player has gamepass)
------------------------------------------------------------------------
local voidSellBtn = Instance.new("TextButton")
voidSellBtn.Size = UDim2.new(0, 140, 0, 40)
voidSellBtn.Position = UDim2.new(0, 10, 0, 55)
voidSellBtn.BackgroundColor3 = Color3.fromRGB(60, 0, 100)
voidSellBtn.Text = "🌀 Void Sell"
voidSellBtn.TextColor3 = Color3.new(1, 1, 1)
voidSellBtn.TextScaled = true
voidSellBtn.Font = Enum.Font.GothamBold
voidSellBtn.BorderSizePixel = 0
voidSellBtn.Visible = false
voidSellBtn.Parent = hubBtnGui
Instance.new("UICorner", voidSellBtn).CornerRadius = UDim.new(0, 8)

voidSellBtn.MouseButton1Click:Connect(function()
	SellOresEvent:FireServer()
end)

-- Void Seller visibility check (simple: always show in mine, server validates gamepass)
RunService.Heartbeat:Connect(function()
	local char = player.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		voidSellBtn.Visible = char.HumanoidRootPart.Position.Y < -5
	end
end)

print("[RiftMiners] Shop GUI loaded! Press E near shops ⛏️")
