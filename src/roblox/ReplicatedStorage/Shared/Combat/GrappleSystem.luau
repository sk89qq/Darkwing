--[=[
	GrappleSystem
	Roblox-native implementation boundary for the recovered Void Hunters
	GrapplingHook / GrappleLauncherBehaviour lifecycle.

	Confirmed source lifecycle:
		idle -> fired -> traveling -> attached -> reel/constraint -> detach/break/retract

	Confirmed original configuration names are retained verbatim so this module
	can consume recovered values without renaming the forensic vocabulary:
		GRAPPLING_HOOK_AIMSPEED
		GRAPPLING_HOOK_AIMARC
		GRAPPLING_HOOK_COOLDOWN
		GRAPPLING_HOOK_FIRE_FORCE
		GRAPPLING_HOOK_SPRING_CONSTANT
		GRAPPLING_HOOK_MAX_EXTENSION8_FORCE
		GRAPPLING_HOOK_MAX_LENGTH
		GRAPPLING_HOOK_MIN_LENGTH
		GRAPPLING_HOOK_ROPE_CHANGE_RATE
		GRAPPLING_HOOK_ROPE_BREAK_LENGTH

	Numerical values are intentionally supplied by the caller. The current raw
	reference establishes the parameter family and lifecycle, but does not expose
	a verified numeric consumer for every parameter in an indexable source form.
]=]

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

export type State =
	"Idle"
	| "Fired"
	| "Traveling"
	| "Attached"
	| "Retracting"
	| "Detached"
	| "Broken"

export type Config = {
	GRAPPLING_HOOK_AIMSPEED: number,
	GRAPPLING_HOOK_AIMARC: number,
	GRAPPLING_HOOK_COOLDOWN: number,
	GRAPPLING_HOOK_FIRE_FORCE: number,
	GRAPPLING_HOOK_SPRING_CONSTANT: number,
	GRAPPLING_HOOK_MAX_EXTENSION8_FORCE: number,
	GRAPPLING_HOOK_MAX_LENGTH: number,
	GRAPPLING_HOOK_MIN_LENGTH: number,
	GRAPPLING_HOOK_ROPE_CHANGE_RATE: number,
	GRAPPLING_HOOK_ROPE_BREAK_LENGTH: number,
}

export type Target = {
	Instance: BasePart,
	Position: Vector3,
	Model: Model?,
}

export type Grapple = {
	OwnerShip: Model,
	Launcher: BasePart,
	Anchor: Attachment,
	Rope: RopeConstraint,
	VisualHook: BasePart,
	State: State,
	Target: BasePart?,
	TargetAttachment: Attachment?,
	Length: number,
	LastStateChange: number,
	LastFire: number,
}

local GrappleSystem = {}
GrappleSystem.__index = GrappleSystem

local function getShipPosition(ship: Model): Vector3
	return ship.PrimaryPart and ship.PrimaryPart.Position or ship:GetPivot().Position
end

local function getShipModel(instance: Instance): Model?
	local model = instance:FindFirstAncestorOfClass("Model")
	if model and model:GetAttribute("IsShip") == true then
		return model
	end
	return nil
end

local function projectPlanar(position: Vector3): Vector3
	return Vector3.new(position.X, position.Y, position.Z)
end

local function clampLength(length: number, config: Config): number
	return math.clamp(length, config.GRAPPLING_HOOK_MIN_LENGTH, config.GRAPPLING_HOOK_MAX_LENGTH)
end

local function createTargetAttachment(part: BasePart, worldPosition: Vector3): Attachment
	local attachment = Instance.new("Attachment")
	attachment.Name = "GrappleTargetAttachment"
	attachment.WorldPosition = worldPosition
	attachment.Parent = part
	return attachment
end

local function createHookVisual(position: Vector3): BasePart
	local hook = Instance.new("Part")
	hook.Name = "GrappleHook"
	hook.Shape = Enum.PartType.Ball
	hook.Size = Vector3.new(0.6, 0.6, 0.6)
	hook.Material = Enum.Material.Neon
	hook.Transparency = 0.2
	hook.Anchored = true
	hook.CanCollide = false
	hook.CanTouch = false
	hook.CanQuery = false
	hook.Position = position
	hook.Parent = Workspace
	return hook
end

local function createRope(anchor: Attachment): RopeConstraint
	local rope = Instance.new("RopeConstraint")
	rope.Name = "GrappleRope"
	rope.Visible = true
	rope.Thickness = 0.08
	rope.Restitution = 0
	rope.Attachment0 = anchor
	rope.Parent = anchor.Parent
	return rope
end

function GrappleSystem.new(ownerShip: Model, launcher: BasePart, config: Config)
	assert(ownerShip and ownerShip:IsA("Model"), "GrappleSystem.new expects a ship model")
	assert(launcher and launcher:IsA("BasePart"), "GrappleSystem.new expects a launcher BasePart")

	local anchor = Instance.new("Attachment")
	anchor.Name = "GrappleLauncherAttachment"
	anchor.Position = Vector3.zero
	anchor.Parent = launcher

	local grapple: Grapple = {
		OwnerShip = ownerShip,
		Launcher = launcher,
		Anchor = anchor,
		Rope = createRope(anchor),
		VisualHook = createHookVisual(launcher.Position),
		State = "Idle",
		Target = nil,
		TargetAttachment = nil,
		Length = config.GRAPPLING_HOOK_MAX_LENGTH,
		LastStateChange = os.clock(),
		LastFire = -math.huge,
	}

	grapple.Rope.Enabled = false
	grapple.VisualHook.Transparency = 1
	return setmetatable({ Grapple = grapple, Config = config, Connection = nil }, GrappleSystem)
