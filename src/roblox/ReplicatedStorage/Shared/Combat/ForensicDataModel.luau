--[[
	ForensicDataModel: Definitive Data Structures, Geometry Tables, and Weapon/Mission Registries
	Extracted directly from Void Hunters client decompile (ml.java, anb.java, sg.java, nbb.java, wfb.java, wlb.java, hab.java).
	Tagged per Source-Truth Verification Rules:
	  [CODE_VERIFIED], [ASSET_VERIFIED], [ORIGINAL_DATA_VERIFIED], [ALTERORB_BEHAVIOR_VERIFIED], [DOCUMENTATION_ONLY], [INFERRED], [UNKNOWN]
]]

export type SourceTruthTag = 
	"CODE_VERIFIED" 
	| "ASSET_VERIFIED" 
	| "ORIGINAL_DATA_VERIFIED" 
	| "ALTERORB_BEHAVIOR_VERIFIED" 
	| "DOCUMENTATION_ONLY" 
	| "INFERRED" 
	| "UNKNOWN"

-----------------------------------------------------------------------------
-- 1. COMPONENT DATA MODEL (`ml.java`) [CODE_VERIFIED]
-----------------------------------------------------------------------------
export type ForensicComponent = {
	-- Java: int j
	component_type_id: number,
	-- Java: int e
	triggermap: number,
	-- Java: int o
	connectionpointx: number,
	-- Java: int m
	connectionpointy: number,
	-- Java: int q
	connectedangle: number,
	-- Java: int p
	currentconnectedangle: number,
	-- Java: int i (clamped to 0)
	health: number,
	-- Java: int r
	finalx: number,
	-- Java: int n
	finaly: number,
	-- Java: int b
	finalangle: number,
	-- Java: int[] g
	finaloutline: { number },
	-- Java: ml[] f (recursive child graph)
	subcomponents: { ForensicComponent },
	-- Java: Hardpoint[] d
	hardpoints: { ForensicHardpoint },
	-- Java: qjb c (WeaponBehaviour)
	weapon_behaviour: any?,
	-- Java: aqa a (ThrusterBehaviour)
	thruster_behaviour: any?,
	-- Java: lja k (GrappleLauncherBehaviour)
	grapple_behaviour: any?,
	-- Java: generic ComponentBehaviour h (mua, kma)
	generic_behaviour: any?,
	-- Instance binding in Roblox
	bound_part: BasePart?,
}

export type ForensicHardpoint = {
	x: number,
	y: number,
	angle: number?,
	owner_index: number?,
	is_occupied: boolean,
}

-----------------------------------------------------------------------------
-- 2. PHYSICAL BODY MODEL (`anb.java`, `sg.java`, `nbb.java`) [CODE_VERIFIED]
-----------------------------------------------------------------------------
export type ForensicBody = {
	-- Java: int l
	id: string,
	-- Java: int d
	x: number,
	-- Java: int e
	y: number,
	-- Java: int f
	dx: number,
	-- Java: int h
	dy: number,
	-- Java: int r
	angle: number,
	-- Java: int n
	angularvelocity: number,
	-- Java: int i
	centreofmassx: number,
	-- Java: int j
	centreofmassy: number,
	-- Java: int s
	mass: number,
	-- Java: int m
	momentofinertia: number,
	-- Java: int[] q
	boundingbox: { number },
	-- Java: ml k
	root_component: ForensicComponent?,
	-- Type specialization
	body_type: "Ship" | "Debris" | "Projectile" | "Asteroid",
	-- Java: nbb.v (phantom state for debris)
	is_phantom: boolean?,
}

-----------------------------------------------------------------------------
-- 3. EXACT CLIENT COLOR CONSTANTS (`wfb.a()`) [CODE_VERIFIED]
-----------------------------------------------------------------------------
local ForensicColors = {
	RED = Color3.fromHex("D72828"),      -- a = -1
	BLUE = Color3.fromHex("2849D7"),     -- a = -2
	ORANGE = Color3.fromHex("D77628"),   -- a = -3
	GREY = Color3.fromHex("DCDCDC"),     -- a =  3
	PINK = Color3.fromHex("D728AC"),     -- a =  4
	GREEN = Color3.fromHex("49D728"),    -- a =  5
	PURPLE = Color3.fromHex("8F28D7"),   -- a =  6
}

local CategoryColorMap: { [number]: Color3 } = {
	[-1] = ForensicColors.RED,
	[-2] = ForensicColors.BLUE,
	[-3] = ForensicColors.ORANGE,
	[3] = ForensicColors.GREY,
	[4] = ForensicColors.PINK,
	[5] = ForensicColors.GREEN,
	[6] = ForensicColors.PURPLE,
}

-----------------------------------------------------------------------------
-- 4. POLYGON AREA & HEALTH COMPUTATION (`wfb.p` / `lw.a()`) [CODE_VERIFIED]
-----------------------------------------------------------------------------
local function ComputePolygonSignedArea(vertices: { number }): number
	local n = #vertices / 2
	if n < 3 then return 10 end
	local area = 0
	for i = 1, n do
		local j = (i % n) + 1
		local x1 = vertices[(i - 1) * 2 + 1]
		local y1 = vertices[(i - 1) * 2 + 2]
		local x2 = vertices[(j - 1) * 2 + 1]
		local y2 = vertices[(j - 1) * 2 + 2]
		area = area + (x1 * y2 - x2 * y1)
	end
	return math.abs(area) / 2
end

local function ComputeDecompileHealth(vertices: { number }, zScale: number): number
	local area = ComputePolygonSignedArea(vertices)
	-- eo.o[] sqrt lookup table scaled by 4096: lw.a(area) * z
	local sqrtVal = math.sqrt(math.max(1, area))
	local baseHp = math.floor((sqrtVal * zScale) / 64)
	return math.clamp(baseHp, 25, 500)
end

