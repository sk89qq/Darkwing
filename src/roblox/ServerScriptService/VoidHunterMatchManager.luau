--[=[
	VoidHunterMatchManager (Server)

	Current implementation is the existing Arena prototype. Its lifecycle/timing is
	NOT declared forensic-verified; the original client has a broader Mission system.
	This manager remains the Arena runtime until mission parity is implemented.

	Team identity is historically Yellow / Blue. Component category colors remain
	independent and are not used as team ownership colors.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local MatchState = require(ReplicatedStorage.Shared.Combat.MatchState)

local function getOrCreateRemote(name: string, isFunction: boolean?): any
	local remote = ReplicatedStorage:FindFirstChild(name)
	if not remote then
		remote = Instance.new(isFunction and "RemoteFunction" or "RemoteEvent")
		remote.Name = name
		remote.Parent = ReplicatedStorage
	end
	return remote
end

local MatchStateEvent = getOrCreateRemote("VoidHunterMatchState")
local MatchNotificationEvent = getOrCreateRemote("VoidHunterMatchNotification")
local MatchLeaderboardFunction = getOrCreateRemote("VoidHunterGetLeaderboard", true)

local VoidHunterMatchManager = {}

local currentPhase: MatchState.MatchPhase = "Lobby"
local phaseTimer = MatchState.LOBBY_DURATION_SEC
local roundNumber = 1
local yellowScore = 0
local blueScore = 0
local winningTeam: MatchState.TeamId? = nil
local playerStats: { [number]: MatchState.PlayerMatchStat } = {}

local function getTeam(player: Player): MatchState.TeamId
	local teamAttr = player:GetAttribute("Team")
	if teamAttr == MatchState.TEAMS.YELLOW or teamAttr == MatchState.TEAMS.BLUE then
		return teamAttr :: MatchState.TeamId
	end
	-- Stable deterministic assignment for the prototype only. Match/mode-specific
	-- assignment will move into the Mission system when it is ported.
	return (player.UserId % 2 == 0) and MatchState.TEAMS.YELLOW or MatchState.TEAMS.BLUE
end

local function initPlayerStats(player: Player)
	if playerStats[player.UserId] then
		return
	end

	local team = getTeam(player)
	playerStats[player.UserId] = {
		PlayerId = player.UserId,
		PlayerName = player.DisplayName or player.Name,
		Team = team,
		Kills = 0,
		Deaths = 0,
		Assists = 0,
		DamageDealt = 0,
		ComponentsSalvaged = 0,
		Score = 0,
	}

	player:SetAttribute("Team", team)
	player:SetAttribute("MatchKills", 0)
	player:SetAttribute("MatchScore", 0)
end

local function broadcastMatchState()
	MatchStateEvent:FireAllClients({
		Phase = currentPhase,
		TimeRemaining = math.ceil(phaseTimer),
		RoundDuration = currentPhase == "Active" and MatchState.ROUND_DURATION_SEC or MatchState.LOBBY_DURATION_SEC,
		YellowScore = yellowScore,
		BlueScore = blueScore,
		WinningTeam = winningTeam,
		RoundNumber = roundNumber,
		MatchId = "MATCH_" .. tostring(roundNumber),
	})
end

function VoidHunterMatchManager.StartLobby()
	currentPhase = "Lobby"
	phaseTimer = MatchState.LOBBY_DURATION_SEC
	winningTeam = nil
	yellowScore = 0
	blueScore = 0

	for _, player in ipairs(Players:GetPlayers()) do
		initPlayerStats(player)
		local stats = playerStats[player.UserId]
		stats.Kills = 0
		stats.Deaths = 0
		stats.Assists = 0
		stats.DamageDealt = 0
		stats.ComponentsSalvaged = 0
		stats.Score = 0
		player:SetAttribute("MatchKills", 0)
		player:SetAttribute("MatchScore", 0)
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
		Subtitle = "Warping to Sector 7 combat perimeter.",
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
		Subtitle = "Arena prototype: first team to " .. tostring(MatchState.SCORE_TO_WIN) .. " kills wins.",
		Duration = 3.0,
		Type = "Combat",
	})
	broadcastMatchState()
end

