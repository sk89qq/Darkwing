-- BUILDER SERVER
local RS = game:GetService("ReplicatedStorage")
local DSS = game:GetService("DataStoreService")
local Debris = game:GetService("Debris")
local PL = game:GetService("Players")

local be = RS.VoidHunterBuilder
local Components = require(RS.VoidHunterComponents)

-- DataStore with error handling
local store = nil
local ok, err = pcall(function() store = DSS:GetDataStore("VHBlueprints") end)
if not ok then
	store = {data={}}
	function store:SetAsync(k,v) self.data[k]=v end
	function store:GetAsync(k) return self.data[k] end
end

local autoActive = {}
local saveCooldowns = {} -- Rate limiting for saves
local SAVE_COOLDOWN = 2 -- seconds between saves

-- Exported module table
local BuilderServer = {}

-- Cache for debris lookups (performance optimization)
local debrisCache = {}
local cacheLastUpdate = 0
local CACHE_TTL = 1 -- seconds

local function getDebrisCache()
	local now = tick()
	if now - cacheLastUpdate > CACHE_TTL then
		debrisCache = {}
		for _, p in ipairs(workspace:GetDescendants()) do
			if p:IsA("BasePart") and p:GetAttribute("IsDebris") then
			debrisCache[p.Name] = debrisCache[p.Name] or {}
			table.insert(debrisCache[p.Name], p)
			end
		end
		cacheLastUpdate = now
	end
	return debrisCache
end

local function captureShip(m)
	local parts = {}
	local primaryPart = m.PrimaryPart
	
	-- Find the actual primary part if it's a nested model
	if not primaryPart then
		for _, desc in ipairs(m:GetDescendants()) do
			if desc:IsA("BasePart") and desc:GetAttribute("IsCore") then
				primaryPart = desc
				break
			end
		end
	end
	
	for _,c in ipairs(m:GetDescendants()) do
		if not c:IsA("BasePart") or c:IsA("VehicleSeat") then continue end
		local tn = nil
		for t,d in pairs(require(RS.VoidHunterComponents).Types) do
			if d.Name == c.Name then tn=t; break end
		end
		-- Also check for component type attribute (for mesh models)
		if not tn and c:GetAttribute("ComponentType") then
			tn = c:GetAttribute("ComponentType")
		end
		if tn then
			local cf = primaryPart and primaryPart.CFrame:ToObjectSpace(c.CFrame) or c.CFrame
			table.insert(parts, {partType=tn, cframe=cf, name=c.Name})
		end
	end
	return {name=m.Name.."_BP", parts=parts}
end

