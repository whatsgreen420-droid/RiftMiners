-- ShopGui.client.lua
-- Scrollable shop GUI using ProximityPrompts (works on mobile, PC, console)
-- No "Press E" text — uses native Roblox ProximityPrompt system

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
local SellOresEvent = ReplicatedStorage:WaitForChild("SellOres")
local PrestigeEvent = ReplicatedStorage:WaitForChild("Prestige")

------------------------------------------------------------------------
-- SHOP SCREEN GUI
------------------------------------------------------------------------
local shopGui = Instance.new("ScreenGui")
shopGui.Name = "ShopGui"
shopGui.ResetOnSpawn = false
shopGui.Enabled = false
shopGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 380, 0, 450)
mainFrame.Position = UDim2.new(0.5, -190, 0.5, -225)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = shopGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(138, 43, 226)
stroke.Thickness = 2
stroke.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, 0, 0, 45)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "SHOP"
titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainFrame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.Position = UDim2.new(1, -40, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
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

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "ItemList"
scrollFrame.Size = UDim2.new(1, -20, 1, -55)
scrollFrame.Position = UDim2.new(0, 10, 0, 50)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 5
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(138, 43, 226)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 5)
listLayout.Parent = scrollFrame
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end)

------------------------------------------------------------------------
-- SHOP FUNCTIONS
------------------------------------------------------------------------
local function clearItems()
	for _, c in ipairs(scrollFrame:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
end

local function formatNum(n)
	if n >= 1000000 then return string.format("%.1fM", n/1000000)
	elseif n >= 1000 then return string.format("%.1fK", n/1000)
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
		card.Size = UDim2.new(1, 0, 0, 65)
		card.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
		card.BorderSizePixel = 0
		card.LayoutOrder = i
		card.Parent = scrollFrame
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

		local colorStripe = Instance.new("Frame")
		colorStripe.Size = UDim2.new(0, 3, 1, -6)
		colorStripe.Position = UDim2.new(0, 3, 0, 3)
		colorStripe.BackgroundColor3 = item.Color or Color3.new(1,1,1)
		colorStripe.BorderSizePixel = 0
		colorStripe.Parent = card

		local nameL = Instance.new("TextLabel")
		nameL.Size = UDim2.new(0.55, 0, 0, 22)
		nameL.Position = UDim2.new(0, 12, 0, 4)
		nameL.BackgroundTransparency = 1
		nameL.Text = item.Name
		nameL.TextColor3 = Color3.new(1,1,1)
		nameL.TextScaled = true
		nameL.Font = Enum.Font.GothamBold
		nameL.TextXAlignment = Enum.TextXAlignment.Left
		nameL.Parent = card

		local statsText = ""
		if shopType == "Pickaxes" then
			statsText = "Power: "..item.Power.." | Speed: "..item.Speed.."x"
		elseif shopType == "Backpacks" then
			statsText = "Capacity: "..formatNum(item.Capacity)
		end

		local statsL = Instance.new("TextLabel")
		statsL.Size = UDim2.new(0.55, 0, 0, 16)
		statsL.Position = UDim2.new(0, 12, 0, 27)
		statsL.BackgroundTransparency = 1
		statsL.Text = statsText
		statsL.TextColor3 = Color3.fromRGB(160,160,180)
		statsL.TextScaled = true
		statsL.Font = Enum.Font.Gotham
		statsL.TextXAlignment = Enum.TextXAlignment.Left
		statsL.Parent = card

		local owned, equipped = false, false
		if shopType == "Pickaxes" then
			for _, o in ipairs(pData.OwnedPickaxes or {}) do if o == item.Name then owned = true end end
			equipped = pData.EquippedPickaxe == item.Name
		elseif shopType == "Backpacks" then
			for _, o in ipairs(pData.OwnedBackpacks or {}) do if o == item.Name then owned = true end end
			equipped = pData.EquippedBackpack == item.Name
		end

		local buyBtn = Instance.new("TextButton")
		buyBtn.Size = UDim2.new(0, 90, 0, 30)
		buyBtn.Position = UDim2.new(1, -98, 0.5, -15)
		buyBtn.BorderSizePixel = 0
		buyBtn.Font = Enum.Font.GothamBold
		buyBtn.TextScaled = true
		buyBtn.Parent = card
		Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 6)

		if equipped then
			buyBtn.Text = "✅ EQUIPPED"
			buyBtn.BackgroundColor3 = Color3.fromRGB(40,120,40)
			buyBtn.TextColor3 = Color3.new(1,1,1)
		elseif owned then
			buyBtn.Text = "OWNED"
			buyBtn.BackgroundColor3 = Color3.fromRGB(60,60,80)
			buyBtn.TextColor3 = Color3.fromRGB(150,150,150)
		else
			buyBtn.Text = "$"..formatNum(item.Price or 0)
			buyBtn.TextColor3 = Color3.new(1,1,1)
			buyBtn.BackgroundColor3 = (pData.Cash or 0) >= (item.Price or 0) and Color3.fromRGB(0,150,80) or Color3.fromRGB(100,40,40)
			buyBtn.MouseButton1Click:Connect(function()
				if shopType == "Pickaxes" then BuyPickaxeEvent:FireServer(item.Name)
				elseif shopType == "Backpacks" then BuyBackpackEvent:FireServer(item.Name) end
				task.wait(0.5)
				openShop(shopType, title)
			end)
		end
	end

	shopGui.Enabled = true
end

