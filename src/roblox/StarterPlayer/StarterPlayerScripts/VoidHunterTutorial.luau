-- VoidHunter Tutorial System
-- Guides new players through game mechanics
-- Place in StarterPlayerScripts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Tutorial configuration
local TUTORIAL_STEPS = {
	{
		title = "Welcome to VoidHunters!",
		text = "You are a space hunter, building and piloting custom ships to battle enemies and collect valuable debris.",
		duration = 5,
	},
	{
		title = "Your Ship",
		text = "Your ship is made of modular components. The Command Core (red) is essential - if it's destroyed, your ship is lost!",
		duration = 5,
	},
	{
		title = "Building Ships",
		text = "Collect debris floating in space to unlock new components. Press E near a ship to enter it.",
		duration = 5,
	},
	{
		title = "Combat",
		text = "Use your weapons to destroy enemies! Different weapons have different effects - Mass Drivers are fast, Plasma penetrates, Missiles home in on targets.",
		duration = 5,
	},
	{
		title = "Energy & Shields",
		text = "Your ship has energy that regenerates over time. Weapons consume energy. Shield Generators protect you but drain energy.",
		duration = 5,
	},
	{
		title = "Radar",
		text = "The radar in the corner shows nearby enemies (red), asteroids (gray), and other objects. Stay alert!",
		duration = 4,
	},
	{
		title = "Good Luck, Hunter!",
		text = "Destroy enemies, collect debris, and build the ultimate ship. Press SPACE to close this tutorial.",
		duration = 0, -- Wait for input
	},
}

-- State
local tutorialActive = false
local currentStep = 1
local tutorialGui = nil
local tutorialFrame = nil
local titleText = nil
local bodyText = nil
local skipButton = nil

-- Create tutorial GUI
local function createTutorialGui()
	-- Create ScreenGui
	tutorialGui = Instance.new("ScreenGui")
	tutorialGui.Name = "TutorialGui"
	tutorialGui.ResetOnSpawn = false
	tutorialGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	tutorialGui.Parent = playerGui
	
	-- Background frame
	tutorialFrame = Instance.new("Frame")
	tutorialFrame.Name = "TutorialFrame"
	tutorialFrame.Size = UDim2.new(0.6, 0, 0, 150)
	tutorialFrame.Position = UDim2.new(0.2, 0, 0.8, -160)
	tutorialFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	tutorialFrame.BorderSizePixel = 0
	tutorialFrame.BackgroundTransparency = 0.2
	tutorialFrame.Parent = tutorialGui
	
	-- Corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = tutorialFrame
	
	-- Stroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(100, 150, 255)
	stroke.Thickness = 2
	stroke.Parent = tutorialFrame
	
	-- Title
	titleText = Instance.new("TextLabel")
	titleText.Name = "Title"
	titleText.Size = UDim2.new(1, -40, 0, 40)
	titleText.Position = UDim2.new(0, 20, 0, 10)
	titleText.BackgroundTransparency = 1
	titleText.TextColor3 = Color3.fromRGB(100, 200, 255)
	titleText.TextSize = 28
	titleText.Font = Enum.Font.GothamBold
	titleText.TextXAlignment = Enum.TextXAlignment.Left
	titleText.Text = ""
	titleText.Parent = tutorialFrame
	
	-- Body text
	bodyText = Instance.new("TextLabel")
	bodyText.Name = "Body"
	bodyText.Size = UDim2.new(1, -40, 0, 80)
	bodyText.Position = UDim2.new(0, 20, 0, 50)
	bodyText.BackgroundTransparency = 1
	bodyText.TextColor3 = Color3.fromRGB(255, 255, 255)
	bodyText.TextSize = 18
	bodyText.Font = Enum.Font.Gotham
	bodyText.TextXAlignment = Enum.TextXAlignment.Left
	bodyText.TextYAlignment = Enum.TextYAlignment.Top
	bodyText.TextWrapped = true
	bodyText.Text = ""
	bodyText.Parent = tutorialFrame
	
	-- Skip button
	skipButton = Instance.new("TextButton")
	skipButton.Name = "SkipButton"
	skipButton.Size = UDim2.new(0, 100, 0, 30)
	skipButton.Position = UDim2.new(1, -120, 1, -40)
	skipButton.BackgroundColor3 = Color3.fromRGB(60, 100, 180)
	skipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	skipButton.Text = "Skip"
	skipButton.Font = Enum.Font.GothamBold
	skipButton.TextSize = 14
	skipButton.Parent = tutorialFrame
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = skipButton
	
	-- Connect skip button click
	skipButton.MouseButton1Click:Connect(function()
		if tutorialActive then
			endTutorial()
		end
	end)
	
	-- Progress indicator
	local progressFrame = Instance.new("Frame")
	progressFrame.Name = "ProgressFrame"
	progressFrame.Size = UDim2.new(1, -40, 0, 4)
	progressFrame.Position = UDim2.new(0, 20, 1, -10)
	progressFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	progressFrame.Parent = tutorialFrame
	
	local progressCorner = Instance.new("UICorner")
	progressCorner.CornerRadius = UDim.new(0, 2)
	progressCorner.Parent = progressFrame
	
	local progressBar = Instance.new("Frame")
	progressBar.Name = "ProgressBar"
	progressBar.Size = UDim2.new(0, 0, 1, 0)
	progressBar.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
	progressBar.Parent = progressFrame
	
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 2)
	barCorner.Parent = progressBar
	
	return tutorialGui
