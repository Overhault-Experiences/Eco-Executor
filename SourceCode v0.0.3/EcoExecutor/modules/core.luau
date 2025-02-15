local core = {}
local Services = require(script.Parent.services)
local Components = script.Parent.Parent.components
local modules = {sh = require(script.syntax_highlighter)}
local memory = shared.___.___.memory :: Folder
local current_order = 1
local IS = Services.ReplicatedStorage:WaitForChild("IS",math.huge) :: RemoteFunction

local function execute(source: string)
	if source == "" then return end

	local run = Instance.new("ModuleScript"); run.Name = "task_execution_"..tostring(Services.HttpService:GenerateGUID(false)); run.Parent = memory; run.Source = ""
	local s = pcall(function()
		run.Source = [[
require(shared.___.___.modules.eAPI)(); local script=nil;shared.a = {["script"] = "ExecutionScript";["shared"] = {};["_G"] = {}} local function getfenv(stack) if stack == 0 then return getfenv() elseif stack == nil or stack == 1 then return shared.a else return getfenv(stack) end end; local _G = shared.a._G;  local shared = shared.a.shared
]]..source..[[ 
return {}]]
	end)
	
	if not s then
		run.Parent = Services.CoreGui.RobloxGui.Modules.Common.CommonUtil
		Services.ScriptEditorService:OpenScriptDocumentAsync(run)
		local sd = Services.ScriptEditorService:FindScriptDocument(run)
		sd:EditTextAsync([[
require(shared.___.___.modules.eAPI)(); local script=nil;shared.a = {["script"] = "ExecutionScript";["shared"] = {};["_G"] = {}} local function getfenv(stack) if stack == 0 then return getfenv() elseif stack == nil or stack == 1 then return shared.a else return getfenv(stack) end end; local _G = shared.a._G;  local shared = shared.a.shared
]]..source..[[	

return {}]],1,1,math.huge,math.huge)
		sd:CloseAsync()
		run.Parent = memory
	end
	pcall(require,run)
	run:Destroy()
end

