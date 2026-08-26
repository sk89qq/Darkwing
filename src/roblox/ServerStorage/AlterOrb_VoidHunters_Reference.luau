--[[
	ALTERORB VOID HUNTERS - REVERSE ENGINEERING & EMULATION REFERENCE
	
	Project: AlterOrb (FunOrb Game Emulation & Preservation Project)
	GitHub Organization: https://github.com/AlterOrb
	Official Site: https://alterorb.net
	
	Key Repositories:
	  1. AlterOrb/launcher       - https://github.com/AlterOrb/launcher
	     The cross-platform desktop launcher (Java 17 / Maven) that boots FunOrb
	     game JARs in singleplayer/local emulation mode.
	  
	  2. AlterOrb/patcher        - https://github.com/AlterOrb/patcher
	     Client bytecode patcher that removes multiplayer lobby dependencies,
	     bypasses Jagex server handshakes, and enables offline/standalone gameplay.
	  
	  3. AlterOrb/deobfuscator   - https://github.com/AlterOrb/deobfuscator
	     Deobfuscation pipeline and mappings for FunOrb Java client bytecodes.
	  
	  4. AlterOrb/funorb-tools   - https://github.com/AlterOrb/funorb-tools
	     Asset extraction, sprite extraction, and audio/data parsing utilities.

	-----------------------------------------------------------------------------
	VOID HUNTERS EMULATION CHARACTERISTICS (NO-MP / SINGLEPLAYER MODE):
	-----------------------------------------------------------------------------
	- Emulation Level: "Basic" / "No-MP Support"
	- In AlterOrb, Void Hunters runs with server/multiplayer lobby networking disabled.
	- The game executes the client-side game engine, local 2D vector physics, component
	  placement/attachment rules, AI enemy waves, and singleplayer mission scripts.
	- Networking stubs return local player authorization and bypass master server matchmaking.
	
	-----------------------------------------------------------------------------
	USEFUL FOR THIS ROBLOX RECREATION:
	-----------------------------------------------------------------------------
	- Component Stats & Hardpoint Layouts:
	    Command Core (250 HP, essential root component)
	    Armor Plating (Heavy / Light / Composite)
	    Reactors (Power distribution & regeneration)
	    Thrusters (Main, Vector/Lateral, Boosters)
	    Weapons (Mass Driver, Plasma Turret, Missile Launcher, Laser, Drone Bay, Point Defence)
	    Utilities (Shield Generator, Scrambler Pulse, Grappling Hook, Repair Bay)
	
	- Gameplay Rules & Physics Reference:
	    2D Top-Down X-Z space plane with inertial dampening and vectored thrust
	    Snap-to-connector building system (InConnect / OutConnect hardpoints)
	    Modular damage model where losing peripheral parts does not kill unless Core is destroyed
	    Debris salvage system (detached components float and can be attached in build mode)
]]

local AlterOrbReference = {
	Project = "AlterOrb",
	OrganizationURL = "https://github.com/AlterOrb",
	LauncherRepo = "https://github.com/AlterOrb/launcher",
	PatcherRepo = "https://github.com/AlterOrb/patcher",
	DeobfuscatorRepo = "https://github.com/AlterOrb/deobfuscator",
	ToolsRepo = "https://github.com/AlterOrb/funorb-tools",
	Website = "https://alterorb.net",
	Game = "Void Hunters",
	MPStatus = "No-MP / Singleplayer Emulation",
	Description = "Single-player client emulation of FunOrb Void Hunters with network calls patched out for standalone play."
}

return AlterOrbReference
