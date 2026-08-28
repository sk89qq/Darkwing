--[=[
	StructuralAuthority
	Canonical ship graph mutation boundary.

	ShipSocketGraph remains the socket/geometry solver. This service is the only
	runtime boundary intended to perform structural attach, detach, replacement,
	and severance.

	Physics boundary:
	- Logical graph mutation remains authoritative.
	- BodyRecomputeService is the single post-mutation recompute boundary.
	- Detached assemblies inherit rigid-body point kinematics from the source ship.
	- Native debris launch terms remain a separate forensic mapping until their
	  source constants and call context are completely recovered.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Components = require(ReplicatedStorage:WaitForChild("VoidHunterComponents"))
local ShipSocketGraph = require(ReplicatedStorage.Shared:WaitForChild("ShipSocketGraph"))
local ComponentAuthority = require(ReplicatedStorage.Shared.Combat:WaitForChild("ComponentAuthority"))
local RigidBody2D = require(ReplicatedStorage.Shared.Physics:WaitForChild("RigidBody2D"))
local MassPoint = require(ReplicatedStorage.Shared.Physics:WaitForChild("MassPoint"))
local PhysicsConfig = require(ReplicatedStorage.Shared.Physics:WaitForChild("PhysicsConfig"))
local BodyRecomputeService = require(ReplicatedStorage.Shared.Physics:WaitForChild("BodyRecomputeService"))

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

local function getCompatibleOutSocket(graph: any, parentNode: any, parentSocket: any, childPart: BasePart, componentType: string): string?
	if not Components.Types[componentType] or not Components.Connections[componentType] then
		return nil
	end
	if not parentNode or not parentSocket or parentSocket.IsOccupied then
		return nil
	end
	if parentSocket.Type ~= "InConnect" then
		return nil
	end

	local childSockets = graph:ExtractComponentSockets(componentType)
	local bestSocketId: string? = nil
	local bestDistance = math.huge
	for socketId, socket in pairs(childSockets) do
		if socket.Type == "OutConnect" then
			local childPosition = childPart.CFrame:PointToWorldSpace(socket.LocalOffset)
			local parentPosition = parentNode.Part.CFrame:PointToWorldSpace(parentSocket.LocalOffset)
			local distance = (childPosition - parentPosition).Magnitude
			if distance < bestDistance then
				bestDistance = distance
				bestSocketId = socketId
			end
		end
	end

	return bestSocketId
end

local function alignPartToSocket(parentNode: any, parentSocket: any, childPart: BasePart, childSocketOffset: Vector3)
	local parentCF = parentNode.Part.CFrame
	local targetSocketPosition = parentCF:PointToWorldSpace(parentSocket.LocalOffset)
	local targetRotation = parentCF - parentCF.Position
	local targetCF = CFrame.new(targetSocketPosition) * targetRotation
	childPart.CFrame = targetCF * CFrame.new(-childSocketOffset)
end

local function getCanonicalComponentMass(part: BasePart): number
	local state = ComponentAuthority.Get(part) or ComponentAuthority.Bind(part)
	local definition = state and Components.Types[state.TypeName]
	if definition then
		for _, value in ipairs({ definition.Mass, definition.PhysicsMass, definition.BodyMass }) do
			if typeof(value) == "number" and value > 0 and value ~= math.huge then
				return value
			end
		end
	end

	local instanceMass = part:GetAttribute("ComponentMass")
	if typeof(instanceMass) == "number" and instanceMass > 0 and instanceMass ~= math.huge then
		return instanceMass
	end

	return PhysicsConfig.DEFAULT_PIECE_MASS
end

local function createSourceRigidBody(ship: Model): any?
	local primaryPart = ship.PrimaryPart
	if not primaryPart then
		return nil
	end

	local body = RigidBody2D.new(
		Vector2.new(primaryPart.Position.X, primaryPart.Position.Z),
		0,
		ship:GetAttribute("ShipId")
	)
	body.Velocity = Vector2.new(primaryPart.AssemblyLinearVelocity.X, primaryPart.AssemblyLinearVelocity.Z)
	body.AngularVelocity = primaryPart.AssemblyAngularVelocity.Y

	local pivot = ship:GetPivot()
	for _, instance in ipairs(ship:GetDescendants()) do
		if instance:IsA("BasePart") and not instance:IsA("VehicleSeat") and ComponentAuthority.IsComponent(instance) then
			local localPosition3D = pivot:PointToObjectSpace(instance.Position)
			local localPosition = Vector2.new(localPosition3D.X, localPosition3D.Z)
			local mass = getCanonicalComponentMass(instance)
			local localInertia = mass * (instance.Size.X * instance.Size.X + instance.Size.Z * instance.Size.Z) / 12
			body.MassPoints[#body.MassPoints + 1] = MassPoint.new(
				mass,
				localPosition,
				math.max(localInertia, 0.0001),
				instance:GetAttribute("ComponentType"),
				instance:GetAttribute("ComponentId")
			)
		end
	end

	BodyRecomputeService.Recompute(body)
	return body
end

local function recomputeShipBody(ship: Model): any?
	local body = createSourceRigidBody(ship)
	if not body then
		return nil
	end

	ship:SetAttribute("BodyMass", body.Mass)
	ship:SetAttribute("BodyCenterOfMassX", body.CenterOfMass.X)
	ship:SetAttribute("BodyCenterOfMassZ", body.CenterOfMass.Y)
	ship:SetAttribute("BodyMomentOfInertia", body.MomentOfInertia)
	ship:SetAttribute("BodyBoundingRadius", body.BoundingRadius)
	return body
end

function StructuralAuthority.BuildGraph(ship: Model): any
	assert(ship and ship:IsA("Model"), "StructuralAuthority.BuildGraph expects a ship Model")
	return ShipSocketGraph.new(ship)
end

function StructuralAuthority.BindShip(ship: Model)
	ComponentAuthority.BindShip(ship)
	local graph = StructuralAuthority.BuildGraph(ship)
	recomputeShipBody(ship)
	return graph
end

function StructuralAuthority.AttachComponent(ship: Model, part: BasePart, componentType: string, maxSnapDistance: number?): (any?, string?)
	if not ship or not ship.Parent or not part or not part.Parent then
		return nil, "invalid input"
	end
	if not Components.Types[componentType] or not Components.Connections[componentType] then
		return nil, "unknown component definition"
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
	recomputeShipBody(ship)
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

	local sourceBody = createSourceRigidBody(ship)
	disconnectExternalWelds(parts)

	local debrisAssembly = Instance.new("Model")
	debrisAssembly.Name = "DebrisAssembly"
	debrisAssembly:SetAttribute("IsDebris", true)
	debrisAssembly:SetAttribute("DetachReason", reason or "StructuralDamage")
	debrisAssembly:SetAttribute("SourceShipId", ship:GetAttribute("ShipId") or ship.Name)
	debrisAssembly.Parent = getDebrisFolder()

	for _, detachedPart in ipairs(parts) do
		detachedPart:SetAttribute("IsDebris", true)
		detachedPart:SetAttribute("ComponentDetached", true)
		detachedPart:SetAttribute("ComponentType", detachedPart:GetAttribute("ComponentType"))
		ComponentAuthority.SetParent(detachedPart, nil)
		detachedPart.Parent = debrisAssembly
	end

	debrisAssembly.PrimaryPart = parts[1]

	local inheritedVelocity = Vector3.zero
	local inheritedAngularVelocity = Vector3.zero
	if sourceBody then
		local rootNode = graph.Nodes[graph.RootNodeId]
		if rootNode and rootNode.Part then
			local localOrigin = rootNode.Part.CFrame:PointToObjectSpace(part.Position)
			local pointVelocity = sourceBody:GetWorldPointVelocity(Vector2.new(localOrigin.X, localOrigin.Z))
			inheritedVelocity = Vector3.new(pointVelocity.X, 0, pointVelocity.Y)
			inheritedAngularVelocity = Vector3.new(0, sourceBody.AngularVelocity, 0)
		end
	end

	for _, detachedPart in ipairs(parts) do
		detachedPart.Anchored = false
		detachedPart.AssemblyLinearVelocity = inheritedVelocity
		detachedPart.AssemblyAngularVelocity = inheritedAngularVelocity
	end

	for _, detachedPart in ipairs(parts) do
		ComponentAuthority.Clear(detachedPart)
	end
	recomputeShipBody(ship)

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

	recomputeShipBody(ship)
	return detached
end

function StructuralAuthority.ReplaceComponent(ship: Model, oldPart: BasePart, newPart: BasePart, componentType: string, maxSnapDistance: number?): (Model?, boolean)
	if not ship or not oldPart or not newPart or oldPart == newPart then
		return nil, false
	end
	if not oldPart:IsDescendantOf(ship) or not newPart.Parent then
		return nil, false
	end
	if not Components.Types[componentType] or not Components.Connections[componentType] then
		return nil, false
	end

	-- Transaction phase: derive the exact occupied hardpoint and replacement
	-- socket before mutating the live graph. No detach/debris operation occurs
	-- until every validation below has succeeded.
	local graph = StructuralAuthority.BuildGraph(ship)
	local oldNodeId = oldPart:GetAttribute("NodeId")
	local oldNode = oldNodeId and graph.Nodes[oldNodeId]
	if not oldNode or oldNode.IsCore then
		return nil, false
	end
	if not oldNode.ParentNodeId or not oldNode.ParentSocketId then
		return nil, false
	end

	local parentNode = graph.Nodes[oldNode.ParentNodeId]
	local parentSocket = parentNode and parentNode.Sockets[oldNode.ParentSocketId]
	if not parentNode or not parentSocket or not parentSocket.IsOccupied then
		return nil, false
	end

	local childSockets = graph:ExtractComponentSockets(componentType)
	local replacementSocketId = getCompatibleOutSocket(graph, parentNode, parentSocket, newPart, componentType)
	if not replacementSocketId then
		return nil, false
	end
	local replacementSocket = childSockets[replacementSocketId]
	if not replacementSocket then
		return nil, false
	end

	local targetSocketPosition = parentNode.Part.CFrame:PointToWorldSpace(parentSocket.LocalOffset)
	local targetRotation = parentNode.Part.CFrame - parentNode.Part.CFrame.Position
	local candidateCFrame = CFrame.new(targetSocketPosition) * targetRotation * CFrame.new(-replacementSocket.LocalOffset)
	if maxSnapDistance and (candidateCFrame.Position - oldPart.Position).Magnitude > maxSnapDistance then
		return nil, false
	end

	-- Snapshot all live state that the commit may touch. This makes failure a
	-- true rollback rather than a best-effort reconstruction of the old part.
	local oldParent = oldPart.Parent
	local oldCFrame = oldPart.CFrame
	local newParent = newPart.Parent
	local newCFrame = newPart.CFrame
	local oldAttrs = {
		NodeId = oldPart:GetAttribute("NodeId"),
		ComponentType = oldPart:GetAttribute("ComponentType"),
		ParentNodeId = oldPart:GetAttribute("ParentNodeId"),
		ParentSocketId = oldPart:GetAttribute("ParentSocketId"),
		ConnectedSocketId = oldPart:GetAttribute("ConnectedSocketId"),
		IsDebris = oldPart:GetAttribute("IsDebris"),
		ComponentDetached = oldPart:GetAttribute("ComponentDetached"),
	}
	local newAttrs = {
		NodeId = newPart:GetAttribute("NodeId"),
		ComponentType = newPart:GetAttribute("ComponentType"),
		ParentNodeId = newPart:GetAttribute("ParentNodeId"),
		ParentSocketId = newPart:GetAttribute("ParentSocketId"),
		ConnectedSocketId = newPart:GetAttribute("ConnectedSocketId"),
		IsDebris = newPart:GetAttribute("IsDebris"),
		ComponentDetached = newPart:GetAttribute("ComponentDetached"),
	}

	local function restoreAttributes(part: BasePart, attrs: { [string]: any })
		for name, value in pairs(attrs) do
			part:SetAttribute(name, value)
		end
	end

	-- Commit phase. The new component is installed at the same authoritative
	-- parent hardpoint first; only after that succeeds is the old component
	-- removed. The graph therefore never has an intermediate empty hardpoint.
	local oldDetached: Model? = nil
	local committed = false
	local ok = pcall(function()
		newPart.CFrame = candidateCFrame
		newPart.Parent = ship

		local replacementGraph = StructuralAuthority.BuildGraph(ship)
		local replacementParent = replacementGraph.Nodes[oldNode.ParentNodeId :: string]
		local replacementParentSocket = replacementParent and replacementParent.Sockets[oldNode.ParentSocketId :: string]
		if not replacementParent or not replacementParentSocket or not replacementParentSocket.IsOccupied then
			error("replacement hardpoint changed during commit")
		end

		-- The temporary graph still contains the old edge. Reserve the same
		-- authoritative hardpoint for the replacement without touching the live
		-- model yet; the old edge remains live until DetachComponent succeeds.
		replacementParentSocket.IsOccupied = false
		replacementParentSocket.ConnectedNodeId = nil
		replacementParentSocket.ConnectedSocketId = nil

		local existingNewNodeId = newPart:GetAttribute("NodeId")
		if typeof(existingNewNodeId) == "string" and replacementGraph.Nodes[existingNewNodeId] then
			error("replacement component already belongs to graph")
		end

		newPart:SetAttribute("NodeId", "replacement_" .. tostring(newPart:GetDebugId(1)))
		local childNode = replacementGraph:AttachComponent(replacementParent, replacementParentSocket, newPart, componentType)
		if not childNode then
			error("replacement graph attach failed")
		end
		ComponentAuthority.Bind(newPart, componentType)
		ComponentAuthority.SetParent(newPart, replacementParent.Part)

		-- Now detach the old subtree. This is the only destructive operation and
		-- it occurs after the replacement graph edge is valid.
		oldDetached = StructuralAuthority.DetachComponent(ship, oldPart, "Replacement")
		if not oldDetached then
			error("old component detach failed")
		end

		committed = true
	end)

	if not ok or not committed then
		-- Roll back both instances and their authoritative attributes. If a
		-- partial debris model was created, restore its parts to their original
		-- parent before deleting the temporary container.
		if oldDetached then
			for _, descendant in ipairs(oldDetached:GetDescendants()) do
				if descendant:IsA("BasePart") then
					descendant.Parent = ship
				end
			end
			oldDetached:Destroy()
		end
		oldPart.Parent = oldParent
		oldPart.CFrame = oldCFrame
		restoreAttributes(oldPart, oldAttrs)
		newPart.Parent = newParent
		newPart.CFrame = newCFrame
		restoreAttributes(newPart, newAttrs)
		ComponentAuthority.Bind(oldPart, oldAttrs.ComponentType)
		recomputeShipBody(ship)
		return nil, false
	end

	recomputeShipBody(ship)
	return oldDetached, true
end

return StructuralAuthority
