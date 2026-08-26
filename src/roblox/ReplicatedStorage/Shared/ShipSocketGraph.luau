--[[
	ShipSocketGraph: Core Socket Graph & Assembly Topology Engine.
	Sourced from AlterOrb / FunOrb Ship Assembly Decompile & Tuned for Roblox.
	
	Manages:
	  - InConnect (Sockets) and OutConnect (Plugs) matching
	  - 7-stud standard grid and hexagonal socket transformations
	  - Real-time WeldConstraint tree construction
	  - BFS Root Reachability validation to sever floating/isolated components into debris
	  - Dynamic snap solving for interactive Build Mode & Tractor Beams
]]

local Components = require(game.ReplicatedStorage.VoidHunterComponents)
local PhysicsConfig = require(game.ReplicatedStorage.Shared.Physics.PhysicsConfig)

local ShipSocketGraph = {}
ShipSocketGraph.__index = ShipSocketGraph

export type SocketInfo = {
	Id: string,
	Type: "InConnect" | "OutConnect",
	LocalOffset: Vector3,
	LocalDirection: Vector3, -- Outward normal vector from socket
	IsOccupied: boolean,
	ConnectedNodeId: string?,
	ConnectedSocketId: string?,
}

export type GraphNode = {
	Id: string,
	Part: BasePart,
	ComponentType: string,
	IsCore: boolean,
	LocalCFrame: CFrame, -- Relative to Core Root
	Sockets: { [string]: SocketInfo },
	ParentNodeId: string?,
	ParentSocketId: string?,
	ChildNodes: { [string]: string }, -- SocketId -> ChildNodeId
}

export type SnapCandidate = {
	ParentNode: GraphNode,
	ParentSocket: SocketInfo,
	TargetCFrame: CFrame,
	Distance: number,
	ChildSocketName: string,
}

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

-----------------------------------------------------------------------------
-- SOCKET DEFINITION EXTRACTOR
-----------------------------------------------------------------------------

local function getSocketNormal(offsetName: string): Vector3
	if string.find(offsetName, "Front") then
		return Vector3.new(0, 0, 1)
	elseif string.find(offsetName, "Back") then
		return Vector3.new(0, 0, -1)
	elseif string.find(offsetName, "Left") then
		return Vector3.new(-1, 0, 0)
	elseif string.find(offsetName, "Right") then
		return Vector3.new(1, 0, 0)
	elseif string.find(offsetName, "Hex1") then
		return Vector3.new(1, 0, 0)
	elseif string.find(offsetName, "Hex2") then
		return Vector3.new(0.5, 0, 0.866)
	elseif string.find(offsetName, "Hex3") then
		return Vector3.new(-0.5, 0, 0.866)
	elseif string.find(offsetName, "Hex4") then
		return Vector3.new(-1, 0, 0)
	elseif string.find(offsetName, "Hex5") then
		return Vector3.new(-0.5, 0, -0.866)
	elseif string.find(offsetName, "Hex") then
		return Vector3.new(0.5, 0, -0.866)
	end
	return Vector3.new(0, 0, 1)
end

