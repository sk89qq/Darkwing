-- VH CONTROLLER
-- Top-down 2D space simulation with build mode
-- LMB fires ALL weapons at cursor with 55deg aiming arc
-- RMB = drag/detach only. B=build mode toggle, R=save blueprint
-- Build mode: drag parts within radius, auto-snap to connection points
--
-- CONTROLS:
--   W/S = Forward/Backward thrust
--   A/D = Rotate left/right
--   Q/E = Strafe left/right
--   Space = Boost (2x speed)
--   Shift = Brake/reverse thrust
--   F = Fire scrambler pulse
--   G = Fire grappling hook / Recall grapple
--   H = Activate repair mode
--   J = Activate self-destruct
--   K = Activate booster
--   T = Toggle shield on/off
--   Y = Launch fighters
--   B = Toggle build mode
--   R = Save blueprint (build mode)
--   L = Load blueprint (build mode)
--   Tab = Cycle blueprint slots (build mode)
--   LMB = Fire weapons / Pick up & drop parts (build mode)
--   RMB = Detach ship part (build mode)

local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Repl = game:GetService("ReplicatedStorage")

local pl = Players.LocalPlayer
local cam = workspace.CurrentCamera
local ms = pl:GetMouse()

local FW = Repl:FindFirstChild("VoidHunterFireWeapon")
local FS = Repl:FindFirstChild("VoidHunterFireScrambler")
local PA = Repl:FindFirstChild("VoidHunterPlayerAction")
local KF = Repl:FindFirstChild("VoidHunterKillFeed")
local RT = Repl:FindFirstChild("VoidHunterRespawnTimer")
local BE = Repl:FindFirstChild("VoidHunterBuilder")
if not BE then BE=Instance.new("RemoteEvent");BE.Name="VoidHunterBuilder";BE.Parent=Repl end

local SS = Repl:FindFirstChild("VoidHunterSelectShip")
if not SS then SS=Instance.new("RemoteEvent");SS.Name="VoidHunterSelectShip";SS.Parent=Repl end

local SaveBP = Repl:FindFirstChild("VoidHunterSaveBlueprint")
local LoadBP = Repl:FindFirstChild("VoidHunterLoadBlueprint")

-- Load Physics Modules
local PhysicsConfig = require(Repl.Shared.Physics.PhysicsConfig)
local RigidBody2D = require(Repl.Shared.Physics.RigidBody2D)
local ShipSocketGraph = require(Repl.Shared.ShipSocketGraph)

-- Load Components module for connection system
local Components = Repl:FindFirstChild("VoidHunterComponents")
if Components then
	Components = require(Components)
end

-- State
local inShip = false
local ship = nil
local shipBody = nil -- RigidBody2D instance
local shipGraph = nil -- ShipSocketGraph instance
local held = nil
local buildMode = false
local TOP_DOWN_HEIGHT = 80
local BUILD_RADIUS = 300
local DRAG_RADIUS = 1500
local SNAP_DISTANCE = 5

-- Blueprint GUI
local blueprintGui = nil
local selectedSlot = 1
local blueprintSlots = {"Slot1", "Slot2", "Slot3"}
local unlockedSlots = 1 -- Default 1 slot, 2 more unlockable

-- Kill feed display
local killFeedFrames = {}
local killFeedGui = nil

-- Respawn timer display
local respawnGui = nil

-- Invulnerability indicator
local invulnGui = nil

