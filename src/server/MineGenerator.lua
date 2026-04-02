-- MineGenerator.lua (Server ModuleScript)
-- Procedural mine with biomes, ore distribution by depth, biome signs

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local MineGenerator = {}

local BLOCK_SIZE = GameConfig.World.Mine.BlockSize
local CHUNK_W = GameConfig.World.Mine.ChunkWidth
local CHUNK_D = GameConfig.World.Mine.ChunkDepth
local MINE_ORIGIN = GameConfig.World.Mine.OriginPosition

------------------------------------------------------------------------
-- GET BIOME FOR DEPTH
------------------------------------------------------------------------
local function getBiome(depth)
	for _, biome in ipairs(GameConfig.Biomes) do
		if depth >= biome.DepthRange[1] and depth <= biome.DepthRange[2] then
			return biome
		end
	end
	return GameConfig.Biomes[#GameConfig.Biomes]
end

------------------------------------------------------------------------
-- ORE SELECTION based on depth + optional luck bonus
------------------------------------------------------------------------
local function pickOreForDepth(depth, luckBonus)
	local candidates = {}
	local totalWeight = 0

	for _, ore in ipairs(GameConfig.Ores) do
		if depth >= ore.MinDepth then
			local weight = ore.Weight
			if luckBonus and luckBonus > 0 and ore.Rarity ~= "Common" then
				weight = weight * (1 + luckBonus)
			end
			table.insert(candidates, {ore = ore, weight = weight})
			totalWeight = totalWeight + weight
		end
	end

	if #candidates == 0 then
		return GameConfig.Ores[1]
	end

	local roll = math.random() * totalWeight
	local cumulative = 0
	for _, c in ipairs(candidates) do
		cumulative = cumulative + c.weight
		if roll <= cumulative then
			return c.ore
		end
	end

	return candidates[#candidates].ore
end

------------------------------------------------------------------------
-- GENERATE A SINGLE LAYER
------------------------------------------------------------------------
function MineGenerator.GenerateLayer(layerIndex, parentFolder)
	local layerFolder = Instance.new("Folder")
	layerFolder.Name = "Layer_" .. layerIndex
	layerFolder.Parent = parentFolder

	local depth = layerIndex
	local yPos = MINE_ORIGIN.Y - (layerIndex * BLOCK_SIZE)
	local biome = getBiome(depth)
	local darken = math.clamp(1 - (depth / 1200), 0.15, 1)

	for x = 0, CHUNK_W - 1 do
		for z = 0, CHUNK_D - 1 do
			local isCenterPath = (x >= CHUNK_W/2 - 1 and x <= CHUNK_W/2) and (z % 4 == 0)
			if isCenterPath then
				continue
			end

			local ore = pickOreForDepth(depth, 0)

			local block = Instance.new("Part")
			block.Name = ore.Name
			block.Anchored = true
			block.Size = Vector3.new(BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE)
			block.Position = MINE_ORIGIN + Vector3.new(
				(x - CHUNK_W/2) * BLOCK_SIZE,
				yPos,
				(z - CHUNK_D/2) * BLOCK_SIZE
			)

			if ore.Rarity == "Common" and ore.Name == "Stone" then
				block.Color = Color3.new(biome.WallColor.R * darken, biome.WallColor.G * darken, biome.WallColor.B * darken)
				block.Material = biome.WallMaterial
			else
				local r = math.clamp(ore.Color.R + (math.random() - 0.5) * 0.1, 0, 1)
				local g = math.clamp(ore.Color.G + (math.random() - 0.5) * 0.1, 0, 1)
				local b = math.clamp(ore.Color.B + (math.random() - 0.5) * 0.1, 0, 1)
				block.Color = Color3.new(r * darken, g * darken, b * darken)
				if ore.Rarity == "Common" then
					block.Material = Enum.Material.Slate
				elseif ore.Rarity == "Uncommon" then
					block.Material = Enum.Material.Granite
				elseif ore.Rarity == "Rare" then
					block.Material = Enum.Material.Marble
				else
					block.Material = Enum.Material.Neon
				end
			end

			block:SetAttribute("OreType", ore.Name)
			block:SetAttribute("OreValue", ore.Value)
			block:SetAttribute("OreHealth", ore.Health)
			block:SetAttribute("MaxHealth", ore.Health)
			block:SetAttribute("OreRarity", ore.Rarity)
			block:SetAttribute("Depth", depth)
			block:SetAttribute("Biome", biome.Name)
			block.Parent = layerFolder
		end
	end

	-- Biome entrance sign
	if depth > 0 and depth == biome.DepthRange[1] then
		local sign = Instance.new("Part")
		sign.Name = "BiomeSign_" .. biome.Name
		sign.Anchored = true
		sign.CanCollide = false
		sign.Size = Vector3.new(2, 2, 2)
		sign.Transparency = 1
		sign.Position = MINE_ORIGIN + Vector3.new(0, yPos + BLOCK_SIZE * 2, 0)

		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.new(0, 300, 0, 80)
		bb.StudsOffset = Vector3.new(0, 3, 0)
		bb.Adornee = sign
		bb.AlwaysOnTop = true
		bb.Parent = sign

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = "🌍 " .. biome.Name .. " 🌍"
		lbl.TextColor3 = biome.AmbientLight
		lbl.TextScaled = true
		lbl.Font = Enum.Font.GothamBold
		lbl.TextStrokeTransparency = 0
		lbl.Parent = bb
		sign.Parent = layerFolder
	end

	return layerFolder
end

------------------------------------------------------------------------
-- INITIALIZE
------------------------------------------------------------------------
function MineGenerator.Initialize()
	local mineFolder = Workspace:FindFirstChild("Mine")
	if not mineFolder then
		mineFolder = Instance.new("Folder")
		mineFolder.Name = "Mine"
		mineFolder.Parent = Workspace
	end

	local initialLayers = GameConfig.World.Mine.RenderDistance
	for i = 0, initialLayers do
		MineGenerator.GenerateLayer(i, mineFolder)
	end

	-- Mine ceiling
	local ceiling = Instance.new("Part")
	ceiling.Name = "MineCeiling"
	ceiling.Anchored = true
	ceiling.Size = Vector3.new(CHUNK_W * BLOCK_SIZE + 20, 4, CHUNK_D * BLOCK_SIZE + 20)
	ceiling.Position = MINE_ORIGIN + Vector3.new(0, BLOCK_SIZE, 0)
	ceiling.Color = Color3.fromRGB(50, 40, 35)
	ceiling.Material = Enum.Material.Slate
	ceiling.Parent = mineFolder

	print("[RiftMiners] Mine initialized with " .. (initialLayers + 1) .. " layers and 10 biomes!")
	return mineFolder
end

return MineGenerator
