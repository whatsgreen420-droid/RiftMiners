-- PlayerDataManager.lua (Server ModuleScript)
-- Handles player data: cash, inventory, equipped pickaxe/backpack, echo cards

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local PlayerDataManager = {}
PlayerDataManager.Data = {} -- [Player] = data table

local DATA_STORE_NAME = "RiftMiners_PlayerData_v1"
local dataStore = DataStoreService:GetDataStore(DATA_STORE_NAME)

------------------------------------------------------------------------
-- DEFAULT DATA
------------------------------------------------------------------------
local function getDefaultData()
	return {
		Cash = GameConfig.Settings.StartingCash,
		Crystals = 0,             -- Void Crystals found (lifetime, never reset)
		EquippedPickaxe = GameConfig.Settings.StartingPickaxe,
		EquippedBackpack = GameConfig.Settings.StartingBackpack,
		OwnedPickaxes = { GameConfig.Settings.StartingPickaxe },
		OwnedBackpacks = { GameConfig.Settings.StartingBackpack },
		Inventory = {},           -- { {OreType = "Gold", Count = 5}, ... }
		InventoryCount = 0,
		PrestigeLevel = 0,
		PrestigeTitle = "",
		PrestigeTrail = "",
		Stats = {
			TotalOresMined = 0,
			TotalCashEarned = 0,
			DeepestLayer = 0,
		},
	}
end

------------------------------------------------------------------------
-- LOAD
------------------------------------------------------------------------
function PlayerDataManager.Load(player)
	local key = "Player_" .. player.UserId
	local success, data = pcall(function()
		return dataStore:GetAsync(key)
	end)

	if success and data then
		PlayerDataManager.Data[player] = data
		print("[RiftMiners] Loaded data for " .. player.Name)
	else
		PlayerDataManager.Data[player] = getDefaultData()
		print("[RiftMiners] Created new data for " .. player.Name)
	end

	-- Set up leaderstats
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local cashStat = Instance.new("IntValue")
	cashStat.Name = "Cash"
	cashStat.Value = PlayerDataManager.Data[player].Cash
	cashStat.Parent = leaderstats

	local crystalStat = Instance.new("IntValue")
	crystalStat.Name = "Crystals"
	crystalStat.Value = PlayerDataManager.Data[player].Crystals
	crystalStat.Parent = leaderstats

	local depthStat = Instance.new("IntValue")
	depthStat.Name = "MaxDepth"
	depthStat.Value = PlayerDataManager.Data[player].Stats.DeepestLayer
	depthStat.Parent = leaderstats

	return PlayerDataManager.Data[player]
end

------------------------------------------------------------------------
-- SAVE
------------------------------------------------------------------------
function PlayerDataManager.Save(player)
	local data = PlayerDataManager.Data[player]
	if not data then return end

	local key = "Player_" .. player.UserId
	local success, err = pcall(function()
		dataStore:SetAsync(key, data)
	end)

	if success then
		print("[RiftMiners] Saved data for " .. player.Name)
	else
		warn("[RiftMiners] Failed to save data for " .. player.Name .. ": " .. tostring(err))
	end
end

------------------------------------------------------------------------
-- CASH OPERATIONS
------------------------------------------------------------------------
function PlayerDataManager.AddCash(player, amount)
	local data = PlayerDataManager.Data[player]
	if not data then return end
	data.Cash = data.Cash + amount
	data.Stats.TotalCashEarned = data.Stats.TotalCashEarned + amount

	local ls = player:FindFirstChild("leaderstats")
	if ls and ls:FindFirstChild("Cash") then
		ls.Cash.Value = data.Cash
	end
end

function PlayerDataManager.GetCash(player)
	local data = PlayerDataManager.Data[player]
	return data and data.Cash or 0
end

function PlayerDataManager.SpendCash(player, amount)
	local data = PlayerDataManager.Data[player]
	if not data or data.Cash < amount then return false end
	data.Cash = data.Cash - amount

	local ls = player:FindFirstChild("leaderstats")
	if ls and ls:FindFirstChild("Cash") then
		ls.Cash.Value = data.Cash
	end
	return true
end

