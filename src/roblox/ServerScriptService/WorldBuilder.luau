-- WORLD BUILDER - runs at game start, builds hangar + ships + debris
local U = 7; local LB = Vector3.new(5000,0,5000)

-- Floor (no walls/ceiling)
local fl = Instance.new("Part")
fl.Name = "HangarFloor"; fl.Size = Vector3.new(120,0.5,60)
fl.Position = LB+Vector3.new(0,-0.25,0)
fl.BrickColor = BrickColor.new("Dark stone gray")
fl.Material = Enum.Material.Concrete; fl.Anchored = true; fl.Parent = workspace

local lt = Instance.new("PointLight")
lt.Brightness = 5; lt.Range = 80; lt.Color = Color3.new(1,1,0.95); lt.Parent = fl

local function mp(n,x,z,c,p)
	local pt=Instance.new("Part"); pt.Name=n; pt.Size=Vector3.new(x*U,3.5,z*U)
	pt.BrickColor=BrickColor.new(c); pt.Material=Enum.Material.Metal
	pt.Anchored=false; pt.CanCollide=true; pt.Parent=p; return pt
end

for i=1,7 do
	local off=(i-4)*4; local pos=LB+Vector3.new(off*U,0.125,0)
	-- Pad
	local pad=Instance.new("Part")
	pad.Name="Pad_"..i; pad.Size=Vector3.new(9,0.25,9); pad.Position=pos
	pad.BrickColor=BrickColor.new("Bright green"); pad.Material=Enum.Material.Neon
	pad.Anchored=true; pad.Transparency=0.4; pad.Parent=workspace
	local g=Instance.new("PointLight"); g.Brightness=2; g.Range=8
	g.Color=Color3.new(0,1,0.5); g.Parent=pad
	-- Ship
	local m=Instance.new("Model"); m.Name="Ship"..i
	local core=mp("Command Core",1,1,"Dark red",m); core.Position=pos+Vector3.new(0,1.5,0)
	local seat=Instance.new("VehicleSeat")
	seat.Name="Seat"; seat.Size=Vector3.new(4,1,4); seat.Anchored=false
	seat.Position=pos+Vector3.new(0,2.5,0); seat.Parent=m
	local sw=Instance.new("WeldConstraint"); sw.Part0=core; sw.Part1=seat; sw.Parent=seat
	local lt=mp("Standard Thruster",1,1,"Bright orange",m); lt.Position=pos+Vector3.new(-U,1.5,0)
	local lw=Instance.new("WeldConstraint"); lw.Part0=core; lw.Part1=lt; lw.Parent=lt
	local rt=mp("Standard Thruster",1,1,"Bright orange",m); rt.Position=pos+Vector3.new(U,1.5,0)
	local rw=Instance.new("WeldConstraint"); rw.Part0=core; rw.Part1=rt; rw.Parent=rt
	m.PrimaryPart=core; m:SetAttribute("IsShip",true); m.Parent=workspace
end
print("World built: hangar + 7 ships")

-- Debris
math.randomseed(tick())
local dtList = {{"Mass Driver","Steel blue"},{"Plasma Ball Launcher","Purple"},{"Missile Launcher","Red"},{"Shield Generator","Cyan"},{"Reactor","Yellow"},{"Light Hull","Gray"},{"Medium Hull","Dark gray"}}
for _,dt in ipairs(dtList) do
	for j=1,3 do
		local px=math.random(-200,200); local pz=math.random(-200,200)
		local C=require(game.ReplicatedStorage.VoidHunterComponents)
		for tn,def in pairs(C.Types) do
			if def.Name==dt[1] then
				local r=C.Create(tn)
				if r then r.Position=Vector3.new(px,3.5,pz); r.Parent=workspace; r:SetAttribute("IsDebris",true) end
			end
		end
	end
end
print("Debris spawned")