function ShipSocketGraph:ExtractComponentSockets(compTypeName: string): { [string]: SocketInfo }
	local sockets: { [string]: SocketInfo } = {}
	local connDef = Components.Connections[compTypeName]
	local offsets = Components.AttachmentOffsets

	if not connDef then
		-- Default generic 4-way sockets for fallback pieces
		local defaultPositions = {
			InConnect_Front = offsets.InConnect_Front or Vector3.new(0, 0, 3.5),
			InConnect_Back = offsets.InConnect_Back or Vector3.new(0, 0, -3.5),
			InConnect_Left = offsets.InConnect_Left or Vector3.new(-3.5, 0, 0),
			InConnect_Right = offsets.InConnect_Right or Vector3.new(3.5, 0, 0),
		}
		for name, off in pairs(defaultPositions) do
			sockets[name] = {
				Id = name,
				Type = "InConnect",
				LocalOffset = off,
				LocalDirection = getSocketNormal(name),
				IsOccupied = false,
				ConnectedNodeId = nil,
				ConnectedSocketId = nil,
			}
		end
		return sockets
	end

	-- 1. Extract InConnect sockets (female receivers)
	if connDef.InConnectPositions then
		for idx, posName in ipairs(connDef.InConnectPositions) do
			local sockId = "InConnect_" .. tostring(idx) .. "_" .. posName
			local offset = offsets[posName] or Vector3.zero
			if connDef.MeshAttachmentPositions and connDef.MeshAttachmentPositions["InConnect_" .. idx] then
				offset = connDef.MeshAttachmentPositions["InConnect_" .. idx]
			end
			sockets[sockId] = {
				Id = sockId,
				Type = "InConnect",
				LocalOffset = offset,
				LocalDirection = getSocketNormal(posName),
				IsOccupied = false,
				ConnectedNodeId = nil,
				ConnectedSocketId = nil,
			}
		end
	end

	-- 2. Extract OutConnect plugs (male connectors)
	if connDef.OutConnectPosition then
		local posName = connDef.OutConnectPosition
		local sockId = "OutConnect_" .. posName
		local offset = offsets[posName] or Vector3.zero
		if connDef.MeshAttachmentPositions and connDef.MeshAttachmentPositions.OutConnect then
			offset = connDef.MeshAttachmentPositions.OutConnect
		end
		sockets[sockId] = {
			Id = sockId,
			Type = "OutConnect",
			LocalOffset = offset,
			LocalDirection = -getSocketNormal(posName),
			IsOccupied = false,
			ConnectedNodeId = nil,
			ConnectedSocketId = nil,
		}
	end

	return sockets
end

-----------------------------------------------------------------------------
-- GRAPH INITIALIZATION FROM MODEL
-----------------------------------------------------------------------------

function ShipSocketGraph:RebuildFromModel(shipModel: Model)
	self.ShipModel = shipModel
	self.Nodes = {}
	self.RootNodeId = nil

	-- 1. Identify Root Core
	local corePart = shipModel.PrimaryPart
	if not corePart then
		for _, desc in ipairs(shipModel:GetDescendants()) do
			if desc:IsA("BasePart") and desc:GetAttribute("IsCore") then
				corePart = desc
				shipModel.PrimaryPart = desc
				break
			end
		end
	end
	corePart = corePart or shipModel:FindFirstChildWhichIsA("BasePart")
	if not corePart then return end

	local coreTypeName = corePart:GetAttribute("ComponentType") or corePart.Name
	local rootNode: GraphNode = {
		Id = corePart:GetAttribute("NodeId") or ("node_" .. corePart.Name .. "_" .. tostring(math.random(1000, 9999))),
		Part = corePart,
		ComponentType = coreTypeName,
		IsCore = true,
		LocalCFrame = CFrame.identity,
		Sockets = self:ExtractComponentSockets(coreTypeName),
		ParentNodeId = nil,
		ParentSocketId = nil,
		ChildNodes = {},
	}
	corePart:SetAttribute("NodeId", rootNode.Id)
	self.Nodes[rootNode.Id] = rootNode
	self.RootNodeId = rootNode.Id

	-- 2. Index all other attached parts
	local rootCF = corePart.CFrame
	for _, part in ipairs(shipModel:GetDescendants()) do
		if part:IsA("BasePart") and part ~= corePart and not part:GetAttribute("IsDebris") then
			local compType = part:GetAttribute("ComponentType") or part.Name
			local nodeId = part:GetAttribute("NodeId") or ("node_" .. part.Name .. "_" .. tostring(math.random(1000, 9999)))
			part:SetAttribute("NodeId", nodeId)

			local node: GraphNode = {
				Id = nodeId,
				Part = part,
				ComponentType = compType,
				IsCore = false,
				LocalCFrame = rootCF:ToObjectSpace(part.CFrame),
				Sockets = self:ExtractComponentSockets(compType),
				ParentNodeId = nil,
				ParentSocketId = nil,
				ChildNodes = {},
			}
			self.Nodes[nodeId] = node
		end
	end

	-- 3. Resolve existing WeldConstraints into graph edges
	self:ResolveExistingWelds()
