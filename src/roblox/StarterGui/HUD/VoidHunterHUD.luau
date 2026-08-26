-- vhHUD.lua (Optimized)
-- Manages client-side HUD (Health, Energy, Shield) and Radar
-- Uses CollectionService for efficient object tracking

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local hud = playerGui:WaitForChild("HUD")

-- UI Elements
local barsFrame = hud:WaitForChild("BarsFrame")
local healthFill = barsFrame:WaitForChild("HealthBar"):WaitForChild("Fill")
local shieldOverlay = barsFrame:WaitForChild("HealthBar"):WaitForChild("ShieldOverlay")
local energyFill = barsFrame:WaitForChild("EnergyBar"):WaitForChild("Fill")

local radarFrame = hud:WaitForChild("RadarFrame")
local radarRadius = radarFrame.AbsoluteSize.X / 2
local radarScale = 0.2 -- Studs to Pixels

-- Configuration
local TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local RADAR_TAGS = {"RadarEnemy", "RadarAsteroid", "RadarShip", "RadarDebris"}
local SCAN_INTERVAL = 0.5 -- How often to scan for new objects

-- State Tracking
local currentShip = nil
local radarIcons = {}
local trackedObjects = {}
local lastScanTime = 0

-- Color mapping for radar types
local RADAR_COLORS = {
	Enemy = Color3.fromRGB(255, 0, 0),
	Asteroid = Color3.fromRGB(150, 150, 150),
	Ship = Color3.fromRGB(0, 255, 255),
	Debris = Color3.fromRGB(255, 255, 100),
	Default = Color3.fromRGB(0, 255, 255)
}

-- Bar Updates
local function updateBars()
	if not currentShip then return end
	
	local health = currentShip:GetAttribute("Health") or 0
	local maxHealth = currentShip:GetAttribute("MaxHealth") or 100
	local shield = currentShip:GetAttribute("Shield") or 0
	local maxShield = currentShip:GetAttribute("MaxShield") or 100
	local energy = currentShip:GetAttribute("Energy") or 0
	local maxEnergy = currentShip:GetAttribute("MaxEnergy") or 100
	
	TweenService:Create(healthFill, TWEEN_INFO, {Size = UDim2.fromScale(health / maxHealth, 1)}):Play()
	TweenService:Create(shieldOverlay, TWEEN_INFO, {Size = UDim2.fromScale(shield / maxShield, 1)}):Play()
	TweenService:Create(energyFill, TWEEN_INFO, {Size = UDim2.fromScale(energy / maxEnergy, 1)}):Play()
end

local function setupShipTracking(ship)
	currentShip = ship
	ship:GetAttributeChangedSignal("Health"):Connect(updateBars)
	ship:GetAttributeChangedSignal("Shield"):Connect(updateBars)
	ship:GetAttributeChangedSignal("Energy"):Connect(updateBars)
	updateBars()
end

-- Radar Icon Management
local function createRadarIcon(object)
	local icon = Instance.new("Frame")
	icon.Size = UDim2.fromOffset(4, 4)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	
	local objType = object:GetAttribute("Type") or "Default"
	icon.BackgroundColor3 = RADAR_COLORS[objType] or RADAR_COLORS.Default
	
	local uiCorner = Instance.new("UICorner", icon)
	uiCorner.CornerRadius = UDim.new(1, 0)
	
	icon.Parent = radarFrame
	radarIcons[object] = icon
	
	return icon
end

local function removeRadarIcon(object)
	local icon = radarIcons[object]
	if icon then
		icon:Destroy()
		radarIcons[object] = nil
	end
end

-- Object Tracking via CollectionService
local function trackObject(object)
	if trackedObjects[object] then return end
	if object == currentShip then return end
	
	trackedObjects[object] = true
	createRadarIcon(object)
	
	-- Clean up when object is destroyed
	object.AncestryChanged:Connect(function(_, parent)
		if not parent then
			trackedObjects[object] = nil
			removeRadarIcon(object)
		end
	end)
end

-- Scan for objects with Type attribute (fallback for non-tagged objects)
local function scanForObjects()
	local workspace = game.Workspace
	
	-- Check Ships folder
	local shipsFolder = workspace:FindFirstChild("Ships")
	if shipsFolder then
		for _, ship in ipairs(shipsFolder:GetChildren()) do
			if ship:GetAttribute("Type") and not trackedObjects[ship] and ship ~= currentShip then
				trackObject(ship)
			end
		end
	end
	
	-- Check Enemies folder
	local enemiesFolder = workspace:FindFirstChild("Enemies")
	if enemiesFolder then
		for _, enemy in ipairs(enemiesFolder:GetChildren()) do
			if enemy:GetAttribute("Type") and not trackedObjects[enemy] then
				trackObject(enemy)
			end
		end
	end
	
	-- Check Asteroids folder
	local asteroidsFolder = workspace:FindFirstChild("Asteroids")
	if asteroidsFolder then
		for _, asteroid in ipairs(asteroidsFolder:GetChildren()) do
			if asteroid:GetAttribute("Type") and not trackedObjects[asteroid] then
				trackObject(asteroid)
			end
		end
	end
	
	-- Check Debris folder
	local debrisFolder = workspace:FindFirstChild("Debris")
	if debrisFolder then
		for _, debris in ipairs(debrisFolder:GetChildren()) do
			if debris:GetAttribute("Type") and not trackedObjects[debris] then
				trackObject(debris)
			end
		end
	end
end

-- Setup CollectionService tags (for future use)
for _, tagName in ipairs(RADAR_TAGS) do
	CollectionService:GetInstanceAddedSignal(tagName):Connect(trackObject)
	CollectionService:GetInstanceRemovedSignal(tagName):Connect(removeRadarIcon)
	
	-- Track existing tagged objects
	for _, object in ipairs(CollectionService:GetTagged(tagName)) do
		trackObject(object)
	end
end

-- Main Update Loop
RunService.RenderStepped:Connect(function()
	local char = player.Character
	if not char or not char.PrimaryPart then return end
	
	local playerPos = char.PrimaryPart.Position
	
	-- Update current ship if needed
	local shipName = player:GetAttribute("CurrentShip")
	if shipName and (not currentShip or currentShip.Name ~= shipName) then
		local shipsFolder = game.Workspace:FindFirstChild("Ships")
		local ship = shipsFolder and shipsFolder:FindFirstChild(shipName)
		if ship then
			setupShipTracking(ship)
		end
	end
	
	-- Periodic scan for new objects (not every frame!)
	local now = tick()
	if now - lastScanTime >= SCAN_INTERVAL then
		lastScanTime = now
		scanForObjects()
	end
	
	-- Update radar icon positions
	for object, icon in pairs(radarIcons) do
		if not object.Parent then
			-- Object was destroyed, clean up
			trackedObjects[object] = nil
			removeRadarIcon(object)
		else
			-- Update position
			local pos = object:IsA("Model") and object:GetPivot().Position or object.Position
			local offset = pos - playerPos
			local radarPos = Vector2.new(offset.X, offset.Z) * radarScale
			
			if radarPos.Magnitude < radarRadius then
				icon.Visible = true
				icon.Position = UDim2.fromOffset(radarRadius + radarPos.X, radarRadius + radarPos.Y)
			else
				icon.Visible = false
			end
		end
	end
end)

-- Initial scan
scanForObjects()

print("[HUD] Initialized with optimized radar system")
