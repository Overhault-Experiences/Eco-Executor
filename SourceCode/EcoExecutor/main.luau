-- // Core Stuff \\ --
local Main = script.Parent
local Modules = script.modules
local Components = script.components

-- // Modules \\ --
local Services = require(Modules.services)

-- // Miscellaneous \\ --
local config

if not Services.RunService:IsStudio() then return end

if not Services.RunService:IsRunning() then
	local Toolbar = plugin:CreateToolbar("Eco Executor") :: PluginToolbar
	local Config = Toolbar:CreateButton("Config","Eco Config: {Injection | Keybind | Server warns}","rbxassetid://79005389041499") :: PluginToolbarButton
	
	if plugin:GetSetting("InjectEnabled") == nil then
		plugin:SetSetting("InjectEnabled",true)
	end
	
	if plugin:GetSetting("Keybind") == nil then
		plugin:SetSetting("Keybind", Enum.KeyCode.LeftControl.Name)
	end
	
	if plugin:GetSetting("ServerWarn") == nil then
		plugin:SetSetting("ServerWarn", true)
	end
	
	Config.Click:Connect(function()
		if config == nil then
			local ij = plugin:GetSetting("InjectEnabled")
			local k = plugin:GetSetting("Keybind")
			
			config = Components.eco_config:Clone()

			config.Parent = Services.CoreGui.RobloxGui

			local config = {
				main = config,
				injection = config.injection.config,
				keybind = config.kebind.config,
				server_warns = config.server_warns.config,
			}
			
			if ij ~= nil then
				if ij == true then
					config.injection.Text = "Enabled"
					config.injection.TextColor3 = Color3.fromRGB(77, 255, 46)
				else
					config.injection.Text = "Disabled"
					config.injection.TextColor3 = Color3.fromRGB(172,0,3)
				end
			end
			
			if k ~= nil and k ~= "Unknown" then
				config.keybind.Text = k
			end
			
			config.injection.Activated:Connect(function()
				if config.injection.Text == "Enabled" then
					config.injection.Active = false
					plugin:SetSetting("InjectEnabled",false)
					config.injection.Text = "Disabled"
					Services.TweenService:Create(config.injection, TweenInfo.new(.2),{TextColor3 = Color3.fromRGB(172,0,3)}):Play()
					config.injection.Active = true
				else
					config.injection.Active = false
					plugin:SetSetting("InjectEnabled",true)
					config.injection.Text = "Enabled"
					Services.TweenService:Create(config.injection, TweenInfo.new(.2),{TextColor3 = Color3.fromRGB(77, 255, 46)}):Play()
					config.injection.Active = true
				end
			end)

			config.keybind.Activated:Connect(function()
				config.keybind.Active = false
				config.keybind.Text = "Press a key"

				local c
				c = Services.UserInputService.InputBegan:Connect(function(input)
					if input ~= Enum.KeyCode.Unknown then
						plugin:SetSetting("Keybind",input.KeyCode.Name)
						config.keybind.Text = input.KeyCode.Name
						config.keybind.Active = true
						c:Disconnect()
					end
				end)
			end)
			
			config.server_warns.Activated:Connect(function()
				if config.server_warns.Text == "Enabled" then
					config.server_warns.Active = false
					plugin:SetSetting("ServerWarn",false)
					config.server_warns.Text = "Disabled"
					Services.TweenService:Create(config.server_warns, TweenInfo.new(.2),{TextColor3 = Color3.fromRGB(172,0,3)}):Play()
					config.server_warns.Active = true
				else
					config.server_warns.Active = false
					plugin:SetSetting("ServerWarn",true)
					config.server_warns.Text = "Enabled"
					Services.TweenService:Create(config.server_warns, TweenInfo.new(.2),{TextColor3 = Color3.fromRGB(77, 255, 46)}):Play()
					config.server_warns.Active = true
				end
			end)
		else
			if config.Parent == script.memory then
				config.Parent = Services.CoreGui.RobloxGui
			else
				config.Parent = script.memory
			end
		end
	end)
	
	return
end

