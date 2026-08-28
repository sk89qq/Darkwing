--[=[
	ShipSocketGraph: authoritative hardpoint topology solver.

	Authority rules:
	- Component definitions come only from VoidHunterComponents.Connections.
	- ComponentType must be explicitly present on every graph component.
	- Unknown component types fail closed; no invented generic sockets.
	- Explicit ParentNodeId / ParentSocketId metadata is authoritative.
	- Weld/proximity reconstruction is not part of the runtime graph rebuild path.
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

local function getAuthoritativeSocketDirection(localOffset: Vector3, socketType: "InConnect" | "OutConnect"): Vector3?
	-- Connection coordinates are the authoritative hardpoint data. Do not
	-- synthesize direction from names (Front/Back/Hex/etc.); when a hardpoint
	-- is non-zero its outward/inward normal is derived from the actual local
	-- hardpoint vector. Zero-length hardpoints have no recoverable direction
	-- and therefore fail closed.
	local magnitude = localOffset.Magnitude
	if magnitude <= 0 then
		return nil
	end

	local outward = localOffset / magnitude
	if socketType == "InConnect" then
		return -outward
	end
	return outward
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
				local direction = getAuthoritativeSocketDirection(offset, "InConnect")
				if direction then
					sockets[socketId] = makeSocket(socketId, "InConnect", offset, direction)
				end
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
			local direction = getAuthoritativeSocketDirection(offset, "OutConnect")
			if direction then
				sockets[socketId] = makeSocket(socketId, "OutConnect", offset, direction)
			end
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

	for nodeId, node in pairs(self.Nodes) do
		if nodeId ~= self.RootNodeId then
			applyRelationshipMetadata(self, node)
		end
	end
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
					if otherNode.Part and (otherNode.Part.Position - finalPartCFrame.Position).Magnitude < 0.1 then
						overlapsExisting = true
						break
					end
				end
				if overlapsExisting then
					continue
				end

				bestCandidate = {
					ParentNode = parentNode,
					ParentSocket = parentSocket,
					TargetCFrame = finalPartCFrame,
					Distance = distance,
					ChildSocketName = outPlugName,
				}
				closestDistance = distance
			end
		end
	end

	return bestCandidate
end

function ShipSocketGraph:AttachComponent(parentNode: GraphNode, parentSocket: SocketInfo, childPart: BasePart, compTypeName: string): GraphNode?
	if not parentNode or not parentSocket or parentSocket.IsOccupied then
		return nil
	end
	if not childPart or not childPart.Parent then
		return nil
	end
	if not Components.Types[compTypeName] or not Components.Connections[compTypeName] then
		return nil
	end

	local childSockets = self:ExtractComponentSockets(compTypeName)
	local childSocket: SocketInfo? = nil
	for _, socket in pairs(childSockets) do
		if socket.Type == "OutConnect" then
			childSocket = socket
			break
		end
	end
	if not childSocket then
		return nil
	end

	local nodeId = getOrCreateNodeId(childPart)
	if self.Nodes[nodeId] then
		return nil
	end

	local childNode: GraphNode = {
		Id = nodeId,
		Part = childPart,
		ComponentType = compTypeName,
		IsCore = false,
		LocalCFrame = self.RootNodeId and self.Nodes[self.RootNodeId].Part.CFrame:ToObjectSpace(childPart.CFrame) or CFrame.identity,
		Sockets = childSockets,
		ParentNodeId = parentNode.Id,
		ParentSocketId = parentSocket.Id,
		ChildNodes = {},
	}

	parentSocket.IsOccupied = true
	parentSocket.ConnectedNodeId = childNode.Id
	parentSocket.ConnectedSocketId = childSocket.Id
	childSocket.IsOccupied = true
	childSocket.ConnectedNodeId = parentNode.Id
	childSocket.ConnectedSocketId = parentSocket.Id
	parentNode.ChildNodes[parentSocket.Id] = childNode.Id

	childPart:SetAttribute("NodeId", childNode.Id)
	childPart:SetAttribute("ParentNodeId", parentNode.Id)
	childPart:SetAttribute("ParentSocketId", parentSocket.Id)
	childPart:SetAttribute("ConnectedSocketId", childSocket.Id)

	self.Nodes[nodeId] = childNode
	return childNode
end

function ShipSocketGraph:DetachComponent(nodeId: string): boolean
	local node = self.Nodes[nodeId]
	if not node or node.IsCore then
		return false
	end

	if node.ParentNodeId and node.ParentSocketId then
		local parentNode = self.Nodes[node.ParentNodeId]
		if parentNode then
			local parentSocket = parentNode.Sockets[node.ParentSocketId]
			if parentSocket then
				parentSocket.IsOccupied = false
				parentSocket.ConnectedNodeId = nil
				parentSocket.ConnectedSocketId = nil
			end
			parentNode.ChildNodes[node.ParentSocketId] = nil
		end
	end

	self.Nodes[nodeId] = nil
	if node.Part then
		node.Part:SetAttribute("ParentNodeId", nil)
		node.Part:SetAttribute("ParentSocketId", nil)
		node.Part:SetAttribute("ConnectedSocketId", nil)
	end
	return true
end

return ShipSocketGraph
