-- vhGameManager.lua
-- Central orchestrator: auto-starts when first player joins, no manual Ready gate

local vhGameManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local WaveManager = require(game.ServerScriptService.VoidHunters:WaitForChild("VoidHunterWaveManager"))
local AsteroidSpawner = require(game.ServerScriptService.VoidHunters:WaitForChild("AsteroidSpawner"))
local SyncManager = require(game.ServerScriptService.VoidHunters:WaitForChild("VoidHunterSyncManager"))

local States = { Lobby = "Lobby", Intermission = "Intermission", Active = "Active", GameOver = "GameOver" }
local currentState = States.Lobby
local HUDController = nil  -- injected after init to avoid circular require

local INTERMISSION_DURATION = 5  -- shortened: players see countdown then arena starts
local GAME_OVER_DURATION = 8

function vhGameManager.SetState(newState)
	if currentState == newState then return end
	print(string.format("[GameManager] %s -> %s", currentState, newState))
	currentState = newState
	game.Workspace:SetAttribute("GameState", newState)
end

function vhGameManager.GetState()
	return currentState
end

function vhGameManager.InjectHUD(hud)
	HUDController = hud
end

local function onActive()
	print("[GameManager] ACTIVE - launching wave session")
	if HUDController then HUDController.BroadcastStatus("🚀 BATTLE BEGINS!", 4) end
	WaveManager.RunSession(vhGameManager, HUDController)
end

local function onGameOver(victory)
	-- Cleanup
	WaveManager.Reset()
	if game.Workspace:FindFirstChild("Enemies") then
		for _, e in ipairs(game.Workspace.Enemies:GetChildren()) do e:Destroy() end
	end
	if game.Workspace:FindFirstChild("Asteroids") then
		for _, a in ipairs(game.Workspace.Asteroids:GetChildren()) do a:Destroy() end
	end
	task.wait(GAME_OVER_DURATION)
	vhGameManager.SetState(States.Lobby)
end

local function onIntermission()
	if HUDController then
		for i = INTERMISSION_DURATION, 1, -1 do
			HUDController.BroadcastStatus("⏳ Arena opens in " .. i .. "s", 1.1)
			task.wait(1)
		end
	else
		task.wait(INTERMISSION_DURATION)
	end
	vhGameManager.SetState(States.Active)
end

-- Main loop: watches for first player join to auto-start, monitors ship survival
local intermissionRunning = false
local gameOverRunning = false

task.spawn(function()
	while true do
		local pCount = #Players:GetPlayers()

		if currentState == States.Lobby then
			intermissionRunning = false
			gameOverRunning = false
			-- Auto-start when at least 1 player is in the game
			if pCount > 0 then
				vhGameManager.SetState(States.Intermission)
			end

		elseif currentState == States.Intermission then
			if not intermissionRunning then
				intermissionRunning = true
				onIntermission()
			end

		elseif currentState == States.Active then
			onActive()  -- RunSession is guarded by sessionActive flag, safe to call here
			-- Monitor: if all players leave or all ships gone, end game
			if pCount == 0 then
				vhGameManager.SetState(States.GameOver)
			end

		elseif currentState == States.GameOver then
			if not gameOverRunning then
				gameOverRunning = true
				onGameOver()
			end
		end

		task.wait(1)
	end
end)

function vhGameManager.Init()
	vhGameManager.SetState(States.Lobby)
	print("[GameManager] Initialized. Waiting for players.")
end

return vhGameManager
