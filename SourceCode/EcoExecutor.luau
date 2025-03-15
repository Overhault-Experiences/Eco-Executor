-- // Core Stuff \\ --
local Main = script
local Components = Main.components
local Memory = Main.memory
local Modules = Main.modules

-- // Modules \\ --
local Services = require(Modules.services)
local Version = require(Modules.version)

-- // Miscellaneous \\ --
local config
local DSSEnabled, HttpEnabled, LoadStringEnabled
local function Debug()
	task.spawn(Version.CheckVersion, Version, Main:GetAttribute("Build"))

	DSSEnabled = pcall(function()
		Services.DataStoreService:GetDataStore("__"):SetAsync("__",0)
	end)

	HttpEnabled = Services.HttpService.HttpEnabled

	LoadStringEnabled = pcall(loadstring,"print(1)")

	if DSSEnabled == false then
		warn("Enable Studio Access to API Services at game settings [Security] is disabled, saveinstance will be non-functional.")
	end

	if HttpEnabled == false then
		warn("Allow HTTP Requests at game settings [Security] is disabled, some executor functions will may not work.")
	end

	if LoadStringEnabled == false then
		warn("loadstring() is not enabled, syntax error highlighting will be non-functional.")
	end
end

if not Services.RunService:IsStudio() then return end

