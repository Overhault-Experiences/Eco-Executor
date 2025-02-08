script.Parent = nil
local real_script = script
script, _G, shared = nil

local pipe = real_script:WaitForChild("Pipe")

function pipe.OnInvoke(name: string, a: any, ...)
	if name == "IS_READY" then
		return true
	elseif name == "PARENT" then
		real_script.Parent = a
	elseif name == "EXEC_FUNC" then
		return a(...)
	elseif name == "REFLECT" then
		return ...
	end
end