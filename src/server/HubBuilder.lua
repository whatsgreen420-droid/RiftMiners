-- HubBuilder.lua (Server ModuleScript)
-- Generates the full surface hub with all shops, prestige altar, leaderboard, mine entrance

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local HubBuilder = {}

------------------------------------------------------------------------
-- UTILITIES
------------------------------------------------------------------------
local function makePart(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = props.CanCollide ~= false
	p.Size = props.Size or Vector3.new(4, 4, 4)
	p.Position = props.Position or Vector3.new(0, 0, 0)
	p.Color = props.Color or Color3.fromRGB(100, 100, 100)
	p.Material = props.Material or Enum.Material.SmoothPlastic
	p.Name = props.Name or "Part"
	p.Transparency = props.Transparency or 0
	p.Parent = props.Parent or Workspace
	if props.Shape then p.Shape = props.Shape end
	return p
end

local function addLabel(part, text, color, offset)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 220, 0, 50)
	bb.StudsOffset = offset or Vector3.new(0, 3, 0)
	bb.Adornee = part
	bb.AlwaysOnTop = true
	bb.Parent = part
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = color or Color3.new(1, 1, 1)
	lbl.TextScaled = true
	lbl.Font = Enum.Font.GothamBold
	lbl.TextStrokeTransparency = 0.3
	lbl.Parent = bb
	return bb
end

local function addLight(part, color, range, brightness)
	local l = Instance.new("PointLight")
	l.Color = color or Color3.new(1, 1, 1)
	l.Range = range or 20
	l.Brightness = brightness or 2
	l.Parent = part
end

local function addParticles(part, color1, color2, rate)
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(color1 or Color3.new(1, 1, 1), color2 or Color3.new(1, 1, 1))
	pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0)})
	pe.Lifetime = NumberRange.new(1, 2)
	pe.Rate = rate or 20
	pe.Speed = NumberRange.new(2, 5)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.LightEmission = 1
	pe.Parent = part
end

local function makeTrigger(name, size, pos, interactionType, parent)
	local t = makePart({Name = name, Size = size, Position = pos, Transparency = 1, CanCollide = false, Parent = parent})
	t:SetAttribute("InteractionType", interactionType)
	return t
end

