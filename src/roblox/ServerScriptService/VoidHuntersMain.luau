-- VoidHunters Main Entry Point

-- Initialize Tutorial Tracker first (handles player data)
local TutorialTracker = require(game.ServerScriptService.VoidHunters:WaitForChild("VoidHunterTutorialTracker"))

-- Initialize Game Manager
local GameManager = require(game.ServerScriptService.VoidHunters:WaitForChild("VoidHunterGameManager"))
GameManager.Init()

-- Initialize PlayerRouter
local PlayerRouter = require(game.ServerScriptService.VoidHunters.VoidHunterPlayerRouter:WaitForChild("PlayerRouter"))
PlayerRouter.Init()

-- Initialize HUD Controller
local HUDController = require(game.ServerScriptService.VoidHunters.PhoenixCoreHUDController:WaitForChild("HUDController"))

-- Initialize Audio Manager
local AudioManager = require(game.ServerScriptService.VoidHunters:WaitForChild("PhoenixCoreAudioManager"))
AudioManager.Init()

print("[VoidHunters] All systems initialized")
