-- VOID HUNTERS COMPONENTS (7-stud base unit, connection-based building)
-- Connection system:
--   InConnect = SOCKET (receives parts - hulls/cores have these)
--   OutConnect = PLUG (connects TO parts - weapons/utility/armor have these)
--   Hull pieces have BOTH: InConnects to receive, OutConnect to chain

local Components = {}
Components.UNIT = 7
Components.HEIGHT = 3.5
Components.Categories = {MOVEMENT="Movement", DEFENSE="Defense", OFFENSE="Offense", UTILITY="Utility", STRUCTURE="Structure"}

-- Build mode settings
Components.BUILD_RADIUS = 300
Components.DRAG_RADIUS = 350
Components.SNAP_DISTANCE = 5

-- Attachment positions (7-stud grid)
Components.AttachmentOffsets = {
	InConnect_Front = Vector3.new(0, 0, 3.5),
	InConnect_Back = Vector3.new(0, 0, -3.5),
	InConnect_Left = Vector3.new(-3.5, 0, 0),
	InConnect_Right = Vector3.new(3.5, 0, 0),
	
	InConnect_Hex1 = Vector3.new(3.5, 0, 0),
	InConnect_Hex2 = Vector3.new(1.75, 0, 3),
	InConnect_Hex3 = Vector3.new(-1.75, 0, 3),
	InConnect_Hex4 = Vector3.new(-3.5, 0, 0),
	InConnect_Hex5 = Vector3.new(-1.75, 0, -3),
	OutConnect_Hex = Vector3.new(1.75, 0, -3),
	
	OutConnect_Back = Vector3.new(0, 0, -3.5),
	OutConnect_Front = Vector3.new(0, 0, 3.5),
	OutConnect_Bottom = Vector3.new(0, -3.5, 0),
	
	Muzzle = Vector3.new(0, 0, 4),
	ThrusterOut = Vector3.new(0, 0, -4),
	DroneSpawn = Vector3.new(0, 0, 0),
	ShieldOrigin = Vector3.new(0, 0, 0),
	EnergyOutput = Vector3.new(0, 0, 0),
	PulseOrigin = Vector3.new(0, 0, 0)
}