if not Services.RunService:IsRunning() then
	local Toolbar = plugin:CreateToolbar("Eco")
	local Config = Toolbar:CreateButton("Eco Config","Eco Config: {Injection | Debug mode}","rbxassetid://79005389041499")
		
	if plugin:GetSetting("Eco_Executor_InjectEnabled") == nil then
		plugin:SetSetting("Eco_Executor_InjectEnabled",true)
	end
	
	if plugin:GetSetting("Eco_Executor_DebugMode") == true then
		task.spawn(Debug)
	elseif plugin:GetSetting("Eco_Executor_DebugMode") == nil then
		plugin:SetSetting("Eco_Executor_DebugMode", false)
	end
	
	Config.Click:Connect(function()
		if config == nil then
			local ij = plugin:GetSetting("Eco_Executor_InjectEnabled")
			local dm = plugin:GetSetting("Eco_Executor_DebugMode")
			
			config = Components.eco_config:Clone()
			config.version.Text = script:GetAttribute("Version")
			config.Parent = Services.CoreGui.RobloxGui
			
			if ij ~= nil then
				if ij == true then
					config.injection.config.Text = "Enabled"
					config.injection.config.TextColor3 = Color3.fromRGB(77, 255, 46)
				else
					config.injection.config.Text = "Disabled"
					config.injection.config.TextColor3 = Color3.fromRGB(172,0,3)
				end
			end
			
			if dm ~= nil then
				if dm == true then
					config.debug_mode.config.Text = "Enabled"
					config.debug_mode.config.TextColor3 = Color3.fromRGB(77, 255, 46)
				else
					config.debug_mode.config.Text = "Disabled"
					config.debug_mode.config.TextColor3 = Color3.fromRGB(172,0,3)
				end
			end
			
			config.injection.config.Activated:Connect(function()
				if config.injection.config.Text == "Enabled" then
					config.injection.config.Active = false
					plugin:SetSetting("Eco_Executor_InjectEnabled",false)
					config.injection.config.Text = "Disabled"
					Services.TweenService:Create(config.injection.config, TweenInfo.new(.2),{TextColor3 = Color3.fromRGB(172,0,3)}):Play()
					config.injection.config.Active = true
				else
					config.injection.config.Active = false
					plugin:SetSetting("Eco_Executor_InjectEnabled",true)
					config.injection.config.Text = "Enabled"
					Services.TweenService:Create(config.injection.config, TweenInfo.new(.2),{TextColor3 = Color3.fromRGB(77, 255, 46)}):Play()
					config.injection.config.Active = true
				end
			end)
			
			config.debug_mode.config.Activated:Connect(function()
				if config.debug_mode.config.Text == "Enabled" then
					config.debug_mode.config.Active = false
					plugin:SetSetting("Eco_Executor_DebugMode",false)
					config.debug_mode.config.Text = "Disabled"
					Services.TweenService:Create(config.debug_mode.config, TweenInfo.new(.2),{TextColor3 = Color3.fromRGB(172,0,3)}):Play()
					config.debug_mode.config.Active = true
				else
					task.spawn(Debug)
					config.debug_mode.config.Active = false
					plugin:SetSetting("Eco_Executor_DebugMode",true)
					config.debug_mode.config.Text = "Enabled"
					Services.TweenService:Create(config.debug_mode.config, TweenInfo.new(.2),{TextColor3 = Color3.fromRGB(77, 255, 46)}):Play()
					config.debug_mode.config.Active = true
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
	if plugin:GetSetting("Eco_Executor_InjectEnabled") == false then return end
	
	local IS = Instance.new("RemoteFunction")
	IS.Name = "IS"; IS.Parent = Services.ReplicatedStorage
	
	local DebugMode = plugin:GetSetting("Eco_Executor_DebugMode")
	
	if DebugMode == true then
		task.spawn(Debug)
	end
	
	task.spawn(function()
		local insert_service = Services.InsertService
		local http = Services.HttpService
		local InstanceStore,Saved,ScriptStore = 
			Services.DataStoreService:GetDataStore("InstanceStore"), 
			Services.DataStoreService:GetDataStore("SavedInstance"), 
			Services.DataStoreService:GetDataStore("ScriptStore")

		local connections = {};local connectionsnames = {}

		IS.OnServerInvoke = function(plr, ...)
			local code,method,args,config = ...
			
			if code ~= "___1___" then return end
			
			if method == "save" then
				if not DSSEnabled then return end
				
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
				if not DSSEnabled then return end
				local fetched = InstanceStore:GetAsync(plr.UserId)
				return fetched[args]
			elseif method == "request_saves" then
				if not DSSEnabled then return end
				local fetched = Saved:GetAsync(plr.UserId)
				return fetched
			elseif method == "reset" then
				if not DSSEnabled then return end
				InstanceStore:RemoveAsync(plr.UserId)
				Saved:RemoveAsync(plr.UserId)
			elseif method == "GetObject" then
				local _,r = pcall(function() return http:JSONDecode(http:PostAsync("https://assetdelivery.roproxy.com/v1/assets/batch", ([=[[{"requestId":"%d","assetId":%d}]]=]):format(args, args))) end)
				return r	
			elseif method == "HttpGet" then
				if not HttpEnabled then return "nil" end
				
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
				if not HttpEnabled then return "nil" end

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
				if not DSSEnabled then return end

				local data = ScriptStore:GetAsync(plr.UserId)

				if data == nil then
					data = {}
				end

				data[args] = config
				return ScriptStore:SetAsync(plr.UserId,data)
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
					if connectionsnames[target.Name] ~= nil then return end
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
					target.OnServerInvoke = function() return end
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
				if LoadStringEnabled == false then return end
				
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
				local scripts = plugin:GetSetting("Eco Executor_"..uid)
				
				if scripts == nil then
					scripts = {}
				end
				
				if config == nil then
					config = Services.HttpService:GenerateGUID(false)
				end
				
				local Current,Time = DateTime.now():ToLocalTime(), nil

				if Current["Hour"] > 12 then
					Time = tostring(Current["Hour"]-12)..":"..tostring(Current["Minute"])..":"..tostring(Current["Second"]).." PM"
				else
					Time = tostring(Current["Hour"])..":"..tostring(Current["Minute"])..":"..tostring(Current["Second"]).." AM"
				end
				
				local LoC = #args:split("\n")
				
				table.insert(scripts,{
					filename = config, 
					content = args, 
					date = DateTime.now():FormatLocalTime("LL", Services.LocalizationService.SystemLocaleId), 
					time = Time, 
					size = LoC,
				})
				
				plugin:SetSetting("Eco Executor_"..uid,scripts)
			elseif method == "overwriteinstore" then
				local uid = Services.StudioService:GetUserId()
				local scripts = plugin:GetSetting("Eco Executor_"..uid)

				if scripts == nil then
					scripts = {}
				end
				
				for index,sourceinfo in pairs(scripts) do
					if tostring(select(5,...)) == tostring(sourceinfo.content) or tostring(config) == tostring(sourceinfo.filename) then
						sourceinfo.content = args
					end
				end
				
				plugin:SetSetting("Eco Executor_"..uid,scripts)
			elseif method == "getfromstore" then
				local uid = Services.StudioService:GetUserId()
				local scripts = plugin:GetSetting("Eco Executor_"..uid)
				
				if scripts == nil then
					scripts = {}
				end
				
				return scripts
			elseif method == "delinstore" then
				local uid = Services.StudioService:GetUserId()
				local scripts = plugin:GetSetting("Eco Executor_"..uid)

				if scripts == nil then
					scripts = {}
				end
				
				for index,sourceinfo in pairs(scripts) do
					if tostring(args) == tostring(sourceinfo.filename) then
						table.remove(scripts,index)
					end
				end

				plugin:SetSetting("Eco Executor_"..uid,scripts)
			end
		end
	end)
	return
end

if Services.RunService:IsClient() then
	if plugin:GetSetting("Eco_Executor_InjectEnabled") == false then return end
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
	task.spawn(function()
		local drawing = Instance.new("ScreenGui"); drawing.Parent = Services.CoreGui
		drawing.Name = "Drawing | Eco"
		drawing.Enabled = true
		drawing.IgnoreGuiInset = false
		drawing.ClipToDeviceSafeArea = true
		drawing.ScreenInsets = Enum.ScreenInsets.None
		drawing.SafeAreaCompatibility = Enum.SafeAreaCompatibility.FullscreenExtension
		drawing.DisplayOrder = 2147483646
		drawing.ResetOnSpawn = false
	end)
	
	task.spawn(function()
		local notification = Instance.new("ScreenGui"); notification.Parent = Services.CoreGui
		notification.Name = "Notification | Eco"
		notification.Enabled = true
		notification.IgnoreGuiInset = false
		notification.ClipToDeviceSafeArea = true
		notification.ScreenInsets = Enum.ScreenInsets.None
		notification.SafeAreaCompatibility = Enum.SafeAreaCompatibility.FullscreenExtension
		notification.DisplayOrder = 2147483647
		notification.ResetOnSpawn = false
	end)
	
	shared.___ = {}
	shared.___.___ = {
		Executor = tostring(Main:GetAttribute("Version")),
		eAPI = tostring(Main:GetAttribute("eAPI")),
		genv = {},
		getnils = function() return nilinstances end,
		modules = script.modules,
		memory = script.memory,
		plugin = plugin,
		components = Components,
	}
	
	local _RobloxReplicatedStorage = Instance.new("Folder")
	_RobloxReplicatedStorage.Name = "RobloxReplicatedStorage"
	_RobloxReplicatedStorage.Parent = shared.___.___.memory
	
	require(Modules.core).inject()	
end