-- Setup PvP HUD elements
local function setupPvPHUD()
	if killFeedGui then return end
	
	local pg = pl:FindFirstChild("PlayerGui")
	if not pg then return end
	
	-- Kill Feed GUI
	killFeedGui = Instance.new("ScreenGui")
	killFeedGui.Name = "PvPHUD"
	killFeedGui.ResetOnSpawn = false
	killFeedGui.Parent = pg
	
	-- Kill feed (top right)
	local kfFrame = Instance.new("Frame")
	kfFrame.Name = "KillFeed"
	kfFrame.Size = UDim2.new(0, 250, 0, 100)
	kfFrame.Position = UDim2.new(1, -260, 0, 10)
	kfFrame.BackgroundTransparency = 1
	kfFrame.Parent = killFeedGui
	
	-- Respawn timer (center screen)
	respawnGui = Instance.new("TextLabel")
	respawnGui.Name = "RespawnTimer"
	respawnGui.Size = UDim2.new(0, 200, 0, 50)
	respawnGui.Position = UDim2.new(0.5, -100, 0.5, -25)
	respawnGui.BackgroundTransparency = 0.5
	respawnGui.BackgroundColor3 = Color3.new(0, 0, 0)
	respawnGui.TextColor3 = Color3.new(1, 1, 1)
	respawnGui.TextSize = 24
	respawnGui.Font = Enum.Font.SourceSansBold
	respawnGui.Text = ""
	respawnGui.Visible = false
	respawnGui.Parent = killFeedGui
	Instance.new("UICorner").CornerRadius = UDim.new(0, 8)
	Instance.new("UICorner").Parent = respawnGui
	
	-- Invulnerability indicator
	invulnGui = Instance.new("TextLabel")
	invulnGui.Name = "InvulnIndicator"
	invulnGui.Size = UDim2.new(0, 160, 0, 30)
	invulnGui.Position = UDim2.new(0.5, -80, 0, 80)
	invulnGui.BackgroundTransparency = 0.5
	invulnGui.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
	invulnGui.TextColor3 = Color3.new(1, 1, 1)
	invulnGui.TextSize = 16
	invulnGui.Font = Enum.Font.SourceSansBold
	invulnGui.Text = "SHIELD ACTIVE"
	invulnGui.Visible = false
	invulnGui.Parent = killFeedGui
	Instance.new("UICorner").CornerRadius = UDim.new(0, 6)
	Instance.new("UICorner").Parent = invulnGui
	
	-- K/D/A display
	local kdaLabel = Instance.new("TextLabel")
	kdaLabel.Name = "KDA"
	kdaLabel.Size = UDim2.new(0, 120, 0, 20)
	kdaLabel.Position = UDim2.new(0, 10, 0, 10)
	kdaLabel.BackgroundTransparency = 1
	kdaLabel.TextColor3 = Color3.new(1, 1, 1)
	kdaLabel.TextSize = 14
	kdaLabel.Font = Enum.Font.SourceSansBold
	kdaLabel.Text = "K:0 D:0 A:0"
	kdaLabel.TextXAlignment = Enum.TextXAlignment.Left
	kdaLabel.Parent = killFeedGui
end

-- Add kill feed message
local function addKillFeed(killer, victim)
	if not killFeedGui then return end
	local kfFrame = killFeedGui:FindFirstChild("KillFeed")
	if not kfFrame then return end
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 18)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 0.8, 0.3)
	label.TextSize = 13
	label.Font = Enum.Font.SourceSansBold
	label.Text = killer .. " > " .. victim
	label.TextXAlignment = Enum.TextXAlignment.Right
	label.Parent = kfFrame
	
	-- Shift existing messages down
	for _, existing in ipairs(kfFrame:GetChildren()) do
		if existing:IsA("TextLabel") and existing ~= label then
			existing.Position = existing.Position + UDim2.new(0, 0, 0, 20)
		end
	end
	
	-- Remove after 5 seconds
	task.delay(5, function()
		if label.Parent then label:Destroy() end
	end)
end

-- Listen for kill feed events
if KF then
	KF.OnClientEvent:Connect(function(killer, victim)
		addKillFeed(killer, victim)
	end)
end

-- Listen for respawn timer
if RT then
	RT.OnClientEvent:Connect(function(time)
		setupPvPHUD()
		if respawnGui then
			respawnGui.Visible = true
			task.spawn(function()
				for i = time, 1, -1 do
					if not respawnGui.Parent then break end
					respawnGui.Text = "Respawning in " .. i .. "..."
					task.wait(1)
				end
				respawnGui.Visible = false
			end)
		end
	end)
end

-- Listen for invulnerability updates
local InvulnEvent = Repl:FindFirstChild("VoidHunterInvulnUpdate")
if InvulnEvent then
	InvulnEvent.OnClientEvent:Connect(function(shipModel, isActive)
		setupPvPHUD()
		if invulnGui then
			invulnGui.Visible = isActive
			if isActive then
				task.delay(3, function()
					if invulnGui then invulnGui.Visible = false end
				end)
			end
		end
	end)
end