Components.Connections = {
	CommandCore = {
		InConnectCount = 4,
		OutConnectCount = 0,
		InConnectPositions = {"InConnect_Front", "InConnect_Back", "InConnect_Left", "InConnect_Right"},
		HasWeaponConnect = false,
		MeshAttachmentPositions = {
			InConnect_1 = Vector3.new(0, 0, 4.65),
			InConnect_2 = Vector3.new(0, 0, -4.65),
			InConnect_3 = Vector3.new(-4.63, 0, 0),
			InConnect_4 = Vector3.new(4.63, 0, 0)
		}
	},
	DragonCore = {
		InConnectCount = 6,
		OutConnectCount = 0,
		InConnectPositions = {"InConnect_Back", "InConnect_Back", "InConnect_Left", "InConnect_Right", "InConnect_Front", "InConnect_Front"},
		HasWeaponConnect = false,
		MeshAttachmentPositions = {
			InConnect_1 = Vector3.new(-3.5, 0, 3.5),
			InConnect_2 = Vector3.new(3.5, 0, 3.5),
			InConnect_3 = Vector3.new(-1.75, 0, 0),
			InConnect_4 = Vector3.new(1.75, 0, 0),
			InConnect_5 = Vector3.new(0, 0, -1.75),
			InConnect_6 = Vector3.new(0, 0, -1.75),
		}
	},
	PelicanCore = {
		InConnectCount = 4,
		OutConnectCount = 0,
		InConnectPositions = {"InConnect_Back", "InConnect_Front", "InConnect_Left", "InConnect_Right"},
		HasWeaponConnect = false,
		MeshAttachmentPositions = {
			InConnect_1 = Vector3.new(0, 0, 10.5),
			InConnect_2 = Vector3.new(0, 0, -10.5),
			InConnect_3 = Vector3.new(-3.5, 0, 0),
			InConnect_4 = Vector3.new(3.5, 0, 0),
		}
	},
	HornetCore = {
		InConnectCount = 4,
		OutConnectCount = 0,
		InConnectPositions = {"InConnect_Front", "InConnect_Right", "InConnect_Back", "InConnect_Left"},
		HasWeaponConnect = false,
		MeshAttachmentPositions = {
			InConnect_1 = Vector3.new(0, 0, -0.75),
			InConnect_2 = Vector3.new(0.75, 0, 0),
			InConnect_3 = Vector3.new(0, 0, 0.75),
			InConnect_4 = Vector3.new(-0.75, 0, 0),
		}
	},
	ScarletCore = {
		InConnectCount = 4,
		OutConnectCount = 0,
		InConnectPositions = {"InConnect_Front", "InConnect_Back", "InConnect_Left", "InConnect_Right"},
		HasWeaponConnect = false,
		MeshAttachmentPositions = {
			InConnect_1 = Vector3.new(0, 0, -7),
			InConnect_2 = Vector3.new(0, 0, 7),
			InConnect_3 = Vector3.new(-7, 0, 0),
			InConnect_4 = Vector3.new(7, 0, 0),
		}
	},
	HullHeavy = {
		InConnectCount = 3,
		OutConnectCount = 1,
		InConnectPositions = {"InConnect_Front", "InConnect_Left", "InConnect_Right"},
		OutConnectPosition = "OutConnect_Back",
		HasWeaponConnect = false
	},
	HullMedium = {
		InConnectCount = 3,
		OutConnectCount = 1,
		InConnectPositions = {"InConnect_Front", "InConnect_Left", "InConnect_Right"},
		OutConnectPosition = "OutConnect_Back",
		HasWeaponConnect = false
	},
	HullSmall = {
		InConnectCount = 3,
		OutConnectCount = 1,
		InConnectPositions = {"InConnect_Front", "InConnect_Left", "InConnect_Right"},
		OutConnectPosition = "OutConnect_Back",
		HasWeaponConnect = false
	},
	Hull1x1 = {
		InConnectCount = 3,
		OutConnectCount = 1,
		InConnectPositions = {"InConnect_Front", "InConnect_Left", "InConnect_Right"},
		OutConnectPosition = "OutConnect_Back"
	},
	Hull3x1 = {
		InConnectCount = 3,
		OutConnectCount = 1,
		InConnectPositions = {"InConnect_Front", "InConnect_Left", "InConnect_Right"},
		OutConnectPosition = "OutConnect_Back"
	},
	HullHex = {
		InConnectCount = 5,
		OutConnectCount = 1,
		InConnectPositions = {"InConnect_Hex1", "InConnect_Hex2", "InConnect_Hex3", "InConnect_Hex4", "InConnect_Hex5"},
		OutConnectPosition = "OutConnect_Hex"
	},
	Armor1x1 = {
		InConnectCount = 0,
		OutConnectCount = 1,
		OutConnectPosition = "OutConnect_Back",
		IsArmor = true
	},
	HullBlock = {
		InConnectCount = 4,
		OutConnectCount = 0,
		InConnectPositions = {"InConnect_Front", "InConnect_Back", "InConnect_Left", "InConnect_Right"},
		HasWeaponConnect = false
	},
	HullBeam = {
		InConnectCount = 3,
		OutConnectCount = 1,
		InConnectPositions = {"InConnect_Front", "InConnect_Left", "InConnect_Right"},
		OutConnectPosition = "OutConnect_Back",
		HasWeaponConnect = false
	},
	HullDiamond = {
		InConnectCount = 4,
		OutConnectCount = 0,
		InConnectPositions = {"InConnect_Front", "InConnect_Back", "InConnect_Left", "InConnect_Right"},
		HasWeaponConnect = false
	},
	HullHexagon = {
		InConnectCount = 6,
		OutConnectCount = 0,
		InConnectPositions = {"InConnect_Hex1", "InConnect_Hex2", "InConnect_Hex3", "InConnect_Hex4", "InConnect_Hex5", "OutConnect_Hex"},
		HasWeaponConnect = false
	},
	HullLattice = {
		InConnectCount = 4,
		OutConnectCount = 0,
		InConnectPositions = {"InConnect_Front", "InConnect_Back", "InConnect_Left", "InConnect_Right"},
		HasWeaponConnect = false
	},
	HullPlate2 = {
		InConnectCount = 2,
		OutConnectCount = 0,
		InConnectPositions = {"InConnect_Front", "InConnect_Back"},
		HasWeaponConnect = false
	},
	HullSpike = {
		InConnectCount = 2,
		OutConnectCount = 1,
		InConnectPositions = {"InConnect_Left", "InConnect_Right"},
		OutConnectPosition = "OutConnect_Back"
	},
	HullTriangle = {
		InConnectCount = 2,
		OutConnectCount = 1,
		OutConnectPosition = "OutConnect_Front",
		IsModule = true,
		MeshAttachmentPositions = {
			OutConnect = Vector3.new(0, 0, -2.02),
			InConnect_1 = Vector3.new(-1.75, 0, 1.01),
			InConnect_2 = Vector3.new(1.75, 0, 1.01)
		}
	},
	HullLeftWing = {
		InConnectCount = 2,
		OutConnectCount = 1,
		InConnectPositions = {"InConnect_Front", "InConnect_Right"},
		OutConnectPosition = "OutConnect_Back",
		HasWeaponConnect = false
	},
	HullRightWing = {
		InConnectCount = 2,
		OutConnectCount = 1,
		InConnectPositions = {"InConnect_Front", "InConnect_Left"},
		OutConnectPosition = "OutConnect_Back",
		HasWeaponConnect = false
	},
	ArmourBig = {
		InConnectCount = 0,
		OutConnectCount = 1,
		OutConnectPosition = "OutConnect_Back",
		IsArmor = true
	},
	ArmourPlate = {
		InConnectCount = 0,
		OutConnectCount = 1,
		OutConnectPosition = "OutConnect_Back",
		IsArmor = true
	},
	ArmourSmall = {
		InConnectCount = 0,
		OutConnectCount = 1,
		OutConnectPosition = "OutConnect_Back",
		IsArmor = true
	},
	StandardEngine = {
		InConnectCount = 0,
		OutConnectCount = 1,
		OutConnectPosition = "OutConnect_Front",
		IsModule = true,
		MuzzlePosition = "ThrusterOut",
		MeshAttachmentPositions = {
			OutConnect = Vector3.new(0, 0, -3.5),
			ThrusterOut = Vector3.new(0, 2, 4.5)
		}
	},
	DualEngine = {
		InConnectCount = 0,
		OutConnectCount = 1,
		OutConnectPosition = "OutConnect_Front",
		IsModule = true,
		MuzzlePosition = "ThrusterOut",
		MeshAttachmentPositions = {
			OutConnect = Vector3.new(0, 0, -7),
			ThrusterOut = Vector3.new(0, 3, 5.25)
		}
	},
	HeavyThruster = {
		InConnectCount = 0,
		OutConnectCount = 1,
		OutConnectPosition = "OutConnect_Front",
		IsModule = true,
		MuzzlePosition = "ThrusterOut",
		MeshAttachmentPositions = {
			OutConnect = Vector3.new(0, 0, -7),
			ThrusterOut = Vector3.new(0, 2.5, 7.5)
		}
	},
	SteeringJet = {
		InConnectCount = 0,
		OutConnectCount = 1,
		OutConnectPosition = "OutConnect_Front",
		IsModule = true,
		MuzzlePosition = "ThrusterOut",
		MeshAttachmentPositions = {
			OutConnect = Vector3.new(0, 0, -1.75),
			ThrusterOut = Vector3.new(0, 3.5, 1.76)
		}
	},
	ArmorPlate = {
		InConnectCount = 0,
		OutConnectCount = 1,
		OutConnectPosition = "OutConnect_Bottom",
		IsModule = true,
		IsArmor = true,
		MeshAttachmentPositions = {
			OutConnect = Vector3.new(0, -3.5, 0)
		}
	},
	ExtensionStrut = {
		InConnectCount = 7,
		OutConnectCount = 1,
		OutConnectPosition = "OutConnect_Front",
		IsModule = true,
		MeshAttachmentPositions = {
			OutConnect = Vector3.new(0, 0, -10.5),
			InConnect_1 = Vector3.new(0, 0, 10.5),
			InConnect_2 = Vector3.new(-3.5, 0, -7),
			InConnect_3 = Vector3.new(-3.5, 0, 0),
			InConnect_4 = Vector3.new(-3.5, 0, 7),
			InConnect_5 = Vector3.new(3.5, 0, -7),
			InConnect_6 = Vector3.new(3.5, 0, 0),
			InConnect_7 = Vector3.new(3.5, 0, 7)
		}
	},
	StandardThruster = {
		InConnectCount = 0,
		OutConnectCount = 1,
		OutConnectPosition = "OutConnect_Back",
		IsModule = true
	},
	SmallThruster = {
		InConnectCount = 0,
		OutConnectCount = 1,
		OutConnectPosition = "OutConnect_Back",
		IsModule = true
	},
	ThrusterBooster = {
		InConnectCount = 0,
		OutConnectCount = 1,
		OutConnectPosition = "OutConnect_Back",
		IsModule = true
	},
	MassDriver = {
		InConnectCount = 0,
		OutConnectCount = 1,
		OutConnectPosition = "OutConnect_Back",
		IsModule = true,
		MuzzlePosition = "Muzzle"
	},
	PlasmaBall = {
		InConnectCount = 0,
		OutConnectCount = 1,
		OutConnectPosition = "OutConnect_Back",
		IsModule = true,
		MuzzlePosition = "Muzzle"
	},
	MissileLauncher = {
		InConnectCount = 0,
		OutConnectCount = 1,
		OutConnectPosition = "OutConnect_Back",
		IsModule = true,
		MuzzlePosition = "Muzzle"
	},
	DroneBay = {
		InConnectCount = 0,
		OutConnectCount = 1,
		OutConnectPosition = "OutConnect_Back",
		IsModule = true
	},
	Laser = {
		InConnectCount = 0,
		OutConnectCount = 1,
		OutConnectPosition = "OutConnect_Back",
		IsModule = true,
		MuzzlePosition = "Muzzle"
	},
	PhasedEnergyBeam = {
		InConnectCount = 0,
		OutConnectCount = 1,
		OutConnectPosition = "OutConnect_Back",
		IsModule = true,
		MuzzlePosition = "Muzzle"
	},
	SpinningBlade = {
		InConnectCount = 0,
		OutConnectCount = 1,
		OutConnectPosition = "OutConnect_Back",
		IsModule = true
	},
	BombletSpray = {
		InConnectCount = 0,
		OutConnectCount = 1,
		OutConnectPosition = "OutConnect_Back",
		IsModule = true,
		MuzzlePosition = "Muzzle"
	},
	SniperCannon = {
		InConnectCount = 0,
		OutConnectCount = 1,
		OutConnectPosition = "OutConnect_Back",
		IsModule = true,
		MuzzlePosition = "Muzzle"
	},
	Torpedo = {
		InConnectCount = 0,
		OutConnectCount = 1,
		OutConnectPosition = "OutConnect_Back",
		IsModule = true,
		MuzzlePosition = "Muzzle"
	},
	Ubercannon = {
		InConnectCount = 0,
		OutConnectCount = 1,
		OutConnectPosition = "OutConnect_Back",
		IsModule = true,
		MuzzlePosition = "Muzzle"
	},
	FighterBay = {
		InConnectCount = 0,
		OutConnectCount = 1,
		OutConnectPosition = "OutConnect_Back",
		IsModule = true
	},
	GrapplingHook = {
		InConnectCount = 0,
		OutConnectCount = 1,
		OutConnectPosition = "OutConnect_Back",
		IsModule = true
	},
	MachineGun = {
		InConnectCount = 0,
		OutConnectCount = 1,
		OutConnectPosition = "OutConnect_Back",
		IsModule = true,
		MuzzlePosition = "Muzzle"
	},
	ShieldGenerator = {
		InConnectCount = 0,
		OutConnectCount = 1,
		OutConnectPosition = "OutConnect_Back",
		IsModule = true
	},
	MissileScrambler = {
		InConnectCount = 0,
		OutConnectCount = 1,
		OutConnectPosition = "OutConnect_Back",
		IsModule = true
	},
	Reactor = {
		InConnectCount = 0,
		OutConnectCount = 1,
		OutConnectPosition = "OutConnect_Back",
		IsModule = true
	},
	PowerPlant = {
		InConnectCount = 0,
		OutConnectCount = 1,
		OutConnectPosition = "OutConnect_Back",
		IsModule = true
	},
	ScramblerPulse = {
		InConnectCount = 0,
		OutConnectCount = 1,
		OutConnectPosition = "OutConnect_Back",
		IsModule = true
	},
	PointDefence = {
		InConnectCount = 0,
		OutConnectCount = 1,
		OutConnectPosition = "OutConnect_Back",
		IsModule = true
	},
	PlasmaTurret = {
		InConnectCount = 0,
		OutConnectCount = 1,
		OutConnectPosition = "OutConnect_Back",
		IsModule = true,
		MuzzlePosition = "Muzzle"
	},
	KineticRailgun = {
		InConnectCount = 0,
		OutConnectCount = 1,
		IsModule = true,
		MuzzlePosition = "Muzzle",
		MeshAttachmentPositions = {
			OutConnect = Vector3.new(0, 0, 10.5),
			Muzzle = Vector3.new(0, 1.75, -10.5)
		}
	},
	FlakSpreader = {
		InConnectCount = 0,
		OutConnectCount = 1,
		IsModule = true,
		MuzzlePosition = "Muzzle",
		MeshAttachmentPositions = {
			OutConnect = Vector3.new(0, 0, 7),
			Muzzle = Vector3.new(0, 1.75, -7)
		}
	},
	MissileBox = {
		InConnectCount = 0,
		OutConnectCount = 1,
		IsModule = true,
		MuzzlePosition = "Muzzle",
		MeshAttachmentPositions = {
			OutConnect = Vector3.new(0, 0, 3.5),
			Muzzle = Vector3.new(0, 0, -3.5)
		}
	},
	DroneHangar = {
		InConnectCount = 0,
		OutConnectCount = 1,
		IsModule = true,
		MeshAttachmentPositions = {
			OutConnect = Vector3.new(0, 0, 7),
			DroneSpawn = Vector3.new(0, 1.75, -3.5)
		}
	},
	ShieldDish = {
		InConnectCount = 0,
		OutConnectCount = 1,
		IsModule = true,
		MeshAttachmentPositions = {
			OutConnect = Vector3.new(0, 0, 1.75),
			ShieldOrigin = Vector3.new(0, 3.5, 0)
		}
	}
}