------------------------------------------------------------------------
-- CRYSTAL TRACKING (Void Crystals = flex/leaderboard stat)
------------------------------------------------------------------------
function PlayerDataManager.AddCrystals(player, amount)
	local data = PlayerDataManager.Data[player]
	if not data then return end
	data.Crystals = data.Crystals + amount
	local ls = player:FindFirstChild("leaderstats")
	if ls and ls:FindFirstChild("Crystals") then
		ls.Crystals.Value = data.Crystals
	end
end

------------------------------------------------------------------------
-- PRESTIGE SYSTEM
------------------------------------------------------------------------
function PlayerDataManager.GetPrestigeCost(player)
	local data = PlayerDataManager.Data[player]
	if not data then return math.huge end
	local level = data.PrestigeLevel + 1
	return math.floor(GameConfig.Prestige.BaseCost * (level ^ GameConfig.Prestige.CostExponent))
end

function PlayerDataManager.GetPrestigeMultipliers(player)
	local data = PlayerDataManager.Data[player]
	if not data then return 1, 1 end
	local level = data.PrestigeLevel
	local oreMulti = 1 + (level * GameConfig.Prestige.BonusPerLevel.OreValueMultiplier)
	local speedMulti = 1 + (level * GameConfig.Prestige.BonusPerLevel.MiningSpeedMultiplier)
	return oreMulti, speedMulti
end

function PlayerDataManager.Prestige(player)
	local data = PlayerDataManager.Data[player]
	if not data then return false, "No data" end
	if data.PrestigeLevel >= GameConfig.Prestige.MaxLevel then
		return false, "Max prestige reached!"
	end

	local cost = PlayerDataManager.GetPrestigeCost(player)
	if data.Cash < cost then
		return false, "Need $" .. tostring(cost) .. " to prestige!"
	end

	-- Reset progress
	data.Cash = 0
	data.EquippedPickaxe = GameConfig.Settings.StartingPickaxe
	data.EquippedBackpack = GameConfig.Settings.StartingBackpack
	data.OwnedPickaxes = { GameConfig.Settings.StartingPickaxe }
	data.OwnedBackpacks = { GameConfig.Settings.StartingBackpack }
	data.Inventory = {}
	data.InventoryCount = 0

	-- Increase prestige level
	data.PrestigeLevel = data.PrestigeLevel + 1

	-- Check for milestone rewards
	local milestone = GameConfig.Prestige.Milestones[data.PrestigeLevel]
	if milestone then
		data.PrestigeTitle = milestone.Title
		data.PrestigeTrail = milestone.Trail
	end

	-- Update leaderstats
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		if ls:FindFirstChild("Cash") then ls.Cash.Value = 0 end
	end

	return true, "Prestige Level " .. data.PrestigeLevel .. "!"
end

------------------------------------------------------------------------
-- GAMEPASS HELPERS
------------------------------------------------------------------------
local MarketplaceService = game:GetService("MarketplaceService")

function PlayerDataManager.HasGamepass(player, gamepassName)
	for _, gp in ipairs(GameConfig.Gamepasses) do
		if gp.Name == gamepassName and gp.Id > 0 then
			local success, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gp.Id)
			end)
			return success and owns
		end
	end
	return false
end

function PlayerDataManager.GetSellMultiplier(player)
	local data = PlayerDataManager.Data[player]
	if not data then return 1 end
	local multi = GameConfig.Settings.SellMultiplier
	-- Prestige bonus
	local oreMulti = PlayerDataManager.GetPrestigeMultipliers(player)
	multi = multi * oreMulti
	-- VIP Seller gamepass
	if PlayerDataManager.HasGamepass(player, "VIP Seller") then
		multi = multi * 1.10
	end
	return multi
end

function PlayerDataManager.GetOreDropMultiplier(player)
	if PlayerDataManager.HasGamepass(player, "2x Ore Drops") then
		return 2
	end
	return 1
end

function PlayerDataManager.GetLuckBonus(player)
	if PlayerDataManager.HasGamepass(player, "Lucky Pickaxe") then
		return 0.25
	end
	return 0
end

