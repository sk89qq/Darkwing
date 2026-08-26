-- VoidHunter Tutorial Tracker (Server)
-- Tracks whether players have completed the tutorial
-- Place in ServerScriptService.VoidHunters

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- DataStore for tutorial progress
local TutorialDataStore = DataStoreService:GetDataStore("VoidHunters_Tutorial_v1")

-- Track tutorial completion
local function onPlayerAdded(player)
	-- Load tutorial status
	local success, data = pcall(function()
		return TutorialDataStore:GetAsync("tutorial_" .. player.UserId)
	end)
	
	if success and data then
		player:SetAttribute("HasSeenTutorial", data.hasSeenTutorial or false)
	else
		player:SetAttribute("HasSeenTutorial", false)
	end
	
	print("[TutorialTracker] " .. player.Name .. " tutorial status loaded")
end

-- Save tutorial status when player leaves
local function onPlayerRemoving(player)
	local hasSeenTutorial = player:GetAttribute("HasSeenTutorial")
	
	if hasSeenTutorial ~= nil then
		pcall(function()
			TutorialDataStore:SetAsync("tutorial_" .. player.UserId, {
				hasSeenTutorial = hasSeenTutorial
			})
		end)
	end
	
	print("[TutorialTracker] " .. player.Name .. " tutorial status saved")
end

-- Connect events
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Handle players already in game
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

print("[TutorialTracker] Loaded")