Components.Types = {
	CommandCore = {
		Name="Command Core", Category="Structure", 
		UnitSize=Vector3.new(1.3,0.65,1.3), Color=Color3.new(0.15,0.15,0.17), 
		Mass=5, HP=250, 
		IsCore=true,
		InConnectCount=4, OutConnectCount=0,
		HasWeaponConnect=false
	},
	DragonCore = {
		Name="Dragon Core", Category="Structure",
		UnitSize=Vector3.new(3,1,2), Color=Color3.fromRGB(0x1C, 0x1E, 0x20),
		Mass=8, HP=400,
		IsCore=true,
		InConnectCount=6, OutConnectCount=0,
		HasWeaponConnect=false,
		ChassisType="Dragon",
		Description="Wishbone frame. Aft 7x14 base, twin rear ports. Front splits into dual 14-stud parallel prongs tapering to 3-sided wedge tips."
	},
	PelicanCore = {
		Name="Pelican Core", Category="Structure",
		UnitSize=Vector3.new(3,1,1), Color=Color3.fromRGB(0x1C, 0x1E, 0x20),
		Mass=6, HP=300,
		IsCore=true,
		InConnectCount=4, OutConnectCount=0,
		HasWeaponConnect=false,
		ChassisType="Pelican",
		Description="Two-tier box hull. Alternating raised armor slabs and recessed utility slots on top. Cargo hatches on sides. 45° yellow hazard stripes on front corners."
	},
	HornetCore = {
		Name="Hornet Core", Category="Structure",
		UnitSize=Vector3.new(2,1,2), Color=Color3.fromRGB(0x1C, 0x1E, 0x20),
		Mass=4, HP=200,
		IsCore=true,
		InConnectCount=4, OutConnectCount=0,
		HasWeaponConnect=false,
		ChassisType="Hornet",
		Description="Open diamond ring frame. No center mass. Thin square perimeter bars. Sockets at 4 corner apex points. Twin yellow triangles on nose."
	},
	ScarletCore = {
		Name="Scarlet Core", Category="Structure",
		UnitSize=Vector3.new(2,1,2), Color=Color3.fromRGB(0x1C, 0x1E, 0x20),
		Mass=5, HP=250,
		IsCore=true,
		InConnectCount=4, OutConnectCount=0,
		HasWeaponConnect=false,
		ChassisType="Scarlet",
		Description="Symmetrical cross. Four 7-stud blocky arms meet at raised center hub. Circular ports on terminal faces. Yellow racing stripes on all arms."
	},
	HullBlock = {
		Name="Hull Block", Category="Structure", 
		UnitSize=Vector3.new(1,0.5,1), Color=Color3.new(0.5,0.5,0.5), 
		Mass=1, HP=100, 
		IsHull=true,
		InConnectCount=4, OutConnectCount=0,
		HasWeaponConnect=false
	},
	HullBeam = {
		Name="Hull Beam", Category="Structure", 
		UnitSize=Vector3.new(3,0.5,1), Color=Color3.new(0.45,0.45,0.5), 
		Mass=3, HP=300, 
		IsHull=true,
		InConnectCount=3, OutConnectCount=1,
		HasWeaponConnect=false
	},
	HullDiamond = {
		Name="Hull Diamond", Category="Structure", 
		UnitSize=Vector3.new(1,0.5,1), Color=Color3.new(0.4,0.45,0.5), 
		Mass=1, HP=120, 
		IsHull=true,
		InConnectCount=4, OutConnectCount=0,
		HasWeaponConnect=false
	},
	HullHexagon = {
		Name="Hull Hexagon", Category="Structure", 
		UnitSize=Vector3.new(1,0.5,1), Color=Color3.new(0.45,0.45,0.5), 
		Mass=4, HP=350, 
		IsHull=true,
		InConnectCount=6, OutConnectCount=0,
		HasWeaponConnect=false
	},
	HullLattice = {
		Name="Hull Lattice", Category="Structure", 
		UnitSize=Vector3.new(2,0.5,2), Color=Color3.new(0.4,0.4,0.45), 
		Mass=2, HP=180, 
		IsHull=true,
		InConnectCount=4, OutConnectCount=0,
		HasWeaponConnect=false
	},
	HullPlate2 = {
		Name="Hull Plate", Category="Structure", 
		UnitSize=Vector3.new(2,0.3,1), Color=Color3.new(0.5,0.5,0.5), 
		Mass=1.5, HP=150, 
		IsHull=true,
		InConnectCount=2, OutConnectCount=0,
		HasWeaponConnect=false
	},
	HullSpike = {
		Name="Hull Spike", Category="Structure", 
		UnitSize=Vector3.new(1,0.5,2), Color=Color3.new(0.35,0.35,0.4), 
		Mass=1.5, HP=130, 
		IsHull=true,
		InConnectCount=2, OutConnectCount=1,
		HasWeaponConnect=false
	},
	HullTriangle = {
		Name="Hull Triangle", Category="Structure", 
		UnitSize=Vector3.new(1,0.07,0.87), Color=Color3.fromRGB(0x55, 0x5B, 0x66), 
		Mass=1, HP=90, 
		IsHull=true,
		IsModule=true,
		InConnectCount=2, OutConnectCount=1,
		Description="Flat equilateral triangle. Transparent body with opaque edge frame. 1 OutConnect bottom, 2 InConnects on left/right sides."
	},
	HullLeftWing = {
		Name="Hull Left Wing", Category="Structure", 
		UnitSize=Vector3.new(1,0.5,1), Color=Color3.new(0.4,0.42,0.5), 
		Mass=1, HP=110, 
		IsHull=true,
		InConnectCount=2, OutConnectCount=1,
		HasWeaponConnect=false
	},
	HullRightWing = {
		Name="Hull Right Wing", Category="Structure", 
		UnitSize=Vector3.new(1,0.5,1), Color=Color3.new(0.4,0.42,0.5), 
		Mass=1, HP=110, 
		IsHull=true,
		InConnectCount=2, OutConnectCount=1,
		HasWeaponConnect=false
	},
	ArmourBig = {
		Name="Armour Big", Category="Defense", 
		UnitSize=Vector3.new(2,0.5,2), Color=Color3.new(0.25,0.28,0.32), 
		Mass=4, HP=300, 
		IsArmor=true,
		InConnectCount=0, OutConnectCount=1
	},
	ArmourPlate = {
		Name="Armour Plate", Category="Defense", 
		UnitSize=Vector3.new(2,0.4,1), Color=Color3.new(0.22,0.25,0.3), 
		Mass=2, HP=200, 
		IsArmor=true,
		InConnectCount=0, OutConnectCount=1
	},
	ArmourSmall = {
		Name="Armour Small", Category="Defense", 
		UnitSize=Vector3.new(1,0.5,1), Color=Color3.new(0.2,0.25,0.3), 
		Mass=1, HP=100, 
		IsArmor=true,
		InConnectCount=0, OutConnectCount=1
	},
	HullHeavy = {
		Name="Hull Heavy (XL)", Category="Structure", 
		UnitSize=Vector3.new(2,0.5,2), Color=Color3.new(0.4,0.5,0.4), 
		Mass=6, HP=400, 
		IsHull=true,
		InConnectCount=3, OutConnectCount=1,
		HasWeaponConnect=false
	},
	HullMedium = {
		Name="Hull Medium", Category="Structure", 
		UnitSize=Vector3.new(2,0.5,1), Color=Color3.new(0.4,0.4,0.4), 
		Mass=3, HP=200, 
		IsHull=true,
		InConnectCount=3, OutConnectCount=1,
		HasWeaponConnect=false
	},
	HullSmall = {
		Name="Hull Small", Category="Structure", 
		UnitSize=Vector3.new(1,0.5,1), Color=Color3.new(0.35,0.35,0.35), 
		Mass=1, HP=100, 
		IsHull=true,
		InConnectCount=3, OutConnectCount=1,
		HasWeaponConnect=false
	},
	StandardEngine = {
		Name="Standard Engine", Category="Movement", 
		UnitSize=Vector3.new(1,1,1), Color=Color3.fromRGB(0x3A, 0x3F, 0x47), 
		Mass=2, HP=80, 
		ThrustForce=80,
		IsModule=true,
		InConnectCount=0, OutConnectCount=1,
		ChassisType="Engine",
		Description="8-sided cylinder on flat 7x7 plate. Dual horizontal silver fuel rods on flanks. Rear exhaust flares to cone with neon green emissive face."
	},
	DualEngine = {
		Name="Dual Engine", Category="Movement", 
		UnitSize=Vector3.new(1,1,2), Color=Color3.fromRGB(0x3A, 0x3F, 0x47), 
		Mass=4, HP=120, 
		ThrustForce=140,
		IsModule=true,
		InConnectCount=0, OutConnectCount=1,
		ChassisType="Engine",
		Description="Flat base plate with twin short cylinder engines side-by-side. 90° bent silver intake pipe bridges bases. Twin flat glowing green rectangles at rear."
	},
	HeavyThruster = {
		Name="Heavy Thruster", Category="Movement", 
		UnitSize=Vector3.new(2,1,2), Color=Color3.fromRGB(0x3A, 0x3F, 0x47), 
		Mass=8, HP=200, 
		ThrustForce=200,
		IsModule=true,
		InConnectCount=0, OutConnectCount=1,
		ChassisType="Engine",
		Description="Hexagonal block. Stepped heat-shield panels on top in flat pyramid stack. Silver plumbing wraps hex boundaries. Deep inset square cavity with neon green grid matrix at rear."
	},
	SteeringJet = {
		Name="Steering Jet", Category="Movement", 
		UnitSize=Vector3.new(0.5,1,0.5), Color=Color3.fromRGB(0x3A, 0x3F, 0x47), 
		Mass=1, HP=40, 
		ThrustForce=30,
		IsModule=true,
		InConnectCount=0, OutConnectCount=1,
		ChassisType="Engine",
		Description="Asymmetric right-angle wedge for corners. Long side mounts flush. Short rear side contains single embedded neon green dot thruster port."
	},
	ArmorPlate = {
		Name="Armor Plate", Category="Defense", 
		UnitSize=Vector3.new(3,1,1), Color=Color3.fromRGB(0x55, 0x5B, 0x66), 
		Mass=3, HP=200, 
		IsArmor=true,
		IsModule=true,
		InConnectCount=0, OutConnectCount=1,
		Description="Solid gray trapezoid. Bottom width 21 studs (3 units), top width 14 studs (2 units), height 7 studs (1 unit). Single OutConnect on bottom face."
	},
	ExtensionStrut = {
		Name="Extension Strut", Category="Structure", 
		UnitSize=Vector3.new(1,0.07,3), Color=Color3.fromRGB(0x55, 0x5B, 0x66), 
		Mass=2, HP=150, 
		IsModule=true,
		InConnectCount=7, OutConnectCount=1,
		Description="Flat 3x1 strut. Transparent body with opaque edge frame. 1 OutConnect front, 1 InConnect back, 3 InConnects per long side."
	},
	StandardThruster = {
		Name="Standard Thruster", Category="Movement", 
		UnitSize=Vector3.new(1,0.5,1), Color=Color3.new(1,0.5,0), 
		Mass=2, HP=80, 
		ThrustForce=80,
		IsModule=true,
		InConnectCount=0, OutConnectCount=1
	},
	SmallThruster = {
		Name="Small Thruster", Category="Movement", 
		UnitSize=Vector3.new(0.5,0.3,0.5), Color=Color3.new(0.9,0.45,0), 
		Mass=0.5, HP=40, 
		ThrustForce=40,
		IsModule=true,
		InConnectCount=0, OutConnectCount=1
	},
	ThrusterBooster = {
		Name="Thruster Booster", Category="Movement", 
		UnitSize=Vector3.new(1,0.5,1), Color=Color3.new(1,0.3,0), 
		Mass=3, HP=60, 
		ThrustForce=120, BoostMultiplier=2.0, BoostDuration=3, BoostCooldown=10,
		IsModule=true,
		InConnectCount=0, OutConnectCount=1
	},
	MachineGun = {
		Name="Machine Gun", Category="Offense", 
		UnitSize=Vector3.new(1,0.5,1), Color=Color3.new(0.3,0.3,0.35), 
		Mass=1, HP=50, 
		Damage=8, FireRate=0.1, Range=50, ProjectileSpeed=300, 
		ProjectileSize=Vector3.new(0.2,0.2,0.5), ProjectileColor=Color3.new(1,0.9,0.3), 
		Penetrates=false, PowerPerShot=16,
		IsModule=true,
		InConnectCount=0, OutConnectCount=1,
		MuzzlePosition="Muzzle"
	},
	Laser = {
		Name="Laser", Category="Offense", 
		UnitSize=Vector3.new(1,0.5,1), Color=Color3.new(0.8,0,0), 
		Mass=1, HP=40, 
		Damage=15, Range=40, Duration=0.3, LaserColor=Color3.new(1,0,0), Cooldown=1, PowerPerShot=30,
		IsModule=true,
		InConnectCount=0, OutConnectCount=1
	},
	PhasedEnergyBeam = {
		Name="Phased Energy Beam", Category="Offense", 
		UnitSize=Vector3.new(1.2,0.6,1.2), Color=Color3.new(0.2,0.6,0.8), 
		Mass=2, HP=70, 
		Damage=25, FireRate=1.5, Range=55, ProjectileSpeed=250, 
		ProjectileSize=Vector3.new(0.4,0.4,1.5), ProjectileColor=Color3.new(0.3,0.8,1), 
		Penetrates=true, PowerPerShot=50, PulseTime=0.2, FadeTime=0.5,
		IsModule=true,
		InConnectCount=0, OutConnectCount=1,
		MuzzlePosition="Muzzle"
	},
	SpinningBlade = {
		Name="Spinning Blade", Category="Offense", 
		UnitSize=Vector3.new(1,0.5,1), Color=Color3.new(0.6,0.6,0.7), 
		Mass=1.5, HP=80, 
		Damage=20, SpinDamage=40, SpinUpSpeed=2, TopSpeed=10, Range=30, 
		ProjectileSize=Vector3.new(1.5,0.1,1.5), ProjectileColor=Color3.new(0.7,0.7,0.8), 
		PowerPerShot=40,
		IsModule=true,
		InConnectCount=0, OutConnectCount=1
	},
	BombletSpray = {
		Name="Bomblet Spray", Category="Offense", 
		UnitSize=Vector3.new(1.2,0.6,1.2), Color=Color3.new(0.5,0.4,0.3), 
		Mass=2, HP=60, 
		Damage=10, FireRate=2.5, Range=35, ProjectileSpeed=100, Projectiles=8, 
		ProjectileSize=Vector3.new(0.3,0.3,0.3), ProjectileColor=Color3.new(1,0.6,0.2), 
		ProjectileLife=1.5, PushMultiplier=1.5, PowerPerShot=60,
		IsModule=true,
		InConnectCount=0, OutConnectCount=1,
		MuzzlePosition="Muzzle"
	},
	MassDriver = {
		Name="Mass Driver", Category="Offense", 
		UnitSize=Vector3.new(1,0.5,1), Color=Color3.new(0.3,0.3,0.6), 
		Mass=1.5, HP=60, 
		Damage=16, FireRate=0.5, Range=60, ProjectileSpeed=200, 
		ProjectileSize=Vector3.new(0.5,0.3,1), ProjectileColor=Color3.new(0.4,0.4,1), 
		Penetrates=false, PowerPerShot=32,
		IsModule=true,
		InConnectCount=0, OutConnectCount=1,
		MuzzlePosition="Muzzle"
	},
	PlasmaBall = {
		Name="Plasma Ball Launcher", Category="Offense", 
		UnitSize=Vector3.new(1,0.5,1), Color=Color3.new(0.6,0.6,0.6), 
		Mass=2, HP=80, 
		Damage=50, TickDamage=10, FireRate=2, Range=40, ProjectileSpeed=60, 
		ProjectileSize=Vector3.new(1,1,1), ProjectileColor=Color3.new(0.8,0.2,0.8), 
		Penetrates=true, ArmorDamageMultiplier=0.5, PowerPerShot=100,
		IsModule=true,
		InConnectCount=0, OutConnectCount=1,
		MuzzlePosition="Muzzle"
	},
	SniperCannon = {
		Name="Sniper Cannon", Category="Offense", 
		UnitSize=Vector3.new(1.5,0.6,2), Color=Color3.new(0.25,0.25,0.35), 
		Mass=3, HP=50, 
		Damage=60, FireRate=4, Range=100, ProjectileSpeed=400, FiringLeeway=5,
		ProjectileSize=Vector3.new(0.3,0.3,2), ProjectileColor=Color3.new(0.9,0.9,1), 
		Penetrates=true, PowerPerShot=120,
		IsModule=true,
		InConnectCount=0, OutConnectCount=1,
		MuzzlePosition="Muzzle"
	},
	MissileLauncher = {
		Name="Missile Launcher", Category="Offense", 
		UnitSize=Vector3.new(1,0.5,1), Color=Color3.new(0.8,0,0), 
		Mass=2, HP=60, 
		Damage=40, FireRate=3, Range=50, ProjectileSpeed=80, SpreadAngle=15, MissileHP=25, 
		ProjectileSize=Vector3.new(1,0.5,1), ProjectileColor=Color3.new(1,0.3,0.3), PowerPerShot=80,
		IsModule=true,
		InConnectCount=0, OutConnectCount=1,
		MuzzlePosition="Muzzle"
	},
	Torpedo = {
		Name="Torpedo", Category="Offense", 
		UnitSize=Vector3.new(1.5,0.8,2), Color=Color3.new(0.3,0.3,0.4), 
		Mass=4, HP=80, 
		Damage=80, FireRate=5, Range=70, ProjectileSpeed=50, MissileHP=50,
		ProjectileSize=Vector3.new(0.8,0.8,2), ProjectileColor=Color3.new(0.4,0.4,0.6), 
		PowerPerShot=160,
		IsModule=true,
		InConnectCount=0, OutConnectCount=1,
		MuzzlePosition="Muzzle"
	},
	Ubercannon = {
		Name="Ubercannon", Category="Offense", 
		UnitSize=Vector3.new(2,1,2), Color=Color3.new(0.1,0.1,0.2), 
		Mass=8, HP=100, 
		Damage=150, FireRate=8, Range=80, ProjectileSpeed=150, ExplosionRadius=15,
		ProjectileSize=Vector3.new(2,2,2), ProjectileColor=Color3.new(1,0.5,0), 
		Penetrates=true, PowerPerShot=300,
		IsModule=true,
		InConnectCount=0, OutConnectCount=1,
		MuzzlePosition="Muzzle"
	},
	FighterBay = {
		Name="Fighter Bay", Category="Offense", 
		UnitSize=Vector3.new(2,1,2), Color=Color3.new(0.4,0.3,0.3), 
		Mass=5, HP=100, 
		MaxFighters=3, EnergyPerFighter=30, FighterHP=60, FighterSpeed=80, 
		FighterDamage=10, FighterFireRate=0.3, FighterRange=40, FighterVision=60,
		IsModule=true,
		InConnectCount=0, OutConnectCount=1
	},
	GrapplingHook = {
		Name="Grappling Hook", Category="Offense", 
		UnitSize=Vector3.new(0.8,0.5,0.8), Color=Color3.new(0.5,0.5,0.4), 
		Mass=1, HP=40, 
		MaxLength=50, MinLength=5, BreakLength=60, SpringConstant=100,
		Cooldown=2, GrappleDebris=true,
		IsModule=true,
		InConnectCount=0, OutConnectCount=1
	},
	DroneBay = {
		Name="Drone Bay", Category="Offense", 
		UnitSize=Vector3.new(1,0.5,1), Color=Color3.new(0.8,0.2,0.2), 
		Mass=2, HP=50, 
		MaxDrones=3, EnergyPerDrone=20, DroneHP=50, DroneSpeed=60, 
		DroneDamage=5, DroneFireRate=0.2, DroneRange=30, DroneEnergyRegen=25,
		IsModule=true,
		InConnectCount=0, OutConnectCount=1
	},
	PointDefence = {
		Name="Point Defence", Category="Offense", 
		UnitSize=Vector3.new(1,0.5,1), Color=Color3.new(0.6,0.6,0.7), 
		Mass=1, HP=40, 
		Range=45, DamagePerSecond=25, TargetingDelay=1,
		TargetsDrones=true, TargetsMissiles=true,
		IsModule=true,
		InConnectCount=0, OutConnectCount=1
	},
	ShieldGenerator = {
		Name="Shield Generator", Category="Defense", 
		UnitSize=Vector3.new(1,0.5,1), Color=Color3.new(0,0.8,0.8), 
		Mass=2, HP=50, 
		ShieldOutput=50, DamageToEnergy=0.5,
		MinEnergyToActivate=50,
		ShieldRadius=75,
		IsModule=true,
		InConnectCount=0, OutConnectCount=1
	},
	MissileScrambler = {
		Name="Missile Scrambler", Category="Defense", 
		UnitSize=Vector3.new(1,0.5,1), Color=Color3.new(0.2,0.6,0.8), 
		Mass=1.5, HP=40, 
		PulseRadius=40, PulseTime=0.5, Cooldown=5, PowerCost=25,
		PulseColor=Color3.new(0.3,0.8,1),
		IsModule=true,
		InConnectCount=0, OutConnectCount=1
	},
	Reactor = {
		Name="Reactor", Category="Utility", 
		UnitSize=Vector3.new(1,0.5,1), Color=Color3.new(1,0.8,0), 
		Mass=3, HP=40, 
		EnergyRegen=5,
		IsModule=true,
		InConnectCount=0, OutConnectCount=1
	},
	PowerPlant = {
		Name="Power Plant", Category="Utility", 
		UnitSize=Vector3.new(1.5,0.5,1.5), Color=Color3.new(1,0.6,0.1), 
		Mass=4, HP=60, 
		EnergyRegen=12, MaxEnergyBoost=50,
		IsModule=true,
		InConnectCount=0, OutConnectCount=1
	},
	ScramblerPulse = {
		Name="Scrambler Pulse", Category="Utility", 
		UnitSize=Vector3.new(1,0.5,1), Color=Color3.new(0,1,1), 
		Mass=1, HP=30, 
		Radius=15, Cooldown=5, PowerCost=5, PulseColor=Color3.new(0,1,1),
		IsModule=true,
		InConnectCount=0, OutConnectCount=1
	},
	PlasmaTurret = {
		Name="Plasma Turret", Category="Offense", 
		UnitSize=Vector3.new(1,0.5,1), Color=Color3.new(0.5,0.2,0.6), 
		Mass=2.5, HP=90, 
		Damage=35, TickDamage=8, FireRate=1.5, Range=50, ProjectileSpeed=70, 
		ProjectileSize=Vector3.new(1.2,1.2,1.2), ProjectileColor=Color3.new(0.8,0.4,1), 
		Penetrates=true, ArmorDamageMultiplier=0.5, PowerPerShot=70,
		IsModule=true,
		InConnectCount=0, OutConnectCount=1,
		DualBarrel=true
	},
	KineticRailgun = {
		Name="Kinetic Railgun", Category="Offense",
		UnitSize=Vector3.new(1,1,3), Color=Color3.fromRGB(0x14, 0x15, 0x17),
		Mass=3, HP=60,
		Damage=40, FireRate=2, Range=80, ProjectileSpeed=350,
		ProjectileSize=Vector3.new(0.3,0.3,1.5), ProjectileColor=Color3.new(1,0.2,0.2),
		Penetrates=true, PowerPerShot=80,
		IsModule=true,
		InConnectCount=0, OutConnectCount=1,
		MuzzlePosition="Muzzle",
		Description="Twin long parallel square accelerator rails extending past core. Three square reinforcement rings clamp rails at even intervals. Laser red stripe runs down outer flanks."
	},
	FlakSpreader = {
		Name="Flak Spreader", Category="Offense",
		UnitSize=Vector3.new(1,1,2), Color=Color3.fromRGB(0x14, 0x15, 0x17),
		Mass=2, HP=50,
		Damage=8, FireRate=1.5, Range=25, ProjectileSpeed=150, Projectiles=5,
		ProjectileSize=Vector3.new(0.3,0.3,0.3), ProjectileColor=Color3.new(1,0.3,0.2),
		SpreadAngle=45, PowerPerShot=40,
		IsModule=true,
		InConnectCount=0, OutConnectCount=1,
		MuzzlePosition="Muzzle",
		Description="Flat triangular wedge, fans horizontally to wide muzzle. Front face has five short barrel nubs in radial arc. Muzzles capped with laser red rings."
	},
	MissileBox = {
		Name="Missile Box", Category="Offense",
		UnitSize=Vector3.new(1,1,1), Color=Color3.fromRGB(0x14, 0x15, 0x17),
		Mass=2, HP=60,
		Damage=40, FireRate=3, Range=50, ProjectileSpeed=80, MissileHP=25,
		ProjectileSize=Vector3.new(0.8,0.8,1.5), ProjectileColor=Color3.new(1,0.3,0.3),
		PowerPerShot=80,
		IsModule=true,
		InConnectCount=0, OutConnectCount=1,
		MuzzlePosition="Muzzle",
		Description="Square launcher pod. Front wall has four deep square cavities in 2x2 matrix. Each cavity contains a sharp geometric cone tip in neon laser red."
	},
	DroneHangar = {
		Name="Drone Hangar", Category="Offense",
		UnitSize=Vector3.new(2,1,2), Color=Color3.fromRGB(0x25, 0x16, 0x30),
		Mass=5, HP=100,
		MaxDrones=3, EnergyPerDrone=30, DroneHP=60, DroneSpeed=80,
		DroneDamage=10, DroneFireRate=0.3, DroneRange=40, DroneVision=60,
		IsModule=true,
		InConnectCount=0, OutConnectCount=1,
		Description="Wedge structure sloping upward to rear, leaving wide rectangular opening at front. Hollow interior launch floor with twin glowing violet runway guide lines."
	},
	ShieldDish = {
		Name="Shield Dish", Category="Defense",
		UnitSize=Vector3.new(1,1,1), Color=Color3.fromRGB(0x25, 0x16, 0x30),
		Mass=2, HP=50,
		ShieldOutput=50, DamageToEnergy=0.5,
		MinEnergyToActivate=50,
		ShieldRadius=75,
		IsModule=true,
		InConnectCount=0, OutConnectCount=1,
		Description="Flat hexagonal dish on blocky 4-sided pedestal. Dish has six independent triangular panels tilting inward. Panels separated by glowing violet emissive groove trenches."
	}
}

