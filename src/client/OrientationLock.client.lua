-- OrientationLock.client.lua
-- Forces landscape by showing a blocking overlay when device is in portrait mode
-- Works on mobile (iOS/Android). No effect on PC/console.

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create blocking overlay
local orientGui = Instance.new("ScreenGui")
orientGui.Name = "OrientationLock"
orientGui.ResetOnSpawn = false
orientGui.DisplayOrder = 100 -- on top of everything
orientGui.IgnoreGuiInset = true
orientGui.Parent = playerGui

local overlay = Instance.new("Frame")
overlay.Name = "PortraitOverlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(10, 8, 20)
overlay.BackgroundTransparency = 0
overlay.BorderSizePixel = 0
overlay.Visible = false
overlay.ZIndex = 100
overlay.Parent = orientGui

-- Rotate icon
local rotateIcon = Instance.new("TextLabel")
rotateIcon.Size = UDim2.new(0, 80, 0, 80)
rotateIcon.Position = UDim2.new(0.5, -40, 0.35, 0)
rotateIcon.BackgroundTransparency = 1
rotateIcon.Text = "📱"
rotateIcon.TextScaled = true
rotateIcon.ZIndex = 101
rotateIcon.Parent = overlay

-- Rotate arrow
local arrow = Instance.new("TextLabel")
arrow.Size = UDim2.new(0, 60, 0, 60)
arrow.Position = UDim2.new(0.5, -30, 0.48, 0)
arrow.BackgroundTransparency = 1
arrow.Text = "↻"
arrow.TextColor3 = Color3.fromRGB(138, 43, 226)
arrow.TextScaled = true
arrow.Font = Enum.Font.GothamBold
arrow.ZIndex = 101
arrow.Parent = overlay

-- Message
local msg = Instance.new("TextLabel")
msg.Size = UDim2.new(0.8, 0, 0, 50)
msg.Position = UDim2.new(0.1, 0, 0.58, 0)
msg.BackgroundTransparency = 1
msg.Text = "Please rotate your device to landscape mode"
msg.TextColor3 = Color3.new(1, 1, 1)
msg.TextScaled = true
msg.Font = Enum.Font.GothamBold
msg.TextWrapped = true
msg.ZIndex = 101
msg.Parent = overlay

-- Sub message
local subMsg = Instance.new("TextLabel")
subMsg.Size = UDim2.new(0.7, 0, 0, 30)
subMsg.Position = UDim2.new(0.15, 0, 0.65, 0)
subMsg.BackgroundTransparency = 1
subMsg.Text = "Rift Miners is best played in landscape"
subMsg.TextColor3 = Color3.fromRGB(150, 150, 170)
subMsg.TextScaled = true
subMsg.Font = Enum.Font.Gotham
subMsg.TextWrapped = true
subMsg.ZIndex = 101
subMsg.Parent = overlay

-- Game logo
local logo = Instance.new("TextLabel")
logo.Size = UDim2.new(0.6, 0, 0, 30)
logo.Position = UDim2.new(0.2, 0, 0.2, 0)
logo.BackgroundTransparency = 1
logo.Text = "⛏️ RIFT MINERS ⛏️"
logo.TextColor3 = Color3.fromRGB(138, 43, 226)
logo.TextScaled = true
logo.Font = Enum.Font.GothamBlack
logo.ZIndex = 101
logo.Parent = overlay

-- Check orientation
local camera = workspace.CurrentCamera

local function checkOrientation()
	local viewSize = camera.ViewportSize
	if viewSize.X < viewSize.Y then
		-- Portrait mode — block
		overlay.Visible = true
	else
		-- Landscape — allow play
		overlay.Visible = false
	end
end

camera:GetPropertyChangedSignal("ViewportSize"):Connect(checkOrientation)
task.defer(checkOrientation)

-- Also check periodically in case signal misses
task.spawn(function()
	while true do
		task.wait(1)
		checkOrientation()
	end
end)

print("[RiftMiners] Orientation lock loaded — landscape only 📱")
