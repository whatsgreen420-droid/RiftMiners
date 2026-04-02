-- HubBuilder.lua (Server ModuleScript)
-- Prestige on white platform, premium pedestals facing left at specified coords,
-- Pickaxe/Backpack shops flanking mine portal, no leaderboard object, cleanup white cube

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local HubBuilder = {}

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
	if props.CFrame then p.CFrame = props.CFrame end
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
	lbl.Size = UDim2.new(1,0,1,0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = color or Color3.new(1,1,1)
	lbl.TextScaled = true
	lbl.Font = Enum.Font.GothamBold
	lbl.TextStrokeTransparency = 0.3
	lbl.Parent = bb
end

local function addLight(part, color, range, brightness)
	local l = Instance.new("PointLight")
	l.Color = color or Color3.new(1,1,1)
	l.Range = range or 20
	l.Brightness = brightness or 2
	l.Parent = part
end

local function addParticles(part, c1, c2, rate)
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(c1 or Color3.new(1,1,1), c2 or Color3.new(1,1,1))
	pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0,0.5), NumberSequenceKeypoint.new(1,0)})
	pe.Lifetime = NumberRange.new(1,2)
	pe.Rate = rate or 20
	pe.Speed = NumberRange.new(2,5)
	pe.SpreadAngle = Vector2.new(180,180)
	pe.LightEmission = 1
	pe.Parent = part
end

local function makeTrigger(name, size, pos, iType, parent)
	local t = makePart({Name=name, Size=size, Position=pos, Transparency=1, CanCollide=false, Parent=parent})
	t:SetAttribute("InteractionType", iType)
	return t
end

------------------------------------------------------------------------
-- CLEANUP: Remove white cube between spawn and mine, remove rocks near shops
------------------------------------------------------------------------
local function cleanup()
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Name ~= "Baseplate" and obj.Name ~= "Terrain" then
			-- Skip our hub folder
			local isOurs = false
			local par = obj.Parent
			while par do
				if par.Name == "Hub" or par.Name == "Mine" then isOurs = true; break end
				par = par.Parent
			end
			if not isOurs then
				local pos = obj.Position
				-- Remove white objects between spawn and mine portal (Z: -50 to -5, X: -15 to 15)
				if pos.X > -15 and pos.X < 15 and pos.Z > -50 and pos.Z < -5 then
					if obj.Color.R > 0.8 and obj.Color.G > 0.8 and obj.Color.B > 0.8 then
						if obj.Size.X < 25 and obj.Size.Y < 25 then
							print("[RiftMiners] Removing: " .. obj.Name .. " at " .. tostring(pos))
							obj:Destroy()
						end
					end
				end
				-- Remove rocks near mine portal to clear path for shops (Z: -80 to -40, X: -35 to 35)
				if pos.X > -35 and pos.X < 35 and pos.Z > -80 and pos.Z < -40 and pos.Y < 15 then
					if obj.Name:lower():find("rock") or obj.Name:lower():find("mesh") or
					   (obj:IsA("MeshPart") and obj.Size.X < 30) then
						print("[RiftMiners] Clearing rock for shop access: " .. obj.Name)
						obj:Destroy()
					end
				end
			end
		end
	end
end