------------------------------------------------------------------------
-- BUILD FULL HUB
------------------------------------------------------------------------
function HubBuilder.Build()
	local hub = Instance.new("Folder")
	hub.Name = "Hub"
	hub.Parent = Workspace
	local cfg = GameConfig.World.Hub

	-- ===== GROUND =====
	makePart({Name="HubGround", Size=Vector3.new(250,2,250), Position=Vector3.new(0,-1,0),
		Color=Color3.fromRGB(70,110,70), Material=Enum.Material.Grass, Parent=hub})

	-- ===== PATHS (stone walkways connecting areas) =====
	local pathColor = Color3.fromRGB(140,130,120)
	local pathMat = Enum.Material.Cobblestone
	-- Center to mine
	makePart({Name="PathToMine", Size=Vector3.new(8,0.5,60), Position=Vector3.new(0,0.3,-30),
		Color=pathColor, Material=pathMat, Parent=hub})
	-- Center to sell pad
	makePart({Name="PathToSell", Size=Vector3.new(50,0.5,8), Position=Vector3.new(-25,0.3,0),
		Color=pathColor, Material=pathMat, Parent=hub})
	-- Center to shop
	makePart({Name="PathToShop", Size=Vector3.new(50,0.5,8), Position=Vector3.new(25,0.3,0),
		Color=pathColor, Material=pathMat, Parent=hub})
	-- Center to prestige
	makePart({Name="PathToPrestige", Size=Vector3.new(8,0.5,60), Position=Vector3.new(0,0.3,30),
		Color=pathColor, Material=pathMat, Parent=hub})

	-- ===== SPAWN PLATFORM =====
	local spawn = makePart({Name="SpawnPlatform", Size=Vector3.new(20,1,20), Position=Vector3.new(0,0.5,0),
		Color=Color3.fromRGB(200,200,210), Material=Enum.Material.Marble, Parent=hub})
	addLabel(spawn, "⛏️ RIFT MINERS ⛏️", Color3.fromRGB(138,43,226), Vector3.new(0,6,0))

	-- ===== PICKAXE SHOP =====
	local shopPos = cfg.ShopPosition
	local shopFloor = makePart({Name="PickaxeShopFloor", Size=Vector3.new(24,1,24), Position=shopPos,
		Color=Color3.fromRGB(100,80,60), Material=Enum.Material.WoodPlanks, Parent=hub})
	-- Walls
	makePart({Name="PSWall1", Size=Vector3.new(24,14,1), Position=shopPos+Vector3.new(0,7,12),
		Color=Color3.fromRGB(90,70,50), Material=Enum.Material.WoodPlanks, Parent=hub})
	makePart({Name="PSWall2", Size=Vector3.new(24,14,1), Position=shopPos+Vector3.new(0,7,-12),
		Color=Color3.fromRGB(90,70,50), Material=Enum.Material.WoodPlanks, Parent=hub})
	makePart({Name="PSWall3", Size=Vector3.new(1,14,24), Position=shopPos+Vector3.new(12,7,0),
		Color=Color3.fromRGB(90,70,50), Material=Enum.Material.WoodPlanks, Parent=hub})
	local shopSign = makePart({Name="ShopSign", Size=Vector3.new(12,4,1), Position=shopPos+Vector3.new(-6,14,0),
		Color=Color3.fromRGB(50,30,15), Material=Enum.Material.Wood, Parent=hub})
	addLabel(shopSign, "⛏️ PICKAXE SHOP", Color3.fromRGB(255,215,0), Vector3.new(0,2,0))
	addLight(shopFloor, Color3.fromRGB(255,200,100), 30)
	makeTrigger("PickaxeShopTrigger", Vector3.new(26,16,26), shopPos+Vector3.new(0,7,0), "PickaxeShop", hub)

	-- ===== BACKPACK SHOP =====
	local bpPos = cfg.BackpackShopPosition
	local bpFloor = makePart({Name="BackpackShopFloor", Size=Vector3.new(20,1,20), Position=bpPos,
		Color=Color3.fromRGB(80,60,45), Material=Enum.Material.WoodPlanks, Parent=hub})
	makePart({Name="BPWall1", Size=Vector3.new(20,12,1), Position=bpPos+Vector3.new(0,6,10),
		Color=Color3.fromRGB(80,60,45), Material=Enum.Material.WoodPlanks, Parent=hub})
	makePart({Name="BPWall2", Size=Vector3.new(1,12,20), Position=bpPos+Vector3.new(10,6,0),
		Color=Color3.fromRGB(80,60,45), Material=Enum.Material.WoodPlanks, Parent=hub})
	local bpSign = makePart({Name="BPSign", Size=Vector3.new(10,3,1), Position=bpPos+Vector3.new(-5,12,0),
		Color=Color3.fromRGB(50,30,15), Material=Enum.Material.Wood, Parent=hub})
	addLabel(bpSign, "🎒 BACKPACK SHOP", Color3.fromRGB(100,200,255), Vector3.new(0,2,0))
	addLight(bpFloor, Color3.fromRGB(100,180,255), 25)
	makeTrigger("BackpackShopTrigger", Vector3.new(22,14,22), bpPos+Vector3.new(0,6,0), "BackpackShop", hub)

	-- ===== SELL PAD =====
	local sellPos = cfg.SellPadPosition
	local sellPad = makePart({Name="SellPad", Size=Vector3.new(18,1,18), Position=sellPos,
		Color=Color3.fromRGB(0,200,50), Material=Enum.Material.Neon, Parent=hub})
	sellPad:SetAttribute("InteractionType", "SellPad")
	addLabel(sellPad, "💰 SELL ORES 💰", Color3.fromRGB(0,255,100), Vector3.new(0,4,0))
	addLight(sellPad, Color3.fromRGB(0,255,50), 30, 3)
	-- Animated border
	for i = 0, 3 do
		local angle = i * 90
		local offset = CFrame.new(0,0.5,0) * CFrame.Angles(0, math.rad(angle), 0) * CFrame.new(9, 0, 0)
		local post = makePart({Name="SellPost"..i, Size=Vector3.new(1,4,1),
			Position=(CFrame.new(sellPos) * offset).Position,
			Color=Color3.fromRGB(255,215,0), Material=Enum.Material.Neon, Parent=hub})
		addLight(post, Color3.fromRGB(255,215,0), 10)
	end

	-- ===== PRESTIGE ALTAR =====
	local prestPos = cfg.PrestigeAltarPosition
	-- Circular platform
	local altarBase = makePart({Name="PrestigeAltar", Size=Vector3.new(20,2,20), Position=prestPos,
		Color=Color3.fromRGB(40,0,60), Material=Enum.Material.Marble, Parent=hub})
	-- Central crystal
	local crystal = makePart({Name="PrestigeCrystal", Size=Vector3.new(3,8,3), Position=prestPos+Vector3.new(0,6,0),
		Color=Color3.fromRGB(255,50,255), Material=Enum.Material.Neon, Parent=hub})
	crystal.CFrame = crystal.CFrame * CFrame.Angles(0, math.rad(45), math.rad(15))
	addLabel(crystal, "⭐ PRESTIGE ⭐", Color3.fromRGB(255,200,50), Vector3.new(0,6,0))
	addLight(crystal, Color3.fromRGB(255,50,255), 40, 3)
	addParticles(crystal, Color3.fromRGB(255,50,255), Color3.fromRGB(255,200,50), 25)
	makeTrigger("PrestigeTrigger", Vector3.new(22,12,22), prestPos+Vector3.new(0,5,0), "PrestigeAltar", hub)

	-- Altar pillars
	for i = 0, 5 do
		local angle = i * 60
		local px = prestPos.X + math.cos(math.rad(angle)) * 10
		local pz = prestPos.Z + math.sin(math.rad(angle)) * 10
		local pillar = makePart({Name="AltarPillar"..i, Size=Vector3.new(2,6,2),
			Position=Vector3.new(px, prestPos.Y + 3, pz),
			Color=Color3.fromRGB(60,0,90), Material=Enum.Material.Marble, Parent=hub})
		addLight(pillar, Color3.fromRGB(138,43,226), 12)
	end

	-- ===== LEADERBOARD DISPLAY =====
	local lbPos = cfg.LeaderboardPosition
	local lbBoard = makePart({Name="LeaderboardBoard", Size=Vector3.new(16,12,1), Position=lbPos+Vector3.new(0,6,0),
		Color=Color3.fromRGB(20,20,30), Material=Enum.Material.SmoothPlastic, Parent=hub})
	addLabel(lbBoard, "🏆 LEADERBOARD 🏆", Color3.fromRGB(255,215,0), Vector3.new(0,7,0))
	addLight(lbBoard, Color3.fromRGB(255,215,0), 20)
	-- Surface GUI for leaderboard will be handled by client
	lbBoard:SetAttribute("InteractionType", "Leaderboard")

	-- ===== GAMEPASS SHOP =====
	local gpPos = cfg.GamepassShopPosition
	local gpFloor = makePart({Name="GamepassShopFloor", Size=Vector3.new(22,1,22), Position=gpPos,
		Color=Color3.fromRGB(30,30,50), Material=Enum.Material.SmoothPlastic, Parent=hub})
	makePart({Name="GPWall1", Size=Vector3.new(22,14,1), Position=gpPos+Vector3.new(0,7,11),
		Color=Color3.fromRGB(20,20,40), Material=Enum.Material.SmoothPlastic, Parent=hub})
	makePart({Name="GPWall2", Size=Vector3.new(1,14,22), Position=gpPos+Vector3.new(11,7,0),
		Color=Color3.fromRGB(20,20,40), Material=Enum.Material.SmoothPlastic, Parent=hub})
	local gpSign = makePart({Name="GPSign", Size=Vector3.new(14,3,1), Position=gpPos+Vector3.new(-5,14,0),
		Color=Color3.fromRGB(255,215,0), Material=Enum.Material.Neon, Parent=hub})
	addLabel(gpSign, "💎 PREMIUM SHOP 💎", Color3.fromRGB(255,215,0), Vector3.new(0,2,0))
	addLight(gpFloor, Color3.fromRGB(255,200,50), 25)
	makeTrigger("GamepassShopTrigger", Vector3.new(24,16,24), gpPos+Vector3.new(0,7,0), "GamepassShop", hub)

	-- ===== MINE ENTRANCE PORTAL =====
	local mePos = cfg.MineEntrancePosition
	-- Stone archway
	makePart({Name="ArchLeft", Size=Vector3.new(3,18,3), Position=mePos+Vector3.new(-7,9,0),
		Color=Color3.fromRGB(60,60,60), Material=Enum.Material.Slate, Parent=hub})
	makePart({Name="ArchRight", Size=Vector3.new(3,18,3), Position=mePos+Vector3.new(7,9,0),
		Color=Color3.fromRGB(60,60,60), Material=Enum.Material.Slate, Parent=hub})
	makePart({Name="ArchTop", Size=Vector3.new(17,3,3), Position=mePos+Vector3.new(0,19,0),
		Color=Color3.fromRGB(60,60,60), Material=Enum.Material.Slate, Parent=hub})
	addLabel(makePart({Name="MineSignAnchor", Size=Vector3.new(1,1,1), Position=mePos+Vector3.new(0,22,0),
		Transparency=1, CanCollide=false, Parent=hub}),
		"⛏️ ENTER THE MINES ⛏️", Color3.fromRGB(255,100,50), Vector3.new(0,2,0))

	-- Glowing portal
	local portal = makePart({Name="MinePortal", Size=Vector3.new(11,14,2), Position=mePos+Vector3.new(0,8,0),
		Color=Color3.fromRGB(138,43,226), Material=Enum.Material.Neon, Transparency=0.3, CanCollide=false, Parent=hub})
	portal:SetAttribute("InteractionType", "MineEntrance")
	addLight(portal, Color3.fromRGB(138,43,226), 45, 3)
	addParticles(portal, Color3.fromRGB(138,43,226), Color3.fromRGB(255,100,255), 40)

	-- ===== DECORATIVE RIFT CRYSTALS =====
	local crystalPositions = {
		{pos=Vector3.new(25, 3, 25), h=6}, {pos=Vector3.new(-25, 4, 25), h=8},
		{pos=Vector3.new(30, 2, -30), h=5}, {pos=Vector3.new(-30, 5, -25), h=7},
		{pos=Vector3.new(60, 3, 30), h=4},  {pos=Vector3.new(-60, 4, -15), h=9},
		{pos=Vector3.new(15, 3, -40), h=5}, {pos=Vector3.new(-15, 3, 45), h=6},
	}
	for i, c in ipairs(crystalPositions) do
		local cr = makePart({Name="RiftCrystal_"..i, Size=Vector3.new(2, c.h, 2), Position=c.pos,
			Color=Color3.fromRGB(math.random(100,180), math.random(0,80), math.random(180,255)),
			Material=Enum.Material.Neon, Parent=hub})
		cr.CFrame = cr.CFrame * CFrame.Angles(math.rad(math.random(-15,15)), math.rad(math.random(0,360)), math.rad(math.random(-15,15)))
		addLight(cr, cr.Color, 15)
	end

	-- ===== LIGHTING & ATMOSPHERE =====
	local lighting = game:GetService("Lighting")
	lighting.TimeOfDay = "14:30:00"
	lighting.Ambient = Color3.fromRGB(40, 30, 50)
	lighting.OutdoorAmbient = Color3.fromRGB(90, 80, 110)
	lighting.FogColor = Color3.fromRGB(50, 30, 80)
	lighting.FogEnd = 600
	lighting.FogStart = 150

	local atmo = lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmo.Density = 0.25
	atmo.Offset = 0.1
	atmo.Color = Color3.fromRGB(130, 90, 170)
	atmo.Decay = Color3.fromRGB(70, 45, 90)
	atmo.Glare = 0.4
	atmo.Haze = 1.5
	atmo.Parent = lighting

	print("[RiftMiners] Hub built successfully! ⛏️")
end

return HubBuilder
