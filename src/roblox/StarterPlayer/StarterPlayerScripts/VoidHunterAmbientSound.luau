-- VoidHunter Ambient Sound Controller
-- Plays ambient space sounds for immersion
-- Place in StarterPlayerScripts

local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Wait for sound manager
local soundManager = ReplicatedStorage:WaitForChild("VoidHunters"):WaitForChild("VoidHunterSoundManager")
local SoundManager = require(soundManager)

-- Ambient sounds
local ambientSounds = {}

-- Start ambient space sound
local function startAmbient()
	-- Space ambient
	local spaceAmbient = Instance.new("Sound")
	spaceAmbient.Name = "SpaceAmbient"
	spaceAmbient.SoundId = "rbxassetid://904518097"
	spaceAmbient.Volume = 0.15
	spaceAmbient.Looped = true
	spaceAmbient.Parent = SoundService
	spaceAmbient:Play()
	table.insert(ambientSounds, spaceAmbient)
	
	-- Engine hum (subtle)
	local engineHum = Instance.new("Sound")
	engineHum.Name = "EngineHum"
	engineHum.SoundId = "rbxassetid://155781703"
	engineHum.Volume = 0.08
	engineHum.Looped = true
	engineHum.Parent = SoundService
	engineHum:Play()
	table.insert(ambientSounds, engineHum)
	
	print("[AmbientSound] Started ambient sounds")
end

-- Stop all ambient sounds
local function stopAmbient()
	for _, sound in ipairs(ambientSounds) do
		if sound.Parent then
			sound:Stop()
			sound:Destroy()
		end
	end
	ambientSounds = {}
end

-- Start ambient on client load
startAmbient()

-- Cleanup on game ending (optional)
game:BindToClose(function()
	stopAmbient()
end)

print("[AmbientSound] Controller loaded")
