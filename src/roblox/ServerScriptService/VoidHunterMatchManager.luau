--[[
	VoidHunterMatchManager (Server)
	Controls the full Arena Match Lifecycle:
	  - Lobby Preparation (15s) -> Sector Ingress (4s) -> Active Engagement (180s) -> Extraction Settlement (10s)
	  - Team scoring (Red vs Blue), kill credit, and match victory conditions
	  - High-frequency match state sync to client HUDs
	  - Leaderboard statistics tracking and post-match settlement rewards
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local MatchState = require(ReplicatedStorage.Shared.Combat.MatchState)

-- Ensure RemoteEvents
local function getOrCreateRemote(name: string, isFunction: boolean?): any
	local r = ReplicatedStorage:FindFirstChild(name)
	if not r then
		r = Instance.new(isFunction and "RemoteFunction" or "RemoteEvent")
		r.Name = name
		r.Parent = ReplicatedStorage
	end
	return r
end

local MatchStateEvent = getOrCreateRemote("VoidHunterMatchState")
local MatchNotificationEvent = getOrCreateRemote("VoidHunterMatchNotification")
local MatchLeaderboardFunction = getOrCreateRemote("VoidHunterGetLeaderboard", true)

local VoidHunterMatchManager = {}

-- State variables
local currentPhase: MatchState.MatchPhase = "Lobby"
local phaseTimer: number = MatchState.LOBBY_DURATION_SEC
local roundNumber: number = 1
local redScore: number = 0
local blueScore: number = 0
local winningTeam: string? = nil
local playerStats: { [number]: MatchState.PlayerMatchStat } = {}

-- Helpers
local function getTeam(player: Player): "Red" | "Blue"
	local arenaSpawner = game.ServerScriptService:FindFirstChild("VoidHunterArenaSpawner")
	if arenaSpawner then
		-- Use existing team assigned attribute
		local teamAttr = player:GetAttribute("Team")
		if teamAttr == "Red" or teamAttr == "Blue" then
			return teamAttr
		end
	end
	return (player.UserId % 2 == 0) and "Red" or "Blue"
end

local function initPlayerStats(player: Player)
	if not playerStats[player.UserId] then
		playerStats[player.UserId] = {
			PlayerId = player.UserId,
			PlayerName = player.DisplayName or player.Name,
			Team = getTeam(player),
			Kills = 0,
			Deaths = 0,
			Assists = 0,
			DamageDealt = 0,
			ComponentsSalvaged = 0,
			Score = 0,
		}
		player:SetAttribute("Team", playerStats[player.UserId].Team)
		player:SetAttribute("MatchKills", 0)
		player:SetAttribute("MatchScore", 0)
	end
end

-- Network Broadcast
local function broadcastMatchState()
	local data: MatchState.MatchData = {
		Phase = currentPhase,
		TimeRemaining = math.ceil(phaseTimer),
		RoundDuration = (currentPhase == "Active") and MatchState.ROUND_DURATION_SEC or MatchState.LOBBY_DURATION_SEC,
		RedScore = redScore,
		BlueScore = blueScore,
		WinningTeam = winningTeam,
		RoundNumber = roundNumber,
		MatchId = "MATCH_" .. tostring(roundNumber),
	}
	MatchStateEvent:FireAllClients(data)
end

-- State Transitions
function VoidHunterMatchManager.StartLobby()
	currentPhase = "Lobby"
	phaseTimer = MatchState.LOBBY_DURATION_SEC
	winningTeam = nil
	redScore = 0
	blueScore = 0
	
	-- Reset player round scores
	for _, p in ipairs(Players:GetPlayers()) do
		initPlayerStats(p)
		playerStats[p.UserId].Kills = 0
		playerStats[p.UserId].Deaths = 0
		playerStats[p.UserId].DamageDealt = 0
		playerStats[p.UserId].Score = 0
		p:SetAttribute("MatchKills", 0)
		p:SetAttribute("MatchScore", 0)
	end

	MatchNotificationEvent:FireAllClients({
		Title = "MATCHMAKING / LOBBY",
		Subtitle = "Assemble your VoidHunter in the dock before sector ingress!",
		Duration = 4.0,
		Type = "Info",
	})
	broadcastMatchState()
end

function VoidHunterMatchManager.StartIngress()
	currentPhase = "Ingress"
	phaseTimer = MatchState.INGRESS_DURATION_SEC

	MatchNotificationEvent:FireAllClients({
		Title = "SECTOR INGRESS INITIATED",
		Subtitle = "Warping to Sector 7 combat perimeter. Engage all hostiles!",
		Duration = 3.5,
		Type = "Alert",
	})
	broadcastMatchState()
end

function VoidHunterMatchManager.StartActiveRound()
	currentPhase = "Active"
	phaseTimer = MatchState.ROUND_DURATION_SEC

	MatchNotificationEvent:FireAllClients({
		Title = "ROUND " .. tostring(roundNumber) .. " ENGAGE",
		Subtitle = "First team to " .. tostring(MatchState.SCORE_TO_WIN) .. " kills wins sector dominance!",
		Duration = 3.0,
		Type = "Combat",
	})
	broadcastMatchState()
end

function VoidHunterMatchManager.EndRound(winner: string)
	currentPhase = "Settlement"
	phaseTimer = MatchState.SETTLEMENT_DURATION_SEC
	winningTeam = winner

	-- Calculate MVPs and settlement rewards
	local topScorer: MatchState.PlayerMatchStat? = nil
	for _, stat in pairs(playerStats) do
		if not topScorer or stat.Score > topScorer.Score then
			topScorer = stat
		end
	end

	MatchNotificationEvent:FireAllClients({
		Title = winner:upper() .. " TEAM VICTORIOUS!",
		Subtitle = topScorer and ("Sector MVP: " .. topScorer.PlayerName .. " with " .. tostring(topScorer.Score) .. " pts") or "Outstanding sector combat performance.",
		Duration = 6.0,
		Type = "Victory",
	})
	broadcastMatchState()
end

-- Scoring API
function VoidHunterMatchManager.RecordKill(killerPlayer: Player?, victimPlayer: Player?, weaponName: string?)
	if currentPhase ~= "Active" then return end

	if killerPlayer then
		initPlayerStats(killerPlayer)
		playerStats[killerPlayer.UserId].Kills += 1
		playerStats[killerPlayer.UserId].Score += 100
		killerPlayer:SetAttribute("MatchKills", playerStats[killerPlayer.UserId].Kills)
		killerPlayer:SetAttribute("MatchScore", playerStats[killerPlayer.UserId].Score)

		local killerTeam = playerStats[killerPlayer.UserId].Team
		if killerTeam == "Red" then
			redScore += 1
		else
			blueScore += 1
		end
	end

	if victimPlayer then
		initPlayerStats(victimPlayer)
		playerStats[victimPlayer.UserId].Deaths += 1
	end

	broadcastMatchState()

	-- Check win condition
	if redScore >= MatchState.SCORE_TO_WIN then
		VoidHunterMatchManager.EndRound("Red")
	elseif blueScore >= MatchState.SCORE_TO_WIN then
		VoidHunterMatchManager.EndRound("Blue")
	end
end

function VoidHunterMatchManager.RecordDamage(attackerPlayer: Player?, damage: number)
	if attackerPlayer and currentPhase == "Active" then
		initPlayerStats(attackerPlayer)
		playerStats[attackerPlayer.UserId].DamageDealt += damage
		playerStats[attackerPlayer.UserId].Score += math.floor(damage * 0.2)
		attackerPlayer:SetAttribute("MatchScore", playerStats[attackerPlayer.UserId].Score)
	end
end

function VoidHunterMatchManager.RecordSalvage(player: Player)
	if player and currentPhase == "Active" then
		initPlayerStats(player)
		playerStats[player.UserId].ComponentsSalvaged += 1
		playerStats[player.UserId].Score += 25
		player:SetAttribute("MatchScore", playerStats[player.UserId].Score)
	end
end

-- RemoteFunction for Full Leaderboard retrieval
MatchLeaderboardFunction.OnServerInvoke = function(player)
	local list = {}
	for _, stat in pairs(playerStats) do
		table.insert(list, stat)
	end
	table.sort(list, function(a, b)
		return a.Score > b.Score
	end)
	return {
		Leaderboard = list,
		RedScore = redScore,
		BlueScore = blueScore,
		Phase = currentPhase,
		TimeRemaining = math.ceil(phaseTimer),
	}
end

-- Lifecycle Connections
Players.PlayerAdded:Connect(function(player)
	initPlayerStats(player)
	broadcastMatchState()
end)

Players.PlayerRemoving:Connect(function(player)
	playerStats[player.UserId] = nil
end)

-- Main Heartbeat Loop
local lastBroadcast = 0
RunService.Heartbeat:Connect(function(dt)
	phaseTimer = math.max(0, phaseTimer - dt)

	-- Broadcast state every second
	if tick() - lastBroadcast >= 1.0 then
		lastBroadcast = tick()
		broadcastMatchState()
	end

	-- Phase Transitions
	if phaseTimer <= 0 then
		if currentPhase == "Lobby" then
			VoidHunterMatchManager.StartIngress()
		elseif currentPhase == "Ingress" then
			VoidHunterMatchManager.StartActiveRound()
		elseif currentPhase == "Active" then
			local winner = (redScore > blueScore) and "Red" or ((blueScore > redScore) and "Blue" or "Draw")
			VoidHunterMatchManager.EndRound(winner)
		elseif currentPhase == "Settlement" then
			roundNumber += 1
			VoidHunterMatchManager.StartLobby()
		end
	end
end)

-- Initialize on server boot
task.defer(function()
	task.wait(1.0)
	VoidHunterMatchManager.StartLobby()
end)

_G.VoidHunterMatchManager = VoidHunterMatchManager
return VoidHunterMatchManager
