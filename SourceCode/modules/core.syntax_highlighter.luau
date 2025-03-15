local highlighter = {}
local eAPI = require("../eAPI")
local keywords = {
	lua = {
		"and", "break", "or", "else", "elseif", "if", "then", "until", "repeat", "while", "do", "for", "in", "end",
		"local", "return", "function", "export", "continue", "type", "typeof", "not",
	},
	rbx = {
		"game","Game", "Workspace", "workspace", "script", "math", "string", "table", "task", "wait", "select", "next", "Enum",
		"error", "warn", "tick", "assert", "shared", "loadstring", "tonumber", "tostring","SharedTable","plugin","DateTime",
		"unpack", "print", "Instance", "CFrame", "Vector3", "Vector2", "Color3", "UDim", "UDim2", "Ray", "BrickColor",
		"OverlapParams", "RaycastParams", "Axes", "Random", "Region3", "Rect", "TweenInfo","printidentity","Content","ColorSequence",
		"collectgarbage", "utf8", "ypcall","pcall", "xpcall", "_G", "setmetatable", "getmetatable", "os", "pairs", "ipairs","ColorSequenceKeypoint",
		"Font", "getfenv", "setfenv", "rawget", "rawlen", "rawset", "rawequal", "RotationCurveKey", "FloatCurveKey", "File", "debug", "coroutine",
		"SecurityCapabilities", "PhysicalProperties", "bit32", "buffer", "CatalogSearchParams", "delay", "Delay", "DockWidgetPluginGuiInfo",
		"spawn", "Spawn", "ElapsedTime", "elapsedTime", "Faces", "NumberSequence", "NumberSequenceKeypoint", "NumberRange", "newproxy",
		"PathWaypoint", "Path2DControlPoint", "Region3int16", "Secret", "settings", "Stats", "stats", "UserSettings", "version", "Version",
		"vector", "Vector2int16", "Vector3int16", "Wait", "require",
	},
	operators = {
		"#", "+", "-", "*", "%", "/", "^", "=", "~", "=", "<", ">", ",", ".", "(", ")", "{", "}", "[", "]", ";", ":"
	},
	extra = {
		["debug"] = {
			"info", "traceback", "profilebeing", "profileend", "dumpcodesize", "getmemorycategory", "setmemorycategory", "resetmemorycategory", "dumpheap", "loadmodule"
		},
		["os"] = {
			"time", "date", "clock", "difftime",
		},
		["DateTime"] = {
			"fromIsoDate", "now", "fromLocalTime", "fromUniversalTime", "fromUnixTimestamp", "fromUnixTimestampMillis",
		},
		["string"] = {
			"byte", "char", "dump", "find", "format", "len", "lower", "match", "rep", "reverse", "sub", "upper", "gmatch", "gsub",
		},
		["math"] = {
			"abs", "acos", "asin", "atan", "atan2", "ceil", "clamp", "cos", "cosh", "deg", "exp", "floor", "fmod", "frexp", "ldexp", "log", "log10", "max", "min", "modf", "noise", "pow", "rad", "random", "randomseed", "sign", "sin", "sinh", "sqrt", "tan", "tanh",
			"huge", "pi"
		},
		["coroutine"] = {
			"create", "resume", "running", "status", "wrap", "yield",
		},
		["table"] = {
			"concat", "insert", "remove", "clear", "sort", "unpack", "freeze", "clone", "find", "create", "pack", "maxn", "move", "isfrozen", "getn", "foreach", "foreachi"
		},
		["task"] = {
			"spawn", "wait", "cancel", "delay", "synchronize", "defer", "desynchronize",
		},
		["OverlapParams"] = {
			"new",
		},
		["Instance"] = {
			"new", "fromExisting",
		},
		["Color3"] = {
			"new", "fromRGB", "fromHex", "fromHSV", 
		},
		["Axes"] = {
			"new",
		},
		["PhysicalProperties"] = {
			"new",
		},
		["PathWaypoint"] = {
			"new",
		},
		["SecurityCapabilities"] = {
			"new", "fromCurrent",
		},
		["Vector3"] = {
			"new", "fromNormalId", "FromNormalId", "fromAxis", "FromAxis", "one", "zero", "xAxis", "yAxis", "zAxis", "max", "min"
		},
		["Vector2"] = {
			"new", "max", "min", "one", "zero", "yAxis", "xAxis"
		},
		["vector"] = {
			"create", "magnitude", "normalize", "cross", "dot", "angle", "floor", "ceil", "abs", "sign", "clamp", "max", "min", "zero", "one"
		},
		["Vector3int16"] = {
			"new",
		},
		["Vector2int16"] = {
			"new",
		},
		["UDim"] = {
			"new",
		},
		["UDim2"] = {
			"new", "fromOffset", "fromScale" 
		},
		["BrickColor"] = {
			"new", "random", "Random", "Red", "Blue", "Gray", "Black", "Green", "White", "Yellow", "pallete", "DarkGray"
		},
		["buffer"] = {
			"create", "fromstring", "tostring", "len", "fill" , "copy", "readstring", "readi8", "readu8", "readi16", "readu16", "readi32", "readu32", "readf32", "readf64", "writestring", "writei8", "writeu8", "writei16", "writeu16", "writei32", "writeu32", "writef32", "writef64"
		},
		["bit32"] = {
			"band", "bor", "bxor", "bnot", "btest", "lshift", "rshift", "arshift", "rol", "ror", "extract", "replace", "countlz", "countrz", "lrotate", "rrotate", "byteswap"
		},
		["CFrame"] = {
			"new", "Angles", "lookat", "identity", "lookAlong","fromMatrix", "fromAxisAngle", "fromEulerAngles", "fromOrientation", "fromEulerAnglesXYZ", "fromEulerAnglesYXZ", "fromRotationBetweenVectors"
		},
		["Content"] = {
			"fromAssetId", "none", "fromUri", "fromObject",
		},
		["ColorSequence"] = {
			"new",
		},
		["ColorSequenceKeypoint"] = {
			"new",
		},
		["CatalogSearchParams"] = {
			"new",
		},
		["DockWidgetPluginGuiInfo"] = {
			"new"
		},
		["FloatCurveKey"] = {
			"new",
		},
		["Faces"] = {
			"new"
		},
		["NumberSequence"] = {
			"new",
		},
		["NumberSequenceKeypoint"] = {
			"new"
		},
		["NumberRange"] = {
			"new"
		},
		["Path2DControlPoint"] = {
			"new"
		},
		["Ray"] = {
			"new",
		},
		["RaycastParams"] = {
			"new"
		},
		["Random"] = {
			"new",
		},
		["Region3"] = {
			"new",
		},
		["RotationCurveKey"] = {
			"new"
		},
		["Rect"] = {
			"new",
		},
		["Region3int16"] = {
			"new",
		},
		["SharedTable"] = {
			"new", "clone", "clear", "update", "size", "isFrozen", "increment", "cloneAndFreeze",
		},
		["TweenInfo"] = {
			"new",
		},
		["utf8"] = {
			"char", "len", "codes", "offset", "codepoint", "graphemes", "charpattern", "nfcnormalize", "nfdnormalize",
		},
	},
	eAPI_functions = eAPI.environment
}
local Studio = require("../services").Studio

