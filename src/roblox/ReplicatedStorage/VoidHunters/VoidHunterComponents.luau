-- VOID HUNTERS COMPONENTS (7-stud, flat 2D, 13 types)
-- Only STRUCTURE parts have SocketIn.
-- Function parts mount on structure front faces.
-- Place in ReplicatedStorage

local Components = {}

Components.UNIT = 7
Components.HEIGHT = 3.5

Components.Categories = {
	MOVEMENT = "Movement",
	DEFENSE = "Defense",
	OFFENSE = "Offense",
	UTILITY = "Utility",
	STRUCTURE = "Structure",
}

function Components.IsStructure(componentType)
	local def = Components.Types[componentType]
	return def and def.Category == Components.Categories.STRUCTURE
end

function Components.IsFunctionPart(componentType)
	local def = Components.Types[componentType]
	if not def then return false end
	return def.Category ~= Components.Categories.STRUCTURE
end

Components.Types = {
	-- ===== STRUCTURE (have SocketIn) =====
	CommandCore = {
		Name = "Command Core",
		Category = Components.Categories.STRUCTURE,
		Description = "Ship brain. Required.",
		UnitSize = Vector3.new(1.3, 0.65, 1.3),
		Color = Color3.new(0.15, 0.15, 0.17),
		GlowColor = Color3.new(0.2, 0.2, 0.25),
		Material = Enum.Material.Metal,
		Shape = "Block",
		Mass = 5,
		HP = 250,
		HasSocketIn = true,
		SocketInOffset = 0.65,
	},

	HullSmall = {
		Name = "Small Hull",
		Category = Components.Categories.STRUCTURE,
		UnitSize = Vector3.new(1, 0.5, 1),
		Color = Color3.new(0.5, 0.5, 0.5),
		GlowColor = Color3.new(0.6, 0.6, 0.6),
		Material = Enum.Material.Metal,
		Shape = "Block",
		Mass = 1,
		HP = 100,
		HasSocketIn = true,
		SocketInOffset = 0.5,
	},

	HullMedium = {
		Name = "Medium Hull",
		Category = Components.Categories.STRUCTURE,
		UnitSize = Vector3.new(2, 0.5, 1),
		Color = Color3.new(0.3, 0.3, 0.3),
		GlowColor = Color3.new(0.4, 0.4, 0.4),
		Material = Enum.Material.Metal,
		Shape = "Block",
		Mass = 2,
		HP = 200,
		HasSocketIn = true,
		SocketInOffset = 0.5,
	},

	HullHeavy = {
		Name = "Heavy Hull",
		Category = Components.Categories.STRUCTURE,
		UnitSize = Vector3.new(2, 0.5, 2),
		Color = Color3.new(0, 0.4, 0),
		GlowColor = Color3.new(0.1, 0.6, 0.1),
		Material = Enum.Material.Metal,
		Shape = "Block",
		Mass = 4,
		HP = 400,
		HasSocketIn = true,
		SocketInOffset = 1,
	},

	-- ===== MOVEMENT =====
	StandardThruster = {
		Name = "Standard Thruster",
		Category = Components.Categories.MOVEMENT,
		UnitSize = Vector3.new(1, 0.5, 1),
		Color = Color3.new(1, 0.5, 0),
		GlowColor = Color3.new(1, 0.7, 0),
		Material = Enum.Material.Metal,
		Shape = "Block",
		Mass = 2,
		HP = 80,
		HasSocketIn = false,
		ThrustForce = 80,
	},

	-- ===== OFFENSE =====
	MassDriver = {
		Name = "Mass Driver",
		Category = Components.Categories.OFFENSE,
		UnitSize = Vector3.new(1, 0.5, 1),
		Color = Color3.new(0.3, 0.3, 0.6),
		GlowColor = Color3.new(0.4, 0.4, 0.8),
		Material = Enum.Material.Metal,
		Shape = "Block",
		Mass = 1.5,
		HP = 60,
		HasSocketIn = false,
		Damage = 25,
		FireRate = 0.5,
		Range = 60,
		ProjectileSpeed = 200,
		ProjectileSize = Vector3.new(0.5, 0.3, 1),
		ProjectileColor = Color3.new(0.4, 0.4, 1),
		Penetrates = false,
		PowerPerShot = 2,
	},

	PlasmaBall = {
		Name = "Plasma Ball Launcher",
		Category = Components.Categories.OFFENSE,
		UnitSize = Vector3.new(1, 0.5, 1),
		Color = Color3.new(0.6, 0, 0.6),
		GlowColor = Color3.new(0.8, 0.2, 0.8),
		Material = Enum.Material.Metal,
		Shape = "Cylinder",
		Mass = 2,
		HP = 80,
		HasSocketIn = false,
		Damage = 50,
		TickDamage = 10,  -- damage per second while overlapping target
		FireRate = 2,
		Range = 40,
		ProjectileSpeed = 60,
		ProjectileSize = Vector3.new(1, 1, 1),
		ProjectileColor = Color3.new(0.8, 0.2, 0.8),
		Penetrates = true,
		ArmorDamageMultiplier = 0.5,
		PowerPerShot = 8,
	},

	MissileLauncher = {
		Name = "Missile Launcher",
		Category = Components.Categories.OFFENSE,
		UnitSize = Vector3.new(1, 0.5, 1),
		Color = Color3.new(0.8, 0, 0),
		GlowColor = Color3.new(1, 0.2, 0.2),
		Material = Enum.Material.Metal,
		Shape = "Block",
		Mass = 2,
		HP = 60,
		HasSocketIn = false,
		Damage = 40,
		FireRate = 3,
		Range = 50,
		ProjectileSpeed = 80,
		SpreadAngle = 15,  -- degrees
		MissileHP = 25,  -- missiles can be shot down
		ProjectileSize = Vector3.new(1, 0.5, 1),
		ProjectileColor = Color3.new(1, 0.3, 0.3),
		PowerPerShot = 5,
	},

	DroneBay = {
		Name = "Drone Bay",
		Category = Components.Categories.OFFENSE,
		UnitSize = Vector3.new(1, 0.5, 1),
		Color = Color3.new(0, 0.8, 0.5),
		GlowColor = Color3.new(0.2, 1, 0.7),
		Material = Enum.Material.Metal,
		Shape = "Cylinder",
		Mass = 2,
		HP = 50,
		HasSocketIn = false,
		Damage = 10,
		FireRate = 1,
		Range = 30,
		DroneSpeed = 30,
		DroneHP = 50,
		DroneColor = Color3.new(0, 1, 0.5),
		PowerPerShot = 3,
	},

	Laser = {
		Name = "Laser",
		Category = Components.Categories.OFFENSE,
		UnitSize = Vector3.new(1, 0.5, 1),
		Color = Color3.new(0.8, 0, 0),
		GlowColor = Color3.new(1, 0.2, 0.2),
		Material = Enum.Material.Metal,
		Shape = "Block",
		Mass = 1,
		HP = 40,
		HasSocketIn = false,
		Damage = 15,  -- per second
		Range = 40,
		Duration = 0.3,  -- beam stays for 0.3s
		LaserColor = Color3.new(1, 0, 0),
		Cooldown = 1,
		PowerPerShot = 2,
	},

	-- ===== DEFENSE =====
	ShieldGenerator = {
		Name = "Shield Generator",
		Category = Components.Categories.DEFENSE,
		UnitSize = Vector3.new(1, 0.5, 1),
		Color = Color3.new(0, 0.8, 0.8),
		GlowColor = Color3.new(0.2, 1, 1),
		Material = Enum.Material.Metal,
		Shape = "Cylinder",
		Mass = 2,
		HP = 50,
		HasSocketIn = false,
		ShieldOutput = 50,
		PowerDrain = 10,
		MinimumRecharge = 4,
	},

	-- ===== UTILITY =====
	Reactor = {
		Name = "Reactor",
		Category = Components.Categories.UTILITY,
		UnitSize = Vector3.new(1, 0.5, 1),
		Color = Color3.new(1, 0.8, 0),
		GlowColor = Color3.new(1, 1, 0.3),
		Material = Enum.Material.Metal,
		Shape = "Block",
		Mass = 3,
		HP = 40,
		HasSocketIn = false,
		EnergyRegen = 5,
	},

	ScramblerPulse = {
		Name = "Scrambler Pulse",
		Category = Components.Categories.UTILITY,
		UnitSize = Vector3.new(1, 0.5, 1),
		Color = Color3.new(0, 1, 1),
		GlowColor = Color3.new(0.3, 1, 1),
		Material = Enum.Material.Metal,
		Shape = "Cylinder",
		Mass = 1,
		HP = 30,
		HasSocketIn = false,
		Radius = 15,
		Cooldown = 5,
		PowerCost = 5,
		PulseColor = Color3.new(0, 1, 1),
	},
}