-- Build or refresh RigidBody2D for a ship model
local function rebuildShipPhysics(m)
	if not m then return nil end
	local pivot = m:GetPivot()
	local pos3 = pivot.Position
	local _, yaw, _ = pivot:ToEulerAnglesYXZ()
	
	local rb = RigidBody2D.new(Vector2.new(pos3.X, pos3.Z), -yaw, "PlayerShip_" .. m.Name)
	rb.FixedY = PhysicsConfig.FIXED_Y_ELEVATION
	rb:ClearMassPoints()
	
	-- Populate mass points for all components
	local corePart = m.PrimaryPart
	if not corePart then
		for _, desc in ipairs(m:GetDescendants()) do
			if desc:IsA("BasePart") and desc:GetAttribute("IsCore") then
				corePart = desc
				m.PrimaryPart = desc
				break
			end
		end
	end
	corePart = corePart or m:FindFirstChildWhichIsA("BasePart")
	local coreCF = corePart and corePart.CFrame or pivot
	
	for _, part in ipairs(m:GetDescendants()) do
		if part:IsA("BasePart") and not part:GetAttribute("IsDebris") then
			local relPos = coreCF:PointToObjectSpace(part.Position)
			local local2D = Vector2.new(relPos.X, relPos.Z)
			
			local mass = PhysicsConfig.DEFAULT_PIECE_MASS
			local pName = part.Name
			if part:GetAttribute("IsCore") or pName == "VehicleSeat" or pName == "CommandCore" then
				mass = PhysicsConfig.BASE_CHASSIS_MASS
			elseif string.find(pName, "Heavy") or string.find(pName, "Reactor") then
				mass = 35
			elseif string.find(pName, "Medium") or string.find(pName, "Shield") then
				mass = 20
			elseif string.find(pName, "Thruster") or string.find(pName, "Weapon") or string.find(pName, "Launcher") or string.find(pName, "Driver") then
				mass = 15
			else
				mass = 10
			end
			
			rb:AddMassPoint(mass, local2D, mass * 0.5, part.Name)
		end
	end
	
	rb:RecalculateMassProperties()
	rb:BindModel(m, PhysicsConfig.FIXED_Y_ELEVATION)
	return rb
end

-- Enter/Exit Ship
local function exitShip()
	if not inShip then return end
	if held then 
		held:SetAttribute("IsDebris", true)
		held = nil
	end
	inShip = false
	ship = nil
	shipBody = nil
	shipGraph = nil
	buildMode = false
	cam.CameraType = Enum.CameraType.Custom
	local ch2 = pl.Character
	if ch2 and ch2:FindFirstChild("Humanoid") then
		cam.CameraSubject = ch2.Humanoid
	end
	
	-- Hide blueprint GUI
	if blueprintGui then
		blueprintGui.Visible = false
	end
end

local function enterShip(m)
	if inShip then exitShip() end
	ship = m
	inShip = true
	shipGraph = ShipSocketGraph.new(m)
	shipBody = rebuildShipPhysics(m)
	cam.CameraType = Enum.CameraType.Scriptable
end

-- Toggle build mode
local function toggleBuildMode()
	if not inShip or not ship then return end
	
	buildMode = not buildMode
	
	-- Refresh mass distribution & socket graph when transitioning build mode
	if ship then
		if not shipGraph then
			shipGraph = ShipSocketGraph.new(ship)
		else
			shipGraph:RebuildFromModel(ship)
		end
		shipBody = rebuildShipPhysics(ship)
	end
	
	-- Enable/disable glow on connection points
	for _, part in ipairs(ship:GetDescendants()) do
		if part:IsA("BasePart") then
			if Components and Components.SetGlowEnabled then
				Components.SetGlowEnabled(part, buildMode)
			end
			-- Also check for attachments directly on the part (for mesh models)
			for _, child in ipairs(part:GetChildren()) do
				if child:IsA("Attachment") and string.sub(child.Name, 1, 9) == "InConnect" then
					local glow = child:FindFirstChild("Glow")
					if glow then
						glow.Enabled = buildMode
					end
				end
			end
		end
	end
	
	-- Show/hide blueprint GUI
	if blueprintGui then
		blueprintGui.Visible = buildMode
	end
	
	print("Build mode:", buildMode and "ON" or "OFF")
end