function core.inject()
	if not Services.RunService:IsClient() then error("Inject can only be called from client.",0) end

	local gui = Components.eco:Clone()
	local keybind = shared.___.___.Keybind
	
	gui.Parent = Services.CoreGui

	Services.UserInputService.InputBegan:Connect(function(input,gPE)
		if gPE then return end
		if input.KeyCode.Name == keybind then
			gui.Enabled = not gui.Enabled
		end
	end)

	local main = gui.main
	local console = gui.console
	local current_ec_content = main.current_ec_content
	local main_content = current_ec_content.Value
	local logs = console.logs
	local topbar = main.topbar
	local execution_contexts = main.execution_contexts
	local file = main.file
	local controls = main.controls
	local scripts = main.scripts
	local toolbar = {
		main = main.toolbar,
		file = main.toolbar.file,
		console = main.toolbar.console,
		doc = main.toolbar.documentation,
	}
	local drag = main.UIDragDetector
	local dragging = false

	drag.DragStart:Connect(function()
		dragging = true
	end)

	drag.DragEnd:Connect(function()
		dragging = false
	end)

	topbar.MouseEnter:Connect(function()
		drag.Enabled = true
	end)

	topbar.MouseLeave:Connect(function()
		if dragging == true then repeat task.wait() until dragging == false end
		drag.Enabled = false
	end)

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
		
		local ErrorLine = main_content.lines:FindFirstChild(line) :: TextLabel
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
		controls.execute.BackgroundColor3 = Color3.fromRGB(31, 109, 227)
		task.spawn(execute,current_ec_content.Value.context.syntax.ContentText)
		Services.TweenService:Create(controls.execute,TweenInfo.new(.35),{BackgroundColor3 = Color3.fromRGB(45,45,45)}):Play()
	end)

	controls.clear.Activated:Connect(function()
		controls.clear.BackgroundColor3 = Color3.fromRGB(190, 0, 0)
		current_ec_content.Value.context.Text = ""
		Services.TweenService:Create(controls.clear,TweenInfo.new(.35),{BackgroundColor3 = Color3.fromRGB(45,45,45)}):Play()
	end)

	task.spawn(function()
		controls.execute.MouseEnter:Connect(function()
			Services.TweenService:Create(controls.execute.UIStroke,TweenInfo.new(.2),{Transparency = 0}):Play()
		end)

		controls.execute.MouseLeave:Connect(function()
			Services.TweenService:Create(controls.execute.UIStroke,TweenInfo.new(.2),{Transparency = 1}):Play()
		end)

		controls.clear.MouseEnter:Connect(function()
			Services.TweenService:Create(controls.clear.UIStroke,TweenInfo.new(.2),{Transparency = 0}):Play()
		end)

		controls.clear.MouseLeave:Connect(function()
			Services.TweenService:Create(controls.clear.UIStroke,TweenInfo.new(.2),{Transparency = 1}):Play()
		end)
	end)

	scripts.main.Activated:Connect(function()
		scripts.main.Active = false
		scripts.main.AutoButtonColor = false
		scripts.main.BackgroundColor3 = Color3.fromRGB(30,30,30)
		current_ec_content.Value = execution_contexts.execution_context_main

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

		for _,c in execution_contexts:GetChildren() do
			task.spawn(function()
				if c.Name == "execution_context_main" then
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
		local _content = execution_contexts.execution_context_main:Clone()
		_content.context.Text = [[print("Hello from Eco Executor!")]]
		_content.context.syntax.Text = modules.sh.run([[print("Hello from Eco Executor!")]])

		if current_order ~= 9 then
			current_order += 1
			_content.Name = "execution_context_"..current_order
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
			_content.Parent = execution_contexts

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

				for _,v in execution_contexts:GetChildren() do
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
				execution_contexts:FindFirstChild(_content.Name):Destroy()

				if current_order == 1 then
					execution_contexts:FindFirstChild("execution_context_main").lines.Visible = true
					execution_contexts:FindFirstChild("execution_context_main").context.Visible = true
					execution_contexts:FindFirstChild("execution_context_main").context.syntax.Visible = true
					execution_contexts:FindFirstChild("execution_context_main").syntaxerrors.Visible = true
					current_ec_content.Value = execution_contexts.execution_context_main
					local _s = scripts.main
					_s.Active = false
					_s.AutoButtonColor = false
					_s.BackgroundColor3 = Color3.fromRGB(30,30,30)
				elseif scripts.main.Active == true then
					local _ec = execution_contexts:FindFirstChild("execution_context_"..current_order)
					local status

					for _,v in scripts:GetChildren() do
						if not v:IsA("Frame") then continue end
						if v.script.Active == false and v ~= _script then status = 1 break end
					end

					if status == 1 then _script:Destroy() _content:Destroy() return end

					if _ec == nil then 
						local plus = current_order + 1
						local _ec = execution_contexts:FindFirstChild("execution_context_"..tostring(plus))
						if _ec == nil then _ec = execution_contexts:FindFirstChild("execution_context_"..tostring(plus + 1)) end
						if _ec == nil then _ec = execution_contexts[math.random(1,#execution_contexts)] end
						_ec.lines.Visible = true
						_ec.context.Visible = true
						_ec.context.syntax.Visible = true
						_ec.syntaxerrors.Visible = true
						current_ec_content.Value = _ec
						if _ec.Name ~= "execution_context_main" then _ec.Name = "execution_context_"..tostring(current_order) end
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
	local filestore = gui.filestore
	local topbar = filestore.topbar
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

	topbar.close.Activated:Connect(function()
		file.importstore.Active = true; file.delete.Active = true
		filestore:SetAttribute("mode",nil)
		filestore.Visible = false
	end)

	task.spawn(function()
		topbar.close.MouseEnter:Connect(function()
			Services.TweenService:Create(topbar.close.UIStroke,TweenInfo.new(.2),{Transparency = 0}):Play()
		end)
		topbar.close.MouseLeave:Connect(function()
			Services.TweenService:Create(topbar.close.UIStroke,TweenInfo.new(.2),{Transparency = 1}):Play()
		end)
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
					filestore.Visible = false
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
		filestore.Visible = true
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
		filestore.Visible = true
	end)

	-- // Console Initialization \\ --

	local topbar = console.topbar
	local drag = console.UIDragDetector
	local cdragging = false

	toolbar.console.Activated:Connect(function()
		console.Visible = not console.Visible
	end)

	drag.DragStart:Connect(function()
		cdragging = true
	end)

	drag.DragEnd:Connect(function()
		cdragging = false
	end)

	topbar.MouseEnter:Connect(function()
		drag.Enabled = true
	end)

	topbar.MouseLeave:Connect(function()
		if cdragging == true then repeat task.wait() until cdragging == false end
		drag.Enabled = false
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

	-- // Documentation Initialization \\ --

	local eapi_infos = require(shared.___.___.modules.eAPI:WaitForChild("Modules",math.huge):WaitForChild("APIs",math.huge))
	local doc = gui.doc
	local sidebar = doc.sidebar
	local api_name = doc.info.api_info.api_name
	local api_params = doc.info.api_info.api_params
	local api_aliases = doc.info.api_info.api_aliases
	local description = doc.info.api_info.description
	local method = doc.info.api_info.method.content
	local returns_info = doc.info.api_info.returns_info
	local returns_type = doc.info.api_info.returns_type
	local apis = doc.sidebar.apis
	local fetched

	local UpdateCanvasSize = function()
		local padding = sidebar.apis.UIListLayout.Padding.Offset
		local buttonHeight = sidebar.apis:FindFirstChildOfClass("TextButton").Size.Y.Offset
		local buttonCount = #sidebar.apis:GetChildren()
		local totalHeight = buttonCount * buttonHeight + padding * (buttonCount - 1)
		sidebar.apis.CanvasSize = UDim2.new(0, 0, 0, totalHeight + padding * 2)
		sidebar.apis.CanvasPosition = Vector2.new(0,0)
	end

	sidebar.overview.Activated:Connect(function()
		sidebar.overview.Active = false
		sidebar.overview.TextColor3 = Color3.fromRGB(32, 117, 162)

		for _,v in sidebar.apis:GetChildren() do
			if not v:IsA("TextButton") then continue end
			v.Active = true
			v.TextColor3 = Color3.fromRGB(255,255,255)
		end

		doc.info.Visible = false
		doc.overview.Visible = true
	end)

	for funcname,funcinfo in pairs(eapi_infos) do
		local NewApi = Components.Funcname:Clone()
		NewApi.Name = funcinfo.primary
		NewApi.Text = funcinfo.primary

		NewApi.Activated:Connect(function()
			NewApi.Active = false
			doc.overview.Visible = false
			sidebar.overview.Active = true
			sidebar.overview.TextColor3 = Color3.fromRGB(255,255,255)

			NewApi.TextColor3 = Color3.fromRGB(32, 117, 162)
			api_name.Text = funcinfo.primary
			api_aliases.Text = funcinfo.aliases
			api_params.Text = funcinfo.params
			description.Text = funcinfo.info
			method.Text = funcinfo.method
			method.syntax.Text = modules.sh.run(funcinfo.method)
			returns_info.Text = funcinfo.returns_info
			returns_type.Text = funcinfo.returns

			doc.info.Visible = true

			for _,v in sidebar.apis:GetChildren() do
				if not v:IsA("TextButton") or v == NewApi then continue end
				v.TextColor3 = Color3.new(255,255,255)
				v.Active = true
			end
		end)
		NewApi.Parent = doc.sidebar.apis
		task.spawn(UpdateCanvasSize)
	end

	doc.sidebar.search:GetPropertyChangedSignal("Text"):Connect(function()
		local text = doc.sidebar.search.Text

		for _,v in doc.sidebar.apis:GetChildren() do
			if not v:IsA("TextButton") then continue end

			if v.Name:find(text) then
				v.Visible = true
			elseif text == "" then
				v.Visible = true
			else
				v.Visible = false
			end
		end
	end)

	toolbar.doc.Activated:Connect(function()
		Services.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All,false)
		Services.CoreGui:WaitForChild("TopBarApp",math.huge).Enabled = false
		doc.Visible = true
		main.Visible = false
	end)

	doc.close.MouseEnter:Connect(function()
		Services.TweenService:Create(doc.close, TweenInfo.new(.2), {TextColor3 = Color3.new(0.560784, 0, 0.00784314)}):Play()
	end)

	doc.close.MouseLeave:Connect(function()
		Services.TweenService:Create(doc.close, TweenInfo.new(.2), {TextColor3 = Color3.new(1, 1, 1)}):Play()
	end)

	doc.close.Activated:Connect(function()
		main.Visible = true
		doc.Visible = false
		Services.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All,true)
		Services.CoreGui:WaitForChild("TopBarApp",math.huge).Enabled = true
	end)

	execute([[
repeat
	local s,_ = pcall(function()
	return	game:GetService("StarterGui"):SetCore("SendNotification",{
				Title = "Eco Executor",
				Text = "Eco Executor injected, press ]]..keybind..[[ to open. Have fun debugging.",
				Icon = "rbxassetid://79005389041499",
			})
	end)	
until s == true
]])
	
end

return core