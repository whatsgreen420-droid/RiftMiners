-- GameServer.server.lua
-- Main server script: init world, handle remotes, mining, selling, shops, prestige

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ServerFolder = ServerScriptService:WaitForChild("Server")
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")

local GameConfig = require(SharedFolder:WaitForChild("GameConfig"))
local HubBuilder = require(ServerFolder:WaitForChild("HubBuilder"))
local MineGenerator = require(ServerFolder:WaitForChild("MineGenerator"))
local PlayerDataManager = require(ServerFolder:WaitForChild("PlayerDataManager"))

------------------------------------------------------------------------
-- REMOTE EVENTS
------------------------------------------------------------------------
local function makeRemote(name, class)
	local r = Instance.new(class or "RemoteEvent")
	r.Name = name
	r.Parent = ReplicatedStorage
	return r
end

local MineBlockEvent     = makeRemote("MineBlock")
local SellOresEvent      = makeRemote("SellOres")
local BuyPickaxeEvent    = makeRemote("BuyPickaxe")
local BuyBackpackEvent   = makeRemote("BuyBackpack")
local PrestigeEvent      = makeRemote("Prestige")
local NotifyEvent        = makeRemote("Notify")
local GetPlayerDataFunc  = makeRemote("GetPlayerData", "RemoteFunction")
local GetShopDataFunc    = makeRemote("GetShopData", "RemoteFunction")

------------------------------------------------------------------------
-- BUILD WORLD
------------------------------------------------------------------------
print("[RiftMiners] ========================================")
print("[RiftMiners]   ⛏️ RIFT MINERS — Server Starting...")
print("[RiftMiners] ========================================")

HubBuilder.Build()
local mineFolder = MineGenerator.Initialize()

print("[RiftMiners] World generation complete!")

------------------------------------------------------------------------
-- PLAYERS
------------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
	local data = PlayerDataManager.Load(player)
	task.wait(2)
	NotifyEvent:FireClient(player, {
		Title = "⛏️ Welcome to Rift Miners!",
		Message = "Dig deep. Get rich. Prestige. Repeat.",
		Duration = 5,
		Color = Color3.fromRGB(138, 43, 226),
	})
	if data.PrestigeLevel > 0 then
		NotifyEvent:FireClient(player, {
			Title = "⭐ Prestige " .. data.PrestigeLevel,
			Message = data.PrestigeTitle ~= "" and data.PrestigeTitle or "Keep going!",
			Duration = 3,
			Color = Color3.fromRGB(255, 200, 50),
		})
	end
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerDataManager.Save(player)
	PlayerDataManager.Data[player] = nil
end)

-- Auto-save
task.spawn(function()
	while true do
		task.wait(GameConfig.Settings.AutoSaveInterval)
		for _, p in ipairs(Players:GetPlayers()) do
			PlayerDataManager.Save(p)
		end
	end
end)

------------------------------------------------------------------------
-- MINING
------------------------------------------------------------------------
MineBlockEvent.OnServerEvent:Connect(function(player, block)
	if not block or not block.Parent then return end
	if not block:GetAttribute("OreType") then return end

	local oreType = block:GetAttribute("OreType")
	local oreHealth = block:GetAttribute("OreHealth")
	local oreValue = block:GetAttribute("OreValue")
	local oreRarity = block:GetAttribute("OreRarity")
	local pickPower = PlayerDataManager.GetPickaxePower(player)

	local newHealth = oreHealth - pickPower
	block:SetAttribute("OreHealth", newHealth)

	if newHealth <= 0 then
		local success, err = PlayerDataManager.AddToInventory(player, oreType, 1)

		if success then
			NotifyEvent:FireClient(player, {
				Title = "+" .. oreType,
				Message = "Value: $" .. oreValue,
				Duration = 1.5,
				Color = GameConfig.RarityColors[oreRarity] or Color3.new(1, 1, 1),
			})

			-- Track depth
			local depth = block:GetAttribute("Depth") or 0
			local data = PlayerDataManager.Data[player]
			if data and depth > data.Stats.DeepestLayer then
				data.Stats.DeepestLayer = depth
				local ls = player:FindFirstChild("leaderstats")
				if ls and ls:FindFirstChild("MaxDepth") then
					ls.MaxDepth.Value = depth
				end
			end
		else
			NotifyEvent:FireClient(player, {
				Title = "🎒 Backpack Full!",
				Message = "Sell your ores at the Sell Pad!",
				Duration = 2,
				Color = Color3.fromRGB(255, 80, 80),
			})
		end

		block:Destroy()

		-- Generate more layers as needed
		local existingLayers = 0
		for _, child in ipairs(mineFolder:GetChildren()) do
			if child:IsA("Folder") then existingLayers = existingLayers + 1 end
		end
		local layerIndex = math.floor(math.abs(block.Position.Y - MINE_ORIGIN.Y) / BLOCK_SIZE)
		if layerIndex >= existingLayers - 2 then
			MineGenerator.GenerateLayer(existingLayers, mineFolder)
		end
	end
end)

