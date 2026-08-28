-- vhGameManager.lua
-- Central orchestrator: auto-starts when first player joins, no manual Ready gate

local vhGameManager = {}

local Players = game:GetService("Players")

local WaveManager = require(game.ServerScriptService.VoidHunters:WaitForChild("VoidHunterWaveManager"))

local States = {
	Lobby = "Lobby",
	Intermission = "Intermission",
	Active = "Active",
	GameOver = "GameOver",
}

local currentState = States.Lobby
local HUDController = nil -- injected after init to avoid circular require
local initialized = false

local INTERMISSION_DURATION = 5
local GAME_OVER_DURATION = 8

-- Workspace.GameState is a public mirror of the server-authoritative state.
-- The Lua value remains authoritative; the attribute exists for diagnostics/UI.
local function publishState(state: string)
	game.Workspace:SetAttribute("GameState", state)
end

function vhGameManager.SetState(newState: string)
	assert(
		newState == States.Lobby
			or newState == States.Intermission
			or newState == States.Active
			or newState == States.GameOver,
		"[GameManager] Invalid game state: " .. tostring(newState)
	)

	local previousState = currentState
	currentState = newState
	publishState(newState)

	if previousState ~= newState then
		print(string.format("[GameManager] %s -> %s", previousState, newState))
	end
end

function vhGameManager.GetState()
	return currentState
end

function vhGameManager.GetStates()
	return States
end

function vhGameManager.IsState(state: string): boolean
	return currentState == state
end

function vhGameManager.InjectHUD(hud)
	HUDController = hud
end

local function onActive()
	print("[GameManager] ACTIVE - launching wave session")
	if HUDController then HUDController.BroadcastStatus("🚀 BATTLE BEGINS!", 4) end
	WaveManager.RunSession(vhGameManager, HUDController)
end

local function onGameOver(_victory)
	WaveManager.Reset()
	if game.Workspace:FindFirstChild("Enemies") then
		for _, e in ipairs(game.Workspace.Enemies:GetChildren()) do
			e:Destroy()
		end
	end
	if game.Workspace:FindFirstChild("Asteroids") then
		for _, a in ipairs(game.Workspace.Asteroids:GetChildren()) do
			a:Destroy()
		end
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

local intermissionRunning = false
local gameOverRunning = false

task.spawn(function()
	while true do
		local pCount = #Players:GetPlayers()

		if currentState == States.Lobby then
			intermissionRunning = false
			gameOverRunning = false
			if pCount > 0 then
				vhGameManager.SetState(States.Intermission)
			end

		elseif currentState == States.Intermission then
			if not intermissionRunning then
				intermissionRunning = true
				onIntermission()
			end

		elseif currentState == States.Active then
			onActive()
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
	if initialized then
		-- Idempotent initialization: always republish the authoritative state.
		publishState(currentState)
		return
	end

	initialized = true
	vhGameManager.SetState(States.Lobby)
	print("[GameManager] Initialized. Waiting for players.")
end

return vhGameManager
