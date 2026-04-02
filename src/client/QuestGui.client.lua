-- QuestGui.client.lua
-- Quest dialog + tracker UI. Opens when clicking NPC. Shows active quests on screen.
-- Works on all platforms (mobile touch, PC click, console)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local questRemote = ReplicatedStorage:WaitForChild("QuestRemote")
local questFunction = ReplicatedStorage:WaitForChild("QuestFunction")
local NotifyEvent = ReplicatedStorage:WaitForChild("Notify")

------------------------------------------------------------------------
-- QUEST DIALOG GUI
------------------------------------------------------------------------
local dialogGui = Instance.new("ScreenGui")
dialogGui.Name = "QuestDialog"
dialogGui.ResetOnSpawn = false
dialogGui.Enabled = false
dialogGui.Parent = playerGui

local dialogBG = Instance.new("Frame")
dialogBG.Size = UDim2.new(0, 380, 0, 450)
dialogBG.Position = UDim2.new(0.5, -190, 0.5, -225)
dialogBG.BackgroundColor3 = Color3.fromRGB(20, 18, 30)
dialogBG.BorderSizePixel = 0
dialogBG.Parent = dialogGui
Instance.new("UICorner", dialogBG).CornerRadius = UDim.new(0, 14)
local bgStroke = Instance.new("UIStroke")
bgStroke.Color = Color3.fromRGB(255, 200, 50)
bgStroke.Thickness = 2
bgStroke.Parent = dialogBG

-- NPC name
local npcTitle = Instance.new("TextLabel")
npcTitle.Size = UDim2.new(1, 0, 0, 45)
npcTitle.BackgroundColor3 = Color3.fromRGB(90, 70, 50)
npcTitle.Text = "Miner Mike"
npcTitle.TextColor3 = Color3.fromRGB(255, 200, 50)
npcTitle.TextScaled = true
npcTitle.Font = Enum.Font.GothamBold
npcTitle.BorderSizePixel = 0
npcTitle.Parent = dialogBG
local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 14)
titleCorner.Parent = npcTitle

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.Position = UDim2.new(1, -40, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = dialogBG
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
closeBtn.MouseButton1Click:Connect(function()
	dialogGui.Enabled = false
end)

-- NPC speech bubble
local speechBubble = Instance.new("TextLabel")
speechBubble.Size = UDim2.new(1, -20, 0, 50)
speechBubble.Position = UDim2.new(0, 10, 0, 50)
speechBubble.BackgroundColor3 = Color3.fromRGB(35, 32, 50)
speechBubble.Text = "\"Howdy, miner! Got some work for ya!\""
speechBubble.TextColor3 = Color3.fromRGB(220, 220, 220)
speechBubble.TextScaled = true
speechBubble.Font = Enum.Font.Gotham
speechBubble.TextWrapped = true
speechBubble.BorderSizePixel = 0
speechBubble.Parent = dialogBG
Instance.new("UICorner", speechBubble).CornerRadius = UDim.new(0, 8)

-- Quest scroll list
local questScroll = Instance.new("ScrollingFrame")
questScroll.Size = UDim2.new(1, -20, 1, -115)
questScroll.Position = UDim2.new(0, 10, 0, 105)
questScroll.BackgroundTransparency = 1
questScroll.ScrollBarThickness = 5
questScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 200, 50)
questScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
questScroll.Parent = dialogBG

local questLayout = Instance.new("UIListLayout")
questLayout.SortOrder = Enum.SortOrder.LayoutOrder
questLayout.Padding = UDim.new(0, 6)
questLayout.Parent = questScroll
questLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	questScroll.CanvasSize = UDim2.new(0, 0, 0, questLayout.AbsoluteContentSize.Y + 10)
end)

------------------------------------------------------------------------
-- QUEST TRACKER (always visible, top right)
------------------------------------------------------------------------
local trackerGui = Instance.new("ScreenGui")
trackerGui.Name = "QuestTracker"
trackerGui.ResetOnSpawn = false
trackerGui.Parent = playerGui

local trackerFrame = Instance.new("Frame")
trackerFrame.Size = UDim2.new(0, 165, 0, 140)
trackerFrame.Position = UDim2.new(1, -172, 0, 55)
trackerFrame.BackgroundColor3 = Color3.fromRGB(15, 13, 25)
trackerFrame.BackgroundTransparency = 0.3
trackerFrame.BorderSizePixel = 0
trackerFrame.Parent = trackerGui
Instance.new("UICorner", trackerFrame).CornerRadius = UDim.new(0, 10)

