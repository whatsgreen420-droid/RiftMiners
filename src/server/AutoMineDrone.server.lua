-- AutoMineDrone.server.lua
-- Auto-Mine Drone gamepass: spawns a drone that mines nearby ores automatically
-- Works on all platforms, requires gamepass ownership

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ServerFolder = game:GetService("ServerScriptService"):WaitForChild("Server")
local PlayerDataManager = require(ServerFolder:WaitForChild("PlayerDataManager"))
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local NotifyEvent = ReplicatedStorage:WaitForChild("Notify")

local DRONE_RANGE = 20
local DRONE_INTERVAL = 3 -- seconds between auto-mines
local DRONE_SIZE = Vector3.new(2, 1, 2)

local activeDrones = {} -- [player] = droneModel

local function createDrone(player)
	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end

	local drone = Instance.new("Model")
	drone.Name = player.Name .. "_Drone"

	-- Drone body
	local body = Instance.new("Part")
	body.Name = "DroneBody"
	body.Anchored = true
	body.CanCollide = false
	body.Size = DRONE_SIZE
	body.Color = Color3.fromRGB(50, 50, 70)
	body.Material = Enum.Material.SmoothPlastic
	body.Parent = drone
	drone.PrimaryPart = body

	-- Drone top
	local top = Instance.new("Part")
	top.Name = "DroneTop"
	top.Anchored = true
	top.CanCollide = false
	top.Size = Vector3.new(1.5, 0.5, 1.5)
	top.Color = Color3.fromRGB(0, 200, 255)
	top.Material = Enum.Material.Neon
	top.Parent = drone

	-- Drone light
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(0, 200, 255)
	light.Range = 15
	light.Brightness = 2
	light.Parent = body

	-- Drone propellers (visual only)
	for _, offset in ipairs({Vector3.new(1,0.5,1), Vector3.new(-1,0.5,1), Vector3.new(1,0.5,-1), Vector3.new(-1,0.5,-1)}) do
		local prop = Instance.new("Part")
		prop.Name = "Propeller"
		prop.Anchored = true
		prop.CanCollide = false
		prop.Size = Vector3.new(0.6, 0.1, 0.6)
		prop.Color = Color3.fromRGB(100, 100, 100)
		prop.Material = Enum.Material.Metal
		prop.Shape = Enum.PartType.Cylinder
		prop.Parent = drone
	end

	-- Label
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 120, 0, 30)
	bb.StudsOffset = Vector3.new(0, 2, 0)
	bb.Adornee = body
	bb.AlwaysOnTop = true
	bb.Parent = body
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1,0,1,0)
	lbl.BackgroundTransparency = 1
	lbl.Text = "🤖 Auto-Drone"
	lbl.TextColor3 = Color3.fromRGB(0, 200, 255)
	lbl.TextScaled = true
	lbl.Font = Enum.Font.GothamBold
	lbl.TextStrokeTransparency = 0
	lbl.Parent = bb

	-- Particles
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(Color3.fromRGB(0,200,255))
	pe.Size = NumberSequence.new(0.2, 0)
	pe.Lifetime = NumberRange.new(0.3, 0.6)
	pe.Rate = 10
	pe.Speed = NumberRange.new(1, 2)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Parent = body

	drone.Parent = Workspace
	return drone
end

local function updateDronePosition(drone, playerPos)
	if not drone or not drone.PrimaryPart then return end
	local targetPos = playerPos + Vector3.new(3, 4, -2)
	drone.PrimaryPart.Position = targetPos

	-- Update all parts relative to body
	for _, part in ipairs(drone:GetDescendants()) do
		if part:IsA("BasePart") and part ~= drone.PrimaryPart then
			if part.Name == "DroneTop" then
				part.Position = targetPos + Vector3.new(0, 0.75, 0)
			end
		end
	end
end

local function findNearestOre(position, range)
	local nearest = nil
	local nearestDist = range
	local mineFolder = Workspace:FindFirstChild("Mine")
	if not mineFolder then return nil end

	for _, layer in ipairs(mineFolder:GetChildren()) do
		if layer:IsA("Folder") then
			for _, block in ipairs(layer:GetChildren()) do
				if block:IsA("BasePart") and block:GetAttribute("OreType") then
					local dist = (block.Position - position).Magnitude
					if dist < nearestDist then
						nearest = block
						nearestDist = dist
					end
				end
			end
		end
	end
	return nearest
end

local function autoMine(player, block)
	if not block or not block.Parent then return end
	if not block:GetAttribute("OreType") then return end

	local oreType = block:GetAttribute("OreType")
	local oreValue = block:GetAttribute("OreValue")
	local oreRarity = block:GetAttribute("OreRarity")

	local success = PlayerDataManager.AddToInventory(player, oreType, 1)
	if success then
		-- Fire quest event
		local oreMinedBE = ReplicatedStorage:FindFirstChild("OreMined")
		if oreMinedBE then oreMinedBE:Fire(player, oreType, 1) end

		NotifyEvent:FireClient(player, {
			Title = "🤖 +" .. oreType,
			Message = "Auto-mined! $" .. oreValue,
			Duration = 1,
			Color = Color3.fromRGB(0, 200, 255),
		})
	end
	block:Destroy()
end

-- Main drone loop per player
local function startDroneLoop(player)
	activeDrones[player] = createDrone(player)

	task.spawn(function()
		while player.Parent and activeDrones[player] do
			task.wait(DRONE_INTERVAL)

			local char = player.Character
			if not char or not char:FindFirstChild("HumanoidRootPart") then continue end
			local hrp = char.HumanoidRootPart

			-- Only work in the mine (Y < -5)
			if hrp.Position.Y > -5 then
				if activeDrones[player] then
					activeDrones[player].Parent = nil -- hide drone on surface
				end
				continue
			else
				if activeDrones[player] and not activeDrones[player].Parent then
					activeDrones[player].Parent = Workspace
				end
			end

			updateDronePosition(activeDrones[player], hrp.Position)

			local ore = findNearestOre(hrp.Position, DRONE_RANGE)
			if ore then
				autoMine(player, ore)
			end
		end
	end)
end

-- Check gamepass on join
Players.PlayerAdded:Connect(function(player)
	task.wait(3)
	if PlayerDataManager.HasGamepass(player, "Auto-Mine Drone") then
		startDroneLoop(player)
		NotifyEvent:FireClient(player, {
			Title = "🤖 Drone Active!",
			Message = "Your Auto-Mine Drone is working!",
			Duration = 3,
			Color = Color3.fromRGB(0, 200, 255),
		})
	end
end)

Players.PlayerRemoving:Connect(function(player)
	if activeDrones[player] then
		activeDrones[player]:Destroy()
		activeDrones[player] = nil
	end
end)

print("[RiftMiners] Auto-Mine Drone system loaded! 🤖")
