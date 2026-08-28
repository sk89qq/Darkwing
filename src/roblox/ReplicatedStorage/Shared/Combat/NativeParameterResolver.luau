--!strict
--[=[
	NativeParameterResolver

	Single runtime authority for source-confirmed Void Hunters native parameters.
	NativeGameplayConfig is the complete 235-key source-resolved default vector.
	This resolver exposes those values without silently falling back to Roblox or
	prototype tuning. Consumer-specific unit conversion belongs outside this
	module and must remain explicitly documented.
]=]

local NativeGameplayConfig = require(script.Parent:WaitForChild("NativeGameplayConfig"))

local NativeParameterResolver = {}

export type Result = {
	Value: any,
	NativeKey: string,
	Status: "RESOLVED" | "MISSING_NATIVE_VALUE",
}

local values: { [string]: any } = {}
local provenance: { [string]: string } = {}

for nativeKey, value in pairs(NativeGameplayConfig) do
	values[nativeKey] = value
	provenance[nativeKey] = "VOIDA/DEFINITIVE_VALUES/native_configuration_values.csv"
end

function NativeParameterResolver.Set(nativeKey: string, value: any, source: string)
	assert(typeof(nativeKey) == "string" and nativeKey ~= "", "native parameter key required")
	assert(typeof(source) == "string" and source ~= "", "native parameter source required")
	values[nativeKey] = value
	provenance[nativeKey] = source
end

function NativeParameterResolver.Resolve(nativeKey: string): Result
	if values[nativeKey] == nil then
		return {
			Value = nil,
			NativeKey = nativeKey,
			Status = "MISSING_NATIVE_VALUE",
		}
	end

	return {
		Value = values[nativeKey],
		NativeKey = nativeKey,
		Status = "RESOLVED",
	}
end

function NativeParameterResolver.GetProvenance(nativeKey: string): string?
	return provenance[nativeKey]
end

function NativeParameterResolver.Has(nativeKey: string): boolean
	return values[nativeKey] ~= nil
end

function NativeParameterResolver.Get(nativeKey: string): any
	local result = NativeParameterResolver.Resolve(nativeKey)
	assert(result.Status == "RESOLVED", "missing native parameter: " .. nativeKey)
	return result.Value
end

function NativeParameterResolver.GetAll(): { [string]: any }
	local snapshot: { [string]: any } = {}
	for nativeKey, value in pairs(values) do
		snapshot[nativeKey] = value
	end
	return snapshot
end

return NativeParameterResolver
