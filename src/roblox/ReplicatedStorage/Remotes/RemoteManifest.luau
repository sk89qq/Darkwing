--[=[
	RemoteManifest
	Canonical registry/documentation surface for client/server remotes.

	This module does not create remotes or replace existing handlers. It defines
	the intended ownership/security contract so individual systems do not invent
	parallel remote conventions.
]=]

local RemoteManifest = {
	Combat = {
		VoidHunterFireWeapon = {
			Direction = "ClientToServer",
			Kind = "RemoteEvent",
			Permission = "OwnedShipWeapon",
		},
		VoidHunterFireScrambler = {
			Direction = "ClientToServer",
			Kind = "RemoteEvent",
			Permission = "OwnedShipUtility",
		},
	},
	Match = {
		VoidHunterMatchState = {
			Direction = "ServerToClient",
			Kind = "RemoteEvent",
			Permission = "PublicMatchState",
		},
		VoidHunterMatchNotification = {
			Direction = "ServerToClient",
			Kind = "RemoteEvent",
			Permission = "PublicMatchNotification",
		},
		VoidHunterGetLeaderboard = {
			Direction = "ClientToServer",
			Kind = "RemoteFunction",
			Permission = "PublicMatchState",
		},
	},
}

return RemoteManifest