local trackerTitle = Instance.new("TextLabel")
trackerTitle.Size = UDim2.new(1, 0, 0, 30)
trackerTitle.BackgroundTransparency = 1
trackerTitle.Text = "📋 Quests"
trackerTitle.TextColor3 = Color3.fromRGB(255, 200, 50)
trackerTitle.TextScaled = true
trackerTitle.Font = Enum.Font.GothamBold
trackerTitle.Parent = trackerFrame

local trackerList = Instance.new("Frame")
trackerList.Size = UDim2.new(1, -10, 1, -35)
trackerList.Position = UDim2.new(0, 5, 0, 32)
trackerList.BackgroundTransparency = 1
trackerList.Parent = trackerFrame

local trackerLayout = Instance.new("UIListLayout")
trackerLayout.SortOrder = Enum.SortOrder.LayoutOrder
trackerLayout.Padding = UDim.new(0, 4)
trackerLayout.Parent = trackerList

------------------------------------------------------------------------
-- FUNCTIONS
------------------------------------------------------------------------
local function clearDialogQuests()
	for _, c in ipairs(questScroll:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
end

local function clearTracker()
	for _, c in ipairs(trackerList:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
end

local function formatReward(reward)
	if reward.Cash then return "$" .. tostring(reward.Cash) end
	return "???"
end

local function refreshDialog()
	clearDialogQuests()

	-- Get active quests
	local active = questFunction:InvokeServer("GetActive")
	if active and #active > 0 then
		for i, aq in ipairs(active) do
			local card = Instance.new("Frame")
			card.Size = UDim2.new(1, 0, 0, 65)
			card.BackgroundColor3 = Color3.fromRGB(30, 50, 30)
			card.BorderSizePixel = 0
			card.LayoutOrder = i
			card.Parent = questScroll
			Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

			local nm = Instance.new("TextLabel")
			nm.Size = UDim2.new(0.7, 0, 0, 22)
			nm.Position = UDim2.new(0, 8, 0, 4)
			nm.BackgroundTransparency = 1
			nm.Text = "✅ " .. aq.Quest.Name
			nm.TextColor3 = Color3.fromRGB(100, 255, 100)
			nm.TextScaled = true
			nm.Font = Enum.Font.GothamBold
			nm.TextXAlignment = Enum.TextXAlignment.Left
			nm.Parent = card

			local prog = Instance.new("TextLabel")
			prog.Size = UDim2.new(1, -16, 0, 18)
			prog.Position = UDim2.new(0, 8, 0, 26)
			prog.BackgroundTransparency = 1
			prog.Text = aq.Quest.Description .. " (" .. aq.Progress .. "/" .. aq.Quest.Amount .. ")"
			prog.TextColor3 = Color3.fromRGB(180, 180, 180)
			prog.TextScaled = true
			prog.Font = Enum.Font.Gotham
			prog.TextXAlignment = Enum.TextXAlignment.Left
			prog.Parent = card

			local rew = Instance.new("TextLabel")
			rew.Size = UDim2.new(1, -16, 0, 16)
			rew.Position = UDim2.new(0, 8, 0, 45)
			rew.BackgroundTransparency = 1
			rew.Text = "Reward: " .. formatReward(aq.Quest.Reward)
			rew.TextColor3 = Color3.fromRGB(255, 215, 0)
			rew.TextScaled = true
			rew.Font = Enum.Font.Gotham
			rew.TextXAlignment = Enum.TextXAlignment.Left
			rew.Parent = card
		end
	end

	-- Get available quests
	local available = questFunction:InvokeServer("GetAvailable")
	if available then
		for i, quest in ipairs(available) do
			local card = Instance.new("Frame")
			card.Size = UDim2.new(1, 0, 0, 75)
			card.BackgroundColor3 = Color3.fromRGB(30, 28, 45)
			card.BorderSizePixel = 0
			card.LayoutOrder = 100 + i
			card.Parent = questScroll
			Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

			local nm = Instance.new("TextLabel")
			nm.Size = UDim2.new(0.65, 0, 0, 22)
			nm.Position = UDim2.new(0, 8, 0, 4)
			nm.BackgroundTransparency = 1
			nm.Text = quest.Name
			nm.TextColor3 = Color3.new(1,1,1)
			nm.TextScaled = true
			nm.Font = Enum.Font.GothamBold
			nm.TextXAlignment = Enum.TextXAlignment.Left
			nm.Parent = card

			local desc = Instance.new("TextLabel")
			desc.Size = UDim2.new(1, -16, 0, 18)
			desc.Position = UDim2.new(0, 8, 0, 26)
			desc.BackgroundTransparency = 1
			desc.Text = quest.Description
			desc.TextColor3 = Color3.fromRGB(170, 170, 180)
			desc.TextScaled = true
			desc.Font = Enum.Font.Gotham
			desc.TextXAlignment = Enum.TextXAlignment.Left
			desc.Parent = card

			local rew = Instance.new("TextLabel")
			rew.Size = UDim2.new(0.5, 0, 0, 16)
			rew.Position = UDim2.new(0, 8, 0, 45)
			rew.BackgroundTransparency = 1
			rew.Text = "💰 " .. formatReward(quest.Reward)
			rew.TextColor3 = Color3.fromRGB(255, 215, 0)
			rew.TextScaled = true
			rew.Font = Enum.Font.Gotham
			rew.TextXAlignment = Enum.TextXAlignment.Left
			rew.Parent = card

			local acceptBtn = Instance.new("TextButton")
			acceptBtn.Size = UDim2.new(0, 80, 0, 30)
			acceptBtn.Position = UDim2.new(1, -88, 0, 38)
			acceptBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
			acceptBtn.Text = "Accept"
			acceptBtn.TextColor3 = Color3.new(1,1,1)
			acceptBtn.TextScaled = true
			acceptBtn.Font = Enum.Font.GothamBold
			acceptBtn.BorderSizePixel = 0
			acceptBtn.Parent = card
			Instance.new("UICorner", acceptBtn).CornerRadius = UDim.new(0, 6)

			acceptBtn.MouseButton1Click:Connect(function()
				local success = questFunction:InvokeServer("Accept", quest.Id)
				if success then
					refreshDialog()
					refreshTracker()
				end
			end)
		end
	end
end

local function refreshTracker()
	clearTracker()
	local active = questFunction:InvokeServer("GetActive")
	if not active or #active == 0 then
		trackerFrame.Visible = false
		return
	end
	trackerFrame.Visible = true

	for i, aq in ipairs(active) do
		local item = Instance.new("Frame")
		item.Size = UDim2.new(1, 0, 0, 45)
		item.BackgroundTransparency = 1
		item.LayoutOrder = i
		item.Parent = trackerList

		local nm = Instance.new("TextLabel")
		nm.Size = UDim2.new(1, 0, 0, 20)
		nm.BackgroundTransparency = 1
		nm.Text = aq.Quest.Name
		nm.TextColor3 = Color3.new(1,1,1)
		nm.TextScaled = true
		nm.Font = Enum.Font.GothamBold
		nm.TextXAlignment = Enum.TextXAlignment.Left
		nm.Parent = item

		local prog = Instance.new("TextLabel")
		prog.Size = UDim2.new(1, 0, 0, 16)
		prog.Position = UDim2.new(0, 0, 0, 20)
		prog.BackgroundTransparency = 1
		prog.Text = aq.Progress .. " / " .. aq.Quest.Amount
		prog.TextColor3 = Color3.fromRGB(150, 255, 150)
		prog.TextScaled = true
		prog.Font = Enum.Font.Gotham
		prog.TextXAlignment = Enum.TextXAlignment.Left
		prog.Parent = item

		-- Progress bar
		local barBG = Instance.new("Frame")
		barBG.Size = UDim2.new(1, 0, 0, 6)
		barBG.Position = UDim2.new(0, 0, 0, 38)
		barBG.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		barBG.BorderSizePixel = 0
		barBG.Parent = item
		Instance.new("UICorner", barBG).CornerRadius = UDim.new(1, 0)

		local barFill = Instance.new("Frame")
		local pct = math.clamp(aq.Progress / aq.Quest.Amount, 0, 1)
		barFill.Size = UDim2.new(pct, 0, 1, 0)
		barFill.BackgroundColor3 = Color3.fromRGB(0, 200, 80)
		barFill.BorderSizePixel = 0
		barFill.Parent = barBG
		Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)
	end
end

------------------------------------------------------------------------
-- EVENT HANDLERS
------------------------------------------------------------------------
questRemote.OnClientEvent:Connect(function(action, ...)
	local args = {...}
	if action == "OpenDialog" then
		refreshDialog()
		dialogGui.Enabled = true
	elseif action == "QuestAccepted" then
		refreshTracker()
	elseif action == "QuestProgress" then
		refreshTracker()
	elseif action == "QuestCompleted" then
		local questName = args[2]
		local reward = args[3]
		NotifyEvent.OnClientEvent:Wait() -- skip, use direct notification
		refreshTracker()
		refreshDialog()
	end
end)

-- Initial tracker load
task.defer(function()
	task.wait(3)
	refreshTracker()
end)

print("[RiftMiners] Quest GUI loaded! 📋")
