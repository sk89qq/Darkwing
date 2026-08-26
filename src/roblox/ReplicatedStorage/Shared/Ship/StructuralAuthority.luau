--[=[
	StructuralAuthority
	Canonical ship graph mutation boundary.

	ShipSocketGraph remains the socket/geometry solver. This service is the only
	runtime boundary intended to perform structural attach, detach, replacement,
	and severance.

	Physics boundary:
	- Logical graph mutation remains authoritative.
	- Detached assemblies inherit rigid-body point kinematics from the source ship.
	- No arbitrary detachment impulse is introduced here.
	- Native debris launch terms remain a separate forensic mapping until their
	  source constants and call context are completely recovered.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Components = require(ReplicatedStorage:WaitForChild("VoidHunterComponents"))
local ShipSocketGraph = require(ReplicatedStorage.Shared:WaitForChild("ShipSocketGraph"))
local ComponentAuthority = require(ReplicatedStorage.Shared.Combat:WaitForChild("ComponentAuthority"))
local RigidBody2D = require(ReplicatedStorage.Shared.Physics:WaitForChild("RigidBody2D"))

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
	return body
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
	if not oldPart:IsDescendantOf(ship) or not newPart.Parent then
		return nil, false
	end
	if not Components.Types[componentType] or not Components.Connections[componentType] then
		return nil, false
	end

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
	if not parentNode or not parentSocket then
		return nil, false
	end

	local childSocketId = getCompatibleOutSocket(graph, parentNode, parentSocket, oldPart, componentType)
	if not childSocketId then
		return nil, false
	end

	local childSockets = graph:ExtractComponentSockets(componentType)
	local childSocket = childSockets[childSocketId]
	if not childSocket then
		return nil, false
	end

	local oldParentId = oldNode.ParentNodeId
	local oldParentSocketId = oldNode.ParentSocketId
	local oldCFrame = oldPart.CFrame
	local oldAttributes = {
		NodeId = oldPart:GetAttribute("NodeId"),
		ComponentType = oldPart:GetAttribute("ComponentType"),
		IsDebris = oldPart:GetAttribute("IsDebris"),
		ComponentDetached = oldPart:GetAttribute("ComponentDetached"),
	}

	local detached = StructuralAuthority.DetachComponent(ship, oldPart, "Replacement")
	if not detached then
		return nil, false
	end

	local replacementGraph = StructuralAuthority.BuildGraph(ship)
	local replacementParent = replacementGraph.Nodes[oldParentId]
	local replacementSocket = replacementParent and replacementParent.Sockets[oldParentSocketId]
	if not replacementParent or not replacementSocket or replacementSocket.IsOccupied then
		local restoredRoot = detached.PrimaryPart or detached:FindFirstChildWhichIsA("BasePart", true)
		if restoredRoot then
			detached.Parent = ship
			restoredRoot.CFrame = oldCFrame
			for attributeName, attributeValue in pairs(oldAttributes) do
				restoredRoot:SetAttribute(attributeName, attributeValue)
			end
		end
		return detached, false
	end

	alignPartToSocket(replacementParent, replacementSocket, newPart, childSocket.LocalOffset)
	local childNode = replacementGraph:AttachComponent(replacementParent, replacementSocket, newPart, componentType)
	if childNode then
		ComponentAuthority.Bind(newPart, componentType)
		ComponentAuthority.SetParent(newPart, replacementParent.Part)
		return detached, true
	end

	if newPart.Parent == ship then
		newPart.Parent = nil
	end

	local restoredRoot = detached.PrimaryPart or detached:FindFirstChildWhichIsA("BasePart", true)
	if restoredRoot then
		detached.Parent = ship
		restoredRoot.CFrame = oldCFrame
		for attributeName, attributeValue in pairs(oldAttributes) do
			restoredRoot:SetAttribute(attributeName, attributeValue)
		end
		ComponentAuthority.Bind(restoredRoot, oldAttributes.ComponentType :: string?)
	end

	return detached, false
end

return StructuralAuthority
