-- QuestManager.server.lua
-- Server-side quest tracking and NPC dialog management

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local DataStoreService = game:GetService("DataStoreService")

local QuestSystem = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("QuestSystem"))

-- Remotes
local questRemote = Instance.new("RemoteEvent")
questRemote.Name = "QuestRemote"
questRemote.Parent = ReplicatedStorage

local questFunction = Instance.new("RemoteFunction")
questFunction.Name = "QuestFunction"
questFunction.Parent = ReplicatedStorage

-- Per-player quest state: { [UserId] = { active = {questId, progress}, completed = {questId = true} } }
local playerQuests = {}

---------- NPC BUILDER ----------

local function createNPC(name, position)
	local npcModel = Instance.new("Model")
	npcModel.Name = name
	
	-- Torso (HumanoidRootPart)
	local torso = Instance.new("Part")
	torso.Name = "HumanoidRootPart"
	torso.Size = Vector3.new(2, 2, 1)
	torso.Position = position
	torso.Anchored = true
	torso.BrickColor = BrickColor.new("Bright yellow")
	torso.Parent = npcModel
	npcModel.PrimaryPart = torso
	
	-- Head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.6, 1.6, 1.6)
	head.Position = position + Vector3.new(0, 1.8, 0)
	head.Anchored = true
	head.BrickColor = BrickColor.new("Light orange")
	head.Parent = npcModel
	
	-- Face
	local face = Instance.new("Decal")
	face.Name = "face"
	face.Face = Enum.NormalId.Front
	face.Texture = "rbxassetid://144080495" -- default Roblox face
	face.Parent = head
	
	-- Mining helmet
	local helmet = Instance.new("Part")
	helmet.Name = "Helmet"
	helmet.Size = Vector3.new(1.8, 0.6, 1.8)
	helmet.Position = position + Vector3.new(0, 2.8, 0)
	helmet.Anchored = true
	helmet.BrickColor = BrickColor.new("Bright orange")
	helmet.Shape = Enum.PartType.Cylinder
	helmet.Orientation = Vector3.new(0, 0, 90)
	helmet.Parent = npcModel
	
	-- Helmet light
	local helmetLight = Instance.new("Part")
	helmetLight.Name = "HelmetLight"
	helmetLight.Size = Vector3.new(0.4, 0.4, 0.4)
	helmetLight.Position = position + Vector3.new(0, 2.8, -0.9)
	helmetLight.Anchored = true
	helmetLight.BrickColor = BrickColor.new("New Yeller")
	helmetLight.Shape = Enum.PartType.Ball
	helmetLight.Material = Enum.Material.Neon
	helmetLight.Parent = npcModel
	
	local light = Instance.new("SpotLight")
	light.Brightness = 3
	light.Range = 30
	light.Angle = 45
	light.Face = Enum.NormalId.Front
	light.Parent = helmetLight
	
	-- Left arm
	local leftArm = Instance.new("Part")
	leftArm.Name = "LeftArm"
	leftArm.Size = Vector3.new(1, 2, 1)
	leftArm.Position = position + Vector3.new(-1.5, 0, 0)
	leftArm.Anchored = true
	leftArm.BrickColor = BrickColor.new("Bright yellow")
	leftArm.Parent = npcModel
	
	-- Right arm
	local rightArm = Instance.new("Part")
	rightArm.Name = "RightArm"
	rightArm.Size = Vector3.new(1, 2, 1)
	rightArm.Position = position + Vector3.new(1.5, 0, 0)
	rightArm.Anchored = true
	rightArm.BrickColor = BrickColor.new("Bright yellow")
	rightArm.Parent = npcModel
	
	-- Left leg
	local leftLeg = Instance.new("Part")
	leftLeg.Name = "LeftLeg"
	leftLeg.Size = Vector3.new(1, 2, 1)
	leftLeg.Position = position + Vector3.new(-0.5, -2, 0)
	leftLeg.Anchored = true
	leftLeg.BrickColor = BrickColor.new("Earth green")
	leftLeg.Parent = npcModel
	
	-- Right leg
	local rightLeg = Instance.new("Part")
	rightLeg.Name = "RightLeg"
	rightLeg.Size = Vector3.new(1, 2, 1)
	rightLeg.Position = position + Vector3.new(0.5, -2, 0)
	rightLeg.Anchored = true
	rightLeg.BrickColor = BrickColor.new("Earth green")
	rightLeg.Parent = npcModel
	
	-- Pickaxe in right hand
	local pickHandle = Instance.new("Part")
	pickHandle.Name = "PickHandle"
	pickHandle.Size = Vector3.new(0.3, 3, 0.3)
	pickHandle.Position = position + Vector3.new(2.2, 0.5, 0)
	pickHandle.Anchored = true
	pickHandle.BrickColor = BrickColor.new("Brown")
	pickHandle.Material = Enum.Material.Wood
	pickHandle.Rotation = Vector3.new(0, 0, -30)
	pickHandle.Parent = npcModel
	
	local pickHead = Instance.new("WedgePart")
	pickHead.Name = "PickHead"
	pickHead.Size = Vector3.new(0.3, 0.5, 1.2)
	pickHead.Position = position + Vector3.new(2.9, 2, 0)
	pickHead.Anchored = true
	pickHead.BrickColor = BrickColor.new("Dark stone grey")
	pickHead.Material = Enum.Material.Metal
	pickHead.Rotation = Vector3.new(0, 0, -30)
	pickHead.Parent = npcModel
	
	-- Humanoid for name display
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = npcModel
	
	-- Name label
	local nameGui = Instance.new("BillboardGui")
	nameGui.Name = "NameGui"
	nameGui.Size = UDim2.new(0, 200, 0, 50)
	nameGui.StudsOffset = Vector3.new(0, 3.5, 0)
	nameGui.Adornee = head
	nameGui.Parent = head
	
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = name
	nameLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = nameGui
	
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, 0, 0.4, 0)
	titleLabel.Position = UDim2.new(0, 0, 0.5, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "📋 Quest Giver"
	titleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	titleLabel.TextStrokeTransparency = 0
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.Gotham
	titleLabel.Parent = nameGui
	
	-- Click detector for interaction
	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 15
	clickDetector.Parent = torso
	
	-- Question mark floating indicator
	local indicatorGui = Instance.new("BillboardGui")
	indicatorGui.Name = "QuestIndicator"
	indicatorGui.Size = UDim2.new(0, 60, 0, 60)
	indicatorGui.StudsOffset = Vector3.new(0, 5, 0)
	indicatorGui.Adornee = head
	indicatorGui.AlwaysOnTop = false; indicatorGui.MaxDistance = 30
	indicatorGui.Parent = head
	
	local indicator = Instance.new("TextLabel")
	indicator.Name = "Icon"
	indicator.Size = UDim2.new(1, 0, 1, 0)
	indicator.BackgroundTransparency = 1
	indicator.Text = "❗"
	indicator.TextScaled = true
	indicator.Font = Enum.Font.GothamBold
	indicator.Parent = indicatorGui
	
	-- Place in workspace
	local npcFolder = workspace:FindFirstChild("NPCs")
	if not npcFolder then
		npcFolder = Instance.new("Folder")
		npcFolder.Name = "NPCs"
		npcFolder.Parent = workspace
	end
	npcModel.Parent = npcFolder
	
	return npcModel, clickDetector
end

---------- QUEST STATE ----------

local function getPlayerState(player)
	if not playerQuests[player.UserId] then
		playerQuests[player.UserId] = {
			active = {},      -- { questId = progress }
			completed = {},   -- { questId = true }
		}
	end
	return playerQuests[player.UserId]
end

local function getAvailableQuests(player)
	local state = getPlayerState(player)
	local available = {}
	
	-- Get player prestige
	local prestige = 0
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local pv = ls:FindFirstChild("Prestige")
		if pv then prestige = pv.Value end
	end
	
	for _, quest in ipairs(QuestSystem.Quests) do
		if not state.completed[quest.Id] and not state.active[quest.Id] and prestige >= quest.MinPrestige then
			table.insert(available, quest)
		end
	end
	return available
end

local function getActiveQuests(player)
	local state = getPlayerState(player)
	local active = {}
	for _, quest in ipairs(QuestSystem.Quests) do
		if state.active[quest.Id] then
			table.insert(active, {
				Quest = quest,
				Progress = state.active[quest.Id],
			})
		end
	end
	return active
end

---------- QUEST ACTIONS ----------

local function acceptQuest(player, questId)
	local state = getPlayerState(player)
	if state.completed[questId] or state.active[questId] then return false end
	
	-- Max 3 active quests
	local activeCount = 0
	for _ in pairs(state.active) do activeCount = activeCount + 1 end
	if activeCount >= 3 then return false end
	
	state.active[questId] = 0
	
	-- Send update to client
	questRemote:FireClient(player, "QuestAccepted", questId)
	return true
end

local function checkQuestProgress(player, questType, target, amount)
	local state = getPlayerState(player)
	
	for _, quest in ipairs(QuestSystem.Quests) do
		if state.active[quest.Id] ~= nil then
			if quest.Type == questType then
				local matches = false
				if quest.Target == nil then
					matches = true
				elseif quest.Target == target then
					matches = true
				end
				
				if matches then
					state.active[quest.Id] = (state.active[quest.Id] or 0) + (amount or 1)
					
					-- Check completion
					if state.active[quest.Id] >= quest.Amount then
						-- Complete!
						state.active[quest.Id] = nil
						state.completed[quest.Id] = true
						
						-- Give rewards
						local ls = player:FindFirstChild("leaderstats")
						if ls and quest.Reward.Cash then
							local coins = ls:FindFirstChild("Coins")
							if coins then
								coins.Value = coins.Value + quest.Reward.Cash
							end
						end
						
						-- Notify client
						questRemote:FireClient(player, "QuestCompleted", quest.Id, quest.Name, quest.Reward)
					else
						-- Progress update
						questRemote:FireClient(player, "QuestProgress", quest.Id, state.active[quest.Id], quest.Amount)
					end
				end
			end
		end
	end
end

---------- REMOTE HANDLERS ----------

questFunction.OnServerInvoke = function(player, action, ...)
	local args = {...}
	
	if action == "GetAvailable" then
		return getAvailableQuests(player)
	elseif action == "GetActive" then
		return getActiveQuests(player)
	elseif action == "Accept" then
		local questId = args[1]
		return acceptQuest(player, questId)
	end
	
	return nil
end

---------- HOOK INTO MINING EVENTS ----------

-- Listen for ore mined events (fired by MineHandler)
local oreMinedEvent = ReplicatedStorage:FindFirstChild("OreMined")
if not oreMinedEvent then
	oreMinedEvent = Instance.new("BindableEvent")
	oreMinedEvent.Name = "OreMined"
	oreMinedEvent.Parent = ReplicatedStorage
end

oreMinedEvent.Event:Connect(function(player, oreName, amount)
	checkQuestProgress(player, "Mine", oreName, amount or 1)
end

)

-- Listen for sell events
local oreSoldEvent = ReplicatedStorage:FindFirstChild("OreSold")
if not oreSoldEvent then
	oreSoldEvent = Instance.new("BindableEvent")
	oreSoldEvent.Name = "OreSold"
	oreSoldEvent.Parent = ReplicatedStorage
end

oreSoldEvent.Event:Connect(function(player, totalValue)
	checkQuestProgress(player, "Sell", nil, totalValue)
end)

-- Listen for depth changes
local depthReachedEvent = ReplicatedStorage:FindFirstChild("DepthReached")
if not depthReachedEvent then
	depthReachedEvent = Instance.new("BindableEvent")
	depthReachedEvent.Name = "DepthReached"
	depthReachedEvent.Parent = ReplicatedStorage
end

depthReachedEvent.Event:Connect(function(player, depth)
	checkQuestProgress(player, "Depth", nil, depth)
end)

-- Listen for prestige
local prestigeEvent = ReplicatedStorage:FindFirstChild("PlayerPrestiged")
if not prestigeEvent then
	prestigeEvent = Instance.new("BindableEvent")
	prestigeEvent.Name = "PlayerPrestiged"
	prestigeEvent.Parent = ReplicatedStorage
end

prestigeEvent.Event:Connect(function(player, newPrestige)
	checkQuestProgress(player, "Prestige", nil, newPrestige)
end)

---------- CLEANUP ----------

Players.PlayerRemoving:Connect(function(player)
	-- Could save to DataStore here, keeping in-memory for now
	playerQuests[player.UserId] = nil
end)

---------- SPAWN NPC ----------

-- Place Miner Mike near the hub
local mikePosition = Vector3.new(90, 14.5, -20) -- Near mine entrance area
local mikeModel, mikeClick = createNPC("Miner Mike", mikePosition)

mikeClick.MouseClick:Connect(function(player)
	questRemote:FireClient(player, "OpenDialog", "Miner Mike")
end)

print("[QuestManager] Quest system loaded with", #QuestSystem.Quests, "quests")
print("[QuestManager] Miner Mike spawned at", mikePosition)