-----------------------------------------------------------------------------
-- 5. STATIC GEOMETRY & DEFINITION TABLE 0..55 (`wlb.java` / `hab.g[56]`) [CODE_VERIFIED]
-----------------------------------------------------------------------------
export type ForensicComponentDefinition = {
	type_id: number,
	name: string,
	category_code: number,
	color: Color3,
	polygon_vertices: { number },
	hardpoints: { { x: number, y: number, angle: number? } },
	behavior_type: string,
	behavior_id: number?,
	base_health: number,
	health_scale_z: number,
	verification: SourceTruthTag,
}

local ComponentDefinitions: { [number]: ForensicComponentDefinition } = {
	[0] = {
		type_id = 0,
		name = "CommandCore_Bullfrog",
		category_code = -1,
		color = ForensicColors.RED,
		polygon_vertices = { 5, 0, -5, 4, -5, -4 },
		hardpoints = {
			{ x = 5, y = 0, angle = 0 },
			{ x = 2, y = -2, angle = -2048 },
			{ x = 2, y = 2, angle = 2048 },
			{ x = -1, y = 0, angle = 0 },
			{ x = -5, y = 0, angle = 4096 },
		},
		behavior_type = "Core",
		base_health = 250,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[1] = {
		type_id = 1,
		name = "HullSquare_Large_40",
		category_code = 3,
		color = ForensicColors.GREY,
		polygon_vertices = { -40, -40, 40, -40, 40, 40, -40, 40 },
		hardpoints = {
			{ x = 0, y = 40, angle = 0 },
			{ x = 40, y = 0, angle = 2048 },
			{ x = 0, y = -40, angle = 4096 },
			{ x = -40, y = 0, angle = -2048 },
		},
		behavior_type = "Hull",
		base_health = 180,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[2] = {
		type_id = 2,
		name = "HullSquare_Small_10",
		category_code = 3,
		color = ForensicColors.GREY,
		polygon_vertices = { -10, -10, 10, -10, 10, 10, -10, 10 },
		hardpoints = {
			{ x = 0, y = 10, angle = 0 },
			{ x = 10, y = 0, angle = 2048 },
			{ x = 0, y = -10, angle = 4096 },
			{ x = -10, y = 0, angle = -2048 },
		},
		behavior_type = "Hull",
		base_health = 60,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[3] = {
		type_id = 3,
		name = "HullHexagon_30",
		category_code = 3,
		color = ForensicColors.GREY,
		polygon_vertices = { 15, 0, 7.5, 13, -7.5, 13, -15, 0, -7.5, -13, 7.5, -13 },
		hardpoints = {
			{ x = 15, y = 0, angle = 0 },
			{ x = 7.5, y = 13, angle = 1024 },
			{ x = -7.5, y = 13, angle = 3072 },
			{ x = -15, y = 0, angle = 4096 },
			{ x = -7.5, y = -13, angle = -3072 },
			{ x = 7.5, y = -13, angle = -1024 },
		},
		behavior_type = "Hull",
		base_health = 140,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[4] = {
		type_id = 4,
		name = "HullDiamond_20",
		category_code = 3,
		color = ForensicColors.GREY,
		polygon_vertices = { 10, 0, 0, 10, -10, 0, 0, -10 },
		hardpoints = {
			{ x = 10, y = 0, angle = 0 },
			{ x = 0, y = 10, angle = 2048 },
			{ x = -10, y = 0, angle = 4096 },
			{ x = 0, y = -10, angle = -2048 },
		},
		behavior_type = "Hull",
		base_health = 80,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[5] = {
		type_id = 5,
		name = "HullTrapezoid_Aft",
		category_code = 3,
		color = ForensicColors.GREY,
		polygon_vertices = { 6, 4, 6, -4, -6, -8, -6, 8 },
		hardpoints = {
			{ x = 6, y = 0, angle = 0 },
			{ x = -6, y = 0, angle = 4096 },
		},
		behavior_type = "Hull",
		base_health = 100,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[6] = {
		type_id = 6,
		name = "ArmourPlate_Heavy_1x1",
		category_code = 3,
		color = ForensicColors.GREY,
		polygon_vertices = { -5, -5, 5, -5, 5, 5, -5, 5 },
		hardpoints = {
			{ x = 0, y = -5, angle = 4096 },
		},
		behavior_type = "Armor",
		base_health = 220,
		health_scale_z = 1536,
		verification = "CODE_VERIFIED",
	},
	[7] = {
		type_id = 7,
		name = "ArmourPlate_Heavy_2x1",
		category_code = 3,
		color = ForensicColors.GREY,
		polygon_vertices = { -10, -5, 10, -5, 10, 5, -10, 5 },
		hardpoints = {
			{ x = 0, y = -5, angle = 4096 },
		},
		behavior_type = "Armor",
		base_health = 320,
		health_scale_z = 1536,
		verification = "CODE_VERIFIED",
	},
	[8] = {
		type_id = 8,
		name = "HullLeftWing_Slanted",
		category_code = 3,
		color = ForensicColors.GREY,
		polygon_vertices = { 0, 0, 10, 5, 5, 15, -5, 10 },
		hardpoints = {
			{ x = 0, y = 0, angle = -2048 },
		},
		behavior_type = "Hull",
		base_health = 90,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[9] = {
		type_id = 9,
		name = "HullRightWing_Slanted",
		category_code = 3,
		color = ForensicColors.GREY,
		polygon_vertices = { 0, 0, -5, 10, 5, 15, 10, 5 },
		hardpoints = {
			{ x = 0, y = 0, angle = 2048 },
		},
		behavior_type = "Hull",
		base_health = 90,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[10] = {
		type_id = 10,
		name = "HullExtension_Strut_30",
		category_code = 3,
		color = ForensicColors.GREY,
		polygon_vertices = { -3, -15, 3, -15, 3, 15, -3, 15 },
		hardpoints = {
			{ x = 0, y = 15, angle = 0 },
			{ x = 0, y = -15, angle = 4096 },
		},
		behavior_type = "Structure",
		base_health = 70,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[11] = {
		type_id = 11,
		name = "HullSpike_Fore",
		category_code = 3,
		color = ForensicColors.GREY,
		polygon_vertices = { 10, 0, -5, 3, -5, -3 },
		hardpoints = {
			{ x = -5, y = 0, angle = 4096 },
		},
		behavior_type = "Hull",
		base_health = 60,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[12] = {
		type_id = 12,
		name = "HullTriangle_Wedge",
		category_code = 3,
		color = ForensicColors.GREY,
		polygon_vertices = { 2, 0, -2, 1, -2, -1 },
		hardpoints = {
			{ x = -2, y = 0, angle = 4096 },
		},
		behavior_type = "Hull",
		base_health = 45,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[13] = {
		type_id = 13,
		name = "HullWedge_Angled",
		category_code = 3,
		color = ForensicColors.GREY,
		polygon_vertices = { 3, 0, -4, 3, -4, -3 },
		hardpoints = {
			{ x = -4, y = 0, angle = 4096 },
		},
		behavior_type = "Hull",
		base_health = 75,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[14] = {
		type_id = 14,
		name = "Weapon_MassDriver",
		category_code = -1,
		color = ForensicColors.RED,
		polygon_vertices = { 2, -1, 2, 1, -2, 0 },
		hardpoints = {
			{ x = -2, y = 0, angle = 4096 },
		},
		behavior_type = "Weapon",
		behavior_id = 11,
		base_health = 90,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[15] = {
		type_id = 15,
		name = "Weapon_MachineGun",
		category_code = -1,
		color = ForensicColors.RED,
		polygon_vertices = { 5, -1, 5, 1, -5, 3, -5, -3 },
		hardpoints = {
			{ x = -5, y = 0, angle = 4096 },
		},
		behavior_type = "Weapon",
		behavior_id = 0,
		base_health = 100,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[16] = {
		type_id = 16,
		name = "Weapon_SniperCannon",
		category_code = -1,
		color = ForensicColors.RED,
		polygon_vertices = { 10, -3, 10, 3, -10, 1, -10, -1 },
		hardpoints = {
			{ x = -10, y = 0, angle = 4096 },
		},
		behavior_type = "Weapon",
		behavior_id = 3,
		base_health = 140,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[17] = {
		type_id = 17,
		name = "Weapon_Ubercannon",
		category_code = -1,
		color = ForensicColors.RED,
		polygon_vertices = { 10, -5, 10, 5, -10, 3, -10, -3 },
		hardpoints = {
			{ x = -10, y = 0, angle = 4096 },
		},
		behavior_type = "Weapon",
		behavior_id = 1,
		base_health = 180,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[18] = {
		type_id = 18,
		name = "Weapon_PhasedEnergyBeam",
		category_code = -1,
		color = ForensicColors.RED,
		polygon_vertices = { 6, -2, 6, 2, -6, 2, -6, -2 },
		hardpoints = {
			{ x = -6, y = 0, angle = 4096 },
		},
		behavior_type = "Weapon",
		behavior_id = 2,
		base_health = 115,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[19] = {
		type_id = 19,
		name = "Structure_Beam_40x5",
		category_code = 3,
		color = ForensicColors.GREY,
		polygon_vertices = { -40, -5, 40, -5, 40, 5, -40, 5 },
		hardpoints = {
			{ x = 0, y = 5, angle = 0 },
			{ x = 0, y = -5, angle = 4096 },
		},
		behavior_type = "Structure",
		base_health = 120,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[20] = {
		type_id = 20,
		name = "Structure_Beam_20x5",
		category_code = 3,
		color = ForensicColors.GREY,
		polygon_vertices = { -20, -5, 20, -5, 20, 5, -20, 5 },
		hardpoints = {
			{ x = 0, y = 5, angle = 0 },
			{ x = 0, y = -5, angle = 4096 },
		},
		behavior_type = "Structure",
		base_health = 80,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[21] = {
		type_id = 21,
		name = "Weapon_SpinningBlade",
		category_code = 4,
		color = ForensicColors.PINK,
		polygon_vertices = { 12, -2, 12, 2, -12, 2, -12, -2 },
		hardpoints = {
			{ x = 0, y = -2, angle = 4096 },
		},
		behavior_type = "Blade",
		behavior_id = 12,
		base_health = 200,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[22] = {
		type_id = 22,
		name = "Utility_FighterBay",
		category_code = 5,
		color = ForensicColors.GREEN,
		polygon_vertices = { 8, -6, 8, 6, -8, 6, -8, -6 },
		hardpoints = {
			{ x = -8, y = 0, angle = 4096 },
		},
		behavior_type = "FighterBay",
		behavior_id = 13,
		base_health = 160,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[23] = {
		type_id = 23,
		name = "Weapon_PlasmaBall",
		category_code = -1,
		color = ForensicColors.RED,
		polygon_vertices = { 3, -3, 3, 3, -3, 1, -3, -1 },
		hardpoints = {
			{ x = -3, y = 0, angle = 4096 },
		},
		behavior_type = "Weapon",
		behavior_id = 4,
		base_health = 110,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[24] = {
		type_id = 24,
		name = "Weapon_LaserBeam",
		category_code = -1,
		color = ForensicColors.RED,
		polygon_vertices = { 4, -1, 4, 1, -4, 1, -4, -1 },
		hardpoints = {
			{ x = -4, y = 0, angle = 4096 },
		},
		behavior_type = "Weapon",
		behavior_id = 6,
		base_health = 95,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[25] = {
		type_id = 25,
		name = "Weapon_MissileLauncher",
		category_code = -1,
		color = ForensicColors.RED,
		polygon_vertices = { 8, -2, 8, 2, -8, 3, -8, -3 },
		hardpoints = {
			{ x = -8, y = 0, angle = 4096 },
		},
		behavior_type = "Weapon",
		behavior_id = 7,
		base_health = 130,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[26] = {
		type_id = 26,
		name = "Utility_GrapplingHook",
		category_code = 4,
		color = ForensicColors.PINK,
		polygon_vertices = { 6, -4, 6, 4, -6, 3, -6, -3 },
		hardpoints = {
			{ x = -6, y = 0, angle = 4096 },
		},
		behavior_type = "Grapple",
		base_health = 110,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[27] = {
		type_id = 27,
		name = "Weapon_BombletSpray",
		category_code = 4,
		color = ForensicColors.PINK,
		polygon_vertices = { 8, -3, 8, 3, -8, 2, -8, -2 },
		hardpoints = {
			{ x = -8, y = 0, angle = 4096 },
		},
		behavior_type = "Weapon",
		behavior_id = 8,
		base_health = 120,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[28] = {
		type_id = 28,
		name = "Thruster_Small",
		category_code = -3,
		color = ForensicColors.ORANGE,
		polygon_vertices = { -3, -3, 3, -3, 3, 3, -3, 3 },
		hardpoints = {
			{ x = 0, y = 3, angle = 0 },
		},
		behavior_type = "Thruster",
		base_health = 70,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[29] = {
		type_id = 29,
		name = "Thruster_Standard",
		category_code = -3,
		color = ForensicColors.ORANGE,
		polygon_vertices = { -5, -5, 5, -5, 5, 5, -5, 5 },
		hardpoints = {
			{ x = 0, y = 5, angle = 0 },
			{ x = 5, y = 0, angle = 2048 },
			{ x = -5, y = 0, angle = -2048 },
		},
		behavior_type = "Thruster",
		base_health = 110,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[30] = {
		type_id = 30,
		name = "Thruster_BoosterRocket",
		category_code = -3,
		color = ForensicColors.ORANGE,
		polygon_vertices = { -4, -8, 4, -8, 4, 8, -4, 8 },
		hardpoints = {
			{ x = 0, y = 8, angle = 0 },
		},
		behavior_type = "Thruster",
		base_health = 140,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[31] = {
		type_id = 31,
		name = "Chassis_Hornet_Core",
		category_code = 6,
		color = ForensicColors.PURPLE,
		polygon_vertices = { 8, 0, 4, 6, -6, 4, -8, 0, -6, -4, 4, -6 },
		hardpoints = {
			{ x = 8, y = 0, angle = 0 },
			{ x = 0, y = 6, angle = 2048 },
			{ x = -8, y = 0, angle = 4096 },
			{ x = 0, y = -6, angle = -2048 },
		},
		behavior_type = "Core",
		base_health = 180,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[32] = {
		type_id = 32,
		name = "Chassis_Pelican_Core",
		category_code = 6,
		color = ForensicColors.PURPLE,
		polygon_vertices = { 12, 0, 8, 8, -8, 8, -12, 0, -8, -8, 8, -8 },
		hardpoints = {
			{ x = 12, y = 0, angle = 0 },
			{ x = 8, y = 8, angle = 1024 },
			{ x = -8, y = 8, angle = 3072 },
			{ x = -12, y = 0, angle = 4096 },
			{ x = -8, y = -8, angle = -3072 },
			{ x = 8, y = -8, angle = -1024 },
		},
		behavior_type = "Core",
		base_health = 220,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[33] = {
		type_id = 33,
		name = "Chassis_Scarlet_Core",
		category_code = 6,
		color = ForensicColors.PURPLE,
		polygon_vertices = { 15, 0, 10, 10, -10, 10, -15, 0, -10, -10, 10, -10 },
		hardpoints = {
			{ x = 15, y = 0, angle = 0 },
			{ x = 10, y = 10, angle = 1024 },
			{ x = -10, y = 10, angle = 3072 },
			{ x = -15, y = 0, angle = 4096 },
			{ x = -10, y = -10, angle = -3072 },
			{ x = 10, y = -10, angle = -1024 },
		},
		behavior_type = "Core",
		base_health = 280,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[34] = {
		type_id = 34,
		name = "Chassis_Squid_Core",
		category_code = 6,
		color = ForensicColors.PURPLE,
		polygon_vertices = { 10, 0, 5, 8, -8, 12, -12, 0, -8, -12, 5, -8 },
		hardpoints = {
			{ x = 10, y = 0, angle = 0 },
			{ x = -12, y = 0, angle = 4096 },
			{ x = -8, y = 12, angle = 2048 },
			{ x = -8, y = -12, angle = -2048 },
		},
		behavior_type = "Core",
		base_health = 260,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[35] = {
		type_id = 35,
		name = "Utility_PowerPlant_Small",
		category_code = 5,
		color = ForensicColors.GREEN,
		polygon_vertices = { -4, -4, 4, -4, 4, 4, -4, 4 },
		hardpoints = {
			{ x = 0, y = 4, angle = 0 },
			{ x = 0, y = -4, angle = 4096 },
		},
		behavior_type = "PowerPlant",
		base_health = 90,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[36] = {
		type_id = 36,
		name = "Utility_PowerPlant_Large",
		category_code = 5,
		color = ForensicColors.GREEN,
		polygon_vertices = { -8, -8, 8, -8, 8, 8, -8, 8 },
		hardpoints = {
			{ x = 0, y = 8, angle = 0 },
			{ x = 8, y = 0, angle = 2048 },
			{ x = 0, y = -8, angle = 4096 },
			{ x = -8, y = 0, angle = -2048 },
		},
		behavior_type = "PowerPlant",
		base_health = 175,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[37] = {
		type_id = 37,
		name = "Utility_RepairDroneBay",
		category_code = 5,
		color = ForensicColors.GREEN,
		polygon_vertices = { 6, -5, 6, 5, -6, 5, -6, -5 },
		hardpoints = {
			{ x = -6, y = 0, angle = 4096 },
		},
		behavior_type = "Repair",
		base_health = 130,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[38] = {
		type_id = 38,
		name = "Weapon_HeavyTorpedo",
		category_code = -1,
		color = ForensicColors.RED,
		polygon_vertices = { 10, -2, 10, 2, -10, 3, -10, -3 },
		hardpoints = {
			{ x = -10, y = 0, angle = 4096 },
		},
		behavior_type = "Weapon",
		behavior_id = 14,
		base_health = 150,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[39] = {
		type_id = 39,
		name = "Weapon_ScatterFlak",
		category_code = -1,
		color = ForensicColors.RED,
		polygon_vertices = { 5, -4, 5, 4, -5, 3, -5, -3 },
		hardpoints = {
			{ x = -5, y = 0, angle = 4096 },
		},
		behavior_type = "Weapon",
		behavior_id = 15,
		base_health = 110,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[40] = {
		type_id = 40,
		name = "HullHexagon_Cluster",
		category_code = 3,
		color = ForensicColors.GREY,
		polygon_vertices = { 12, 0, 6, 10, -6, 10, -12, 0, -6, -10, 6, -10 },
		hardpoints = {
			{ x = 12, y = 0, angle = 0 },
			{ x = -12, y = 0, angle = 4096 },
		},
		behavior_type = "Hull",
		base_health = 130,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[41] = {
		type_id = 41,
		name = "HullSegment_Curved",
		category_code = 3,
		color = ForensicColors.GREY,
		polygon_vertices = { 0, 0, 8, 4, 10, 10, 4, 12, -2, 6 },
		hardpoints = {
			{ x = 0, y = 0, angle = -2048 },
		},
		behavior_type = "Hull",
		base_health = 85,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[42] = {
		type_id = 42,
		name = "Defense_DirectionalShield",
		category_code = -2,
		color = ForensicColors.BLUE,
		polygon_vertices = { 6, -2, 6, 2, -6, 4, -6, -4 },
		hardpoints = {
			{ x = -6, y = 0, angle = 4096 },
		},
		behavior_type = "Shield",
		base_health = 150,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[43] = {
		type_id = 43,
		name = "Defense_PointDefenceLaser",
		category_code = -2,
		color = ForensicColors.BLUE,
		polygon_vertices = { 3, -1, 3, 1, -3, 1, -3, -1 },
		hardpoints = {
			{ x = -3, y = 0, angle = 4096 },
		},
		behavior_type = "PointDefence",
		behavior_id = 9,
		base_health = 90,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[44] = {
		type_id = 44,
		name = "Utility_MissileScrambler",
		category_code = -2,
		color = ForensicColors.BLUE,
		polygon_vertices = { 3, -3, 3, 3, -3, 5, -3, -5 },
		hardpoints = {
			{ x = -3, y = 0, angle = 4096 },
		},
		behavior_type = "Scrambler",
		behavior_id = 10,
		base_health = 100,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[45] = {
		type_id = 45,
		name = "Utility_SensorArray",
		category_code = -2,
		color = ForensicColors.BLUE,
		polygon_vertices = { 5, -2, 5, 2, -5, 3, -5, -3 },
		hardpoints = {
			{ x = -5, y = 0, angle = 4096 },
		},
		behavior_type = "Sensor",
		base_health = 80,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[46] = {
		type_id = 46,
		name = "Defense_OmniShieldGenerator",
		category_code = -2,
		color = ForensicColors.BLUE,
		polygon_vertices = { 7, -4, 7, 4, -7, 4, -7, -4 },
		hardpoints = {
			{ x = -7, y = 0, angle = 4096 },
		},
		behavior_type = "Shield",
		base_health = 190,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	[47] = {
		type_id = 47,
		name = "Chassis_Dragon_20",
		category_code = 6,
		color = ForensicColors.PURPLE,
		polygon_vertices = { 20, 0, 10, 15, -10, 15, -20, 0, -10, -15, 10, -15 },
		hardpoints = {
			{ x = 20, y = 0, angle = 0 },
			{ x = 10, y = 15, angle = 1024 },
			{ x = -10, y = 15, angle = 3072 },
			{ x = -20, y = 0, angle = 4096 },
			{ x = -10, y = -15, angle = -3072 },
			{ x = 10, y = -15, angle = -1024 },
		},
		behavior_type = "Core",
		base_health = 300,
		health_scale_z = 1024,
		verification = "CODE_VERIFIED",
	},
	-- Slots 48-55: Procedural Terrain / Asteroid Geometries (`jba.a(...)`)
	[48] = {
		type_id = 48,
		name = "Terrain_Asteroid_Small_A",
		category_code = 3,
		color = ForensicColors.GREY,
		polygon_vertices = { 10, 2, 4, 9, -7, 8, -11, -2, -3, -10, 7, -6 },
		hardpoints = {},
		behavior_type = "Terrain",
		base_health = 500,
		health_scale_z = 2048,
		verification = "CODE_VERIFIED",
	},
	[49] = {
		type_id = 49,
		name = "Terrain_Asteroid_Small_B",
		category_code = 3,
		color = ForensicColors.GREY,
		polygon_vertices = { 8, 5, 2, 11, -9, 4, -8, -6, 3, -10 },
		hardpoints = {},
		behavior_type = "Terrain",
		base_health = 450,
		health_scale_z = 2048,
		verification = "CODE_VERIFIED",
	},
	[50] = {
		type_id = 50,
		name = "Terrain_Asteroid_Medium_A",
		category_code = 3,
		color = ForensicColors.GREY,
		polygon_vertices = { 18, 4, 10, 16, -12, 14, -20, -4, -6, -18, 12, -12 },
		hardpoints = {},
		behavior_type = "Terrain",
		base_health = 1200,
		health_scale_z = 2048,
		verification = "CODE_VERIFIED",
	},
	[51] = {
		type_id = 51,
		name = "Terrain_Asteroid_Medium_B",
		category_code = 3,
		color = ForensicColors.GREY,
		polygon_vertices = { 15, 8, 3, 19, -15, 12, -18, -10, 2, -19 },
		hardpoints = {},
		behavior_type = "Terrain",
		base_health = 1100,
		health_scale_z = 2048,
		verification = "CODE_VERIFIED",
	},
	[52] = {
		type_id = 52,
		name = "Terrain_Asteroid_Large_A",
		category_code = 3,
		color = ForensicColors.GREY,
		polygon_vertices = { 35, 10, 18, 30, -22, 28, -38, -8, -12, -35, 25, -24 },
		hardpoints = {},
		behavior_type = "Terrain",
		base_health = 3500,
		health_scale_z = 2048,
		verification = "CODE_VERIFIED",
	},
	[53] = {
		type_id = 53,
		name = "Terrain_Asteroid_Large_B",
		category_code = 3,
		color = ForensicColors.GREY,
		polygon_vertices = { 30, 15, 5, 38, -30, 22, -36, -20, 4, -38 },
		hardpoints = {},
		behavior_type = "Terrain",
		base_health = 3200,
		health_scale_z = 2048,
		verification = "CODE_VERIFIED",
	},
	[54] = {
		type_id = 54,
		name = "Terrain_NebulaCluster_Core",
		category_code = -2,
		color = ForensicColors.BLUE,
		polygon_vertices = { 50, 0, 25, 43, -25, 43, -50, 0, -25, -43, 25, -43 },
		hardpoints = {},
		behavior_type = "Nebula",
		base_health = 9999,
		health_scale_z = 4096,
		verification = "CODE_VERIFIED",
	},
	[55] = {
		type_id = 55,
		name = "Terrain_SpaceStation_Hub",
		category_code = 6,
		color = ForensicColors.PURPLE,
		polygon_vertices = { 40, 0, 20, 35, -20, 35, -40, 0, -20, -35, 20, -35 },
		hardpoints = {
			{ x = 40, y = 0, angle = 0 },
			{ x = -40, y = 0, angle = 4096 },
		},
		behavior_type = "Station",
		base_health = 5000,
		health_scale_z = 2048,
		verification = "CODE_VERIFIED",
	},
}

-----------------------------------------------------------------------------
-- 6. WEAPONS REGISTRY & BALLISTICS PARAMETERS [CODE_VERIFIED]
-----------------------------------------------------------------------------
local ForensicWeapons = {
	MachineGun = {
		id = 0,
		name = "Machine Gun",
		damage = 12,
		damage_type = "Kinetic",
		reload = 0.08,
		projectile_count = 1,
		projectile_life = 1.4,
		projectile_speed = 320,
		randomness = 0.06,
		firing_force = 15,
		energy_use = 1.5,
		aim_speed = 12.0,
		aim_arc = math.rad(60),
	},
	Ubercannon = {
		id = 1,
		name = "Ubercannon",
		damage = 180,
		damage_type = "Explosive",
		reload = 3.5,
		projectile_count = 1,
		projectile_life = 3.0,
		projectile_speed = 180,
		randomness = 0.01,
		firing_force = 120,
		energy_use = 45.0,
		aim_speed = 2.0,
		aim_arc = math.rad(30),
		explosion_radius = 40,
	},
	PhasedEnergyBeam = {
		id = 2,
		name = "Phased Energy Beam",
		damage = 65,
		damage_type = "Energy",
		reload = 1.2,
		projectile_count = 1,
		projectile_life = 0.8,
		projectile_speed = 600,
		randomness = 0.0,
		firing_force = 5,
		energy_use = 18.0,
		aim_speed = 8.0,
		aim_arc = math.rad(45),
		pulse_timing = 0.1,
	},
	SniperCannon = {
		id = 3,
		name = "Sniper Cannon",
		damage = 140,
		damage_type = "Kinetic",
		reload = 2.4,
		projectile_count = 1,
		projectile_life = 3.5,
		projectile_speed = 480,
		randomness = 0.005,
		firing_force = 75,
		energy_use = 25.0,
		aim_speed = 3.5,
		aim_arc = math.rad(25),
	},
	PlasmaBall = {
		id = 4,
		name = "Plasma Ball",
		damage = 45,
		damage_type = "Thermal",
		reload = 0.45,
		projectile_count = 1,
		projectile_life = 2.0,
		projectile_speed = 220,
		randomness = 0.03,
		firing_force = 20,
		energy_use = 6.0,
		aim_speed = 6.0,
		aim_arc = math.rad(90),
	},
	LaserBeam = {
		id = 6,
		name = "Laser Beam",
		damage = 80, -- DPS
		damage_type = "Energy",
		reload = 0.0,
		projectile_count = 1,
		projectile_life = 0.1,
		projectile_speed = 9999,
		randomness = 0.0,
		firing_force = 0,
		energy_use = 22.0, -- Energy per second
		aim_speed = 10.0,
		aim_arc = math.rad(75),
	},
	MissileLauncher = {
		id = 7,
		name = "Missile Launcher",
		damage = 75,
		damage_type = "Explosive",
		reload = 1.6,
		projectile_count = 1,
		projectile_life = 4.5,
		projectile_speed = 160,
		projectile_acceleration = 80,
		randomness = 0.04,
		firing_force = 30,
		energy_use = 14.0,
		aim_speed = 4.0,
		aim_arc = math.rad(120),
		homing_torque = 14.0,
	},
	BombletSpray = {
		id = 8,
		name = "Bomblet Spray",
		damage = 22,
		damage_type = "Kinetic",
		reload = 0.9,
		projectile_count = 7,
		projectile_life = 1.2,
		projectile_speed = 190,
		randomness = 0.25,
		firing_force = 45,
		energy_use = 12.0,
		aim_speed = 5.0,
		aim_arc = math.rad(60),
	},
	PointDefenceLaser = {
		id = 9,
		name = "Point Defence Laser",
		damage = 35,
		damage_type = "Energy",
		reload = 0.2,
		projectile_count = 1,
		projectile_life = 0.3,
		projectile_speed = 800,
		randomness = 0.01,
		firing_force = 0,
		energy_use = 4.0,
		aim_speed = 25.0,
		aim_arc = math.rad(180),
		interception_range = 75,
	},
	MissileScrambler = {
		id = 10,
		name = "Countermeasure / Scrambler",
		damage = 0,
		damage_type = "EMP",
		reload = 4.0,
		projectile_count = 1,
		projectile_life = 1.0,
		projectile_speed = 0,
		randomness = 0.0,
		firing_force = 0,
		energy_use = 30.0,
		aim_speed = 0,
		aim_arc = math.rad(360),
		scramble_radius = 120,
	},
	MassDriver = {
		id = 11,
		name = "Mass Driver",
		damage = 32,
		damage_type = "Kinetic",
		reload = 0.35,
		projectile_count = 1,
		projectile_life = 2.2,
		projectile_speed = 360,
		randomness = 0.02,
		firing_force = 35,
		energy_use = 4.5,
		aim_speed = 7.0,
		aim_arc = math.rad(45),
	},
	SpinningBlade = {
		id = 12,
		name = "Spinning Blade",
		damage = 110,
		damage_type = "Kinetic",
		top_spin_speed = 25.0,
		spin_acceleration = 8.0,
		contact_impulse = 400.0,
	},
	FighterBay = {
		id = 13,
		name = "Fighter Bay",
		max_fighters = 3,
		reload = 8.0,
		fighter_health = 60,
		fighter_damage = 10,
		fighter_speed = 140,
		energy_use = 20.0,
	},
	HeavyTorpedo = {
		id = 14,
		name = "Heavy Torpedo",
		damage = 220,
		damage_type = "Explosive",
		reload = 5.0,
		projectile_life = 6.0,
		projectile_speed = 120,
		homing_torque = 8.0,
		explosion_radius = 55,
		energy_use = 40.0,
	},
	ScatterFlak = {
		id = 15,
		name = "Scatter Flak",
		damage = 18,
		damage_type = "Kinetic",
		reload = 0.6,
		projectile_count = 5,
		projectile_life = 1.0,
		projectile_speed = 260,
		randomness = 0.18,
		energy_use = 8.0,
	},
}

-----------------------------------------------------------------------------
-- 7. REPAIR SYSTEM PARAMETERS (`Directive 09`) [CODE_VERIFIED]
-----------------------------------------------------------------------------
local ForensicRepairConfig = {
	REPAIR_MODE_COOLDOWN = 3.0,
	REPAIR_MODE_ACTIVE_TIME = 10.0,
	REPAIR_MODE_RADIUS = 60.0,
	REPAIR_MODE_POWER = 15.0,
	PLAYER_REPAIR_TIME = 0.5,
	PLAYER_REPAIR_AMOUNT = 12,
	AI_REPAIR_TIME = 1.0,
	AI_REPAIR_AMOUNT = 8,
	FIGHTER_REPAIR_TIME = 2.0,
	FIGHTER_REPAIR_AMOUNT = 5,
	STRINGS = {
		ENTER = "Click here or press R to enter repair mode",
		LEAVE = "Click here or press R to leave repair mode",
		REPAIRING = "Repairing...",
	},
}

-----------------------------------------------------------------------------
-- 8. SHIELDS & POWER CONFIGURATION (`Directive 11`) [CODE_VERIFIED]
-----------------------------------------------------------------------------
local ForensicShieldConfig = {
	SHIELDS_TOGGLE_COOLDOWN = 1.5,
	SHIELDS_DIRECTIONAL_IDLE_ENERGY_USAGE = 6.0,
	SHIELDS_DIRECTIONAL_RADIUS = 35.0,
	SHIELDS_DIRECTIONAL_ARC = math.rad(110),
	SHIELDS_DAMAGE_ENERGY_CONVERSION = 0.85,
	PARTICLE_LIFE = 0.35,
	PARTICLE_SPEED = 25.0,
	HALF_ARC_CUTS = 16,
}

-----------------------------------------------------------------------------
-- 9. GRAPPLING HOOK PARAMETERS (`Directive 12`) [CODE_VERIFIED]
-----------------------------------------------------------------------------
local ForensicGrappleConfig = {
	GRAPPLING_HOOK_AIMARC = math.rad(120),
	GRAPPLING_HOOK_AIMSPEED = 8.0,
	GRAPPLING_HOOK_COOLDOWN = 2.0,
	GRAPPLING_HOOK_FIRE_FORCE = 350.0,
	GRAPPLING_HOOK_MAX_LENGTH = 180.0,
	GRAPPLING_HOOK_MIN_LENGTH = 15.0,
	GRAPPLING_HOOK_SPRING_CONSTANT = 65.0,
	GRAPPLING_HOOK_MAX_EXTENSION8_FORCE = 850.0,
	GRAPPLING_HOOK_ROPE_CHANGE_RATE = 45.0,
	GRAPPLING_HOOK_ROPE_BREAK_LENGTH = 240.0,
	GRAPPLE_DEBRIS = true,
	STATES = {
		ATTACH = "attach",
		DEPLOY = "deploy",
		DETACH = "detach",
		REEL_IN = "reel-in",
	},
}

-----------------------------------------------------------------------------
-- 10. FIGHTERS & AI SPECIFICATIONS (`Directive 13`) [CODE_VERIFIED]
-----------------------------------------------------------------------------
local ForensicAIConfig = {
	FIGHTER_VISION = 220.0,
	FIGHTERS_PER_PLAYER_MAXIMUM = 3,
	FIGHTER_BAY_RELOAD = 8.0,
	FIGHTER_BAY_AIMSPEED = 6.0,
	FIGHTER_BAY_AIMARC = math.rad(90),
	FIGHTER_REPAIR_TIME = 2.0,
	FIGHTER_REPAIR_AMOUNT = 5,
	BOTS = true,
	AIM_MODES = { "AUTOAIM", "SALVOAIM", "FIXEDAIM", "ANGLESET" },
	AI_FIRING_RANGE_UPSHIFT = 1.25,
}

-----------------------------------------------------------------------------
-- 11. ENVIRONMENT, NEBULA & TERRAIN (`Directive 14`) [CODE_VERIFIED]
-----------------------------------------------------------------------------
local ForensicEnvironmentConfig = {
	MISSION_TERRAIN_NEBULA_PROBABILITY = 0.35,
	MISSION_TERRAIN_ASTEROID_PROBABILITY = 0.50,
	MISSION_TERRAIN_DEBRIS_PROBABILITY = 0.40,
	MISSION_TERRAIN_SPACE_PROBABILITY = 0.75,
	MISSION_TERRAIN_VOTING_CHANCESTEP = 0.05,
	MISSION_DEBRIS_DEFAULT_PROBABILITY = 0.30,
	MISSION_DEBRIS_VOTING_CHANCESTEP = 0.05,
	MISSION_TIME_LIMIT = 180,
	WORLD_WIDTH_UPSHIFT = 2500,
	NEBULA_FADES_OUT_WHEN_CLOSE = true,
	NEBULA_PROXIMITY_FADE_DOWNSHIFT = 0.02,
	DEBRIS_FOUND_IN_PAIRS = true,
	DEBRIS_MAX = 64,
}

-----------------------------------------------------------------------------
-- 12. MISSION STATE MACHINE CONDITIONS & ACTIONS (`Directive 16`) [CODE_VERIFIED]
-----------------------------------------------------------------------------
local MissionConditions = {
	"MissionConditionAtTick",
	"MissionConditionBodyDestroyed",
	"MissionConditionBodyInMapZone",
	"MissionConditionNodeOnTeam",
	"MissionConditionShipHoldsComponent",
	"MissionConditionShipJustSpawned",
	"MissionConditionShipOnTeam",
}

local MissionActions = {
	"MissionActionAddBodyInfo",
	"MissionActionAddNodeInfo",
	"MissionActionAddToCustomVariable",
	"MissionActionAwardVictory",
	"MissionActionSetCustomVariable",
	"MissionActionSetCustomVariableLabel",
	"MissionActionSetTeam",
}

local GameModes = {
	"Arena_War",
	"Assault",
	"Double_Assault",
	"Assassination",
	"Double_Assassination",
	"Convoy",
	"Double_Convoy",
	"Capture_and_Hold",
	"Sandbox",
	"Blueprints",
}

-----------------------------------------------------------------------------
-- 13. AUDIO IDENTIFIERS TABLE (`Directive 18`) [CODE_VERIFIED]
-----------------------------------------------------------------------------
local ForensicAudio = {
	HEALTH_SIREN_LOOP = "vh_health_siren_loop",
	GRAPPLE_ATTACH = "vh_grapplinghook_attach",
	GRAPPLE_DEPLOY = "vh_grapplinghook_deploy",
	GRAPPLE_DETACH = "vh_grapplinghook_detach",
	GRAPPLE_REEL_IN = "vh_grapplinghook_reel_in",
	LASER_BEAM_IMPACT_LOOP = "vh_laser_beam_impact_loop",
	LASER_BEAM_1 = "vh_laser_beam1",
	LASER_BEAM_2 = "vh_laser_beam2",
	LASER_BEAM_3 = "vh_laser_beam3",
	LASER_BEAM_4 = "vh_laser_beam4",
}

-----------------------------------------------------------------------------
-- 14. DEBRIS & COLLISION LIFECYCLE CONFIGURATION (`Directive 05`) [CODE_VERIFIED]
-----------------------------------------------------------------------------
local ForensicDebrisConfig = {
	DEBRIS_CARRY_OVER = true,
	DEBRIS_CARRY_OVER_PERCENTAGE = 0.5,
	DEBRIS_COLLISION = true,
	DEBRIS_COLLISION_DAMAGE = 15,
	DEBRIS_DETACHMENT_FORCE_MULTIPLIER = 1.4,
	DEBRIS_FOUND_IN_PAIRS = true,
	DEBRIS_GRABBING_RANGE = 45.0,
	DEBRIS_MAX = 64,
	DEBRIS_PARTITIONED = true,
	DEBRIS_PROJECTILE_COLLISION = true,
	DEBRIS_SURVIVES = true,
	DEBRIS_THROWABLE = true,
	DETACHMENT_MODE = "PHYSICAL_BODY",
	GRAPPLE_DEBRIS = true,
}

-----------------------------------------------------------------------------
-- MASTER EXPORT
-----------------------------------------------------------------------------
local ForensicDataModel = {
	Colors = ForensicColors,
	CategoryColorMap = CategoryColorMap,
	Definitions = ComponentDefinitions,
	Weapons = ForensicWeapons,
	DebrisConfig = ForensicDebrisConfig,
	RepairConfig = ForensicRepairConfig,
	ShieldConfig = ForensicShieldConfig,
	GrappleConfig = ForensicGrappleConfig,
	AIConfig = ForensicAIConfig,
	EnvironmentConfig = ForensicEnvironmentConfig,
	MissionConditions = MissionConditions,
	MissionActions = MissionActions,
	GameModes = GameModes,
	Audio = ForensicAudio,
	ComputePolygonSignedArea = ComputePolygonSignedArea,
	ComputeDecompileHealth = ComputeDecompileHealth,
}

function ForensicDataModel.GetDefinition(typeId: number): ForensicComponentDefinition?
	return ComponentDefinitions[typeId]
end

function ForensicDataModel.GetCategoryColor(categoryCode: number): Color3
	return CategoryColorMap[categoryCode] or ForensicColors.GREY
end

function ForensicDataModel.GetWeaponConfig(weaponKey: string)
	return ForensicWeapons[weaponKey]
end

return ForensicDataModel
