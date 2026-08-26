# VOIDA Roblox / Luau Engineering Reference

## Purpose

This is the standing quick-reference for Roblox-specific Luau implementation in the Void Hunters port. Prefer these patterns when they preserve the recovered behavior and do not conflict with `AGENTS.md` or recovered source semantics.

## Canonical naming

Use authoritative nouns consistently:

| Deprecated / ambiguous | Canonical |
|---|---|
| `partHealth` / `partMaxHealth` | `ComponentAuthority.Health` / `ComponentAuthority.MaxHealth` |
| local ship maps | `ShipRegistry` |
| ad-hoc weld mutation | `StructuralAuthority` |
| generic socket fallback | authoritative `Components.Connections` hardpoints |
| name-based component state | `ComponentType` + component definition |
| Red / Blue team vocabulary | `TeamIdentity.YELLOW` / `TeamIdentity.BLUE` |
| direct detached-part deletion | `StructuralAuthority.DetachComponent` |
| Instance attribute as gameplay authority | ModuleScript runtime state; attributes are mirrors/diagnostics |

Never retain a deprecated term merely as a second source of truth. Compatibility aliases should be thin, explicit, and temporary.

## Service/container locals

Prefer standard service locals near the top of a server/client module:

```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
```

Common container conventions:

```lua
local shared = ReplicatedStorage.Shared
local components = ReplicatedStorage.VoidHunterComponents
local shipsFolder = Workspace:FindFirstChild("Ships")
local debrisFolder = Workspace:FindFirstChild("VoidHunterDebris")
```

Use lowercase locals for instances/services and PascalCase for ModuleScript APIs/types.

## ModuleScript pattern

```lua
local ExampleService = {}
ExampleService.__index = ExampleService

function ExampleService.new()
	return setmetatable({}, ExampleService)
end

return ExampleService
```

For stateless authoritative services, a plain table is preferable to a class-shaped object.

## Type annotations

Use Luau types at subsystem boundaries and important state tables:

```lua
local ships: { [Player]: Model } = {}
local cooldowns: { [Player]: number } = {}

local function validateShip(player: Player, ship: Model): (boolean, string?)
	...
end
```

Prefer narrow unions for protocol/state values:

```lua
export type TeamId = "Yellow" | "Blue"
export type DamageType = "Kinetic" | "Thermal" | "Energy" | "Explosive" | "EMP"
```

## Guards and early returns

Use guard clauses instead of deep nesting:

```lua
if not player or not player.Parent then
	return false, "Invalid player"
end

if not ship or not ship:IsDescendantOf(Workspace) then
	return false, "Invalid ship"
end
```

Validate ownership before mutating state:

```lua
if not ShipRegistry.IsOwner(player, ship) then
	return
end
```

For numeric remote input, reject NaN and infinities:

```lua
local function isFiniteNumber(value: any): boolean
	return typeof(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
end
```

## Tables and cleanup

Prefer local tables with explicit ownership. Do not create a second authoritative dictionary for state already owned by a module service.

For ephemeral instance-keyed caches, weak keys are useful:

```lua
local stateByPart = setmetatable({}, { __mode = "k" })
```

Always clear references on lifecycle events:

```lua
ship.AncestryChanged:Connect(function(_, parent)
	if not parent then
		ShipRegistry.UnregisterShip(ship)
	end
end)
```

## Connections

Store connections when they need explicit teardown:

```lua
local connections = {}
connections[#connections + 1] = player.CharacterAdded:Connect(onCharacterAdded)

local function disconnectAll()
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	table.clear(connections)
end
```

Avoid creating repeated heartbeat/touched connections without a teardown path.

## `task` over legacy scheduling

Prefer:

```lua
task.spawn(fn)
task.defer(fn)
task.delay(seconds, fn)
task.wait(seconds)
```

Avoid old `spawn`, `delay`, and `wait` APIs in new code.

## Iteration

Prefer `ipairs` for arrays and `pairs` for dictionaries:

```lua
for _, part in ipairs(parts) do
	...
end

for player, ship in pairs(shipMap) do
	...
end
```

For hot loops, avoid repeated `workspace:GetDescendants()`. Maintain indexed registries or use spatial queries such as `Workspace:GetPartBoundsInRadius` when appropriate.

## Instances and containers

Prefer `FindFirstChild` when absence is valid:

```lua
local shipsFolder = Workspace:FindFirstChild("Ships")
```

Prefer `WaitForChild` for required boot-time dependencies:

```lua
local Components = require(ReplicatedStorage:WaitForChild("VoidHunterComponents"))
```