------------------------------------------------------------------------
-- PROXIMITY PROMPT DETECTION (replaces "Press E" — works on ALL platforms)
------------------------------------------------------------------------
task.spawn(function()
	-- Wait for hub to build
	task.wait(5)

	local hubFolder = workspace:FindFirstChild("Hub")
	if not hubFolder then return end

	-- Add ProximityPrompts to shop triggers
	for _, obj in ipairs(hubFolder:GetDescendants()) do
		local iType = obj:GetAttribute("InteractionType")
		if iType and obj:IsA("BasePart") then
			-- Remove any existing ClickDetectors
			local cd = obj:FindFirstChildOfClass("ClickDetector")
			if cd then cd:Destroy() end

			local prompt = Instance.new("ProximityPrompt")
			prompt.MaxActivationDistance = 12
			prompt.RequiresLineOfSight = false
			prompt.HoldDuration = 0

			if iType == "PickaxeShop" then
				prompt.ActionText = "Browse"
				prompt.ObjectText = "⛏️ Pickaxe Shop"
				prompt.Triggered:Connect(function(p)
					if p == player then openShop("Pickaxes", "⛏️ PICKAXE SHOP") end
				end)
			elseif iType == "BackpackShop" then
				prompt.ActionText = "Browse"
				prompt.ObjectText = "🎒 Backpack Shop"
				prompt.Triggered:Connect(function(p)
					if p == player then openShop("Backpacks", "🎒 BACKPACK SHOP") end
				end)
			elseif iType == "PrestigeAltar" then
				prompt.ActionText = "Prestige"
				prompt.ObjectText = "⭐ Prestige Altar"
				prompt.Triggered:Connect(function(p)
					if p == player then PrestigeEvent:FireServer() end
				end)
			elseif iType == "SellPad" then
				prompt.ActionText = "Sell All"
				prompt.ObjectText = "💰 Sell Ores"
				prompt.Triggered:Connect(function(p)
					if p == player then SellOresEvent:FireServer() end
				end)
			elseif iType == "MineEntrance" then
				prompt.ActionText = "Enter"
				prompt.ObjectText = "⛏️ The Mines"
				prompt.Triggered:Connect(function() end) -- Teleport handled by touch
			elseif iType == "ReturnToHub" then
				prompt.ActionText = "Return"
				prompt.ObjectText = "🏠 Surface"
				prompt.Triggered:Connect(function() end) -- Teleport handled by touch
			elseif iType == "BuyGamepass" then
				local gpName = obj:GetAttribute("GamepassName") or "Premium"
				prompt.ActionText = "Purchase"
				prompt.ObjectText = "💎 " .. gpName
				prompt.Triggered:Connect(function(p)
					if p == player then
						-- Would open gamepass purchase prompt here
						-- MarketplaceService:PromptGamePassPurchase(player, gamepassId)
					end
				end)
			end

			prompt.Parent = obj
		end
	end

	-- Also add to mine return portal
	local mineFolder = workspace:FindFirstChild("Mine")
	if mineFolder then
		local returnPortal = mineFolder:FindFirstChild("ReturnPortal")
		if returnPortal then
			local prompt = Instance.new("ProximityPrompt")
			prompt.MaxActivationDistance = 12
			prompt.ActionText = "Return"
			prompt.ObjectText = "🏠 Surface"
			prompt.RequiresLineOfSight = false
			prompt.Parent = returnPortal
		end
	end
end)

------------------------------------------------------------------------
-- RETURN TO HUB BUTTON (in mine only)
------------------------------------------------------------------------
local hubBtnGui = Instance.new("ScreenGui")
hubBtnGui.Name = "HubButton"
hubBtnGui.ResetOnSpawn = false
hubBtnGui.Parent = playerGui

local hubBtn = Instance.new("TextButton")
hubBtn.Size = UDim2.new(0, 120, 0, 35)
hubBtn.Position = UDim2.new(0, 10, 0, 10)
hubBtn.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
hubBtn.BackgroundTransparency = 0.2
hubBtn.Text = "🏠 Surface"
hubBtn.TextColor3 = Color3.new(1,1,1)
hubBtn.TextScaled = true
hubBtn.Font = Enum.Font.GothamBold
hubBtn.BorderSizePixel = 0
hubBtn.Visible = false
hubBtn.Parent = hubBtnGui
Instance.new("UICorner", hubBtn).CornerRadius = UDim.new(0, 8)

local TeleportToHubEvent = ReplicatedStorage:WaitForChild("TeleportToHub")
hubBtn.MouseButton1Click:Connect(function()
	TeleportToHubEvent:FireServer()
end)

-- Void Sell button (mine only)
local voidSellBtn = Instance.new("TextButton")
voidSellBtn.Size = UDim2.new(0, 120, 0, 35)
voidSellBtn.Position = UDim2.new(0, 10, 0, 50)
voidSellBtn.BackgroundColor3 = Color3.fromRGB(60, 0, 100)
voidSellBtn.BackgroundTransparency = 0.2
voidSellBtn.Text = "🌀 Sell"
voidSellBtn.TextColor3 = Color3.new(1,1,1)
voidSellBtn.TextScaled = true
voidSellBtn.Font = Enum.Font.GothamBold
voidSellBtn.BorderSizePixel = 0
voidSellBtn.Visible = false
voidSellBtn.Parent = hubBtnGui
Instance.new("UICorner", voidSellBtn).CornerRadius = UDim.new(0, 8)
voidSellBtn.MouseButton1Click:Connect(function()
	SellOresEvent:FireServer()
end)

-- Show/hide based on position
RunService.Heartbeat:Connect(function()
	local char = player.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		local inMine = char.HumanoidRootPart.Position.Y < -5
		hubBtn.Visible = inMine
		voidSellBtn.Visible = inMine
	end
end)

print("[RiftMiners] Shop GUI loaded with ProximityPrompts! 🛒")
