--[=[

API Info table example

funcname = {
		primary = "",
		aliases = "",
		returns = "",
		params = "",
		info = "",
		returns_info = "nil",
		method = [[
]]
},

]=]

local APIs = {
	getinstances = {
		primary = "getinstances",
		aliases = "getinstances, get_instances",
		returns = "table",
		params = "(void)",
		info = "Returns all instance in the game.",
		returns_info = "{Instance}",
		method = [[
local Instances = getinstances()
print(Instances) --print a table containing a instances

Instances[1]:Destroy()
]]
	},
	getscripts = {
		primary = "getscripts",
		aliases = "getscripts, get_scripts",
		returns = "table",
		params = "(void)",
		info = "Returns all script in the game.",
		returns_info = "{LuaSourceContainer}",
		method = [[
local Scripts = getscripts()
print(Scripts) --prints a table containing a scripts

Scripts[1].Enabled = false
]]
	},
	getmodules = {
		primary = "getmodules",
		aliases = "getmodules, get_modules",
		returns = "table",
		params = "(void)",
		info = "Returns all module script in the game.",
		returns_info = "{ModuleScript}",
		method = [[
local Modules = getmodules()
print(Modules) --prints a table containing a module scripts
require(Modules[1])
]]
	},
	getloadedmodules = {
		primary = "getloadedmodules",
		aliases = "getloadedmodules, get_loaded_modules",
		returns = "table",
		params = "(void)",
		info = "Returns loaded module scripts in the game.",
		returns_info = "{ModuleScript}",
		method = [[
local Modules = getloadedmodules()
print(Modules) --prints a table containing a loaded module scripts
Modules[1]:Destroy()
]]
	},
	getscripthash = {
		primary = "getscripthash",
		aliases = "getscripthash, get_scripthash",
		returns = "table",
		params = "(void)",
		info = "",
		returns_info = "",
		method = [[
]]
	},
	getrunningscripts = {
		primary = "getrunningscripts",
		aliases = "getrunningscripts, get_running_scripts",
		returns = "table",
		params = "(void)",
		info = "Returns a table containing running scripts",
		returns_info = "{BaseScript}",
		method = [[
local running_scripts = getrunningscripts()
for _,Script in running_scritpts do
Script.Disabled = true
end
]]
	},
	fireproximityprompt = {
		primary = "fireproximityprompt",
		aliases = "fireproximityprompt, fire_proximity_prompt",
		returns = "void",
		params = "(prompt: ProximityPrompt, amount: number?, skip: boolean?)",
		info = "Fires/Triggers the proximity prompt.",
		returns_info = "nil",
		method = [[
local prompt = workspace.Door.ProximityPrompt
fireproximityprompt(prompt,5,false)
]]
	},
	firetouchinterest = {
		primary = "firetouchinterest",
		aliases = "firetouchinterest, fire_touch_interest, fake_touch, faketouch",
		returns = "void",
		params = "(toucher: BasePart, touch_interest: TouchTransmitter, toggle: number)",
		info = "Fires the Instance.Touched event. Toggle : (0 > true, 1 > false)",
		returns_info = "nil",
		method = [[
local part = workspace.KillPart
faketouch(game.Players.Someguy123, part.TouchInterest, 0)
]]
	},
	setscriptsource = {
		primary = "setscriptsource",
		aliases = "setscriptsource, setsource",
		returns = "string",
		params = "(targetscript: BaseScript, NewSource: string)",
		info = "Change source of the target script",
		returns_info = "OriginalSource: string",
		method = [[
local detector = workspace.KickPart.Kick -- This script runs on client
setsource(detector, "--haha get source script changed")
]]
	},
	lockinstance = {
		primary = "lockinstance",
		aliases = "lockinstance",
		returns = "void",
		params = "(TargetInstance: Instance)",
		info = "Locks the instance's parent, usefull when protecting instance from getting moved (Instance.Parent = somewhere).",
		returns_info = "nil",
		method = [[
local target = workspace.TemporaryGuy --We know this instance will get moved back to replicated storage for re-use, let's protect him.
lockinstance(target)
]]
	},
	getlockedinstances = {
		primary = "getlockedinstances",
		aliases = "getlockedinstances",
		returns = "table",
		params = "(void)",
		info = "Returns a table containing locked instances",
		returns_info = "{LockedInstances}",
		method = [[
lockinstance(workspace.Bullet) --We locked it, lets check
local locked = getlockedinstances()
print(locked)
]]
	},
	restrictinstance = {
		primary = "restrictinstance",
		aliases = "restrictinstance, rinstance",
		returns = "void",
		params = "(TargetInstance: Instance)",
		info = "Restricts target instance from inserting a child or descendant",
		returns_info = "nil",
		method = [[
local target = workspace.NPCs --This is a folder containing a models of NPC, the folder still got the npc inserted in.
rinstance(target) --This will restrict the instance (Any child added to this folder, will got deleted)
]]
	},
	freeinstance = {
		primary = "freeinstance",
		aliases = "freeinstance",
		returns = "void",
		params = "(targetInstance: Instance)",
		info = "Un-restrict the restricted instance (aka free the instance).",
		returns_info = "nil",
		method = [[
local restricted = workspace.NPCs
freeinstance(restricted)
]]
	},
	getrestrictedinstances = {
		primary = "getrestrictedinstances",
		aliases = "getrestrictedinstances, getrestricts, getrestricted",
		returns = "table",
		params = "(void)",
		info = "Returns a table containing restricted instances",
		returns_info = "{RestrictedInstances}",
		method = [[
local RestrictedInstances = getrestricts()
for _,v in RestrictedInstances do --Lets clear up
freeinstance(v)
end
]]
	},
	getnilinstances = {
		primary = "getnilinstances",
		aliases = "getnilinstances, get_nil_instances, getnils",
		returns = "table",
		params = "(void)",
		info = "Returns a table containing nil parented instances.",
		returns_info = "{NilInstances}",
		method = [[
local nils = getnilinstances() -- Do something

for _,v in nils do
	if v.Name == "Anti" then -- Anti Cheat script found, lets parent it into the ReplicatedStorage
		parentinstance(v,game.ReplicatedStorage)
	else
		print(v.ClassName)
		print(v.Parent.Name)
	end
end
]]
	},
	info = {
		primary = "info",
		aliases = "info, couput",
		returns = "table",
		params = "(message)",
		info = "Prints a message but as test message to the output within the text colored as blue.",
		returns_info = "nil",
		method = [[
info("Loadstring on infinite yield")
]]
	},
	isscriptable = {
		primary = "isscriptable",
		aliases = "isscriptable, is_scriptable",
		returns = "boolean",
		params = "(object: Instance, property: string)",
		info = "Returns a boolean wether the property of a object is scriptable or not.",
		returns_info = "boolean",
		method = [[
local target = workspace.Characters[game.Players.LocalPlayer.Name]
local abletoscript = is_scriptable(target.Humanoid,"Health")

if abletoscript then
	target.Humanoid.Health = math.huge --I know this is not going to work but yea, for info
end
]]
	},
	isnetworkowner = {
		primary = "isnetworkowner",
		aliases = "isnetworkowner, is_network_owner",
		returns = "boolean",
		params = "(part: BasePart)",
		info = "Returns a boolean wether or not is the part networkship is set to the local player.",
		returns_info = "boolean",
		method = [[
print(is_network_owner(workspace.NPC.ChillGuy))
]]
	},
	gethui = {
		primary = "gethui",
		aliases = "gethui, get_hidden_ui, gethiddenui, get_hui",
		returns = "instance",
		params = "(void)",
		info = "Returns a coregui.",
		returns_info = "CoreGui",
		method = [[
local something = Instance.new("ScreenGui")
local something2 = Instance.new("Frame",something)
something.Parent = gethui()
]]
	},
	protect_gui = {
		primary = "protect_gui",
		aliases = "protect_gui",
		returns = "void",
		params = "(gui: Instance)",
		info = "Protects the target gui.",
		returns_info = "nil",
		method = [[
protect_gui(game.Players.LocalPlayer.PlayerGui.MyOwnGui) --MyOwnGui recently created, lets protect it
]]
	},
	run_on_actor = {
		primary = "run_on_actor",
		aliases = "run_on_actor",
		returns = "",
		params = "(actor: Actor, source: string, ...)",
		info = "",
		returns_info = "",
		method = [[
]]
	},
	getrawmetatable = {
		primary = "getrawmetatable",
		aliases = "getrawmetatable, get_raw_metatable",
		returns = "table",
		params = "(obj: any)",
		info = "Returns a metatable of the object",
		returns_info = "{any}",
		method = [[
]]
	},
	hookmetamethod = {
		primary = "hookmetamethod",
		aliases = "hookmetamethod",
		returns = "function",
		params = "(obj: any, method: string, hook: _function)",
		info = "Hooks the method of the function by setting a new function to the original and returns the old function.",
		returns_info = "OldFunction",
		method = [[
]]
	},
	isreadonly = {
		primary = "isreadonly",
		aliases = "isreadyonly, is_readonly, is_read_only",
		returns = "boolean",
		params = "(obj: {any}| userdata)",
		info = "",
		returns_info = "IsReadOnly?",
		method = [[
]]
	},
	setreadonly = {
		primary = "setreadonly",
		aliases = "setreadonly, set_readonly, set_read_only",
		returns = "",
		params = "(obj: {any}| userdata, value: boolean)",
		info = "",
		returns_info = "",
		method = [[
]]
	},
	makewriteable = {
		primary = "makewriteable",
		aliases = "makewriteable, make_writeable",
		returns = "",
		params = "(obj: {any}",
		info = "",
		returns_info = "",
		method = [[
]]
	},
	getproperties = {
		primary = "getproperties",
		aliases = "getproperties",
		returns = "table",
		params = "(obj: Instance)",
		info = "Returns a table containing the property of the instance and the value.",
		returns_info = "{string}",
		method = [[
local props = getproperties(workspace)
print(props) --Prints a table of workspace properties, including the functions
]]
	},
	hookfunction = {
		primary = "hookfunction",
		aliases = "hookfunction, hookfunc",
		returns = "function",
		params = "(oldfunction, newfunction)",
		info = "Hooks the old function and returns the old function.",
		returns_info = "OldFunction",
		method = [[
local old = hookfunction(wait, print)
wait(20) --prints out a 20 in the output
old(20) --a normal/old function and this will wait 20
]]
	},
	restorefunction = {
		primary = "restorefunction",
		aliases = "restorefunction, restore_func",
		returns = "void",
		params = "(function)",
		info = "",
		returns_info = "nil",
		method = [[
]]
	},
	isfunctionhooked = {
		primary = "isfunctionhooked",
		aliases = "isfunctionhooked, is_function_hooked",
		returns = "boolean",
		params = "(function)",
		info = "Returns wether or not the function is hooked.",
		returns_info = "Hooked?",
		method = [[
local IsHooked = isfunctionhooked(wait)

if not isHooked then
	print("The function isn't hooked!")
else
	print("Function hooked")
end
]]
	},
	emulate_call = {
		primary = "emulate_call",
		aliases = "emulate_call, secure_call, securecall",
		returns = "void",
		params = "(function, target: LuaSourceContainer, ...)",
		info = "",
		returns_info = "nil",
		method = [[
]]
	},
	newcclosure = {
		primary = "newcclosure",
		aliases = "newcclosure, new_c_closure",
		returns = "function",
		params = "(function)",
		info = "",
		returns_info = "function",
		method = [[
]]
	},
	newlclosure = {
		primary = "newlclosure",
		aliases = "newlclosure, new_l_closure",
		returns = "function",
		params = "(function)",
		info = "",
		returns_info = "function",
		method = [[
]]
	},
	iscclosure = {
		primary = "iscclosure",
		aliases = "iscclosure, is_c_closure",
		returns = "boolean",
		params = "(function)",
		info = "",
		returns_info = "IsCClosure?",
		method = [[
]]
	},
	islclosure = {
		primary = "islclosure",
		aliases = "islclosure, is_l_closure",
		returns = "boolean",
		params = "(function)",
		info = "",
		returns_info = "IsLClosure?",
		method = [[
]]
	},
	dumpstring = {
		primary = "dumpstring",
		aliases = "dumpstring",
		returns = "string",
		params = "(source: string | function | number)",
		info = "",
		returns_info = "DumpedString?",
		method = [[
]]
	},
	checkcaller = {
		primary = "checkcaller",
		aliases = "checkcaller, issynapsethread",
		returns = "boolean",
		params = "(void)",
		info = "",
		returns_info = "IsSynapseThread?",
		method = [[
]]
	},
	checkcallstak = {
		primary = "checkcallstack",
		aliases = "checkcallstack",
		returns = "boolean",
		params = "(void)",
		info = "",
		returns_info = "Boolean",
		method = [[
]]
	},
	getcallingscript = {
		primary = "getcallingscript",
		aliases = "getcallingscript, get_calling_script",
		returns = "",
		params = "(void)",
		info = "",
		returns_info = "",
		method = [[
]]
	},
	clonefunction = {
		primary = "clonefunction",
		aliases = "clonefunction, clonefunc, cloneclosure",
		returns = "function",
		params = "(function)",
		info = "",
		returns_info = "function",
		method = [[
]]
	},
	getidentity = {
		primary = "getidentity",
		aliases = "getidentity",
		returns = "boolean",
		params = "(void)",
		info = "Returns the current identity of the executor.",
		returns_info = "Boolean?",
		method = [[
local identity = getidentity()
print(identity)
]]
	},
	is_executor_closure = {
		primary = "is_executor_closure",
		aliases = "is_executor_closure, issynapsefunction",
		returns = "boolean",
		params = "(function)",
		info = "",
		returns_info = "Boolean",
		method = [[
]]
	},
	getrenv = {
		primary = "getrenv",
		aliases = "getrenv",
		returns = "table",
		params = "(void)",
		info = "",
		returns_info = "{any}",
		method = [[
]]
	},
	getgenv = {
		primary = "getgenv",
		aliases = "getgenv",
		returns = "table",
		params = "(void)",
		info = "Returns the environment that applies to the script ran by executor.",
		returns_info = "{EnvironmentOfTheScriptRanByExecutor}",
		method = [[
local genv = getgenv()
genv.Key = "a2943baa-c4d5-4dca-bea5-0d774341758a" -- Other script ran in the executor have a access to this.
]]
	},
	decompile = {
		primary = "decompile",
		aliases = "decompile, bytecode_to_lua",
		returns = "string",
		params = "(ScriptToDecompile: LuaSourceContainer)",
		info = "Returns a string of the script code (Pretty much same as viewscript() except this returns the script code instead of viewing the script code)",
		returns_info = "SourceScript",
		method = [[
local target = game.Players.LocalPlayer.PlayerGui.Menu.KickButton.KickScript -- This script runs on client
local d = decompile(target)
print(d) -- Do whatever you want, for now we just gonna print the script code
]]
	},
	dump_function = {
		primary = "dump_function",
		aliases = "dump_function, dumpfunction",
		returns = "",
		params = "(function)",
		info = "",
		returns_info = "",
		method = [[
]]
	},
	protect_function = {
		primary = "protect_function",
		aliases = "protect_function, protectfunction",
		returns = "function",
		params = "(function)",
		info = "",
		returns_info = "ProtectedFunction",
		method = [[
]]
	},
	queue_on_teleport = {
		primary = "queue_on_teleport",
		aliases = "queue_on_teleport, queueonteleport",
		returns = "void",
		params = "(source: string)",
		info = "",
		returns_info = "nil",
		method = [[
]]
	},
	clear_teleport_queue = {
		primary = "clear_teleport_queue",
		aliases = "clear_teleport_queue, cleateleportqueue",
		returns = "",
		params = "(void)",
		info = "",
		returns_info = "",
		method = [[
]]
	},
	executeclipboard = {
		primary = "executeclipboard",
		aliases = "executeclipboard, execute_clipboard",
		returns = "",
		params = "(...)",
		info = "",
		returns_info = "nil?",
		method = [[
]]
	},
	setclipboard = {
		primary = "setclipboard",
		aliases = "setclipboard, set_clipboard",
		returns = "void",
		params = "(content: string)",
		info = "Sets the clipboard to the content text. Note: This function will not override the real clipboard, only replicate by tracking the control + v keyboard using UserInputService.",
		returns_info = "nil",
		method = [[
local content = "Hello, my clipboard"
setclipboard(content)

Hello, my clipboard --Pasted text
]]
	},
	getclipboard = {
		primary = "getclipboard",
		aliases = "getclipboard, get_clipboard",
		returns = "any",
		params = "(void)",
		info = "Returns the content that was setted to the replicated clipboard.",
		returns_info = "Any?",
		method = [[
local content = "Hello, my clipboard"
setclipboard(content)

local fetchedcontent = getclipboard()
print(fetechedcontent) --Will print the content string (Hello, my clipboard)
]]
	},
	iskeydown = {
		primary = "iskeydown",
		aliases = "iskeydown, is_key_down",
		returns = "boolean",
		params = "(key_code: string)",
		info = "Returns wheter or not the given keycode is pressed down.",
		returns_info = "Boolean",
		method = [[
local IsPressedDown = iskeydown("Backspace")

if not IsPresseddown then
	print("Backspace isn't pressing")
else
	warn("Pressing backspace!")
end
]]
	},
	hook = {
		primary = "hook",
		aliases = "hook",
		returns = "function",
		params = "(oldfunction, newfunction)",
		info = "OTH Library Function",
		returns_info = "OldFunction",
		method = [[
]]
	},
	unhook = {
		primary = "unhook",
		aliases = "unhook",
		returns = "void",
		params = "(function)",
		info = "OTH Library Function",
		returns_info = "nil",
		method = [[
]]
	},
	getexecutorinfo = {
		primary = "getexecutorinfo",
		aliases = "getexecutorinfo",
		returns = "table",
		params = "(void)",
		info = "Returns the info of the executor.",
		returns_info = "{Name, Version, API}",
		method = [[
]]
	},
	getapi_info = {
		primary = "getapi_info",
		aliases = "getapi_info",
		returns = "table",
		params = "(void)",
		info = "Returns the info of the used API by the executor.",
		returns_info = "{Name, Version}",
		method = [[
]]
	},
	HttpGet = {
		primary = "HttpGet",
		aliases = "HttpGet",
		returns = "any",
		params = "(url: string)",
		info = "Get async of the http url and returns the returned content (usefull in loadstring())",
		returns_info = "content?",
		method = [[
]]
	},
	HttpPost = {
		primary = "HttpPost",
		aliases = "HttpPost",
		returns = "any",
		params = "(url: string, body: string)",
		info = "Post async of the http url and returns the returned content",
		returns_info = "content?",
		method = [[
]]
	},
	getgc = {
		primary = "getgc",
		aliases = "getgc",
		returns = "table",
		params = "(void)",
		info = "",
		returns_info = "{content?}",
		method = [[
]]
	},
	insert_luau_code = {
		primary = "insert_luau_code",
		aliases = "insert_luau_code, insert_luau_module",
		returns = "function",
		params = "(function, source: string)",
		info = "",
		returns_info = "function?",
		method = [[
]]
	},
	getinfo = {
		primary = "getinfo",
		aliases = "getinfo",
		returns = "table",
		params = "(f: function | number)",
		info = "Returns the info of the given args.",
		returns_info = "{source, short_src, func, what, currentline, name, nups, numparams, is_vararg}",
		method = [[
]]
	},
	isvalidlevel = {
		primary = "isvalidlevel",
		aliases = "isvalidlevel",
		returns = "boolean",
		params = "(level: number)",
		info = "Returns wether or not the given level value is valid.",
		returns_info = "Boolean",
		method = [[
]]
	},
	compareinstance = {
		primary = "compareinstance",
		aliases = "compareinstance, cinstances",
		returns = "boolean",
		params = "(a: Instance, b: Instance)",
		info = "Returns false or true which if the instance `a` is same as instance `b`.",
		returns_info = "Boolean",
		method = [[
local Same = compareinstance(game, workspace)

if not Same then
	warn("The instance wasn't same!")
else
	print("Same instance!")
end
]]
	},
	cloneref = {
		primary = "cloneref",
		aliases = "cloneref, clone_ref",
		returns = "instance",
		params = "(obj: Instance)",
		info = "Clone the given obj",
		returns_info = "proxy?",
		method = [[
]]
	},
	isrbxactive = {
		primary = "isrbxactive",
		aliases = "isrbxactive, isgameactive",
		returns = "boolean",
		params = "(void)",
		info = "Returns a boolean wether or not the roblox window is focused.",
		returns_info = "Boolean",
		method = [[
local focused = isrbxactive()

while task.wait() do
	if focused then
		print("Focused!")
	else
		print("Un-Focused!")
	end
end
]]
	},
	getscreenres = {
		primary = "getscreenres",
		aliases = "getscreenres, get_screen_res",
		returns = "boolean",
		params = "()",
		info = "Returns a table containing a screen resolution info.",
		returns_info = "{ScreenResolutionInfo: string, ScreenResolution: {X,Y} : {number}}",
		method = [[
local Resolution = getscreenres
print(Resolution[1]) --Will prints out "NumberA X NumberB"

print(Resolution[2].X)
print(Resolution[2].Y) --Both of them is number
]]
	},
	set_fps_cap = {
		primary = "setfpscap",
		aliases = "setfpscap, set_fps_cap",
		returns = "void",
		params = "(new_cap: number)",
		info = "Set fps cap to the given value, setting to `0` will just uncap the fps.",
		returns_info = "nil",
		method = [[
setfpscap(20)
task.wait(10)
setfpscap(0) --Uncap
]]
	},
	getfpscap = {
		primary = "getfpscap",
		aliases = "getfpscap, get_fps_cap",
		returns = "number",
		params = "(void)",
		info = "Returns setted fps cap, not an actual fps cap.",
		returns_info = "fpsCap",
		method = [[
local cap = getfpscap()
print(cap) --Will print 0 because we didn't setted yet the fps cap.
setfpscap(23)
print(cap) --Will print 23 because we setted the fps cap 23.
]]
	},
	saveinstance = {
		primary = "saveinstance",
		aliases = "saveinstance",
		returns = "void",
		params = "(InstanceToSave: Instance | void)",
		info = "Saves the instance and can be loaded back by using loadinstance passing their respective instance name to the instance that will be loaded.",
		returns_info = "nil?",
		method = [[
local targetInstance = workspace.NPC --We wanted to save this
saveinstance(targetInstance) --We saved it, we can use it later for loading this instance
]]
	},
	loadinstance = {
		primary = "loadinstance",
		aliases = "loadinstance",
		returns = "instance",
		params = "(InstanceName: string)",
		info = "Returns the unparented (nil-parented, excluded from the getnilinstances()) saved instance by the given instance name.",
		returns_info = "SavedInstance",
		method = [[
local targetInstance = workspace.NPC --We wanted to save this (yeah, we do the same but this one we add loadinstance method)
saveinstance(targetInstance) --We saved it

local loaded = loadinstance("NPC") --Since we saved the targetInstance and the name of the instance is NPC, we need to use their respective name to load the saved instance that we wanted for
--loaded.Parent = workspace -> Error
parentinstance(loaded, workspace) -- -> No error, see the documentation of parentinstance()
]]
	},
	getsavedinstances = {
		primary = "getsavedinstances",
		aliases = "getsavedinstances",
		returns = "table",
		params = "(void)",
		info = "Returns a table containing a name of saved instances, not a content of the instance like properties, children (usefull incase forgot the instances name that you saved)",
		returns_info = "{SavedInstances: string}",
		method = [[
local saved = getsavedinstances() --A table
local folder = Instance.new("Folder")
folder.Name = "Saved"
folder.Parent = game:GetService("ReplicatedStorage")

for _,SavedInstanceName in pairs(saved) do
	local LoadedInstance = loadinstance(SavedInstanceName) --The SavedInstanceName variable is a typeof(string) therefore, we can use it on loadinstance()
	parentinstance(LoadedInstance, folder) --Since the loaded instance from loadinstance() is unparented (nil) we parent them in
end
]]
	},
	reset_savedinstances = {
		primary = "reset_savedinstances",
		aliases = "reset_savedinstances, resetsaves",
		returns = "void",
		params = "(void)",
		info = "Resets the saved instances (when using the getsavedinstances(), it will return nil)",
		returns_info = "nil",
		method = [[
]]
	},
	parentinstance = {
		primary = "parentinstance",
		aliases = "parentinstance",
		returns = "instance",
		params = "(InstanceToParent: Instance, Parent: Instance)",
		info = "Parents the instance of the first param to a instance of second param (there is a bug where you cannot parent the instance, as it just result invalid argument thing)",
		returns_info = "ParentedInstance",
		method = [[
local nils = getnilinstances()
local NilFolder = Instance.new("Folder")
NilFolder.Name = "Nils"
NilFolder.Parent = game:GetService("ReplicatedStorage") --We can parent this normally somehow, except for the instance that was returned by the API (xAPI modded [eAPI])

for _,v in pairs(nils) do
	parentinstance(v, NilFolder) --The v is a instance that was nil parented and returned as a table but from the API, we can't parent them normally
end
]]
	},
	identifyexecutor = {
		primary = "identifyexecutor",
		aliases = "identifyexecutor, getexecutorname",
		returns = "string",
		params = "(void)",
		info = "Returns the executor name, the easier version to get executor name instead of getexecutorinfo() which returns a table. Made for compatibility with other scripts (loadstring thing)",
		returns_info = "ExecutorName",
		method = [[
local executorname = identifyexecutor()
print(executorname) --Will print Studio Executor
]]
	},
	rconsoleprint = {
		primary = "rconsoleprint",
		aliases = "rconsoleprint",
		returns = "void",
		params = "(ColorCode: string | Message: string)",
		info = "Prints message into the console, rconsoleprint also supports colors (to see the logs, open the console located at the executor next to APIs button)",
		returns_info = "nil",
		method = [[
rconsoleprint("@@RED@@")
rconsoleprint("this is a red text or a message")

--[=[
LIST OF COLOR CODE
{
	["@@BLACK@@"],
	["@@BLUE@@"],
	["@@GREEN@@"],
	["@@CYAN@@"],
	["@@RED@@"],
	["@@MAGENTA@@"],
	["@@BROWN@@"],
	["@@LIGHT_GRAY@@"],
	["@@DARK_GRAY@@"],
	["@@LIGHT_BLUE@@"],
	["@@LIGHT_GREEN@@"],
	["@@LIGHT_CYAN@@"],
	["@@LIGHT_RED@@"],
	["@@LIGHT_MAGENTA@@"],
	["@@YELLOW@@"],
	["@@WHITE@@"],
}
]=]
]]
	},
	rconsoleinfo = {
		primary = "rconsoleinfo",
		aliases = "rconsoleinfo",
		returns = "void",
		params = "(Message: string)",
		info = "Prints message into the console, with a info text before it.",
		returns_info = "nil",
		method = [[
rconsoleinfo("ExampleName API has loaded!")
]]
	},
	rconsolewarn = {
		primary = "rconsolewarn",
		aliases = "rconsolewarn",
		returns = "void",
		params = "(Message: string)",
		info = "Same as rconsoleinfo(), except the text before it colored as yellow.",
		returns_info = "nil",
		method = [[
rconsolewarn("The ExampleName API is outdated, latest version is 1.3.5")
]]
	},
	rconsoleerr = {
		primary = "rconsoleerr",
		aliases = "rconsolerr",
		returns = "void",
		params = "(Message: string)",
		info = "Same as rconsoleinfo(), except the text before it colored as red.",
		returns_info = "nil",
		method = [[
rconsoleerr("There was an error while loading ExampleName API, returning...")
]]
	},
	rconsoleclear = {
		primary = "rconsoleclear",
		aliases = "rconsoleclear",
		returns = "void",
		params = "(void)",
		info = "Clears the console.",
		returns_info = "nil",
		method = [[
--Woah, there is too many logs, although these logs are no longer useful, might just clear it up now.
rconsoleclear()
]]
	},
	rconsolename = {
		primary = "rconsolename",
		aliases = "rconsolename",
		returns = "void",
		params = "(NewTitle: string)",
		info = "Sets the title to a given new title.",
		returns_info = "nil",
		method = [[
rconsolename("ExampleName Console")
]]
	},
	rconsoleinput = {
		primary = "rconsoleinput",
		aliases = "rconsoleinput",
		returns = "string",
		params = "(void)",
		info = "Yields until the input message log into the console (from input, not rconsole functions). Returns the input message.",
		returns_info = "Message",
		method = [[
local exampletext = rconsoleinput() -- This function will yield until the user input message.
rconsoleinfo(exampletext) -- This will just prints a "Hey! This is not default roblox console" as already by the user.
]]
	},
	printconsole = {
		primary = "printconsole",
		aliases = "printconsole",
		returns = "void",
		params = "(Message: string, red: number, green: number, blue: number)",
		info = "Same as rconsoleprint() but this one support custom color and have 2 params which the first one is message that will be printed in the console and the 2,3,4 is R,G,B.",
		returns_info = "nil",
		method = [[
printconsole("Hello console, im custom colored text.",122, 200, 153)
]]
	},
	spyremote = {
		primary = "spyremote",
		aliases = "spyremote, spyr",
		returns = "void",
		params = "(remote: RemoteEvent, callback: function)",
		info = "Spy the remote and runs the passed second argument, callback (typeof(function)). Doesn't yield when the remote is fired nor when execute in the script. This also doesn't block the :FireServer method on the remote event on the script that wants to fire.",
		returns_info = "nil",
		method = [[
spyr(path.to.Anti, function(...) --Calling this function does not yield the script nor block the :FireServer method, the other script still can fire it normally and the server still receives it.
	local args = ... -- This "..." is a tupple of what the remote event send through :FireServer method.
	warn("The remote event is fired with the argument: "..args)
end) -- What happens here is when the remote is fired, this callback (function) will runs, look at the function, what it does is just to warns the argument that was being passed to the server.
]]
	},
	stopspyremote = {
		primary = "stopspyremote",
		aliases = "stopspyremote,stopspyr",
		returns = "void",
		params = "(remote: RemoteEvent)",
		info = "Stop spying the remote and prevents the callback from running when the remote event is fired.",
		returns_info = "nil",
		method = [[
local remote = path.to.Anti --This remote has been spied, lets stop the spying this remote to prevent further callback execution
stopspyr(remote) --Now we have stopped spying on this remote. Even if the remote hasn't been spied at all (it will not throws any errors (warn))
]]
	},
	isremotespied = {
		primary = "isremotespied",
		aliases = "isremotespied, isrspied",
		returns = "boolean",
		params = "(remote: RemoteEvent)",
		info = "Returns a boolean indicating the passed remote event is being spied or not.",
		returns_info = "Spied?",
		method = [[
local KickRemote = path.to.Kick --I don't remember using spyr on this remote
local Spied = isrspied(KickRemote)

if Spied == true then
	rconsoleprint("@@RED@@")
	rconsoleprint("This remote is being spied on!")
else
	rconsoleprint("@@GREEN@@")
	rconsoleprint("This remote isn't being spied.")
end
]]
	},
	spiedremotes = {
		primary = "spiedremotes",
		aliases = "spiedremotes, getspied",
		returns = "table",
		params = "(void)",
		info = "Returns a table containg spied remotes",
		returns_info = "{SpiedRemotes}",
		method = [[
local Spied = getspied() -- I want to clear up, lets do this

for _,remote in pairs(Spied) do -- Clearing
	stopspyremote(remote)
end
]]
	},
	path = {
		primary = "path",
		aliases = "path",
		returns = "table",
		params = "nil",
		info = "A path's library",
		returns_info = "{Path'sLibrary}",
		method = [[
]]
	},
	pathto = {
		primary = "path.to",
		aliases = "path.to",
		returns = "instance",
		params = "nil",
		info = "(From path's library) This is not a function, it will do automatically. This is a auto-function that returns a instance with the given index (as a name)",
		returns_info = "IndexedInstance",
		method = [[
local instance = game.ReplicatedStorage.Communications.Binables.Events.GetProductInfo
--As you can see, it is way too long to reach the "GetProductInfo" bindable event
local int = path.to.GetProductInfo
--This is shorter and faster

print(int.ClassName) --OR
local productinfo = int:Fire(AssetIdHere)
print(productinfo)
-- You can also do like this:
print(path.to.GetProductInfo.Parent.Name) -- Will print Events
]]
	},
	pathfind = {
		primary = "path.find",
		aliases = "path.find",
		returns = "instance",
		params = "(name: string, classname: string)",
		info = "Returns a instance matching with the given name and classname, this one isn't automated function, but more specific incase there is multiple same name but different classname.",
		returns_info = "Instance",
		method = [[
local int = path.to.MyRemote -- Let say this won't return what we want (we want RemoteFunction in this case) because there is two same remote name but they are different, one is RemoteEvent and one is RemoteFunction.
local instance = path.find("MyRemote","RemoteFunction") -- Use this to get the specific instance

int:InvokeServer(9999999999,"GiveCoins") -- This won't work because it returns a RemoteEvent (will throw an error unless it manages to return a RemoteFunction which is unlikely)
instance:InvokeServer(9999999999,"GiveCoins")
]]
	},
	loadmodule = {
		primary = "loadmodule",
		aliases = "loadmodule",
		returns = "any",
		params = "(_m: ModuleScript)",
		info = "Refreshes the module and loads it. Return the module returns",
		returns_info = "ModuleReturns",
		method = [=[
local myModule = Instance.new("ModuleScript",)
]=]
	},
	getscriptbytecode = {
		primary = "getscriptbytecode",
		aliases = "getscriptbytecode",
		returns = "string",
		params = "LuaSourceContainer: Script | LocalScript | ModuleScript",
		info = "Returns a bytecode of the given LuaSourceContainer.",
		returns_info = "ByteCode",
		method = [[
local bytecode = getscriptbytecode(path.to.Modules.HealthTracker) -- The bytecode of the script

warn(bytecode) -- Do what you want, in this case we just gonna warn a bytecode
]]
	},
	loadbytecode = {
		primary = "loadbytecode",
		aliases = "loadbytecode",
		returns = "function",
		params = "ByteCode: string",
		info = "Returns a function of the given ByteCode (could be useful if you don't want to cache a unrequired ModuleScript)",
		returns_info = "LoadedByteCode",
		method = [[
local bytecode = getscriptbytecode(path.to.pinbreaker) -- pinbreaker is a ModuleScript

local loaded = loadbytecode(bytecode)
local table = loaded()

for member,content in table do
	print(member, content)
end
]]
	},
}

return APIs