if Services.RunService:IsServer() then
	local IS = Instance.new("RemoteFunction")
	IS.Name = "IS"
	IS.Parent = Services.ReplicatedStorage
	
	local ServerWarn = plugin:GetSetting("ServerWarn")
	
	if ServerWarn == true then
		local DSSEnabled = xpcall(function()
			return game:GetService("DataStoreService"):GetDataStore("__IsEnabled"):GetAsync("_____")
		end, function() return end)
		
		local HttpEnabled = game:GetService("HttpService").HttpEnabled
		
		if DSSEnabled == false then
			warn("Enable Studio Access to API Services at game settings [Security] is disabled, saveinstance will be non-functional.")
		end

		if HttpEnabled == false then
			warn("Allow HTTP Requests at game settings [Security] is disabled, some executor functions will may not work.")
		end
	end

	task.spawn(function()
		local insert_service = Services.InsertService
		local http = Services.HttpService
		local InstanceStore,Saved,ScriptStore = game:GetService("DataStoreService"):GetDataStore("InstanceStore"), game:GetService("DataStoreService"):GetDataStore("SavedInstance"), game:GetService("DataStoreService"):GetDataStore("ScriptStore")

		local connections = {};local connectionsnames = {}

		IS.OnServerInvoke = function(plr, ...)
			
			local code,method,args,config = ...
			
			if code ~= "___1___" then return end
			
			if method == "save" then
				local si = InstanceStore:GetAsync(plr.UserId)
				local saves = Saved:GetAsync(plr.UserId)

				if si == nil then
					si = {}
				elseif saves == nil then
					saves = {}
				end

				si[args.Name] = args
				saves[args.Name] = args.Name
				InstanceStore:SetAsync(plr.UserId,si)
				Saved:SetAsync(plr.UserId,saves)
			elseif method == "request" then

				local fetched = InstanceStore:GetAsync(plr.UserId)
				return fetched[args]
			elseif method == "request_saves" then

				local fetched = Saved:GetAsync(plr.UserId)
				return fetched
			elseif method == "reset" then

				InstanceStore:RemoveAsync(plr.UserId)
				Saved:RemoveAsync(plr.UserId)
			elseif method == "GetObject" then
				return http:JSONDecode(http:PostAsync("https://assetdelivery.roproxy.com/v1/assets/batch", ([=[[{"requestId":"%d","assetId":%d}]]=]):format(args, args)))
			elseif method == "HttpGet" then
				
				if http.HttpEnabled ~= true then return "nil" end
				
				local url: string = config.Url
				local http_config = table.clone(config)
				local headers = table.clone(http_config.Headers or {})

				headers["Eco-Fingerprint"] = args

				http_config.Headers = headers

				local proxies = {
					["discord.com"] = "webhook.lewisakura.moe",
					["roblox.com"] = "roproxy.com"
				}

				for original, proxy in proxies do
					url = url:gsub(original, proxy)
				end

				http_config.Url = url
				
				return http:RequestAsync(http_config)
			elseif method == "HttpPost" then

				if http.HttpEnabled ~= true then return "nil" end

				local url: string = config.Url
				local http_config = table.clone(config)
				local headers = table.clone(http_config.Headers or {})

				headers["Eco-Fingerprint"] = args

				http_config.Headers = headers

				local proxies = {
					["discord.com"] = "webhook.lewisakura.moe",
					["roblox.com"] = "roproxy.com"
				}

				for original, proxy in proxies do
					url = url:gsub(original, proxy)
				end

				http_config.Url = url

				return http:RequestAsync(http_config)
			elseif method == "save_script" then
				local DSSEnabled = pcall(function()
					return game:GetService("DataStoreService"):GetDataStore("DSSEnabled"):GetAsync("_____")
				end)

				if not DSSEnabled then
					return
				end

				local data = ScriptStore:GetAsync(plr.UserId)

				if data == nil then
					data = {}
				end

				data[args] = config
				local _s = pcall(function()
					ScriptStore:SetAsync(plr.UserId,data)
				end)
				return _s
			elseif method == "spy" then
				local target

				for _,v in game:GetDescendants() do
					if v.Name == args and v:GetFullName() == config then
						target = v
					end
				end

				if target.ClassName == "RemoteEvent" then
					if connectionsnames[target.Name] ~= nil then return end
					connectionsnames[target.Name] = target:GetFullName()
					connections[target.Name] = target.OnServerEvent:Connect(function(_, ...)
						IS:InvokeClient(plr, ...)
					end)
				else
					if connectionsnames[target.Name] ~= nil then print("isn't nil") return end
					connectionsnames[target.Name] = target:GetFullName()
					target.OnServerInvoke = function(_, ...)
						IS:InvokeClient(plr, ...)
					end
				end

				return
			elseif method == "unspy" then
				if connections[args] ~= nil then connections[args]:Disconnect() connectionsnames[args] = nil return end

				local target
				for _,v in game:GetDescendants() do
					if v:GetFullName() == config then
						target = v
					end
				end

				if target:IsA("RemoteFunction") then
					target.OnServerInvoke = nil
				end

				connectionsnames[args] = nil
				return
			elseif method == "isspied" then
				if connectionsnames[args] ~= nil then
					return true
				else
					return false
				end

			elseif method == "spied" then
				return connectionsnames
			elseif method == "checkerror" then
				local function checkSyntax(code) : string
					local func, err = loadstring(code,"ScriptAnalysis")
					if not func then
						return false, err
					end
					return true, nil
				end
				
				local _s, _e = checkSyntax(args)
				if _e == nil then return "" end

				if not _s then
					local error = _e:match(":%d+:%s*(.+)")
					local lineNumber = _e:match(":(%d+):")
					return lineNumber,error
				end
				
				return
			elseif method == "savetostore" then
				local uid = Services.StudioService:GetUserId()
				local scripts = plugin:GetSetting(uid)
				
				if scripts == nil then
					scripts = {}
				end
				
				if config == nil then
					config = Services.HttpService:GenerateGUID(false)
				end
				
				table.insert(scripts,{name = config, code = args})
				plugin:SetSetting(uid,scripts)
			elseif method == "overwriteinstore" then
				local uid = Services.StudioService:GetUserId()
				local scripts = plugin:GetSetting(uid)

				if scripts == nil then
					scripts = {}
				end

				if config == nil then
					config = Services.HttpService:GenerateGUID(false)
				end

				for index,sourceinfo in pairs(scripts) do
					if tostring(config) == tostring(sourceinfo.name) then
						sourceinfo.code = args
					end
				end
				
				plugin:SetSetting(uid,scripts)
			elseif method == "getfromstore" then
				local uid = Services.StudioService:GetUserId()
				local scripts = plugin:GetSetting(uid)
				
				if scripts == nil then
					scripts = {}
				end
				
				return scripts
			elseif method == "delinstore" then
				local uid = Services.StudioService:GetUserId()
				local scripts = plugin:GetSetting(uid)

				if scripts == nil then
					scripts = {}
				end

				if config == nil then
					config = Services.HttpService:GenerateGUID(false)
				end

				for index,sourceinfo in pairs(scripts) do
					if tostring(args) == tostring(sourceinfo.name) then
						table.remove(scripts,index)
					end
				end

				plugin:SetSetting(uid,scripts)
			end
		end
	end)
	return
