--[=[
	TeamIdentity
	Single shared team vocabulary for the Void Hunters port.

	Important:
	Component category colors are independent from ownership/team colors.
	The original game uses Yellow and Blue team identities.
]=]

local TeamIdentity = {
	YELLOW = "Yellow",
	BLUE = "Blue",
}

export type TeamId = "Yellow" | "Blue"

function TeamIdentity.IsValid(value: any): boolean
	return value == TeamIdentity.YELLOW or value == TeamIdentity.BLUE
end

function TeamIdentity.Other(team: TeamId): TeamId
	return team == TeamIdentity.YELLOW and TeamIdentity.BLUE or TeamIdentity.YELLOW
end

function TeamIdentity.AssignDeterministic(playerUserId: number): TeamId
	return playerUserId % 2 == 0 and TeamIdentity.YELLOW or TeamIdentity.BLUE
end

function TeamIdentity.Set(object: Instance, team: TeamId)
	assert(TeamIdentity.IsValid(team), "Invalid Void Hunters team")
	object:SetAttribute("Team", team)
end

function TeamIdentity.Get(object: Instance): TeamId?
	local value = object:GetAttribute("Team")
	return TeamIdentity.IsValid(value) and (value :: TeamId) or nil
end

return TeamIdentity
