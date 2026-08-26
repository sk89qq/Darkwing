--[=[
	VoidHunterBuilderServer

	Blueprint persistence remains compatible with the current project format, but
	all physical attachment mutations now go through StructuralAuthority. Manual
	build and AutoBuild therefore share the same socket/graph mutation boundary.
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
					cframe = relative,
					name = part.Name,
					NodeId = part:GetAttribute("NodeId"),
					ComponentId = part:GetAttribute("ComponentId"),
					ParentNodeId = part:GetAttribute("ParentNodeId"),
				})
			end
		end
	end

	return {
		version = 2,
		name = ship.Name .. "_BP",
		parts = parts,
	}
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
	local nearest: BasePart? = nil
	local nearestDistance = maxDistance
	local folder = workspace:FindFirstChild("VoidHunterDebris")
	if not folder then
		return nil
	end

	for _, instance in ipairs(folder:GetDescendants()) do
		if instance:IsA("BasePart") and instance:GetAttribute("IsDebris") then
			local definition = Components.Types[componentName]
			local typeName = resolveType(instance)
			if definition and typeName == componentName then
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
	local success, blueprint = pcall(function()
		return store:GetAsync("bp_" .. player.UserId)
	end)
	if not success or not blueprint or not blueprint.parts then
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
		if not definition then
			continue
		end

		local debris = getNearbyDebris(entry.partType, primary.Position, 45)
		if not debris then
			continue
		end

		-- Let the canonical graph solver decide whether/how this part attaches.
		-- We do not nearest-neighbor weld or invent a new socket relationship here.
		local targetCFrame = primary.CFrame:ToWorldSpace(entry.cframe)
		debris.CFrame = CFrame.new(targetCFrame.Position.X, 3.5, targetCFrame.Position.Z) * (targetCFrame - targetCFrame.Position)

		local _, attachError = StructuralAuthority.AttachComponent(ship, debris, entry.partType, 6)
		if attachError then
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
		-- Welding is intentionally routed through the same graph on the next build
		-- validation pass; do not create an arbitrary WeldConstraint here.
		local part = ship:FindFirstChild(partName, true)
		if part and part:IsA("BasePart") then
			StructuralAuthority.BindShip(ship)
		end
	end
end)

function BuilderServer.BuildShipFromBlueprint(blueprint)
	if not blueprint or not blueprint.Components then
		warn("Invalid blueprint provided")
		return nil
	end

	local ship = Instance.new("Model")
	ship.Name = blueprint.Name or "Ship"
	ship:SetAttribute("IsShip", true)

	local primaryPart: BasePart? = nil
	for _, comp in ipairs(blueprint.Components) do
		local result = Components.Create(comp.Type)
		if result and result.part then
			local part = result.part
			part.CFrame = CFrame.new(comp.Pos) * CFrame.Angles(math.rad(comp.Rot.X), math.rad(comp.Rot.Y), math.rad(comp.Rot.Z))
			part.Parent = ship
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
	return okGet and data or nil
end

Players.PlayerRemoving:Connect(function(player)
	autoActive[player] = nil
	saveCooldowns[player.UserId] = nil
end)

print("BuilderServer loaded")
return BuilderServer
