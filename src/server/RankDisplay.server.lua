-- RankDisplay.server.lua
-- Shows player rank/title above their head using BillboardGui
-- Works on all platforms (mobile, PC, console)
-- Updates when prestige changes

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local ServerFolder = game:GetService("ServerScriptService"):WaitForChild("Server")
local PlayerDataManager = require(ServerFolder:WaitForChild("PlayerDataManager"))

------------------------------------------------------------------------
-- RANK TIERS (based on total cash earned + prestige)
------------------------------------------------------------------------
local RankTiers = {
	{ Name = "Newcomer",         Color = Color3.fromRGB(180, 180, 180), MinCash = 0,         MinPrestige = 0  },
	{ Name = "Apprentice Miner", Color = Color3.fromRGB(120, 200, 120), MinCash = 1000,      MinPrestige = 0  },
	{ Name = "Journeyman",       Color = Color3.fromRGB(80, 180, 255),  MinCash = 10000,     MinPrestige = 0  },
	{ Name = "Skilled Miner",    Color = Color3.fromRGB(80, 180, 255),  MinCash = 50000,     MinPrestige = 0  },
	{ Name = "Expert Digger",    Color = Color3.fromRGB(163, 53, 238),  MinCash = 200000,    MinPrestige = 0  },
	{ Name = "Master Miner",     Color = Color3.fromRGB(163, 53, 238),  MinCash = 1000000,   MinPrestige = 0  },
	{ Name = "Diamond Hands",    Color = Color3.fromRGB(0, 200, 255),   MinCash = 5000000,   MinPrestige = 0  },
	{ Name = "Rift Explorer",    Color = Color3.fromRGB(138, 43, 226),  MinCash = 0,         MinPrestige = 5  },
	{ Name = "Void Walker",      Color = Color3.fromRGB(100, 0, 200),   MinCash = 0,         MinPrestige = 15 },
	{ Name = "Nebula Lord",      Color = Color3.fromRGB(255, 100, 255), MinCash = 0,         MinPrestige = 30 },
	{ Name = "⭐ WORLDSPLITTER", Color = Color3.fromRGB(255, 215, 0),   MinCash = 0,         MinPrestige = 50 },
}

local function getRank(data)
	if not data then return RankTiers[1] end

	-- Prestige title overrides if they have a milestone title
	if data.PrestigeTitle and data.PrestigeTitle ~= "" then
		-- Find matching prestige milestone color
		for i = #RankTiers, 1, -1 do
			if data.PrestigeLevel >= RankTiers[i].MinPrestige and RankTiers[i].MinPrestige > 0 then
				return { Name = data.PrestigeTitle, Color = RankTiers[i].Color }
			end
		end
		return { Name = data.PrestigeTitle, Color = Color3.fromRGB(255, 200, 50) }
	end

	-- Otherwise use cash-based rank
	local bestRank = RankTiers[1]
	for _, rank in ipairs(RankTiers) do
		if (data.Stats and data.Stats.TotalCashEarned >= rank.MinCash) and data.PrestigeLevel >= rank.MinPrestige then
			bestRank = rank
		end
	end
	return bestRank
end

------------------------------------------------------------------------
-- CREATE OVERHEAD GUI
------------------------------------------------------------------------
local function createOverheadGui(character, data)
	-- Remove old one
	local head = character:WaitForChild("Head", 5)
	if not head then return end

	local existing = head:FindFirstChild("RankGui")
	if existing then existing:Destroy() end

	local rank = getRank(data)

	local gui = Instance.new("BillboardGui")
	gui.Name = "RankGui"
	gui.Size = UDim2.new(0, 200, 0, 60)
	gui.StudsOffset = Vector3.new(0, 2.5, 0)
	gui.Adornee = head
	gui.AlwaysOnTop = false
	gui.MaxDistance = 50
	gui.Parent = head

	-- Player name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "PlayerName"
	nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = character.Name
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	nameLabel.Parent = gui

	-- Rank title
	local rankLabel = Instance.new("TextLabel")
	rankLabel.Name = "RankTitle"
	rankLabel.Size = UDim2.new(1, 0, 0.4, 0)
	rankLabel.Position = UDim2.new(0, 0, 0.5, 0)
	rankLabel.BackgroundTransparency = 1
	rankLabel.Text = rank.Name
	rankLabel.TextColor3 = rank.Color
	rankLabel.TextScaled = true
	rankLabel.Font = Enum.Font.GothamBold
	rankLabel.TextStrokeTransparency = 0
	rankLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	rankLabel.Parent = gui

	-- Prestige stars if applicable
	if data and data.PrestigeLevel > 0 then
		local starsLabel = Instance.new("TextLabel")
		starsLabel.Name = "PrestigeStars"
		starsLabel.Size = UDim2.new(1, 0, 0.2, 0)
		starsLabel.Position = UDim2.new(0, 0, 0.85, 0)
		starsLabel.BackgroundTransparency = 1
		local stars = ""
		local count = math.min(data.PrestigeLevel, 10)
		for _ = 1, count do stars = stars .. "⭐" end
		if data.PrestigeLevel > 10 then
			stars = stars .. " +" .. (data.PrestigeLevel - 10)
		end
		starsLabel.Text = stars
		starsLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
		starsLabel.TextScaled = true
		starsLabel.Font = Enum.Font.Gotham
		starsLabel.TextStrokeTransparency = 0.5
		starsLabel.Parent = gui
	end
end

------------------------------------------------------------------------
-- APPLY TO ALL PLAYERS
------------------------------------------------------------------------
local function setupPlayer(player)
	local function onCharacterAdded(character)
		-- Wait for data to load
		task.wait(1)
		local data = PlayerDataManager.Data[player]
		createOverheadGui(character, data)
	end

	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		task.spawn(function()
			onCharacterAdded(player.Character)
		end)
	end
end

Players.PlayerAdded:Connect(setupPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(function() setupPlayer(p) end)
end

-- Refresh ranks periodically (every 30s) to reflect prestige changes
task.spawn(function()
	while true do
		task.wait(30)
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Character then
				local data = PlayerDataManager.Data[p]
				createOverheadGui(p.Character, data)
			end
		end
	end
end)

-- Also refresh on prestige
local PrestigeEvent = ReplicatedStorage:WaitForChild("Prestige")
PrestigeEvent.OnServerEvent:Connect(function(player)
	-- The prestige handler in GameServer already processes this
	-- We just need to refresh the overhead display after a short delay
	task.wait(1)
	if player.Character then
		local data = PlayerDataManager.Data[player]
		createOverheadGui(player.Character, data)
	end
end)

print("[RiftMiners] Rank display system loaded! ⭐")
