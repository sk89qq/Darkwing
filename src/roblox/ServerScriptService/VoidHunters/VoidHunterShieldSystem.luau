-- VoidHunter Shield System
-- Handles shield generator activation and bubble visualization

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Configuration
local SHIELD_CONFIG = {
	ENERGY_REGEN_RATE = 5, -- energy per second when recharging
	DAMAGE_TO_ENERGY = 0.5, -- 1 damage = 0.5 energy (5 damage = 2.5 energy)
	MAX_ENERGY = 100,
	MIN_ENERGY_TO_ACTIVATE = 50, -- 50% energy required to activate
	SHIELD_RADIUS = 75, -- studs (matches visual bubble size)
	RECHARGE_DELAY = 2, -- seconds after deactivation before recharge starts
	BUBBLE_SIZE = 75, -- studs (visual bubble diameter)
	GLOW_BRIGHTNESS_BASE = 0.9, -- reduced by 70%
	GLOW_RANGE_BASE = 80, -- matches bubble size
}

-- Track active shields
local activeShields = {}
local shieldCooldowns = {}

-- Find all shield generators in workspace
local function findShieldGenerators()
	local shields = {}
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Model") or obj:IsA("Part") then
			local name = obj.Name
			if name == "ShieldGenerator" or name == "Shield Generator" then
				table.insert(shields, obj)
			end
		end
	end
	return shields
end

-- Initialize a shield generator
local function initShieldGenerator(shieldModel)
	local body = shieldModel:FindFirstChild("world")
	if body then
		body = body:FindFirstChild("body")
	end
	if not body then return end
	
	local bubble = body:FindFirstChild("ShieldBubble")
	if not bubble then return end
	
	-- Set initial state
	bubble:SetAttribute("ShieldActive", false)
	bubble:SetAttribute("ShieldEnergy", SHIELD_CONFIG.MAX_ENERGY)
	bubble:SetAttribute("MaxEnergy", SHIELD_CONFIG.MAX_ENERGY)
	bubble.Transparency = 0.95
	
	local light = bubble:FindFirstChild("BubbleGlow")
	if light then
		light.Brightness = 0
	end
	
	activeShields[bubble] = {
		model = shieldModel,
		energy = SHIELD_CONFIG.MAX_ENERGY,
		active = false,
		lastHitTime = 0
	}
end

-- Update shield bubble visual
local function updateShieldVisual(bubble, energy, isActive)
	local energyPercent = energy / SHIELD_CONFIG.MAX_ENERGY
	
	-- Find opaque module for visual feedback
	local parent = bubble.Parent
	local opaqueModule = parent and parent:FindFirstChild("GeneratorModule_Opaque")
	
	if isActive then
		-- Active shield: visible with glow (reduced intensity)
		bubble.Transparency = 0.85 - (energyPercent * 0.1)
		bubble.Color = Color3.fromRGB(
			100 + (1 - energyPercent) * 50,
			180 + energyPercent * 40,
			220 + energyPercent * 35
		)
		
		local light = bubble:FindFirstChild("BubbleGlow")
		if light then
			-- Reduced glow effect (70% less)
			light.Brightness = SHIELD_CONFIG.GLOW_BRIGHTNESS_BASE + energyPercent * 0.5
			light.Range = SHIELD_CONFIG.GLOW_RANGE_BASE + energyPercent * 15
		end
		
		-- Subtle pulse on opaque module when active
		if opaqueModule then
			opaqueModule.Color = Color3.fromRGB(
				70 + energyPercent * 30,
				160 + energyPercent * 40,
				180 + energyPercent * 40
			)
			opaqueModule.Reflectance = 0.2 + energyPercent * 0.15
		end
	else
		-- Inactive shield: mostly transparent
		bubble.Transparency = 0.92
		bubble.Color = Color3.fromRGB(100, 200, 255)
		
		local light = bubble:FindFirstChild("BubbleGlow")
		if light then
			light.Brightness = SHIELD_CONFIG.GLOW_BRIGHTNESS_BASE * 0.3 * energyPercent
			light.Range = SHIELD_CONFIG.GLOW_RANGE_BASE * 0.5
		end
		
		-- Reset opaque module
		if opaqueModule then
			opaqueModule.Color = Color3.fromRGB(70, 160, 160)
			opaqueModule.Reflectance = 0.2
		end
	end
