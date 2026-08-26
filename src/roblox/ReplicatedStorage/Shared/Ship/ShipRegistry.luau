--[=[
	ShipRegistry
	Canonical server-side owner/ship lookup for Void Hunters.

	Instances remain the physical projection; this module owns the in-memory
	player -> ship relationship used by authoritative server systems.
]=]

local ShipRegistry = {}

local playerToShip: { [Player]: Model } = setmetatable({}, { __mode = "k" })
local shipToPlayer: { [Model]: Player } = setmetatable({}, { __mode = "k" })

function ShipRegistry.Register(player: Player, ship: Model)
	assert(player and player:IsA("Player"), "ShipRegistry.Register expects Player")
	assert(ship and ship:IsA("Model"), "ShipRegistry.Register expects Model")

	local previous = playerToShip[player]
	if previous and previous ~= ship then
		shipToPlayer[previous] = nil
	end

	local previousOwner = shipToPlayer[ship]
	if previousOwner and previousOwner ~= player then
		playerToShip[previousOwner] = nil
	end

	playerToShip[player] = ship
	shipToPlayer[ship] = player
end

function ShipRegistry.UnregisterShip(ship: Model)
	local player = shipToPlayer[ship]
	if player then
		playerToShip[player] = nil
	end
	shipToPlayer[ship] = nil
end

function ShipRegistry.UnregisterPlayer(player: Player)
	local ship = playerToShip[player]
	if ship then
		shipToPlayer[ship] = nil
	end
	playerToShip[player] = nil
end

function ShipRegistry.GetShip(player: Player): Model?
	local ship = playerToShip[player]
	return ship and ship.Parent and ship or nil
end

function ShipRegistry.GetOwner(ship: Model): Player?
	local player = shipToPlayer[ship]
	return player and player.Parent and player or nil
end

function ShipRegistry.IsOwner(player: Player, ship: Model): boolean
	return ShipRegistry.GetShip(player) == ship
end

function ShipRegistry.GetAll(): { [Player]: Model }
	local snapshot = {}
	for player, ship in pairs(playerToShip) do
		if player.Parent and ship.Parent then
			snapshot[player] = ship
		end
	end
	return snapshot
end

return ShipRegistry
