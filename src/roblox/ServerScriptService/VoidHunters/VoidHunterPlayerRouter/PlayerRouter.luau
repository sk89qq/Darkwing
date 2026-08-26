-- VoidHunterPlayerRouter.lua
-- Routes players to battle world and attaches them to ships permanently

local PlayerRouter = {}

local Players = game:GetService("Players")
local Workspace = game.Workspace

local PLAYER_OFFSET = Vector3.new(0, 5, 0)

function PlayerRouter.TeleportPlayerToShip(player)
	local shipName = player:GetAttribute("CurrentShip")
	if not shipName then
		warn(player.Name .. " has no CurrentShip attribute")
		return false
	end
	
	local shipsFolder = Workspace:FindFirstChild("Ships")
	if not shipsFolder then
		warn("Ships folder not found in Workspace")
		return false
	end
	
	local playerShip = shipsFolder:FindFirstChild(shipName)
	if not playerShip then
		warn("Ship " .. shipName .. " not found for " .. player.Name)
		return false
	end
	
	local character = player.Character
	if not character or not character.PrimaryPart then
		warn(player.Name .. " character not loaded")
		return false
	end
	
	local shipCore = playerShip:FindFirstChild("Core")
	if shipCore then
		character:MoveTo(shipCore.Position + PLAYER_OFFSET)
	else
		character:MoveTo(playerShip:GetPivot().Position + PLAYER_OFFSET)
	end
	
	PlayerRouter.AttachPlayerToShip(character, playerShip)
	print(player.Name .. " teleported to ship: " .. shipName)
	return true
end

function PlayerRouter.AttachPlayerToShip(character, ship)
	local shipCore = ship:FindFirstChild("Core") or ship.PrimaryPart
	if not shipCore then return end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	-- Remove any existing weld first
	local existing = humanoidRootPart:FindFirstChild("ShipWeld")
	if existing then existing:Destroy() end
	
	local weld = Instance.new("WeldConstraint")
	weld.Name = "ShipWeld"
	weld.Part0 = humanoidRootPart
	weld.Part1 = shipCore
	weld.Parent = humanoidRootPart
	print(character.Name .. " welded to ship")
end

function PlayerRouter.DetachPlayerFromShip(character)
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	local weld = humanoidRootPart:FindFirstChild("ShipWeld")
	if weld then
		weld:Destroy()
		print(character.Name .. " detached from ship")
	end
end

function PlayerRouter.Init()
	task.spawn(function()
		local GameManager = require(game.ServerScriptService.VoidHunters:WaitForChild("VoidHunterGameManager"))
		local lastState = ""
		while true do
			local state = GameManager.GetState()
			if state == "Active" and lastState ~= "Active" then
				task.wait(1) -- Give characters time to load
				for _, player in ipairs(Players:GetPlayers()) do
					if player.Character then
						PlayerRouter.TeleportPlayerToShip(player)
					end
				end
			end
			lastState = state
			task.wait(1)
		end
	end)
end

return PlayerRouter
