--[=[
	VoidHunterBuilderServer

	Blueprint persistence uses a versioned primitive-only DataStore schema.
	All physical attachment mutations route through StructuralAuthority.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local builderEvent = ReplicatedStorage:WaitForChild("VoidHunterBuilder")
local Components = require(ReplicatedStorage:WaitForChild("VoidHunterComponents"))
local StructuralAuthority = require(ReplicatedStorage.Shared.Ship:WaitForChild("StructuralAuthority"))

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
	if typeof(explicit) == "string" and Components.Types[explicit] then
		return explicit
	end
	for typeName, definition in pairs(Components.Types) do
		if definition.Name == part.Name then
			return typeName
		end
	end
	return nil
end

local function findPrimary(m: Model): BasePart?
	if m.PrimaryPart then
		return m.PrimaryPart
	end
	for _, desc in ipairs(m:GetDescendants()) do
		if desc:IsA("BasePart") and desc:GetAttribute("IsCore") then
			m.PrimaryPart = desc
			return desc
		end
	end
	return m:FindFirstChildWhichIsA("BasePart", true)
end

local function cframeToData(cf: CFrame): {[string]: number}
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
	local parts = {}

	for _, part in ipairs(ship:GetDescendants()) do
		if part:IsA("BasePart") and not part:IsA("VehicleSeat") then
			local typeName = resolveType(part)
			if typeName then
				local relative = primary and primary.CFrame:ToObjectSpace(part.CFrame) or part.CFrame
				table.insert(parts, {
					partType = typeName,
					transform = cframeToData(relative),
					name = part.Name,
					NodeId = part:GetAttribute("NodeId"),
					ComponentId = part:GetAttribute("ComponentId"),
					ParentNodeId = part:GetAttribute("ParentNodeId"),
					ParentSocketId = part:GetAttribute("ParentSocketId"),
				})
			end
		end
	end

	return {
		version = BLUEPRINT_VERSION,
		name = ship.Name .. "_BP",
		rootType = primary and resolveType(primary) or nil,
		parts = parts,
	}
end

local function normalizeBlueprint(raw: any): any?
	if type(raw) ~= "table" then
		return nil
	end

	-- V2 is already the canonical schema.
	if raw.version == BLUEPRINT_VERSION and type(raw.parts) == "table" then
		return raw
	end

	-- Legacy compatibility: convert previous flat CFrame entries in memory.
	if type(raw.parts) == "table" then
		local migrated = {
			version = BLUEPRINT_VERSION,
			name = raw.name or "Ship_BP",
			rootType = raw.rootType,
			parts = {},
		}
		for _, entry in ipairs(raw.parts) do
			if type(entry) == "table" and type(entry.partType) == "string" then
				local transform = entry.transform
				if not transform and typeof(entry.cframe) == "CFrame" then
					transform = cframeToData(entry.cframe)
				end
				if transform then
					table.insert(migrated.parts, {
						partType = entry.partType,
						transform = transform,
						name = entry.name,
						NodeId = entry.NodeId,
						ComponentId = entry.ComponentId,
						ParentNodeId = entry.ParentNodeId,
						ParentSocketId = entry.ParentSocketId,
					})
				end
			end
		end
		return migrated
	end

	-- Compatibility with the older SyncManager format.
	if type(raw.Components) == "table" then
		local migrated = {
			version = BLUEPRINT_VERSION,
			name = raw.Name or "Ship_BP",
			rootType = nil,
			parts = {},
		}
		for _, comp in ipairs(raw.Components) do
			if type(comp) == "table" and type(comp.Type) == "string" and type(comp.Pos) == "table" then
				local rot = type(comp.Rot) == "table" and comp.Rot or { X = 0, Y = 0, Z = 0 }
				local cf = CFrame.new(comp.Pos.X or 0, comp.Pos.Y or 0, comp.Pos.Z or 0)
					* CFrame.Angles(math.rad(rot.X or 0), math.rad(rot.Y or 0), math.rad(rot.Z or 0))
				table.insert(migrated.parts, {
					partType = comp.Type,
					transform = cframeToData(cf),
				})
			end
		end
		return migrated
	end

	return nil
end

local function saveBlueprint(player: Player, ship: Model)
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

	local key = "bp_" .. player.UserId
	local saveOk, saveErr = pcall(function()
		store:SetAsync(key, blueprint)
	end)
	if not saveOk then
		warn("Blueprint save failed: " .. tostring(saveErr))
		return false, "Save failed"
	end

	return true, blueprint
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
	local success, raw = pcall(function()
		return store:GetAsync("bp_" .. player.UserId)
	end)
	local blueprint = success and normalizeBlueprint(raw) or nil
	if not blueprint then
		autoActive[player] = false
		return
	end

	local primary = findPrimary(ship)
	if not primary then
		autoActive[player] = false
		return
	end

	for _, entry in ipairs(blueprint.parts) do
		if not autoActive[player] or not ship.Parent then
			break
		end

		local definition = Components.Types[entry.partType]
		local targetCF = dataToCFrame(entry.transform)
		if not definition or not targetCF then
			continue
		end

		local debris = getNearbyDebris(entry.partType, primary.Position, 45)
		if not debris then
			continue
		end

		-- Move only as a visual/build preview; StructuralAuthority validates the final snap.
		debris.CFrame = primary.CFrame:ToWorldSpace(targetCF)
		local _, attachError = StructuralAuthority.AttachComponent(ship, debris, entry.partType, 6)
		if attachError then
			-- Return the part to debris state; never consume an unusable part.
			debris:SetAttribute("IsDebris", true)
			continue
		end

		debris:SetAttribute("IsDebris", nil)
		debris:SetAttribute("ComponentDetached", nil)
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

	local ownerId = ship:GetAttribute("OwnerId")
	if ownerId and ownerId ~= player.UserId then
		return
	end

	if action == "save_blueprint" then
		saveBlueprint(player, ship)
	elseif action == "start_blueprint" then
		task.spawn(autoBuild, player, ship)
	elseif action == "stop_blueprint" then
		autoActive[player] = false
	elseif action == "detach" and partName then
		local part = ship:FindFirstChild(partName, true)
		if part and part:IsA("BasePart") then
			StructuralAuthority.DetachComponent(ship, part, "ManualDetach")
		end
	elseif action == "weld" and partName then
		local part = ship:FindFirstChild(partName, true)
		if part and part:IsA("BasePart") then
			StructuralAuthority.BindShip(ship)
		end
	end
end)

function BuilderServer.BuildShipFromBlueprint(blueprint)
	local normalized = normalizeBlueprint(blueprint)
	if not normalized then
		warn("Invalid blueprint provided")
		return nil
	end

	local ship = Instance.new("Model")
	ship.Name = normalized.name or "Ship"
	ship:SetAttribute("IsShip", true)

	local primaryPart: BasePart? = nil
	for index, comp in ipairs(normalized.parts) do
		local result = Components.Create(comp.partType)
		local transform = dataToCFrame(comp.transform)
		if result and result.part and transform then
			local part = result.part
			part.CFrame = transform
			part.Parent = ship
			part:SetAttribute("NodeId", comp.NodeId)
			part:SetAttribute("ComponentId", comp.ComponentId)
			part:SetAttribute("ParentNodeId", comp.ParentNodeId)
			part:SetAttribute("ParentSocketId", comp.ParentSocketId)
			primaryPart = primaryPart or part
		end
	end

	if primaryPart then
		ship.PrimaryPart = primaryPart
		StructuralAuthority.BindShip(ship)
	end
	return ship
end

function BuilderServer.GetBlueprint(player: Player)
	local okGet, data = pcall(function()
		return store:GetAsync("bp_" .. player.UserId)
	end)
	return okGet and normalizeBlueprint(data) or nil
end

Players.PlayerRemoving:Connect(function(player)
	autoActive[player] = nil
	saveCooldowns[player.UserId] = nil
end)

print("BuilderServer loaded")
return BuilderServer
