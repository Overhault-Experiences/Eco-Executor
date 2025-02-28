--note: this is a package

local Version, __meta = {
	Version = "V0.0.4"
}, {}

function __meta:__newindex(key, val)
	return error("Version."..key.." = "..val..":"..debug.info(2,"l").." attempt to modify a readonly table", 0)
end

table.freeze(__meta)

function Version:CheckVersion(CurrentVersion: string)
	if self ~= Version then error("Expected `:` not `.` calling member function CheckVersion", 0) end
	if self.Version ~= CurrentVersion then
		return warn("The current version of the Eco Executor is outdated (Latest: "..Version.Version.." | Current: "..CurrentVersion..")")
	end
end

return table.freeze(setmetatable(Version, __meta))