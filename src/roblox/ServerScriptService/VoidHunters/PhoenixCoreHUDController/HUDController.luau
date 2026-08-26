-- PhoenixCoreHUDController.lua
-- Server-side HUD relay - creates RemoteEvents and fires them to clients

local HUDController = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Create or reuse RemoteEvents folder
local hudEvents = ReplicatedStorage:FindFirstChild("PhoenixCoreHUDEvents")
if not hudEvents then
	hudEvents = Instance.new("Folder")
	hudEvents.Name = "PhoenixCoreHUDEvents"
	hudEvents.Parent = ReplicatedStorage
end

local function getOrCreate(name)
	local existing = hudEvents:FindFirstChild(name)
	if existing then return existing end
	local re = Instance.new("RemoteEvent")
	re.Name = name
	re.Parent = hudEvents
	return re
end

local updateHealth = getOrCreate("UpdateHealth")
local updateShield = getOrCreate("UpdateShield")
local updateWave = getOrCreate("UpdateWave")
local addKill = getOrCreate("AddKill")
local showStatus = getOrCreate("ShowStatus")

function HUDController.UpdatePlayerHealth(player, current, max)
	updateHealth:FireClient(player, current, max)
end

function HUDController.UpdatePlayerShield(player, current, max)
	updateShield:FireClient(player, current, max)
end

function HUDController.UpdateWaveInfo(player, current, total, enemies)
	updateWave:FireClient(player, current, total, enemies)
end

function HUDController.AddPlayerKill(player, points)
	addKill:FireClient(player, points)
end

function HUDController.ShowStatusMessage(player, message, duration)
	showStatus:FireClient(player, message, duration or 3)
end

function HUDController.BroadcastStatus(message, duration)
	for _, p in ipairs(Players:GetPlayers()) do
		HUDController.ShowStatusMessage(p, message, duration)
	end
end

function HUDController.BroadcastWaveInfo(current, total, enemies)
	for _, p in ipairs(Players:GetPlayers()) do
		HUDController.UpdateWaveInfo(p, current, total, enemies)
	end
end

return HUDController