-- Camera (Top-Down 2D View)
local function cup()
	if not inShip or not ship then
		-- Reset to default camera when not in ship
		cam.CameraType = Enum.CameraType.Custom
		return
	end
	
	-- Use GetPivot() for reliable position with nested models
	local pivot = ship:GetPivot()
	local po = pivot.Position
	
	-- Force top-down camera
	cam.CameraType = Enum.CameraType.Scriptable
	
	-- Top-down view: camera directly above, looking straight down
	-- This creates the 2D space simulation effect
	cam.CFrame = CFrame.lookAt(
		Vector3.new(po.X, TOP_DOWN_HEIGHT, po.Z), -- Camera position (high above)
		Vector3.new(po.X, 0, po.Z), -- Look at point (ship position on ground)
		Vector3.new(0, 0, -1) -- Up vector (forward is -Z)
	)
end

-- Movement (2D Top-Down with vectored thrust & RigidBody2D simulation)
local function mup(dt)
	if not inShip or not ship then return end
	if not shipBody then
		shipBody = rebuildShipPhysics(ship)
		if not shipBody then return end
	end
	
	-- Read input flags
	local forwardThrust = 0
	local strafeThrust = 0
	local turnTorque = 0
	local isBoosting = UIS:IsKeyDown(Enum.KeyCode.Space)
	local isBraking = UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)
	
	-- W/S = Forward / Reverse
	if UIS:IsKeyDown(Enum.KeyCode.W) then forwardThrust += 1 end
	if UIS:IsKeyDown(Enum.KeyCode.S) then forwardThrust -= 1 end
	
	-- Q/E = Strafe Left / Right
	if UIS:IsKeyDown(Enum.KeyCode.Q) then strafeThrust -= 1 end
	if UIS:IsKeyDown(Enum.KeyCode.E) then strafeThrust += 1 end
	
	-- A/D = Yaw Rotation
	if UIS:IsKeyDown(Enum.KeyCode.A) then turnTorque -= 1 end
	if UIS:IsKeyDown(Enum.KeyCode.D) then turnTorque += 1 end
	
	local thrustMult = isBoosting and 2.2 or 1.0
	local baseForce = 2800.0 * thrustMult
	local baseTorque = 12000.0 * thrustMult

	-- 1. Apply Vectored Thrust on 2D Body
	if forwardThrust ~= 0 then
		local forwardDir = shipBody:GetForwardVector2D()
		shipBody:AddForce(forwardDir * (forwardThrust * baseForce))
	end
	
	if strafeThrust ~= 0 then
		local rightDir = shipBody:GetRightVector2D()
		shipBody:AddForce(rightDir * (strafeThrust * baseForce * 0.75))
	end
	
	if turnTorque ~= 0 then
		shipBody:AddTorque(turnTorque * baseTorque)
	end
	
	-- 2. Apply Inertial Damping (AlterOrb exponential decay)
	if isBraking then
		shipBody:ApplyInertialDamping(dt, PhysicsConfig.BRAKE_LINEAR_DAMPING, PhysicsConfig.BRAKE_ANGULAR_DAMPING)
	else
		shipBody:ApplyInertialDamping(dt, PhysicsConfig.LINEAR_DAMPING, PhysicsConfig.ANGULAR_DAMPING)
	end
	
	-- 3. Step RigidBody2D Kinematics
	shipBody:Integrate(dt, isBoosting)
	
	-- 4. Sync transform to visual Roblox model
	shipBody:SyncToVisual(PhysicsConfig.FIXED_Y_ELEVATION)
end

-- Seats
local function cs(m)
	local s = m:FindFirstChildWhichIsA("VehicleSeat")
	if not s then return end
	s:GetPropertyChangedSignal("Occupant"):Connect(function()
		local o = s.Occupant
		if o and o.Parent==pl.Character then enterShip(m)
		elseif inShip and ship==m then exitShip() end
	end)
	if s.Occupant and s.Occupant.Parent==pl.Character then enterShip(m) end
end
workspace.ChildAdded:Connect(function(c) task.wait(); cs(c) end)
for _,c in ipairs(workspace:GetChildren()) do cs(c) end

