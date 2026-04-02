-- HubDecorations.server.lua
-- Decorative elements for the hub area: wooden leaderboard boards, lanterns,
-- large ore crystal displays, fence details — all matching game color palette

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local function makePart(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = props.CanCollide ~= false
	p.Size = props.Size or Vector3.new(4,4,4)
	p.Position = props.Position or Vector3.new(0,0,0)
	p.Color = props.Color or Color3.fromRGB(100,100,100)
	p.Material = props.Material or Enum.Material.SmoothPlastic
	p.Name = props.Name or "Part"
	p.Transparency = props.Transparency or 0
	p.Parent = props.Parent or Workspace
	return p
end

local function addLabel(part, text, color, offset)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 200, 0, 40)
	bb.StudsOffset = offset or Vector3.new(0, 2, 0)
	bb.Adornee = part; bb.AlwaysOnTop = true; bb.Parent = part
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1
	lbl.Text = text; lbl.TextColor3 = color or Color3.new(1,1,1)
	lbl.TextScaled = true; lbl.Font = Enum.Font.GothamBold
	lbl.TextStrokeTransparency = 0.3; lbl.Parent = bb
end

local function addLight(part, color, range)
	local l = Instance.new("PointLight")
	l.Color = color or Color3.new(1,1,1)
	l.Range = range or 15; l.Brightness = 2; l.Parent = part
end

local function createLantern(position, parent)
	-- Wooden post
	local post = makePart({Name="LanternPost", Size=Vector3.new(0.5, 6, 0.5), Position=position,
		Color=Color3.fromRGB(80,60,40), Material=Enum.Material.Wood, Parent=parent})
	-- Crossbar
	makePart({Name="LanternArm", Size=Vector3.new(2, 0.3, 0.3), Position=position+Vector3.new(1, 3, 0),
		Color=Color3.fromRGB(60,40,25), Material=Enum.Material.Wood, Parent=parent})
	-- Lantern body
	local lantern = makePart({Name="LanternBody", Size=Vector3.new(0.8, 1.2, 0.8),
		Position=position+Vector3.new(2, 2.5, 0),
		Color=Color3.fromRGB(255, 180, 50), Material=Enum.Material.Neon,
		Transparency=0.2, Parent=parent})
	addLight(lantern, Color3.fromRGB(255, 160, 50), 25)
	-- Warm fire particles
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(Color3.fromRGB(255,150,30), Color3.fromRGB(255,80,0))
	pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.15), NumberSequenceKeypoint.new(1,0)})
	pe.Lifetime = NumberRange.new(0.3, 0.6); pe.Rate = 8
	pe.Speed = NumberRange.new(0.5, 1.5); pe.SpreadAngle = Vector2.new(15,15)
	pe.LightEmission = 1; pe.Parent = lantern
end

------------------------------------------------------------------------
-- BUILD DECORATIONS
------------------------------------------------------------------------
local decoFolder = Instance.new("Folder")
decoFolder.Name = "Decorations"
decoFolder.Parent = Workspace

-- ===== WOODEN LEADERBOARD BOARDS =====
-- Near spawn area, matching wood palette
local lbPos = Vector3.new(-35, 5, 30)

-- Main board (wood)
local boardBack = makePart({Name="LeaderboardBack", Size=Vector3.new(18, 12, 2),
	Position=lbPos+Vector3.new(0, 6, 0),
	Color=Color3.fromRGB(80, 60, 45), Material=Enum.Material.WoodPlanks, Parent=decoFolder})

-- Board frame
for _, off in ipairs({Vector3.new(-9.5, 6, 0), Vector3.new(9.5, 6, 0)}) do
	makePart({Name="BoardPost", Size=Vector3.new(1.5, 14, 1.5),
		Position=lbPos+off, Color=Color3.fromRGB(60, 40, 25),
		Material=Enum.Material.Wood, Parent=decoFolder})
end
makePart({Name="BoardTop", Size=Vector3.new(20, 1.5, 2),
	Position=lbPos+Vector3.new(0, 13, 0), Color=Color3.fromRGB(60, 40, 25),
	Material=Enum.Material.Wood, Parent=decoFolder})

addLabel(boardBack, "🏆 TOP MINERS 🏆", Color3.fromRGB(255, 215, 0), Vector3.new(0, 7, 0))

-- Sub-labels for categories
local categories = {"💎 Most Crystals", "📏 Deepest Miner", "⭐ Highest Prestige"}
for i, cat in ipairs(categories) do
	local subSign = makePart({Name="LBSub_"..i, Size=Vector3.new(5, 2, 0.5),
		Position=lbPos + Vector3.new(-6 + (i-1)*6, 10, -1.5),
		Color=Color3.fromRGB(50, 35, 20), Material=Enum.Material.Wood, Parent=decoFolder})
	addLabel(subSign, cat, Color3.fromRGB(200, 200, 200), Vector3.new(0, 1.5, 0))
end

-- Lanterns near leaderboard
createLantern(lbPos + Vector3.new(-12, 0, 2), decoFolder)
createLantern(lbPos + Vector3.new(12, 0, 2), decoFolder)