end

function GrappleSystem:_setState(state: State)
	self.Grapple.State = state
	self.Grapple.LastStateChange = os.clock()
end

function GrappleSystem:GetState(): State
	return self.Grapple.State
end

function GrappleSystem:GetLength(): number
	return self.Grapple.Length
end

function GrappleSystem:CanFire(): boolean
	if self.Grapple.State ~= "Idle" and self.Grapple.State ~= "Detached" and self.Grapple.State ~= "Broken" then
		return false
	end
	return os.clock() - self.Grapple.LastFire >= self.Config.GRAPPLING_HOOK_COOLDOWN
end

function GrappleSystem:FindTarget(origin: Vector3, direction: Vector3): Target?
	if direction.Magnitude <= 0.001 then
		return nil
	end

	local rayDirection = direction.Unit * self.Config.GRAPPLING_HOOK_MAX_LENGTH
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	params.FilterDescendantsInstances = { self.Grapple.OwnerShip, self.Grapple.VisualHook }

	local result = Workspace:Raycast(origin, rayDirection, params)
	if not result then
		return nil
	end

	local targetModel = getShipModel(result.Instance)
	return {
		Instance = result.Instance,
		Position = result.Position,
		Model = targetModel,
	}
end

function GrappleSystem:Fire(direction: Vector3): (boolean, string?)
	if not self:CanFire() then
		return false, "Cooldown or invalid state"
	end
	if direction.Magnitude <= 0.001 then
		return false, "Invalid direction"
	end

	self.Grapple.LastFire = os.clock()
	self:_setState("Fired")
	self.Grapple.Target = nil
	self.Grapple.TargetAttachment = nil
	self.Grapple.Rope.Enabled = false
	self.Grapple.VisualHook.Transparency = 0.2
	self.Grapple.VisualHook.Position = self.Grapple.Launcher.Position

	local origin = self.Grapple.Launcher.Position
	local target = self:FindTarget(origin, direction)
	if target then
		self.Grapple.Target = target.Instance
		self:_setState("Traveling")
		self:_attach(target)
	else
		self:_setState("Retracting")
	end

	return true, nil
end

function GrappleSystem:_attach(target: Target)
	if not target.Instance.Parent then
		self:_setState("Broken")
		return
	end

	local targetAttachment = createTargetAttachment(target.Instance, target.Position)
	self.Grapple.TargetAttachment = targetAttachment
	self.Grapple.Rope.Attachment1 = targetAttachment
	self.Grapple.Length = clampLength((self.Grapple.Launcher.Position - target.Position).Magnitude, self.Config)
	self.Grapple.Rope.Length = self.Grapple.Length
	self.Grapple.Rope.Enabled = true
	self.Grapple.VisualHook.Position = target.Position
	self:_setState("Attached")
end

function GrappleSystem:Detach(reason: string?)
	if self.Grapple.TargetAttachment then
		self.Grapple.TargetAttachment:Destroy()
		self.Grapple.TargetAttachment = nil
	end
	self.Grapple.Target = nil
	self.Grapple.Rope.Enabled = false
	self.Grapple.VisualHook.Transparency = 1
	self:_setState(reason == "Break" and "Broken" or "Detached")
end

function GrappleSystem:ReelIn(dt: number, delta: number)
	if self.Grapple.State ~= "Attached" then
		return
	end
	if not self.Grapple.Target or not self.Grapple.Target.Parent then
		self:Detach("Break")
		return
	end

	local rate = math.max(delta, 0) * math.max(self.Config.GRAPPLING_HOOK_ROPE_CHANGE_RATE, 0)
	self.Grapple.Length = clampLength(self.Grapple.Length - rate, self.Config)
	self.Grapple.Rope.Length = self.Grapple.Length

	local distance = (self.Grapple.Launcher.Position - self.Grapple.Target.Position).Magnitude
	if distance > self.Config.GRAPPLING_HOOK_ROPE_BREAK_LENGTH then
		self:Detach("Break")
		return
	end

	if self.Grapple.Length <= self.Config.GRAPPLING_HOOK_MIN_LENGTH then
		self:_setState("Retracting")
	end
end

function GrappleSystem:Step(dt: number)
	if dt <= 0 then
		return
	end

	if self.Grapple.State == "Retracting" then
		local current = self.Grapple.VisualHook.Position
		local target = self.Grapple.Launcher.Position
		local offset = target - current
		local distance = offset.Magnitude
		if distance <= 0.5 then
			self.Grapple.VisualHook.Position = target
			self.Grapple.VisualHook.Transparency = 1
			self:_setState("Idle")
			return
		end
		self.Grapple.VisualHook.Position = current + offset.Unit * math.min(distance, self.Config.GRAPPLING_HOOK_AIMSPEED * dt)
	end
end

function GrappleSystem:Destroy()
	if self.Connection then
		self.Connection:Disconnect()
		self.Connection = nil
	end
	self:Detach("Break")
	if self.Grapple.Rope.Parent then
		self.Grapple.Rope:Destroy()
	end
	if self.Grapple.Anchor.Parent then
		self.Grapple.Anchor:Destroy()
	end
	if self.Grapple.VisualHook.Parent then
		self.Grapple.VisualHook:Destroy()
	end
end

return GrappleSystem
