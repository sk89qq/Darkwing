-- VoidHunter Sound Manager
-- Handles all game audio (weapons, explosions, ambient)
-- Place in ReplicatedStorage.VoidHunters

local SoundManager = {}

local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Sound IDs (using Roblox library sounds - replace with custom sounds as needed)
local SOUND_IDS = {
	-- Weapons
	MassDriver = "rbxassetid://130767925",  -- Laser/pew sound
	PlasmaBall = "rbxassetid://183524370",  -- Energy projectile
	MissileLauncher = "rbxassetid://155868808",  -- Whoosh/launch
	DroneBay = "rbxassetid://297345269",  -- Mechanical deploy
	Laser = "rbxassetid://130767925",  -- Beam (same as mass driver)
	ScramblerPulse = "rbxassetid://276558599",  -- EMP pulse
	
	-- Impacts
	HitMetal = "rbxassetid://142082166",  -- Metal impact
	HitShield = "rbxassetid://276580372",  -- Energy shield
	Explosion = "rbxassetid://142082169",  -- Explosion
	ExplosionLarge = "rbxassetid://142082169",  -- Large explosion
	
	-- Ambient
	AmbientSpace = "rbxassetid://904518097",  -- Space ambient
	EngineThruster = "rbxassetid://155781703",  -- Engine hum
	
	-- UI
	UIClick = "rbxassetid://170470350",  -- Button click
	CollectDebris = "rbxassetid://276580372",  -- Pickup sound
}

-- Volume settings
local VOLUMES = {
	MassDriver = 0.6,
	PlasmaBall = 0.7,
	MissileLauncher = 0.8,
	DroneBay = 0.5,
	Laser = 0.5,
	ScramblerPulse = 0.7,
	HitMetal = 0.4,
	HitShield = 0.3,
	Explosion = 0.8,
	ExplosionLarge = 1.0,
	AmbientSpace = 0.3,
	EngineThruster = 0.2,
	UIClick = 0.5,
	CollectDebris = 0.6,
}

-- Sound cache
local soundCache = {}

-- Create or get a sound
local function getSound(soundName)
	if soundCache[soundName] then
		return soundCache[soundName]
	end
	
	local soundId = SOUND_IDS[soundName]
	if not soundId then
		warn("[SoundManager] Unknown sound: " .. soundName)
		return nil
	end
	
	local sound = Instance.new("Sound")
	sound.Name = soundName
	sound.SoundId = soundId
	sound.Volume = VOLUMES[soundName] or 0.5
	sound.Archivable = true
	
	soundCache[soundName] = sound
	return sound
end

-- Play a sound at a specific position (3D spatial)
function SoundManager.PlayPositional(soundName, position, parent)
	local sound = getSound(soundName)
	if not sound then return end
	
	local soundInstance = sound:Clone()
	soundInstance.Parent = parent or workspace
	
	-- For 3D positioning, we need to place the sound near the position
	if parent and parent:IsA("BasePart") then
		soundInstance.Position = position or Vector3.new(0, 0, 0)
	else
		-- Create a temporary part for 3D sound
		local tempPart = Instance.new("Part")
		tempPart.Name = "SoundEmitter_" .. soundName
		tempPart.Size = Vector3.new(1, 1, 1)
		tempPart.Transparency = 1
		tempPart.CanCollide = false
		tempPart.Anchored = true
		tempPart.Position = position or Vector3.new(0, 0, 0)
		tempPart.Parent = workspace
		
		soundInstance.Parent = tempPart
		soundInstance.RollOffMaxDistance = 200
		
		-- Clean up after sound finishes
		soundInstance.Ended:Connect(function()
			tempPart:Destroy()
		end)
	end
	
	soundInstance:Play()
	return soundInstance
end

-- Play a sound attached to a part
function SoundManager.PlayAttached(soundName, part)
	if not part or not part.Parent then return nil end
	
	local sound = getSound(soundName)
	if not sound then return nil end
	
	local soundInstance = sound:Clone()
	soundInstance.Parent = part
	
	-- Clean up after sound finishes
	soundInstance.Ended:Connect(function()
		if soundInstance.Parent then
			soundInstance:Destroy()
		end
	end)
	
	soundInstance:Play()
	return soundInstance
end

-- Play a 2D sound (for UI, global effects)
function SoundManager.PlayGlobal(soundName)
	local sound = getSound(soundName)
	if not sound then return nil end
	
	local soundInstance = sound:Clone()
	soundInstance.Parent = SoundService
	soundInstance.RollOffMaxDistance = 10000
	
	soundInstance.Ended:Connect(function()
		soundInstance:Destroy()
	end)
	
	soundInstance:Play()
	return soundInstance
end

-- Play weapon sound
function SoundManager.PlayWeapon(weaponType, position, parent)
	local soundName = weaponType
	if weaponType == "MassDriver" then
		soundName = "MassDriver"
	elseif weaponType == "PlasmaBall" then
		soundName = "PlasmaBall"
	elseif weaponType == "MissileLauncher" then
		soundName = "MissileLauncher"
	elseif weaponType == "DroneBay" then
		soundName = "DroneBay"
	elseif weaponType == "Laser" then
		soundName = "Laser"
	elseif weaponType == "ScramblerPulse" then
		soundName = "ScramblerPulse"
	end
	
	return SoundManager.PlayPositional(soundName, position, parent)
end

-- Play explosion sound
function SoundManager.PlayExplosion(position, isLarge)
	local soundName = isLarge and "ExplosionLarge" or "Explosion"
	return SoundManager.PlayPositional(soundName, position)
end

-- Play hit sound
function SoundManager.PlayHit(position, isShield)
	local soundName = isShield and "HitShield" or "HitMetal"
	return SoundManager.PlayPositional(soundName, position)
end

-- Play ambient sound (loops)
function SoundManager.PlayAmbient(soundName)
	local sound = getSound(soundName)
	if not sound then return nil end
	
	local soundInstance = sound:Clone()
	soundInstance.Looped = true
	soundInstance.Parent = SoundService
	soundInstance:Play()
	
	return soundInstance
end

-- Play UI sound
function SoundManager.PlayUI(soundName)
	return SoundManager.PlayGlobal(soundName or "UIClick")
end

-- Play debris collection sound
function SoundManager.PlayCollect()
	return SoundManager.PlayGlobal("CollectDebris")
end

return SoundManager
