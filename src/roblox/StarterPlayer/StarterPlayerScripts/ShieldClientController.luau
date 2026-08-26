-- Shield Generator Client Controller
-- Handles proximity prompt interaction and shield toggle

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Get remote event
local comms = ReplicatedStorage:WaitForChild("Communication")
local shieldAction = comms:WaitForChild("ShieldAction")

-- Track shield state
local shieldActive = false
local currentShieldModel = nil

-- Create shield status UI
local function createShieldUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ShieldStatusUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	
	-- Main frame
	local frame = Instance.new("Frame")
	frame.Name = "ShieldFrame"
	frame.Size = UDim2.new(0, 200, 0, 80)
	frame.Position = UDim2.new(0.5, -100, 0.9, -90)
	frame.BackgroundColor3 = Color3.fromRGB(20, 30, 40)
	frame.BackgroundTransparency = 0.3
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = screenGui
	
	-- Corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 25)
	title.Position = UDim2.new(0, 0, 0, 5)
	title.BackgroundTransparency = 1
	title.Text = "SHIELD GENERATOR"
	title.TextColor3 = Color3.fromRGB(100, 200, 255)
	title.TextSize = 14
	title.Font = Enum.Font.GothamBold
	title.Parent = frame
	
	-- Energy bar background
	local energyBg = Instance.new("Frame")
	energyBg.Name = "EnergyBg"
	energyBg.Size = UDim2.new(0.9, 0, 0, 20)
	energyBg.Position = UDim2.new(0.05, 0, 0, 35)
	energyBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	energyBg.Parent = frame
	
	local energyCorner = Instance.new("UICorner")
	energyCorner.CornerRadius = UDim.new(0, 4)
	energyCorner.Parent = energyBg
	
	-- Energy bar fill
	local energyFill = Instance.new("Frame")
	energyFill.Name = "EnergyFill"
	energyFill.Size = UDim2.new(1, 0, 1, 0)
	energyFill.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
	energyFill.Parent = energyBg
	
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = energyFill
	
	-- Status text
	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Size = UDim2.new(1, 0, 0, 20)
	status.Position = UDim2.new(0, 0, 0, 58)
	status.BackgroundTransparency = 1
	status.Text = "Press E to activate"
	status.TextColor3 = Color3.fromRGB(200, 200, 200)
	status.TextSize = 12
	status.Font = Enum.Font.Gotham
	status.Parent = frame
	
	return screenGui, frame, energyFill, status
end

local shieldUI, shieldFrame, energyBar, statusText = createShieldUI()

-- Update UI based on shield state
local function updateUI(energy, maxEnergy, isActive)
	local energyPercent = energy / maxEnergy
	
	energyBar.Size = UDim2.new(energyPercent, 0, 1, 0)
	
	if isActive then
		energyBar.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
		statusText.Text = "SHIELD ACTIVE"
		statusText.TextColor3 = Color3.fromRGB(100, 255, 150)
	else
		if energyPercent < 0.2 then
			energyBar.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
			statusText.Text = "LOW ENERGY"
		elseif energyPercent < 0.5 then
			energyBar.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
			statusText.Text = "RECHARGING..."
		else
			energyBar.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
			statusText.Text = "Press E to activate"
		end
		statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
	end
end

-- Handle proximity prompt triggers
local function setupProximityPrompt(prompt, shieldModel)
	prompt.Triggered:Connect(function()
		if not currentShieldModel then return end
		
		-- Toggle shield
		if shieldActive then
			shieldAction:FireServer("deactivate", shieldModel)
			shieldActive = false
		else
			shieldAction:FireServer("activate", shieldModel)
			shieldActive = true
		end
	end)
end

-- Monitor for proximity prompts
local function findAndSetupPrompts()
	for _, descendant in ipairs(workspace:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") and descendant.Name == "ShieldPrompt" then
			local parent = descendant.Parent
			if parent then
				local model = parent:FindFirstAncestorOfClass("Model")
				if model then
					setupProximityPrompt(descendant, model)
				end
			end
		end
	end
end

-- Initial setup
findAndSetupPrompts()

-- Monitor for new prompts
workspace.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("ProximityPrompt") and descendant.Name == "ShieldPrompt" then
		task.wait(0.1)
		local parent = descendant.Parent
		if parent then
			local model = parent:FindFirstAncestorOfClass("Model")
			if model then
				setupProximityPrompt(descendant, model)
			end
		end
	end
end)

-- Update loop for UI
local function updateLoop()
	while task.wait(0.1) do
		if currentShieldModel and shieldFrame.Visible then
			local body = currentShieldModel:FindFirstChild("world")
			if body then body = body:FindFirstChild("body") end
			if body then
				local bubble = body:FindFirstChild("ShieldBubble")
				if bubble then
					local energy = bubble:GetAttribute("ShieldEnergy") or 0
					local maxEnergy = bubble:GetAttribute("MaxEnergy") or 100
					local active = bubble:GetAttribute("ShieldActive") or false
					updateUI(energy, maxEnergy, active)
				end
			end
		end
	end
end

task.spawn(updateLoop)

-- Show/hide UI based on proximity
local function checkProximity()
	local character = player.Character
	if not character then return end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	local nearestShield = nil
	local nearestDist = 20
	
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj.Name == "ShieldGenerator" then
			local body = obj:FindFirstChild("world")
			if body then body = body:FindFirstChild("body") end
			if body then
				local meshPart = body:FindFirstChild("body_geom")
				if meshPart then
					local dist = (meshPart.Position - humanoidRootPart.Position).Magnitude
					if dist < nearestDist then
						nearestDist = dist
						nearestShield = obj
					end
				end
			end
		end
	end
	
	if nearestShield then
		currentShieldModel = nearestShield
		shieldFrame.Visible = true
	else
		currentShieldModel = nil
		shieldFrame.Visible = false
	end
end

-- Run proximity check periodically
task.spawn(function()
	while task.wait(0.5) do
		checkProximity()
	end
end)

print("Shield client controller loaded")
