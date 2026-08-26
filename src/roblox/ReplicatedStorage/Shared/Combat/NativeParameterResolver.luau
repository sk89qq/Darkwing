--[=[
	NativeParameterResolver

	Maps source-confirmed Void Hunters parameter keys to an explicit runtime
	configuration table. A missing native value is a hard lookup miss; this
	module never silently substitutes a Roblox/prototype value.
]=]

local NativeParameterResolver = {}

export type Result = {
	Value: any,
	NativeKey: string,
	Status: "RESOLVED" | "MISSING_NATIVE_VALUE",
}

local values: { [string]: any } = {}
local provenance: { [string]: string } = {}

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

return NativeParameterResolver
