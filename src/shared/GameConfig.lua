-- GameConfig.lua
-- Master configuration for Rift Miners
-- 15 ores, 15 pickaxes, 15 backpacks, 10 biomes, 50 prestige levels, gamepasses

local GameConfig = {}

------------------------------------------------------------------------
-- 15 ORES (Common → Legendary, deeper = rarer)
------------------------------------------------------------------------
GameConfig.Ores = {
	-- COMMON (Biomes 1-3)
	{ Name = "Stone",           Rarity = "Common",    Color = Color3.fromRGB(128, 128, 128), Value = 1,      Health = 3,   MinDepth = 0,   Weight = 50 },
	{ Name = "Coal",            Rarity = "Common",    Color = Color3.fromRGB(50, 50, 50),    Value = 3,      Health = 4,   MinDepth = 0,   Weight = 40 },
	{ Name = "Copper",          Rarity = "Common",    Color = Color3.fromRGB(184, 115, 51),  Value = 8,      Health = 5,   MinDepth = 10,  Weight = 30 },

	-- UNCOMMON (Biomes 2-5)
	{ Name = "Iron",            Rarity = "Uncommon",  Color = Color3.fromRGB(160, 160, 170), Value = 15,     Health = 7,   MinDepth = 50,  Weight = 25 },
	{ Name = "Silver",          Rarity = "Uncommon",  Color = Color3.fromRGB(192, 192, 192), Value = 25,     Health = 9,   MinDepth = 100, Weight = 20 },
	{ Name = "Gold",            Rarity = "Uncommon",  Color = Color3.fromRGB(255, 215, 0),   Value = 50,     Health = 12,  MinDepth = 150, Weight = 15 },

	-- RARE (Biomes 4-7)
	{ Name = "Ruby",            Rarity = "Rare",      Color = Color3.fromRGB(224, 17, 95),   Value = 100,    Health = 16,  MinDepth = 200, Weight = 12 },
	{ Name = "Emerald",         Rarity = "Rare",      Color = Color3.fromRGB(0, 168, 107),   Value = 175,    Health = 20,  MinDepth = 300, Weight = 10 },
	{ Name = "Sapphire",        Rarity = "Rare",      Color = Color3.fromRGB(15, 82, 186),   Value = 250,    Health = 24,  MinDepth = 400, Weight = 8  },

	-- EPIC (Biomes 6-9)
	{ Name = "Platinum",        Rarity = "Epic",      Color = Color3.fromRGB(229, 228, 226), Value = 500,    Health = 30,  MinDepth = 500, Weight = 7  },
	{ Name = "Rift Shard",      Rarity = "Epic",      Color = Color3.fromRGB(138, 43, 226),  Value = 850,    Health = 40,  MinDepth = 600, Weight = 5  },
	{ Name = "Echo Stone",      Rarity = "Epic",      Color = Color3.fromRGB(0, 255, 200),   Value = 1200,   Health = 50,  MinDepth = 700, Weight = 4  },

	-- LEGENDARY (Biomes 8-10)
	{ Name = "Nebula Fragment",  Rarity = "Legendary", Color = Color3.fromRGB(100, 0, 200),  Value = 2500,   Health = 70,  MinDepth = 800, Weight = 3  },
	{ Name = "Singularity Gem",  Rarity = "Legendary", Color = Color3.fromRGB(255, 50, 255), Value = 5000,   Health = 90,  MinDepth = 900, Weight = 2  },
	{ Name = "Void Crystal",     Rarity = "Legendary", Color = Color3.fromRGB(20, 0, 50),    Value = 10000,  Health = 120, MinDepth = 950, Weight = 1  },
}

------------------------------------------------------------------------
-- RARITY COLORS (for UI)
------------------------------------------------------------------------
GameConfig.RarityColors = {
	Common    = Color3.fromRGB(180, 180, 180),
	Uncommon  = Color3.fromRGB(30, 200, 30),
	Rare      = Color3.fromRGB(30, 144, 255),
	Epic      = Color3.fromRGB(163, 53, 238),
	Legendary = Color3.fromRGB(255, 165, 0),
}