------------------------------------------------------------------------
-- SELL ORES (touch-based + remote)
------------------------------------------------------------------------
SellOresEvent.OnServerEvent:Connect(function(player)
	local totalValue = PlayerDataManager.SellAllOres(player)
	if totalValue > 0 then
		NotifyEvent:FireClient(player, {
			Title = "💰 Ores Sold!",
			Message = "Earned $" .. tostring(totalValue),
			Duration = 3,
			Color = Color3.fromRGB(0, 255, 100),
		})
	else
		NotifyEvent:FireClient(player, {
			Title = "Empty Backpack",
			Message = "Go mine some ores first!",
			Duration = 2,
			Color = Color3.fromRGB(255, 200, 0),
		})
	end
end)

-- Sell pad touch
task.spawn(function()
	task.wait(3)
	local sellPad = workspace:FindFirstChild("Hub") and workspace.Hub:FindFirstChild("SellPad")
	if sellPad then
		local debounce = {}
		sellPad.Touched:Connect(function(hit)
			local p = Players:GetPlayerFromCharacter(hit.Parent)
			if p and not debounce[p] then
				debounce[p] = true
				local val = PlayerDataManager.SellAllOres(p)
				if val > 0 then
					NotifyEvent:FireClient(p, {
						Title = "💰 Ores Sold!",
						Message = "Earned $" .. tostring(val),
						Duration = 3,
						Color = Color3.fromRGB(0, 255, 100),
					})
				end
				task.wait(1)
				debounce[p] = nil
			end
		end)
	end
end)

------------------------------------------------------------------------
-- SHOPS
------------------------------------------------------------------------
BuyPickaxeEvent.OnServerEvent:Connect(function(player, name)
	local ok, msg = PlayerDataManager.BuyPickaxe(player, name)
	NotifyEvent:FireClient(player, {
		Title = ok and "⛏️ Purchased!" or "Cannot Buy",
		Message = msg,
		Duration = 2,
		Color = ok and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 80, 80),
	})
end)

BuyBackpackEvent.OnServerEvent:Connect(function(player, name)
	local ok, msg = PlayerDataManager.BuyBackpack(player, name)
	NotifyEvent:FireClient(player, {
		Title = ok and "🎒 Purchased!" or "Cannot Buy",
		Message = msg,
		Duration = 2,
		Color = ok and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 80, 80),
	})
end)

------------------------------------------------------------------------
-- PRESTIGE
------------------------------------------------------------------------
PrestigeEvent.OnServerEvent:Connect(function(player)
	local ok, msg = PlayerDataManager.Prestige(player)
	NotifyEvent:FireClient(player, {
		Title = ok and "⭐ PRESTIGE! ⭐" or "Cannot Prestige",
		Message = msg,
		Duration = ok and 5 or 2,
		Color = ok and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(255, 80, 80),
	})
end)

------------------------------------------------------------------------
-- DATA REQUESTS
------------------------------------------------------------------------
GetPlayerDataFunc.OnServerInvoke = function(player)
	return PlayerDataManager.Data[player]
end

GetShopDataFunc.OnServerInvoke = function(player, shopType)
	if shopType == "Pickaxes" then return GameConfig.Pickaxes
	elseif shopType == "Backpacks" then return GameConfig.Backpacks
	elseif shopType == "Gamepasses" then return GameConfig.Gamepasses
	elseif shopType == "Prestige" then
		local data = PlayerDataManager.Data[player]
		return {
			Level = data and data.PrestigeLevel or 0,
			Cost = PlayerDataManager.GetPrestigeCost(player),
			MaxLevel = GameConfig.Prestige.MaxLevel,
			Milestones = GameConfig.Prestige.Milestones,
		}
	end
	return nil
end

print("[RiftMiners] Server fully loaded! ⛏️🌀")