end

-- Update progress bar
local function updateProgress()
	if not tutorialFrame then return end
	
	local progress = tutorialFrame:FindFirstChild("ProgressFrame", true)
	if progress then
		local bar = progress:FindFirstChild("ProgressBar")
		if bar then
			local percent = currentStep / #TUTORIAL_STEPS
			bar.Size = UDim2.new(percent, 0, 1, 0)
		end
	end
end

-- Show a tutorial step
local function showStep(stepIndex)
	if stepIndex > #TUTORIAL_STEPS then
		-- Tutorial complete
		endTutorial()
		return
	end
	
	currentStep = stepIndex
	local step = TUTORIAL_STEPS[stepIndex]
	
	-- Update text
	titleText.Text = step.title
	bodyText.Text = step.text
	
	-- Update progress
	updateProgress()
	
	-- Animate in
	tutorialFrame.BackgroundTransparency = 1
	tutorialFrame.Position = UDim2.new(0.2, 0, 0.85, -160)
	
	TweenService:Create(tutorialFrame, TweenInfo.new(0.3), {
		BackgroundTransparency = 0.2,
		Position = UDim2.new(0.2, 0, 0.8, -160)
	}):Play()
	
	-- Auto-advance if duration set
	if step.duration > 0 then
		task.delay(step.duration, function()
			if tutorialActive then
				showStep(currentStep + 1)
			end
		end)
	end
end

-- Start tutorial
local function startTutorial()
	if tutorialActive then return end
	
	-- Check if player has seen tutorial before
	local hasSeenTutorial = player:GetAttribute("HasSeenTutorial")
	if hasSeenTutorial then
		return
	end
	
	tutorialActive = true
	createTutorialGui()
	showStep(1)
	
	print("[Tutorial] Started")
end

-- End tutorial
function endTutorial()
	if not tutorialActive then return end
	
	tutorialActive = false
	
	-- Animate out
	if tutorialFrame then
		TweenService:Create(tutorialFrame, TweenInfo.new(0.3), {
			BackgroundTransparency = 1,
			Position = UDim2.new(0.2, 0, 0.85, -160)
		}):Play()
		
		task.wait(0.3)
	end
	
	if tutorialGui then
		tutorialGui:Destroy()
		tutorialGui = nil
	end
	
	-- Mark as seen
	player:SetAttribute("HasSeenTutorial", true)
	
	print("[Tutorial] Completed")
end

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.Space and tutorialActive then
		-- Advance to next step or close
		local step = TUTORIAL_STEPS[currentStep]
		if step.duration == 0 then
			-- This step waits for input
			showStep(currentStep + 1)
		end
	end
end)

-- Start tutorial after a short delay
task.delay(2, function()
	startTutorial()
end)

-- Expose endTutorial globally for skip button
_G.EndTutorial = endTutorial

print("[Tutorial] System loaded")