end

function ShipSocketGraph:ResolveExistingWelds()
	for _, node in pairs(self.Nodes) do
		if node.Part then
			for _, child in ipairs(node.Part:GetChildren()) do
				if child:IsA("WeldConstraint") and child.Part0 and child.Part1 then
					local otherPart = (child.Part0 == node.Part) and child.Part1 or child.Part0
					local otherNodeId = otherPart:GetAttribute("NodeId")
					local otherNode = otherNodeId and self.Nodes[otherNodeId]
					if otherNode then
						-- Mark as connected in graph
						self:PairSocketsByProximity(node, otherNode)
					end
				end
			end
		end
	end
end

function ShipSocketGraph:PairSocketsByProximity(nodeA: GraphNode, nodeB: GraphNode)
	local partA = nodeA.Part
	local partB = nodeB.Part
	if not partA or not partB then return end

	local bestDist = 3.0 -- Stud tolerance
	local bestSockA = nil
	local bestSockB = nil

	for sockIdA, sockA in pairs(nodeA.Sockets) do
		local worldPosA = partA.CFrame:PointToWorldSpace(sockA.LocalOffset)
		for sockIdB, sockB in pairs(nodeB.Sockets) do
			if sockA.Type ~= sockB.Type then
				local worldPosB = partB.CFrame:PointToWorldSpace(sockB.LocalOffset)
				local dist = (worldPosA - worldPosB).Magnitude
				if dist < bestDist then
					bestDist = dist
					bestSockA = sockA
					bestSockB = sockB
				end
			end
		end
	end

	if bestSockA and bestSockB then
		bestSockA.IsOccupied = true
		bestSockA.ConnectedNodeId = nodeB.Id
		bestSockA.ConnectedSocketId = bestSockB.Id

		bestSockB.IsOccupied = true
		bestSockB.ConnectedNodeId = nodeA.Id
		bestSockB.ConnectedSocketId = bestSockA.Id

		if bestSockA.Type == "InConnect" and bestSockB.Type == "OutConnect" then
			nodeA.ChildNodes[bestSockA.Id] = nodeB.Id
			nodeB.ParentNodeId = nodeA.Id
			nodeB.ParentSocketId = bestSockA.Id
		elseif bestSockB.Type == "InConnect" and bestSockA.Type == "OutConnect" then
			nodeB.ChildNodes[bestSockB.Id] = nodeA.Id
			nodeA.ParentNodeId = nodeB.Id
			nodeA.ParentSocketId = bestSockB.Id
		end
	end
end

-----------------------------------------------------------------------------
-- SNAP SOLVER FOR BUILD MODE & TRACTOR BEAM
-----------------------------------------------------------------------------