function Components.Create(ct)
	local d = Components.Types[ct]
	if not d then return nil end
	
	local p = Instance.new("Part")
	p.Name = d.Name
	
	if ct == "HullHex" then
		p.Shape = Enum.PartType.Cylinder
		p.Size = Vector3.new(3.5, 7, 7)
		p.Orientation = Vector3.new(0, 0, 90)
	else
		p.Size = Vector3.new(d.UnitSize.X*7, 3.5, d.UnitSize.Z*7)
	end
	
	p.BrickColor = BrickColor.new(d.Color)
	p.Material = Enum.Material.Metal
	p.CanCollide = true
	p.CastShadow = true
	
	local connConfig = Components.Connections[ct]
	if connConfig then
		if connConfig.InConnectPositions then
			for i, posName in ipairs(connConfig.InConnectPositions) do
				if i <= (connConfig.InConnectCount or 0) then
					local offset = Components.AttachmentOffsets[posName]
					if offset then
						local a = Instance.new("Attachment")
						a.Name = "InConnect_" .. i
						a.Position = offset
						a.Parent = p
						
						local glow = Instance.new("PointLight")
						glow.Name = "Glow"
						glow.Color = Color3.new(0, 1, 1)
						glow.Brightness = 0.5
						glow.Range = 5
						glow.Enabled = false
						glow.Parent = a
					end
				end
			end
		end
		
		if connConfig.OutConnectPosition then
			local offset = Components.AttachmentOffsets[connConfig.OutConnectPosition]
			if offset then
				local a = Instance.new("Attachment")
				a.Name = "OutConnect"
				a.Position = offset
				a.Parent = p
				
				local glow = Instance.new("PointLight")
				glow.Name = "Glow"
				glow.Color = Color3.new(1, 0.5, 0)
				glow.Brightness = 0.5
				glow.Range = 5
				glow.Enabled = false
				glow.Parent = a
			end
		end
		
		if connConfig.MuzzlePosition then
			local offset = Components.AttachmentOffsets[connConfig.MuzzlePosition]
			if offset then
				local a = Instance.new("Attachment")
				a.Name = "Muzzle"
				a.Position = offset
				a.Parent = p
			end
		end
	end
	
	p:SetAttribute("ComponentType", ct)
	p:SetAttribute("IsModule", d.IsModule or false)
	p:SetAttribute("IsHull", d.IsHull or false)
	p:SetAttribute("IsArmor", d.IsArmor or false)
	p:SetAttribute("IsCore", d.IsCore or false)
	
	return p
