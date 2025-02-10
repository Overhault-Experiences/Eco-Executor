local setmetatable = setmetatable
local pcall = pcall
local table = table
local debug = debug
local string = string
local coroutine = coroutine
local require = require
local setfenv = setfenv
local getfenv = getfenv
local task = task

local main = shared.___.___.___
local fflags = require(script:WaitForChild("FFlags"))
local lockedinstances = {}
local remoteconnections = {}
local restrictedinstances = {}
local _restrictedinstances = {}
local script = script
local rconsole_colours = {
	["@@BLACK@@"] = Color3.new(0,0,0),
	["@@BLUE@@"] = Color3.new(0.0705882, 0.0941176, 0.529412),
	["@@GREEN@@"] = Color3.new(0.0392157, 0.301961, 0.0117647),
	["@@CYAN@@"] = Color3.new(0.0941176, 0.486275, 0.4),
	["@@RED@@"] = Color3.new(0.415686, 0, 0.00784314),
	["@@MAGENTA@@"] = Color3.new(0.494118, 0, 0.494118),
	["@@BROWN@@"] = Color3.new(0.294118, 0.188235, 0.133333),
	["@@LIGHT_GRAY@@"] = Color3.new(0.505882, 0.505882, 0.505882),
	["@@DARK_GRAY@@"] = Color3.new(0.25, 0.25, 0.25),
	["@@LIGHT_BLUE@@"] = Color3.new(0.0823529, 0.784314, 1),
	["@@LIGHT_GREEN@@"] = Color3.new(0.0313725, 1, 0.176471),
	["@@LIGHT_CYAN@@"] = Color3.new(0.129412, 1, 0.854902),
	["@@LIGHT_RED@@"] = Color3.new(1, 0, 0.0313725),
	["@@LIGHT_MAGENTA@@"] = Color3.new(1, 0, 1),
	["@@YELLOW@@"] = Color3.new(1, 0.968627, 0),
	["@@WHITE@@"] = Color3.new(1, 1, 1),
	
}
local current_rconsole = rconsole_colours["@@WHITE@@"]
local core_gui = game:GetService("CoreGui")
local rrs = shared.___.___.memory.RobloxReplicatedStorage
local services = require("./services")

local function lock(_instance:Instance,_parent)
	local c = true
	local _type = 0
	
	for index,int in pairs(lockedinstances) do
		if _instance:IsDescendantOf(int) then
			_type = 1
		end
	end
	
	if _type == 0 then
		local function __()
			while task.wait() and c == true do
				_instance.Parent = _parent
			end
		end
		task.spawn(__)

		local function _t()
			c = false
			_instance = _instance:Clone()
			_instance.Parent = _parent
			_instance.Destroying:Connect(_t)
			c = true
			task.spawn(__)
		end

		local __s,__r = pcall(function()
			_instance.Destroying:Connect(_t)
		end)
		table.insert(lockedinstances,_instance)
		for _,v in _instance:GetDescendants() do
			task.spawn(lock,v,v.Parent)
		end
	else
		local function __()
			while task.wait() and c == true do
				_instance.Parent = _parent
			end
		end
		task.spawn(__)

		local function _t()
			c = false
			_instance = _instance:Clone()
			_instance.Parent = _parent
			_instance.Destroying:Connect(_t)
			c = true
			task.spawn(__)
		end

		local __s,__r = pcall(function()
			_instance.Destroying:Connect(_t)
		end)
	end
end

local function _cclosure(f: _function)
	return coroutine.wrap(function(...)
		while true do
			coroutine.yield(f(...))
		end
	end)
end

type userdata = {}
type _function = (...any) -> (...any)

local eAPI = {
    environment = {
		crypt = {
			url = {},
			custom = {},
			hex = {},
			base64 = {}
		},
		debug = {},
		cache = {},
		oth = {},
		rnet = {},
		base64 = {},
		http = {}
	},
	
	original_fenvs = {},
	environments = {},
	scopes = {},
	global_count = 0
}

function eAPI.load_fflags(new_fflags: {string: any})
	fflags = new_fflags
end

eAPI.environment.crypto = eAPI.environment.crypt

function eAPI.cache(f: _function)
    return setmetatable({}, {
        __index = function(self, key)
            local value = f(key)

            self[key] = value
            return value
        end
    })
end

function eAPI.load(scope: () -> ()?)
	scope = scope or debug.info(2, "f")
	
	local environment = getfenv(scope)
	
	table.insert(eAPI.scopes, scope)
	table.insert(eAPI.environments, environment)
	
	for i, v in eAPI.environment do
		if type(v) == "table" then
			if not v.__NOFREEZE then
				pcall(table.freeze, v)
			else
				v.__NOFREEZE = nil
			end
		end
		
		environment[i] = v
	end
end

eAPI.service = eAPI.cache(function(service_name)
    return game:GetService(service_name)
end)

do
	local libraries = script:WaitForChild("Libraries")
	eAPI.library = eAPI.cache(function(module_name)
		return require(libraries:FindFirstChild(module_name))
	end)

	local modules = script:WaitForChild("Modules")
	eAPI.module = eAPI.cache(function(module_name)
		return require(modules:FindFirstChild(module_name))
	end)
end

--adds a global function to the requirer
function eAPI.addGlobal(names: {string}, value: any, libraries: {any}?)
	eAPI.global_count += 1
	
	for _, library in libraries or {eAPI.environment} do
		for _, name in names do
            library[name] = value
        end
	end
end

local type_check = eAPI.library.TypeChecking.type_check
local add_global, library, module, environment, service, scopes, environments = eAPI.addGlobal, eAPI.library, eAPI.module, eAPI.environment, eAPI.service, eAPI.scopes, eAPI.environments
local instance = module.Instance

local player: Player = service.Players.LocalPlayer

local http_get

local get_properties do
	local class_data = {}
	local properties = module.Properties
	
	for _, class in properties.Classes do
		class_data[class.Name] = class.Members
	end

	function get_properties(obj)
		local properties = {}

		for class, members in class_data do
			if obj:IsA(class) then
				for _, property in members do
					pcall(function()
						properties[property.Name] = obj[property.Name]
					end)
				end
			end
		end

		return properties
	end
end

local function type_check_instance(num: number, obj: Instance | any, preferred_class: string?)
	preferred_class = preferred_class or "Instance"

	if fflags.bool_instance_wrapping then
		obj = module.Instance.instance_map[obj] or obj
	end

	if typeof(obj) ~= "Instance" then
		error(("invalid argument %d (expected Instance, got %s)"):format(num, typeof(obj)), 0)
	elseif typeof(obj) == "Instance" and not obj:IsA(preferred_class) then
		error(("invalid argument %d (expected %s, got %s)"):format(num, preferred_class, obj.ClassName), 0)
	end
end

local function checkinstance_exist(targetInstance) : Instance
	local status
	if typeof(targetInstance) == "string" then
		status = game:FindFirstChild(targetInstance,true)
	else
		status = game:FindFirstChild(targetInstance.Name,true)
	end
	return status
end

local function random(length: number, a: number?, b: number?)
	local result = ""

	for _ = 1, length do
		result ..= string.char(math.random(a or 0, b or 255))
	end

	return result
end

local function setreadonly(obj, value)
	local mt = getmetatable(obj)
	
	if mt and type(mt) == "table" then
		if value == true then
			mt.__oldindex = mt.__newindex
			mt.__newindex = _cclosure(function() error("attempt to modify a readonly table", 0) end)
		else
			if mt.__oldindex then
				mt.__newindex = mt.__oldindex
				mt.__oldindex = nil
			elseif mt.__readonly then
				mt.__newindex = nil
				mt.__readonly = nil
			end
		end
	elseif not mt then
		setmetatable(obj, {
			__newindex = _cclosure(function() error("attempt to modify a readonly table", 0) end),
			__readonly = true
		})
	else
		error("unable to safely freeze table")
	end
end


local vLuau_settings = {
	vectorCtor = function() error("vectorCtor was not provided",0) end,
	vectorSize = 4,
	useNativeNamecall = false,
	namecallHandler = function() error("Native __namecall handler was not provided",0) end,
	extensions = eAPI.environment,
	callHooks = {},
	errorHandling = false,
	generalizedIteration = true,
	allowProxyErrors = false,
	useImportConstants = false,
	staticEnvironment = {},
	decodeOp = function(op) return op end
}

local proxy_daemon do
	local proxy = script:WaitForChild("Proxy",math.huge)
	local pipe = proxy:WaitForChild("Pipe",math.huge)
	
	proxy.Parent = game:GetService("ReplicatedFirst")
	
	while not pipe:Invoke("IS_READY") do
		task.wait()
	end
	
	proxy_daemon = pipe
end