------------------------------------------------------------------------
-- 15 PICKAXES
------------------------------------------------------------------------
GameConfig.Pickaxes = {
	{ Name = "Wooden Pickaxe",       Power = 1,   Speed = 1.0,  Price = 0,          Color = Color3.fromRGB(139, 90, 43)   },
	{ Name = "Stone Pickaxe",        Power = 2,   Speed = 1.05, Price = 50,         Color = Color3.fromRGB(128, 128, 128) },
	{ Name = "Copper Pickaxe",       Power = 4,   Speed = 1.1,  Price = 250,        Color = Color3.fromRGB(184, 115, 51)  },
	{ Name = "Iron Pickaxe",         Power = 7,   Speed = 1.2,  Price = 1000,       Color = Color3.fromRGB(160, 160, 170) },
	{ Name = "Silver Pickaxe",       Power = 11,  Speed = 1.3,  Price = 3500,       Color = Color3.fromRGB(192, 192, 192) },
	{ Name = "Gold Pickaxe",         Power = 16,  Speed = 1.4,  Price = 10000,      Color = Color3.fromRGB(255, 215, 0)   },
	{ Name = "Ruby Pickaxe",         Power = 22,  Speed = 1.5,  Price = 30000,      Color = Color3.fromRGB(224, 17, 95)   },
	{ Name = "Emerald Pickaxe",      Power = 30,  Speed = 1.7,  Price = 75000,      Color = Color3.fromRGB(0, 168, 107)   },
	{ Name = "Sapphire Pickaxe",     Power = 40,  Speed = 1.9,  Price = 175000,     Color = Color3.fromRGB(15, 82, 186)   },
	{ Name = "Platinum Pickaxe",     Power = 55,  Speed = 2.1,  Price = 400000,     Color = Color3.fromRGB(229, 228, 226) },
	{ Name = "Rift Pickaxe",         Power = 75,  Speed = 2.4,  Price = 900000,     Color = Color3.fromRGB(138, 43, 226)  },
	{ Name = "Echo Breaker",         Power = 100, Speed = 2.8,  Price = 2000000,    Color = Color3.fromRGB(0, 255, 200)   },
	{ Name = "Nebula Drill",         Power = 140, Speed = 3.2,  Price = 5000000,    Color = Color3.fromRGB(100, 0, 200)   },
	{ Name = "Void Crusher",         Power = 200, Speed = 3.8,  Price = 15000000,   Color = Color3.fromRGB(20, 0, 50)     },
	{ Name = "The Worldsplitter",    Power = 300, Speed = 5.0,  Price = 50000000,   Color = Color3.fromRGB(255, 255, 255) },
}

------------------------------------------------------------------------
-- 15 BACKPACKS
------------------------------------------------------------------------
GameConfig.Backpacks = {
	{ Name = "Starter Sack",         Capacity = 15,     Price = 0          },
	{ Name = "Leather Pouch",        Capacity = 30,     Price = 75         },
	{ Name = "Canvas Bag",           Capacity = 60,     Price = 400        },
	{ Name = "Iron Bucket",          Capacity = 100,    Price = 1500       },
	{ Name = "Reinforced Crate",     Capacity = 175,    Price = 5000       },
	{ Name = "Gold Chest",           Capacity = 300,    Price = 15000      },
	{ Name = "Crystal Carrier",      Capacity = 500,    Price = 45000      },
	{ Name = "Emerald Vault",        Capacity = 800,    Price = 120000     },
	{ Name = "Platinum Container",   Capacity = 1200,   Price = 300000     },
	{ Name = "Rift Pouch",           Capacity = 1800,   Price = 700000     },
	{ Name = "Echo Satchel",         Capacity = 2800,   Price = 1500000    },
	{ Name = "Nebula Hauler",        Capacity = 4500,   Price = 4000000    },
	{ Name = "Void Reservoir",       Capacity = 7500,   Price = 10000000   },
	{ Name = "Singularity Pack",     Capacity = 12000,  Price = 30000000   },
	{ Name = "Dimensional Vault",    Capacity = 20000,  Price = 75000000   },
}

