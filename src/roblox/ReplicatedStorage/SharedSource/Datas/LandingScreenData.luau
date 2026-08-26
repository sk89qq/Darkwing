local LandingScreenData = {
	---- Ship Definitions
	Ships = {
		{
			id = "ship_alpha",
			name = "Ship Alpha",
			description = "A balanced all-rounder vessel. Reliable in any situation.",
			flavorText = "\"The ship that started it all.\"",
			stats = { speed = 60, hull = 50, power = 50 },
			default = true,
		},
		{
			id = "ship_beta",
			name = "Ship Beta",
			description = "Lightweight and fast. Outrun your enemies with ease.",
			flavorText = "\"Speed is the best armor.\"",
			stats = { speed = 85, hull = 30, power = 40 },
			default = false,
		},
		{
			id = "ship_gamma",
			name = "Ship Gamma",
			description = "Heavy plating and brute force. Built to take a beating.",
			flavorText = "\"They can't stop what they can't break.\"",
			stats = { speed = 35, hull = 85, power = 45 },
			default = false,
		},
		{
			id = "ship_delta",
			name = "Ship Delta",
			description = "Advanced reactor core. Power hungry but devastating.",
			flavorText = "\"Energy is the ultimate weapon.\"",
			stats = { speed = 50, hull = 40, power = 85 },
			default = false,
		},
	},

	---- Game Mode Definitions
	GameModes = {
		{
			id = "sandbox",
			name = "SandBox",
			description = "Freely explore and build. No enemies, no limits.",
			minPlayers = 1,
			maxPlayers = 1,
		},
		{
			id = "ffa",
			name = "FFA",
			description = "Free-for-All. Every pilot for themselves!",
			minPlayers = 2,
			maxPlayers = 8,
		},
		{
			id = "convoy",
			name = "Convoy",
			description = "Survive the waves. Team up against the void.",
			minPlayers = 1,
			maxPlayers = 4,
		},
		{
			id = "teams",
			name = "Teams",
			description = "Red vs Blue. Coordinate and conquer.",
			minPlayers = 2,
			maxPlayers = 8,
		},
	},

	---- Tab Definitions
	Tabs = {
		{
			id = "ship_selection",
			name = "Ship Selection",
			defaultTab = true,
		},
		{
			id = "shop",
			name = "Shop",
			defaultTab = false,
		},
	},

	---- Shop Categories (matching VoidHunterComponents part types)
	ShopCategories = {
		{ id = "thrusters", name = "Thrusters", sortOrder = 1 },
		{ id = "weapons", name = "Weapons", sortOrder = 2 },
		{ id = "hulls", name = "Hulls", sortOrder = 3 },
		{ id = "shields", name = "Shields", sortOrder = 4 },
		{ id = "reactors", name = "Reactors", sortOrder = 5 },
		{ id = "conduits", name = "Conduits", sortOrder = 6 },
	},

	---- Placeholder Shop Items (populated later)
	ShopItems = {
		thrusters = {
			{ name = "Standard Thruster", description = "Basic thrust component.", category = "thrusters", cost = 100, placeholder = true },
			{ name = "Afterburner", description = "High-output thruster.", category = "thrusters", cost = 250, placeholder = true },
		},
		weapons = {
			{ name = "Mass Driver", description = "Kinetic projectile weapon.", category = "weapons", cost = 150, placeholder = true },
			{ name = "Plasma Ball", description = "Slow but devastating energy shot.", category = "weapons", cost = 300, placeholder = true },
		},
		hulls = {
			{ name = "Light Hull", description = "Minimal protection, maximum speed.", category = "hulls", cost = 80, placeholder = true },
			{ name = "Medium Hull", description = "Standard protection.", category = "hulls", cost = 180, placeholder = true },
			{ name = "Heavy Hull", description = "Maximum plating.", category = "hulls", cost = 400, placeholder = true },
		},
		shields = {
			{ name = "Shield Generator", description = "Energy shield for damage absorption.", category = "shields", cost = 350, placeholder = true },
		},
		reactors = {
			{ name = "Standard Reactor", description = "Balanced power output.", category = "reactors", cost = 200, placeholder = true },
			{ name = "Advanced Reactor", description = "High energy generation.", category = "reactors", cost = 500, placeholder = true },
		},
		conduits = {
			{ name = "Power Conduit", description = "Connects reactors to components.", category = "conduits", cost = 50, placeholder = true },
		},
	},
}

---- Utility Functions

function LandingScreenData:GetShip(shipId)
	for _, ship in ipairs(self.Ships) do
		if ship.id == shipId then
			return ship
		end
	end
	return nil
end

function LandingScreenData:GetDefaultShip()
	for _, ship in ipairs(self.Ships) do
		if ship.default then
			return ship
		end
	end
	return self.Ships[1]
end

function LandingScreenData:GetGameMode(modeId)
	for _, mode in ipairs(self.GameModes) do
		if mode.id == modeId then
			return mode
		end
	end
	return nil
end

function LandingScreenData:GetShopItemsByCategory(categoryId)
	return self.ShopItems[categoryId] or {}
end

return LandingScreenData
