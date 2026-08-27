--!strict
-- NativeTrigTable
--
-- Source: voidhunters_decompiled/kra.java static initializer.
-- RAW-DIRECT reference table contains 2049 entries:
--   kra.a[i] = round(65536 * sin(pi * i / 4096)), i=0..2048
--
-- Exhaustive comparison against the recovered literal table produced zero
-- mismatches. The table is therefore generated from the exact recovered
-- construction rather than carrying a large duplicated literal blob.

local NativeTrigTable: {number} = table.create(2049)

for i = 0, 2048 do
	NativeTrigTable[i + 1] = math.round(65536 * math.sin(math.pi * i / 4096))
end

local function maskAngle(angleUnits: number): number
	return bit32.band(angleUnits, 0x1FFF)
end

-- Exact fc.a() mapping used by aqa for the native X component.
function NativeTrigTable.GetForceXComponent(angleUnits: number): number
	local n = maskAngle(angleUnits)
	if n < 4096 then
		if n < 2048 then
			return NativeTrigTable[2049 - n]
		end
		return -NativeTrigTable[n - 2048 + 1]
	end
	if n >= 6144 then
		return -NativeTrigTable[n - 6144 + 1]
	end
	return NativeTrigTable[8192 - n + 1]
end

-- Exact eu.a() mapping used by aqa for the native Z component.
function NativeTrigTable.GetForceZComponent(angleUnits: number): number
	local n = maskAngle(angleUnits)
	if n < 4096 then
		if n < 2048 then
			return NativeTrigTable[n + 1]
		end
		return NativeTrigTable[4096 - n + 1]
	end
	if n >= 6144 then
		return -NativeTrigTable[8192 - n + 1]
	end
	return -NativeTrigTable[n - 4096 + 1]
end

return NativeTrigTable