-- ===== LARGE ORE CRYSTAL DISPLAYS =====
-- Decorative crystals around hub, showing off different ores
local crystalDisplays = {
	{pos = Vector3.new(30, 3, 35),  ore = "Ruby",      color = Color3.fromRGB(224, 17, 95),  h = 7},
	{pos = Vector3.new(-30, 3, 35), ore = "Emerald",    color = Color3.fromRGB(0, 168, 107),  h = 6},
	{pos = Vector3.new(40, 3, -20), ore = "Rift Shard", color = Color3.fromRGB(138, 43, 226), h = 8},
	{pos = Vector3.new(-40, 3, -20),ore = "Gold",       color = Color3.fromRGB(255, 215, 0),  h = 5},
	{pos = Vector3.new(20, 3, 50),  ore = "Sapphire",   color = Color3.fromRGB(15, 82, 186),  h = 6},
	{pos = Vector3.new(-20, 3, 50), ore = "Void Crystal",color = Color3.fromRGB(20, 0, 50),   h = 9},
}

for i, cd in ipairs(crystalDisplays) do
	-- Pedestal (stone, matching palette)
	local ped = makePart({Name="CrystalPed_"..i, Size=Vector3.new(4, 2, 4), Position=cd.pos,
		Color=Color3.fromRGB(70, 65, 60), Material=Enum.Material.Slate, Parent=decoFolder})

	-- Crystal
	local crystal = makePart({Name="Crystal_"..cd.ore, Size=Vector3.new(2, cd.h, 2),
		Position=cd.pos + Vector3.new(0, cd.h/2 + 1, 0),
		Color=cd.color, Material=Enum.Material.Neon, Parent=decoFolder})
	crystal.CFrame = crystal.CFrame * CFrame.Angles(
		math.rad(math.random(-10,10)), math.rad(math.random(0,360)), math.rad(math.random(-10,10)))
	addLight(crystal, cd.color, 20)
	addLabel(crystal, cd.ore, cd.color, Vector3.new(0, cd.h/2 + 1, 0))

	-- Subtle particles
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(cd.color, Color3.new(1,1,1))
	pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.2), NumberSequenceKeypoint.new(1,0)})
	pe.Lifetime = NumberRange.new(1,2); pe.Rate = 5
	pe.Speed = NumberRange.new(0.5,1.5); pe.SpreadAngle = Vector2.new(180,180)
	pe.LightEmission = 0.8; pe.Transparency = NumberSequence.new(0.3, 1)
	pe.Parent = crystal
end

-- ===== HUB LANTERNS along paths =====
local lanternPositions = {
	Vector3.new(10, 0, -20), Vector3.new(-10, 0, -20),
	Vector3.new(10, 0, -40), Vector3.new(-10, 0, -40),
	Vector3.new(25, 0, 10),  Vector3.new(-25, 0, 10),
	Vector3.new(0, 0, 20),   Vector3.new(0, 0, 40),
}

for _, pos in ipairs(lanternPositions) do
	createLantern(pos, decoFolder)
end

-- ===== WOODEN FENCE around spawn area =====
local fenceColor = Color3.fromRGB(90, 70, 50)
local fenceMat = Enum.Material.WoodPlanks

-- Fence segments around the hub perimeter
local fenceSegments = {
	{pos = Vector3.new(80, 2, 0),   size = Vector3.new(2, 4, 80)},
	{pos = Vector3.new(-80, 2, 0),  size = Vector3.new(2, 4, 80)},
	{pos = Vector3.new(0, 2, 70),   size = Vector3.new(160, 4, 2)},
}

for i, seg in ipairs(fenceSegments) do
	makePart({Name="HubFence_"..i, Size=seg.size, Position=seg.pos,
		Color=fenceColor, Material=fenceMat, Parent=decoFolder})
	-- Fence posts every 10 studs
	local length = math.max(seg.size.X, seg.size.Z)
	local isXAxis = seg.size.X > seg.size.Z
	for j = 0, math.floor(length / 10) do
		local offset = -length/2 + j * 10
		local postPos
		if isXAxis then
			postPos = seg.pos + Vector3.new(offset, 1, 0)
		else
			postPos = seg.pos + Vector3.new(0, 1, offset)
		end
		makePart({Name="FencePost_"..i.."_"..j, Size=Vector3.new(1, 6, 1),
			Position=postPos, Color=Color3.fromRGB(60,40,25),
			Material=Enum.Material.Wood, Parent=decoFolder})
	end
end

-- ===== VERSION DISPLAY (small, bottom corner) =====
-- Added via client script would be better, but a world sign works too
local versionSign = makePart({Name="VersionSign", Size=Vector3.new(6, 2, 0.5),
	Position=Vector3.new(75, 2, 68),
	Color=Color3.fromRGB(40, 35, 30), Material=Enum.Material.Wood, Parent=decoFolder})
addLabel(versionSign, "v1.0.0", Color3.fromRGB(150, 150, 150), Vector3.new(0, 1, 0))

print("[RiftMiners] Hub decorations loaded: leaderboards, lanterns, crystals, fences 🏮")