------------------------------------------------------------------------
-- 10 BIOMES (each 100 depth layers)
------------------------------------------------------------------------
GameConfig.Biomes = {
	{
		Name = "Surface Caverns",
		DepthRange = {0, 99},
		WallColor = Color3.fromRGB(120, 100, 80),
		WallMaterial = Enum.Material.Slate,
		FogColor = Color3.fromRGB(80, 70, 60),
		AmbientLight = Color3.fromRGB(80, 75, 65),
		Music = nil, -- placeholder
	},
	{
		Name = "Mudstone Tunnels",
		DepthRange = {100, 199},
		WallColor = Color3.fromRGB(100, 70, 50),
		WallMaterial = Enum.Material.Slate,
		FogColor = Color3.fromRGB(70, 50, 35),
		AmbientLight = Color3.fromRGB(70, 60, 50),
	},
	{
		Name = "Crystal Hollow",
		DepthRange = {200, 299},
		WallColor = Color3.fromRGB(60, 60, 90),
		WallMaterial = Enum.Material.Granite,
		FogColor = Color3.fromRGB(40, 40, 80),
		AmbientLight = Color3.fromRGB(50, 50, 100),
	},
	{
		Name = "Magma Depths",
		DepthRange = {300, 399},
		WallColor = Color3.fromRGB(80, 30, 10),
		WallMaterial = Enum.Material.CrackedLava,
		FogColor = Color3.fromRGB(100, 30, 10),
		AmbientLight = Color3.fromRGB(120, 50, 20),
	},
	{
		Name = "Frozen Abyss",
		DepthRange = {400, 499},
		WallColor = Color3.fromRGB(150, 200, 220),
		WallMaterial = Enum.Material.Glacier,
		FogColor = Color3.fromRGB(100, 150, 200),
		AmbientLight = Color3.fromRGB(80, 120, 180),
	},
	{
		Name = "Mushroom Grotto",
		DepthRange = {500, 599},
		WallColor = Color3.fromRGB(60, 80, 50),
		WallMaterial = Enum.Material.Grass,
		FogColor = Color3.fromRGB(30, 60, 20),
		AmbientLight = Color3.fromRGB(50, 100, 40),
	},
	{
		Name = "Rift Zone",
		DepthRange = {600, 699},
		WallColor = Color3.fromRGB(60, 20, 100),
		WallMaterial = Enum.Material.Neon,
		FogColor = Color3.fromRGB(80, 0, 120),
		AmbientLight = Color3.fromRGB(100, 30, 160),
	},
	{
		Name = "Echo Chamber",
		DepthRange = {700, 799},
		WallColor = Color3.fromRGB(0, 80, 80),
		WallMaterial = Enum.Material.Glass,
		FogColor = Color3.fromRGB(0, 60, 70),
		AmbientLight = Color3.fromRGB(0, 120, 130),
	},
	{
		Name = "Nebula Core",
		DepthRange = {800, 899},
		WallColor = Color3.fromRGB(30, 0, 60),
		WallMaterial = Enum.Material.Neon,
		FogColor = Color3.fromRGB(50, 0, 80),
		AmbientLight = Color3.fromRGB(80, 20, 140),
	},
	{
		Name = "The Void",
		DepthRange = {900, 999},
		WallColor = Color3.fromRGB(5, 0, 10),
		WallMaterial = Enum.Material.Neon,
		FogColor = Color3.fromRGB(10, 0, 20),
		AmbientLight = Color3.fromRGB(20, 0, 40),
	},
}

------------------------------------------------------------------------
-- 50 PRESTIGE LEVELS
-- Reset cash + progress → permanent multiplier + cosmetics
------------------------------------------------------------------------
GameConfig.Prestige = {
	MaxLevel = 50,
	-- Cost to prestige = this formula based on level
	-- RequiredCash(level) = 100000 * (level ^ 1.8)
	BaseCost = 100000,
	CostExponent = 1.8,

	-- Each prestige level gives:
	BonusPerLevel = {
		OreValueMultiplier = 0.05,      -- +5% ore sell value per level
		MiningSpeedMultiplier = 0.03,   -- +3% mining speed per level
	},

	-- Milestone rewards at specific prestige levels
	Milestones = {
		[1]  = { Title = "Novice Miner",        Trail = "Dust Trail" },
		[5]  = { Title = "Seasoned Digger",      Trail = "Spark Trail" },
		[10] = { Title = "Crystal Hunter",       Trail = "Crystal Trail" },
		[15] = { Title = "Deep Explorer",        Trail = "Flame Trail" },
		[20] = { Title = "Rift Walker",          Trail = "Rift Trail" },
		[25] = { Title = "Echo Master",          Trail = "Echo Trail" },
		[30] = { Title = "Void Touched",         Trail = "Void Trail" },
		[35] = { Title = "Nebula Born",          Trail = "Nebula Trail" },
		[40] = { Title = "Dimension Breaker",    Trail = "Dimension Trail" },
		[45] = { Title = "Reality Shaper",       Trail = "Reality Trail" },
		[50] = { Title = "⭐ WORLDSPLITTER ⭐",  Trail = "Singularity Trail" },
	},
}