-- ProximityPrompt for ship entry
local function setupPrompt(part)
	local prompt = part:FindFirstChildWhichIsA("ProximityPrompt")
	if not prompt then return end
	
	prompt.Triggered:Connect(function(player)
		if player ~= pl then return end
		
		-- Walk up the hierarchy to find the ship model (marked with IsShip attribute)
		local shipModel = part.Parent
		while shipModel and shipModel ~= workspace do
			if shipModel:IsA("Model") and shipModel:GetAttribute("IsShip") then
				break
			end
			shipModel = shipModel.Parent
		end
		if not shipModel or not shipModel:GetAttribute("IsShip") then return end
		
		if inShip then
			exitShip()
		else
			-- Find the seat and sit in it
			local seat = shipModel:FindFirstChildWhichIsA("VehicleSeat")
			if seat then
				local character = pl.Character
				if character then
					local humanoid = character:FindFirstChild("Humanoid")
					if humanoid then
						humanoid.Sit = true
						seat:Sit(humanoid)
					end
				end
			end
			enterShip(shipModel)
		end
	end)
end

-- Setup prompts on existing parts
for _, obj in ipairs(workspace:GetDescendants()) do
	if obj:IsA("BasePart") then
		setupPrompt(obj)
	end
end
workspace.DescendantAdded:Connect(function(desc)
	if desc:IsA("ProximityPrompt") then
		task.wait()
		setupPrompt(desc.Parent)
	end
end)

-- Zoom (disabled for top-down - fixed height)
-- Camera height is fixed for consistent 2D view
ms.WheelForward:Connect(function() 
	if inShip then 
		TOP_DOWN_HEIGHT = math.max(40, TOP_DOWN_HEIGHT - 10)
	end 
end)
ms.WheelBackward:Connect(function() 
	if inShip then 
		TOP_DOWN_HEIGHT = math.min(150, TOP_DOWN_HEIGHT + 10)
	end 
end)

-- ===== WEAPON AIMING =====
-- Weapons rotate freely 360 degrees on XZ plane to face cursor
-- LMB fires ALL weapons at their current aimed direction

-- Get aim CFrame for a weapon part based on mouse position (360 degree rotation on XZ plane)
local function getAimCF(wp)
	if not ship then return wp.CFrame end
	local mPos = ms.Hit.Position
	-- Weapon's position in world
	local wPos = wp.Position
	-- Direction from weapon to mouse on XZ plane (flat 2D)
	local toMouse = Vector3.new(mPos.X - wPos.X, 0, mPos.Z - wPos.Z)
	if toMouse.Magnitude < 0.1 then
		return wp.CFrame -- No movement if mouse is on top of weapon
	end
	toMouse = toMouse.Unit
	-- Create CFrame looking at mouse position (flat on XZ plane)
	local aimCF = CFrame.lookAt(wPos, wPos + toMouse, Vector3.new(0, 1, 0))
	return aimCF
end

-- Fire primary weapons on LMB (Kinetic, Mass Driver, Laser)
local function fireAll()
	if not inShip or not ship or not FW then return end
	for _,c in ipairs(ship:GetDescendants()) do
		if not c:IsA("BasePart") then continue end
		local n = c.Name
		local isPrimary = (n=="MassDriver" or n=="Mass Driver" or n=="Laser" or n=="PlasmaTurret" or n=="Plasma Turret" or n=="PlasmaBall" or n=="Plasma Ball Launcher" or n=="MissileLauncher" or n=="Missile Launcher")
		if isPrimary then
			local aimDir = getAimCF(c).LookVector
			FW:FireServer(ship, c.Name, aimDir)
		end
	end
end

-- Fire secondary heavy ordnance on RMB (Missiles, Plasma Artillery, Scrambler)
local function fireSecondary()
	if not inShip or not ship or not FW then return end
	for _,c in ipairs(ship:GetDescendants()) do
		if not c:IsA("BasePart") then continue end
		local n = c.Name
		local isSecondary = (n=="MissileLauncher" or n=="Missile Launcher" or n=="PlasmaBall" or n=="Plasma Ball Launcher")
		if isSecondary then
			local aimDir = getAimCF(c).LookVector
			FW:FireServer(ship, c.Name, aimDir)
		end
	end
end

-- Visual snap indicator (created once)
local snapIndicator = nil
local function getSnapIndicator()
	if not snapIndicator then
		snapIndicator = Instance.new("Part")
		snapIndicator.Name = "SnapIndicator"
		snapIndicator.Shape = Enum.PartType.Cylinder
		snapIndicator.Size = Vector3.new(0.5, 3, 3)
		snapIndicator.Color = Color3.new(0, 1, 1)
		snapIndicator.Material = Enum.Material.Neon
		snapIndicator.Anchored = true
		snapIndicator.CanCollide = false
		snapIndicator.CastShadow = false
		snapIndicator.Transparency = 0.5
		snapIndicator.Parent = workspace
	end
	return snapIndicator