do
	local instances = {}
	
	local function register_instance(obj: Instance)
		if not table.find(instances, obj) then
			table.insert(instances, obj)
		end
	end
	
	game.DescendantAdded:Connect(register_instance)
	game.DescendantRemoving:Connect(register_instance)
	
	for _, instance in game:GetDescendants() do
		register_instance(instance)
	end
	
	add_global({"getinstances", "get_instances"}, function(): {Instance}
		return table.clone(instances)
	end)

	add_global({"getscripts", "get_scripts"}, function(): {LuaSourceContainer}
		local scripts = {}

		for _, instance in instances do
			pcall(function()
				if instance:IsA("BaseScript") then
					table.insert(scripts, instance)
				end
			end)
		end

		return scripts
	end)
	
	add_global({"getmodules", "get_modules"}, function(): {ModuleScript}
		local modules = {}

		for _, instance in instances do
			pcall(function()
				if instance:IsA("ModuleScript") then
					table.insert(modules, instance)
				end
			end)
		end

		return modules
	end)
	
	add_global({"getloadedmodules", "get_loaded_modules"}, function(): {ModuleScript}
		return environment.getmodules()
	end)
	
	add_global({"getscripthash", "get_script_hash"}, function(script: BaseScript)
		type_check_instance(1, module, "BaseScript")
		
		return library.HashLib.sha256((table.find(instances, module) or -1) .. module:GetFullName())
	end)
	
	add_global({"getrunningscripts", "get_running_scripts"}, function(): {BaseScript}
		local scripts = environment.getscripts()
		local running_scripts = {}
		
		local run_check = Instance.new("Folder")
		
		local function is_destroyed(script)
			if script.Parent == nil then
				local parent_unlocked = pcall(function()
					script.Parent = run_check
					script.Parent = nil
				end)
				
				return parent_unlocked
			end
			
			return false
		end
		
		for _, script: BaseScript in scripts do
			if not is_destroyed(script) and script.Enabled and not script.Disabled then
				table.insert(running_scripts, script)
			end
		end
		
		return running_scripts
	end)
	
	add_global({"fireproximityprompt", "fire_proximity_prompt"}, function(prompt: ProximityPrompt, amount: number?, skip: boolean?)
		type_check_instance(1, prompt, "ProximityPrompt")
		
		type_check(2, amount, {"number"}, true)
		type_check(3, skip, {"boolean"}, true)
		
		amount = amount or 1
		skip = skip or false
		
		local hold_duration = prompt.HoldDuration
		
		if skip then
			prompt.HoldDuration = 0
		end
		
		for _ = 1, amount do
			prompt:InputHoldBegin()
			
			if not skip then
				task.wait(hold_duration)
			end
			
			prompt:InputHoldEnd()
		end
		
		if skip then
			prompt.HoldDuration = hold_duration
		end
	end)
	
	local active_touches = {}
	
	add_global({"firetouchinterest", "fire_touch_interest", "fake_touch", "faketouch"}, function(toucher: BasePart, touch_interest: TouchTransmitter, toggle: number)
		type_check_instance(1, toucher, "BasePart")
		type_check_instance(2, touch_interest, "TouchTransmitter")
		type_check(3, toggle, {"number"})
		
		local toggle_boolean = (toggle == 0 and true) or (toggle == 1 and false)
		
		local transmitter_parent = touch_interest.Parent
		if not transmitter_parent or (transmitter_parent and not transmitter_parent:IsA("BasePart")) then
			error("invalid touch transmitter", 0)
		end
		
		local transmitter_position = transmitter_parent.CFrame
		local old_toucher_position = toucher.CFrame
		
		if toggle_boolean then
			active_touches[toucher] = touch_interest
			
			task.spawn(function()
				while active_touches[toucher] do
					toucher.CFrame = transmitter_position
					
					task.wait()
					
					toucher.CFrame = old_toucher_position
				end
			end)
		else
			active_touches[toucher] = nil
			
			task.defer(function()
				toucher.CFrame = old_toucher_position
			end)
		end
	end)
end

-- // Eco Executor APIs \\

