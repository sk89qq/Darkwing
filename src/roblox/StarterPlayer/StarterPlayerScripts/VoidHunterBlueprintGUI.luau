-- VoidHunter Blueprint GUI
-- Overlay for managing blueprints (left side aligned)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BlueprintGUI"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false -- Hidden by default
screenGui.Parent = playerGui

-- Main frame (left side)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 200, 0, 400)
mainFrame.Position = UDim2.new(0, 10, 0.5, -200)
mainFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
mainFrame.BackgroundTransparency = 0.3
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 40)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1

title.Text = "BLUEPRINTS"
title.TextColor3 = Color3.new(0, 0.8, 1)
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

-- Slot buttons container
local slotsContainer = Instance.new("Frame")
slotsContainer.Name = "SlotsContainer"
slotsContainer.Size = UDim2.new(1, -20, 0, 200)
slotsContainer.Position = UDim2.new(0, 10, 0, 50)
slotsContainer.BackgroundTransparency = 1
slotsContainer.Parent = mainFrame

local slotsLayout = Instance.new("UIListLayout")
slotsLayout.Padding = UDim.new(0, 8)
slotsLayout.Parent = slotsContainer

-- Create slot buttons
local slotButtons = {}
local unlockedSlots = 1 -- Default 1 slot

for i = 1, 3 do
	local slotFrame = Instance.new("Frame")
	slotFrame.Name = "Slot" .. i
	slotFrame.Size = UDim2.new(1, 0, 0, 50)
	slotFrame.BackgroundColor3 = Color3.new(0.15, 0.15, 0.2)
	slotFrame.BackgroundTransparency = 0.5
	slotFrame.BorderSizePixel = 0
	slotFrame.Parent = slotsContainer
	
	local slotCorner = Instance.new("UICorner")
	slotCorner.CornerRadius = UDim.new(0, 4)
	slotCorner.Parent = slotFrame
	
	local slotLabel = Instance.new("TextLabel")
	slotLabel.Size = UDim2.new(0.5, 0, 1, 0)
	slotLabel.Position = UDim2.new(0, 10, 0, 0)
	slotLabel.BackgroundTransparency = 1
	slotLabel.Text = "Slot " .. i
	slotLabel.TextColor3 = Color3.new(1, 1, 1)
	slotLabel.TextSize = 14
	slotLabel.Font = Enum.Font.Gotham
	slotLabel.TextXAlignment = Enum.TextXAlignment.Left
	slotLabel.Parent = slotFrame
	
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "Status"
	statusLabel.Size = UDim2.new(0.5, 0, 1, 0)
	statusLabel.Position = UDim2.new(0.5, 0, 0, 0)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = i <= unlockedSlots and "Empty" or "Locked"
	statusLabel.TextColor3 = i <= unlockedSlots and Color3.new(0.5, 0.5, 0.5) or Color3.new(0.3, 0.3, 0.3)
	statusLabel.TextSize = 12
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextXAlignment = Enum.TextXAlignment.Right
	statusLabel.Parent = slotFrame
	
	-- Lock overlay for locked slots
	if i > unlockedSlots then
		local lockOverlay = Instance.new("Frame")
		lockOverlay.Size = UDim2.new(1, 0, 1, 0)
		lockOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
		lockOverlay.BackgroundTransparency = 0.7
		lockOverlay.Parent = slotFrame
		
		local lockCorner = Instance.new("UICorner")
		lockCorner.CornerRadius = UDim.new(0, 4)
		lockCorner.Parent = lockOverlay
		
		local lockIcon = Instance.new("TextLabel")
		lockIcon.Size = UDim2.new(1, 0, 1, 0)
		lockIcon.BackgroundTransparency = 1
		lockIcon.Text = "🔒"
		lockIcon.TextSize = 20
		lockIcon.Parent = lockOverlay
	end
	
	slotButtons[i] = {
		frame = slotFrame,
		label = slotLabel,
		status = statusLabel,
		unlocked = i <= unlockedSlots
	}
end

-- Action buttons
local actionsContainer = Instance.new("Frame")
actionsContainer.Name = "ActionsContainer"
actionsContainer.Size = UDim2.new(1, -20, 0, 80)
actionsContainer.Position = UDim2.new(0, 10, 0, 270)
actionsContainer.BackgroundTransparency = 1
actionsContainer.Parent = mainFrame

local actionsLayout = Instance.new("UIListLayout")
actionsLayout.Padding = UDim.new(0, 8)
actionsLayout.Parent = actionsContainer

