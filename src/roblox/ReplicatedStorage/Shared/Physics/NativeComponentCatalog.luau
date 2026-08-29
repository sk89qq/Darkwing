--!strict
--[=[
	NativeComponentCatalog

	Implementation-facing representation of the original game's 56-slot wfb
	component table. This is deliberately source-domain data only: it does not
	assign Roblox component names and it performs no unit conversion.

	Every native slot 0..55 is represented exactly once. Direct polygon slots
	carry their recovered vertex/origin data. Referenced/generated slots carry
	the exact recovered source expression/reference so a later execution layer
	can instantiate the same native definition without guessing an identity.
]=]

export type NativeSlot = {
	Id: number,
	SourceLine: number,
	DefinitionKind: string,
	Initializer: string,
	Behavior: string?,
	Vertices: { number }?,
	OriginX: number?,
	OriginY: number?,
}

local slots: { [number]: NativeSlot } = {
	[0] = { Id = 0, SourceLine = 104, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "wfb2" },
	[1] = { Id = 1, SourceLine = 106, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "new wfb(new int[]{40,0,0,40,-40,0,0,-40},0,0)", Vertices = { 40, 0, 0, 40, -40, 0, 0, -40 }, OriginX = 0, OriginY = 0 },
	[2] = { Id = 2, SourceLine = 113, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "new wfb(new int[]{10,0,0,10,-10,0,0,-10},0,0)", Vertices = { 10, 0, 0, 10, -10, 0, 0, -10 }, OriginX = 0, OriginY = 0 },
	[3] = { Id = 3, SourceLine = 369, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "object" },
	[4] = { Id = 4, SourceLine = 383, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "object" },
	[5] = { Id = 5, SourceLine = 393, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "object" },
	[6] = { Id = 6, SourceLine = 405, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "object" },
	[7] = { Id = 7, SourceLine = 416, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "object" },
	[8] = { Id = 8, SourceLine = 427, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "object" },
	[9] = { Id = 9, SourceLine = 440, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "object" },
	[10] = { Id = 10, SourceLine = 453, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "object" },
	[11] = { Id = 11, SourceLine = 462, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "object" },
	[12] = { Id = 12, SourceLine = 122, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "wfb2" },
	[13] = { Id = 13, SourceLine = 127, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "wfb2" },
	[14] = { Id = 14, SourceLine = 135, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "new wfb(new int[]{2,-1,2,1,-2,0},-2,0)", Behavior = "weapon=11", Vertices = { 2, -1, 2, 1, -2, 0 }, OriginX = -2, OriginY = 0 },
	[15] = { Id = 15, SourceLine = 139, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "new wfb(new int[]{5,-1,5,1,-5,3,-5,-3},-5,0)", Behavior = "weapon=0", Vertices = { 5, -1, 5, 1, -5, 3, -5, -3 }, OriginX = -5, OriginY = 0 },
	[16] = { Id = 16, SourceLine = 143, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "new wfb(new int[]{10,-3,10,3,-10,1,-10,-1},-10,0)", Behavior = "weapon=3", Vertices = { 10, -3, 10, 3, -10, 1, -10, -1 }, OriginX = -10, OriginY = 0 },
	[17] = { Id = 17, SourceLine = 152, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "new wfb(new int[]{10,-5,10,5,-10,3,-10,-3},-10,0)", Behavior = "weapon=1", Vertices = { 10, -5, 10, 5, -10, 3, -10, -3 }, OriginX = -10, OriginY = 0 },
	[18] = { Id = 18, SourceLine = 341, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "object", Behavior = "weapon=2" },
	[19] = { Id = 19, SourceLine = 155, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "new wfb(new int[]{40,5,-40,5,-40,-5,40,-5},-35,0)", Behavior = "generic=kma", Vertices = { 40, 5, -40, 5, -40, -5, 40, -5 }, OriginX = -35, OriginY = 0 },
	[20] = { Id = 20, SourceLine = 158, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "new wfb(new int[]{20,5,-20,5,-20,-5,20,-5},-15,0)", Behavior = "generic=kma", Vertices = { 20, 5, -20, 5, -20, -5, 20, -5 }, OriginX = -15, OriginY = 0 },
	[21] = { Id = 21, SourceLine = 491, DefinitionKind = "GENERATED_EXPRESSION", Initializer = "jba.a(...)" },
	[22] = { Id = 22, SourceLine = 481, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "new wfb((int[])object,0,0)" },
	[23] = { Id = 23, SourceLine = 166, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "new wfb(new int[]{3,-3,3,3,-3,1,-3,-1},-3,0)", Behavior = "weapon=4", Vertices = { 3, -3, 3, 3, -3, 1, -3, -1 }, OriginX = -3, OriginY = 0 },
	[24] = { Id = 24, SourceLine = 170, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "new wfb(new int[]{4,-1,4,1,-4,1,-4,-1},-4,0)", Behavior = "weapon=6", Vertices = { 4, -1, 4, 1, -4, 1, -4, -1 }, OriginX = -4, OriginY = 0 },
	[25] = { Id = 25, SourceLine = 174, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "new wfb(new int[]{8,-1,8,1,-8,2,-8,-2},-8,0)", Behavior = "weapon=7", Vertices = { 8, -1, 8, 1, -8, 2, -8, -2 }, OriginX = -8, OriginY = 0 },
	[26] = { Id = 26, SourceLine = 181, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "new wfb(new int[]{6,-4,6,4,-6,3,-6,-3},-6,0)", Behavior = "grapple", Vertices = { 6, -4, 6, 4, -6, 3, -6, -3 }, OriginX = -6, OriginY = 0 },
	[27] = { Id = 27, SourceLine = 147, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "new wfb(new int[]{8,-3,8,3,-8,1,-8,-1},-8,0)", Behavior = "weapon=8", Vertices = { 8, -3, 8, 3, -8, 1, -8, -1 }, OriginX = -8, OriginY = 0 },
	[28] = { Id = 28, SourceLine = 186, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "new wfb(new int[]{3,-3,3,3,-3,3,-3,-3},0,0)", Vertices = { 3, -3, 3, 3, -3, 3, -3, -3 }, OriginX = 0, OriginY = 0 },
	[29] = { Id = 29, SourceLine = 161, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "new wfb(new int[]{5,-5,5,5,-5,5,-5,-5},-5,0)", Vertices = { 5, -5, 5, 5, -5, 5, -5, -5 }, OriginX = -5, OriginY = 0 },
	[30] = { Id = 30, SourceLine = 222, DefinitionKind = "GENERATED_EXPRESSION", Initializer = "new wfb(new int[]{n6,0,-n6,n5,-n6,-n5},-n6,0)" },
	[31] = { Id = 31, SourceLine = 235, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "wfb3" },
	[32] = { Id = 32, SourceLine = 243, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "object" },
	[33] = { Id = 33, SourceLine = 267, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "object" },
	[34] = { Id = 34, SourceLine = 277, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "object2" },
	[35] = { Id = 35, SourceLine = 286, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "object" },
	[36] = { Id = 36, SourceLine = 297, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "object" },
	[37] = { Id = 37, SourceLine = 258, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "object" },
	[38] = { Id = 38, SourceLine = 317, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "object" },
	[39] = { Id = 39, SourceLine = 325, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "object" },
	[40] = { Id = 40, SourceLine = 251, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "object" },
	[41] = { Id = 41, SourceLine = 333, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "object" },
	[42] = { Id = 42, SourceLine = 188, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "new wfb(new int[]{5,-8,5,8,-5,5,-5,-5},-5,0)", Vertices = { 5, -8, 5, 8, -5, 5, -5, -5 }, OriginX = -5, OriginY = 0 },
	[43] = { Id = 43, SourceLine = 193, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "new wfb(new int[]{3,-1,3,1,-3,1,-3,-1},-3,0)", Behavior = "weapon=9", Vertices = { 3, -1, 3, 1, -3, 1, -3, -1 }, OriginX = -3, OriginY = 0 },
	[44] = { Id = 44, SourceLine = 197, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "new wfb(new int[]{3,-3,3,3,-3,5,-3,-5},-3,0)", Behavior = "weapon=10", Vertices = { 3, -3, 3, 3, -3, 5, -3, -5 }, OriginX = -3, OriginY = 0 },
	[45] = { Id = 45, SourceLine = 357, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "object" },
	[46] = { Id = 46, SourceLine = 134, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "wfb2" },
	[47] = { Id = 47, SourceLine = 202, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "new wfb(new int[]{20,-18,20,18,-11,18,-11,5,-20,5,-20,-5,-11,-5,-11,-18},-20,0)", Vertices = { 20, -18, 20, 18, -11, 18, -11, 5, -20, 5, -20, -5, -11, -5, -11, -18 }, OriginX = -20, OriginY = 0 },
	[48] = { Id = 48, SourceLine = 492, DefinitionKind = "GENERATED_EXPRESSION", Initializer = "jba.a(...)" },
	[49] = { Id = 49, SourceLine = 493, DefinitionKind = "GENERATED_EXPRESSION", Initializer = "jba.a(...)" },
	[50] = { Id = 50, SourceLine = 494, DefinitionKind = "GENERATED_EXPRESSION", Initializer = "jba.a(...)" },
	[51] = { Id = 51, SourceLine = 307, DefinitionKind = "DIRECT_OR_OBJECT_REFERENCE", Initializer = "object" },
	[52] = { Id = 52, SourceLine = 495, DefinitionKind = "GENERATED_EXPRESSION", Initializer = "jba.a(...)" },
	[53] = { Id = 53, SourceLine = 496, DefinitionKind = "GENERATED_EXPRESSION", Initializer = "jba.a(...)" },
	[54] = { Id = 54, SourceLine = 497, DefinitionKind = "GENERATED_EXPRESSION", Initializer = "jba.a(...)" },
	[55] = { Id = 55, SourceLine = 498, DefinitionKind = "GENERATED_EXPRESSION", Initializer = "jba.a(...)" },
}

local NativeComponentCatalog = {}

function NativeComponentCatalog.Get(id: number): NativeSlot?
	return slots[id]
end

function NativeComponentCatalog.All(): {[number]: NativeSlot}
	return table.clone(slots)
end

function NativeComponentCatalog.Count(): number
	local count = 0
	for _ in pairs(slots) do count += 1 end
	return count
end

function NativeComponentCatalog.IsComplete(): boolean
	if NativeComponentCatalog.Count() ~= 56 then return false end
	for id = 0, 55 do
		if slots[id] == nil then return false end
	end
	return true
end

return NativeComponentCatalog
