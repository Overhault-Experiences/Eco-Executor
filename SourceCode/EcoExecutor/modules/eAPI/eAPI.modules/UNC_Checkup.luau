local UNC_Checkup = {}

function UNC_Checkup.checkenv(fenv) : (number, number, number)
	local failed = 0
	local success = 0
	local missing_aliases = 0

	local test = function(name, aliases)
		local func = name:split(".")[1]
		local member = name:split(".")[2]

		if fenv[func] ~= nil then
			if typeof(fenv[func]) == "function" then
				print("✅ "..func)
				success += 1
			else
				if fenv[func][member] then
					print("✅ "..func.."."..member)
					success += 1
				else
					if typeof(fenv[func]) == "table" then
						print("✅ "..name)
						success += 1
					else
						warn("⛔ "..name.." failed")
						failed += 1
					end
				end
			end
		else
			warn("⛔ "..name.." failed")
			failed += 1
		end

		if aliases ~= {} then
			for i,alias in aliases do
				local func = alias:split(".")[1]
				local member = alias:split(".")[2]

				if fenv[func] ~= nil then
					if typeof(fenv[func]) == "function" then
						print("✅ "..func)
					else
						if fenv[func][member] then
							print("✅ "..func.."."..member)
						else
							warn("⚠️ "..alias.." failed")
						end
					end
				else
					warn("⚠️ "..func.." failed")
					missing_aliases += 1
				end
			end
		end
	end

	do

		test("cache.invalidate", {})

		test("cache.iscached", {})

		test("cache.replace", {})

		test("cloneref", {})

		test("compareinstances", {})

		-- Closures

		test("checkcaller", {})

		test("clonefunction", {})

		test("getcallingscript", {})

		test("getscriptclosure", {"getscriptfunction"})

		test("hookfunction", {"replaceclosure"})

		test("iscclosure", {})

		test("islclosure", {})

		test("isexecutorclosure", {"checkclosure", "isourclosure"})

		test("loadstring", {})

		test("newcclosure", {})

		-- Console

		test("rconsoleclear", {"consoleclear"})

		test("rconsolecreate", {"consolecreate"})

		test("rconsoledestroy", {"consoledestroy"})

		test("rconsoleinput", {"consoleinput"})

		test("rconsoleprint", {"consoleprint"})

		test("rconsolesettitle", {"rconsolename", "consolesettitle"})

		-- Crypt

		test("crypt.base64encode", {"crypt.base64.encode", "crypt.base64_encode", "base64.encode", "base64_encode"})

		test("crypt.base64decode", {"crypt.base64.decode", "crypt.base64_decode", "base64.decode", "base64_decode"})

		test("crypt.encrypt", {})

		test("crypt.decrypt", {})

		test("crypt.generatebytes", {})

		test("crypt.generatekey", {})

		test("crypt.hash", {})

		--- Debug

		test("debug.getconstant", {})

		test("debug.getconstants", {})

		test("debug.getinfo", {})

		test("debug.getproto", {})

		test("debug.getprotos", {})

		test("debug.getstack", {})

		test("debug.getupvalue", {})

		test("debug.getupvalues", {})

		test("debug.setconstant", {})

		test("debug.setstack", {})

		test("debug.setupvalue", {})

		-- Filesystem

		test("readfile", {})

		test("listfiles", {})

		test("writefile", {})

		test("makefolder", {})

		test("appendfile", {})

		test("isfile", {})

		test("isfolder", {})

		test("delfolder", {})

		test("delfile", {})

		test("loadfile", {})

		test("dofile", {})

		-- Input

		test("isrbxactive", {"isgameactive"})

		test("mouse1click", {})

		test("mouse1press", {})

		test("mouse1release", {})

		test("mouse2click", {})

		test("mouse2press", {})

		test("mouse2release", {})

		test("mousemoveabs", {})

		test("mousemoverel", {})

		test("mousescroll", {})

		-- Instances

		test("fireclickdetector", {})

		test("getcallbackvalue", {})

		test("getconnections", {})

		test("getcustomasset", {})

		test("gethiddenproperty", {})

		test("sethiddenproperty", {})

		test("gethui", {})

		test("getinstances", {})

		test("getnilinstances", {})

		test("isscriptable", {})

		test("setscriptable", {})

		test("setrbxclipboard", {})

		-- Metatable

		test("getrawmetatable", {})

		test("hookmetamethod", {})

		test("getnamecallmethod", {})

		test("isreadonly", {})

		test("setrawmetatable", {})

		test("setreadonly", {})

		-- Miscellaneous

		test("identifyexecutor", {"getexecutorname"})

		test("lz4compress", {})

		test("lz4decompress", {})

		test("messagebox", {})

		test("queue_on_teleport", {"queueonteleport"})

		test("request", {"http.request", "http_request"})

		test("setclipboard", {"toclipboard"})

		test("setfpscap", {})

		-- Scripts

		test("getgc", {})

		test("getgenv", {})

		test("getloadedmodules", {})

		test("getrenv", {})

		test("getrunningscripts", {})

		test("getscriptbytecode", {"dumpstring"})

		test("getscripthash", {})

		test("getscripts", {})

		test("getsenv", {})

		test("getthreadidentity", {"getidentity", "getthreadcontext"})

		test("setthreadidentity", {"setidentity", "setthreadcontext"})

		-- Drawing

		test("Drawing", {})

		test("Drawing.new", {})

		test("Drawing.Fonts", {})

		test("isrenderobj", {})

		test("getrenderproperty", {})

		test("setrenderproperty", {})

		test("cleardrawcache", {})

		-- WebSocket

		test("WebSocket", {})

		test("WebSocket.connect", {})
		
		return success,failed,missing_aliases
	end
end

return UNC_Checkup