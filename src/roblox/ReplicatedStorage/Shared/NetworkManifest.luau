--[=[
	NetworkManifest
	Canonical registry for server-owned Roblox remotes used by Void Hunters.

	This is a declarative contract only. Existing handlers remain authoritative until
	they are migrated to consume these entries. Payload validation belongs at the
	server handler boundary.
]=]

local NetworkManifest = {
	Combat = {
		VoidHunterFireWeapon = {
			Direction = "ClientToServer",
			Kind = "RemoteEvent",
			RateLimitPerSecond = 20,
			Payload = { "Ship", "WeaponName", "AimDirection" },
			Permission = "OwnedShipWeapon",
		},
		VoidHunterFireScrambler = {
			Direction = "ClientToServer",
			Kind = "RemoteEvent",
			RateLimitPerSecond = 20,
			Payload = { "Ship", "ScramblerName" },
			Permission = "OwnedShipScrambler",
		},
		VoidHunterPlayerAction = {
			Direction = "ClientToServer",
			Kind = "RemoteEvent",
			RateLimitPerSecond = 20,
			Payload = { "Action" },
			Permission = "OwnedShipAction",
		},
	},
	Match = {
		VoidHunterMatchState = {
			Direction = "ServerToClient",
			Kind = "RemoteEvent",
			Payload = { "MatchData" },
			Permission = "ServerBroadcast",
		},
		VoidHunterMatchNotification = {
			Direction = "ServerToClient",
			Kind = "RemoteEvent",
			Payload = { "Notification" },
			Permission = "ServerBroadcast",
		},
		VoidHunterGetLeaderboard = {
			Direction = "ClientToServer",
			Kind = "RemoteFunction",
			Payload = {},
			Permission = "PlayerRead",
		},
	},
	UI = {
		VoidHunterKillFeed = {
			Direction = "ServerToClient",
			Kind = "RemoteEvent",
			Payload = { "KillerName", "VictimName" },
			Permission = "ServerBroadcast",
		},
		VoidHunterRespawnTimer = {
			Direction = "ServerToClient",
			Kind = "RemoteEvent",
			Payload = { "Seconds" },
			Permission = "ServerToClient",
		},
		VoidHunterInvulnUpdate = {
			Direction = "ServerToClient",
			Kind = "RemoteEvent",
			Payload = { "Ship", "Enabled" },
			Permission = "ServerBroadcast",
		},
	},
}

function NetworkManifest.Get(group: string, remoteName: string): {[string]: any}?
	local namespace = NetworkManifest[group]
	if type(namespace) ~= "table" then
		return nil
	end
	local contract = namespace[remoteName]
	return type(contract) == "table" and contract or nil
end

function NetworkManifest.IsDeclared(remoteName: string): boolean
	for _, namespace in pairs(NetworkManifest) do
		if type(namespace) == "table" and namespace[remoteName] then
			return true
		end
	end
	return false
end

return NetworkManifest