------------------------------------------------------------------------
-- INVENTORY OPERATIONS
------------------------------------------------------------------------
function PlayerDataManager.GetBackpackCapacity(player)
	local data = PlayerDataManager.Data[player]
	if not data then return 15 end

	local capacity = 15
	for _, bp in ipairs(GameConfig.Backpacks) do
		if bp.Name == data.EquippedBackpack then
			capacity = bp.Capacity
			break
		end
	end

	return capacity
end

function PlayerDataManager.AddToInventory(player, oreType, count)
	local data = PlayerDataManager.Data[player]
	if not data then return false end

	-- Apply 2x Ore Drops gamepass
	local dropMulti = PlayerDataManager.GetOreDropMultiplier(player)
	count = count * dropMulti

	local capacity = PlayerDataManager.GetBackpackCapacity(player)
	if data.InventoryCount + count > capacity then
		return false, "Backpack full!"
	end

	local found = false
	for _, item in ipairs(data.Inventory) do
		if item.OreType == oreType then
			item.Count = item.Count + count
			found = true
			break
		end
	end

	if not found then
		table.insert(data.Inventory, { OreType = oreType, Count = count })
	end

	data.InventoryCount = data.InventoryCount + count
	data.Stats.TotalOresMined = data.Stats.TotalOresMined + count
	return true
end

function PlayerDataManager.SellAllOres(player)
	local data = PlayerDataManager.Data[player]
	if not data then return 0 end

	local sellMultiplier = PlayerDataManager.GetSellMultiplier(player)
	local totalValue = 0

	for _, item in ipairs(data.Inventory) do
		for _, ore in ipairs(GameConfig.Ores) do
			if ore.Name == item.OreType then
				totalValue = totalValue + math.floor(ore.Value * item.Count * sellMultiplier)
				-- Track Void Crystals for leaderboard
				if ore.Name == "Void Crystal" then
					PlayerDataManager.AddCrystals(player, item.Count)
				end
				break
			end
		end
	end

	data.Inventory = {}
	data.InventoryCount = 0

	if totalValue > 0 then
		PlayerDataManager.AddCash(player, totalValue)
	end

	return totalValue
end

------------------------------------------------------------------------
-- PICKAXE / BACKPACK OPERATIONS
------------------------------------------------------------------------
function PlayerDataManager.GetPickaxePower(player)
	local data = PlayerDataManager.Data[player]
	if not data then return 1 end

	local power = 1
	for _, pick in ipairs(GameConfig.Pickaxes) do
		if pick.Name == data.EquippedPickaxe then
			power = pick.Power
			break
		end
	end

	-- Prestige mining speed bonus
	local _, speedMulti = PlayerDataManager.GetPrestigeMultipliers(player)
	power = math.floor(power * speedMulti)

	return power
end

function PlayerDataManager.BuyPickaxe(player, pickaxeName)
	local data = PlayerDataManager.Data[player]
	if not data then return false, "No data" end

	-- Check if already owned
	for _, owned in ipairs(data.OwnedPickaxes) do
		if owned == pickaxeName then return false, "Already owned" end
	end

	-- Find pickaxe config
	for _, pick in ipairs(GameConfig.Pickaxes) do
		if pick.Name == pickaxeName then
			if data.Cash >= pick.Price then
				PlayerDataManager.SpendCash(player, pick.Price)
				table.insert(data.OwnedPickaxes, pickaxeName)
				data.EquippedPickaxe = pickaxeName
				return true, "Purchased!"
			else
				return false, "Not enough cash"
			end
		end
	end
	return false, "Pickaxe not found"
end

function PlayerDataManager.BuyBackpack(player, backpackName)
	local data = PlayerDataManager.Data[player]
	if not data then return false, "No data" end

	for _, owned in ipairs(data.OwnedBackpacks) do
		if owned == backpackName then return false, "Already owned" end
	end

	for _, bp in ipairs(GameConfig.Backpacks) do
		if bp.Name == backpackName then
			if data.Cash >= bp.Price then
				PlayerDataManager.SpendCash(player, bp.Price)
				table.insert(data.OwnedBackpacks, backpackName)
				data.EquippedBackpack = backpackName
				return true, "Purchased!"
			else
				return false, "Not enough cash"
			end
		end
	end
	return false, "Backpack not found"
end

return PlayerDataManager
