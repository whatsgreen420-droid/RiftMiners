-- PrestigeTrails.server.lua
-- Attaches particle trail effects to players based on prestige level
-- Works on all platforms, automatically applies on spawn

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerFolder = game:GetService("ServerScriptService"):WaitForChild("Server")
local PlayerDataManager = require(ServerFolder:WaitForChild("PlayerDataManager"))
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local trailConfigs = {
	{ MinLevel = 1,  Color1 = Color3.fromRGB(180,180,180), Color2 = Color3.fromRGB(120,120,120), Rate = 8,  Size = 0.3 },
	{ MinLevel = 5,  Color1 = Color3.fromRGB(255,200,50),  Color2 = Color3.fromRGB(255,150,0),   Rate = 12, Size = 0.4 },
	{ MinLevel = 10, Color1 = Color3.fromRGB(0,200,255),   Color2 = Color3.fromRGB(0,100,200),   Rate = 15, Size = 0.5 },
	{ MinLevel = 15, Color1 = Color3.fromRGB(255,100,30),  Color2 = Color3.fromRGB(200,50,0),    Rate = 18, Size = 0.5 },
	{ MinLevel = 20, Color1 = Color3.fromRGB(138,43,226),  Color2 = Color3.fromRGB(80,0,160),    Rate = 22, Size = 0.6 },
	{ MinLevel = 25, Color1 = Color3.fromRGB(0,255,200),   Color2 = Color3.fromRGB(0,180,150),   Rate = 25, Size = 0.6 },
	{ MinLevel = 30, Color1 = Color3.fromRGB(20,0,50),     Color2 = Color3.fromRGB(80,0,120),    Rate = 28, Size = 0.7 },
	{ MinLevel = 35, Color1 = Color3.fromRGB(100,0,200),   Color2 = Color3.fromRGB(150,50,255),  Rate = 30, Size = 0.7 },
	{ MinLevel = 40, Color1 = Color3.fromRGB(255,0,255),   Color2 = Color3.fromRGB(0,255,255),   Rate = 35, Size = 0.8 },
	{ MinLevel = 45, Color1 = Color3.fromRGB(255,200,200), Color2 = Color3.fromRGB(200,100,255),  Rate = 38, Size = 0.8 },
	{ MinLevel = 50, Color1 = Color3.fromRGB(255,255,255), Color2 = Color3.fromRGB(255,215,0),   Rate = 45, Size = 1.0 },
}

local function getTrailConfig(level)
	local best = nil
	for _, cfg in ipairs(trailConfigs) do
		if level >= cfg.MinLevel then best = cfg end
	end
	return best
end

local function applyTrail(character, data)
	if not data or data.PrestigeLevel < 1 then return end

	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if not hrp then return end

	-- Remove old trail
	local old = hrp:FindFirstChild("PrestigeTrail")
	if old then old:Destroy() end

	local cfg = getTrailConfig(data.PrestigeLevel)
	if not cfg then return end

	-- Particle trail attached to root part
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "PrestigeTrail"
	pe.Color = ColorSequence.new(cfg.Color1, cfg.Color2)
	pe.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, cfg.Size),
		NumberSequenceKeypoint.new(0.5, cfg.Size * 0.6),
		NumberSequenceKeypoint.new(1, 0),
	})
	pe.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.7, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	pe.Lifetime = NumberRange.new(0.5, 1.2)
	pe.Rate = cfg.Rate
	pe.Speed = NumberRange.new(0.5, 2)
	pe.SpreadAngle = Vector2.new(360, 360)
	pe.LightEmission = 0.8
	pe.LightInfluence = 0.3
	pe.LockedToPart = false
	pe.Parent = hrp
end

local function setupPlayer(player)
	player.CharacterAdded:Connect(function(char)
		task.wait(1)
		local data = PlayerDataManager.Data[player]
		applyTrail(char, data)
	end)
	if player.Character then
		task.spawn(function()
			task.wait(1)
			local data = PlayerDataManager.Data[player]
			applyTrail(player.Character, data)
		end)
	end
end

Players.PlayerAdded:Connect(setupPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(function() setupPlayer(p) end)
end

-- Refresh on prestige
local PrestigeEvent = ReplicatedStorage:WaitForChild("Prestige")
PrestigeEvent.OnServerEvent:Connect(function(player)
	task.wait(1)
	if player.Character then
		local data = PlayerDataManager.Data[player]
		applyTrail(player.Character, data)
	end
end)

print("[RiftMiners] Prestige trails loaded! ✨")
