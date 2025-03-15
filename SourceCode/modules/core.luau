local core = {}
local Services = require(script.Parent.services)
local Components = script.Parent.Parent.components
local modules = {sh = require(script.syntax_highlighter)}
local memory = shared.___.___.memory :: Folder
local plugin = shared.___.___.plugin :: Plugin
local current_order = 1
local IS = Services.ReplicatedStorage:WaitForChild("IS",math.huge) :: RemoteFunction
local DockWidgetInfos = {
	Main = DockWidgetPluginGuiInfo.new(
		Enum.InitialDockState.Float,
		false,
		false,
		657,
		305,
		657,
		305
	),
	Console = DockWidgetPluginGuiInfo.new(
		Enum.InitialDockState.Float,
		false,
		false,
		292,
		376,
		292,
		376
	),
	FileStore = DockWidgetPluginGuiInfo.new(
		Enum.InitialDockState.Float,
		false,
		false,
		689,
		406,
		689,
		606
	)
}

local function execute(source: string, noparent:boolean?)
	if source == "" then return end
	
	local run = Instance.new("ModuleScript"); run.Name = "code_execution_"..tostring(Services.HttpService:GenerateGUID(false)); run.Parent = memory; run.Source = ""
	xpcall(function()
		run.Source = [[
require(shared.___.___.modules.eAPI)(); local script=nil;shared.a = {["script"] = "ExecutionScript";["shared"] = {};["_G"] = {}} local function getfenv() return shared.a end; local _G = shared.a._G;  local shared = shared.a.shared
do
	]]..source..[[ 
end

return {}]]
	end, function()
		run.Parent = Services.CoreGui.RobloxGui.Modules.Common.CommonUtil
		Services.ScriptEditorService:OpenScriptDocumentAsync(run)
		local sd = Services.ScriptEditorService:FindScriptDocument(run)
		sd:EditTextAsync([[
require(shared.___.___.modules.eAPI)(); local script=nil;shared.a = {["script"] = "ExecutionScript";["shared"] = {};["_G"] = {}} local function getfenv() return shared.a end; local _G = shared.a._G;  local shared = shared.a.shared
do
	]]..source..[[ 
end

return {}]],1,1,math.huge,math.huge)
		sd:CloseAsync()
		run.Parent = memory
	end)
	
	if noparent then
		run.Parent = nil
	end
	
	xpcall(function()
		require(run)
		run:Destroy()
	end, function()
		run:Destroy()
	end)
end

