-- PhoenixCoreHUD LocalScript
-- Client-side HUD: health, shield, wave counter, score, status messages

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PhoenixCoreHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local function makeBar(name, pos, fillColor)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = UDim2.new(0, 220, 0, 22)
	frame.Position = pos
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	frame.BorderSizePixel = 1
	frame.BorderColor3 = Color3.fromRGB(80, 80, 120)
	frame.Parent = screenGui
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = fillColor
	fill.BorderSizePixel = 0
	fill.Parent = frame
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = 12
	label.Font = Enum.Font.GothamBold
	label.Text = ""
	label.Parent = frame
	return frame, fill, label
end

local healthFrame, healthFill, healthLabel = makeBar("HealthBar", UDim2.new(0.01, 0, 0.02, 0), Color3.fromRGB(0, 220, 80))
local shieldFrame, shieldFill, shieldLabel = makeBar("ShieldBar", UDim2.new(0.01, 0, 0.065, 0), Color3.fromRGB(0, 160, 255))

local waveLabel = Instance.new("TextLabel")
waveLabel.Name = "WaveCounter"
waveLabel.Size = UDim2.new(0, 260, 0, 34)
waveLabel.Position = UDim2.new(0.5, -130, 0.015, 0)
waveLabel.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
waveLabel.BackgroundTransparency = 0.2
waveLabel.BorderSizePixel = 1
waveLabel.BorderColor3 = Color3.fromRGB(255, 220, 50)
waveLabel.TextColor3 = Color3.fromRGB(255, 220, 50)
waveLabel.TextSize = 15
waveLabel.Font = Enum.Font.GothamBold
waveLabel.Text = "Waiting for wave..."
waveLabel.Parent = screenGui

local scoreLabel = Instance.new("TextLabel")
scoreLabel.Name = "Score"
scoreLabel.Size = UDim2.new(0, 160, 0, 34)
scoreLabel.Position = UDim2.new(1, -170, 0.015, 0)
scoreLabel.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
scoreLabel.BackgroundTransparency = 0.2
scoreLabel.BorderSizePixel = 1
scoreLabel.BorderColor3 = Color3.fromRGB(255, 140, 0)
scoreLabel.TextColor3 = Color3.fromRGB(255, 140, 0)
scoreLabel.TextSize = 15
scoreLabel.Font = Enum.Font.GothamBold
scoreLabel.Text = "Score: 0"
scoreLabel.Parent = screenGui

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusMessage"
statusLabel.Size = UDim2.new(0, 450, 0, 60)
statusLabel.Position = UDim2.new(0.5, -225, 0.42, 0)
statusLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
statusLabel.BackgroundTransparency = 0.35
statusLabel.BorderSizePixel = 0
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
statusLabel.TextSize = 26
statusLabel.Font = Enum.Font.GothamBold
statusLabel.Text = ""
statusLabel.Visible = false
statusLabel.Parent = screenGui

local score = 0

local function setBar(fill, label, current, max, suffix)
	local ratio = math.clamp(current / math.max(max, 1), 0, 1)
	TweenService:Create(fill, TweenInfo.new(0.2), {Size = UDim2.new(ratio, 0, 1, 0)}):Play()
	label.Text = current .. "/" .. max .. " " .. suffix
end

local function showStatus(msg, duration)
	statusLabel.Text = msg
	statusLabel.Visible = true
	statusLabel.TextTransparency = 0
	task.delay(duration or 3, function()
		TweenService:Create(statusLabel, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
		task.wait(0.5)
		statusLabel.Visible = false
		statusLabel.TextTransparency = 0
	end)
end

local hudEvents = ReplicatedStorage:WaitForChild("PhoenixCoreHUDEvents", 15)
if hudEvents then
	local evHealth = hudEvents:WaitForChild("UpdateHealth", 5)
	local evShield = hudEvents:WaitForChild("UpdateShield", 5)
	local evWave = hudEvents:WaitForChild("UpdateWave", 5)
	local evKill = hudEvents:WaitForChild("AddKill", 5)
	local evStatus = hudEvents:WaitForChild("ShowStatus", 5)

	if evHealth then
		evHealth.OnClientEvent:Connect(function(hp, maxHp)
			setBar(healthFill, healthLabel, hp, maxHp, "HP")
			local ratio = hp / math.max(maxHp, 1)
			healthFill.BackgroundColor3 = Color3.fromRGB(math.floor(255*(1-ratio)), math.floor(220*ratio), 0)
		end)
	end
	if evShield then
		evShield.OnClientEvent:Connect(function(sh, maxSh)
			setBar(shieldFill, shieldLabel, sh, maxSh, "SH")
		end)
	end
	if evWave then
		evWave.OnClientEvent:Connect(function(current, total, enemies)
			waveLabel.Text = "Wave " .. current .. "/" .. total .. " | Enemies: " .. enemies
		end)
	end
	if evKill then
		evKill.OnClientEvent:Connect(function(points)
			score = score + points
			scoreLabel.Text = "Score: " .. score
		end)
	end
	if evStatus then
		evStatus.OnClientEvent:Connect(function(msg, duration)
			showStatus(msg, duration)
		end)
	end
end

healthLabel.Text = "100/100 HP"
shieldLabel.Text = "50/50 SH"
