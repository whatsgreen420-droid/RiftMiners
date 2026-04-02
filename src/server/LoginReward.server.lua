-- LoginReward.server.lua
-- Daily login reward system. Players get increasing rewards for consecutive days.
-- Shows notification on join. Works on all platforms.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local ServerFolder = game:GetService("ServerScriptService"):WaitForChild("Server")
local PlayerDataManager = require(ServerFolder:WaitForChild("PlayerDataManager"))
local NotifyEvent = ReplicatedStorage:WaitForChild("Notify")

local loginStore = DataStoreService:GetDataStore("RiftMiners_LoginRewards_v1")

local DAILY_REWARDS = {
	{ Day = 1, Cash = 100,    Label = "Day 1" },
	{ Day = 2, Cash = 250,    Label = "Day 2" },
	{ Day = 3, Cash = 500,    Label = "Day 3" },
	{ Day = 4, Cash = 1000,   Label = "Day 4" },
	{ Day = 5, Cash = 2500,   Label = "Day 5" },
	{ Day = 6, Cash = 5000,   Label = "Day 6" },
	{ Day = 7, Cash = 10000,  Label = "Day 7 — BONUS!" },
}

local COOLDOWN_SECONDS = 72000 -- 20 hours (allows some flexibility)

Players.PlayerAdded:Connect(function(player)
	task.wait(4) -- Let other systems load first

	local key = "Login_" .. player.UserId
	local success, data = pcall(function()
		return loginStore:GetAsync(key)
	end)

	local now = os.time()
	local loginData = (success and data) or { streak = 0, lastLogin = 0 }

	local timeSince = now - (loginData.lastLogin or 0)

	if timeSince >= COOLDOWN_SECONDS then
		-- Eligible for reward
		local newStreak = (loginData.streak or 0) + 1

		-- Reset streak if more than 48 hours (missed a day)
		if timeSince > 172800 then
			newStreak = 1
		end

		-- Wrap around after day 7
		local dayIndex = ((newStreak - 1) % 7) + 1
		local reward = DAILY_REWARDS[dayIndex]

		-- Give reward
		PlayerDataManager.AddCash(player, reward.Cash)

		-- Save
		pcall(function()
			loginStore:SetAsync(key, {
				streak = newStreak,
				lastLogin = now,
			})
		end)

		-- Notify
		task.wait(1)
		NotifyEvent:FireClient(player, {
			Title = "🎁 Daily Reward — " .. reward.Label,
			Message = "Streak: " .. newStreak .. " days! Earned $" .. tostring(reward.Cash),
			Duration = 5,
			Color = Color3.fromRGB(255, 200, 50),
		})
	else
		-- Already claimed today
		local hoursLeft = math.ceil((COOLDOWN_SECONDS - timeSince) / 3600)
		NotifyEvent:FireClient(player, {
			Title = "🕐 Daily Reward",
			Message = "Come back in ~" .. hoursLeft .. " hours for your next reward!",
			Duration = 3,
			Color = Color3.fromRGB(150, 150, 200),
		})
	end
end)

print("[RiftMiners] Login reward system loaded! 🎁")
