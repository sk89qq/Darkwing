--[[
	VOIDHUNTERS - ARCHITECTURE & EMULATION COMPARATIVE REFERENCE PLAN
	Last Updated: Full Dissection of AlterOrb / FunOrb Client Decompile Reference
	
	FULL REFERENCE: game.ServerStorage.VoidHunters_Complete_Reference
	ALTERORB REFERENCE: game.ServerStorage.AlterOrb_VoidHunters_Reference
	
	PURPOSE: Architectural guide for all future Void Hunters development.
	Contains side-by-side comparative analysis of the Roblox implementation
	and the decompiled FunOrb / AlterOrb singleplayer emulation state.
]]

local VoidHuntersPlan = {
	Meta = {
		Version = "2.0.0",
		TargetPlatform = "Roblox (Luau)",
		ReferencePlatform = "FunOrb Java Client (AlterOrb No-MP Emulation)",
		CoordinateMapping = "Original 2D (X, Y) -> Roblox 2D Plane (X, Z with fixed Y=3.5)",
	},

	AlterOrbRepositories = {
		Organization = "https://github.com/AlterOrb",
		Launcher = "https://github.com/AlterOrb/launcher",
		Patcher = "https://github.com/AlterOrb/patcher",
		Deobfuscator = "https://github.com/AlterOrb/deobfuscator",
		Tools = "https://github.com/AlterOrb/funorb-tools",
		EmulationProfile = "Basic / No-MP Support (Local loop, offline gamestate, singleplayer AI)",
	},

	-----------------------------------------------------------------------------
	-- COMPARATIVE SUBSYSTEM MATRIX:
	-- COLUMN 1: RobloxArchitecture (Target Luau Implementation & Function Mappings)
	-- COLUMN 2: EmulationStateReference (Sourced from AlterOrb & FunOrb Client Engine)
	-----------------------------------------------------------------------------
	Subsystems = {
		-- 1. PHYSICS & KINEMATICS ENGINE
		PhysicsEngine = {
			RobloxArchitecture = {
				Description = "Fixed-timestep 2D simulation over the Roblox 3D engine using X-Z plane with fixed Y elevation.",
				CoreModules = {
					"Shared.Physics.PhysicsConfig",
					"Shared.Physics.PhysicsTypes",
					"Shared.Physics.RigidBody2D",
					"Shared.Physics.MassPoint",
				},
				PlannedFunctions = {
					"RigidBody2D:Integrate(dt: number) -> void",
					"RigidBody2D:RecalculateMassProperties() -> void",
					"RigidBody2D:ApplyThrustVector(thrustVector: Vector2, torque: number) -> void",
					"RigidBody2D:ApplyInertialDamping(linearDrag: number, angularDrag: number) -> void",
				},
				StateRepresentation = "Vector2 Position, Vector2 Velocity, number Rotation (rad), number AngularVelocity (rad/s), force & torque accumulators cleared per tick.",
			},
			EmulationStateReference = {
				SourceTag = "[SOURCED FROM EMULATION STATE: AlterOrb/FunOrb 2D Engine]",
				OriginalMechanism = "50Hz (20ms fixed tick) integer/fixed-point 2D Cartesian accumulator.",
				KinematicFormulas = {
					MassCenter = "COM = sum(m_i * pos_i) / sum(m_i)",
					MomentOfInertia = "I_total = sum(m_i * (dist(pos_i, COM)^2) + I_piece_local)",
					LinearDamping = "v = v * pow(DAMP_LINEAR, dt * 50)  (approx 0.967 per second without thrust)",
					AngularDamping = "w = w * pow(DAMP_ANGULAR, dt * 50) (approx 0.781 per second without turn input)",
					VectoredThrust = "Individual thruster pieces generate directional force relative to ship orientation. Asymmetric thruster placement creates unintended rotational moment (torque = r x F).",
				},
				ArchitecturalDirectives = "Ensure thruster impulse calculations take the thruster offset relative to COM into account to replicate natural spin on asymmetric hulls.",
			},
		},

		-- 2. SHIP CHASSIS & COMPONENT GRAPH HIERARCHY
		ComponentGraph = {
			RobloxArchitecture = {
				Description = "Hierarchical Tree model rooted at Command Core with attachment-based socket system and WeldConstraints.",
				CoreModules = {
					"ReplicatedStorage.VoidHunterComponents",
					"ReplicatedStorage.VoidHunters.VoidHunterShipManager",
				},
				PlannedFunctions = {
					"Components.AttachPiece(shipModel: Model, parentPart: BasePart, parentSocket: Attachment, childPiece: BasePart, childSocket: Attachment) -> boolean",
					"Components.DetachPiece(shipModel: Model, targetPart: BasePart, dropAsDebris: boolean) -> BasePart",
					"Components.RecalculateConnectivity(shipModel: Model) -> { OrphanedParts: {BasePart} }",
					"Components.FindNearestConnection(heldPart: BasePart, targetPart: BasePart, maxDist: number) -> (Attachment, Attachment, number, BasePart)",
				},
				StateRepresentation = "Model attributes (IsShip, ChassisType, TotalMass, ComponentCount), Part socket attachments (InConnect, OutConnect, OutConnect_L, OutConnect_R).",
			},
			EmulationStateReference = {
				SourceTag = "[SOURCED FROM EMULATION STATE: AlterOrb/FunOrb Component Graph]",
				OriginalMechanism = "Strict Directed Tree rooted at a central Chassis (e.g. Bullfrog, Pelican, Wasp, Mosquito, Squid, Hydra, Stingray, Butterfly, Dragon).",
				SocketConventions = {
					RootChassis = "Contains 2 to 6 primary hardpoints (`InConnect_0` through `InConnect_N`).",
					Pieces = "Each piece defines 1 input hardpoint (`InConnect`) and 0 to 4 output sockets (`OutConnect_N`) with fixed angular orientations (0, 90, 180, 270 deg).",
					GraphIntegrity = "Strict acyclic tree structure. Every piece has exactly one parent node and zero or more child nodes.",
				},
				ArchitecturalDirectives = "Prevent multiple parents or loop connections during build mode. Snapping must validate socket availability and bounding geometry collision.",
			},
		},

		-- 3. DAMAGE PROPAGATION & ORPHAN SEVERING SYSTEM
		StructuralIntegrity = {
			RobloxArchitecture = {
				Description = "Per-component hit points with cascade detachment of disconnected subtrees.",
				CoreModules = {
					"ServerScriptService.VoidHuntersDamageEngine",
					"ReplicatedStorage.VoidHuntersComponents",
				},
				PlannedFunctions = {
					"DamageEngine.ApplyDamage(hitPart: BasePart, damageAmount: number, damageType: string, attackerPlayer: Player) -> void",
					"DamageEngine.SeverOrphans(shipModel: Model, destroyedPart: BasePart) -> {DebrisModel}",
					"DamageEngine.ExplodeCore(shipModel: Model) -> void",
				},
				StateRepresentation = "Part attributes: ComponentHP (number), MaxHP (number), ArmorRating (number), IsCore (bool), IsDebris (bool).",
			},
			EmulationStateReference = {
				SourceTag = "[SOURCED FROM EMULATION STATE: AlterOrb/FunOrb Destruction Logic]",
				OriginalMechanism = "Component HP pool + Breadth-First-Search (BFS) Root Reachability Check on every component death.",
				LifecycleRules = {
					PartDestruction = "When Piece.HP <= 0, the piece explodes, emitting spark/debris VFX, and its sockets are cleared.",
					OrphanCascade = "BFS traversal initiated from Chassis Root. Any connected component NOT reached during BFS is flagged as ORPHANED.",
					OrphanRelease = "Orphaned sub-graphs break apart, receive outward velocity burst + rotational impulse (simulating structural fracture), and convert into floating salvageable Debris.",
					CoreDestruction = "If Chassis Root HP <= 0, the ship undergoes CATASTROPHIC FAILURE: all attached pieces instantly detach as flying debris with radial explosive impulse.",
				},
				ArchitecturalDirectives = "Implement full BFS traversal upon any part destruction to guarantee instant severing of dangling appendages.",
			},
		},

		-- 4. WEAPONS, PROJECTILES & POINT DEFENCE
		WeaponSystems = {
			RobloxArchitecture = {
				Description = "Multi-weapon firing controller with aiming arcs, spatial raycasts, projectile simulation, and energy consumption.",
				CoreModules = {
					"ReplicatedStorage.VoidHunters.VoidHunterWeaponController",
					"StarterPlayer.StarterPlayerScripts.VoidHunterController",
					"ServerScriptService.VoidHunterServer",
				},
				PlannedFunctions = {
					"WeaponController.FireWeapon(shipModel: Model, weaponPart: BasePart, targetAimVector: Vector3) -> ProjectileData",
					"WeaponController.StepProjectiles(dt: number) -> void",
					"WeaponController.ExecutePointDefence(shipModel: Model, pdlPart: BasePart) -> void",
				},
				StateRepresentation = "Weapon types: MassDriver, PlasmaTurret, MissileLauncher, LaserBeam, SawBlade, PointDefenceLaser, FighterBay.",
			},
			EmulationStateReference = {
				SourceTag = "[SOURCED FROM EMULATION STATE: AlterOrb/FunOrb Weapons Matrix]",
				OriginalMechanism = "Deterministic tick-based weapon state machine with cooldown timers, energy drain, traverse limits, and ordnance classification.",
				WeaponProfiles = {
					MassDriver = "Long range kinetic slug, high knockback momentum, penetration chance through armor.",
					PlasmaBall = "Medium range plasma orb, high rate of fire, multi-hit continuous splash damage.",
					MissileLauncher = "Spawns homing ordnance with turn-rate clamping (`maxTurnPerTick`) and target tracking. Vulnerable to PDL and Scrambler pulses.",
					LaserBeam = "Continuous raycast trace, extreme instantaneous damage, heavy continuous energy drain.",
					SawBlade = "Close-range melee contact damage per tick. Devastating for high-speed ramming builds.",
					PointDefenceLaser = "Autonomous interceptor scanning `RADIUS_PDL` for incoming missile/ordnance entities, shooting them down before impact.",
					MissileScrambler = "Emits pulse in radius `RADIUS_SCRAMBLER` that flips target allegiance of incoming hostile missiles.",
				},
				ArchitecturalDirectives = "Ensure Point Defence specifically targets Missiles/Ordnance instances and not entire ships, matching original FunOrb defense role.",
			},
		},

		-- 5. ENERGY GRID & POWER ALLOCATION
		EnergyGrid = {
			RobloxArchitecture = {
				Description = "Shared ship energy pool calculated from active Reactor components with priority brownout handling.",
				CoreModules = {
					"ReplicatedStorage.VoidHunters.VoidHunterEnergyManager",
					"StarterPlayer.StarterPlayerScripts.VoidHunterHUD",
				},
				PlannedFunctions = {
					"EnergyManager.RecalculateCapacity(shipModel: Model) -> (number, number)",
					"EnergyManager.ConsumeEnergy(shipModel: Model, amount: number) -> boolean",
					"EnergyManager.StepRecharge(shipModel: Model, dt: number) -> void",
				},
				StateRepresentation = "Ship attributes: Energy (current), MaxEnergy (capacity), EnergyRechargeRate (per second).",
			},
			EmulationStateReference = {
				SourceTag = "[SOURCED FROM EMULATION STATE: AlterOrb/FunOrb Power Management]",
				OriginalMechanism = "Aggregate power system where reactors scale both max storage and tick replenishment.",
				PowerRules = {
					CapacityFormula = "E_max = BASE_CAPACITY + (ReactorCount * REACTOR_CAPACITY_BONUS)",
					RechargeFormula = "E_regen = BASE_REGEN + (ReactorCount * REACTOR_REGEN_RATE)",
					DrainPriority = {
						Priority1_Shields = "Continuous passive drain when active. If Energy reaches 0, shields collapse immediately.",
						Priority2_Boosters = "High drain during Spacebar boost.",
						Priority3_Weapons = "Per-shot deduction. Insufficient energy prevents weapon trigger.",
					},
				},
				ArchitecturalDirectives = "Shield generators must automatically deactivate and play power-down audio when energy is depleted.",
			},
		},

		-- 6. TRACTOR BEAM, SALVAGE & BLUEPRINT SYSTEM
		SalvageAndBuild = {
			RobloxArchitecture = {
				Description = "Interactive tractor beam dragging and snap-point welding in Build Mode, paired with 3-slot blueprint serialization.",
				CoreModules = {
					"StarterPlayer.StarterPlayerScripts.VoidHunterController",
					"StarterPlayer.StarterPlayerScripts.VoidHunterBlueprintGUI",
					"ServerScriptService.VoidHunterBlueprintStore",
				},
				PlannedFunctions = {
					"BlueprintStore.SerializeShip(shipModel: Model) -> string",
					"BlueprintStore.DeserializeShip(blueprintJson: string, spawnCFrame: CFrame) -> Model",
					"BuildMode.HandleTractorDrag(heldDebris: BasePart, targetWorldPos: Vector3) -> void",
					"BuildMode.CommitSnap(heldDebris: BasePart, targetShip: Model) -> boolean",
				},
				StateRepresentation = "Blueprint Slots 1-3 saved to DataStore / local session memory, JSON format with chassis type + relative piece socket indices.",
			},
			EmulationStateReference = {
				SourceTag = "[SOURCED FROM EMULATION STATE: AlterOrb/FunOrb Sandbox & Blueprints]",
				OriginalMechanism = "Physics-based tractor beam with distance attenuation, magnetic socket snapping, and compact slot serialization.",
				BuildMechanics = {
					TractorBeam = "Tether spring force pulling selected debris towards mouse target position within max radius (300-500px / studs).",
					SnapThreshold = "Snap occurs when connector distance < 5 studs and socket angles align within 45 degrees of cardinal angles.",
					BlueprintSchema = "{ chassis: string, components: [ { id: int, type: string, parentId: int, socketIn: int, socketOut: int } ] }",
				},
				ArchitecturalDirectives = "Blueprints must store the structural graph hierarchy rather than absolute positions, ensuring reliable reconstruction on any chassis orientation.",
			},
		},

		-- 7. SINGLEPLAYER AI & MISSION DIRECTOR
		MissionDirector = {
			RobloxArchitecture = {
				Description = "Autonomous wave spawner with AI state machines for enemy chassis tactics.",
				CoreModules = {
					"ServerScriptService.VoidHunterAIService",
					"ServerScriptService.VoidHunterWaveDirector",
				},
				PlannedFunctions = {
					"WaveDirector.SpawnWave(waveNumber: number, difficulty: number) -> void",
					"AIService.StepAI(enemyShip: Model, dt: number) -> void",
					"AIService.EvaluateTactics(enemyShip: Model, targetShip: Model) -> void",
				},
				StateRepresentation = "AI States: PATROL, APPROACH, ORBIT_FIRE, EVADE, RAMMING, FIGHTER_SWARM.",
			},
			EmulationStateReference = {
				SourceTag = "[SOURCED FROM EMULATION STATE: AlterOrb/FunOrb Singleplayer AI]",
				OriginalMechanism = "Chassis-specific tactical AI behaviors derived from the FunOrb sandbox and combat bots.",
				ChassisTactics = {
					Bullfrog = "'Thug' tactic: Direct frontal assault, aggressive ramming, mass driver volleys at point-blank range.",
					Pelican = "'Carrier' tactic: Maintains distance, deploys fighter swarms to distract and flank player.",
					Dragon = "'Striker' tactic: Fast circling maneuver, twin laser beam burning coupled with plasma ball burst.",
					Squid = "'Sniper' tactic: Releases harassment drone then retreats to edge of radar to fire sniper cannon.",
					Wasp = "'Queen' tactic: High speed evasive strafing with plasma turret and active defense lasers.",
				},
				ArchitecturalDirectives = "Assign unique AI tactical controllers based on enemy ChassisType attribute to recreate distinct combat personalities.",
			},
		},
	},

	-----------------------------------------------------------------------------
	-- FUTURE FUNCTION SIGNATURE REGISTRY (ROADMAP)
	-----------------------------------------------------------------------------
	FutureFunctionRegistry = {
		-- Physics Core
		"PhysicsWorld:Step(dt: number) -> void",
		"PhysicsWorld:RegisterBody(body: RigidBody2D) -> void",
		"PhysicsWorld:UnregisterBody(body: RigidBody2D) -> void",
		"PhysicsWorld:CastRay(origin: Vector2, direction: Vector2, maxDistance: number) -> RaycastResult2D",
		
		-- Component & Damage Core
		"Components:BuildShipFromChassis(chassisName: string, rootCFrame: CFrame) -> Model",
		"Components:ValidateSocketMatch(socketA: Attachment, socketB: Attachment) -> boolean",
		"DamageEngine:ProcessProjectileHit(projectile: Projectile, hitPart: BasePart) -> void",
		"DamageEngine:TriggerOrphanCascade(rootModel: Model, detachedPart: BasePart) -> void",
		
		-- Weapon & Ordnance Core
		"WeaponManager:FireManualWeapons(ship: Model, cursorWorldPos: Vector3) -> void",
		"WeaponManager:UpdateHomingMissiles(dt: number) -> void",
		"WeaponManager:TriggerScramblerPulse(scramblerPart: BasePart) -> number",
		
		-- Energy & Shields
		"EnergySystem:UpdateShipPower(ship: Model, dt: number) -> void",
		"ShieldSystem:HandleAbsorbedDamage(shieldBubble: BasePart, damage: number) -> number",
		
		-- Blueprints & AI
		"BlueprintSystem:SaveToSlot(player: Player, slotIndex: number, ship: Model) -> boolean",
		"BlueprintSystem:LoadFromSlot(player: Player, slotIndex: number, spawnPos: Vector3) -> Model",
		"AIDirector:AssignChassisProfile(npcShip: Model, profileName: string) -> void",
	}
}

return VoidHuntersPlan