end

local InjectEnabled = plugin:GetSetting("InjectEnabled")
local Keybind = plugin:GetSetting("Keybind")

if Services.RunService:IsClient() and InjectEnabled then
	local nilinstances = {}
	task.spawn(function()
		game.DescendantRemoving:Connect(function(d)
			if typeof(d) == "Instance" then
				table.insert(nilinstances,d)
			end
		end)
		
		task.spawn(function()
			while task.wait() do
				for i,v in nilinstances do
					if v and v.Parent == nil then continue end
					table.remove(nilinstances,i)
				end
			end
		end)
	end)
	task.spawn(require,script.modules.eAPI.Proxy)
	shared.___ = {}
	shared.___.___ = {
		["Keybind"] = Keybind,
		Executor = tostring(script.Parent:GetAttribute("Version")),
		eAPI = tostring(script.Parent:GetAttribute("eAPI")),
		genv = {},
		getnils = function()
			return nilinstances
		end,
		modules = script.modules,
		memory = script.memory,
		components = Components,
		plugin = plugin, 
	}
	local _RobloxReplicatedStorage = Instance.new("Folder")
	_RobloxReplicatedStorage.Name = "RobloxReplicatedStorage"
	_RobloxReplicatedStorage.Parent = shared.___.___.memory
	require(Modules.core).inject()
end