-- ===== HELPERS =====

function Components.GetByCategory(category)
	local results = {}
	for _, comp in pairs(Components.Types) do
		if comp.Category == category then
			table.insert(results, comp)
		end
	end
	return results
end

function Components.Create(componentType)
	local def = Components.Types[componentType]
	if not def then return nil end

	local part = Instance.new("Part")
	part.Name = def.Name
	part.Size = Vector3.new(
		def.UnitSize.X * Components.UNIT,
		Components.HEIGHT,
		def.UnitSize.Z * Components.UNIT
	)

	if def.Shape == "Cylinder" then
		part.Shape = Enum.PartShape.Cylinder
	else
		part.Shape = Enum.PartShape.Block
	end

	part.BrickColor = BrickColor.new(def.Color)
	part.Material = def.Material or Enum.Material.Metal
	part.CanCollide = true
	part.Anchored = false

	local result = { part = part, socketAttachment = nil }

	if def.HasSocketIn and def.SocketInOffset then
		local sock = Instance.new("Attachment")
		sock.Name = "SocketIn"
		sock.Position = Vector3.new(0, 0, -def.SocketInOffset * Components.UNIT)
		sock.Parent = part
		result.socketAttachment = sock
	end

	return result
end

function Components.GetAllTypes()
	local names = {}
	for name, _ in pairs(Components.Types) do
		table.insert(names, name)
	end
	return names
end

function Components.GetStructureTypes()
	local names = {}
	for name, def in pairs(Components.Types) do
		if def.Category == Components.Categories.STRUCTURE then
			table.insert(names, name)
		end
	end
	return names
end

return Components
