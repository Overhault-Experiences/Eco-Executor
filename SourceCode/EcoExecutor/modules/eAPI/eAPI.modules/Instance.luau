local instance_map = {}
local proxy_map = {}

local Instance = {
	instance_map = instance_map,
	proxy_map = proxy_map,
	
	custom_behaviour = {}
}

local function filter(a: any)
	if type(a) == "table" then
		local clone = {}
		
		for i, v in pairs(a) do
			clone[filter(i)] = filter(v)
		end
		
		return clone
	elseif typeof(a) == "Instance" then
		return Instance.new(a)
	elseif type(a) == "function" then
		return function(...)
			local self = ...
			local varargs = table.move({...}, 2, #({...}), 1, {})
			local filtered_varargs = {}
			
			for i, v in varargs do
				if type(v) == "table" then
					for i2, v2 in pairs(v) do
						v[i2] = instance_map[v2] or v2
					end
				end
				
				filtered_varargs[i] = instance_map[v] or v
			end
			
			local args = {instance_map[self] or self, unpack(filtered_varargs)}
			local filtered = filter(a(unpack(args)))
			return filtered
		end
	end
	
	return a
end

function Instance:__index(...)
	local self = instance_map[self]
	local custom_behaviour = Instance.custom_behaviour
	for class, behaviour in custom_behaviour do
		local success, value = pcall(function(...)
			if typeof(class) == "Instance" then
				if self:IsA(class.ClassName) and behaviour[...] then
					return behaviour[...]
				end
			else
				if self:IsA(class) and behaviour[...] then
					return behaviour[...]
				end
			end
			
		end, ...)
		
		if success and value then
			return value
		elseif value then
			if value:find(class) then
				return behaviour[...]
			end
		end
	end
	
	return filter(self[...])
end

function Instance:__newindex(...)
	local key, value = ...
	
	local custom_behaviour = Instance.custom_behaviour
	for class, behaviour in custom_behaviour do
		local index = behaviour[key]
		
		if typeof(class) == "Instance" then
			if self:IsA(class.ClassName) and index and typeof(index) ~= "function" then
				behaviour[key] = value
			end
		else
			if self:IsA(class) and index and typeof(index) ~= "function" then
				behaviour[key] = value
			end
		end
	end
	
	(instance_map[self] or self)[key] = instance_map[value] or value
end

function Instance:__tostring(...)
	local self = instance_map[self]
	local success, value = pcall(function()
		return self.Name
	end)
	
	if success then
		return value
	else
		return "Instance"
	end
end

Instance.__type = "Instance"
Instance.__metatable = "The metatable is locked"

function Instance.new(onion: Instance): Instance
	if proxy_map[onion] then
		return proxy_map[onion]
	end
	
	local proxy = newproxy(true)
	local mt = getmetatable(proxy)
	
	for i, v in Instance do
		mt[i] = v
	end
	
	instance_map[proxy] = onion
	proxy_map[onion] = proxy
	
	return proxy
end

return Instance