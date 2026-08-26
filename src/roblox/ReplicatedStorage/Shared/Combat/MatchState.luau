--[[
	MatchState: Match State Definitions & Configurable Pacing Matrix.

	Structural rule:
	- Team identity is Yellow / Blue for Void Hunters.
	- Component category colors remain independent of team identity.
	- Arena timing values remain implementation parameters until the original
	  mission/match state machine is fully reconciled.
]]

export type MatchPhase = "Lobby" | "Ingress" | "Active" | "Settlement"
export type TeamId = "Yellow" | "Blue"

export type MatchData = {
	Phase: MatchPhase,
	TimeRemaining: number,
	RoundDuration: number,
	YellowScore: number,
	BlueScore: number,
	WinningTeam: TeamId?,
	RoundNumber: number,
	MatchId: string,
}

export type PlayerMatchStat = {
	PlayerId: number,
	PlayerName: string,
	Team: TeamId,
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

	TEAMS = {
		YELLOW = "Yellow",
		BLUE = "Blue",
	},
}

return MatchState