do
	add_global({"setscriptsource","setsource"},function(ts,ns)
		if typeof(ts) ~= "userdata" then
			warn("Invalid argument #1 : Argument #1 expects a userdata, but "..typeof(ts).." was passed")
			return
		elseif typeof(ns) ~= "string" then
			warn("Invalid argument #2 : Argument #2 expects a source typeof(string), but "..typeof(ns).." was passed")
			return
		end
		local ts = game:FindFirstChild(ts.Name,true)
		
		if ts.ClassName ~= "LocalScript" and ts.ClassName ~= "ModuleScript" then
			warn("Invalid argument #1 : Argument #1 expects a local script or module script class, but "..ts.ClassName.." class was passed")
			return
		elseif ts.ClassName == "Script" then
			warn("Cannot edit source of an LuaSourceContainer within classname script")
			return
		end
		
		local _os = ts.Source
		ts.Source = ns
		ts.Disabled=true;ts.Disabled=false
		
		return _os
	end)

	add_global({"lockinstance"},function(int)
		if int == nil then warn("Passed value is nil") return end
		local _s,int = pcall(function()
			return game:FindFirstChild(int.Name,true)
		end)
		if not _s then
			warn("Passed value is not an instance")
			return
		else
			if int.Parent == game and game:FindService(int.ClassName) ~= nil then
				warn("Cannot lock instance called service : "..int.ClassName)
				return
			elseif int == game then
				warn("Cannot lock instance called data model")
				return
			end
		end
		if table.find(lockedinstances,int) then
			warn("Instance already locked")
			return
		end
		lock(int,int.Parent)
	end)

	add_global({"getlockedinstances"},function()
		return table.clone(lockedinstances)
	end)

	add_global({"restrictinstance","rinstance"},function(_int)
		if _int == nil then warn("Passed value is nil") return end
		local _s,int = pcall(function()
			return game:FindFirstChild(_int.Name,true)
		end)
		if not _s and typeof(int) ~= "Instance" then
			warn("Passed value is not an instance")
			return
		end
		if table.find(restrictedinstances,int) then
			warn("Instance was already restriced!")
			return
		end
		int.Archivable = false
		local c
		c = int.DescendantAdded:Connect(function(des)
			des:Destroy()
		end)
		table.insert(restrictedinstances,int)
		table.insert(_restrictedinstances,{Instance = int,Connection = c})
	end)

	add_global({"freeinstance"},function(_int)
		if _int == nil then warn("Passed value is nil") return end
		local _s,int = pcall(function()
			return game:FindFirstChild(_int.Name,true)
		end)
		if not _s and typeof(int) ~= "Instance" then
			warn("Passed value is not an instance")
			return
		else
			if int == game then
				warn("Cannot restrict instance called data model")
				return
			end
		end
		if not table.find(restrictedinstances,int) then
			warn("Instance was already freed!")
			return
		end
		for index,content in pairs(_restrictedinstances) do
			for __index,int in pairs(restrictedinstances) do
				if int == content.Instance then
					content.Instance.Archivable = true
					content.Connection:Disconnect()
					table.remove(restrictedinstances,__index)
					table.remove(_restrictedinstances,index)
				end
			end
		end
	end)

	add_global({"getrestrictedinstances","getrestricts","getrestricted"},function()
		local t = table.clone(restrictedinstances)
		return t
	end)

	add_global({"getnilinstances", "get_nil_instances", "getnils"},function()
		local nils = shared.___.___.getnils()
		
		for index,int in nils do	
			if instance.proxy_map[int] and instance.proxy_map[int].Name == "RobloxReplicatedStorage" then
				nils[index] = nil
			end
		end
		
		return nils
	end)

	add_global({"saveinstance"},function(_int, ...)
		if _int == nil then warn("Passed value is nil") return end
		
		local _s,int = pcall(function()
			return game:FindFirstChild(_int.Name,true)
		end)
		
		if not _s and typeof(int) ~= "Instance" then
			warn("Passed value is not an instance")
			return
		else
			if _int == nil then
				return
			else
				if int.Parent == game and int.ClassName == int.Name then
					warn("Cannot save an instance called service (attempted to saveinstance on "..int.Name..")")
					return
				end
			end
		end
		
		local InstanceService = require(script.Modules.InstanceService)
		local data = InstanceService:ConvertToTable(int)
		
		services.ReplicatedStorage:WaitForChild("IS",math.huge):InvokeServer("___1___","save",data)
	end)

	add_global({"loadinstance"},function(_instancename)
		if _instancename == nil then warn("Passed value is nil") return end
		local data = service.ReplicatedStorage:InvokeServer("___1___","request",_instancename)
		
		if data then
			local InstanceService = require(script.Modules.InstanceService)
			local instance = InstanceService:ConvertToInstance(data)
			return instance
		end
	end)

	add_global({"getsavedinstances"}, function()
		local data = service.ReplicatedStorage:InvokeServer("___1___","request_saves")
		return data
	end)

	add_global({"reset_savedinstances","resetsaves"},function()
		service.ReplicatedStorage:InvokeServer("___1___","reset_saves")
	end)

	add_global({"parentinstance"},function(_i,_p)
		local _parent = checkinstance_exist(_p)
		if _parent == nil then
			warn("Argument #2 : Instance does not exist.")
			return
		end
		
		pcall(function()
			repeat
				_i.Parent = _parent
				task.wait()
			until _i.Parent == _parent
		end)
		
		return _i
	end)
	-- rconsole functions support
	do
		add_global({"rconsoleprint"},function(send)
			local status
			if tostring(send) == nil then return end
			local send = tostring(send)
			
			for colorname,color3 in pairs(rconsole_colours) do
				if send == colorname then
					status = 1
				end
			end
			
			if status == 1 then -- passed value is a colorname
				current_rconsole = rconsole_colours[send]
				return
			end
			
			local c = shared.___.___.components.log:Clone()
			c.TextColor3 = current_rconsole
			c.Text = send
			
			c.Parent = game:GetService("CoreGui").eco.console.logs
		end)
		
		add_global({"rconsoleinfo"},function(txt)
			if tostring(txt) == nil then return end
			local txt = tostring(txt)
			local c = shared.___.___.components.log:Clone()
			c.Text = `[`..`<font color="rgb(255, 255, 255)">*</font>`..`]: `..txt
			
			local ctext = c.Text

			c.Focused:Connect(function()
				c.Text = c.ContentText
				c:CaptureFocus()
			end)

			c.FocusLost:Connect(function()
				c.Text = ctext
			end)
			
			c.Parent = game:GetService("CoreGui").eco.console.logs
		end)
		
		add_global({"rconsolewarn"},function(txt)
			if tostring(txt) == nil then return end
			local txt = tostring(txt)
			local c = shared.___.___.components.log:Clone()
			c.Text = `[`..`<font color="rgb(238, 255, 46)">*</font>`..`]: `..txt
			local ctext = c.Text
			
			c.Focused:Connect(function()
				c.Text = c.ContentText
				c:CaptureFocus()
			end)
			
			c.FocusLost:Connect(function()
				c.Text = ctext
			end)
			
			c.Parent = game:GetService("CoreGui").eco.console.logs
		end)
		
		add_global({"rconsoleerr"},function(txt)
			if tostring(txt) == nil then return end
			local txt = tostring(txt)
			local c = shared.___.___.components.log:Clone()
			c.Text = `[`..`<font color="rgb(255, 0, 4)">*</font>`..`]: `..txt
			
			local ctext = c.Text

			c.Focused:Connect(function()
				c.Text = c.ContentText
				c:CaptureFocus()
			end)

			c.FocusLost:Connect(function()
				c.Text = ctext
			end)
			
			c.Parent = game:GetService("CoreGui").eco.console.logs
		end)
		
		add_global({"rconsoleclear"},function()
			local cs = game:GetService("CoreGui").eco.console.logs
			for _,log in cs:GetChildren() do
				if log:IsA("TextBox") then
					log:Destroy()
				end
			end
		end)
		
		add_global({"rconsolename"},function(custom_title)
			if typeof(custom_title) ~= "string" then return end
			local cn = game:GetService("CoreGui").eco.console.topbar.title
			cn.Text = custom_title
		end)
		
		add_global({"rconsoleinput","rconsoleinputasync"},function()
			local cs = game:GetService("CoreGui").eco.console.logs
			local status,c = nil,nil
			
			c = cs.ChildAdded:Connect(function(c)
				if c.Name == "input_log" then
					status = c.ContentText
					c = nil
				end
			end)
			repeat
				task.wait()
			until status ~= nil
			return status
		end)
		
		add_global({"printconsole"},function(txt, ...)
			if tostring(txt) == nil then return end
			local txt = tostring(txt)
			
			if (...) == nil then
				local c = shared.___.___.components.log:Clone()
				local cs = game:GetService("CoreGui").eco.console.logs

				c.TextColor3 = Color3.fromRGB(255,255,255)
				c.Text = txt
				c.Parent = cs
				return
			end
			
			local red,green,blue = ...
			if typeof(red) ~= "number" then return end
			if typeof(green) ~= "number" then return end
			if typeof(blue) ~= "number" then return end
			
			local c = shared.___.___.components.log:Clone()
			local cs = game:GetService("CoreGui").eco.console.logs

			c.TextColor3 = Color3.fromRGB(red,green,blue)
			c.Text = txt
			c.Parent = cs
		end)
	end
	
	add_global({"error"}, function(msg)
		error(msg, 0)
	end)
	
	add_global({"spyremote","spyr"}, function(_remote,callback)
		if _remote == nil or callback == nil then warn("Passed argument is nil") return end

		local _,remote = pcall(function()
			for _,v in game:GetDescendants() do
				if v:GetFullName() == _remote:GetFullName() then
					return v
				end
			end
		end)

		if remote == nil then warn("Attempted spying on a remote failed: The instance is nil") return end
		if typeof(callback) ~= "function" then warn("Argument #2: The current argument is not a typeof(function)") return end

		if remote.ClassName == "RemoteEvent" or remote.ClassName == "RemoteFunction" or remote.ClassName == "UnreliableRemoteEvent" then
			local IS = game:GetService("ReplicatedStorage"):WaitForChild("IS",math.huge) :: RemoteFunction
			IS:InvokeServer("___1___", "spy",remote.Name,remote:GetFullName())
			IS.OnClientInvoke = callback
			return
		elseif remote.ClassName == "BindableEvent" then
			if remoteconnections[remote] ~= nil then warn("The remote is already spied") return end
			remoteconnections[remote] = remote.Event:Connect(callback)
			return
		elseif remote.ClassName == "BindableFunction" then
			if remoteconnections[remote] ~= nil then warn("The remote is already spied") return end
			remoteconnections[remote] = remote
			remote.OnInvoke = callback
			return
		else
			warn("Current instance's classname is not a remote.")
			return
		end
	end)

	add_global({"stopspyremote","stopspyr"}, function(_remote)
		if _remote == nil then warn("Passed argument is nil") return end

		local _,remote = pcall(function()
			for _,v in game:GetDescendants() do
				if v:GetFullName() == _remote:GetFullName() then
					return v
				end
			end
		end)

		if remote == nil then warn("Attempted stop spying on a remote failed: The instance is nil") return end

		if remote.ClassName == "RemoteEvent" or remote.ClassName == "RemoteFunction" or remote.ClassName == "UnreliableRemoteEvent" then
			local IS = game:GetService("ReplicatedStorage"):WaitForChild("IS",math.huge) :: RemoteFunction
			IS:InvokeServer("___1___", "unspy",remote.Name,remote:GetFullName())
			IS.OnClientInvoke = nil
			return
		elseif remote.ClassName == "BindableEvent" then
			if remoteconnections[remote] == nil then return end
			remoteconnections[remote]:Disconnect()
			remoteconnections[remote] = nil
			return
		elseif remote.ClassName == "BindableFunction" then
			remoteconnections[remote].OnInvoke = nil
			remoteconnections[remote] = nil
		else	
			warn("Current instance's classname is not a remote.")
			return
		end
	end)

	add_global({"isremotespied","isrspied"}, function(_remote)
		if _remote == nil then warn("Passed argument is nil") return end

		local _,remote = pcall(function()
			for _,v in game:GetDescendants() do
				if v:GetFullName() == _remote:GetFullName() then
					return v
				end
			end
		end)

		if remote == nil then warn("Attempted stop spying on a remote failed: The instance is nil") return end

		if remote.ClassName == "RemoteEvent" or remote.ClassName == "RemoteFunction" or remote.ClassName == "UnreliableRemoteEvent" then
			local IS = game:GetService("ReplicatedStorage"):WaitForChild("IS",math.huge) :: RemoteFunction
			return IS:InvokeServer("___1___", "isspied",remote.Name)
		elseif remote.ClassName == "BindableEvent" or remote.ClassName == "BindableFunction" then
			return remoteconnections[remote] ~= nil
		else
			warn("Current instance's classname is not a remote.")
			return nil
		end
	end)

	add_global({"spiedremotes","getspied"}, function()
		local IS = game:GetService("ReplicatedStorage"):WaitForChild("IS",math.huge) :: RemoteFunction
		local Table = IS:InvokeServer("___1___", "spied")

		local Spied = {}
		for r,v in pairs(Table) do
			for _,vv in game:GetDescendants() do	
				if (not vv:IsA("RemoteEvent") or not vv:IsA("RemoteFunction") or not vv:IsA("UnreliableRemoteEvent")) then continue end
				if vv:GetFullName() == v then
					table.insert(Spied,vv)
				end
			end
		end

		for remote,_ in pairs(remoteconnections) do
			table.insert(Spied,remote)
		end

		return Spied
	end)
	
	do
		local path = {}

		path.to = {}
		setmetatable(path.to,{
			__index = function(self,key)
				local _int
				for _,v in game:GetDescendants() do
					if v.Name == key then
						_int = v
					end
				end
				return _int
			end,
			__metatable = "The metatable is locked",
		})
		
		path.find = function(name, classname)
			local _int
			for _,v in game:GetDescendants() do
				if v.Name == name and v.ClassName == classname then
					_int = v
				end
			end
			return _int
		end
		
		local mt = setmetatable(path,table.freeze({
			__newindex = function(self,key,value)
				warn("path."..key.." = "..value..": attempt to modify a readonly table")
				return
			end,
		}))
		
		add_global({"path"},table.freeze(path))
	end
	
	add_global({"loadmodule"},function(_m)
		
		if rrs:FindFirstChild(_m) then
			_m = rrs:FindFirstChild(_m)
		end
		
		local _n = _m:Clone()
		local _,returns =  xpcall(function() return require(_n) end, function() end)
		_n:Destroy()
		return returns
	end)
	
	add_global({"replace"}, function(a, b)
		local a = checkinstance_exist(a); local b = checkinstance_exist(b)
		a.Name = b.Name
		a.Parent = b.Parent
		
		return a
	end)
	
	add_global({"getscriptbytecode"}, function(obj)
		local int
		
		for _,v in game:GetDescendants() do
			if v:GetFullName() == obj:GetFullName() then
				int = v; break
			end
		end
		
		if int then
			
			if int.ClassName ~= "Script" and int.ClassName ~= "LocalScript" and int.ClassName ~= "ModuleScript" then
				error("The instance's classname was not a script/localscript/modulescript ("..int.ClassName..")",0)
			end
			
			return library.vLuau.luau_compile(int.Source)
		else
			if rrs:FindFirstChild(int.Name) then
				int = rrs:FindFirstChild(int.Name)
				
				if int.ClassName ~= "Script" and int.ClassName ~= "LocalScript" and int.ClassName ~= "ModuleScript" then
					error("The instance's classname was not a script/localscript/modulescript",0)
				end

				return library.vLuau.luau_compile(int.Source)
			end
		end
	end)
	
	add_global({"loadbytecode"}, function(bytecode)
		if typeof(bytecode) ~= "string" then error("Passed argument is not a typeof(string)",0) end
		
		local fenv = {}
		fenv.script = "ExecutionScript"
		fenv.shared = getfenv(2).shared.a.shared
		fenv._G = getfenv(2).shared.a._G
		
		return library.vLuau.luau_load(bytecode, fenv)
	end)
end

-- 

add_global({"info", "coutput"}, function(...)
	local log = ""
	
	for _, v in {...} do
		log ..= tostring(v) .. " "
	end
	
	service.TestService:Message(log)
end)

add_global({"isscriptable", "is_scriptable"}, function(object: Instance, property: string): boolean
	type_check_instance(1, object)
	type_check(2, property, {"string"})

	return select(1, pcall(function()
		return object[property]
	end))
end)

add_global({"isnetworkowner", "is_network_owner"}, function(part: BasePart): boolean
	type_check_instance(1, part, "BasePart")

	if not part:IsA("BasePart") then
		error(("invalid argument #1 (expected BasePart, got %s)"):format(part.ClassName))
	end

	if part.Anchored then
		return false
	end

	if part:IsDescendantOf(player.Character) then
		return true
	end

	return false
end)

add_global({"gethui", "get_hidden_ui", "gethiddenui", "get_hui"}, function()
	return instance.new(core_gui)
end)