end

-- Drag part in build mode
RS.RenderStepped:Connect(function()
	if held and buildMode and ship then
		local shipPos = ship.PrimaryPart and ship.PrimaryPart.Position or ship:GetPivot().Position
		local mousePos = ms.Hit.Position
		
		-- Clamp to build radius
		local toMouse = mousePos - shipPos
		if toMouse.Magnitude > BUILD_RADIUS then
			toMouse = toMouse.Unit * BUILD_RADIUS
			mousePos = shipPos + toMouse
		end
		
		-- Keep at fixed height
		held.Position = Vector3.new(mousePos.X, 3.5, mousePos.Z)
		held.Anchored = true
		
		-- Find nearest connection point and highlight it
		if Components then
			local nearestPart, nearestPoint, nearestDist, nearestTargetBase = nil, nil, math.huge, nil
			
			for _, part in ipairs(ship:GetDescendants()) do
				if part:IsA("BasePart") and part ~= held and not part:IsA("VehicleSeat") then
					local partPoint, targetPoint, distance, targetBase = Components.FindNearestConnection(held, part, SNAP_DISTANCE * 3)
					if distance < nearestDist then
						nearestDist = distance
						nearestPart = part
						nearestPoint = targetPoint
						nearestTargetBase = targetBase
					end
				end
			end
			
			-- Visual feedback: show snap indicator at connection point
			local indicator = getSnapIndicator()
			if nearestPart and nearestPoint and nearestDist < SNAP_DISTANCE * 3 then
				-- Get the target base part for world position
				local targetBase = nearestTargetBase or nearestPart
				if targetBase and targetBase:IsA("BasePart") then
					local worldPos = targetBase.CFrame * nearestPoint.Position
					indicator.CFrame = CFrame.new(worldPos) * CFrame.Angles(0, 0, math.rad(90))
					indicator.Transparency = 0.3 + (nearestDist / (SNAP_DISTANCE * 3)) * 0.5
					indicator.Color = nearestDist < SNAP_DISTANCE * 2 and Color3.new(0, 1, 0) or Color3.new(0, 1, 1)
					indicator.Parent = workspace
				else
					indicator.Parent = nil
				end
			else
				indicator.Parent = nil
			end
		end
	elseif held and not buildMode then
		-- Normal drag (outside build mode)
		local h = ms.Hit.Position
		held.Position = Vector3.new(h.X, 3.5, h.Z)
		held.Anchored = true
		
		-- Hide snap indicator
		if snapIndicator then
			snapIndicator.Parent = nil
		end
	end
	
	-- Hide snap indicator when not holding anything
	if not held and snapIndicator then
		snapIndicator.Parent = nil
	end
end)