local function saveBP(pl, m)
	-- Rate limiting
	local now = tick()
	if saveCooldowns[pl.UserId] and now - saveCooldowns[pl.UserId] < SAVE_COOLDOWN then
		return false, "Rate limited"
	end
	saveCooldowns[pl.UserId] = now
	
	local success, d = pcall(captureShip, m)
	if not success then
		warn("Failed to capture ship: " .. tostring(d))
		return false, "Capture failed"
	end
	
	local key = "bp_"..pl.UserId
	local saveOk, saveErr = pcall(function() store:SetAsync(key, d) end)
	if not saveOk then
		warn("Failed to save blueprint: " .. tostring(saveErr))
		return false, "Save failed"
	end
	
	print("BP saved:", #d.parts, "parts")
	return true
end

local function autoBuild(pl, m)
	if not pl or not m or not m.Parent then return end
	
	autoActive[pl] = true
	local key = "bp_"..pl.UserId
	local ok, d = pcall(function() return store:GetAsync(key) end)
	if not ok or not d or not d.parts then
		autoActive[pl] = false
		return
	end
	
	-- Find the actual primary part (handles nested models like CommandCore)
	local primaryPart = m.PrimaryPart
	if not primaryPart then
		for _, desc in ipairs(m:GetDescendants()) do
			if desc:IsA("BasePart") and desc:GetAttribute("IsCore") then
				primaryPart = desc
				break
			end
		end
	end
	local primaryPos = primaryPart and primaryPart.Position or Vector3.new(0, 0, 0)
	
	for _, bp in ipairs(d.parts) do
		if not autoActive[pl] then break end
		if not m or not m.Parent then break end
		
		local def = Components.Types[bp.partType]
		if not def then continue end
		
		-- Use cached debris lookup instead of O(N) search
		local cache = getDebrisCache()
		local debris = nil
		local debrisList = cache[def.Name]
		if debrisList then
			for _, p in ipairs(debrisList) do
				if p.Parent and (p.Position - primaryPos).Magnitude <= 20 then
					debris = p
					break
				end
			end
		end
		if not debris then continue end
		local tcf = primaryPart and primaryPart.CFrame:ToWorldSpace(bp.cframe) or bp.cframe
		tcf = CFrame.new(tcf.X,3.5,tcf.Z)
		local sp = debris.Position
		local el = 0; local dur = 0.3
		debris:SetAttribute("IsDebris", nil); debris.Anchored = true
		while el < dur and debris.Parent do
			el = el+0.03; local t = math.min(el/dur,1)
			local e = t*t*(3-2*t)
			local np = sp:Lerp(tcf.Position, e)
			debris.Position = Vector3.new(np.X,3.5,np.Z)
			task.wait(0.03)
		end
		if not debris.Parent then continue end
		debris.Anchored = false
		debris.Position = Vector3.new(tcf.X,3.5,tcf.Z)
		local best,bestD = nil,8
		for _,c in ipairs(m:GetDescendants()) do
			if c:IsA("BasePart") and c ~= debris then
				local d2 = (debris.Position-c.Position).Magnitude
				if d2 < bestD then bestD=d2; best=c end
			end
		end
		if best then
			local w = Instance.new("WeldConstraint")
			w.Part0 = best; w.Part1 = debris; w.Parent = debris
		end
		debris:SetAttribute("IsDebris", nil)
		task.wait(0.05)
	end
	autoActive[pl] = false
	print("BP build complete")
end

be.OnServerEvent:Connect(function(pl, action, m, partName)
	if not m or not m.Parent then return end
	if action == "save_blueprint" then saveBP(pl, m)
	elseif action == "start_blueprint" then task.spawn(autoBuild, pl, m)
	elseif action == "stop_blueprint" then autoActive[pl] = false
	elseif action == "weld" then
		local p = m:FindFirstChild(partName, true)
		if p and p:IsA("BasePart") then p:SetAttribute("IsDebris", nil) end
	elseif action == "detach" then
		local p = m:FindFirstChild(partName, true)
		if p and p:IsA("BasePart") then
			p:SetAttribute("IsDebris", true)
			for _,w in ipairs(p:GetDescendants()) do if w:IsA("WeldConstraint") then w:Destroy() end end
		end
	end
end)
-- Build ship from blueprint (for SyncManager)
function BuilderServer.BuildShipFromBlueprint(blueprint)
	if not blueprint or not blueprint.Components then
		warn("Invalid blueprint provided")
		return nil
	end
	
	local ship = Instance.new("Model")
	ship.Name = blueprint.Name or "Ship"
	
	local primaryPart = nil
	
	for _, comp in ipairs(blueprint.Components) do
		local result = Components.Create(comp.Type)
		if result and result.part then
			local part = result.part
			part.CFrame = CFrame.new(comp.Pos) * CFrame.Angles(math.rad(comp.Rot.X), math.rad(comp.Rot.Y), math.rad(comp.Rot.Z))
			part.Parent = ship
			
			if not primaryPart then
				primaryPart = part
			end
		end
	end
	
	if primaryPart then
		ship.PrimaryPart = primaryPart
	end
	
	return ship
end

-- Get blueprint for player (for SyncManager)
function BuilderServer.GetBlueprint(player)
	local key = "bp_" .. player.UserId
	local ok, data = pcall(function() return store:GetAsync(key) end)
	if ok and data then
		return data
	end
	return nil
end

print("BuilderServer loaded")
return BuilderServer
