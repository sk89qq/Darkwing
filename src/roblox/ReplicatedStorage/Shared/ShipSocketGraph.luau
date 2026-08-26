--[=[
	ShipSocketGraph: authoritative hardpoint topology solver.

	Authority rules:
	- Component definitions come only from VoidHunterComponents.Connections.
	- ComponentType must be explicitly present on every graph component.
	- Unknown component types fail closed; no invented generic sockets.
	- Explicit ParentNodeId / ParentSocketId metadata is authoritative.
	- Weld/proximity reconstruction is a legacy import adapter only.
	- Roblox WeldConstraints are physical projection, not topology authority.
]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Components = require(ReplicatedStorage:WaitForChild("VoidHunterComponents"))

local ShipSocketGraph = {}
ShipSocketGraph.__index = ShipSocketGraph

export type SocketInfo = {
	Id: string,
	Type: "InConnect" | "OutConnect",
	LocalOffset: Vector3,
	LocalDirection: Vector3,
	IsOccupied: boolean,
	ConnectedNodeId: string?,
	ConnectedSocketId: string?,
}

export type GraphNode = {
	Id: string,
	Part: BasePart,
	ComponentType: string,
	IsCore: boolean,
	LocalCFrame: CFrame,
	Sockets: { [string]: SocketInfo },
	ParentNodeId: string?,
	ParentSocketId: string?,
	ChildNodes: { [string]: string },
}

export type SnapCandidate = {
	ParentNode: GraphNode,
	ParentSocket: SocketInfo,
	TargetCFrame: CFrame,
	Distance: number,
	ChildSocketName: string,
}

local function getSocketNormal(offsetName: string): Vector3
	if string.find(offsetName, "Front", 1, true) then
		return Vector3.new(0, 0, 1)
	elseif string.find(offsetName, "Back", 1, true) then
		return Vector3.new(0, 0, -1)
	elseif string.find(offsetName, "Left", 1, true) then
		return Vector3.new(-1, 0, 0)
	elseif string.find(offsetName, "Right", 1, true) then
		return Vector3.new(1, 0, 0)
	elseif string.find(offsetName, "Hex1", 1, true) then
		return Vector3.new(1, 0, 0)
	elseif string.find(offsetName, "Hex2", 1, true) then
		return Vector3.new(0.5, 0, 0.866)
	elseif string.find(offsetName, "Hex3", 1, true) then
		return Vector3.new(-0.5, 0, 0.866)
	elseif string.find(offsetName, "Hex4", 1, true) then
		return Vector3.new(-1, 0, 0)
	elseif string.find(offsetName, "Hex5", 1, true) then
		return Vector3.new(-0.5, 0, -0.866)
	elseif string.find(offsetName, "Hex", 1, true) then
		return Vector3.new(0.5, 0, -0.866)
	end
	return Vector3.new(0, 0, 1)
end

local function makeSocket(id: string, socketType: "InConnect" | "OutConnect", localOffset: Vector3, localDirection: Vector3): SocketInfo
	return {
		Id = id,
		Type = socketType,
		LocalOffset = localOffset,
		LocalDirection = localDirection,
		IsOccupied = false,
		ConnectedNodeId = nil,
		ConnectedSocketId = nil,
	}
end

function ShipSocketGraph.new(shipModel: Model?)
	local self = setmetatable({}, ShipSocketGraph)
	self.ShipModel = shipModel
	self.Nodes = {} :: { [string]: GraphNode }
	self.RootNodeId = nil :: string?
	self.GridUnit = Components.UNIT or 7

	if shipModel then
		self:RebuildFromModel(shipModel)
	end

	return self
end

function ShipSocketGraph:ExtractComponentSockets(compTypeName: string): { [string]: SocketInfo }
	local connectionDefinition = Components.Connections[compTypeName]
	if not connectionDefinition then
		return {}
	end

	local offsets = Components.AttachmentOffsets
	local sockets: { [string]: SocketInfo } = {}

	if connectionDefinition.InConnectPositions then
		for index, positionName in ipairs(connectionDefinition.InConnectPositions) do
			local socketId = "InConnect_" .. tostring(index) .. "_" .. positionName
			local offset = offsets[positionName]
			if connectionDefinition.MeshAttachmentPositions then
				offset = connectionDefinition.MeshAttachmentPositions["InConnect_" .. tostring(index)] or offset
			end
			if offset then
				sockets[socketId] = makeSocket(socketId, "InConnect", offset, getSocketNormal(positionName))
			end
		end
	end

	if connectionDefinition.OutConnectPosition then
		local positionName = connectionDefinition.OutConnectPosition
		local socketId = "OutConnect_" .. positionName
		local offset = offsets[positionName]
		if connectionDefinition.MeshAttachmentPositions then
			offset = connectionDefinition.MeshAttachmentPositions.OutConnect or offset
		end
		if offset then
			sockets[socketId] = makeSocket(socketId, "OutConnect", offset, -getSocketNormal(positionName))
		end
	end

	return sockets
end

local function getExplicitComponentType(part: BasePart): string?
	local componentType = part:GetAttribute("ComponentType")
	if typeof(componentType) ~= "string" or componentType == "" then
		return nil
	end
	if not Components.Types[componentType] or not Components.Connections[componentType] then
		return nil
	end
	return componentType
end

local function getOrCreateNodeId(part: BasePart): string
	local nodeId = part:GetAttribute("NodeId")
	if typeof(nodeId) == "string" and nodeId ~= "" then
		return nodeId
	end
	local generated = "node_" .. tostring(part:GetDebugId(1))
	part:SetAttribute("NodeId", generated)
	return generated
end

local function applyRelationshipMetadata(graph: any, node: GraphNode): boolean
	local parentNodeId = node.Part:GetAttribute("ParentNodeId")
	local parentSocketId = node.Part:GetAttribute("ParentSocketId")
	if typeof(parentNodeId) ~= "string" or typeof(parentSocketId) ~= "string" then
		return false
	end

	local parentNode = graph.Nodes[parentNodeId]
	local parentSocket = parentNode and parentNode.Sockets[parentSocketId]
	if not parentNode or not parentSocket or parentSocket.Type ~= "InConnect" then
		return false
	end
	if parentSocket.IsOccupied then
		return false
	end

	local childSocketId = node.Part:GetAttribute("ConnectedSocketId")
	local childSocket = node.Sockets[typeof(childSocketId) == "string" and childSocketId or ""]
	if not childSocket then
		for _, candidate in pairs(node.Sockets) do
			if candidate.Type == "OutConnect" then
				childSocket = candidate
				break
			end
		end
	end
	if not childSocket or childSocket.Type ~= "OutConnect" then
		return false
	end

	parentSocket.IsOccupied = true
	parentSocket.ConnectedNodeId = node.Id
	parentSocket.ConnectedSocketId = childSocket.Id
	childSocket.IsOccupied = true
	childSocket.ConnectedNodeId = parentNode.Id
	childSocket.ConnectedSocketId = parentSocket.Id

	parentNode.ChildNodes[parentSocket.Id] = node.Id
	node.ParentNodeId = parentNode.Id
	node.ParentSocketId = parentSocket.Id
	return true
end

function ShipSocketGraph:RebuildFromModel(shipModel: Model)
	self.ShipModel = shipModel
	self.Nodes = {}
	self.RootNodeId = nil

	local corePart: BasePart? = nil
	for _, descendant in ipairs(shipModel:GetDescendants()) do
		if descendant:IsA("BasePart") and not descendant:GetAttribute("IsDebris") then
			if descendant:GetAttribute("IsCore") == true then
				local componentType = getExplicitComponentType(descendant)
				if componentType then
					corePart = descendant
					break
				end
			end
		end
	end

	if not corePart then
		local primaryPart = shipModel.PrimaryPart
		if primaryPart and primaryPart:IsA("BasePart") and primaryPart:GetAttribute("IsCore") == true and getExplicitComponentType(primaryPart) then
			corePart = primaryPart
		end
	end

	if not corePart then
		return
	end

	shipModel.PrimaryPart = corePart

	local rootType = getExplicitComponentType(corePart)
	if not rootType then
		return
	end

	local rootId = getOrCreateNodeId(corePart)
	local rootNode: GraphNode = {
		Id = rootId,
		Part = corePart,
		ComponentType = rootType,
		IsCore = true,
		LocalCFrame = CFrame.identity,
		Sockets = self:ExtractComponentSockets(rootType),
		ParentNodeId = nil,
		ParentSocketId = nil,
		ChildNodes = {},
	}
	self.Nodes[rootId] = rootNode
	self.RootNodeId = rootId

	local rootCFrame = corePart.CFrame
	for _, part in ipairs(shipModel:GetDescendants()) do
		if part:IsA("BasePart") and part ~= corePart and not part:GetAttribute("IsDebris") then
			local componentType = getExplicitComponentType(part)
			if componentType then
				local nodeId = getOrCreateNodeId(part)
				self.Nodes[nodeId] = {
					Id = nodeId,
					Part = part,
					ComponentType = componentType,
					IsCore = false,
					LocalCFrame = rootCFrame:ToObjectSpace(part.CFrame),
					Sockets = self:ExtractComponentSockets(componentType),
					ParentNodeId = nil,
					ParentSocketId = nil,
					ChildNodes = {},
				}
			end
		end
	end

	local explicitLinkedNodes: { [string]: boolean } = {}
	for nodeId, node in pairs(self.Nodes) do
		if nodeId ~= self.RootNodeId and applyRelationshipMetadata(self, node) then
			explicitLinkedNodes[nodeId] = true
		end
	end

	-- Legacy physical migration adapter: only consider existing welds for nodes
	-- that have no explicit relationship metadata. The weld never invents a new
	-- component or socket; it can only confirm an unambiguous existing pair.
	for nodeId, node in pairs(self.Nodes) do
		if nodeId ~= self.RootNodeId and not explicitLinkedNodes[nodeId] then
			self:ResolveLegacyWeldEvidence(node)
		end
	end
end

function ShipSocketGraph:ResolveLegacyWeldEvidence(node: GraphNode)
	local part = node.Part
	if not part then
		return
	end

	for _, child in ipairs(part:GetChildren()) do
		if not child:IsA("WeldConstraint") then
			continue
		end
		local otherPart = nil
		if child.Part0 == part then
			otherPart = child.Part1
		elseif child.Part1 == part then
			otherPart = child.Part0
		end
		if not otherPart or not otherPart:IsDescendantOf(self.ShipModel) then
			continue
		end
		local otherNodeId = otherPart:GetAttribute("NodeId")
		if typeof(otherNodeId) ~= "string" then
			continue
		end
		local otherNode = self.Nodes[otherNodeId]
		if not otherNode then
			continue
		end
		self:PairSocketsByProximity(node, otherNode)
		break
	end
end

function ShipSocketGraph:PairSocketsByProximity(nodeA: GraphNode, nodeB: GraphNode): boolean
	if not nodeA or not nodeB or nodeA == nodeB then
		return false
	end
	local partA = nodeA.Part
	local partB = nodeB.Part
	if not partA or not partB then
		return false
	end

	local bestDistance = 3.0
	local bestSocketA: SocketInfo? = nil
	local bestSocketB: SocketInfo? = nil

	for _, socketA in pairs(nodeA.Sockets) do
		if socketA.IsOccupied then
			continue
		end
		local worldA = partA.CFrame:PointToWorldSpace(socketA.LocalOffset)
		for _, socketB in pairs(nodeB.Sockets) do
			if socketB.IsOccupied or socketA.Type == socketB.Type then
				continue
			end
			local worldB = partB.CFrame:PointToWorldSpace(socketB.LocalOffset)
			local distance = (worldA - worldB).Magnitude
			if distance < bestDistance then
				bestDistance = distance
				bestSocketA = socketA
				bestSocketB = socketB
			end
		end
	end

	if not bestSocketA or not bestSocketB then
		return false
	end

	bestSocketA.IsOccupied = true
	bestSocketA.ConnectedNodeId = nodeB.Id
	bestSocketA.ConnectedSocketId = bestSocketB.Id
	bestSocketB.IsOccupied = true
	bestSocketB.ConnectedNodeId = nodeA.Id
	bestSocketB.ConnectedSocketId = bestSocketA.Id

	if bestSocketA.Type == "InConnect" and bestSocketB.Type == "OutConnect" then
		nodeA.ChildNodes[bestSocketA.Id] = nodeB.Id
		nodeB.ParentNodeId = nodeA.Id
		nodeB.ParentSocketId = bestSocketA.Id
	elseif bestSocketB.Type == "InConnect" and bestSocketA.Type == "OutConnect" then
		nodeB.ChildNodes[bestSocketB.Id] = nodeA.Id
		nodeA.ParentNodeId = nodeB.Id
		nodeA.ParentSocketId = bestSocketB.Id
	else
		return false
	end

	return true
end

function ShipSocketGraph:FindBestSnap(heldPart: BasePart, compTypeName: string, maxSnapDist: number?): SnapCandidate?
	if not heldPart or not heldPart.Parent then
		return nil
	end
	if not Components.Types[compTypeName] or not Components.Connections[compTypeName] then
		return nil
	end

	local snapRadius = maxSnapDist or Components.SNAP_DISTANCE or 6.0
	local heldSockets = self:ExtractComponentSockets(compTypeName)
	local outPlugName: string? = nil
	local outPlug: SocketInfo? = nil

	for socketName, socketData in pairs(heldSockets) do
		if socketData.Type == "OutConnect" then
			outPlugName = socketName
			outPlug = socketData
			break
		end
	end
	if not outPlug or not outPlugName then
		return nil
	end

	local bestCandidate: SnapCandidate? = nil
	local closestDistance = snapRadius

	for _, parentNode in pairs(self.Nodes) do
		if parentNode.Part and parentNode.Part:IsDescendantOf(Workspace) then
			for _, parentSocket in pairs(parentNode.Sockets) do
				if parentSocket.IsOccupied or parentSocket.Type ~= "InConnect" then
					continue
				end
				local socketPosition = parentNode.Part.CFrame:PointToWorldSpace(parentSocket.LocalOffset)
				local distance = (heldPart.Position - socketPosition).Magnitude
				if distance >= closestDistance then
					continue
				end

				local targetRotation = parentNode.Part.CFrame - parentNode.Part.CFrame.Position
				local targetSocketCFrame = CFrame.new(socketPosition) * targetRotation
				local finalPartCFrame = targetSocketCFrame * CFrame.new(-outPlug.LocalOffset)

				local overlapsExisting = false
				for _, otherNode in pairs(self.Nodes) do
					if otherNode.Part and (otherNode.Part.Position - finalPartCFrame.Position).Magnitude < 3.0 then
						overlapsExisting = true
						break
					end
				end
				if not overlapsExisting then
					closestDistance = distance
					bestCandidate = {
						ParentNode = parentNode,
						ParentSocket = parentSocket,
						TargetCFrame = finalPartCFrame,
						Distance = distance,
						ChildSocketName = outPlugName,
					}
				end
			end
		end
	end

	return bestCandidate
end

function ShipSocketGraph:AttachComponent(parentNode: GraphNode, parentSocket: SocketInfo, childPart: BasePart, compTypeName: string): GraphNode?
	if not parentNode or not parentNode.Part or not parentSocket or not childPart then
		return nil
	end
	if parentSocket.Type ~= "InConnect" or parentSocket.IsOccupied then
		return nil
	end
	if not Components.Types[compTypeName] or not Components.Connections[compTypeName] then
		return nil
	end
	if childPart:IsDescendantOf(self.ShipModel) and childPart:GetAttribute("NodeId") then
		return nil
	end

	local childNodeId = "node_" .. tostring(childPart:GetDebugId(1))
	childPart:SetAttribute("NodeId", childNodeId)
	childPart:SetAttribute("ComponentType", compTypeName)
	childPart:SetAttribute("ParentNodeId", parentNode.Id)
	childPart:SetAttribute("ParentSocketId", parentSocket.Id)
	childPart:SetAttribute("IsDebris", nil)

	local childSockets = self:ExtractComponentSockets(compTypeName)
	local childNode: GraphNode = {
		Id = childNodeId,
		Part = childPart,
		ComponentType = compTypeName,
		IsCore = false,
		LocalCFrame = parentNode.Part.CFrame:ToObjectSpace(childPart.CFrame),
		Sockets = childSockets,
		ParentNodeId = parentNode.Id,
		ParentSocketId = parentSocket.Id,
		ChildNodes = {},
	}

	local childSocket: SocketInfo? = nil
	for _, socket in pairs(childSockets) do
		if socket.Type == "OutConnect" then
			childSocket = socket
			break
		end
	end
	if not childSocket then
		childPart:SetAttribute("NodeId", nil)
		childPart:SetAttribute("ParentNodeId", nil)
		childPart:SetAttribute("ParentSocketId", nil)
		return nil
	end

	parentSocket.IsOccupied = true
	parentSocket.ConnectedNodeId = childNodeId
	parentSocket.ConnectedSocketId = childSocket.Id
	childSocket.IsOccupied = true
	childSocket.ConnectedNodeId = parentNode.Id
	childSocket.ConnectedSocketId = parentSocket.Id
	childPart:SetAttribute("ConnectedSocketId", childSocket.Id)
	parentNode.ChildNodes[parentSocket.Id] = childNodeId

	childPart.Anchored = false
	childPart.CanCollide = true
	childPart.Parent = self.ShipModel

	local weld = Instance.new("WeldConstraint")
	weld.Name = "SocketWeld_" .. compTypeName
	weld.Part0 = parentNode.Part
	weld.Part1 = childPart
	weld.Parent = childPart

	self.Nodes[childNodeId] = childNode
	return childNode
end

function ShipSocketGraph:ValidateReachability(): { Reachable: { [string]: GraphNode }, Severed: { [string]: GraphNode } }
	local reachable: { [string]: GraphNode } = {}
	local severed: { [string]: GraphNode } = {}
	if not self.RootNodeId or not self.Nodes[self.RootNodeId] then
		for id, node in pairs(self.Nodes) do
			severed[id] = node
		end
		return { Reachable = reachable, Severed = severed }
	end

	local queue: { string } = { self.RootNodeId }
	local head = 1
	reachable[self.RootNodeId] = self.Nodes[self.RootNodeId]

	while head <= #queue do
		local currentId = queue[head]
		head += 1
		local currentNode = self.Nodes[currentId]
		if currentNode then
			for _, socket in pairs(currentNode.Sockets) do
				local neighborId = socket.ConnectedNodeId
				if socket.IsOccupied and neighborId and self.Nodes[neighborId] and not reachable[neighborId] then
					reachable[neighborId] = self.Nodes[neighborId]
					queue[#queue + 1] = neighborId
				end
			end
		end
	end

	for id, node in pairs(self.Nodes) do
		if not reachable[id] then
			severed[id] = node
		end
	end
	return { Reachable = reachable, Severed = severed }
end

function ShipSocketGraph:SeverUnreachableComponents(debrisFolder: Instance?): { BasePart }
	local result = self:ValidateReachability()
	local severedParts: { BasePart } = {}
	local targetParent = debrisFolder or Workspace

	for nodeId, node in pairs(result.Severed) do
		local part = node.Part
		if part and part.Parent then
			for _, descendant in ipairs(part:GetDescendants()) do
				if descendant:IsA("WeldConstraint") then
					descendant:Destroy()
				end
			end
			part:SetAttribute("IsDebris", true)
			part:SetAttribute("NodeId", nil)
			part:SetAttribute("ParentNodeId", nil)
			part:SetAttribute("ParentSocketId", nil)
			part.Parent = targetParent
			part.Anchored = false
			part.CanCollide = true

			local origin = self.ShipModel and self.ShipModel:GetPivot().Position or part.Position
			local delta = part.Position - origin
			local outward = delta.Magnitude > 0.001 and delta.Unit or Vector3.new(1, 0, 0)
			part.AssemblyLinearVelocity = Vector3.new(outward.X * 15, 0, outward.Z * 15)
			part.AssemblyAngularVelocity = Vector3.new(0, math.random(-5, 5), 0)
			severedParts[#severedParts + 1] = part
		end
		self.Nodes[nodeId] = nil
	end

	return severedParts
end

function ShipSocketGraph:Serialize(): any
	local rootNode = self.RootNodeId and self.Nodes[self.RootNodeId]
	local rootCFrame = rootNode and rootNode.Part and rootNode.Part.CFrame or CFrame.identity
	local blueprint = {
		RootType = rootNode and rootNode.ComponentType or nil,
		Pieces = {},
	}

	if not blueprint.RootType then
		return blueprint
	end

	for id, node in pairs(self.Nodes) do
		if node.Part then
			local relative = rootCFrame:ToObjectSpace(node.Part.CFrame)
			local rx, ry, rz = relative:ToEulerAnglesYXZ()
			blueprint.Pieces[#blueprint.Pieces + 1] = {
				Id = id,
				Type = node.ComponentType,
				IsCore = node.IsCore,
				Position = { X = relative.Position.X, Y = relative.Position.Y, Z = relative.Position.Z },
				Rotation = { X = rx, Y = ry, Z = rz },
				ParentNodeId = node.ParentNodeId,
				ParentSocketId = node.ParentSocketId,
			}
		end
	end

	return blueprint
end

return ShipSocketGraph