-- Save button
local saveButton = Instance.new("TextButton")
saveButton.Name = "SaveButton"
saveButton.Size = UDim2.new(1, 0, 0, 35)
saveButton.BackgroundColor3 = Color3.new(0.2, 0.6, 0.2)
saveButton.BackgroundTransparency = 0.3
saveButton.BorderSizePixel = 0
saveButton.Text = "SAVE [R]"
saveButton.TextColor3 = Color3.new(1, 1, 1)
saveButton.TextSize = 14
saveButton.Font = Enum.Font.GothamBold
saveButton.Parent = actionsContainer

local saveCorner = Instance.new("UICorner")
saveCorner.CornerRadius = UDim.new(0, 4)
saveCorner.Parent = saveButton

-- Load button
local loadButton = Instance.new("TextButton")
loadButton.Name = "LoadButton"
loadButton.Size = UDim2.new(1, 0, 0, 35)
loadButton.BackgroundColor3 = Color3.new(0.2, 0.4, 0.6)
loadButton.BackgroundTransparency = 0.3
loadButton.BorderSizePixel = 0
loadButton.Text = "LOAD [L]"
loadButton.TextColor3 = Color3.new(1, 1, 1)
loadButton.TextSize = 14
loadButton.Font = Enum.Font.GothamBold
loadButton.Parent = actionsContainer

local loadCorner = Instance.new("UICorner")
loadCorner.CornerRadius = UDim.new(0, 4)
loadCorner.Parent = loadButton

-- Instructions
local instructions = Instance.new("TextLabel")
instructions.Name = "Instructions"
instructions.Size = UDim2.new(1, -20, 0, 60)
instructions.Position = UDim2.new(0, 10, 1, -70)
instructions.BackgroundTransparency = 1
instructions.Text = "B: Toggle Build Mode\nLMB: Pick/Drop Parts\nRMB: Detach Parts\nTab: Cycle Slots"
instructions.TextColor3 = Color3.new(0.6, 0.6, 0.6)
instructions.TextSize = 11
instructions.Font = Enum.Font.Gotham
instructions.TextXAlignment = Enum.TextXAlignment.Left
instructions.TextYAlignment = Enum.TextYAlignment.Top
instructions.Parent = mainFrame

-- Selected slot indicator
local selectedSlot = 1

local function updateSlotSelection()
	for i, slotData in ipairs(slotButtons) do
		if slotData.unlocked then
			if i == selectedSlot then
				slotData.frame.BackgroundColor3 = Color3.new(0.2, 0.4, 0.6)
				slotData.label.TextColor3 = Color3.new(0, 0.8, 1)
			else
				slotData.frame.BackgroundColor3 = Color3.new(0.15, 0.15, 0.2)
				slotData.label.TextColor3 = Color3.new(1, 1, 1)
			end
		end
	end
end

-- Slot click handlers
for i, slotData in ipairs(slotButtons) do
	if slotData.unlocked then
		slotData.frame.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				selectedSlot = i
				updateSlotSelection()
			end
		end)
	end
end

-- Button handlers
saveButton.MouseButton1Click:Connect(function()
	print("Save clicked for slot", selectedSlot)
end)

loadButton.MouseButton1Click:Connect(function()
	print("Load clicked for slot", selectedSlot)
end)

-- Expose functions
local BlueprintGUI = {}

function BlueprintGUI.SetVisible(visible)
	screenGui.Enabled = visible
end

function BlueprintGUI.SetSlotStatus(slotIndex, status, complete)
	if slotButtons[slotIndex] and slotButtons[slotIndex].unlocked then
		slotButtons[slotIndex].status.Text = status
		if complete then
			slotButtons[slotIndex].status.TextColor3 = Color3.new(0, 1, 0)
		else
			slotButtons[slotIndex].status.TextColor3 = Color3.new(0.8, 0.8, 0.2)
		end
	end
end

function BlueprintGUI.GetSelectedSlot()
	return selectedSlot
end

function BlueprintGUI.SetUnlockedSlots(count)
	unlockedSlots = count
	for i, slotData in ipairs(slotButtons) do
		slotData.unlocked = i <= count
		-- Update lock overlay visibility
		for _, child in ipairs(slotData.frame:GetChildren()) do
			if child:IsA("Frame") and child.Name ~= "Status" then
				child.Visible = not slotData.unlocked
			end
		end
	end
end

-- Initialize
updateSlotSelection()

_G.BlueprintGUI = BlueprintGUI

print("[BlueprintGUI] Loaded")

return BlueprintGUI
