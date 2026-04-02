-- MineGenerator.lua (Server ModuleScript)
-- Complete mine area: enclosed, secluded, biome-layered, mining sim style
-- Mine is a separate walled-off underground area only accessible via portal
-- Each biome has distinct walls, lighting, and atmosphere

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local MineGenerator = {}

local BLOCK = GameConfig.World.Mine.BlockSize
local W = GameConfig.World.Mine.ChunkWidth
local D = GameConfig.World.Mine.ChunkDepth
local ORIGIN = GameConfig.World.Mine.OriginPosition
local ENTRANCE = GameConfig.World.Mine.EntrancePosition

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
			table.insert(cands, {ore = ore, w = w})
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
-- GENERATE ONE LAYER
------------------------------------------------------------------------
function MineGenerator.GenerateLayer(layerIndex, parentFolder)
	local folder = Instance.new("Folder")
	folder.Name = "Layer_" .. layerIndex
	folder.Parent = parentFolder

	local depth = layerIndex
	local yPos = ORIGIN.Y - (layerIndex * BLOCK)
	local biome = getBiome(depth)
	local darken = math.clamp(1 - (depth / 1200), 0.15, 1)

	local mineW = W * BLOCK
	local mineD = D * BLOCK

	-- Enclosing walls for this layer (keeps mine secluded)
	local wallColor = Color3.new(
		biome.WallColor.R * darken,
		biome.WallColor.G * darken,
		biome.WallColor.B * darken
	)

	-- Left wall
	local lw = Instance.new("Part")
	lw.Name = "WL"; lw.Anchored = true
	lw.Size = Vector3.new(3, BLOCK, mineD + 6)
	lw.Position = ORIGIN + Vector3.new(-mineW/2 - 1.5, yPos, 0)
	lw.Color = wallColor; lw.Material = biome.WallMaterial; lw.Parent = folder

	-- Right wall
	local rw = lw:Clone(); rw.Name = "WR"
	rw.Position = ORIGIN + Vector3.new(mineW/2 + 1.5, yPos, 0)
	rw.Parent = folder

	-- Back wall
	local bw = Instance.new("Part")
	bw.Name = "WB"; bw.Anchored = true
	bw.Size = Vector3.new(mineW + 6, BLOCK, 3)
	bw.Position = ORIGIN + Vector3.new(0, yPos, -mineD/2 - 1.5)
	bw.Color = wallColor; bw.Material = biome.WallMaterial; bw.Parent = folder

	-- Front wall (with gap for entry on first layer)
	if layerIndex > 0 then
		local fw = bw:Clone(); fw.Name = "WF"
		fw.Position = ORIGIN + Vector3.new(0, yPos, mineD/2 + 1.5)
		fw.Parent = folder
	else
		-- Front wall with entry gap
		local fwL = Instance.new("Part")
		fwL.Name = "WFL"; fwL.Anchored = true
		fwL.Size = Vector3.new(mineW/2 - 6, BLOCK, 3)
		fwL.Position = ORIGIN + Vector3.new(-mineW/4 - 3, yPos, mineD/2 + 1.5)
		fwL.Color = wallColor; fwL.Material = biome.WallMaterial; fwL.Parent = folder

		local fwR = fwL:Clone(); fwR.Name = "WFR"
		fwR.Position = ORIGIN + Vector3.new(mineW/4 + 3, yPos, mineD/2 + 1.5)
		fwR.Parent = folder
	end

	-- Floor for visual depth separation between layers
	if layerIndex > 0 and layerIndex % 5 == 0 then
		local floor = Instance.new("Part")
		floor.Name = "Floor_"..layerIndex
		floor.Anchored = true
		floor.Size = Vector3.new(mineW, 1, mineD)
		floor.Position = ORIGIN + Vector3.new(0, yPos + BLOCK/2 + 0.5, 0)
		floor.Color = Color3.new(wallColor.R * 0.7, wallColor.G * 0.7, wallColor.B * 0.7)
		floor.Material = biome.WallMaterial
		floor.Transparency = 0.3
		floor.Parent = folder
	end

	-- Generate ore blocks
	for x = 0, W - 1 do
		for z = 0, D - 1 do
			-- Walking paths: cross shape + edges
			local cx = math.floor(W / 2)
			local cz = math.floor(D / 2)
			local isPath = (x == cx or x == cx - 1) or (z == cz or z == cz - 1)
			local isEdge = (x == 0 or x == W - 1) and (z % 3 == 0)
			if isPath or isEdge then continue end

			local ore = pickOre(depth, 0)
			local block = Instance.new("Part")
			block.Name = ore.Name
			block.Anchored = true
			block.Size = Vector3.new(BLOCK, BLOCK, BLOCK)
			block.Position = ORIGIN + Vector3.new(
				(x - W/2) * BLOCK + BLOCK/2,
				yPos,
				(z - D/2) * BLOCK + BLOCK/2
			)

			-- Stone uses biome color
			if ore.Rarity == "Common" and ore.Name == "Stone" then
				block.Color = wallColor
				block.Material = biome.WallMaterial
			else
				local r = math.clamp(ore.Color.R + (math.random()-0.5)*0.08, 0, 1)
				local g = math.clamp(ore.Color.G + (math.random()-0.5)*0.08, 0, 1)
				local b = math.clamp(ore.Color.B + (math.random()-0.5)*0.08, 0, 1)
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

	-- Biome transition sign
	if depth > 0 and depth == biome.DepthRange[1] then
		local sign = Instance.new("Part")
		sign.Name = "BiomeSign_"..biome.Name
		sign.Anchored = true; sign.CanCollide = false
		sign.Size = Vector3.new(1,1,1); sign.Transparency = 1
		sign.Position = ORIGIN + Vector3.new(0, yPos + BLOCK*1.5, 0)

		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.new(0, 228, 0, 65)
		bb.StudsOffset = Vector3.new(0, 2, 0)
		bb.Adornee = sign; bb.AlwaysOnTop = false; bb.MaxDistance = 60; bb.Parent = sign

		-- Background card
		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, 0, 1, 0)
		card.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
		card.BackgroundTransparency = 0.3
		card.BorderSizePixel = 0; card.Parent = bb
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)
		local stroke = Instance.new("UIStroke")
		stroke.Color = biome.AmbientLight; stroke.Thickness = 2; stroke.Parent = card

		local biomeName = Instance.new("TextLabel")
		biomeName.Size = UDim2.new(1, 0, 0.6, 0)
		biomeName.BackgroundTransparency = 1
		biomeName.Text = "🌍 " .. biome.Name
		biomeName.TextColor3 = biome.AmbientLight
		biomeName.TextScaled = true
		biomeName.Font = Enum.Font.GothamBold
		biomeName.TextStrokeTransparency = 0; biomeName.Parent = card

		local depthLbl = Instance.new("TextLabel")
		depthLbl.Size = UDim2.new(1, 0, 0.4, 0)
		depthLbl.Position = UDim2.new(0, 0, 0.6, 0)
		depthLbl.BackgroundTransparency = 1
		depthLbl.Text = "Depth: " .. depth .. " - " .. biome.DepthRange[2] .. " blocks"
		depthLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
		depthLbl.TextScaled = true
		depthLbl.Font = Enum.Font.Gotham
		depthLbl.TextStrokeTransparency = 0.5; depthLbl.Parent = card

		sign.Parent = folder
	end

	-- Biome-specific decorations
	if depth == biome.DepthRange[1] then
		-- Ambient lighting for the biome
		local light = Instance.new("PointLight")
		light.Name = "BiomeLight_"..biome.Name
		light.Color = biome.AmbientLight
		light.Range = 60
		light.Brightness = 1.5

		local lightHolder = Instance.new("Part")
		lightHolder.Name = "LightHolder"; lightHolder.Anchored = true
		lightHolder.CanCollide = false; lightHolder.Transparency = 1
		lightHolder.Size = Vector3.new(1,1,1)
		lightHolder.Position = ORIGIN + Vector3.new(0, yPos, 0)
		light.Parent = lightHolder
		lightHolder.Parent = folder
	end

	-- Ladder on right wall every layer
	local ladder = Instance.new("TrussPart")
	ladder.Name = "Ladder_"..layerIndex
	ladder.Anchored = true
	ladder.Size = Vector3.new(2, BLOCK, 2)
	ladder.Position = ORIGIN + Vector3.new(W * BLOCK / 2, yPos, 0)
	ladder.Color = Color3.fromRGB(120, 80, 40)
	ladder.Parent = folder

	return folder