end

function Components.GetConnectionPoints(part)
	local points = {
		InConnects = {},
		OutConnect = nil,
		WeaponConnect = nil
	}
	
	local searchPart = part
	if part:IsA("Model") then
		for _, descendant in ipairs(part:GetDescendants()) do
			if descendant:IsA("BasePart") then
				for _, child in ipairs(descendant:GetChildren()) do
					if child:IsA("Attachment") and string.sub(child.Name, 1, 9) == "InConnect" then
						searchPart = descendant
						break
					end
				end
				if searchPart ~= part then break end
			end
		end
	end
	
	for _, child in ipairs(searchPart:GetChildren()) do
		if child:IsA("Attachment") then
			if string.sub(child.Name, 1, 9) == "InConnect" then
				table.insert(points.InConnects, child)
			elseif child.Name == "OutConnect" then
				points.OutConnect = child
			elseif child.Name == "WeaponConnect" then
				points.WeaponConnect = child
			end
		end
	end
	
	return points, searchPart
end

function Components.FindNearestConnection(part, targetPart, maxDistance)
	local partPoints, actualPart = Components.GetConnectionPoints(part)
	local targetPoints, actualTarget = Components.GetConnectionPoints(targetPart)
	
	local nearestDistance = maxDistance or Components.SNAP_DISTANCE
	local nearestPartPoint = nil
	local nearestTargetPoint = nil
	local nearestTargetPart = nil
	
	local partBase = actualPart:IsA("BasePart") and actualPart or part
	local targetBase = actualTarget:IsA("BasePart") and actualTarget or targetPart
	
	if partPoints.OutConnect and #targetPoints.InConnects > 0 then
		local partWorldPos = partBase.CFrame * partPoints.OutConnect.Position
		
		for _, targetInConnect in ipairs(targetPoints.InConnects) do
			local targetWorldPos = targetBase.CFrame * targetInConnect.Position
			local distance = (partWorldPos - targetWorldPos).Magnitude
			
			if distance < nearestDistance then
				nearestDistance = distance
				nearestPartPoint = partPoints.OutConnect
				nearestTargetPoint = targetInConnect
				nearestTargetPart = targetBase
			end
		end
	end
	
	return nearestPartPoint, nearestTargetPoint, nearestDistance, nearestTargetPart
