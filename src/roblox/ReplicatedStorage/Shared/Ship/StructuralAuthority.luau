--[=[
	StructuralAuthority
	Canonical ship graph mutation boundary.

	ShipSocketGraph remains the socket/geometry solver. This service is the only
	runtime boundary intended to perform structural attach, detach, replacement,
	and severance.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ShipSocketGraph = require(ReplicatedStorage.Shared:WaitForChild("ShipSocketGraph"))
local ComponentAuthority = require(ReplicatedStorage.Shared.Combat:WaitForChild("ComponentAuthority"))

local StructuralAuthority = {}
StructuralAuthority.__index = StructuralAuthority

local function getDebrisFolder(): Folder
	local folder = Workspace:FindFirstChild("VoidHunterDebris")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "VoidHunterDebris"
		folder.Parent = Workspace
	end
	return folder
end

local function collectNodeSubtree(graph: any, rootNodeId: string): { any }
	local result = {}
	local visited: { [string]: boolean } = {}
	local queue = { rootNodeId }
	local head = 1

	while head <= #queue do
		local nodeId = queue[head]
		head += 1
		if not visited[nodeId] then
			visited[nodeId] = true
			local node = graph.Nodes[nodeId]
			if node then
				result[#result + 1] = node
				for _, childId in pairs(node.ChildNodes) do
					queue[#queue + 1] = childId
				end
			end
		end
	end

	return result
end

local function disconnectExternalWelds(parts: { BasePart })
	local inSet: { [BasePart]: boolean } = {}
	for _, part in ipairs(parts) do
		inSet[part] = true
	end

	for _, part in ipairs(parts) do
		for _, descendant in ipairs(part:GetDescendants()) do
			if descendant:IsA("WeldConstraint") then
				local p0, p1 = descendant.Part0, descendant.Part1
				if p0 and p1 and (inSet[p0] ~= inSet[p1]) then
					descendant:Destroy()
				end
			end
		end
	end
end

function StructuralAuthority.BuildGraph(ship: Model): any
	assert(ship and ship:IsA("Model"), "StructuralAuthority.BuildGraph expects a ship Model")
	return ShipSocketGraph.new(ship)
end

function StructuralAuthority.BindShip(ship: Model)
	ComponentAuthority.BindShip(ship)
	return StructuralAuthority.BuildGraph(ship)
end

function StructuralAuthority.AttachComponent(ship: Model, part: BasePart, componentType: string, maxSnapDistance: number?): (any?, string?)
	if not ship or not ship.Parent or not part or not part.Parent then
		return nil, "invalid input"
	end

	local graph = StructuralAuthority.BuildGraph(ship)
	local candidate = graph:FindBestSnap(part, componentType, maxSnapDistance)
	if not candidate then
		return nil, "no compatible hardpoint"
	end

	part.CFrame = candidate.TargetCFrame
	local childNode = graph:AttachComponent(candidate.ParentNode, candidate.ParentSocket, part, componentType)
	if not childNode then
		return nil, "graph attach failed"
	end

	ComponentAuthority.Bind(part, componentType)
	ComponentAuthority.SetParent(part, candidate.ParentNode.Part)
	return childNode, nil
end

function StructuralAuthority.DetachComponent(ship: Model, part: BasePart, reason: string?): Model?
	if not ship or not ship.Parent or not part or not part.Parent then
		return nil
	end
	if not part:IsDescendantOf(ship) then
		return nil
	end

	local graph = StructuralAuthority.BuildGraph(ship)
	local nodeId = part:GetAttribute("NodeId")
	if not nodeId or not graph.Nodes[nodeId] then
		return nil
	end
	if graph.RootNodeId == nodeId then
		return nil
	end

	local nodes = collectNodeSubtree(graph, nodeId)
	if #nodes == 0 then
		return nil
	end

	local parts = {}
	for _, node in ipairs(nodes) do
		if node.Part and node.Part.Parent then
			parts[#parts + 1] = node.Part
		end
	end
	if #parts == 0 then
		return nil
	end

	disconnectExternalWelds(parts)

	local debrisAssembly = Instance.new("Model")
	debrisAssembly.Name = "DebrisAssembly"
	debrisAssembly:SetAttribute("IsDebris", true)
	debrisAssembly:SetAttribute("DetachReason", reason or "StructuralDamage")
	debrisAssembly:SetAttribute("SourceShipId", ship:GetAttribute("ShipId") or ship.Name)
	debrisAssembly.Parent = getDebrisFolder()

	local sourceVelocity = Vector3.zero
	local sourceAngular = Vector3.zero
	if ship.PrimaryPart then
		sourceVelocity = ship.PrimaryPart.AssemblyLinearVelocity
		sourceAngular = ship.PrimaryPart.AssemblyAngularVelocity
	end

	for _, detachedPart in ipairs(parts) do
		detachedPart:SetAttribute("IsDebris", true)
		detachedPart:SetAttribute("ComponentDetached", true)
		ComponentAuthority.SetParent(detachedPart, nil)
		detachedPart.Parent = debrisAssembly
	end

	debrisAssembly.PrimaryPart = parts[1]
	for _, detachedPart in ipairs(parts) do
		detachedPart.Anchored = false
		detachedPart.AssemblyLinearVelocity = sourceVelocity
		detachedPart.AssemblyAngularVelocity = sourceAngular
	end

	return debrisAssembly
end

function StructuralAuthority.SeverDisconnected(ship: Model): { Model }
	if not ship or not ship.Parent then
		return {}
	end

	local graph = StructuralAuthority.BuildGraph(ship)
	if not graph.RootNodeId then
		return {}
	end

	local reachable: { [string]: boolean } = {}
	local queue = { graph.RootNodeId }
	local head = 1
	while head <= #queue do
		local nodeId = queue[head]
		head += 1
		if not reachable[nodeId] then
			reachable[nodeId] = true
			local node = graph.Nodes[nodeId]
			if node then
				for _, childId in pairs(node.ChildNodes) do
					queue[#queue + 1] = childId
				end
			end
		end
	end

	local detached = {}
	local rootsToDetach = {}
	for nodeId, node in pairs(graph.Nodes) do
		if not reachable[nodeId] and node.ParentNodeId == nil then
			rootsToDetach[#rootsToDetach + 1] = node
		end
	end

	for _, node in ipairs(rootsToDetach) do
		if node.Part and node.Part.Parent then
			local assembly = StructuralAuthority.DetachComponent(ship, node.Part, "Disconnected")
			if assembly then
				detached[#detached + 1] = assembly
			end
		end
	end

	return detached
end

function StructuralAuthority.ReplaceComponent(ship: Model, oldPart: BasePart, newPart: BasePart, componentType: string, maxSnapDistance: number?): (Model?, boolean)
	if not ship or not oldPart or not newPart or oldPart == newPart then
		return nil, false
	end

	local graph = StructuralAuthority.BuildGraph(ship)
	local oldNodeId = oldPart:GetAttribute("NodeId")
	local oldNode = oldNodeId and graph.Nodes[oldNodeId]
	if not oldNode or oldNode.IsCore then
		return nil, false
	end

	local oldCFrame = oldPart.CFrame
	local detached = StructuralAuthority.DetachComponent(ship, oldPart, "Replacement")
	if not detached then
		return nil, false
	end

	local _, attachError = StructuralAuthority.AttachComponent(ship, newPart, componentType, maxSnapDistance)
	if not attachError then
		return detached, true
	end

	-- Replacement failed. Restore the old physical assembly rather than silently
	-- losing a valid component. Exact hardpoint restoration remains source-fidelity
	-- work until the original replacement method is fully recovered.
	local oldRoot = detached.PrimaryPart or detached:FindFirstChildWhichIsA("BasePart", true)
	if oldRoot then
		detached.Parent = ship
		oldRoot.CFrame = oldCFrame
		oldRoot:SetAttribute("IsDebris", nil)
		oldRoot:SetAttribute("ComponentDetached", nil)
		ComponentAuthority.SetParent(oldRoot, nil)
	end

	return detached, false
end

return StructuralAuthority