function VoidHunterMatchManager.EndRound(winner: MatchState.TeamId?)
	currentPhase = "Settlement"
	phaseTimer = MatchState.SETTLEMENT_DURATION_SEC
	winningTeam = winner

	local topScorer: MatchState.PlayerMatchStat? = nil
	for _, stats in pairs(playerStats) do
		if not topScorer or stats.Score > topScorer.Score then
			topScorer = stats
		end
	end

	local title = winner and (winner:upper() .. " TEAM VICTORIOUS!") or "ROUND DRAW"
	local subtitle = topScorer
		and ("Sector MVP: " .. topScorer.PlayerName .. " with " .. tostring(topScorer.Score) .. " pts")
		or "Outstanding sector combat performance."

	MatchNotificationEvent:FireAllClients({
		Title = title,
		Subtitle = subtitle,
		Duration = 6.0,
		Type = "Victory",
	})
	broadcastMatchState()
end

function VoidHunterMatchManager.RecordKill(killerPlayer: Player?, victimPlayer: Player?, _weaponName: string?)
	if currentPhase ~= "Active" then
		return
	end

	if killerPlayer then
		initPlayerStats(killerPlayer)
		local killerStats = playerStats[killerPlayer.UserId]
		killerStats.Kills += 1
		killerStats.Score += 100
		killerPlayer:SetAttribute("MatchKills", killerStats.Kills)
		killerPlayer:SetAttribute("MatchScore", killerStats.Score)

		if killerStats.Team == MatchState.TEAMS.YELLOW then
			yellowScore += 1
		elseif killerStats.Team == MatchState.TEAMS.BLUE then
			blueScore += 1
		end
	end

	if victimPlayer then
		initPlayerStats(victimPlayer)
		playerStats[victimPlayer.UserId].Deaths += 1
	end

	broadcastMatchState()

	if yellowScore >= MatchState.SCORE_TO_WIN then
		VoidHunterMatchManager.EndRound(MatchState.TEAMS.YELLOW)
	elseif blueScore >= MatchState.SCORE_TO_WIN then
		VoidHunterMatchManager.EndRound(MatchState.TEAMS.BLUE)
	end
end

function VoidHunterMatchManager.RecordDamage(attackerPlayer: Player?, damage: number)
	if attackerPlayer and currentPhase == "Active" and typeof(damage) == "number" and damage > 0 then
		initPlayerStats(attackerPlayer)
		local stats = playerStats[attackerPlayer.UserId]
		stats.DamageDealt += damage
		stats.Score += math.floor(damage * 0.2)
		attackerPlayer:SetAttribute("MatchScore", stats.Score)
	end
end

function VoidHunterMatchManager.RecordSalvage(player: Player)
	if player and currentPhase == "Active" then
		initPlayerStats(player)
		local stats = playerStats[player.UserId]
		stats.ComponentsSalvaged += 1
		stats.Score += 25
		player:SetAttribute("MatchScore", stats.Score)
	end
end

MatchLeaderboardFunction.OnServerInvoke = function()
	local list = {}
	for _, stats in pairs(playerStats) do
		table.insert(list, stats)
	end
	table.sort(list, function(a, b)
		return a.Score > b.Score
	end)

	return {
		Leaderboard = list,
		YellowScore = yellowScore,
		BlueScore = blueScore,
		Phase = currentPhase,
		TimeRemaining = math.ceil(phaseTimer),
	}
end

Players.PlayerAdded:Connect(function(player)
	initPlayerStats(player)
	broadcastMatchState()
end)

Players.PlayerRemoving:Connect(function(player)
	playerStats[player.UserId] = nil
end)

local lastBroadcast = 0
RunService.Heartbeat:Connect(function(dt)
	phaseTimer = math.max(0, phaseTimer - dt)

	if os.clock() - lastBroadcast >= 1.0 then
		lastBroadcast = os.clock()
		broadcastMatchState()
	end

	if phaseTimer <= 0 then
		if currentPhase == "Lobby" then
			VoidHunterMatchManager.StartIngress()
		elseif currentPhase == "Ingress" then
			VoidHunterMatchManager.StartActiveRound()
		elseif currentPhase == "Active" then
			local winner: MatchState.TeamId? = nil
			if yellowScore > blueScore then
				winner = MatchState.TEAMS.YELLOW
			elseif blueScore > yellowScore then
				winner = MatchState.TEAMS.BLUE
			end
			VoidHunterMatchManager.EndRound(winner)
		elseif currentPhase == "Settlement" then
			roundNumber += 1
			VoidHunterMatchManager.StartLobby()
		end
	end
end)

task.defer(function()
	task.wait(1.0)
	VoidHunterMatchManager.StartLobby()
end)

_G.VoidHunterMatchManager = VoidHunterMatchManager
return VoidHunterMatchManager