local colors = {
	numbers = Studio["Number Color"],
	boolean = Studio["Bool Color"],
	operator = Studio["Operator Color"],
	lua = Studio["Built-in Function Color"],
	rbx = Studio["Luau Keyword Color"],
	str = Studio["String Color"],
	comment = Studio["Comment Color"],
	null = Studio["\"nil\" Color"],
	call = Studio["Function Name Color"],
	local_color = Studio["\"local\" Color"],
	function_color = Studio["\"function\" Color"],
	self_color = Studio["\"self\" Color"],
	local_property = Studio["Property Color"],
	eAPI_function = Color3.fromRGB(152, 79, 255),
}

local function createKeywordSet(keywords)
	local keywordSet = {}
	for _, keyword in ipairs(keywords) do
		keywordSet[keyword] = true
	end
	return keywordSet
end

local luaSet = createKeywordSet(keywords.lua)
local rbxSet = createKeywordSet(keywords.rbx)
local operatorsSet = createKeywordSet(keywords.operators)

local function getHighlight(tokens, index)
	local token = tokens[index]
	
	if colors[token .. "_color"] then
		return colors[token .. "_color"]
	end
	
	if tonumber(token) then
		return colors.numbers
	elseif token == "nil" then
		return colors.null
	elseif token:sub(1, 2) == "--" then
		return colors.comment
	elseif operatorsSet[token] then
		return colors.operator
	elseif luaSet[token] then
		return colors.rbx
	elseif rbxSet[token] then
		return colors.lua
	elseif token:sub(1, 1) == "\"" or token:sub(1, 1) == "\'" then
		return colors.str
	elseif token == "true" or token == "false" then
		return colors.boolean
	end
	
	if tokens[index + 1] == "(" then
		if tokens[index - 1] == ":" then
			return colors.call
		end
		local first = tokens[index - 2]; local second = tokens[index]
		if table.find(keywords.rbx,first) then
			if keywords.extra[first] and table.find(keywords.extra[first],second)  then
				return colors.lua
			elseif keywords.eAPI_functions[token] then
				return colors.eAPI_function
			else
				return colors.call
			end
		end
		
		if keywords.eAPI_functions[token] then
			return colors.eAPI_function
		end

		return colors.call
	end
	
	if tokens[index - 1] == "." then
		if tokens[index - 2] == "Enum" then
			local enum = pcall(function()
				return Enum[tokens[index]]
			end)
			
			if enum then
				return colors.lua
			end
			
			return colors.local_property
		else
			if table.find(keywords.rbx,tokens[index - 2]) then
				if keywords.extra[tokens[index - 2]] and table.find(keywords.extra[tokens[index - 2]],tokens[index]) then
					return colors.lua
				else
					return colors.local_property
				end
			else
				if keywords.eAPI_functions[token] then
					return colors.eAPI_function
				end
			end
		end

		return colors.local_property
	end
	
	if keywords.eAPI_functions[token] then
		return colors.eAPI_function
	end