Do not use `WaitForChild` inside hot gameplay loops as a search mechanism.

## Attributes

Attributes are useful discovery and diagnostic mirrors:

```lua
part:SetAttribute("ComponentType", state.TypeName)
```

They are not the canonical authority when a ModuleScript service already owns the runtime state.

Do not use attributes as a mutable substitute for a state service just because they are convenient.

## Remotes

Create remotes once during server initialization, then reuse them. Every remote handler should validate:

1. player exists
2. action/protocol type is valid
3. ownership is valid
4. target instance is in the expected container/model
5. numeric values are finite and bounded
6. requested state transition is legal

Never trust client-provided `Model`, `BasePart`, damage, distance, or timing values without server validation.

## CFrame / Transform patterns

Use object-space transforms for blueprints and relative assembly state:

```lua
local relative = root.CFrame:ToObjectSpace(part.CFrame)
local world = root.CFrame:ToWorldSpace(relative)
```

Use `Model:PivotTo` for moving a whole model when the model's pivot is authoritative:

```lua
ship:PivotTo(targetCFrame)
```

Use `CFrame:PointToWorldSpace` / `PointToObjectSpace` for socket or attachment positions.

## Physics

Prefer Roblox-native physics only when it preserves the required observable behavior:

- `AssemblyLinearVelocity`
- `AssemblyAngularVelocity`
- `BasePart:ApplyImpulse`
- `VectorForce`
- `AlignOrientation`
- `WeldConstraint`
- `Raycast`

Keep the logical ship graph separate from Roblox weld topology. Welds are a physical projection, not the authoritative graph.

## Structural mutation

All attach/detach/replace/sever paths converge on `StructuralAuthority`:

```lua
StructuralAuthority.AttachComponent(...)
StructuralAuthority.DetachComponent(...)
StructuralAuthority.ReplaceComponent(...)
StructuralAuthority.SeverDisconnected(...)
```

Do not create ad-hoc nearest-neighbor weld logic in another subsystem.

## Component state

All HP, damage, repair, critical, and destruction state converges on `ComponentAuthority`:

```lua
local state = ComponentAuthority.Get(part) or ComponentAuthority.Bind(part)
ComponentAuthority.ApplyDamage(part, amount)
ComponentAuthority.Repair(part, amount)
ComponentAuthority.MarkDestroyed(part)
```

Do not create local copies of component HP.

## Teams

Use `TeamIdentity` instead of string literals:

```lua
local TeamIdentity = require(ReplicatedStorage.Shared.Combat.TeamIdentity)

TeamIdentity.Set(ship, TeamIdentity.YELLOW)
local team = TeamIdentity.Get(ship)
```

Component category colors and team colors are separate concepts.

## Replace-all / bulk refactor rule

When a deprecated symbol is purely lexical and has one canonical replacement, a repository-wide replace-all is preferred over manual one-off renames. Before applying it:

1. enumerate all matches
2. classify code vs documentation vs historical/reference text
3. replace code first
4. update comments/docs that describe the old authority
5. re-scan for remaining live references
6. compile/smoke-test the affected paths

Do not replace historical source quotations when the old term is part of recovered evidence; preserve the source text and annotate the mapping instead.

## Recommended refactor order

1. `ComponentAuthority` for state
2. `ShipRegistry` for owner/ship lookup
3. `StructuralAuthority` for graph mutation
4. `TeamIdentity` for ownership vocabulary
5. component definitions for type/hardpoint truth
6. subsystem-specific behavior
7. documentation/status cleanup

This minimizes temporary duplicate authorities during migration.

## Fast Lua cleanup patterns

Prefer:

```lua
local target = condition and valueA or valueB
local name = instance.Name
local primary = model.PrimaryPart
```

over repeated property traversal when values are reused in the same scope.

Use `table.clear(t)` when reusing a table instead of allocating a replacement in hot loops.

Use `math.clamp` for bounded scalar values.

Use `continue` when it makes a loop's rejection path clearer, especially during blueprint/component processing.

Avoid clever metatable tricks for ordinary state. Explicit service APIs are easier to audit and safer for authoritative multiplayer logic.

## Verification discipline

Every engineering change should record:

```text
SOURCE:
CURRENT IMPLEMENTATION:
BEHAVIORAL DELTA:
ACCEPTANCE TEST:
STATUS:
```

Use `IMPLEMENTED` until the behavior is actually acceptance-tested against the appropriate reference evidence. Do not promote inferred constants or compatible Roblox behavior to `VERIFIED` without source support and a test.