end

local function getConnectionNormal(offset)
	local horizontalDir = Vector3.new(offset.X, 0, offset.Z)
	if horizontalDir.Magnitude < 0.01 then
		return Vector3.new(0, 0, 1)
	end
	return horizontalDir.Unit
end

function Components.CalculateSnapCFrame(part, partPoint, targetPart, targetPoint)
	local partOffset = partPoint.Position
	local targetOffset = targetPoint.Position
	
	local partBase = part
	if part:IsA("Model") then
		for _, desc in ipairs(part:GetDescendants()) do
			if desc:IsA("BasePart") and desc:FindFirstChild("OutConnect") then
				partBase = desc
				break
			end
		end
	end
	
	local targetBase = targetPart
	if targetPart:IsA("Model") then
		for _, desc in ipairs(targetPart:GetDescendants()) do
			if desc:IsA("BasePart") then
				for _, child in ipairs(desc:GetChildren()) do
					if child:IsA("Attachment") and string.sub(child.Name, 1, 9) == "InConnect" then
						targetBase = desc
						break
					end
				end
				if targetBase ~= targetPart then break end
			end
		end
	end
	
	local partLocalNormal = getConnectionNormal(partOffset)
	local targetLocalNormal = getConnectionNormal(targetOffset)
	
	local partWorldNormal = partBase.CFrame:VectorToWorldSpace(partLocalNormal)
	local targetWorldNormal = targetBase.CFrame:VectorToWorldSpace(targetLocalNormal)
	
	local desiredPartNormal = -targetWorldNormal
	local targetWorldPos = targetBase.CFrame * targetOffset
	local newPartPos = targetWorldPos - partOffset
	local upVector = Vector3.new(0, 1, 0)
	
	local rightVector = upVector:Cross(desiredPartNormal)
	if rightVector.Magnitude < 0.1 then
		rightVector = Vector3.new(1, 0, 0):Cross(desiredPartNormal)
		if rightVector.Magnitude < 0.1 then
			rightVector = Vector3.new(0, 0, 1):Cross(desiredPartNormal)
		end
	end
	rightVector = rightVector.Unit
	upVector = desiredPartNormal:Cross(rightVector).Unit
	
	local newCFrame = CFrame.fromMatrix(newPartPos, rightVector, upVector, desiredPartNormal)
	return newCFrame
end

function Components.SetGlowEnabled(part, enabled)
	for _, child in ipairs(part:GetDescendants()) do
		if child:IsA("PointLight") and child.Name == "Glow" then
			child.Enabled = enabled
		end
	end
end

function Components.GetPartsInBuildRadius(center, radius)
	local parts = {}
	local droppedParts = workspace:FindFirstChild("DroppedParts")
	if not droppedParts then return parts end
	
	for _, part in ipairs(droppedParts:GetChildren()) do
		if part:IsA("BasePart") then
			local distance = (part.Position - center).Magnitude
			if distance <= radius then
				table.insert(parts, part)
			end
		end
	end
	
	return parts
end

return Components
