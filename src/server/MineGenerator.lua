-- MineGenerator.lua (Server ModuleScript)
-- Creates a proper mining-sim style mine area:
-- Open pit with walls, descending layers of ore blocks,
-- biome-colored walls, walking paths between blocks,
-- return-to-surface portal at top of mine

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local MineGenerator = {}

local BLOCK_SIZE = GameConfig.World.Mine.BlockSize
local CHUNK_W = GameConfig.World.Mine.ChunkWidth
local CHUNK_D = GameConfig.World.Mine.ChunkDepth
local MINE_ORIGIN = GameConfig.World.Mine.OriginPosition
local MINE_ENTRANCE = GameConfig.World.Mine.EntrancePosition

------------------------------------------------------------------------
-- BIOME LOOKUP
------------------------------------------------------------------------
local function getBiome(depth)
	for _, b in ipairs(GameConfig.Biomes) do
		if depth >= b.DepthRange[1] and depth <= b.DepthRange[2] then return b end
	end
	return GameConfig.Biomes[#GameConfig.Biomes]
end

------------------------------------------------------------------------
-- ORE SELECTION
------------------------------------------------------------------------
local function pickOre(depth, luck)
	local cands, total = {}, 0
	for _, ore in ipairs(GameConfig.Ores) do
		if depth >= ore.MinDepth then
			local w = ore.Weight
			if luck and luck > 0 and ore.Rarity ~= "Common" then w = w * (1 + luck) end
			table.insert(cands, {ore=ore, w=w})
			total = total + w
		end
	end
	if #cands == 0 then return GameConfig.Ores[1] end
	local roll = math.random() * total
	local cum = 0
	for _, c in ipairs(cands) do
		cum = cum + c.w
		if roll <= cum then return c.ore end
	end
	return cands[#cands].ore
end

------------------------------------------------------------------------
-- GENERATE A LAYER
------------------------------------------------------------------------
function MineGenerator.GenerateLayer(layerIndex, parentFolder)
	local folder = Instance.new("Folder")
	folder.Name = "Layer_" .. layerIndex
	folder.Parent = parentFolder

	local depth = layerIndex
	local yPos = MINE_ORIGIN.Y - (layerIndex * BLOCK_SIZE)
	local biome = getBiome(depth)
	local darken = math.clamp(1 - (depth / 1200), 0.15, 1)

	-- Mine walls (surrounding the ore area)
	local mineWidth = CHUNK_W * BLOCK_SIZE
	local mineDepthZ = CHUNK_D * BLOCK_SIZE

	-- Left wall
	local lw = Instance.new("Part")
	lw.Name = "WallL_"..layerIndex
	lw.Anchored = true
	lw.Size = Vector3.new(2, BLOCK_SIZE, mineDepthZ)
	lw.Position = MINE_ORIGIN + Vector3.new(-mineWidth/2 - 1, yPos, 0)
	lw.Color = Color3.new(biome.WallColor.R * darken, biome.WallColor.G * darken, biome.WallColor.B * darken)
	lw.Material = biome.WallMaterial
	lw.Parent = folder

	-- Right wall
	local rw = lw:Clone()
	rw.Name = "WallR_"..layerIndex
	rw.Position = MINE_ORIGIN + Vector3.new(mineWidth/2 + 1, yPos, 0)
	rw.Parent = folder

	-- Back wall
	local bw = Instance.new("Part")
	bw.Name = "WallB_"..layerIndex
	bw.Anchored = true
	bw.Size = Vector3.new(mineWidth + 4, BLOCK_SIZE, 2)
	bw.Position = MINE_ORIGIN + Vector3.new(0, yPos, -mineDepthZ/2 - 1)
	bw.Color = lw.Color
	bw.Material = biome.WallMaterial
	bw.Parent = folder

	-- Front wall
	local fw = bw:Clone()
	fw.Name = "WallF_"..layerIndex
	fw.Position = MINE_ORIGIN + Vector3.new(0, yPos, mineDepthZ/2 + 1)
	fw.Parent = folder

	-- Generate ore blocks in a grid
	for x = 0, CHUNK_W - 1 do
		for z = 0, CHUNK_D - 1 do
			-- Walking paths: leave a cross-shaped path every few blocks
			local isPath = (x == math.floor(CHUNK_W/2)) or (z == math.floor(CHUNK_D/2))
			-- Also leave corner paths for movement
			local isEdgePath = (x == 0 or x == CHUNK_W-1) and (z % 4 == 0)
			if isPath or isEdgePath then continue end

			local ore = pickOre(depth, 0)
			local block = Instance.new("Part")
			block.Name = ore.Name
			block.Anchored = true
			block.Size = Vector3.new(BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE)
			block.Position = MINE_ORIGIN + Vector3.new(
				(x - CHUNK_W/2) * BLOCK_SIZE + BLOCK_SIZE/2,
				yPos,
				(z - CHUNK_D/2) * BLOCK_SIZE + BLOCK_SIZE/2
			)

			-- Color: stone uses biome color, ores use their own
			if ore.Rarity == "Common" and ore.Name == "Stone" then
				block.Color = Color3.new(biome.WallColor.R*darken, biome.WallColor.G*darken, biome.WallColor.B*darken)
				block.Material = biome.WallMaterial
			else
				local r = math.clamp(ore.Color.R + (math.random()-0.5)*0.1, 0, 1)
				local g = math.clamp(ore.Color.G + (math.random()-0.5)*0.1, 0, 1)
				local b = math.clamp(ore.Color.B + (math.random()-0.5)*0.1, 0, 1)
				block.Color = Color3.new(r*darken, g*darken, b*darken)
				if ore.Rarity == "Common" then block.Material = Enum.Material.Slate
				elseif ore.Rarity == "Uncommon" then block.Material = Enum.Material.Granite
				elseif ore.Rarity == "Rare" then block.Material = Enum.Material.Marble
				else block.Material = Enum.Material.Neon end
			end

			block:SetAttribute("OreType", ore.Name)
			block:SetAttribute("OreValue", ore.Value)
			block:SetAttribute("OreHealth", ore.Health)
			block:SetAttribute("MaxHealth", ore.Health)
			block:SetAttribute("OreRarity", ore.Rarity)
			block:SetAttribute("Depth", depth)
			block:SetAttribute("Biome", biome.Name)
			block.Parent = folder
		end
	end

	-- Biome sign at start of each biome
	if depth > 0 and depth == biome.DepthRange[1] then
		local sign = Instance.new("Part")
		sign.Name = "BiomeSign_"..biome.Name
		sign.Anchored = true; sign.CanCollide = false
		sign.Size = Vector3.new(2,2,2); sign.Transparency = 1
		sign.Position = MINE_ORIGIN + Vector3.new(0, yPos + BLOCK_SIZE*2, 0)
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.new(0,300,0,80)
		bb.StudsOffset = Vector3.new(0,3,0)
		bb.Adornee = sign; bb.AlwaysOnTop = true; bb.Parent = sign
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1
		lbl.Text = "🌍 " .. biome.Name .. " — Depth " .. depth .. "m"
		lbl.TextColor3 = biome.AmbientLight; lbl.TextScaled = true
		lbl.Font = Enum.Font.GothamBold; lbl.TextStrokeTransparency = 0
		lbl.Parent = bb; sign.Parent = folder
	end

	return folder
end

------------------------------------------------------------------------
-- INITIALIZE MINE
------------------------------------------------------------------------
function MineGenerator.Initialize()
	local mineFolder = Workspace:FindFirstChild("Mine") or Instance.new("Folder")
	mineFolder.Name = "Mine"
	mineFolder.Parent = Workspace

	local mineWidth = CHUNK_W * BLOCK_SIZE
	local mineDepthZ = CHUNK_D * BLOCK_SIZE

	-- ===== MINE ENTRANCE AREA (top of the pit) =====
	-- Platform at the top where players arrive
	local entrancePlatform = Instance.new("Part")
	entrancePlatform.Name = "MineEntrancePlatform"
	entrancePlatform.Anchored = true
	entrancePlatform.Size = Vector3.new(mineWidth + 20, 2, 20)
	entrancePlatform.Position = MINE_ENTRANCE + Vector3.new(0, 0, mineDepthZ/2 + 15)
	entrancePlatform.Color = Color3.fromRGB(80, 70, 60)
	entrancePlatform.Material = Enum.Material.Slate
	entrancePlatform.Parent = mineFolder

	-- "Return to Surface" portal at mine entrance
	local returnPortal = Instance.new("Part")
	returnPortal.Name = "ReturnPortal"
	returnPortal.Anchored = true
	returnPortal.CanCollide = false
	returnPortal.Size = Vector3.new(8, 10, 2)
	returnPortal.Position = MINE_ENTRANCE + Vector3.new(0, 6, mineDepthZ/2 + 20)
	returnPortal.Color = Color3.fromRGB(0, 200, 100)
	returnPortal.Material = Enum.Material.Neon
	returnPortal.Transparency = 0.3
	returnPortal.Parent = mineFolder
	returnPortal:SetAttribute("InteractionType", "ReturnToHub")

	local rpBB = Instance.new("BillboardGui")
	rpBB.Size = UDim2.new(0, 200, 0, 50)
	rpBB.StudsOffset = Vector3.new(0, 7, 0)
	rpBB.Adornee = returnPortal; rpBB.AlwaysOnTop = true; rpBB.Parent = returnPortal
	local rpLbl = Instance.new("TextLabel")
	rpLbl.Size = UDim2.new(1,0,1,0); rpLbl.BackgroundTransparency = 1
	rpLbl.Text = "🏠 RETURN TO SURFACE"; rpLbl.TextColor3 = Color3.fromRGB(0,255,100)
	rpLbl.TextScaled = true; rpLbl.Font = Enum.Font.GothamBold
	rpLbl.TextStrokeTransparency = 0; rpLbl.Parent = rpBB

	local rpLight = Instance.new("PointLight")
	rpLight.Color = Color3.fromRGB(0,200,100); rpLight.Range = 30; rpLight.Brightness = 3
	rpLight.Parent = returnPortal

	local rpParticles = Instance.new("ParticleEmitter")
	rpParticles.Color = ColorSequence.new(Color3.fromRGB(0,200,100), Color3.fromRGB(100,255,200))
	rpParticles.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.5), NumberSequenceKeypoint.new(1,0)})
	rpParticles.Lifetime = NumberRange.new(1,2); rpParticles.Rate = 20
	rpParticles.Speed = NumberRange.new(2,4); rpParticles.SpreadAngle = Vector2.new(180,180)
	rpParticles.LightEmission = 1; rpParticles.Parent = returnPortal

	-- Mine ceiling over the entrance area
	local ceiling = Instance.new("Part")
	ceiling.Name = "MineCeiling"
	ceiling.Anchored = true
	ceiling.Size = Vector3.new(mineWidth + 20, 4, mineDepthZ + 40)
	ceiling.Position = MINE_ORIGIN + Vector3.new(0, BLOCK_SIZE + 2, 0)
	ceiling.Color = Color3.fromRGB(50, 40, 35)
	ceiling.Material = Enum.Material.Slate
	ceiling.Parent = mineFolder

	-- Generate initial layers
	local initialLayers = GameConfig.World.Mine.RenderDistance
	for i = 0, initialLayers do
		MineGenerator.GenerateLayer(i, mineFolder)
	end

	-- Ladder parts along one wall for players to climb back up
	for i = 0, initialLayers do
		local ladderY = MINE_ORIGIN.Y - (i * BLOCK_SIZE)
		local ladder = Instance.new("TrussPart")
		ladder.Name = "Ladder_"..i
		ladder.Anchored = true
		ladder.Size = Vector3.new(2, BLOCK_SIZE, 2)
		ladder.Position = MINE_ORIGIN + Vector3.new(CHUNK_W * BLOCK_SIZE / 2 + 3, ladderY, 0)
		ladder.Color = Color3.fromRGB(139, 90, 43)
		ladder.Parent = mineFolder
	end

	print("[RiftMiners] Mine initialized: " .. (initialLayers+1) .. " layers, walls, ladders, return portal ⛏️")
	return mineFolder
end

return MineGenerator