end

function highlighter.run(source)
	if source == "" then return "" end
	local tokens = {}
	local currentToken = ""

	local inString = false
	local inComment = false
	local commentPersist = false

	for i = 1, #source do
		local character = source:sub(i, i)
		
		if inComment then
			if character == "\n" and not commentPersist then
				table.insert(tokens, currentToken)
				table.insert(tokens, character)
				currentToken = ""

				inComment = false
			elseif source:sub(i - 1, i) == "]]" and commentPersist then
				currentToken ..= "]"

				table.insert(tokens, currentToken)
				currentToken = ""

				inComment = false
				commentPersist = false
			else
				currentToken = currentToken .. character
			end
		elseif inString then
			if character == inString and source:sub(i-1, i-1) ~= "\\" or character == "\n" then
				currentToken = currentToken .. character
				inString = false
			else
				currentToken = currentToken .. character
			end
		else
			if source:sub(i, i + 1) == "--" then
				table.insert(tokens, currentToken)
				currentToken = "-"
				inComment = true
				commentPersist = source:sub(i + 2, i + 3) == "[["
			elseif character == "\"" or character == "\'" then
				table.insert(tokens, currentToken)
				currentToken = character
				inString = character
			elseif operatorsSet[character] then
				table.insert(tokens, currentToken)
				table.insert(tokens, character)
				currentToken = ""
			elseif character:match("[%w_]") then
				currentToken = currentToken .. character
			else
				table.insert(tokens, currentToken)
				table.insert(tokens, character)
				currentToken = ""
			end
		end
	end

	table.insert(tokens, currentToken)
	
	local highlighted = {}
	
	for i, token in ipairs(tokens) do
		local highlight = getHighlight(tokens, i)

		if highlight then
			local syntax = string.format("<font color = \"#%s\">%s</font>", highlight:ToHex(), token:gsub("<", "&lt;"):gsub(">", "&gt;"))

			table.insert(highlighted, syntax)
		else
			table.insert(highlighted, token)
		end
	end

	return table.concat(highlighted)
end

return highlighter