function core.inject()
	if not Services.RunService:IsClient() then error("Inject can only be called from client.",0) end
	
	local maincomponents = Components.main
	local executor = maincomponents.main
	local dock
	
	dock = plugin:CreateDockWidgetPluginGui("Eco Executor", DockWidgetInfos.Main)
	executor.Parent = dock
	dock.Title = "Eco Executor"
	dock.Name = "eco"
	
	local console = maincomponents.console
	local current_ec_content = executor.current_ec_content
	local main_content = current_ec_content.Value
	local logs = console.logs
	local editors = executor.editors
	local file = executor.file
	local controls = executor.controls
	local scripts = executor.scripts
	local toolbar = executor.toolbar

	main_content.context.syntax.Text = modules.sh.run(main_content.context.ContentText)

	main_content.context:GetPropertyChangedSignal("Text"):Connect(function()
		local fetched = main_content.context.ContentText

		task.spawn(function()
			main_content.context.syntax.Text = modules.sh.run(fetched)
		end)
		
		local syntaxerrors = main_content.syntaxerrors
		local currentpos = main_content.context.CursorPosition - 1
		local bc = main_content.context.Text:sub(1,currentpos)
		local editingline = #bc:split("\n")
		local EditableLines = #(string.split(fetched, "\n"))
		local ParentedLines = main_content.lines:GetChildren()
		local Counted = #ParentedLines - 1

		if Counted < EditableLines then
			for i = Counted + 1, EditableLines do
				local Line = Components["1"]:Clone()
				local syntaxerrorline = Components.syntaxerrorline:Clone()
				task.spawn(function()
					Line.Name = i
					Line.Text = i
					Line.LayoutOrder = i
					Line.Parent = main_content.lines
				end)
				task.spawn(function()
					syntaxerrorline.Name = i
					syntaxerrorline.LayoutOrder = i
					syntaxerrorline.Parent = main_content.syntaxerrors
				end)
			end
		else
			for i = EditableLines + 1, Counted do
				main_content.lines[i]:Destroy()
				main_content.syntaxerrors[i]:Destroy()
			end
		end
		
		if fetched:split("\n")[1]:split(" ")[1] == "--!noSyntaxCheck" then
			task.spawn(function()
				for _,v in syntaxerrors:GetChildren() do
					if not v:IsA("TextLabel") then continue end
					if v.Name == tostring(editingline) then
						v.BackgroundColor3 = Services.Studio["Current Line Highlight Color"]
						v.BackgroundTransparency = .55
						continue
					end
					v.BackgroundTransparency = 1
					v.TextTransparency = 1
				end
			end)
			
			task.spawn(function()
				for i,v in main_content.lines:GetChildren() do
					if not v:IsA("TextLabel") then continue end
					Services.TweenService:Create(v,TweenInfo.new(.2),{TextColor3 = Color3.fromRGB(255,255,255)}):Play()
				end
			end)
			return
		end
		
		local line,err = IS:InvokeServer("___1___","checkerror",main_content.context.ContentText)
		if line == nil or err == nil then
			task.spawn(function()
				for _,v in syntaxerrors:GetChildren() do
					if not v:IsA("TextLabel") then continue end
					if v.Name == tostring(editingline) then
						v.BackgroundColor3 = Services.Studio["Current Line Highlight Color"]
						v.BackgroundTransparency = .55
						continue
					end
					v.BackgroundTransparency = 1
					v.TextTransparency = 1
				end
			end)
			task.spawn(function()
				for i,v in main_content.lines:GetChildren() do
					if not v:IsA("TextLabel") then continue end
					Services.TweenService:Create(v,TweenInfo.new(.2),{TextColor3 = Color3.fromRGB(255,255,255)}):Play()
				end
			end)
			return
		end
		
		local ErrorLine = main_content.lines:FindFirstChild(tostring(line)) :: TextLabel
		Services.TweenService:Create(ErrorLine,TweenInfo.new(.2), {TextColor3 = Color3.fromRGB(217,3,3)}):Play()
		if syntaxerrors:FindFirstChild(line) then
			local syntaxerror = syntaxerrors:FindFirstChild(line) :: TextLabel
			syntaxerror.Text = err
			syntaxerror.BackgroundColor3 = Color3.fromRGB(188, 34, 39)
			syntaxerror.TextTransparency = 1
			syntaxerror.BackgroundTransparency = .5
			ErrorLine.MouseEnter:Connect(function()
				if ErrorLine.TextColor3 == Color3.fromRGB(255,255,255) then return end
				syntaxerror.ZIndex = 2
				Services.TweenService:Create(syntaxerror,TweenInfo.new(.3),{TextTransparency = 0}):Play()
				Services.TweenService:Create(syntaxerror,TweenInfo.new(.3),{BackgroundTransparency = 0}):Play()
			end)
			ErrorLine.MouseLeave:Connect(function()
				if ErrorLine.TextColor3 == Color3.fromRGB(255,255,255) then return end
				syntaxerror.ZIndex = 1
				Services.TweenService:Create(syntaxerror,TweenInfo.new(.3),{TextTransparency = 1}):Play()
				Services.TweenService:Create(syntaxerror,TweenInfo.new(.3),{BackgroundTransparency = 0.5}):Play()
			end)
			return
		end
		
		local syntaxerror = Components.syntaxerrorline:Clone()
		syntaxerror.Name = line
		syntaxerror.LayoutOrder = line
		syntaxerror.Text = err
		syntaxerror.TextTransparency = 1
		syntaxerror.BackgroundTransparency = .5
		syntaxerror.Parent = syntaxerrors
		
		ErrorLine.MouseEnter:Connect(function()
			if ErrorLine.TextColor3 == Color3.fromRGB(255,255,255) then return end
			syntaxerror.ZIndex = 2
			Services.TweenService:Create(syntaxerror,TweenInfo.new(.3),{TextTransparency = 0}):Play()
			Services.TweenService:Create(syntaxerror,TweenInfo.new(.3),{BackgroundTransparency = 0}):Play()
		end)
		
		ErrorLine.MouseLeave:Connect(function()
			if ErrorLine.TextColor3 == Color3.fromRGB(255,255,255) then return end
			syntaxerror.ZIndex = 1
			Services.TweenService:Create(syntaxerror,TweenInfo.new(.3),{TextTransparency = 1}):Play()
			Services.TweenService:Create(syntaxerror,TweenInfo.new(.3),{BackgroundTransparency = 0.5}):Play()
		end)
	end)

	main_content.context:GetPropertyChangedSignal("CursorPosition"):Connect(function()
		if main_content.context.CursorPosition == -1 then return end
		
		local currentpos = main_content.context.CursorPosition - 1
		local bc = main_content.context.Text:sub(1,currentpos)
		local editingline = #bc:split("\n")

		task.spawn(function()
			for i,v in main_content.syntaxerrors:GetChildren() do
				if not v:IsA("TextLabel") then continue end
				if v.BackgroundTransparency <= 0.5 then continue end
				if v.Name == tostring(editingline) then
					v.BackgroundColor3 = Services.Studio["Current Line Highlight Color"]
					v.BackgroundTransparency = .55
					continue
				end
				v.BackgroundTransparency = 1
			end
		end)
		
		for i,v in main_content.lines:GetChildren() do
			if not v:IsA("TextLabel") then continue end
			if (v.Text == tostring(editingline)) == true then
				v.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json",Enum.FontWeight.Bold,Enum.FontStyle.Normal)
			else
				v.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json",Enum.FontWeight.Regular,Enum.FontStyle.Normal)
			end
		end
	end)
	
	controls.execute.Activated:Connect(function()
		controls.execute.BackgroundColor3 = controls.execute.UIStroke.Color
		
		if controls.execution_context.Text == "Studio" then
			task.spawn(execute,current_ec_content.Value.context.syntax.ContentText,true)
			Services.TweenService:Create(controls.execute,TweenInfo.new(.35),{BackgroundColor3 = Color3.fromRGB(45,45,45)}):Play()
			return
		end
		
		task.spawn(execute,current_ec_content.Value.context.syntax.ContentText)
		Services.TweenService:Create(controls.execute,TweenInfo.new(.35),{BackgroundColor3 = Color3.fromRGB(45,45,45)}):Play()
	end)
	
	controls.clear.Activated:Connect(function()
		controls.clear.BackgroundColor3 = Color3.fromRGB(190, 0, 0)
		current_ec_content.Value.context.Text = ""
		Services.TweenService:Create(controls.clear,TweenInfo.new(.35),{BackgroundColor3 = Color3.fromRGB(45,45,45)}):Play()
	end)
	
	controls.execution_context.Activated:Connect(function()
		if controls.execution_context.Text == "Client" then
			controls.execution_context.Text = "Studio"
			Services.TweenService:Create(controls.execution_context, TweenInfo.new(.2), {TextColor3 = Color3.fromRGB(84,84,84)}):Play()
			Services.TweenService:Create(controls.execution_context.UIStroke, TweenInfo.new(.2), {Color = Color3.fromRGB(84,84,84)}):Play()
			Services.TweenService:Create(controls.execute.UIStroke, TweenInfo.new(.2), {Color = Color3.fromRGB(84,84,84)}):Play()
		else
			controls.execution_context.Text = "Client"
			Services.TweenService:Create(controls.execution_context, TweenInfo.new(.2), {TextColor3 = Color3.fromRGB(31, 109, 227)}):Play()
			Services.TweenService:Create(controls.execution_context.UIStroke, TweenInfo.new(.2), {Color = Color3.fromRGB(31, 109, 227)}):Play()
			Services.TweenService:Create(controls.execute.UIStroke, TweenInfo.new(.2), {Color = Color3.fromRGB(31, 109, 227)}):Play()
		end
	end)
	
	task.spawn(function()
		for i,v in controls:GetChildren() do
			if not v:IsA("TextButton") then continue end
			v.MouseEnter:Connect(function()
				Services.TweenService:Create(v.UIStroke, TweenInfo.new(.2), {Transparency = 0}):Play()
			end)
			v.MouseLeave:Connect(function()
				Services.TweenService:Create(v.UIStroke, TweenInfo.new(.2), {Transparency = 1}):Play()
			end)
		end
	end)

	scripts.main.Activated:Connect(function()
		scripts.main.Active = false
		scripts.main.AutoButtonColor = false
		scripts.main.BackgroundColor3 = Color3.fromRGB(30,30,30)
		current_ec_content.Value = editors.editor_main

		task.spawn(function()
			for _,s in scripts:GetChildren() do
				if s:IsA("Frame") then
					s.script.Active = true
					s.script.AutoButtonColor = true
					s.script.BackgroundColor3 = Color3.fromRGB(50,50,50)
					s.close.BackgroundColor3 = Color3.fromRGB(50,50,50)
				end
			end
		end)

		for _,c in editors:GetChildren() do
			task.spawn(function()
				if c.Name == "editor_main" then
					c.context.Visible = true
					c.context.syntax.Visible = true
					c.lines.Visible = true
					c.syntaxerrors.Visible = true
				else
					c.context.Visible = false
					c.context.syntax.Visible = false
					c.lines.Visible = false
					c.syntaxerrors.Visible = false
				end
			end)
		end
	end)

	scripts.plus.Activated:Connect(function()
		local _script = Components.script2:Clone()
		local _content = editors.editor_main:Clone()
		_content.context.Text = [[print("Hello from Eco Executor!")]]
		_content.context.syntax.Text = modules.sh.run([[print("Hello from Eco Executor!")]])

		if current_order ~= 9 then
			current_order += 1
			_content.Name = "editor_"..current_order
			_content.lines.Visible = false
			task.spawn(function()
				for _,v in _content.lines:GetChildren() do
					if not v:IsA("TextLabel") then continue end
					if v.Name == "1" then continue end
					v:Destroy()
				end
			end)

			task.spawn(function()
				for _,v in _content.syntaxerrors:GetChildren() do
					if not v:IsA("TextLabel") then continue end
					if v.Name == "1" then continue end
					v:Destroy()
				end
			end)

			_content.syntaxerrors.Visible = false
			_content.lines.Visible = false
			_content.context.Visible = false
			_content.context.syntax.Visible = false
			_content.Parent = editors

			_content.context:GetPropertyChangedSignal("Text"):Connect(function()
				local fetched = _content.context.ContentText

				task.spawn(function()
					_content.context.syntax.Text = modules.sh.run(fetched)
				end)
				
				local syntaxerrors = _content.syntaxerrors
				local currentpos = _content.context.CursorPosition - 1
				local bc = _content.context.Text:sub(1,currentpos)
				local editingline = #bc:split("\n")
				local EditableLines = #(string.split(fetched, "\n"))
				local ParentedLines = _content.lines:GetChildren()
				local Counted = #ParentedLines - 1
				if Counted < EditableLines then
					for i = Counted + 1, EditableLines do
						local Line = Components["1"]:Clone()
						local syntaxerrorline = Components.syntaxerrorline:Clone()
						task.spawn(function()
							Line.Name = i
							Line.Text = i
							Line.LayoutOrder = i
							Line.Parent = _content.lines
						end)
						task.spawn(function()
							syntaxerrorline.Name = i
							syntaxerrorline.LayoutOrder = i
							syntaxerrorline.Parent = _content.syntaxerrors
						end)
					end
				else
					for i = EditableLines + 1, Counted do
						_content.lines[i]:Destroy()
						_content.syntaxerrors[i]:Destroy()
					end
				end
				
				if fetched:split("\n")[1]:split(" ")[1] == "--!noSyntaxCheck" then
					task.spawn(function()
						for _,v in syntaxerrors:GetChildren() do
							if not v:IsA("TextLabel") then continue end
							if v.Name == tostring(editingline) then
								v.BackgroundColor3 = Services.Studio["Current Line Highlight Color"]
								v.BackgroundTransparency = .55
								continue
							end
							v.BackgroundTransparency = 1
							v.TextTransparency = 1
						end
					end)
					
					task.spawn(function()
						for i,v in _content.lines:GetChildren() do
							if not v:IsA("TextLabel") then continue end
							Services.TweenService:Create(v,TweenInfo.new(.2),{TextColor3 = Color3.fromRGB(255,255,255)}):Play()
						end
					end)
					return
				end
				
				local line,err = IS:InvokeServer("___1___","checkerror",_content.context.ContentText)
				if line == nil or err == nil then
					task.spawn(function()
						for _,v in syntaxerrors:GetChildren() do
							if not v:IsA("TextLabel") then continue end
							if v.Name == tostring(editingline) then
								v.BackgroundColor3 = Services.Studio["Current Line Highlight Color"]
								v.BackgroundTransparency = .55
								continue
							end
							v.BackgroundTransparency = 1
							v.TextTransparency = 1
						end
					end)
					
					task.spawn(function()
						for i,v in _content.lines:GetChildren() do
							if not v:IsA("TextLabel") then continue end
							Services.TweenService:Create(v,TweenInfo.new(.2),{TextColor3 = Color3.fromRGB(255,255,255)}):Play()
						end
					end)
					return
				end
				local ErrorLine = _content.lines:FindFirstChild(line) :: TextLabel
				Services.TweenService:Create(ErrorLine,TweenInfo.new(.2), {TextColor3 = Color3.fromRGB(217,3,3)}):Play()
				if syntaxerrors:FindFirstChild(line) then
					local syntaxerror = syntaxerrors:FindFirstChild(line) :: TextLabel
					syntaxerror.BackgroundColor3 = Color3.fromRGB(188, 34, 39)
					syntaxerror.Text = err
					syntaxerror.TextTransparency = 1
					syntaxerror.BackgroundTransparency = .5
					ErrorLine.MouseEnter:Connect(function()
						if ErrorLine.TextColor3 == Color3.fromRGB(255,255,255) then return end
						syntaxerror.ZIndex = 2
						Services.TweenService:Create(syntaxerror,TweenInfo.new(.3),{TextTransparency = 0}):Play()
						Services.TweenService:Create(syntaxerror,TweenInfo.new(.3),{BackgroundTransparency = 0}):Play()
					end)
					ErrorLine.MouseLeave:Connect(function()
						if ErrorLine.TextColor3 == Color3.fromRGB(255,255,255) then return end
						syntaxerror.ZIndex = 1
						Services.TweenService:Create(syntaxerror,TweenInfo.new(.3),{TextTransparency = 1}):Play()
						Services.TweenService:Create(syntaxerror,TweenInfo.new(.3),{BackgroundTransparency = 0.5}):Play()
					end)
					return
				end
				local syntaxerror = Components.syntaxerrorline:Clone()
				syntaxerror.Name = line
				syntaxerror.LayoutOrder = line
				syntaxerror.Text = err
				syntaxerror.TextTransparency = 1
				syntaxerror.BackgroundTransparency = .5
				syntaxerror.Parent = syntaxerrors
				ErrorLine.MouseEnter:Connect(function()
					if ErrorLine.TextColor3 == Color3.fromRGB(255,255,255) then return end
					syntaxerror.ZIndex = 2
					Services.TweenService:Create(syntaxerror,TweenInfo.new(.3),{TextTransparency = 0}):Play()
					Services.TweenService:Create(syntaxerror,TweenInfo.new(.3),{BackgroundTransparency = 0}):Play()
				end)
				ErrorLine.MouseLeave:Connect(function()
					if ErrorLine.TextColor3 == Color3.fromRGB(255,255,255) then return end
					syntaxerror.ZIndex = 1
					Services.TweenService:Create(syntaxerror,TweenInfo.new(.3),{TextTransparency = 1}):Play()
					Services.TweenService:Create(syntaxerror,TweenInfo.new(.3),{BackgroundTransparency = 0.5}):Play()
				end)
			end)

			_content.context:GetPropertyChangedSignal("CursorPosition"):Connect(function()
				if _content.context.CursorPosition == -1 then return end
				local currentpos = _content.context.CursorPosition - 1
				local bc = _content.context.Text:sub(1,currentpos)
				local editingline = #bc:split("\n")

				task.spawn(function()
					for i,v in _content.syntaxerrors:GetChildren() do
						if not v:IsA("TextLabel") then continue end
						if v.BackgroundTransparency <= 0.5 then continue end
						if v.Name == tostring(editingline) then
							v.BackgroundColor3 = Services.Studio["Current Line Highlight Color"]
							v.BackgroundTransparency = .55
							continue
						end
						v.BackgroundTransparency = 1
					end
				end)
				for i,v in _content.lines:GetChildren() do
					if not v:IsA("TextLabel") then continue end
					if (v.Text == tostring(editingline)) == true then
						v.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json",Enum.FontWeight.Bold,Enum.FontStyle.Normal)
					else
						v.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json",Enum.FontWeight.Regular,Enum.FontStyle.Normal)
					end
				end
			end)

			_script.Name = "script"..current_order
			_script.script.Text = "script"..current_order..".lua"

			_script.script.Activated:Connect(function()
				_script.script.BackgroundColor3 = Color3.fromRGB(30, 30, 30)

				task.spawn(function()
					for _,s in scripts:GetChildren() do
						if s:IsA("TextButton") and s.Name == "main" then
							s.AutoButtonColor = true
							s.Active = true
							s.BackgroundColor3 = Color3.fromRGB(50,50,50)
						elseif s:IsA("Frame") and s ~= _script then
							s.script.Active = true
							s.script.AutoButtonColor = true
							s.script.BackgroundColor3 = Color3.fromRGB(50,50,50)
							s.close.BackgroundColor3 = Color3.fromRGB(50,50,50)
						end
					end
				end)

				_script.script.Active = false
				_script.script.AutoButtonColor = false
				_script.script.BackgroundColor3 = Color3.fromRGB(30,30,30)
				_script.close.BackgroundColor3 = Color3.fromRGB(30,30,30)
				current_ec_content.Value = _content

				for _,v in editors:GetChildren() do
					if v.Name ~= _content.Name then
						v.lines.Visible  = false
						v.syntaxerrors.Visible = false
						v.context.Visible = false
						v.context.syntax.Visible = false
					end
				end

				_content.lines.Visible = true
				_content.context.Visible = true
				_content.context.syntax.Visible = true
				_content.syntaxerrors.Visible = true
			end)

			_script.close.Activated:Connect(function()
				_script.close.Active = false
				_script.close.AutoButtonColor = false
				current_order -= 1
				editors:FindFirstChild(_content.Name):Destroy()

				if current_order == 1 then
					editors:FindFirstChild("editor_main").lines.Visible = true
					editors:FindFirstChild("editor_main").context.Visible = true
					editors:FindFirstChild("editor_main").context.syntax.Visible = true
					editors:FindFirstChild("editor_main").syntaxerrors.Visible = true
					current_ec_content.Value = editors.editor_main
					local _s = scripts.main
					_s.Active = false
					_s.AutoButtonColor = false
					_s.BackgroundColor3 = Color3.fromRGB(30,30,30)
				elseif scripts.main.Active == true then
					local _ec = editors:FindFirstChild("editor_"..current_order)
					local status

					for _,v in scripts:GetChildren() do
						if not v:IsA("Frame") then continue end
						if v.script.Active == false and v ~= _script then status = 1 break end
					end

					if status == 1 then _script:Destroy() _content:Destroy() return end

					if _ec == nil then 
						local plus = current_order + 1
						local _ec = editors:FindFirstChild("editor_"..tostring(plus))
						if _ec == nil then _ec = editors:FindFirstChild("editor_"..tostring(plus + 1)) end
						if _ec == nil then _ec = editors[math.random(1,#editors)] end
						_ec.lines.Visible = true
						_ec.context.Visible = true
						_ec.context.syntax.Visible = true
						_ec.syntaxerrors.Visible = true
						current_ec_content.Value = _ec
						if _ec.Name ~= "editor_main" then _ec.Name = "editor_"..tostring(current_order) end
						local _s = scripts:FindFirstChild("script"..tostring(plus))
						if _s == nil then _s = scripts:FindFirstChild("script"..tostring(plus + 1)) end
						if _s == nil then _s = scripts[math.random(1,#scripts)] end
						_s.Name = "script"..tostring(current_order)
						_s.script.Text = "script"..tostring(current_order)..".lua"
						_s.script.Active = false
						_s.script.AutoButtonColor = false
						_s.script.BackgroundColor3 = Color3.fromRGB(30,30,30)
						_s.close.BackgroundColor3 = Color3.fromRGB(30,30,30)
						_script:Destroy()
						_content:Destroy()
						return
					end

					_ec.lines.Visible = true
					_ec.context.Visible = true
					_ec.context.syntax.Visible = true
					_ec.syntaxerrors.Visible = true
					current_ec_content.Value = _ec
					local _s = scripts:FindFirstChild("script"..current_order)
					_s.script.Active = false
					_s.script.AutoButtonColor = false
					_s.script.BackgroundColor3 = Color3.fromRGB(30,30,30)
					_s.close.BackgroundColor3 = Color3.fromRGB(30,30,30)
				end

				_script:Destroy()
				_content:Destroy()
			end)

			_script.Parent = scripts
		end
	end)

	-- // File System Initialization \\ --
	local filestore = maincomponents.filestore
	local filestore_dock = plugin:CreateDockWidgetPluginGui("Eco FileStore", DockWidgetInfos.FileStore)
	filestore.Parent = filestore_dock
	filestore_dock.Title = "Eco FileStore"
	filestore_dock.Name = "eco_filestore"
	
	local UCS = function()
		local padding = filestore.files.UIListLayout.Padding.Offset
		local buttonHeight = filestore.files:FindFirstChildOfClass("TextButton").Size.Y.Offset
		local buttonCount = #filestore.files:GetChildren()
		local totalHeight = buttonCount * buttonHeight + padding * (buttonCount - 1)
		filestore.files.CanvasSize = UDim2.new(0, 0, 0, totalHeight + padding * 2)
		filestore.files.CanvasPosition = Vector2.new(0,0)
	end

	toolbar.file.Activated:Connect(function()
		if file.BackgroundTransparency == 0 then
			Services.TweenService:Create(toolbar.file,TweenInfo.new(.2),{BackgroundColor3 = Color3.fromRGB(45,45,45)}):Play()
			task.spawn(function()
				for _,v:Instance in file:GetChildren() do
					if not v:IsA("TextButton") then continue end
					task.spawn(function()
						Services.TweenService:Create(v,TweenInfo.new(.2),{BackgroundTransparency = 1}):Play()
						task.wait(.2)
						v.Visible = false
					end)
				end
			end)
			Services.TweenService:Create(file,TweenInfo.new(.25),{BackgroundTransparency = 1}):Play()
			toolbar.file.AutoButtonColor = true
			file.Visible = false
		else
			toolbar.file.AutoButtonColor = false
			file.Visible = true
			Services.TweenService:Create(toolbar.file,TweenInfo.new(.2),{BackgroundColor3 = Color3.fromRGB(35,35,35)}):Play()
			task.spawn(function()
				for _,v:Instance in file:GetChildren() do
					if not v:IsA("TextButton") then continue end
					task.spawn(function()
						v.Visible = true
						Services.TweenService:Create(v,TweenInfo.new(.2),{BackgroundTransparency = 0}):Play()
					end)
				end
			end)
			Services.TweenService:Create(file,TweenInfo.new(.25),{BackgroundTransparency = 0}):Play()
		end
	end)

	filestore_dock:GetPropertyChangedSignal("Enabled"):Connect(function()
		if filestore_dock.Enabled ~= false then return end
		file.importstore.Active = true; file.delete.Active = true
		filestore:SetAttribute("mode",nil)
	end)

	local function load()
		local scripts = IS:InvokeServer("___1___","getfromstore")

		for _,v in filestore.files:GetChildren() do
			if not v:IsA("TextButton") then continue end
			v:Destroy()
		end

		for index,sourceinfo in pairs(scripts) do
			local newsavedfile = Components.filename:Clone()
			newsavedfile.Name = sourceinfo.filename
			newsavedfile.Text = "  "..sourceinfo.filename
			newsavedfile:SetAttribute("source",sourceinfo.content)
			newsavedfile.date.Text = "  "..sourceinfo.date
			newsavedfile.time.Text = "  "..sourceinfo.time
			newsavedfile.size.Text = "  "..sourceinfo.size.." LoC"
			newsavedfile.Parent = filestore.files
			task.spawn(UCS)
		end

		for _,v in filestore.files:GetChildren() do
			if not v:IsA("TextButton") then continue end
			v.MouseEnter:Connect(function()
				if filestore:GetAttribute("mode") == "import" then
					Services.TweenService:Create(v,TweenInfo.new(.2),{BackgroundColor3 = Color3.fromRGB(24, 70, 126)}):Play()
				else
					Services.TweenService:Create(v,TweenInfo.new(.2),{BackgroundColor3 = Color3.fromRGB(126, 0, 2)}):Play()
				end
			end)
			v.MouseLeave:Connect(function()
				Services.TweenService:Create(v,TweenInfo.new(.2),{BackgroundColor3 = Color3.fromRGB(35,35,35)}):Play()
			end)
			v.Activated:Connect(function()
				if filestore:GetAttribute("mode") == "import" then
					filestore:SetAttribute("mode",nil)
					filestore_dock.Enabled = false
					current_ec_content.Value.context.Text = v:GetAttribute("source")
					file.importstore.Active = true
				elseif filestore:GetAttribute("mode") == "del" then
					IS:InvokeServer("___1___","delinstore",v.Name)
					v:Destroy()
				end
			end)
		end
	end

	task.spawn(load)

	for _,v: Instance in file:GetChildren() do
		if not v:IsA("TextButton") then continue end
		v.MouseEnter:Connect(function()
			Services.TweenService:Create(v,TweenInfo.new(.2),{BackgroundColor3 = Color3.fromRGB(24, 70, 126)}):Play()
		end)
		v.MouseLeave:Connect(function()
			Services.TweenService:Create(v,TweenInfo.new(.2),{BackgroundColor3 = Color3.fromRGB(35,35,35)}):Play()
		end)
	end

	file.save.Activated:Connect(function()
		file.save.Active = false
		local fetchedscript = current_ec_content.Value.context.ContentText :: string
		
		if fetchedscript == "" then
			Services.StarterGui:SetCore("SendNotification",{
				Title = "Eco Executor",
				Text = "Failed to save to File, the script is empty",
			})
			file.save.Active = true
			return
		end
		
		if fetchedscript:split("\n")[1]:split(" ")[1] == "--!nameFile" then
			local filename = fetchedscript:split("\n")[1]:split(" ")[2]
			local x = fetchedscript:split("\n")
			table.remove(x,1)
			local fetchedscript = table.concat(x,"\n")
			IS:InvokeServer("___1___","savetostore",fetchedscript,filename)
		elseif fetchedscript:split("\n")[1]:split(" ")[1] == "--!overwriteFile" then
			local filename = fetchedscript:split("\n")[1]:split(" ")[2]
			local x = fetchedscript:split("\n")
			table.remove(x,1)
			local fetchedscript = table.concat(x,"\n")
			local ogcontent = filestore.files[filename]
			if ogcontent then
				ogcontent = ogcontent:GetAttribute("source")
			end
			IS:InvokeServer("___1___","overwriteinstore",fetchedscript,filename,ogcontent) 
		else
			IS:InvokeServer("___1___","savetostore",fetchedscript)
		end
		
		task.spawn(load)
		Services.TweenService:Create(toolbar.file,TweenInfo.new(.2),{BackgroundColor3 = Color3.fromRGB(45,45,45)}):Play()
		task.spawn(function()
			for _,v:Instance in file:GetChildren() do
				if not v:IsA("TextButton") then continue end
				task.spawn(function()
					Services.TweenService:Create(v,TweenInfo.new(.2),{BackgroundTransparency = 1}):Play()
					task.wait(.2)
					v.Visible = false
				end)
			end
		end)
		
		Services.TweenService:Create(file,TweenInfo.new(.25),{BackgroundTransparency = 1}):Play()
		toolbar.file.AutoButtonColor = true
		file.Visible = false
		file.save.Active = true
	end)

	file.import.Activated:Connect(function()
		file.import.Active = false
		local currentscript = current_ec_content.Value.context:: TextBox
		local importedfile = Services.StudioService:PromptImportFile({"luau","lua","txt"}) :: File

		if not importedfile then 
			Services.TweenService:Create(file,TweenInfo.new(.25),{BackgroundTransparency = 1}):Play()
			toolbar.file.AutoButtonColor = true
			file.Visible = false
			file.import.Active = true  return 
		end

		local importedscript = importedfile:GetBinaryContents()
		local s,_ = pcall(function()
			currentscript.Text = importedscript
		end)

		if not s then
			Services.StarterGui:SetCore("SendNotification",{
				Title = "Eco Executor",
				Text = "Failed to import from File, the File might be corrupted or the size might be too large (use `Execute from File` instead)",
			})
			file.import.Active = true
			return
		end

		Services.TweenService:Create(toolbar.file,TweenInfo.new(.2),{BackgroundColor3 = Color3.fromRGB(45,45,45)}):Play()
		task.spawn(function()
			for _,v:Instance in file:GetChildren() do
				if not v:IsA("TextButton") then continue end
				task.spawn(function()
					Services.TweenService:Create(v,TweenInfo.new(.2),{BackgroundTransparency = 1}):Play()
					task.wait(.2)
					v.Visible = false
				end)
			end
		end)

		Services.TweenService:Create(file,TweenInfo.new(.25),{BackgroundTransparency = 1}):Play()
		toolbar.file.AutoButtonColor = true
		file.Visible = false
		file.import.Active = true
	end)

	file.importstore.Activated:Connect(function()
		file.importstore.Active = false
		filestore:SetAttribute("mode","import")
		filestore_dock.Enabled = true
	end)

	file.execute.Activated:Connect(function()
		file.execute.Active = false
		local importedfile = Services.StudioService:PromptImportFile({"luau","lua","txt"}) :: File
		local importedscript = if importedfile then importedfile:GetBinaryContents() else nil

		if importedscript == nil then 
			Services.TweenService:Create(file,TweenInfo.new(.25),{BackgroundTransparency = 1}):Play()
			toolbar.file.AutoButtonColor = true
			file.Visible = false
			file.execute.Active = true
			return
		end

		task.spawn(execute,importedscript)
		Services.TweenService:Create(toolbar.file,TweenInfo.new(.2),{BackgroundColor3 = Color3.fromRGB(45,45,45)}):Play()
		task.spawn(function()
			for _,v:Instance in file:GetChildren() do
				if not v:IsA("TextButton") then continue end
				task.spawn(function()
					Services.TweenService:Create(v,TweenInfo.new(.2),{BackgroundTransparency = 1}):Play()
					task.wait(.2)
					v.Visible = false
				end)
			end
		end)
		Services.TweenService:Create(file,TweenInfo.new(.25),{BackgroundTransparency = 1}):Play()
		toolbar.file.AutoButtonColor = true
		file.Visible = false
		file.execute.Active = true
	end)

	file.delete.Activated:Connect(function()
		file.delete.Active = false
		filestore:SetAttribute("mode","del")
		filestore_dock.Enabled = true
	end)

	-- // Console Initialization \\ --
	local console_dock = plugin:CreateDockWidgetPluginGui("Eco Console", DockWidgetInfos.Console)
	console_dock.Title = "Eco Console"
	console_dock.Name = "eco_console"
	console.Parent = console_dock
	
	toolbar.console.Activated:Connect(function()
		console_dock.Enabled = not console_dock.Enabled
	end)

	console.input.FocusLost:Connect(function(eP)
		if not eP or console.input.Text == "" then return end
		local fetched_text = console.input.Text
		local newc = Components.log:Clone()

		newc.Name = "input_log"
		newc.Text = fetched_text
		newc.Parent = console.logs 
		console.input.Text = ""
	end)

	local function UpdateCanvasSize()
		local padding = logs.UIListLayout.Padding.Offset
		local buttonHeight = logs:GetChildren()[2].Size.Y.Offset
		local buttonCount = #logs:GetChildren()
		local totalHeight = buttonCount * buttonHeight + padding * (buttonCount - 1)
		logs.CanvasSize = UDim2.new(0, 0, 0, totalHeight + padding * 2)
		logs.CanvasPosition = Vector2.new(0,0)
	end

	logs.ChildAdded:Connect(function(c)
		if c:IsA("TextBox") then
			task.spawn(UpdateCanvasSize)
		end
	end)
	
	local executor_control = plugin:CreateToolbar("Eco")
	executor_control:CreateButton("Eco Executor","Toggle Eco Executor", "rbxassetid://79005389041499").Click:Connect(function()
		dock.Enabled = not dock.Enabled
	end)

	execute([[
repeat
	local s,_ = pcall(function()
	return	game:GetService("StarterGui"):SetCore("SendNotification",{
				Title = "Eco Executor",
				Text = "Eco Executor injected. Have fun debugging.",
				Icon = "rbxassetid://79005389041499",
			})
	end)	
until s == true
]])
end

return core