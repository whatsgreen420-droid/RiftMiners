-- HubBuilder.lua (Server ModuleScript)
-- Builds hub: shops next to white platform, prestige+leaderboard ON white platform,
-- premium items as individual stands inside awning building, mine teleporter, no white cube

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local HubBuilder = {}

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
	pe.Color = ColorSequence.new(color1 or Color3.new(1,1,1), color2 or Color3.new(1,1,1))
	pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.5), NumberSequenceKeypoint.new(1,0)})
	pe.Lifetime = NumberRange.new(1, 2)
	pe.Rate = rate or 20
	pe.Speed = NumberRange.new(2, 5)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.LightEmission = 1
	pe.Parent = part
end

local function makeTrigger(name, size, pos, interactionType, parent)
	local t = makePart({Name=name, Size=size, Position=pos, Transparency=1, CanCollide=false, Parent=parent})
	t:SetAttribute("InteractionType", interactionType)
	return t
end

------------------------------------------------------------------------
-- CLEANUP: Remove unwanted objects from existing world
------------------------------------------------------------------------
local function cleanupExistingWorld()
	-- Remove any white cube with cylinder between spawn and mine portal
	-- Look for parts near (0, Y, -30) area that are white and blocky
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Name ~= "Baseplate" and obj.Name ~= "Terrain" then
			local pos = obj.Position
			-- Target area: between spawn (0,0,0) and mine entrance (0,5,-60)
			-- Looking for white/light objects in the gap zone
			if pos.X > -15 and pos.X < 15 and pos.Z > -50 and pos.Z < -5 then
				if obj.Color.R > 0.8 and obj.Color.G > 0.8 and obj.Color.B > 0.8 then
					if obj.Size.X < 20 and obj.Size.Y < 20 and obj.Size.Z < 20 then
						-- Check if it's part of the Hub folder (our stuff) - skip those
						local isOurs = false
						local parent = obj.Parent
						while parent do
							if parent.Name == "Hub" then isOurs = true; break end
							parent = parent.Parent
						end
						if not isOurs then
							print("[RiftMiners] Removing object: " .. obj.Name .. " at " .. tostring(obj.Position))
							obj:Destroy()
						end
					end
				end
			end
		end
	end
end

