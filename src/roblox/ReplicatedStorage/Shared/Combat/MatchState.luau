--[[
	MatchState: Match State Definitions & Configurable Pacing Matrix.
	Sourced from VOIDA Gameplay Loop Specification.
]]

export type MatchPhase = "Lobby" | "Ingress" | "Active" | "Settlement"

export type MatchData = {
	Phase: MatchPhase,
	TimeRemaining: number,
	RoundDuration: number,
	RedScore: number,
	BlueScore: number,
	WinningTeam: string?,
	RoundNumber: number,
	MatchId: string,
}

export type PlayerMatchStat = {
	PlayerId: number,
	PlayerName: string,
	Team: "Red" | "Blue",
	Kills: number,
	Deaths: number,
	Assists: number,
	DamageDealt: number,
	ComponentsSalvaged: number,
	Score: number,
}

local MatchState = {
	LOBBY_DURATION_SEC = 15.0,
	INGRESS_DURATION_SEC = 4.0,
	ROUND_DURATION_SEC = 180.0,
	SETTLEMENT_DURATION_SEC = 10.0,
	RESPAWN_DELAY_SEC = 3.5,
	SCORE_TO_WIN = 15,
}

return MatchState
