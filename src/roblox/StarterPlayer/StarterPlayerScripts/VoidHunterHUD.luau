--[[
	VoidHunter HUD & Tactical Radar System (Client)
	Provides:
	  - 360° Tactical Radar with Range Rings, Compass Heading, and Color-Coded Entity Blips (Enemies, Allies, Salvage, Asteroids)
	  - Vitality Gauges: Command Core HP, Deflector Shield Capacity, and Reactor Capacitor Power (with Brownout Alerts)
	  - Arena Match Header: Round Phase, Countdown Timer, Team Scores (Red vs Blue), and Personal Kills/Score
	  - Event Killfeed Ticker & Match State Notification Banners
	  - Interactive Scoreboard (TAB toggle)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Ensure ScreenGui
local hudGui = Instance.new("ScreenGui")
hudGui.Name = "VoidHunterHUD"
hudGui.ResetOnSpawn = false
hudGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
hudGui.Parent = PlayerGui

-----------------------------------------------------------------------------
-- CONSTANTS & PALETTE
-----------------------------------------------------------------------------
local COLOR_BG = Color3.fromRGB(15, 18, 24)
local COLOR_BORDER = Color3.fromRGB(40, 52, 70)
local COLOR_ACCENT_CYAN = Color3.fromRGB(0, 200, 255)
local COLOR_RED_TEAM = Color3.fromRGB(255, 65, 65)
local COLOR_BLUE_TEAM = Color3.fromRGB(50, 140, 255)
local COLOR_GOLD_SALVAGE = Color3.fromRGB(255, 200, 40)
local COLOR_ASTEROID = Color3.fromRGB(130, 120, 110)
local COLOR_SHIELD = Color3.fromRGB(80, 180, 255)
local COLOR_ENERGY = Color3.fromRGB(70, 240, 120)
local COLOR_HP_GREEN = Color3.fromRGB(60, 220, 100)

local RADAR_SIZE = 170
local RADAR_RANGE = 250 -- studs in world space

-----------------------------------------------------------------------------
-- 1. MATCH HEADER (TOP CENTER)
-----------------------------------------------------------------------------
local headerFrame = Instance.new("Frame")
headerFrame.Name = "MatchHeader"
headerFrame.Size = UDim2.new(0, 420, 0, 56)
headerFrame.Position = UDim2.new(0.5, -210, 0, 12)
headerFrame.BackgroundColor3 = COLOR_BG
headerFrame.BackgroundTransparency = 0.25
headerFrame.BorderSizePixel = 0
headerFrame.Parent = hudGui

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 8)
headerCorner.Parent = headerFrame

local headerStroke = Instance.new("UIStroke")
headerStroke.Color = COLOR_BORDER
headerStroke.Thickness = 1.2
headerStroke.Parent = headerFrame

-- Match Phase & Timer Label
local phaseLabel = Instance.new("TextLabel")
phaseLabel.Name = "PhaseLabel"
phaseLabel.Size = UDim2.new(1, 0, 0, 18)
phaseLabel.Position = UDim2.new(0, 0, 0, 4)
phaseLabel.BackgroundTransparency = 1
phaseLabel.Text = "LOBBY PREPARATION"
phaseLabel.TextColor3 = COLOR_ACCENT_CYAN
phaseLabel.TextSize = 11
phaseLabel.Font = Enum.Font.GothamBold
phaseLabel.TextXAlignment = Enum.TextXAlignment.Center
phaseLabel.Parent = headerFrame

local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "TimerLabel"
timerLabel.Size = UDim2.new(0, 80, 0, 26)
timerLabel.Position = UDim2.new(0.5, -40, 0, 22)
timerLabel.BackgroundTransparency = 1
timerLabel.Text = "02:45"
timerLabel.TextColor3 = Color3.new(1, 1, 1)
timerLabel.TextSize = 18
timerLabel.Font = Enum.Font.GothamBlack
timerLabel.TextXAlignment = Enum.TextXAlignment.Center
timerLabel.Parent = headerFrame

-- Red Team Score
local redScoreLabel = Instance.new("TextLabel")
redScoreLabel.Name = "RedScore"
redScoreLabel.Size = UDim2.new(0, 110, 0, 26)
redScoreLabel.Position = UDim2.new(0, 16, 0, 22)
redScoreLabel.BackgroundTransparency = 1
redScoreLabel.Text = "RED  0"
redScoreLabel.TextColor3 = COLOR_RED_TEAM
redScoreLabel.TextSize = 16
redScoreLabel.Font = Enum.Font.GothamBlack
redScoreLabel.TextXAlignment = Enum.TextXAlignment.Left
redScoreLabel.Parent = headerFrame

-- Blue Team Score
local blueScoreLabel = Instance.new("TextLabel")
blueScoreLabel.Name = "BlueScore"
blueScoreLabel.Size = UDim2.new(0, 110, 0, 26)
blueScoreLabel.Position = UDim2.new(1, -126, 0, 22)
blueScoreLabel.BackgroundTransparency = 1
blueScoreLabel.Text = "0  BLUE"
blueScoreLabel.TextColor3 = COLOR_BLUE_TEAM
blueScoreLabel.TextSize = 16
blueScoreLabel.Font = Enum.Font.GothamBlack
blueScoreLabel.TextXAlignment = Enum.TextXAlignment.Right
blueScoreLabel.Parent = headerFrame

-----------------------------------------------------------------------------
-- 2. NOTIFICATION BANNER (TOP-CENTER MODAL POPUP)
-----------------------------------------------------------------------------
local notifBanner = Instance.new("Frame")
notifBanner.Name = "NotificationBanner"
notifBanner.Size = UDim2.new(0, 480, 0, 48)
notifBanner.Position = UDim2.new(0.5, -240, 0, 76)
notifBanner.BackgroundColor3 = COLOR_BG
notifBanner.BackgroundTransparency = 0.15
notifBanner.Visible = false
notifBanner.BorderSizePixel = 0
notifBanner.Parent = hudGui

local notifCorner = Instance.new("UICorner")
notifCorner.CornerRadius = UDim.new(0, 6)
notifCorner.Parent = notifBanner

local notifStroke = Instance.new("UIStroke")
notifStroke.Color = COLOR_ACCENT_CYAN
notifStroke.Thickness = 1.5
notifStroke.Parent = notifBanner

local notifTitle = Instance.new("TextLabel")
notifTitle.Name = "Title"
notifTitle.Size = UDim2.new(1, 0, 0, 20)
notifTitle.Position = UDim2.new(0, 0, 0, 4)
notifTitle.BackgroundTransparency = 1
notifTitle.Text = "SECTOR INGRESS"
notifTitle.TextColor3 = COLOR_ACCENT_CYAN
notifTitle.TextSize = 14
notifTitle.Font = Enum.Font.GothamBold
notifTitle.Parent = notifBanner

local notifSub = Instance.new("TextLabel")
notifSub.Name = "Subtitle"
notifSub.Size = UDim2.new(1, 0, 0, 16)
notifSub.Position = UDim2.new(0, 0, 0, 24)
notifSub.BackgroundTransparency = 1
notifSub.Text = "Engage hostile forces."
notifSub.TextColor3 = Color3.fromRGB(210, 220, 230)
notifSub.TextSize = 11
notifSub.Font = Enum.Font.Gotham
notifSub.Parent = notifBanner

-----------------------------------------------------------------------------
-- 3. 360° TACTICAL RADAR (BOTTOM RIGHT)
-----------------------------------------------------------------------------
local radarContainer = Instance.new("Frame")
radarContainer.Name = "RadarContainer"
radarContainer.Size = UDim2.new(0, RADAR_SIZE, 0, RADAR_SIZE)
radarContainer.Position = UDim2.new(1, -RADAR_SIZE - 20, 1, -RADAR_SIZE - 20)
radarContainer.BackgroundColor3 = COLOR_BG
radarContainer.BackgroundTransparency = 0.25
radarContainer.BorderSizePixel = 0
radarContainer.Parent = hudGui

local radarCorner = Instance.new("UICorner")
radarCorner.CornerRadius = UDim.new(1, 0)
radarCorner.Parent = radarContainer

local radarStroke = Instance.new("UIStroke")
radarStroke.Color = COLOR_BORDER
radarStroke.Thickness = 1.5
radarStroke.Parent = radarContainer

-- Concentric Range Rings
local function createRadarRing(scale: number)
	local ring = Instance.new("Frame")
	ring.Size = UDim2.new(scale, 0, scale, 0)
	ring.Position = UDim2.new((1 - scale)/2, 0, (1 - scale)/2, 0)
	ring.BackgroundTransparency = 1
	ring.BorderSizePixel = 0
	ring.Parent = radarContainer

	local rCorner = Instance.new("UICorner")
	rCorner.CornerRadius = UDim.new(1, 0)
	rCorner.Parent = ring

	local rStroke = Instance.new("UIStroke")
	rStroke.Color = Color3.fromRGB(45, 60, 80)
	rStroke.Thickness = 1
	rStroke.Transparency = 0.4
	rStroke.Parent = ring
end

createRadarRing(0.33)
createRadarRing(0.66)
createRadarRing(0.95)

-- Radar Center Ship Blip (Self)
local selfBlip = Instance.new("Frame")
selfBlip.Name = "SelfBlip"
selfBlip.Size = UDim2.new(0, 6, 0, 6)
selfBlip.Position = UDim2.new(0.5, -3, 0.5, -3)
selfBlip.BackgroundColor3 = COLOR_ACCENT_CYAN
selfBlip.BorderSizePixel = 0
selfBlip.ZIndex = 5
selfBlip.Parent = radarContainer

local selfCorner = Instance.new("UICorner")
selfCorner.CornerRadius = UDim.new(1, 0)
selfCorner.Parent = selfBlip

local radarTitle = Instance.new("TextLabel")
radarTitle.Size = UDim2.new(1, 0, 0, 14)
radarTitle.Position = UDim2.new(0, 0, 0, -18)
radarTitle.BackgroundTransparency = 1
radarTitle.Text = "TACTICAL RADAR (250m)"
radarTitle.TextColor3 = COLOR_ACCENT_CYAN
radarTitle.TextSize = 10
radarTitle.Font = Enum.Font.GothamBold
radarTitle.TextXAlignment = Enum.TextXAlignment.Center
radarTitle.Parent = radarContainer

-----------------------------------------------------------------------------
-- 4. SHIP VITALITY GAUGES (BOTTOM RIGHT, LEFT OF RADAR)
-----------------------------------------------------------------------------
local gaugesFrame = Instance.new("Frame")
gaugesFrame.Name = "GaugesFrame"
gaugesFrame.Size = UDim2.new(0, 200, 0, 110)
gaugesFrame.Position = UDim2.new(1, -RADAR_SIZE - 235, 1, -130)
gaugesFrame.BackgroundColor3 = COLOR_BG
gaugesFrame.BackgroundTransparency = 0.35
gaugesFrame.BorderSizePixel = 0
gaugesFrame.Parent = hudGui

local gaugesCorner = Instance.new("UICorner")
gaugesCorner.CornerRadius = UDim.new(0, 6)
gaugesCorner.Parent = gaugesFrame

local gaugesStroke = Instance.new("UIStroke")
gaugesStroke.Color = COLOR_BORDER
gaugesStroke.Thickness = 1
gaugesStroke.Parent = gaugesFrame

local function createBar(name: string, yPos: number, barColor: Color3, labelText: string)
	local label = Instance.new("TextLabel")
	label.Name = name .. "Label"
	label.Size = UDim2.new(1, -16, 0, 12)
	label.Position = UDim2.new(0, 8, 0, yPos)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextColor3 = Color3.fromRGB(200, 210, 220)
	label.TextSize = 9
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = gaugesFrame

	local valLabel = Instance.new("TextLabel")
	valLabel.Name = name .. "Val"
	valLabel.Size = UDim2.new(0, 80, 0, 12)
	valLabel.Position = UDim2.new(1, -88, 0, yPos)
	valLabel.BackgroundTransparency = 1
	valLabel.Text = "100%"
	valLabel.TextColor3 = Color3.new(1, 1, 1)
	valLabel.TextSize = 9
	valLabel.Font = Enum.Font.GothamBold
	valLabel.TextXAlignment = Enum.TextXAlignment.Right
	valLabel.Parent = gaugesFrame

	local bg = Instance.new("Frame")
	bg.Name = name .. "BG"
	bg.Size = UDim2.new(1, -16, 0, 10)
	bg.Position = UDim2.new(0, 8, 0, yPos + 14)
	bg.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
	bg.BorderSizePixel = 0
	bg.Parent = gaugesFrame

	local bCorner = Instance.new("UICorner")
	bCorner.CornerRadius = UDim.new(0, 3)
	bCorner.Parent = bg

	local fill = Instance.new("Frame")
	fill.Name = name .. "Fill"
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = barColor
	fill.BorderSizePixel = 0
	fill.Parent = bg

	local fCorner = Instance.new("UICorner")
	fCorner.CornerRadius = UDim.new(0, 3)
	fCorner.Parent = fill

	return fill, valLabel
end

local hpFill, hpVal = createBar("HP", 8, COLOR_HP_GREEN, "COMMAND CORE HP")
local shieldFill, shieldVal = createBar("Shield", 40, COLOR_SHIELD, "DEFLECTOR SHIELD")
local energyFill, energyVal = createBar("Energy", 72, COLOR_ENERGY, "CAPACITOR POWER")

-----------------------------------------------------------------------------
-- 5. KILLFEED TICKER (TOP RIGHT)
-----------------------------------------------------------------------------
local killfeedFrame = Instance.new("Frame")
killfeedFrame.Name = "KillFeed"
killfeedFrame.Size = UDim2.new(0, 220, 0, 150)
killfeedFrame.Position = UDim2.new(1, -230, 0, 12)
killfeedFrame.BackgroundTransparency = 1
killfeedFrame.Parent = hudGui

local killfeedLayout = Instance.new("UIListLayout")
killfeedLayout.SortOrder = Enum.SortOrder.LayoutOrder
killfeedLayout.Padding = UDim.new(0, 4)
killfeedLayout.Parent = killfeedFrame

local function addKillfeedItem(killer: string, victim: string)
	local item = Instance.new("Frame")
	item.Size = UDim2.new(1, 0, 0, 22)
	item.BackgroundColor3 = COLOR_BG
	item.BackgroundTransparency = 0.3
	item.BorderSizePixel = 0
	item.Parent = killfeedFrame

	local iCorner = Instance.new("UICorner")
	iCorner.CornerRadius = UDim.new(0, 4)
	iCorner.Parent = item

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -8, 1, 0)
	lbl.Position = UDim2.new(0, 4, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = killer .. " ⚔️ " .. victim
	lbl.TextColor3 = Color3.fromRGB(240, 240, 240)
	lbl.TextSize = 10
	lbl.Font = Enum.Font.GothamBold
	lbl.TextXAlignment = Enum.TextXAlignment.Right
	lbl.Parent = item

	task.delay(4.0, function()
		if item.Parent then
			local tween = TweenService:Create(item, TweenInfo.new(0.5), { BackgroundTransparency = 1 })
			local textTween = TweenService:Create(lbl, TweenInfo.new(0.5), { TextTransparency = 1 })
			tween:Play()
			textTween:Play()
			task.wait(0.5)
			item:Destroy()
		end
	end)
end

-----------------------------------------------------------------------------
-- 6. TAB LEADERBOARD OVERLAY
-----------------------------------------------------------------------------
local leaderboardFrame = Instance.new("Frame")
leaderboardFrame.Name = "LeaderboardOverlay"
leaderboardFrame.Size = UDim2.new(0, 520, 0, 320)
leaderboardFrame.Position = UDim2.new(0.5, -260, 0.5, -160)
leaderboardFrame.BackgroundColor3 = COLOR_BG
leaderboardFrame.BackgroundTransparency = 0.15
leaderboardFrame.Visible = false
leaderboardFrame.BorderSizePixel = 0
leaderboardFrame.Parent = hudGui

local lbCorner = Instance.new("UICorner")
lbCorner.CornerRadius = UDim.new(0, 8)
lbCorner.Parent = leaderboardFrame

local lbStroke = Instance.new("UIStroke")
lbStroke.Color = COLOR_BORDER
lbStroke.Thickness = 1.5
lbStroke.Parent = leaderboardFrame

local lbTitle = Instance.new("TextLabel")
lbTitle.Size = UDim2.new(1, 0, 0, 32)
lbTitle.BackgroundTransparency = 1
lbTitle.Text = "SECTOR COMBAT LEADERBOARD"
lbTitle.TextColor3 = COLOR_ACCENT_CYAN
lbTitle.TextSize = 14
lbTitle.Font = Enum.Font.GothamBlack
lbTitle.Parent = leaderboardFrame

local lbScroll = Instance.new("ScrollingFrame")
lbScroll.Size = UDim2.new(1, -24, 1, -44)
lbScroll.Position = UDim2.new(0, 12, 0, 36)
lbScroll.BackgroundTransparency = 1
lbScroll.ScrollBarThickness = 4
lbScroll.Parent = leaderboardFrame

local lbLayout = Instance.new("UIListLayout")
lbLayout.SortOrder = Enum.SortOrder.LayoutOrder
lbLayout.Padding = UDim.new(0, 4)
lbLayout.Parent = lbScroll

local function updateLeaderboard()
	for _, c in ipairs(lbScroll:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end

	local getLeaderboardFunc = ReplicatedStorage:FindFirstChild("VoidHunterGetLeaderboard")
	if getLeaderboardFunc and getLeaderboardFunc:IsA("RemoteFunction") then
		local ok, data = pcall(function() return getLeaderboardFunc:InvokeServer() end)
		if ok and data and data.Leaderboard then
			for idx, stat in ipairs(data.Leaderboard) do
				local row = Instance.new("Frame")
				row.Size = UDim2.new(1, 0, 0, 24)
				row.BackgroundColor3 = (stat.Team == "Red") and Color3.fromRGB(60, 25, 25) or Color3.fromRGB(25, 45, 75)
				row.BackgroundTransparency = 0.4
				row.BorderSizePixel = 0
				row.Parent = lbScroll

				local rCorner = Instance.new("UICorner")
				rCorner.CornerRadius = UDim.new(0, 4)
				rCorner.Parent = row

				local pName = Instance.new("TextLabel")
				pName.Size = UDim2.new(0, 180, 1, 0)
				pName.Position = UDim2.new(0, 8, 0, 0)
				pName.BackgroundTransparency = 1
				pName.Text = tostring(idx) .. ". " .. stat.PlayerName .. " (" .. stat.Team .. ")"
				pName.TextColor3 = (stat.Team == "Red") and COLOR_RED_TEAM or COLOR_BLUE_TEAM
				pName.TextSize = 11
				pName.Font = Enum.Font.GothamBold
				pName.TextXAlignment = Enum.TextXAlignment.Left
				pName.Parent = row

				local statsText = Instance.new("TextLabel")
				statsText.Size = UDim2.new(1, -200, 1, 0)
				statsText.Position = UDim2.new(0, 190, 0, 0)
				statsText.BackgroundTransparency = 1
				statsText.Text = "K: " .. tostring(stat.Kills) .. "  |  D: " .. tostring(stat.Deaths) .. "  |  DMG: " .. tostring(stat.DamageDealt) .. "  |  SCORE: " .. tostring(stat.Score)
				statsText.TextColor3 = Color3.fromRGB(230, 230, 230)
				statsText.TextSize = 10
				statsText.Font = Enum.Font.Gotham
				statsText.TextXAlignment = Enum.TextXAlignment.Right
				statsText.Parent = row
			end
		end
	end
end

-- Toggle Leaderboard with TAB
UserInputService.InputBegan:Connect(function(input, gpe)
	if not gpe and input.KeyCode == Enum.KeyCode.Tab then
		leaderboardFrame.Visible = not leaderboardFrame.Visible
		if leaderboardFrame.Visible then
			updateLeaderboard()
		end
	end
end)

-----------------------------------------------------------------------------
-- 7. EVENT LISTENERS
-----------------------------------------------------------------------------
local MatchStateEvent = ReplicatedStorage:WaitForChild("VoidHunterMatchState", 5)
if MatchStateEvent then
	MatchStateEvent.OnClientEvent:Connect(function(data)
		phaseLabel.Text = data.Phase:upper() .. " - ROUND " .. tostring(data.RoundNumber or 1)
		local mins = math.floor(data.TimeRemaining / 60)
		local secs = data.TimeRemaining % 60
		timerLabel.Text = string.format("%02d:%02d", mins, secs)
		redScoreLabel.Text = "RED  " .. tostring(data.RedScore)
		blueScoreLabel.Text = tostring(data.BlueScore) .. "  BLUE"
	end)
end

local MatchNotificationEvent = ReplicatedStorage:WaitForChild("VoidHunterMatchNotification", 5)
if MatchNotificationEvent then
	MatchNotificationEvent.OnClientEvent:Connect(function(info)
		notifTitle.Text = info.Title or "ALERT"
		notifSub.Text = info.Subtitle or ""
		notifBanner.Visible = true

		if info.Type == "Victory" then
			notifStroke.Color = COLOR_GOLD_SALVAGE
			notifTitle.TextColor3 = COLOR_GOLD_SALVAGE
		else
			notifStroke.Color = COLOR_ACCENT_CYAN
			notifTitle.TextColor3 = COLOR_ACCENT_CYAN
		end

		task.delay(info.Duration or 3.5, function()
			notifBanner.Visible = false
		end)
	end)
end

local KillFeedEvent = ReplicatedStorage:WaitForChild("VoidHunterKillFeed", 5)
if KillFeedEvent then
	KillFeedEvent.OnClientEvent:Connect(function(killer, victim)
		addKillfeedItem(killer, victim)
	end)
end

-----------------------------------------------------------------------------
-- 8. REAL-TIME RADAR & GAUGES HEARTBEAT LOOP
-----------------------------------------------------------------------------
RunService.Heartbeat:Connect(function()
	local ship = nil
	for _, c in ipairs(workspace:GetChildren()) do
		if c:IsA("Model") and c:GetAttribute("IsShip") then
			local s = c:FindFirstChildWhichIsA("VehicleSeat")
			if s and s.Occupant and s.Occupant.Parent == LocalPlayer.Character then
				ship = c
				break
			end
		end
	end

	if not ship then
		radarContainer.Visible = false
		gaugesFrame.Visible = false
		return
	end

	radarContainer.Visible = true
	gaugesFrame.Visible = true

	local shipPos = ship.PrimaryPart and ship.PrimaryPart.Position or ship:GetPivot().Position
	local shipForward = ship.PrimaryPart and ship.PrimaryPart.CFrame.LookVector or Vector3.new(0, 0, 1)
	local shipYaw = math.atan2(shipForward.X, shipForward.Z)

	-- 1. Read Command Core HP
	local coreHP = 250
	local coreMaxHP = 250
	for _, c in ipairs(ship:GetDescendants()) do
		if c:IsA("BasePart") and c:GetAttribute("IsCore") then
			coreHP = c:GetAttribute("ComponentHP") or 250
			break
		end
	end
	local hpRatio = math.clamp(coreHP / coreMaxHP, 0, 1)
	hpFill.Size = UDim2.new(hpRatio, 0, 1, 0)
	hpVal.Text = tostring(math.floor(coreHP)) .. " / " .. tostring(coreMaxHP)

	-- 2. Read Shield & Energy
	local shieldHP = ship:GetAttribute("ShieldHP") or 150
	local maxShield = 150
	local shieldRatio = math.clamp(shieldHP / maxShield, 0, 1)
	shieldFill.Size = UDim2.new(shieldRatio, 0, 1, 0)
	shieldVal.Text = tostring(math.floor(shieldRatio * 100)) .. "%"

	local energyValRatio = ship:GetAttribute("EnergyPercent") or 0.85
	energyFill.Size = UDim2.new(energyValRatio, 0, 1, 0)
	energyVal.Text = (energyValRatio <= 0.05) and "BROWNOUT" or (tostring(math.floor(energyValRatio * 100)) .. "%")
	energyFill.BackgroundColor3 = (energyValRatio <= 0.05) and Color3.fromRGB(255, 50, 50) or COLOR_ENERGY

	-- 3. Clear dynamic radar blips
	for _, child in ipairs(radarContainer:GetChildren()) do
		if child.Name == "RadarBlip" then
			child:Destroy()
		end
	end

	-- 4. Plot Radar Entities (Ships, Debris, Asteroids)
	local halfRad = RADAR_SIZE / 2
	local maxDisplayRadius = halfRad - 8

	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Model") and obj:GetAttribute("IsShip") and obj ~= ship then
			local objPos = obj.PrimaryPart and obj.PrimaryPart.Position or obj:GetPivot().Position
			local relPos = objPos - shipPos
			local dist = math.sqrt(relPos.X^2 + relPos.Z^2)

			if dist <= RADAR_RANGE and dist > 1.0 then
				local normX = relPos.X / RADAR_RANGE
				local normZ = relPos.Z / RADAR_RANGE

				-- Rotate relative to ship forward heading
				local rotX = normX * math.cos(-shipYaw) - normZ * math.sin(-shipYaw)
				local rotY = normX * math.sin(-shipYaw) + normZ * math.cos(-shipYaw)

				local blipX = halfRad + rotX * maxDisplayRadius
				local blipY = halfRad - rotY * maxDisplayRadius

				local isEnemy = (obj:GetAttribute("Team") ~= LocalPlayer:GetAttribute("Team"))
				local blip = Instance.new("Frame")
				blip.Name = "RadarBlip"
				blip.Size = UDim2.new(0, 5, 0, 5)
				blip.Position = UDim2.new(0, blipX - 2.5, 0, blipY - 2.5)
				blip.BackgroundColor3 = isEnemy and COLOR_RED_TEAM or COLOR_BLUE_TEAM
				blip.BorderSizePixel = 0
				blip.ZIndex = 4
				blip.Parent = radarContainer

				local bCorn = Instance.new("UICorner")
				bCorn.CornerRadius = UDim.new(1, 0)
				bCorn.Parent = blip
			end
		end
	end
end)

print("VoidHunter Tactical HUD & Radar initialized successfully.")