------------------------------------------------------------------------
-- BUILD
------------------------------------------------------------------------
function HubBuilder.Build()
	local hub = Instance.new("Folder")
	hub.Name = "Hub"
	hub.Parent = Workspace
	local cfg = GameConfig.World.Hub

	-- Clean up the white cube between spawn and mine
	task.defer(cleanupExistingWorld)

	-- ===== STONE PATHS connecting areas =====
	local pathColor = Color3.fromRGB(140,130,120)
	local pathMat = Enum.Material.Cobblestone
	-- Spawn to mine
	makePart({Name="PathToMine", Size=Vector3.new(8,0.5,60), Position=Vector3.new(0,0.3,-30),
		Color=pathColor, Material=pathMat, Parent=hub})
	-- Spawn to sell pad
	makePart({Name="PathToSell", Size=Vector3.new(50,0.5,8), Position=Vector3.new(-25,0.3,0),
		Color=pathColor, Material=pathMat, Parent=hub})
	-- Spawn to shops (right side)
	makePart({Name="PathToShops", Size=Vector3.new(65,0.5,8), Position=Vector3.new(32,0.3,20),
		Color=pathColor, Material=pathMat, Parent=hub})
	-- Spawn to prestige/leaderboard (back-right)
	makePart({Name="PathToPrestige", Size=Vector3.new(8,0.5,55), Position=Vector3.new(80,0.3,27),
		Color=pathColor, Material=pathMat, Parent=hub})
	-- Spawn to premium shop (left)
	makePart({Name="PathToPremium", Size=Vector3.new(8,0.5,40), Position=Vector3.new(-60,0.3,20),
		Color=pathColor, Material=pathMat, Parent=hub})

	-- ===== PICKAXE SHOP (right side, near white platform) =====
	local shopPos = cfg.ShopPosition
	local shopFloor = makePart({Name="PickaxeShopFloor", Size=Vector3.new(22,1,22), Position=shopPos,
		Color=Color3.fromRGB(100,80,60), Material=Enum.Material.WoodPlanks, Parent=hub})
	makePart({Name="PSWall1", Size=Vector3.new(22,14,1), Position=shopPos+Vector3.new(0,7,11),
		Color=Color3.fromRGB(90,70,50), Material=Enum.Material.WoodPlanks, Parent=hub})
	makePart({Name="PSWall2", Size=Vector3.new(1,14,22), Position=shopPos+Vector3.new(11,7,0),
		Color=Color3.fromRGB(90,70,50), Material=Enum.Material.WoodPlanks, Parent=hub})
	local shopSign = makePart({Name="ShopSign", Size=Vector3.new(12,4,1), Position=shopPos+Vector3.new(-5,14,0),
		Color=Color3.fromRGB(50,30,15), Material=Enum.Material.Wood, Parent=hub})
	addLabel(shopSign, "⛏️ PICKAXE SHOP", Color3.fromRGB(255,215,0), Vector3.new(0,2,0))
	addLight(shopFloor, Color3.fromRGB(255,200,100), 30)
	makeTrigger("PickaxeShopTrigger", Vector3.new(24,16,24), shopPos+Vector3.new(0,7,0), "PickaxeShop", hub)

	-- ===== BACKPACK SHOP (right side, next to pickaxe shop) =====
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

	-- ===== SELL PAD (left of spawn) =====
	local sellPos = cfg.SellPadPosition
	local sellPad = makePart({Name="SellPad", Size=Vector3.new(18,1,18), Position=sellPos,
		Color=Color3.fromRGB(0,200,50), Material=Enum.Material.Neon, Parent=hub})
	sellPad:SetAttribute("InteractionType", "SellPad")
	addLabel(sellPad, "💰 SELL ORES 💰", Color3.fromRGB(0,255,100), Vector3.new(0,4,0))
	addLight(sellPad, Color3.fromRGB(0,255,50), 30, 3)
	for i = 0, 3 do
		local angle = i * 90
		local offset = CFrame.new(0,0.5,0) * CFrame.Angles(0, math.rad(angle), 0) * CFrame.new(9,0,0)
		local post = makePart({Name="SellPost"..i, Size=Vector3.new(1,4,1),
			Position=(CFrame.new(sellPos)*offset).Position,
			Color=Color3.fromRGB(255,215,0), Material=Enum.Material.Neon, Parent=hub})
		addLight(post, Color3.fromRGB(255,215,0), 10)
	end

	-- ===== PRESTIGE ALTAR (on white platform, back-right) =====
	local prestPos = cfg.PrestigeAltarPosition
	local altarBase = makePart({Name="PrestigeAltar", Size=Vector3.new(18,2,18), Position=prestPos,
		Color=Color3.fromRGB(40,0,60), Material=Enum.Material.Marble, Parent=hub})
	local crystal = makePart({Name="PrestigeCrystal", Size=Vector3.new(3,8,3), Position=prestPos+Vector3.new(0,6,0),
		Color=Color3.fromRGB(255,50,255), Material=Enum.Material.Neon, Parent=hub})
	crystal.CFrame = crystal.CFrame * CFrame.Angles(0, math.rad(45), math.rad(15))
	addLabel(crystal, "⭐ PRESTIGE ⭐", Color3.fromRGB(255,200,50), Vector3.new(0,6,0))
	addLight(crystal, Color3.fromRGB(255,50,255), 40, 3)
	addParticles(crystal, Color3.fromRGB(255,50,255), Color3.fromRGB(255,200,50), 25)
	makeTrigger("PrestigeTrigger", Vector3.new(20,12,20), prestPos+Vector3.new(0,5,0), "PrestigeAltar", hub)
	-- Pillars around altar
	for i = 0, 5 do
		local angle = i * 60
		local px = prestPos.X + math.cos(math.rad(angle)) * 9
		local pz = prestPos.Z + math.sin(math.rad(angle)) * 9
		makePart({Name="AltarPillar"..i, Size=Vector3.new(2,6,2),
			Position=Vector3.new(px, prestPos.Y+3, pz),
			Color=Color3.fromRGB(60,0,90), Material=Enum.Material.Marble, Parent=hub})
	end

	-- ===== LEADERBOARD (on white platform, next to prestige) =====
	local lbPos = cfg.LeaderboardPosition
	local lbBoard = makePart({Name="LeaderboardBoard", Size=Vector3.new(14,10,1), Position=lbPos+Vector3.new(0,5,0),
		Color=Color3.fromRGB(20,20,30), Material=Enum.Material.SmoothPlastic, Parent=hub})
	addLabel(lbBoard, "🏆 LEADERBOARD 🏆", Color3.fromRGB(255,215,0), Vector3.new(0,6,0))
	addLight(lbBoard, Color3.fromRGB(255,215,0), 20)
	lbBoard:SetAttribute("InteractionType", "Leaderboard")

	-- ===== PREMIUM SHOP — Individual purchase stands inside awning building =====
	local gpBase = cfg.GamepassShopPosition
	-- Floor for premium area
	makePart({Name="PremiumFloor", Size=Vector3.new(40,1,30), Position=gpBase,
		Color=Color3.fromRGB(30,30,50), Material=Enum.Material.SmoothPlastic, Parent=hub})

	local premiumLabel = makePart({Name="PremiumSignAnchor", Size=Vector3.new(1,1,1),
		Position=gpBase+Vector3.new(0,14,0), Transparency=1, CanCollide=false, Parent=hub})
	addLabel(premiumLabel, "💎 PREMIUM SHOP 💎", Color3.fromRGB(255,215,0), Vector3.new(0,2,0))

	-- Individual purchase pedestals for each gamepass
	local gamepasses = GameConfig.Gamepasses
	local spacing = 8
	local startX = gpBase.X - ((#gamepasses - 1) * spacing / 2)

	for i, gp in ipairs(gamepasses) do
		local pedestalPos = Vector3.new(startX + (i-1) * spacing, gpBase.Y + 1, gpBase.Z)

		-- Pedestal
		local pedestal = makePart({Name="Pedestal_"..gp.Name, Size=Vector3.new(5,3,5), Position=pedestalPos,
			Color=Color3.fromRGB(50,50,80), Material=Enum.Material.Marble, Parent=hub})

		-- Glowing orb on top
		local orbColor
		if gp.Name == "2x Ore Drops" then orbColor = Color3.fromRGB(0,200,255)
		elseif gp.Name == "Auto-Mine Drone" then orbColor = Color3.fromRGB(100,255,100)
		elseif gp.Name == "Lucky Pickaxe" then orbColor = Color3.fromRGB(50,255,50)
		elseif gp.Name == "VIP Seller" then orbColor = Color3.fromRGB(255,215,0)
		elseif gp.Name == "Void Seller" then orbColor = Color3.fromRGB(138,43,226)
		else orbColor = Color3.fromRGB(255,255,255)
		end

		local orb = makePart({Name="Orb_"..gp.Name, Size=Vector3.new(3,3,3),
			Position=pedestalPos+Vector3.new(0,4,0),
			Color=orbColor, Material=Enum.Material.Neon, Parent=hub, Shape=Enum.PartType.Ball})
		addLight(orb, orbColor, 15, 2)
		addParticles(orb, orbColor, Color3.new(1,1,1), 10)

		-- Label with icon + name
		addLabel(orb, gp.Icon .. " " .. gp.Name, orbColor, Vector3.new(0,3,0))

		-- Description label below
		local descAnchor = makePart({Name="Desc_"..gp.Name, Size=Vector3.new(1,1,1),
			Position=pedestalPos+Vector3.new(0,4,0), Transparency=1, CanCollide=false, Parent=hub})
		local descBB = Instance.new("BillboardGui")
		descBB.Size = UDim2.new(0, 200, 0, 40)
		descBB.StudsOffset = Vector3.new(0, 1, 0)
		descBB.Adornee = descAnchor
		descBB.AlwaysOnTop = true
		descBB.Parent = descAnchor
		local descLbl = Instance.new("TextLabel")
		descLbl.Size = UDim2.new(1,0,1,0)
		descLbl.BackgroundTransparency = 1
		descLbl.Text = gp.Description
		descLbl.TextColor3 = Color3.fromRGB(200,200,200)
		descLbl.TextScaled = true
		descLbl.Font = Enum.Font.Gotham
		descLbl.TextStrokeTransparency = 0.5
		descLbl.Parent = descBB

		-- Purchase trigger
		local trigger = makeTrigger("GamepassTrigger_"..gp.Name, Vector3.new(6,8,6),
			pedestalPos+Vector3.new(0,3,0), "BuyGamepass", hub)
		trigger:SetAttribute("GamepassName", gp.Name)
	end

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

	-- Glowing portal (teleporter to mine)
	local portal = makePart({Name="MinePortal", Size=Vector3.new(11,14,2), Position=mePos+Vector3.new(0,8,0),
		Color=Color3.fromRGB(138,43,226), Material=Enum.Material.Neon, Transparency=0.3, CanCollide=false, Parent=hub})
	portal:SetAttribute("InteractionType", "MineEntrance")
	addLight(portal, Color3.fromRGB(138,43,226), 45, 3)
	addParticles(portal, Color3.fromRGB(138,43,226), Color3.fromRGB(255,100,255), 40)

	-- ===== DECORATIVE RIFT CRYSTALS =====
	local crystalPositions = {
		{pos=Vector3.new(25,3,25), h=6}, {pos=Vector3.new(-25,4,25), h=8},
		{pos=Vector3.new(30,2,-30), h=5}, {pos=Vector3.new(-30,5,-25), h=7},
		{pos=Vector3.new(15,3,-40), h=5}, {pos=Vector3.new(-15,3,45), h=6},
	}
	for i, c in ipairs(crystalPositions) do
		local cr = makePart({Name="RiftCrystal_"..i, Size=Vector3.new(2,c.h,2), Position=c.pos,
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

	print("[RiftMiners] Hub built! Shops right, Prestige+LB on platform, Premium left, Mine portal ready ⛏️")
end

return HubBuilder