------------------------------------------------------------------------
-- GAMEPASSES (Premium)
------------------------------------------------------------------------
GameConfig.Gamepasses = {
	{
		Name = "2x Ore Drops",
		Id = 0,  -- Replace with real gamepass ID
		Description = "Every ore you mine counts as 2! Double your earnings!",
		Effect = "DoubleOres",
		Icon = "💎",
	},
	{
		Name = "Auto-Mine Drone",
		Id = 0,
		Description = "A drone that automatically mines nearby ores for you!",
		Effect = "AutoMine",
		Icon = "🤖",
	},
	{
		Name = "Lucky Pickaxe",
		Id = 0,
		Description = "+25% chance to find rare ores!",
		Effect = "LuckyMining",
		LuckBonus = 0.25,
		Icon = "🍀",
	},
	{
		Name = "VIP Seller",
		Id = 0,
		Description = "+10% value on all ore sales!",
		Effect = "VIPSeller",
		SellBonus = 0.10,
		Icon = "💰",
	},
	{
		Name = "Void Seller",
		Id = 0,
		Description = "Sell ores anywhere! No need to return to the surface!",
		Effect = "VoidSeller",
		Icon = "🌀",
	},
}

------------------------------------------------------------------------
-- LEADERBOARD STATS
------------------------------------------------------------------------
GameConfig.Leaderboards = {
	"Crystals",   -- total Void Crystals found (prestige currency / flex)
	"MaxDepth",   -- deepest layer reached
}

------------------------------------------------------------------------
-- WORLD LAYOUT
------------------------------------------------------------------------
GameConfig.World = {
	Hub = {
		SpawnPosition = Vector3.new(0, 10, 0),
		-- Prestige altar: on the white platform
		PrestigeAltarPosition = Vector3.new(-0.129, 6.202, 142.16),
		-- Premium items: centered on top of item, facing left (-X direction)
		PremiumShopPosition = Vector3.new(108.313, 17.243, 0.448),
		-- Pickaxe shop: left side of mine portal
		ShopPosition = Vector3.new(-20, 5, -60),
		-- Backpack shop: right side of mine portal
		BackpackShopPosition = Vector3.new(20, 5, -60),
		-- Sell pad: left of spawn area
		SellPadPosition = Vector3.new(-50, 5, 0),
		-- Mine entrance: behind spawn
		MineEntrancePosition = Vector3.new(0, 5, -60),
	},
	Mine = {
		-- Mine area: large open pit style, descending layers
		-- Entrance at top, players mine downward through visible layers
		BlockSize = 6,
		ChunkWidth = 16,         -- wider mine like real mining sims
		ChunkDepth = 16,
		MaxDepth = 999,
		RenderDistance = 8,       -- more layers visible
		-- Mine entrance position: where players teleport to (top of the pit)
		EntrancePosition = Vector3.new(0, -10, -200),
		-- Origin: where blocks start generating
		OriginPosition = Vector3.new(0, -15, -200),
	},
}

------------------------------------------------------------------------
-- GAME SETTINGS
------------------------------------------------------------------------
GameConfig.Settings = {
	StartingCash = 0,
	StartingPickaxe = "Wooden Pickaxe",
	StartingBackpack = "Starter Sack",
	AutoSaveInterval = 60,
	SellMultiplier = 1.0,
	MiningCooldown = 0.3,
	MineRange = 20,
}

return GameConfig
