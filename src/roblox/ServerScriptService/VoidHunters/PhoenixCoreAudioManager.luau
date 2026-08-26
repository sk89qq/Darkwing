-- PhoenixCoreAudioManager.lua
-- Server-side audio coordination + client music/SFX shell
-- Phase 1: Framework only. Fill in rbxassetid values when assets are uploaded.

local AudioManager = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Create audio folder structure in ReplicatedStorage
local audioFolder = ReplicatedStorage:FindFirstChild("PhoenixCoreAudio")
if not audioFolder then
	audioFolder = Instance.new("Folder")
	audioFolder.Name = "PhoenixCoreAudio"
	audioFolder.Parent = ReplicatedStorage
	for _, sub in ipairs({"Music", "SFX"}) do
		local f = Instance.new("Folder")
		f.Name = sub
		f.Parent = audioFolder
	end
end

-- Music asset IDs - replace XXXXX with actual uploaded IDs
local MUSIC_IDS = {
	Lobby = "rbxassetid://0",    -- TODO: Upload and replace
	Combat = "rbxassetid://0",   -- TODO: Upload and replace
	Victory = "rbxassetid://0",  -- TODO: Upload and replace
	Defeat = "rbxassetid://0",   -- TODO: Upload and replace
}

-- SFX asset IDs
local SFX_IDS = {
	weaponFire = "rbxassetid://0",
	enemyDeath = "rbxassetid://0",
	asteroidBreak = "rbxassetid://0",
	shieldHit = "rbxassetid://0",
	waveClear = "rbxassetid://0",
}

-- RemoteEvent for client audio commands
local commFolder = ReplicatedStorage:FindFirstChild("Communication")
if not commFolder then
	commFolder = Instance.new("Folder")
	commFolder.Name = "Communication"
	commFolder.Parent = ReplicatedStorage
end

local audioEvent = commFolder:FindFirstChild("PhoenixAudioCommand")
if not audioEvent then
	audioEvent = Instance.new("RemoteEvent")
	audioEvent.Name = "PhoenixAudioCommand"
	audioEvent.Parent = commFolder
end

local currentState = nil

local function broadcastAudio(command, data)
	for _, p in ipairs(Players:GetPlayers()) do
		audioEvent:FireClient(p, command, data)
	end
end

function AudioManager.PlayMusic(state)
	if currentState == state then return end
	currentState = state
	local assetId = MUSIC_IDS[state]
	if assetId and assetId ~= "rbxassetid://0" then
		broadcastAudio("playMusic", assetId)
	end
	print("[AudioManager] Music state: " .. state)
end

function AudioManager.PlaySFX(soundType, player)
	local assetId = SFX_IDS[soundType]
	if assetId and assetId ~= "rbxassetid://0" then
		if player then
			audioEvent:FireClient(player, "playSFX", assetId)
		else
			broadcastAudio("playSFX", assetId)
		end
	end
end

function AudioManager.SetMusicId(state, assetId)
	MUSIC_IDS[state] = assetId
end

function AudioManager.SetSFXId(sfxType, assetId)
	SFX_IDS[sfxType] = assetId
end

function AudioManager.Init()
	print("[AudioManager] Initialized. Add asset IDs via SetMusicId/SetSFXId.")
end

return AudioManager