function ShipSocketGraph:FindBestSnap(heldPart: BasePart, compTypeName: string, maxSnapDist: number?): SnapCandidate?
	local snapRadius = maxSnapDist or Components.SNAP_DISTANCE or 6.0
	local heldSockets = self:ExtractComponentSockets(compTypeName)
	local heldCF = heldPart.CFrame

	-- Find any OutConnect plug on held part (plugs connect into ship sockets)
	local outPlugName = nil
	local outPlug = nil
	for sName, sData in pairs(heldSockets) do
		if sData.Type == "OutConnect" then
			outPlugName = sName
			outPlug = sData
			break
		end
	end

	-- If piece has no OutConnect (e.g. symmetrical hull blocks), fallback to first InConnect
	if not outPlug then
		for sName, sData in pairs(heldSockets) do
			outPlugName = sName
			outPlug = sData
			break
		end
	end

	if not outPlug then return nil end

	local bestCandidate: SnapCandidate? = nil
	local closestDistance = snapRadius

	for _, parentNode in pairs(self.Nodes) do
		if parentNode.Part and parentNode.Part:IsDescendantOf(workspace) then
			local parentCF = parentNode.Part.CFrame
			for parentSockId, parentSock in pairs(parentNode.Sockets) do
				-- Sockets only receive if not occupied and female (InConnect)
				if not parentSock.IsOccupied and (parentSock.Type == "InConnect" or not parentNode.IsCore) then
					local worldSocketPos = parentCF:PointToWorldSpace(parentSock.LocalOffset)
					local dist = (heldPart.Position - worldSocketPos).Magnitude

					if dist < closestDistance then
						-- Compute target CFrame that aligns held plug directly with parent socket
						local targetSocketPos = worldSocketPos
						local targetRotation = parentCF - parentCF.Position
						
						-- Invert direction for plug-to-socket mate
						local targetCF = CFrame.new(targetSocketPos) * targetRotation
						local finalPartCF = targetCF * CFrame.new(-outPlug.LocalOffset)

						-- Check for collision / overlap with existing nodes
						local hasOverlap = false
						for _, otherNode in pairs(self.Nodes) do
							if otherNode.Part and (otherNode.Part.Position - finalPartCF.Position).Magnitude < 3.0 then
								hasOverlap = true
								break
							end
						end

						if not hasOverlap then
							closestDistance = dist
							bestCandidate = {
								ParentNode = parentNode,
								ParentSocket = parentSock,
								TargetCFrame = finalPartCF,
								Distance = dist,
								ChildSocketName = outPlugName,
							}
						end
					end
				end
			end
		end
	end

	return bestCandidate
end

-----------------------------------------------------------------------------
-- ATTACH & DETACH PIPELINE
-----------------------------------------------------------------------------

function ShipSocketGraph:AttachComponent(parentNode: GraphNode, parentSocket: SocketInfo, childPart: BasePart, compTypeName: string): GraphNode?
	if not parentNode or not parentNode.Part or not childPart then return nil end

	-- 1. Create child node
	local childNodeId = "node_" .. compTypeName .. "_" .. tostring(math.random(10000, 99999))
	childPart:SetAttribute("NodeId", childNodeId)
	childPart:SetAttribute("ComponentType", compTypeName)
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

	-- 2. Establish bidirectional socket linkage
	parentSocket.IsOccupied = true
	parentSocket.ConnectedNodeId = childNodeId
	parentNode.ChildNodes[parentSocket.Id] = childNodeId

	-- Find matching plug on child
	for cSockId, cSock in pairs(childSockets) do
		if cSock.Type == "OutConnect" then
			cSock.IsOccupied = true
			cSock.ConnectedNodeId = parentNode.Id
			cSock.ConnectedSocketId = parentSocket.Id
			parentSocket.ConnectedSocketId = cSockId
			break
		end
	end

	-- 3. Create WeldConstraint
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

-----------------------------------------------------------------------------
-- BFS ROOT REACHABILITY & SEVERANCE ENGINE (AlterOrb Mechanic)
-----------------------------------------------------------------------------

