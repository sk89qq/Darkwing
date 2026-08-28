-- ARCHIVED LEGACY PROTOTYPE
-- Original active path: src/roblox/ReplicatedStorage/VoidHunters/VoidHunterWeaponController.luau
-- Preserved verbatim for forensic/history purposes. NOT RUNTIME AUTHORITY.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local Components = require(ReplicatedStorage.VoidHunters:WaitForChild("VoidHunterComponents"))

local UNIT = Components.UNIT
local commsFolder = ReplicatedStorage:WaitForChild("Communication")
local FireWeaponEvent = commsFolder:FindFirstChild("VoidHunterFireWeapon") or Instance.new("RemoteEvent", commsFolder)
FireWeaponEvent.Name = "VoidHunterFireWeapon"
local FireScramblerEvent = commsFolder:FindFirstChild("攻擊者FireScrambler") or Instance.new("RemoteEvent", commsFolder)
FireScramblerEvent.Name = "VoidHunterFireScrambler"
local weaponCooldowns = {}
local partHP = {}
local shipEnergy = {}
local function GetShipParts(ship) local p = {} for _, c in ipairs(ship:GetDescendants()) do if c:IsA("BasePart") and not c:IsA("VehicleSeat") then table.insert(p, c) end end return p end
local function GetComponentType(part) for tn, def in pairs(Components.Types) do if def.Name == part.Name then return tn end end; return nil end
local function GetPartOwner(part) local m = part:FindFirstAncestorOfClass("Model") return m and m:GetAttribute("Type") == "Ship" and m or nil end
function WeaponController.ApplyDamage(hitPart, damage, isPlasma) if partHP[hitPart] == nil then local def = nil for _, d in pairs(Components.Types) do if d.Name == hitPart.Name then def = d; break end end partHP[hitPart] = def and def.HP or 50 end partHP[hitPart] = math.max(0, partHP[hitPart] - damage) if partHP[hitPart] <= 0 then WeaponController.DestroyComponent(hitPart) end end
function WeaponController.DestroyComponent(part) local ship = GetPartOwner(part) part:Destroy() if part.Name == "Command Core" and ship then ship:Destroy() end end
function WeaponController.FireWeapon(ship, weaponType, targetPos) print("Firing " .. weaponType .. " from " .. ship.Name) end
return WeaponController