end

------------------------------------------------------------------------
-- INITIALIZE MINE
------------------------------------------------------------------------
function MineGenerator.Initialize()
	local mineFolder = Instance.new("Folder")
	mineFolder.Name = "Mine"
	mineFolder.Parent = Workspace

	local mineW = W * BLOCK
	local mineD = D * BLOCK

	-- ===== MINE ENTRANCE AREA =====
	-- Entrance platform (where players arrive after teleporting)
	local platPos = ENTRANCE + Vector3.new(0, 0, mineD/2 + 20)
	local platform = Instance.new("Part")
	platform.Name = "MineEntrancePlatform"
	platform.Anchored = true
	platform.Size = Vector3.new(mineW + 10, 2, 30)
	platform.Position = platPos
	platform.Color = Color3.fromRGB(70, 65, 55)
	platform.Material = Enum.Material.Slate
	platform.Parent = mineFolder

	-- Entrance sign (wooden, matching hub palette)
	local signBoard = Instance.new("Part")
	signBoard.Name = "MineSign"
	signBoard.Anchored = true
	signBoard.Size = Vector3.new(20, 8, 2)
	signBoard.Position = platPos + Vector3.new(0, 6, -5)
	signBoard.Color = Color3.fromRGB(90, 70, 50)
	signBoard.Material = Enum.Material.WoodPlanks
	signBoard.Parent = mineFolder

	-- Sign posts
	for _, xOff in ipairs({-9, 9}) do
		local post = Instance.new("Part")
		post.Name = "SignPost"; post.Anchored = true
		post.Size = Vector3.new(2, 12, 2)
		post.Position = platPos + Vector3.new(xOff, 4, -5)
		post.Color = Color3.fromRGB(80, 60, 40)
		post.Material = Enum.Material.Wood
		post.Parent = mineFolder
	end

	local signBB = Instance.new("BillboardGui")
	signBB.Size = UDim2.new(0, 163, 0, 39)
	signBB.StudsOffset = Vector3.new(0, 5, 0)
	signBB.Adornee = signBoard; signBB.AlwaysOnTop = false; signBB.MaxDistance = 60
	signBB.Parent = signBoard
	local signLbl = Instance.new("TextLabel")
	signLbl.Size = UDim2.new(1,0,1,0)
	signLbl.BackgroundTransparency = 1
	signLbl.Text = "⛏️ THE MINES ⛏️"
	signLbl.TextColor3 = Color3.fromRGB(255, 200, 100)
	signLbl.TextScaled = true; signLbl.Font = Enum.Font.GothamBold
	signLbl.TextStrokeTransparency = 0; signLbl.Parent = signBB

	-- Fence around entrance area (wooden, matching palette)
	local fenceColor = Color3.fromRGB(90, 70, 50)
	local fenceMat = Enum.Material.WoodPlanks
	-- Left fence
	local fl = Instance.new("Part"); fl.Name = "FenceL"; fl.Anchored = true
	fl.Size = Vector3.new(2, 4, 30); fl.Position = platPos + Vector3.new(-mineW/2 - 5, 2, 0)
	fl.Color = fenceColor; fl.Material = fenceMat; fl.Parent = mineFolder
	-- Right fence
	local fr = fl:Clone(); fr.Name = "FenceR"
	fr.Position = platPos + Vector3.new(mineW/2 + 5, 2, 0); fr.Parent = mineFolder
	-- Back fence (behind platform)
	local fb = Instance.new("Part"); fb.Name = "FenceB"; fb.Anchored = true
	fb.Size = Vector3.new(mineW + 14, 4, 2); fb.Position = platPos + Vector3.new(0, 2, 15)
	fb.Color = fenceColor; fb.Material = fenceMat; fb.Parent = mineFolder

	-- Return to Surface portal
	local returnPortal = Instance.new("Part")
	returnPortal.Name = "ReturnPortal"
	returnPortal.Anchored = true; returnPortal.CanCollide = false
	returnPortal.Size = Vector3.new(8, 10, 2)
	returnPortal.Position = platPos + Vector3.new(0, 6, 10)
	returnPortal.Color = Color3.fromRGB(0, 200, 100)
	returnPortal.Material = Enum.Material.Neon
	returnPortal.Transparency = 0.3
	returnPortal.Parent = mineFolder
	returnPortal:SetAttribute("InteractionType", "ReturnToHub")

	-- Portal sign
	local rpBB = Instance.new("BillboardGui")
	rpBB.Size = UDim2.new(0, 130, 0, 32)
	rpBB.StudsOffset = Vector3.new(0, 7, 0)
	rpBB.Adornee = returnPortal; rpBB.AlwaysOnTop = false; rpBB.MaxDistance = 50; rpBB.Parent = returnPortal
	local rpLbl = Instance.new("TextLabel")
	rpLbl.Size = UDim2.new(1,0,1,0); rpLbl.BackgroundTransparency = 1
	rpLbl.Text = "🏠 RETURN TO SURFACE"
	rpLbl.TextColor3 = Color3.fromRGB(0, 255, 100)
	rpLbl.TextScaled = true; rpLbl.Font = Enum.Font.GothamBold
	rpLbl.TextStrokeTransparency = 0; rpLbl.Parent = rpBB

	-- Portal particles + light
	local rpPE = Instance.new("ParticleEmitter")
	rpPE.Color = ColorSequence.new(Color3.fromRGB(0,200,100), Color3.fromRGB(100,255,200))
	rpPE.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.5), NumberSequenceKeypoint.new(1,0)})
	rpPE.Lifetime = NumberRange.new(1,2); rpPE.Rate = 20
	rpPE.Speed = NumberRange.new(2,4); rpPE.SpreadAngle = Vector2.new(180,180)
	rpPE.LightEmission = 1; rpPE.Parent = returnPortal

	local rpLight = Instance.new("PointLight")
	rpLight.Color = Color3.fromRGB(0,200,100); rpLight.Range = 30
	rpLight.Brightness = 3; rpLight.Parent = returnPortal

	-- Torch lights along entrance area (matching palette)
	for _, pos in ipairs({
		platPos + Vector3.new(-15, 4, 0),
		platPos + Vector3.new(15, 4, 0),
		platPos + Vector3.new(-15, 4, -10),
		platPos + Vector3.new(15, 4, -10),
	}) do
		local torch = Instance.new("Part")
		torch.Name = "Torch"; torch.Anchored = true
		torch.Size = Vector3.new(1, 6, 1)
		torch.Position = pos
		torch.Color = Color3.fromRGB(80, 60, 40)
		torch.Material = Enum.Material.Wood
		torch.Parent = mineFolder

		local flame = Instance.new("PointLight")
		flame.Color = Color3.fromRGB(255, 160, 50)
		flame.Range = 20; flame.Brightness = 2
		flame.Parent = torch

		local firePE = Instance.new("ParticleEmitter")
		firePE.Color = ColorSequence.new(Color3.fromRGB(255,150,30), Color3.fromRGB(255,80,0))
		firePE.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.3), NumberSequenceKeypoint.new(1,0)})
		firePE.Lifetime = NumberRange.new(0.3, 0.8)
		firePE.Rate = 15; firePE.Speed = NumberRange.new(1,3)
		firePE.SpreadAngle = Vector2.new(20, 20)
		firePE.LightEmission = 1; firePE.Parent = torch
	end

	-- Mine ceiling (covers entire mine area)
	local ceiling = Instance.new("Part")
	ceiling.Name = "MineCeiling"; ceiling.Anchored = true
	ceiling.Size = Vector3.new(mineW + 20, 4, mineD + 50)
	ceiling.Position = ORIGIN + Vector3.new(0, BLOCK + 2, 10)
	ceiling.Color = Color3.fromRGB(50, 40, 35)
	ceiling.Material = Enum.Material.Slate
	ceiling.Parent = mineFolder

	-- Separation wall between mine and hub (ensures mine is secluded)
	local sepWall = Instance.new("Part")
	sepWall.Name = "SeparationWall"; sepWall.Anchored = true
	sepWall.Size = Vector3.new(200, 50, 5)
	sepWall.Position = ORIGIN + Vector3.new(0, 25, mineD/2 + 40)
	sepWall.Color = Color3.fromRGB(50, 45, 40)
	sepWall.Material = Enum.Material.Slate
	sepWall.Transparency = 0
	sepWall.Parent = mineFolder

	-- Generate initial layers
	local initLayers = GameConfig.World.Mine.RenderDistance
	for i = 0, initLayers do
		MineGenerator.GenerateLayer(i, mineFolder)
	end

	print("[RiftMiners] Mine initialized: " .. (initLayers+1) .. " layers, enclosed, biome-lit, secluded ⛏️")
	return mineFolder
end

return MineGenerator