-- Input handling
UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	
	-- LMB: Fire weapons OR pick up/drop parts
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local ray = cam:ScreenPointToRay(ms.X, ms.Y)
		local hit = workspace:FindPartOnRay(ray)
		
		if buildMode and held then
			-- Drop part with auto-snap via ShipSocketGraph
			if ship then
				if not shipGraph then
					shipGraph = ShipSocketGraph.new(ship)
				end

				local compTypeName = held:GetAttribute("ComponentType") or held.Name
				local snapCandidate = shipGraph:FindBestSnap(held, compTypeName, SNAP_DISTANCE * 2.5)

				if snapCandidate and snapCandidate.ParentNode and snapCandidate.ParentNode.Part then
					held.CFrame = snapCandidate.TargetCFrame
					held.Anchored = false
					
					-- Attach into graph & create clean WeldConstraint
					shipGraph:AttachComponent(snapCandidate.ParentNode, snapCandidate.ParentSocket, held, compTypeName)
					held:SetAttribute("IsDebris", nil)
					held:SetAttribute("IsDroppedPart", nil)
					print("Snapped and welded", held.Name, "via SocketGraph to", snapCandidate.ParentNode.Part.Name)
				else
					-- Fallback connection check
					local bestPart, bestPoint, bestDist, bestTargetBase = nil, nil, math.huge, nil
					if Components and Components.FindNearestConnection then
						for _, part in ipairs(ship:GetDescendants()) do
							if part:IsA("BasePart") and part ~= held and not part:IsA("VehicleSeat") then
								local partPoint, targetPoint, distance, targetBase = Components.FindNearestConnection(held, part, SNAP_DISTANCE * 2)
								if distance < bestDist then
									bestDist = distance
									bestPart = part
									bestPoint = targetPoint
									bestTargetBase = targetBase
								end
							end
						end
					end

					if bestPart and bestPoint and bestDist < SNAP_DISTANCE * 2 then
						local heldOutConnect = held:FindFirstChild("OutConnect")
						if heldOutConnect and Components.CalculateSnapCFrame then
							local snapCF = Components.CalculateSnapCFrame(held, heldOutConnect, bestPart, bestPoint)
							held.CFrame = snapCF
							held.Anchored = false
							local weldTarget = bestTargetBase or bestPart
							local weld = Instance.new("WeldConstraint")
							weld.Part0 = weldTarget
							weld.Part1 = held
							weld.Parent = held
							held:SetAttribute("IsDebris", nil)
							held:SetAttribute("IsDroppedPart", nil)
						else
							held.Anchored = true
						end
					else
						held.Anchored = true
					end
				end

				-- Recalculate physics mass and COM
				shipBody = rebuildShipPhysics(ship)
				held.Transparency = 0
				held = nil
			end
			return
		end
		
		if buildMode and hit then
			-- Pick up dropped part within drag radius
			local shipPos = ship.PrimaryPart and ship.PrimaryPart.Position or ship:GetPivot().Position
			local distance = (hit.Position - shipPos).Magnitude
			
			if distance <= DRAG_RADIUS then
				local isDroppedPart = hit:GetAttribute("IsDroppedPart") or hit:GetAttribute("IsDebris")
				local isShipPart = ship and hit:IsDescendantOf(ship)
				
				if isDroppedPart or isShipPart then
					held = hit
					held:SetAttribute("IsDebris", nil)
					held.Transparency = 0.3
					
					-- Remove welds if it's a ship part
					if isShipPart and hit.Name ~= "VehicleSeat" and not hit:GetAttribute("IsCore") then
						for _, w in ipairs(hit:GetDescendants()) do
							if w:IsA("WeldConstraint") then w:Destroy() end
						end
						for _, w in ipairs(ship:GetDescendants()) do
							if w:IsA("WeldConstraint") and (w.Part1 == hit or w.Part0 == hit) then
								w:Destroy()
							end
						end
						
						-- Run BFS reachability check to sever newly orphaned pieces
						if shipGraph then
							local severed = shipGraph:SeverUnreachableComponents(workspace)
							if #severed > 0 then
								print("Severed", #severed, "orphaned components into debris")
							end
						end
						shipBody = rebuildShipPhysics(ship)
					end
				end
			end
			return
		end
		
		-- Fire all weapons (when not in build mode)
		if inShip and not buildMode then
			fireAll()
		end
	end
	
	-- RMB: Detach ship part (in build mode) or fire secondary weapons (in combat)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		if buildMode and ship then
			local ray = cam:ScreenPointToRay(ms.X, ms.Y)
			local hit = workspace:FindPartOnRay(ray)
			
			if hit and hit:IsDescendantOf(ship) and hit.Name ~= "VehicleSeat" and not hit:GetAttribute("IsCore") then
				-- Detach part
				hit:SetAttribute("IsDebris", true)
				for _, w in ipairs(hit:GetDescendants()) do
					if w:IsA("WeldConstraint") then w:Destroy() end
				end
				for _, w in ipairs(ship:GetDescendants()) do
					if w:IsA("WeldConstraint") and (w.Part1 == hit or w.Part0 == hit) then
						w:Destroy()
					end
				end

				-- Run BFS reachability to sever any orphaned branches
				if shipGraph then
					local severed = shipGraph:SeverUnreachableComponents(workspace)
					if #severed > 0 then
						print("BFS Severed", #severed, "disconnected parts into debris")
					end
				end
				shipBody = rebuildShipPhysics(ship)
				print("Detached", hit.Name)
			end
		elseif inShip and not buildMode then
			fireSecondary()
		end
	end
	
	-- B: Toggle build mode
	if input.KeyCode == Enum.KeyCode.B and inShip then
		toggleBuildMode()
	end
	
	-- R: Save blueprint
	if input.KeyCode == Enum.KeyCode.R and inShip and buildMode then
		if SaveBP then
			SaveBP:FireServer(blueprintSlots[selectedSlot], ship)
			print("Saved blueprint to", blueprintSlots[selectedSlot])
		end
	end
	
	-- F: Scrambler pulse
	if input.KeyCode == Enum.KeyCode.F and inShip and not buildMode then
		if FS then
			for _, c in ipairs(ship:GetDescendants()) do
				if c:IsA("BasePart") and c.Name == "Scrambler Pulse" then
					FS:FireServer(ship, c.Name)
				end
			end
		end
	end
	
	-- G: Grappling hook fire/recall
	if input.KeyCode == Enum.KeyCode.G and inShip and not buildMode then
		if PA then PA:FireServer("GrappleFire") end
	end
	
	-- H: Repair mode
	if input.KeyCode == Enum.KeyCode.H and inShip and not buildMode then
		if PA then PA:FireServer("RepairMode") end
	end
	
	-- J: Self-destruct
	if input.KeyCode == Enum.KeyCode.J and inShip and not buildMode then
		if PA then PA:FireServer("SelfDestruct") end
	end
	
	-- K: Booster activation
	if input.KeyCode == Enum.KeyCode.K and inShip and not buildMode then
		if PA then PA:FireServer("Booster") end
	end
	
	-- T: Shield toggle
	if input.KeyCode == Enum.KeyCode.T and inShip and not buildMode then
		if PA then
			-- Check current shield state
			local shieldActive = false
			for _, c in ipairs(ship:GetDescendants()) do
				if c:IsA("BasePart") and (c.Name == "ShieldGenerator" or c.Name == "Shield Generator") then
					local bubble = c:FindFirstChild("ShieldBubble", true)
					if bubble then
						shieldActive = bubble:GetAttribute("ShieldActive") or false
					end
				end
			end
			PA:FireServer("ShieldToggle", shieldActive and "deactivate" or "activate")
		end
	end
	
	-- Y: Launch fighters
	if input.KeyCode == Enum.KeyCode.Y and inShip and not buildMode then
		if PA then PA:FireServer("LaunchFighters") end
	end
	
	-- Tab: Cycle blueprint slots
	if input.KeyCode == Enum.KeyCode.Tab and buildMode then
		selectedSlot = selectedSlot % unlockedSlots + 1
		print("Selected slot:", selectedSlot)
	end
	
	-- L: Load blueprint
	if input.KeyCode == Enum.KeyCode.L and inShip and buildMode then
		if LoadBP then
			LoadBP:FireServer(blueprintSlots[selectedSlot])
			print("Loading blueprint from", blueprintSlots[selectedSlot])
		end
	end
end)

-- Weapon rotation: rotate all weapons to face cursor (360 degree on XZ plane)
RS:BindToRenderStep("WeaponAim", Enum.RenderPriority.Character.Value + 1, function()
	if not inShip or not ship or buildMode then return end
	
	for _, c in ipairs(ship:GetDescendants()) do
		if c:IsA("BasePart") then
			local n = c.Name
			-- DroneBay and PointDefence don't rotate (automatic systems)
			local isWep = (n == "MassDriver" or n == "Mass Driver" or n == "PlasmaBall" or n == "Plasma Ball Launcher" or n == "MissileLauncher" or n == "Missile Launcher" or n == "Laser" or n == "PlasmaTurret" or n == "Plasma Turret")
			if isWep then
				local aimCF = getAimCF(c)
				-- Only rotate Y axis, keep position and other axes
				c.CFrame = CFrame.new(c.Position) * CFrame.Angles(0, select(2, aimCF:ToEulerAnglesYXZ()), 0)
			end
		end
	end
end)

RS:BindToRenderStep("ShipCam", Enum.RenderPriority.Camera.Value+1, cup)
RS.Heartbeat:Connect(mup)

-- Setup PvP HUD on spawn
pl.CharacterAdded:Connect(function()
	task.wait(1)
	setupPvPHUD()
end)
task.spawn(setupPvPHUD)

print("VH: WASD=move, Q/E=strafe, Space=boost, Shift=brake, F=scrambler, G=grapple, H=repair, J=self-destruct, K=booster, T=shield, Y=fighters, B=build mode, R=save blueprint")