end

-- Activate shield
local function activateShield(bubble)
	local data = activeShields[bubble]
	if not data then return end
	
	if data.energy >= SHIELD_CONFIG.MIN_ENERGY_TO_ACTIVATE then
		data.active = true
		bubble:SetAttribute("ShieldActive", true)
		updateShieldVisual(bubble, data.energy, true)
	end
end

-- Deactivate shield
local function deactivateShield(bubble)
	local data = activeShields[bubble]
	if not data then return end
	
	data.active = false
	data.wasActive = true -- Remember it was active for auto-reactivation
	bubble:SetAttribute("ShieldActive", false)
	shieldCooldowns[bubble] = tick()
	updateShieldVisual(bubble, data.energy, false)
end

-- Damage shield (called when hit)
-- Converts damage to energy use: 5 damage = 2.5 energy
local function damageShield(bubble, amount)
	local data = activeShields[bubble]
	if not data or not data.active then return false end
	
	-- Convert damage to energy cost
	local energyCost = amount * SHIELD_CONFIG.DAMAGE_TO_ENERGY
	data.energy = math.max(0, data.energy - energyCost)
	data.lastHitTime = tick()
	
	if data.energy <= 0 then
		deactivateShield(bubble)
		return false -- Shield broke
	end
	
	updateShieldVisual(bubble, data.energy, true)
	return true -- Shield absorbed damage
end

-- Main update loop
RunService.Heartbeat:Connect(function(deltaTime)
	for bubble, data in pairs(activeShields) do
		if bubble and bubble.Parent then
			-- Recharge energy when not active
			if not data.active then
				local lastHit = shieldCooldowns[bubble] or 0
				if tick() - lastHit > SHIELD_CONFIG.RECHARGE_DELAY then
					data.energy = math.min(SHIELD_CONFIG.MAX_ENERGY, data.energy + SHIELD_CONFIG.ENERGY_REGEN_RATE * deltaTime)
					bubble:SetAttribute("ShieldEnergy", data.energy)
					updateShieldVisual(bubble, data.energy, false)
					
					-- Auto-reactivate when energy reaches 50%
					if data.energy >= SHIELD_CONFIG.MIN_ENERGY_TO_ACTIVATE and data.wasActive then
						activateShield(bubble)
						data.wasActive = false
					end
				end
			else
				-- No passive drain - only drain on damage
				bubble:SetAttribute("ShieldEnergy", data.energy)
				updateShieldVisual(bubble, data.energy, true)
			end
		end
	end
end)

-- Initialize existing shields
for _, shield in ipairs(findShieldGenerators()) do
	initShieldGenerator(shield)
end

-- Handle new shields added to workspace
workspace.DescendantAdded:Connect(function(descendant)
	if descendant.Name == "ShieldGenerator" or descendant.Name == "Shield Generator" then
		task.wait(0.1) -- Wait for full model to load
		initShieldGenerator(descendant)
	end
end)

-- RemoteEvent for player activation
local function setupRemoteEvent()
	local comms = ReplicatedStorage:FindFirstChild("Communication")
	if not comms then
		comms = Instance.new("Folder")
		comms.Name = "Communication"
		comms.Parent = ReplicatedStorage
	end
	
	local event = comms:FindFirstChild("ShieldAction")
	if not event then
		event = Instance.new("RemoteEvent")
		event.Name = "ShieldAction"
		event.Parent = comms
	end
	
	event.OnServerEvent:Connect(function(player, action, shieldModel)
		if not shieldModel then return end
		
		local body = shieldModel:FindFirstChild("world")
		if body then body = body:FindFirstChild("body") end
		if not body then return end
		
		local bubble = body:FindFirstChild("ShieldBubble")
		if not bubble then return end
		
		if action == "activate" then
			activateShield(bubble)
		elseif action == "deactivate" then
			deactivateShield(bubble)
		end
	end)
end

setupRemoteEvent()

-- Export functions for other scripts
local ShieldSystem = {}
ShieldSystem.damageShield = damageShield
ShieldSystem.activateShield = activateShield
ShieldSystem.deactivateShield = deactivateShield
ShieldSystem.isShieldActive = function(bubble)
	local data = activeShields[bubble]
	return data and data.active
end

return ShieldSystem