function HubBuilder.Build()
	local hub = Instance.new("Folder")
	hub.Name = "Hub"
	hub.Parent = Workspace
	local cfg = GameConfig.World.Hub

	task.defer(cleanup)

	-- ===== PATHS =====
	local pC = Color3.fromRGB(140,130,120)
	local pM = Enum.Material.Cobblestone
	-- Spawn to mine
	makePart({Name="PathToMine", Size=Vector3.new(8,0.5,60), Position=Vector3.new(0,0.3,-30), Color=pC, Material=pM, Parent=hub})
	-- Left to pickaxe shop
	makePart({Name="PathToPickaxe", Size=Vector3.new(20,0.5,8), Position=Vector3.new(-20,0.3,-55), Color=pC, Material=pM, Parent=hub})
	-- Right to backpack shop
	makePart({Name="PathToBackpack", Size=Vector3.new(20,0.5,8), Position=Vector3.new(20,0.3,-55), Color=pC, Material=pM, Parent=hub})

	-- ===== MINE ENTRANCE PORTAL (center) =====
	local mePos = cfg.MineEntrancePosition
	makePart({Name="ArchLeft", Size=Vector3.new(3,18,3), Position=mePos+Vector3.new(-7,9,0),
		Color=Color3.fromRGB(60,60,60), Material=Enum.Material.Slate, Parent=hub})
	makePart({Name="ArchRight", Size=Vector3.new(3,18,3), Position=mePos+Vector3.new(7,9,0),
		Color=Color3.fromRGB(60,60,60), Material=Enum.Material.Slate, Parent=hub})
	makePart({Name="ArchTop", Size=Vector3.new(17,3,3), Position=mePos+Vector3.new(0,19,0),
		Color=Color3.fromRGB(60,60,60), Material=Enum.Material.Slate, Parent=hub})
	local signAnchor = makePart({Name="MineSign", Size=Vector3.new(1,1,1), Position=mePos+Vector3.new(0,22,0),
		Transparency=1, CanCollide=false, Parent=hub})
	addLabel(signAnchor, "⛏️ ENTER THE MINES ⛏️", Color3.fromRGB(255,100,50), Vector3.new(0,2,0))

	local portal = makePart({Name="MinePortal", Size=Vector3.new(11,14,2), Position=mePos+Vector3.new(0,8,0),
		Color=Color3.fromRGB(138,43,226), Material=Enum.Material.Neon, Transparency=0.3, CanCollide=false, Parent=hub})
	portal:SetAttribute("InteractionType", "MineEntrance")
	addLight(portal, Color3.fromRGB(138,43,226), 45, 3)
	addParticles(portal, Color3.fromRGB(138,43,226), Color3.fromRGB(255,100,255), 40)

	-- ===== PICKAXE SHOP (LEFT of mine portal) =====
	local shopPos = cfg.ShopPosition
	makePart({Name="PickaxeShopFloor", Size=Vector3.new(22,1,22), Position=shopPos,
		Color=Color3.fromRGB(100,80,60), Material=Enum.Material.WoodPlanks, Parent=hub})
	makePart({Name="PSBack", Size=Vector3.new(22,14,1), Position=shopPos+Vector3.new(0,7,-11),
		Color=Color3.fromRGB(90,70,50), Material=Enum.Material.WoodPlanks, Parent=hub})
	makePart({Name="PSLeft", Size=Vector3.new(1,14,22), Position=shopPos+Vector3.new(-11,7,0),
		Color=Color3.fromRGB(90,70,50), Material=Enum.Material.WoodPlanks, Parent=hub})
	local psSign = makePart({Name="PSSign", Size=Vector3.new(12,4,1), Position=shopPos+Vector3.new(0,14,11),
		Color=Color3.fromRGB(50,30,15), Material=Enum.Material.Wood, Parent=hub})
	addLabel(psSign, "⛏️ PICKAXE SHOP", Color3.fromRGB(255,215,0), Vector3.new(0,2,0))
	addLight(makePart({Name="PSLight", Size=Vector3.new(1,1,1), Position=shopPos+Vector3.new(0,12,0),
		Transparency=1, CanCollide=false, Parent=hub}), Color3.fromRGB(255,200,100), 30)
	makeTrigger("PickaxeShopTrigger", Vector3.new(24,16,24), shopPos+Vector3.new(0,7,0), "PickaxeShop", hub)

	-- ===== BACKPACK SHOP (RIGHT of mine portal) =====
	local bpPos = cfg.BackpackShopPosition
	makePart({Name="BackpackShopFloor", Size=Vector3.new(22,1,22), Position=bpPos,
		Color=Color3.fromRGB(80,60,45), Material=Enum.Material.WoodPlanks, Parent=hub})
	makePart({Name="BPBack", Size=Vector3.new(22,14,1), Position=bpPos+Vector3.new(0,7,-11),
		Color=Color3.fromRGB(80,60,45), Material=Enum.Material.WoodPlanks, Parent=hub})
	makePart({Name="BPRight", Size=Vector3.new(1,14,22), Position=bpPos+Vector3.new(11,7,0),
		Color=Color3.fromRGB(80,60,45), Material=Enum.Material.WoodPlanks, Parent=hub})
	local bpSign = makePart({Name="BPSign", Size=Vector3.new(12,4,1), Position=bpPos+Vector3.new(0,14,11),
		Color=Color3.fromRGB(50,30,15), Material=Enum.Material.Wood, Parent=hub})
	addLabel(bpSign, "🎒 BACKPACK SHOP", Color3.fromRGB(100,200,255), Vector3.new(0,2,0))
	addLight(makePart({Name="BPLight", Size=Vector3.new(1,1,1), Position=bpPos+Vector3.new(0,12,0),
		Transparency=1, CanCollide=false, Parent=hub}), Color3.fromRGB(100,180,255), 25)
	makeTrigger("BackpackShopTrigger", Vector3.new(24,16,24), bpPos+Vector3.new(0,7,0), "BackpackShop", hub)

	-- ===== SELL PAD =====
	local sellPos = cfg.SellPadPosition
	local sellPad = makePart({Name="SellPad", Size=Vector3.new(18,1,18), Position=sellPos,
		Color=Color3.fromRGB(0,200,50), Material=Enum.Material.Neon, Parent=hub})
	sellPad:SetAttribute("InteractionType", "SellPad")
	addLabel(sellPad, "💰 SELL ORES 💰", Color3.fromRGB(0,255,100), Vector3.new(0,4,0))
	addLight(sellPad, Color3.fromRGB(0,255,50), 30, 3)
	for i = 0, 3 do
		local a = i * 90
		local off = CFrame.new(0,0.5,0) * CFrame.Angles(0,math.rad(a),0) * CFrame.new(9,0,0)
		local post = makePart({Name="SellPost"..i, Size=Vector3.new(1,4,1),
			Position=(CFrame.new(sellPos)*off).Position,
			Color=Color3.fromRGB(255,215,0), Material=Enum.Material.Neon, Parent=hub})
		addLight(post, Color3.fromRGB(255,215,0), 10)
	end

	-- ===== PRESTIGE ALTAR (on white platform at exact coords) =====
	local prestPos = cfg.PrestigeAltarPosition
	local altarBase = makePart({Name="PrestigeAltar", Size=Vector3.new(16,2,16), Position=prestPos,
		Color=Color3.fromRGB(40,0,60), Material=Enum.Material.Marble, Parent=hub})
	local crystal = makePart({Name="PrestigeCrystal", Size=Vector3.new(3,8,3), Position=prestPos+Vector3.new(0,6,0),
		Color=Color3.fromRGB(255,50,255), Material=Enum.Material.Neon, Parent=hub})
	crystal.CFrame = crystal.CFrame * CFrame.Angles(0, math.rad(45), math.rad(15))
	addLabel(crystal, "⭐ PRESTIGE ⭐", Color3.fromRGB(255,200,50), Vector3.new(0,6,0))
	addLight(crystal, Color3.fromRGB(255,50,255), 40, 3)
	addParticles(crystal, Color3.fromRGB(255,50,255), Color3.fromRGB(255,200,50), 25)
	makeTrigger("PrestigeTrigger", Vector3.new(18,12,18), prestPos+Vector3.new(0,5,0), "PrestigeAltar", hub)
	for i = 0, 5 do
		local a = i * 60
		makePart({Name="AltarPillar"..i, Size=Vector3.new(2,6,2),
			Position=Vector3.new(prestPos.X + math.cos(math.rad(a))*8, prestPos.Y+3, prestPos.Z + math.sin(math.rad(a))*8),
			Color=Color3.fromRGB(60,0,90), Material=Enum.Material.Marble, Parent=hub})
	end

	-- ===== PREMIUM SHOP — Individual pedestals facing LEFT (-X direction) =====
	local premBase = cfg.PremiumShopPosition  -- 108.054, 33.348, 2.703
	local gamepasses = GameConfig.Gamepasses
	local spacing = 10  -- space between each pedestal along Z axis

	-- Title sign
	local premSign = makePart({Name="PremiumSign", Size=Vector3.new(1,1,1),
		Position=premBase + Vector3.new(0, 8, (#gamepasses-1)*spacing/2),
		Transparency=1, CanCollide=false, Parent=hub})
	addLabel(premSign, "💎 PREMIUM SHOP 💎", Color3.fromRGB(255,215,0), Vector3.new(0,2,0))

	for i, gp in ipairs(gamepasses) do
		-- Line them up along Z axis, all facing left (-X)
		local pedPos = Vector3.new(premBase.X, premBase.Y, premBase.Z + (i-1) * spacing)

		-- Pedestal (rotated to face -X)
		local pedestal = makePart({Name="Pedestal_"..gp.Name, Size=Vector3.new(5,3,5), Position=pedPos,
			Color=Color3.fromRGB(50,50,80), Material=Enum.Material.Marble, Parent=hub})
		-- Face left: rotate 90 degrees around Y
		pedestal.CFrame = CFrame.new(pedPos) * CFrame.Angles(0, math.rad(90), 0)

		-- Glowing orb
		local orbColor
		if gp.Name == "2x Ore Drops" then orbColor = Color3.fromRGB(0,200,255)
		elseif gp.Name == "Auto-Mine Drone" then orbColor = Color3.fromRGB(100,255,100)
		elseif gp.Name == "Lucky Pickaxe" then orbColor = Color3.fromRGB(50,255,50)
		elseif gp.Name == "VIP Seller" then orbColor = Color3.fromRGB(255,215,0)
		elseif gp.Name == "Void Seller" then orbColor = Color3.fromRGB(138,43,226)
		else orbColor = Color3.fromRGB(255,255,255)
		end

		local orb = Instance.new("Part")
		orb.Name = "Orb_"..gp.Name
		orb.Anchored = true
		orb.CanCollide = false
		orb.Shape = Enum.PartType.Ball
		orb.Size = Vector3.new(3,3,3)
		orb.Position = pedPos + Vector3.new(0,4,0)
		orb.Color = orbColor
		orb.Material = Enum.Material.Neon
		orb.Parent = hub
		addLight(orb, orbColor, 15, 2)
		addParticles(orb, orbColor, Color3.new(1,1,1), 10)
		addLabel(orb, gp.Icon .. " " .. gp.Name, orbColor, Vector3.new(0,3,0))

		-- Description
		local descA = makePart({Name="Desc_"..gp.Name, Size=Vector3.new(1,1,1),
			Position=pedPos+Vector3.new(0,4,0), Transparency=1, CanCollide=false, Parent=hub})
		local dbb = Instance.new("BillboardGui")
		dbb.Size = UDim2.new(0,200,0,40)
		dbb.StudsOffset = Vector3.new(0,1,0)
		dbb.Adornee = descA; dbb.AlwaysOnTop = true; dbb.Parent = descA
		local dl = Instance.new("TextLabel")
		dl.Size = UDim2.new(1,0,1,0); dl.BackgroundTransparency = 1
		dl.Text = gp.Description; dl.TextColor3 = Color3.fromRGB(200,200,200)
		dl.TextScaled = true; dl.Font = Enum.Font.Gotham; dl.TextStrokeTransparency = 0.5; dl.Parent = dbb

		-- Trigger
		local trig = makeTrigger("GPTrigger_"..gp.Name, Vector3.new(6,8,6), pedPos+Vector3.new(0,3,0), "BuyGamepass", hub)
		trig:SetAttribute("GamepassName", gp.Name)
	end

	-- ===== DECORATIVE RIFT CRYSTALS =====
	local crystals = {
		{pos=Vector3.new(25,3,25), h=6}, {pos=Vector3.new(-25,4,25), h=8},
		{pos=Vector3.new(30,2,-30), h=5}, {pos=Vector3.new(-30,5,-25), h=7},
	}
	for i, c in ipairs(crystals) do
		local cr = makePart({Name="RiftCrystal_"..i, Size=Vector3.new(2,c.h,2), Position=c.pos,
			Color=Color3.fromRGB(math.random(100,180), math.random(0,80), math.random(180,255)),
			Material=Enum.Material.Neon, Parent=hub})
		cr.CFrame = cr.CFrame * CFrame.Angles(math.rad(math.random(-15,15)), math.rad(math.random(0,360)), math.rad(math.random(-15,15)))
		addLight(cr, cr.Color, 15)
	end

	-- ===== LIGHTING =====
	local lighting = game:GetService("Lighting")
	lighting.TimeOfDay = "14:30:00"
	lighting.Ambient = Color3.fromRGB(40,30,50)
	lighting.OutdoorAmbient = Color3.fromRGB(90,80,110)
	lighting.FogColor = Color3.fromRGB(50,30,80)
	lighting.FogEnd = 600; lighting.FogStart = 150
	local atmo = lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmo.Density = 0.25; atmo.Offset = 0.1
	atmo.Color = Color3.fromRGB(130,90,170); atmo.Decay = Color3.fromRGB(70,45,90)
	atmo.Glare = 0.4; atmo.Haze = 1.5; atmo.Parent = lighting

	print("[RiftMiners] Hub built! ⛏️")
end

return HubBuilder