function ShipSocketGraph:ValidateReachability(): { Reachable: { [string]: GraphNode }, Severed: { [string]: GraphNode } }
	local reachable: { [string]: GraphNode } = {}
	local severed: { [string]: GraphNode } = {}

	if not self.RootNodeId or not self.Nodes[self.RootNodeId] then
		-- Entire ship is lost
		for id, node in pairs(self.Nodes) do
			severed[id] = node
		end
		return { Reachable = reachable, Severed = severed }
	end

	-- BFS Traversal from Root Core
	local queue = { self.RootNodeId }
	reachable[self.RootNodeId] = self.Nodes[self.RootNodeId]

	while #queue > 0 do
		local currentId = table.remove(queue, 1)
		local currentNode = self.Nodes[currentId]

		if currentNode and currentNode.Part and currentNode.Part.Parent then
			-- Inspect all active connections on this node
			for _, socket in pairs(currentNode.Sockets) do
				if socket.IsOccupied and socket.ConnectedNodeId then
					local neighborId = socket.ConnectedNodeId
					local neighborNode = self.Nodes[neighborId]
					
					-- Verify physical weld integrity
					local hasWeld = false
					if neighborNode and neighborNode.Part then
						for _, child in ipairs(neighborNode.Part:GetChildren()) do
							if child:IsA("WeldConstraint") and (child.Part0 == currentNode.Part or child.Part1 == currentNode.Part) then
								hasWeld = true
								break
							end
						end
						if not hasWeld then
							for _, child in ipairs(currentNode.Part:GetChildren()) do
								if child:IsA("WeldConstraint") and (child.Part0 == neighborNode.Part or child.Part1 == neighborNode.Part) then
									hasWeld = true
									break
								end
							end
						end
					end

					if hasWeld and not reachable[neighborId] then
						reachable[neighborId] = neighborNode
						table.insert(queue, neighborId)
					end
				end
			end
		end
	end

	-- All unvisited nodes in the graph are severed debris
	for id, node in pairs(self.Nodes) do
		if not reachable[id] then
			severed[id] = node
		end
	end

	return { Reachable = reachable, Severed = severed }
end

-- Severs all disconnected components, frees welds, and assigns 2D debris drift
function ShipSocketGraph:SeverUnreachableComponents(debrisFolder: Instance?): { BasePart }
	local result = self:ValidateReachability()
	local severedParts: { BasePart } = {}
	local targetParent = debrisFolder or workspace

	for severedId, node in pairs(result.Severed) do
		local part = node.Part
		if part and part.Parent then
			-- 1. Break all Welds
			for _, desc in ipairs(part:GetDescendants()) do
				if desc:IsA("WeldConstraint") then
					desc:Destroy()
				end
			end

			-- 2. Mark as independent debris
			part:SetAttribute("IsDebris", true)
			part:SetAttribute("NodeId", nil)
			part.Parent = targetParent
			part.Anchored = false
			part.CanCollide = true

			-- 3. Impart outward sever impulse
			local outwardDir = (part.Position - (self.ShipModel and self.ShipModel:GetPivot().Position or part.Position)).Unit
			part.AssemblyLinearVelocity = Vector3.new(outwardDir.X * 15, 0, outwardDir.Z * 15)
			part.AssemblyAngularVelocity = Vector3.new(0, math.random(-5, 5), 0)

			table.insert(severedParts, part)
		end
		-- Remove from active topology graph
		self.Nodes[severedId] = nil
	end

	return severedParts
end

-----------------------------------------------------------------------------
-- SERIALIZATION & BLUEPRINT RECONSTRUCTION
-----------------------------------------------------------------------------

function ShipSocketGraph:Serialize(): any
	local blueprint = {
		RootType = self.RootNodeId and self.Nodes[self.RootNodeId] and self.Nodes[self.RootNodeId].ComponentType or "CommandCore",
		Pieces = {},
	}

	local rootNode = self.RootNodeId and self.Nodes[self.RootNodeId]
	local rootCF = rootNode and rootNode.Part and rootNode.Part.CFrame or CFrame.identity

	for id, node in pairs(self.Nodes) do
		if node.Part then
			local relCF = rootCF:ToObjectSpace(node.Part.CFrame)
			table.insert(blueprint.Pieces, {
				Id = id,
				Type = node.ComponentType,
				IsCore = node.IsCore,
				Position = { X = relCF.Position.X, Y = relCF.Position.Y, Z = relCF.Position.Z },
				Rotation = { X = relCF:ToEulerAnglesYXZ() },
				ParentSocketId = node.ParentSocketId,
			})
		end
	end

	return blueprint
end

return ShipSocketGraph
