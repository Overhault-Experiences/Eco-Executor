--note: this is a package

local Version, __meta = {
	Build = 5
}, {}

function __meta:__newindex(key, val)
	return error("Version."..key.." = "..val..":"..debug.info(2,"l").." attempt to modify a readonly table", 0)
end

table.freeze(__meta)

function Version:CheckVersion(CurrentVersion: string)
	if self ~= Version then error("Expected `:` not `.` calling member function CheckVersion", 0) end
	if typeof(CurrentVersion) ~= "number" then return error("Expected typeof(number), but instead typeof("..typeof(CurrentVersion)..") was passed.",0) end
	
	if CurrentVersion < self.Build then
		return warn("The current version of the Eco Executor is outdated (Latest: V0.0."..self.Build.." | Current: V0.0."..CurrentVersion..")")
	end
end

return table.freeze(setmetatable(Version, __meta))