add_global({"protect_gui"}, function(gui: Instance)
	type_check_instance(1, gui)
	
	local object = module.Instance.instance_map[gui] or gui
	
	local function rename(object: boolean)
		local base_properties = get_properties(object)
		local property_keys = {}

		for i in base_properties do
			table.insert(property_keys, i)
		end
		
		if math.random(0, 1) == 0 then
			object.Name = object.ClassName
		else
			object.Name = property_keys[math.random(1, #property_keys)]
		end
	end
	
	rename(gui)
	
	for _, child in object:GetDescendants() do
		rename(object)
	end
end)

add_global({"run_on_actor"}, function(actor: Actor, source: string, ...): boolean
	type_check_instance(1, actor, "Actor")
	
	return proxy_daemon:Invoke("EXEC_FUNC", library.vLuau(source))
end)

-- Metatable

if fflags.bool_metatable_manipulation then
	add_global({"getrawmetatable", "get_raw_metatable"}, function(obj: any): {any}
		type_check(1, obj, {"any"})

		local raw_mt = library.Metatable.get_all_L_closures(obj)

		return setmetatable({
			__tostring = _cclosure(function(self)
				return tostring(self)
			end)
		}, {
			__index = raw_mt,
			__newindex = function(_, key, value)
				local success = pcall(function()
					getmetatable(obj)[key] = value
				end)

				if not success then error("attempt to write to a protected/read-only metatable", 5) end
			end
		})
	end)
	
	add_global({"hookmetamethod"}, function(obj: any, method: string, hook: _function): _function
		type_check(1, obj, {"any"})
		type_check(2, method, {"string"})
		type_check(3, hook, {"function"}, true)

		local rmt = library.Metatable.get_all_L_closures(obj)
		local mt = getmetatable(obj)

		local old = rmt[method]
		local is_writable = pcall(function()
			mt[random(math.random(128, 512))] = nil 
		end)

		if is_writable then
			mt[method] = hook
		else
			local old_environment = getfenv(old)
			local is_hookable = pcall(setfenv, old, old_environment)
			
			if is_hookable then
				return module.Hookfunction(old, hook, old_environment)
			else
				warn("unable to hook a non-hookable metatable")
			end
		end

		return old
	end)
end

add_global({"isreadonly", "is_readonly", "is_read_only"}, function(obj: {any} | userdata): boolean
	type_check(1, obj, {"table", "userdata"})
	
	return not select(1, pcall(function()
		obj[random(math.random(128, 256))] = nil
	end))
end)

add_global({"setreadonly", "set_readonly", "set_read_only"}, function(obj: {any} | userdata, value: boolean)
	type_check(1, obj, {"table", "userdata"})
	type_check(2, value, {"boolean"})
	
	return setreadonly(obj, value)
end)

add_global({"makewriteable", "make_writable"}, function(obj: {any})
	type_check(1, obj, {"table", "userdata"})
	
	return setreadonly(obj, false)
end)

add_global({"getproperties"}, function(obj: Instance): {string}
	type_check_instance(1, obj)
	
	return get_properties(obj)
end)

-- Closures

if fflags.bool_detours then
	if fflags.bool_executor_mode and fflags.bool_fake_compatibility then
		add_global({"hookfunction_raw"}, module.Hookfunction) -- Fluxus MacOS support
	end
	
	add_global({"hookfunction", "replaceclosure", "hookfunc", "replacefunction", "replacefunc", "detourfunc", "detour_function"}, function(old: _function, new: _function?): _function
		type_check(1, old, {"function"})
		type_check(2, new, {"function"}, true)
		
		local old_environment = getfenv(old)
		eAPI.original_fenvs[old] = old_environment

		return module.Hookfunction(old, new, old_environment)
	end)

	add_global({"restorefunction", "restore_function", "restore_func", "restoreclosure", "restore_closure"}, function(f: _function)
		type_check(1, f, {"function"})

		setfenv(f, eAPI.original_fenvs[f] or getfenv(f))
		eAPI.original_fenvs[f] = nil
	end)

	add_global({"isfunctionhooked", "is_function_hooked"}, function(f: _function)
		type_check(1, f, {"function"})

		return eAPI.original_fenvs[f] ~= nil
	end)

	add_global({"emulate_call", "secure_call", "securecall"}, function(f: _function, target: LuaSourceContainer, ...): ...any
		type_check(1, f, {"function"})
		type_check_instance(2, target, "LuaSourceContainer")

		local self_env = debug.info(1, "f")
		local real_env = getfenv(self_env)

		setfenv(self_env, setmetatable({
			script = target,
			_G = _G,
			shared = shared
		}, {
			__index = real_env,
			__metatable = "This metatable is locked."
		}))

		local return_value = {f(...)}
		setfenv(self_env, real_env)

		return unpack(return_value)
	end)
end

add_global({"newcclosure", "new_c_closure"}, function(f: _function): _function
	type_check(1, f, {"function"})
	
	local c_closure = _cclosure(f)
	table.insert(scopes, c_closure)
	
	return c_closure
end)

add_global({"newlclosure", "new_l_closure"}, function(f: _function): _function
	type_check(1, f, {"function"})
	
	local l_closure = function(...)
		return f(...)
	end
	
	table.insert(scopes, l_closure)
	
	return l_closure 
end)

add_global({"iscclosure", "is_c_closure"}, function(f: _function): boolean
	type_check(1, f, {"function"})	

	return debug.info(f, "s") == "[C]"
end)

add_global({"islclosure", "is_l_closure"}, function(f: _function): boolean
	type_check(1, f, {"function"})	
	
	return debug.info(f, "s") ~= "[C]"
end)

if fflags.bool_decompiler then
	add_global({"dumpstring"}, function(source: string | _function | number): string
		type_check(1, source, {"string", "function", "number"})	

		local compile = library.vLuau.luau_compile
		if type(source) == "string" then
			return ({compile(source)})[1]
		elseif type(source) == "number" then
			source += 1
			
			if not pcall(getfenv, source) then
				error("invalid stack level", 0)
			end
			
			local stack = debug.info(source, "f")
			local decompilation = module.FunctionDecomp(stack)[1]
			local recompilation = compile(decompilation)
			
			return recompilation
		else
			if pcall(setfenv, source, getfenv(source)) then
				local decompiled = module.FunctionDecomp(source)[1]

				return ({compile(decompiled)})[1]
			else
				return "-- non-decompilable functions are not supported"
			end
		end
	end)
end

add_global({"loadstring"}, function(source: string, chunkname: string): _function
	if source == "" then return warn("Argument #1 is nil, expected typeof(string)") end
	local new = Instance.new("ModuleScript")
	
	new.Name = chunkname or service.HttpService:GenerateGUID(false)
	new.Parent = shared.___.___.memory
	
	local s = pcall(function()
		new.Source = [[
require(shared.___.___.modules.eAPI)(); local script=nil;shared.a = {["script"] = "ExecutionScript";["shared"] = {};["_G"] = {}} local function getfenv(stack) if stack == 0 then return getfenv() elseif stack == nil or stack == 1 then return shared.a else return getfenv(stack) end end; local _G = shared.a._G;  local shared = shared.a.shared
]]..source..[[ 
return {}]]
	end)
	
	if not s then
		new.Parent = service.CoreGui.RobloxGui.Modules.Common.CommonUtil
		service.ScriptEditorService:OpenScriptDocumentAsync(new)
		local sd = service.ScriptEditorService:FindScriptDocument(new)
		sd:EditTextAsync([[
require(shared.___.___.modules.eAPI)(); local script=nil;shared.a = {["script"] = "ExecutionScript";["shared"] = {};["_G"] = {}} local function getfenv(stack) if stack == 0 then return getfenv() elseif stack == nil or stack == 1 then return shared.a else return getfenv(stack) end end; local _G = shared.a._G;  local shared = shared.a.shared
]]..source..[[	

return {}]],1,1,math.huge,math.huge)
		sd:CloseAsync()
		new.Parent = shared.___.___.memory
	end
	
	return function(...)
		local any = ...
		xpcall(function()
			if any then
				require(new)(any)
			end
			require(new)
		end, function()
			return
		end)
	end
end)

add_global({"checkcaller", "issynapsethread"}, function(): boolean
	for level = 1, 200 do
		local success, env = pcall(getfenv, level)
		
		if success and table.find(environments, env) then
			return true
		end
	end
	
	return false
end)

add_global({"checkcallstack"}, function(): boolean
	local valid = true
	
	for level = 1, 200 do
		local success, env = pcall(getfenv, level)

		if success and not table.find(environments, env) then
			valid = false
		end
	end

	return valid
end)

add_global({"getcallingscript", "get_calling_script"}, function()
	local earliest_script

	for level = 1, 200 do
		local success, env = pcall(getfenv, level)

		earliest_script = (success and rawget(env, "script")) or earliest_script
	end

	return earliest_script
end)

add_global({"clonefunction", "clonefunc", "cloneclosure"}, function(f: _function): _function
	type_check(1, f, {"function"})	
	
	if debug.info(f, "s") == "[C]" then
		return _cclosure(f)
	else
		if fflags.bool_decompiler and fflags.bool_loadstring then
			local decompilation_success, decompiled = pcall(module.FunctionDecomp, f)
			
			if decompilation_success then
				local env = getfenv(2)
				
				return function(...)
					local env_injections = {}
					
					for i, v in env do
						env_injections[i] = v
					end
					
					for i, v in {...} do
						env_injections["_p"..i] = v 
					end
					
					local local_settings = library.vLuau.interpreter.luau_newsettings()
					local_settings.extensions = env_injections
					
					return library.vLuau(decompiled[1], local_settings)(...)
				end
			end
		end
		
		return function(...)
			return f(...)
		end
	end
end)

add_global({"getidentity", "getthreadcontext", "getthreadidentity", "getcontext", "get_thread_context", "get_thread_identity"}, function(): boolean
	local tests = {
		-- PluginSecurity (1)
		pcall(function()
			return game:GetJobsInfo()
		end),
		
		-- LocalUserSecurity (3)
		pcall(function()
			return workspace:ExperimentalSolverIsEnabled()
		end),
		
		-- WritePlayerSecurity (4)
		pcall(Instance.new, "Player"),
		
		-- RobloxScriptSecurity (5)
		pcall(function()
			return game:GetPlaySessionId()
		end),
		
		-- RobloxSecurity (6)
		pcall(function()
			return Instance.new("SurfaceAppearance").TexturePack
		end),
		
		-- NotAccessibleSecurity (7)
		pcall(function()
			Instance.new("MeshPart").HasJointOffset = false
		end)
	}
	
	local permission_chart = {
		{},
		-- GameScript (2)
		{ false, false, false, false, false, false },
		
		-- ElevatedGameScript (3)
		{ true, true, false, true, false, false },
		
		-- CommandBar (4)
		{ true, true, false, false, false, false },
		
		-- StudioPlugin (5)
		{ true, false, false, false, false, false },
		
		-- ElevatedStudioPlugin (6)
		{ true, true, false, true, false, false },
		
		-- COM (7)
		{ true, true, true, true, true, true },
		
		-- WebService (8)
		{ true, true, true, true, true, true },
		
		-- Replicator (9)
		{ false, false, true, true, false, false }
	}
	
	for identity = 1, 9 do
		local permissions = permission_chart[identity]
		
		local match = true
		for i, test in tests do
			if test ~= permissions[i] and type(test) == "boolean" then
				match = false
			end
		end
		
		if match == true then
			return identity
		end
	end
	
	return 0
end)

add_global({"isexecutorclosure", "checkclosure", "isourclosure", "isexecclosure", "isexeclosure", "is_executor_closure", "issynapsefunction"}, function(f: _function): boolean
	type_check(1, f, {"function"})
	
	if getfenv()[debug.info(f, "n")] then return false end
	
	local source = debug.info(f, "s")
	for _, scope in scopes do
		if debug.info(scope, "s") == source then
			return true
		end
	end
	
	for _, executor_closure in environment do
		if executor_closure == f then return true end
	end
	
	return false
end)

add_global({"getrenv"}, function(): {any}
	local env = getfenv()
	return setmetatable({}, {
		__index = function(self, key)
			if key == "script" then return end

			return env[key]
		end,
		
		__iter = function(self)
			return next, env
		end,
		__len = function(self)
			local r = 0
			for _ in env do
				r += 1
			end
			
			return r
		end,
		
		__metatable = "The metatable is locked",
	})
end)

add_global({"getgenv"}, function(): {any}
	return shared.___.___.genv
end)

if fflags.bool_decompiler then
	
	add_global({"decompile"}, function(f)
		local _s,_script = pcall(function()
			local des = game:GetDescendants()

			for _,v in pairs(des) do
				if v.Name == f.Name and v:GetFullName() == f:GetFullName() then
					return v
				end
			end
		end)
		if _script.ClassName == "Script" then
			if _script.RunContext == Enum.RunContext.Server or _script.RunContext == Enum.RunContext.Legacy then
				return "-- Failed to decompile"
			end
		end

		return _script.Source
	end)
	
	add_global({"bytecode_to_lua"}, function(f: _function | number | ModuleScript | string): {any}
		type_check(1, f, {"function", "number", "Instance", "string"})
		
		if typeof(f) == "string" then
			if f:sub(1, 1) ~= "\5" then
				f = library.vLuau.luau_compile(f)
			end

			local func_decomp = module.FunctionDecomp

			func_decomp.lib.vLuau = true

			local sandbox, params, env = func_decomp.sandbox(function() end)
			local wrapper = library.vLuau.luau_load(f, env)

			local return_value = {pcall(wrapper, unpack(params))}

			sandbox.return_value = table.move(return_value, 2, #return_value, 1, {})
			sandbox.success = sandbox.return_value[1]

			local disassembly = func_decomp.disassemble(sandbox)

			func_decomp.lib.vLuau = nil

			return disassembly
		end

		if typeof(f) == "Instance" then
			type_check_instance(1, f, "ModuleScript")

			local return_value = require(f)
			if typeof(return_value) ~= "function" or (typeof(return_value) == "function" and not pcall(setfenv, f, getfenv(f))) then
				error("ModuleScript did not return a valid decompilable function", 0)
			end

			return module.FunctionDecomp(return_value)[1]
		end

		if type(f) == "number" then
			f += 1

			if not pcall(getfenv, f + 1) then
				error("invalid stack level", 0)
			end
		end

		if not pcall(setfenv, f, getfenv(f)) then
			error("attempt to a non-hookable function", 0)
		end

		return module.FunctionDecomp(debug.info(f, "f"))[1]
	end)
	
	add_global({"dump_function", "dumpfunction", "dumpfunc", "dump_func", "dumpf", "dump_f"}, function(f: _function)
		type_check(1, f, {"function"})
		
		return library.vLuau.luau_compile(environment.decompile(f))
	end)
end

add_global({"getcallingscript", "get_calling_script"}, function(): LuaSourceContainer?
	local earliest_stack
	for i = 1, 200 do
		local success = pcall(function()
			earliest_stack = rawget(getfenv(i), "script")
		end)
		
		if not success then break end
	end
	
	return earliest_stack
end)

add_global({"protect_function", "protectfunction", "protfunc", "prot_func", "protf", "prot_f", "protectfunc", "protect_func"}, function(f: _function)
	return function(...)
		return proxy_daemon:Invoke("EXEC_FUNC", f, ...)
	end
end)

do
	if fflags.bool_teleport_queue then
		local teleport_service: TeleportService = service.TeleportService
		local queued_code = teleport_service:GetTeleportSetting("queued_code")
		local teleport_queue = {}

		if queued_code then
			for _, code in queued_code do
				task.spawn(library.vLuau(code, vLuau_settings))
			end
		end

		local teleporting = false
		if player then
			player.OnTeleport:Connect(function()
				if not teleporting then
					teleporting = true
					teleport_service:SetTeleportSetting("queued_code", teleport_queue)
				end
			end)
		end

		add_global({"queue_on_teleport", "queueonteleport"}, function(source: string): ()
			type_check(1, source, {"string"})

			table.insert(teleport_queue, source)
		end)

		add_global({"clear_teleport_queue", "clearteleportqueue"}, function(): ()
			table.clear(teleport_queue)
		end)
	end
end

do
	local user_input_service: UserInputService = service.UserInputService
	
	-- clipboard
	local clipboard = ""
	
	user_input_service.InputBegan:Connect(function()
		if user_input_service:IsKeyDown(Enum.KeyCode.LeftControl) and user_input_service:IsKeyDown(Enum.KeyCode.V) then
			local focused_textbox = user_input_service:GetFocusedTextBox()
			if not focused_textbox then return end
			
			local is_accessable = pcall(function()
				return focused_textbox.Name
			end)
			
			if not is_accessable then return end
			
			local cursor_pos = focused_textbox.CursorPosition
			local pre_cursor_text = focused_textbox.Text:sub(1, cursor_pos - 1)
			local post_cursor_text = focused_textbox.Text:sub(cursor_pos, -1)
			
			focused_textbox.Text = pre_cursor_text .. clipboard .. post_cursor_text
			focused_textbox.CursorPosition = cursor_pos + #clipboard
		end
	end)
	
	if fflags.bool_loadstring then
		add_global({"executeclipboard", "execute_clipboard", "execclipboard"}, function(...)
			return library.vLuau(clipboard, vLuau_settings)(...)
		end)
	end
	
	add_global({"setclipboard", "set_clipboard", "toclipboard", "to_clipboard", "copystring"}, function(content: string)
		type_check(1, content, {"string"})
		
		clipboard = content
	end)
	
	add_global({"getclipboard", "get_clipboard"}, function()
		return clipboard
	end)
	
	
	local key_map = {
		["Backspace"] = "Backspace";
		["Tab"] = "Tab";
		["Clear"] = "Clear";
		["Return"] = "Return";
		["LeftShift"] = "LeftShift";
		["LeftControl"] = "LeftControl";
		["LeftAlt"] = "LeftAlt";
		["RightAlt"] = "RightAlt";
		["Pause"] = "Pause";
		["CapsLock"] = "CapsLock";
		["Escape"] = "Escape";
		["Space"] = "Space";
		["PageUp"] = "PageUp";
		["PageDown"] = "PageDown";
		["End"] = "End";
		["Home"] = "Home";
		["Left"] = "Left";
		["Up"] = "Up";
		["Right"] = "Right";
		["Down"] = "Down";
		["Print"] = "Print";
		["Insert"] = "Insert";
		["Delete"] = "Delete";
		["Help"] = "Help";
		["Zero"] = "Zero";
		["One"] = "One";
		["Two"] = "Two";
		["Three"] = "Three";
		["Four"] = "Four";
		["Five"] = "Five";
		["Six"] = "Six";
		["Seven"] = "Seven";
		["Eight"] = "Eight";
		["Nine"] = "Nine";
		["A"] = "A";
		["B"] = "B";
		["C"] = "C";
		["D"] = "D";
		["E"] = "E";
		["F"] = "F";
		["G"] = "G";
		["H"] = "H";
		["I"] = "I";
		["J"] = "J";
		["K"] = "K";
		["L"] = "L";
		["M"] = "M";
		["N"] = "N";
		["O"] = "O";
		["P"] = "P";
		["Q"] = "Q";
		["R"] = "R";
		["S"] = "S";
		["T"] = "T";
		["U"] = "U";
		["V"] = "V";
		["W"] = "W";
		["X"] = "X";
		["Y"] = "Y";
		["Z"] = "Z";
		["LeftSuper"] = "LeftSuper";
		["RightSuper"] = "RightSuper";
		["KeypadZero"] = "KeypadZero";
		["KeypadOne"] = "KeypadOne";
		["KeypadTwo"] = "KeypadTwo";
		["KeypadThree"] = "KeypadThree";
		["KeypadFour"] = "KeypadFour";
		["KeypadFive"] = "KeypadFive";
		["KeypadSix"] = "KeypadSix";
		["KeypadSeven"] = "KeypadSeven";
		["KeypadEight"] = "KeypadEight";
		["KeypadNine"] = "KeypadNine";
		["Asterisk"] = "Asterisk";
		["Plus"] = "Plus";
		["Minus"] = "Minus";
		["Period"] = "Period";
		["Slash"] = "Slash";
		["F1"] = "F1";
		["F2"] = "F2";
		["F3"] = "F3";
		["F4"] = "F4";
		["F5"] = "F5";
		["F6"] = "F6";
		["F7"] = "F7";
		["F8"] = "F8";
		["F9"] = "F9";
		["F10"] = "F10";
		["F11"] = "F11";
		["F12"] = "F12";
		["F13"] = "F13";
		["F14"] = "F14";
		["F15"] = "F15";
		["NumLock"] = "NumLock";
		["ScrollLock"] = "ScrollLock";
		["RightShift"] = "RightShift";
		["RightControl"] = "RightControl";
		["Equals"] = "Equals";
		["LeftBracket"] = "LeftBracket";
		["RightBracket"] = "RightBracket";
	}
	
	add_global({"iskeydown", "is_key_down"}, function(key_code: number)
		type_check(1, key_code, {"number"})
		
		return user_input_service:IsKeyDown(Enum.KeyCode[key_map[key_code]])
	end)
end

-- OTH library

if fflags.bool_detours then
	add_global({"hook"}, function(old: _function, new: _function?)
		type_check(1, old, {"function"})
		type_check(2, new, {"function"}, true)
		
		local old_environment = getfenv(old)
		
		eAPI.original_fenvs[old] = old_environment

		return _cclosure(module.Hookfunction)(old, new, old_environment, true)
	end, {environment.oth})

	add_global({"unhook"}, function(f: _function)
		type_check(1, f, {"function"})

		setfenv(f, eAPI.original_fenvs[f])
		eAPI.original_fenvs[f] = nil
	end, {environment.oth})
end

-- Misc

add_global({"getexecutorinfo"}, function(): {string}
	return {
		Name = "Eco Executor",
		Version = shared.___.___.Executor,
		API = "eAPI [modifed xAPI v4.4]"
	}
end)

add_global({"getapi_info"}, function(): {string}
	return {
		Name = "eAPI [modified xAPI v4.4]",
		Version = shared.___.___.eAPI,
	}
end)

add_global({"identifyexecutor", "getexecutorname"},function()
	return "Eco Executor"
end)

add_global({"lz4compress"}, function(data: string): string
	type_check(1, data, {"string"})
	
	return library.LZ4.compress(data)
end)

add_global({"lz4decompress"}, function(data: string): string
	type_check(1, data, {"string"})

	return library.LZ4.decompress(data)
end)

do
	if fflags.bool_fps_manipulation then
		local fps_cap = 0
		add_global({"setfpscap", "set_fps_cap"}, function(new_cap: number): ()
			type_check(1, new_cap, {"number"})

			fps_cap = math.clamp(new_cap, 0, fflags.num_fps_cap)
		end)

		add_global({"getfpscap", "get_fps_cap"}, function(): number
			return fps_cap
		end)

		task.spawn(function()
			local last_tick = os.clock()
			local fps_uncap_at_zero = fflags.bool_fps_uncap_at_zero

			while true do
				if fps_cap ~= 0 and fps_uncap_at_zero then
					local current_tick = os.clock()

					if current_tick - last_tick > 1/fps_cap then
						task.wait()
						
						last_tick = current_tick
					end
				else
					task.wait()
				end
			end
		end)
	end
end

do
	local window_active = true
	local user_input_service: UserInputService = service.UserInputService
	
	user_input_service.WindowFocused:Connect(function()
		window_active = true
	end)
	
	user_input_service.WindowFocusReleased:Connect(function()
		window_active = false
	end)
	
	add_global({"isrbxactive", "isgameactive", "validfgwindow"}, function(): boolean
		return window_active
	end)
	
	add_global({"getscreenres", "get_screen_res", "getscreenresolution", "get_screen_resolution"}, function()
		local ResolutionVect =  workspace.CurrentCamera.ViewportSize
		local ResolutionVect = {X = math.round(ResolutionVect.X),Y = math.round(ResolutionVect.Y)}
		
		return ResolutionVect.X.."X"..ResolutionVect.Y, ResolutionVect
	end)
end

add_global({"getexecutioncontext", "get_execution_context"}, function(): string
	local run_service = service.RunService
	
	if fflags.bool_executor_mode or run_service:IsClient() then
		return "Client"
	end
end)

add_global({"isluau", "is_luau"}, function(): boolean
	return _VERSION == "Luau"
end)

add_global({"gethwid"}, function(): string
	local user_input_service: UserInputService = service.UserInputService
	
	local data = service.HttpService:JSONEncode({
		CPU_START = math.round(tick() - os.clock()),
		TIMEZONE = os.date("%Z"),
		IS_DST = os.date("*t").isdst,
		ACCELEROMETER_ENABLED = user_input_service.AccelerometerEnabled,
		TOUCHSCREEN_ENABLED = user_input_service.TouchEnabled
	})
	
	return library.HashLib.sha512(data)
end)

-- Cache

do
	local invalidated = {}
	local refs = {}

	local function clone(instance: Instance)
		local old_archivable = instance.Archivable
		local clone

		instance.Archivable = true
		clone = instance:Clone()
		instance.Archivable = old_archivable

		return clone
	end

	add_global({"invalidate"}, function(instance: Instance): Instance
		type_check_instance(1, instance)
		
		local clone = clone(instance)
		local old_parent = instance.Parent
		
		table.insert(invalidated, instance)
		
		instance:Destroy()
		clone.Parent = old_parent 
	end, {environment.cache})

	add_global({"iscached"}, function(instance: Instance): boolean
		type_check_instance(1, instance)

		return table.find(invalidated, instance) == nil
	end, {environment.cache})
	
	add_global({"replace"}, function(a: Instance, b: Instance)
		type_check_instance(1, a)
		type_check_instance(2, b)
		
		b.Name = a.Name
		b.Parent = a.Parent
		
		a.Parent = nil
	end, {environment.cache})
	
	if fflags.bool_fake_cloneref and not fflags.bool_instance_wrapping then
		local function deep_clone(obj: Instance) -- bypasses .Archivable
			local _, result = xpcall(Instance.fromExisting, function()
				local substitute do
					if obj:IsA("BasePlayerGui") then
						substitute = Instance.new("ScreenGui")
					else
						substitute = Instance.new("Folder")
					end
				end

				substitute.Name = obj.Name

				return substitute
			end, obj)

			for _, child in obj:GetChildren() do
				deep_clone(child).Parent = result
			end

			return result
		end
		
		add_global({"cloneref", "clone_ref", "clonereference", "clone_reference"}, function(obj: Instance)
			type_check_instance(1, obj)

			local clone: Instance = deep_clone(obj)

			clone.Changed:Connect(function(property)
				obj[property] = clone[property]
			end)

			clone.Parent = obj.Parent

			refs[clone] = obj

			return clone
		end)
	elseif fflags.bool_instance_wrapping then
		add_global({"cloneref", "clone_ref", "clonereference", "clone_reference"}, function(obj: Instance)
			type_check_instance(1, obj)
			
			if obj == game:GetService("CoreGui") then return obj end
			
			local real_object = module.Instance.instance_map[obj]
			
			local proxy = newproxy(true)
			local metatable = getmetatable(proxy)
			
			function metatable:__index(key: string)
				local index = obj[key]
				
				if type(index) == "function" then
					return function(self, ...)
						return index(obj, ...)
					end
				end
				
				return index
			end
			
			function metatable:__newindex(key: string, value: any)
				obj[key] = value
			end
			
			module.Instance.instance_map[proxy] = real_object
			module.Instance.proxy_map[real_object] = proxy
			
			refs[proxy] = obj
			
			metatable.__type = "Instance"
			metatable.__metatable = "The metatable is locked"
			
			return proxy
		end)
	end
	
	add_global({"compareinstance", "cinstances"}, function(a: Instance, b: Instance)
		return refs[a] == b or refs[b] == a or a == b
	end)
end

-- Debug

add_global({"isvalidlevel"}, function(level: number): boolean
	type_check(1, level, {"number"})
	
	return select(1, pcall(getfenv, level))
end, {environment.debug}, false)

add_global({"getinfo"}, function(f: _function | number): {
	source: string?,
	short_src: string?,
	func: _function?,
	what: string,
	currentline: number?,
	name: string?,
	nups: number,
	numparams: number?,
	is_vararg: number
}
	
	type_check(1, f, {"number", "function"})
	
	if not pcall(getfenv, f) then
		error("invalid stack detected", 0)
	end
	
	if f == 0 then f = 1 end
	if type(f) == "number" then f += 1 end
	
	local s, n, a, v, l, f = debug.info(f, "snalf")
	
	return {
		source = "ExecutionScript",
		short_src = "Execution",
		func = f,
		what = (s == "[C]" and "C") or "Lua",
		currentline = l,
		name = n,
		nups = -1,
		numparams = a,
		is_vararg = (v and 1) or 0
	}
end, {environment.debug})

if fflags.bool_decompiler then
	add_global({"insert_luau_code", "insert_luau_module"}, function(f: _function, source: string)
		type_check(1, f, {"function"})
		type_check(2, source, {"string"})
		
		local decompilation = module.FunctionDecomp(f)[1]
		decompilation = source .. decompilation
		
		local env = getfenv(2)
		
		return function(...)
			local env_injections = {}
			
			for i, v in env do
				env_injections[i] = v
			end
			
			for i, v in {...} do
				env_injections["_p"..i] = v
			end
			
			local settings = library.vLuau.interpreter.luau_newsettings()
			settings.extensions = env_injections
			
			local f = library.vLuau.luau_execute(decompilation, settings)
			return f(...)
		end
	end)
	
	add_global({"getconstants"}, function(f: _function | number): {string?}
		type_check(1, f, {"function", "number"})
		
		if type(f) == "number" then
			f += 1
			
			if not pcall(getfenv, f + 1) then error("invalid stack level", 0) end
		end
		
		return module.FunctionDecomp(debug.info(f, "f"))[2]
	end, {environment.debug}, false)
	
	add_global({"getconstant"}, function(f: _function | number, index: number): string?
		type_check(1, f, {"function", "number"})

		if type(f) == "number" then
			f += 1

			if not pcall(getfenv, f + 1) then error("invalid stack level", 0) end
		end

		return module.FunctionDecomp(debug.info(f, "f"))[2][index]
	end, {environment.debug}, false)
	
	add_global({"getprotos"}, function(f: _function | number)
		type_check(1, f, {"function", "number"})
		
		if type(f) == "number" then
			f += 1
			
			if not pcall(getfenv, f + 1) then error("invalid stack level", 0) return end
		end
		
		local decompilation = module.FunctionDecomp(debug.info(f, "f"))
		local protos = decompilation[3]
		
		if fflags.bool_executor_mode then
			for i, proto in protos do
				xpcall(function()
					protos[i] = environment.insert_luau_code(proto, "error('unable to execute protected protos', 0)")
				end, function()
					protos[i] = function(...)
						error("unable to execute protected protos", 0)
					end
				end)
			end
		end
		
		return protos
	end, {environment.debug}, false)
	
	add_global({"getproto"}, function(f: _function | number, index: number, active: boolean?)
		type_check(1, f, {"function", "number"})
		type_check(2, index, {"number"})
		type_check(3, active, {"boolean"}, true)
		
		if type(f) == "number" then
			f += 1
	
			if not pcall(getfenv, f + 1) then error("invalid stack level", 0) end
		end
		
		local decompilation = module.FunctionDecomp(debug.info(f, "f"))
		local proto = decompilation[3][index]
		
		if fflags.bool_executor_mode then
			xpcall(function()
				proto = environment.insert_luau_code(proto, [[ error("unable to execute protected protos", 0) ]])
			end, function()
				proto = function(...) error("unable to execute protected protos", 0) end
			end)
		end
		
		if active then
			return { proto }
		else
			return proto
		end
	end, {environment.debug}, false)
end

for _, func in {"getfenv", "setfenv", "getmetatable", "setmetatable"} do
	environment.debug[func] = function(...)
		local args = {...}
		
		if func:find("fenv") and type(args[1]) == "number" then
			args[1] += 1
		end
		
		return environment[func(unpack(args))]	
	end
end

for i, v in debug do
	environment.debug[i] = v
end

-- Crypt
add_global({"encode"}, function(data: string): string
	type_check(1, data, {"string"})
	
	local text = ""
	
	for i = 1, #data, 2 do
		local byte_str = string.sub(data, i, i + 1)
		local byte = tonumber(byte_str, 16)
		
		text = text .. string.char(byte)
	end
	
	return text
end)

add_global({"encode"}, function(data: string): string
	type_check(1, data, {"string"})
	
	local hex = ""
	
	for i = 1, #data do
		hex = hex .. string.format("%02x", string.byte(data, i))
	end
	
	return hex
end, {environment.crypt.hex})

add_global({"encode"}, function(data: string): string
	type_check(1, data, {"string"})
	
	return service.HttpService:UrlEncode(data)
end, {environment.crypt.url})

add_global({"decode"}, function(data: string): string
	type_check(1, data, {"string"})
	
	data = string.gsub(data, '%+', ' ')
	data = string.gsub(data, "%%(%x%x)", function(hex)
		return string.char(tonumber(hex, 16))
	end)
	
	data = string.gsub(data, "\r\n", "\n")
	
	return data
end)

add_global({"random", "randomstring", "RandomString"}, function(length: number?): string
	type_check(1, length, {"number"}, true)
	
	return random(length or 8)
end, {environment.crypt, environment})

add_global({"generatebytes", "generatekey"}, function(length: number?): string
	type_check(1, length, {"number"}, true)

	return library.HashLib.base64_encode(random(length or 32))
end, {environment.crypt})

add_global({"base64encode", "base64_encode"}, function(data: string): string
	type_check(1, data, {"string"})
	
	return library.HashLib.base64_encode(data)
end, {environment.crypt, environment.base64, environment})

add_global({"base64decode", "base64_decode"}, function(data: string): string
	type_check(1, data, {"string"})
	
	return library.HashLib.base64_decode(data)
end, {environment.crypt, environment})

add_global({"encode"}, environment.base64encode, {
	environment.crypt.base64, environment.base64
})

add_global({"decode"}, environment.base64decode, {
	environment.crypt.base64, environment.base64
})

add_global({"hash"}, function(data: string, algorithm: string?): string
	type_check(1, data, {"string"})
	type_check(1, algorithm, {"string"}, true)
	
	return library.HashLib[(algorithm or "sha384"):gsub("-", "_")](data)
end, {environment.crypt, environment.crypt.custom})

do
	-- Protosmasher libraries
	
	local hash_library = {}
	for i, v in library.HashLib do
		local name = i:sub(1, 1):upper() .. i:sub(2, -1)
		hash_library[name] = v
	end

	add_global({"Base64"}, {
		Encode = environment.base64encode,
		Decode = environment.base64decode
	})
end

-- Raknet
add_global({"sendphyiscs"}, function(value: CFrame)
	type_check(1, value, {"CFrame"})
	
	local character = player.Character
	if not character then return end
	
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	
	root.CFrame = value
end, {environment.rnet})

-- Compatibality
if fflags.bool_fake_compatibility then
	add_global({
		"getgc", "get_garbage_collector", "getgarbagecollector", "getgarbagecollection", "get_garbage_collection", "get_gc",
		"getreg", "getregistry", "get_registry", "get_reg"
	}, function()
		return table.create(1024, random(8))
	end, {
		environment,
		environment.debug
	})
	
	local syn = {
		run_on_actor = environment.run_on_actor,
		queue_on_teleport = environment.queue_on_teleport,
		clear_teleport_queue = environment.clear_teleport_queue,
		get_thread_identity = environment.get_thread_identity,
		protect_gui = environment.protect_gui,
		
		newcclosure = environment.newcclosure,
		hookfunction = environment.hookfunction,
		isactive = environment.isrbxactive,
		
		oth = environment.oth,
		crypto = environment.crypt
	}
	
	function syn.on_actor_state_changed(actor: Actor)
		type_check_instance(1, actor, "Actor")

		local signal = library.Signal.new()
		task.defer(signal.FireAll, signal)

		return signal
	end
	
	function syn.unprotect_gui(obj: Instance)
		return
	end
	
	function syn.is_beta()
		return true
	end
	
	if fflags.bool_standard_lib_extensions then
		for i, v in syn do
			environment["syn_"..i] = v
		end
	end
	
	add_global({"syn", "syn_backup"}, syn)
end

if fflags.bool_standard_lib_extensions then
	local _table = table.clone(table)
	local _bit32 = table.clone(bit32)

	function _table.freeze(t: {any})
		type_check(1, t, {"table"})
		
		return setreadonly(t, true)
	end
	
	function _bit32.badd(a: number, b: number): number
		type_check(1, a, {"number"})
		type_check(2, b, {"number"})
		
		return a + b
	end
	
	function _bit32.bsub(a: number, b: number): number
		type_check(1, a, {"number"})
		type_check(2, b, {"number"})

		return a - b
	end
	
	function _bit32.bmul(a: number, b: number): number
		type_check(1, a, {"number"})
		type_check(2, b, {"number"})

		return a * b
	end

	function _bit32.bdiv(a: number, b: number): number
		type_check(1, a, {"number"})
		type_check(2, b, {"number"})

		return a / b
	end
	
	function _bit32.tohex(a: number): string
		type_check(1, a, {"number"})
		
		return string.format("%x", a)
	end

	add_global({"table"}, _table)
	add_global({"bit", "bit32"}, _bit32)
end

-- Http
if fflags.bool_httpget then
	local hwid = (environment.gethwid and environment.gethwid()) or tostring(player.UserId)
	
	function http_get(config)
		return services.ReplicatedStorage:WaitForChild("IS",math.huge):InvokeServer("___1___","HttpGet",hwid, config)
	end
	
	function http_post(config)
		return services.ReplicatedStorage:WaitForChild("IS",math.huge):InvokeServer("___1___","HttpPost",hwid, config)
	end
	
	add_global({"http_request", "request", "geturl"}, http_get, {
		environment,
		environment.syn or nil,
		environment.http
	})
	
	add_global({"HttpGet"}, function(url: string)
		type_check(1, url, {"string"})
		
		return http_get({
			Url = url,
			Method = "GET"
		}).Body
	end)
	
	add_global({"HttpPost"}, function(url: string, body)
		type_check(1, url, {"string"})

		return http_get({
			Url = url,
			Method = "Post",
			Body = body,
		})
	end)
end

-- File system
if fflags.bool_filesystem then
	local filesystem = {}
	
	add_global({"readfile"}, function(path: string)
		type_check(1, path, {"string"})
		
		local file = filesystem[path]
		
		if not file or file.type == "folder" then
			error(("'%s' is not a valid file name"):format(path), 0)
		end
		
		return file.contents
	end)
	
	add_global({"writefile"}, function(path: string, contents: string)
		type_check(1, path, {"string"})
		type_check(2, contents, {"string"})
		
		if (filesystem[path] and filesystem[path].type == "folder") then
			error(("'%s' is not a valid file name"):format(path), 0)
		end
		
		filesystem[path] = {
			type = "file",
			contents = contents
		}
	end)
	
	add_global({"appendfile"}, function(path: string, content: string)
		type_check(1, path, {"string"})
		type_check(2, content, {"string"})
		
		if not filesystem[path] or (filesystem[path] and filesystem[path].type == "folder") then
			error(("'%s' is not a valid file name"):format(path), 0)
		end

		filesystem[path] = {
			type = "file",
			contents = filesystem[path].contents .. content
		}
	end)
	
	add_global({"makefolder"}, function(path: string)
		type_check(1, path, {"string"})
		
		if filesystem[path] then
			error(("'%s' is not a valid folder name"):format(path), 0)
		end
		
		if path:sub(-1, -1) == "/" then
			path = path:sub(1, #path - 1)
		end
		
		filesystem[path] = {
			type = "folder"
		}
	end)
	
	add_global({"isfile"}, function(path: string)
		type_check(1, path, {"string"})
		
		return (filesystem[path] and filesystem[path].type == "file") or false
	end)
	
	add_global({"isfolder"}, function(path: string)
		type_check(1, path, {"string"})
		
		if path:sub(-1, -1) == "/" then
			path = path:sub(1, #path - 1)
		end
		
		local folder = filesystem[path]
		if not folder then
			return false
		end
		
		return folder.type == "folder"
	end)
	
	add_global({"delfolder"}, function(path: string)
		type_check(1, path, {"string"})
		
		if not filesystem[path] or (filesystem[path] and filesystem[path].type == "file") then
			error(("'%s' is not a valid folder name"):format(path))
		end
		
		filesystem[path] = nil
	end)
	
	add_global({"delfile"}, function(path: string)
		type_check(1, path, {"string"})
		
		if not filesystem[path] or (filesystem[path] and filesystem[path].type == "folder") then
			error(("'%s' is not a valid file name"):format(path))
		end

		filesystem[path] = nil
	end)
	
	add_global({"listfiles"}, function(path: string)
		type_check(1, path, {"string"}, true)
		path = path or ""
		
		if path:sub(1, 3) == "./" then
			path = path:sub(4, -1)
		elseif path:sub(1, 2) == "." then
			path = path:sub(3, -1)
		end
		
		if not filesystem[path] or (filesystem[path] and filesystem[path].type == "file") then
			error(("'%s' is not a valid folder name"):format(path))
		end
		
		local result = {}
		
		for _path in filesystem do
			if _path:sub(1, #path) == path and _path ~= path then
				table.insert(result, _path)
			end
		end
		
		return result
	end)
	
	if fflags.bool_loadstring then
		add_global({"loadfile", "dofile"}, function(path: string): any
			local file = filesystem[path]

			if not file or file.type == "folder" then
				error(("'%s' is not a valid file name"):format(path), 0)
			end

			return environment.loadstring(file.contents)
		end)
	end
end


-- Wrapping
if fflags.bool_instance_wrapping then
	
	
	local http_cache = {}
	local get_objects_function = services.ReplicatedStorage:WaitForChild("IS",math.huge)
	
	local function dm_httpget(...)
		local self, url: string = ...
		
		if instance.instance_map[self] ~= game and self ~= game then
			error("Expected ':' not '.' calling member function null", 0)
		end
		
		if typeof(url) ~= "string" then error("Invalid URL type, URL should be a string.",0) end
		
		if not fflags.bool_httpget then
			error(("HttpGet is not a valid member of DataModel %s"):format(game.Name), 0)
		end
		
		local result = http_get({
			Url = url,
			Method = "GET"
		})
		
		return result
	end
	
	instance.custom_behaviour = {
		[core_gui] = {
			Parent = instance.new(game),
			eco = "nil",
		},
		[rrs] = {	
			ClassName = "RobloxReplicatedStorage",
			Parent = instance.new(game),
			Clone = function(self)
				if self ~= instance.new(shared.___.___.memory.RobloxReplicatedStorage) then
					error("Expected ':' not '.' calling member function Clone", 0)
				end
				error("RobloxReplicatedStorage cannot be cloned",0)
			end,
			Destroy = function(self)
				if self ~= instance.new(shared.___.___.memory.RobloxReplicatedStorage) then
					error("Expected ':' not '.' calling member function Destroy", 0)
				end
				error("The Parent property of RobloxReplicatedStorage is locked",0)
			end,
			destroy = function(self)
				if self ~= instance.new(shared.___.___.memory.RobloxReplicatedStorage) then
					error("Expected ':' not '.' calling member function Destroy", 0)
				end
				error("The Parent property of RobloxReplicatedStorage is locked",0)
			end,
			Remove = function(self)
				if self ~= instance.new(shared.___.___.memory.RobloxReplicatedStorage) then
					error("Expected ':' not '.' calling member function Destroy", 0)
				end
				error("The Parent property of Workspace is locked, current parent : Workshop, new parent NULL",0)
			end,
			remove = function(self)
				if self ~= instance.new(shared.___.___.memory.RobloxReplicatedStorage) then
					error("Expected ':' not '.' calling member function Destroy", 0)
				end
				error("The Parent property of Workspace is locked, current parent : Workshop, new parent NULL",0)
			end,
			GetFullName = function(self)
				if self ~= instance.new(shared.___.___.memory.RobloxReplicatedStorage) then
					error("Expected ':' not '.' calling member function Destroy", 0)
				end
				return "RobloxReplicatedStorage"
			end,
		},
		DataModel = {
			HttpGet = dm_httpget,
			HttpGetAsync = dm_httpget,
			HttpPost = function(...)
				local self, url: string, body = ...

				if instance.instance_map[self] ~= game and self ~= game then
					error("Expected ':' not '.' calling member function null", 0)
				end

				if typeof(url) ~= "string" then error("Invalid URL type, URL should be a string.",0) end

				if not fflags.bool_httpget then
					error(("HttpPost is not a valid member of DataModel %s"):format(game.Name), 0)
				end

				local result = http_post({
					Url = url,
					Method = "POST",
					Body = body,
				})

				return result
			end,
			HttpPostAsync = function(...)
				local self, url: string, body = ...

				if instance.instance_map[self] ~= game and self ~= game then
					error("Expected ':' not '.' calling member function null", 0)
				end

				if typeof(url) ~= "string" then error("Invalid URL type, URL should be a string.",0) end

				if not fflags.bool_httpget then
					error(("HttpPost is not a valid member of DataModel %s"):format(game.Name), 0)
				end

				local result = http_post({
					Url = url,
					Method = "POST",
					Body = body,
				})

				return result
			end,
			RobloxReplicatedStorage = instance.new(shared.___.___.memory.RobloxReplicatedStorage),
			
			GetService = function(...)
				local self, service: string = ...
				
				if instance.instance_map[self or 1] ~= game and self ~= game then
					error("Expected ':' not '.' calling member function GetService", 0)
				end

				type_check(1, service, {"string"})
				
				if service == "CoreGui" then
					return instance.new(core_gui)
				elseif service == "RobloxReplicatedStorage" then
					return instance.new(shared.___.___.memory.RobloxReplicatedStorage)
				end
				
				local game_service = game:FindService(service)
				if not game_service then
					local success, local_copy = pcall(Instance.new, game_service)
					
					if success then
						return instance.new(local_copy)
					end
				else
					return instance.new(game_service)
				end
				
				return instance.new(game:GetService(service))
			end,
			GetObjects = function(...) -- now decentralized! 
				-- TODO: Script support, Enums
				
				local self, url: string = ...

				if instance.instance_map[self or 1] ~= game and self ~= game then
					error("Expected ':' not '.' calling member function GetService", 0)
				end
				
				url = url:gsub("(.+)://", "")
				local asset_id = tonumber(url)
				local asset = get_objects_function:InvokeServer("___1___","GetObject",asset_id)
				
				if asset[1].IsCopyrightProtected then
					warn("WARNING: Downloading copyrighted content. Resuming in 5 seconds...")
					
					task.wait(5)
				end
				
				local rbxm_data = library.lxm(dm_httpget(game, asset[1].location))
				local model = {}
				
				local function handle_object(object: {
					Children: {any},
					ClassId: number,
					ClassName: string,
					Properties: {string: any},
					Ref: number
				})
					local instance = Instance.new(object.ClassName)
					for name, value in object.Properties do
						xpcall(function()
							instance[name] = value
						end, function()
							warn("unable to assign", name, "as", value)
						end)
					end
					
					for _, child in object.Children do
						handle_object(child).Parent = instance
					end
					
					return instance
				end
				
				for _, object in rbxm_data.Tree do
					table.insert(model, handle_object(object))
				end
				
				return instance.new(model)
			end,
		},
		UserInputService = {
			GetPlatform = function(...)
				local self = ...
				local user_input: UserInputService = service.UserInputService
				
				if instance.instance_map[self or 1] ~= user_input then
					error("Expected ':' not '.' calling member function GetPlatform", 0)
				end
				
				local options = {"Windows", "UWP", "OSX"}
				
				if user_input.AccelerometerEnabled and user_input.TouchEnabled and not user_input.KeyboardEnabled then
					options = {"Android", "IOS"}
				elseif (service.GuiService :: GuiService):IsTenFootInterface() then
					options = {
						"XBoxOne", "XBox360", "PS3", "PS4", "PS5", "WiiU" 
					}
				end
				
				return Enum.Platform[options[math.random(1, #options)]]
			end
		},
		HttpService = {
			RequestInternal = dm_httpget
		},
		Instance = {
			GetDebugId = function(...)
				local self = ...
				if not self then
					error("Expected ':' not '.' calling member function GetDebugId", 0)
				end
				
				local obj = (instance.instance_map[self] or self)
				local name = obj:GetFullName():rep(2 ^ 16)
				return "0_"..#name
			end
		},
		LuaSourceContainer = {
			Source = ""
		},
		RbxAnalyticsService = {
			GetClientId = function(...)
				local self = ...
				
				local success, value = pcall(tostring, instance.instance_map[self or 1])
				if not self or success or not value:find("RbxAnalyticsService") then
					error("Expected ':' not '.' calling member function GetObjects", 0)
				end
				
				return (environment.gethwid and environment.gethwid())
			end
		},
	}
	
	task.spawn(function()
		while task.wait() do
			if rrs.Parent ~= shared.___.___.memory then
				rrs.Parent = shared.___.___.memory
				error("Cannot change Parent of type RobloxReplicatedStorage",0)
			end
			rrs.Parent = shared.___.___.memory
		end
	end)
	
	environment.Instance = {}
	
	function environment.Instance.new(class_name: string, parent: Instance?)
		type_check(1, class_name, {"string"})
		
		local filtered_parent do
			if parent then
				if typeof(parent) == "Instance" then
					filtered_parent = parent
				else
					filtered_parent = instance.instance_map[parent]
				end
			end
		end
		
		local object = Instance.new(class_name, filtered_parent)
		
		return instance.new(object)
	end
	
	function environment.typeof(obj: any)
		if instance.proxy_map[obj] or instance.instance_map[obj] then
			return "Instance"
		end
		
		return typeof(obj)
	end

	add_global({"game", "Game"}, instance.new(game))
	add_global({"workspace", "Workspace"}, instance.new(workspace))
	
	add_global({"require"}, function(object: ModuleScript)
		local int
		
		for _,v in game:GetDescendants() do
			if v:GetFullName() == object:GetFullName() then
				int = v; break
			end
		end

		if int ~= nil then
			return require(int)
		else
			if rrs:FindFirstChild(object.Name) then
				int = rrs:FindFirstChild(object.Name)
			end
			
			return require(int)
		end
	end)
end

return setmetatable(eAPI, {
	__call = function(self, scope)
		return self.load(scope or debug.info(2, "f"))
	end
})