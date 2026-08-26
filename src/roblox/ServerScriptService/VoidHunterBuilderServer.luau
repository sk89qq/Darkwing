--[=[
	VoidHunterBuilderServer

	Canonical blueprint persistence and physical ship construction boundary.
	All physical structural mutations route through StructuralAuthority.

	V2 blueprint reconstruction is delegated to BlueprintLoader. Legacy stored
	blueprints remain readable through normalizeBlueprint until migrated, but no
	new direct topology construction is performed for V2 data.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local builderEvent = ReplicatedStorage:WaitForChild("VoidHunterBuilder")
local Components = require(ReplicatedStorage:WaitForChild("VoidHunterComponents"))
local StructuralAuthority = require(ReplicatedStorage.Shared.Ship:WaitForChild("StructuralAuthority"))
local BlueprintSerializer = require(ReplicatedStorage.Shared.Ship:WaitForChild("BlueprintSerializer"))
local BlueprintLoader = require(ReplicatedStorage.Shared.Ship:WaitForChild("BlueprintLoader"))

local store
local ok, err = pcall(function()
	store = DataStoreService:GetDataStore("VHBlueprints")
end)
if not ok then
	warn("VHBlueprints DataStore unavailable: " .. tostring(err))
	store = { data = {} }
	function store:SetAsync(key, value)
		self.data[key] = value
	end
	function store:GetAsync(key)
		return self.data[key]
	end
end

local BuilderServer = {}
local autoActive: { [Player]: boolean } = {}
local saveCooldowns: { [number]: number } = {}
local SAVE_COOLDOWN = 2
local BLUEPRINT_VERSION = 2

local function resolveType(part: BasePart): string?
	local explicit = part:GetAttribute("ComponentType")
	if typeof(explicit) == "string" and Components.Types[explicit] and Components.Connections[explicit] then
		return explicit
	end
	return nil
end

local function findPrimary(model: Model): BasePart?
	local primary = model.PrimaryPart
	if primary and primary:IsA("BasePart") and resolveType(primary) then
		return primary
	end
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant:GetAttribute("IsCore") == true and resolveType(descendant) then
			model.PrimaryPart = descendant
			return descendant
		end
	end
	return nil
end

local function cframeToData(cf: CFrame): { [string]: number }
	local rx, ry, rz = cf:ToOrientation()
	return {
		px = cf.Position.X,
		py = cf.Position.Y,
		pz = cf.Position.Z,
		rx = rx,
		ry = ry,
		rz = rz,
	}
end

local function dataToCFrame(data: any): CFrame?
	if type(data) ~= "table" then
		return nil
	end
	if typeof(data.px) ~= "number" or typeof(data.py) ~= "number" or typeof(data.pz) ~= "number" then
		return nil
	end
	local rx = typeof(data.rx) == "number" and data.rx or 0
	local ry = typeof(data.ry) == "number" and data.ry or 0
	local rz = typeof(data.rz) == "number" and data.rz or 0
	return CFrame.new(data.px, data.py, data.pz) * CFrame.fromOrientation(rx, ry, rz)
end

local function captureShip(ship: Model)
	local primary = findPrimary(ship)
	if not primary then
		error("No authoritative ship core")
	end

	local captured = BlueprintSerializer.Capture(ship)
	if not captured then
		error("BlueprintSerializer capture failed")
	end

	return captured
end

local function saveBlueprintInternal(player: Player, ship: Model)
	local now = os.clock()
	local previous = saveCooldowns[player.UserId]
	if previous and now - previous < SAVE_COOLDOWN then
		return false, "Rate limited"
	end
	saveCooldowns[player.UserId] = now

	local success, blueprint = pcall(captureShip, ship)
	if not success then
		warn("Blueprint capture failed: " .. tostring(blueprint))
		return false, "Capture failed"
	end

	local encoded = BlueprintSerializer.Encode(blueprint)
	local saveOk, saveErr = pcall(function()
		store:SetAsync("bp_" .. player.UserId, encoded)
	end)
	if not saveOk then
		warn("Blueprint save failed: " .. tostring(saveErr))
		return false, "Save failed"
	end
	return true, blueprint
end

function BuilderServer.SaveBlueprint(player: Player, ship: Model)
	if not player or not player.Parent or not ship or not ship.Parent then
		return false, "Invalid input"
	end
	if ship:GetAttribute("OwnerId") ~= player.UserId then
		return false, "Not owner"
	end
	return saveBlueprintInternal(player, ship)
end

local function normalizeLegacyBlueprint(raw: any): BlueprintSerializer.Blueprint?
	if type(raw) ~= "table" then
		return nil
	end

	if raw.Version == BLUEPRINT_VERSION and type(raw.Components) == "table" then
		return raw :: BlueprintSerializer.Blueprint
	end

	if type(raw.parts) == "table" then
		local components = {}
		local rootComponentId: string? = nil
		local previousId: string? = nil
		for index, entry in ipairs(raw.parts) do
			if type(entry) == "table" and type(entry.partType) == "string" then
				local transform = entry.transform
				if transform and dataToCFrame(transform) then
					local id = typeof(entry.ComponentId) == "string" and entry.ComponentId or ("legacy_" .. tostring(index))
					components[#components + 1] = {
						Id = id,
						ComponentType = entry.partType,
						ParentId = previousId,
						ParentHardpointId = entry.ParentSocketId,
						ChildHardpointId = entry.ConnectedSocketId,
						Position = { x = transform.px, y = transform.pz },
						Angle = -(transform.ry or 0),
					}
					rootComponentId = rootComponentId or id
					previousId = id
				end
			end
		end
		if rootComponentId and #components > 0 then
			return {
				Version = BLUEPRINT_VERSION,
				RootComponentId = rootComponentId,
				Components = components,
			}
		end
	end

	return nil
end

function BuilderServer.GetBlueprint(player: Player): BlueprintSerializer.Blueprint?
	local okGet, encoded = pcall(function()
		return store:GetAsync("bp_" .. player.UserId)
	end)
	if not okGet then
		return nil
	end

	if typeof(encoded) == "string" then
		local decoded = BlueprintSerializer.Decode(encoded)
		if decoded then
			return decoded
		end
	end

	return normalizeLegacyBlueprint(encoded)
end

local function getNearbyDebris(componentName: string, origin: Vector3, maxDistance: number): BasePart?
	local folder = workspace:FindFirstChild("VoidHunterDebris")
	if not folder then
		return nil
	end

	local nearest: BasePart? = nil
	local nearestDistance = maxDistance
	for _, instance in ipairs(folder:GetDescendants()) do
		if instance:IsA("BasePart") and instance:GetAttribute("IsDebris") then
			local typeName = resolveType(instance)
			if typeName == componentName then
				local distance = (instance.Position - origin).Magnitude
				if distance < nearestDistance then
					nearestDistance = distance
					nearest = instance
				end
			end
		end
	end
	return nearest
end

local function autoBuild(player: Player, ship: Model)
	autoActive[player] = true
	local blueprint = BuilderServer.GetBlueprint(player)
	if not blueprint then
		autoActive[player] = false
		return
	end

	local primary = findPrimary(ship)
	if not primary then
		autoActive[player] = false
		return
	end

	for _, entry in ipairs(blueprint.Components) do
		if not autoActive[player] or not ship.Parent then
			break
		end

		local debris = getNearbyDebris(entry.ComponentType, primary.Position, 45)
		if not debris then
			continue
		end

		local localCFrame = CFrame.new(entry.Position.x, 0, entry.Position.y) * CFrame.Angles(0, -entry.Angle, 0)
		debris.CFrame = primary.CFrame:ToWorldSpace(localCFrame)
		local _, attachError = StructuralAuthority.AttachComponent(ship, debris, entry.ComponentType, Components.SNAP_DISTANCE or 5)
		if attachError then
			debris:SetAttribute("IsDebris", true)
		end
	end

	autoActive[player] = false
end

builderEvent.OnServerEvent:Connect(function(player: Player, action: string, ship: Model?, partName: string?)
	if typeof(action) ~= "string" or not ship or not ship.Parent then
		return
	end
	if not ship:IsA("Model") or not ship:GetAttribute("IsShip") then
		return
	end
	if ship:GetAttribute("OwnerId") ~= player.UserId then
		return
	end

	if action == "save_blueprint" then
		BuilderServer.SaveBlueprint(player, ship)
	elseif action == "start_blueprint" then
		task.spawn(autoBuild, player, ship)
	elseif action == "stop_blueprint" then
		autoActive[player] = false
	elseif action == "detach" and partName then
		local part = ship:FindFirstChild(partName, true)
		if part and part:IsA("BasePart") then
			StructuralAuthority.DetachComponent(ship, part, "ManualDetach")
		end
	elseif action == "weld" then
		StructuralAuthority.BindShip(ship)
	end
end)

function BuilderServer.BuildShipFromBlueprint(blueprint: any): Model?
	local normalized = blueprint
	if not (type(normalized) == "table" and normalized.Version == BLUEPRINT_VERSION and type(normalized.Components) == "table") then
		normalized = normalizeLegacyBlueprint(blueprint)
	end
	if not normalized then
		warn("Invalid blueprint provided")
		return nil
	end

	local ship = Instance.new("Model")
	ship.Name = "Ship"
	ship:SetAttribute("IsShip", true)

	local factory = function(componentType: string, _logicalId: string): BasePart?
		local created = Components.Create(componentType)
		return created and created.part or nil
	end

	local loaded, loadError = BlueprintLoader.Load(ship, normalized :: BlueprintSerializer.Blueprint, factory)
	if not loaded then
		ship:Destroy()
		warn("Blueprint construction failed: " .. tostring(loadError))
		return nil
	end

	return ship
end

Players.PlayerRemoving:Connect(function(player: Player)
	autoActive[player] = nil
	saveCooldowns[player.UserId] = nil
end)

return BuilderServer