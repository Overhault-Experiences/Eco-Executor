local DefaultSettings = {
	--Property Settings--
	IncludeProperties = true,
	OnlySaveUniqueProperties = true, --This setting greatly reduces table size. When enabled, the converted table will only include properties if they are different than the default.
	OnlySaveWritableProperties = true, --If Studio has a property marked as "Read Only", it will not be included when converting to table. Greatly reduces table size. If you are missing important properties, try setting this to false.
	ExcludedProperties = {"ExcludedProperty1","ExcludedProperty2","ExcludedProperty3","etc."}, --(Case Sensitive)
	SpecificExcludedProperties = { --(Case Sensitive)
		--FORMAT: ["ClassName"] = {"ExcludedProperty1","ExcludedProperty2","ExcludedProperty3","etc."},
		--EXAMPLE: ["Part"] = {"LeftSurfaceInput", "TopSurfaceInput","BottomSurfaceInput", "RightSurfaceInput", "FrontSurfaceInput", "BackSurfaceInput"}, 
	},
	IgnoreAttachmentWorldProperties = true, --99% of the time, you won't need the World properties over CFrame. This greatly helps with accurate attachment creation.
	FetchLatestPropertiesOnline = false, --If set to true, HTTPService.HttpEnabled needs to be enabled. If set to true and HTTPService.HttpEnabled is not enabled, it will revert to false. Using this setting requires a response from the setup.rbxcdn.com servers, so any response time will also add to your conversion time. (Typically 0-3 seconds but varies by server.)
	ShowHTTPWarning = true, --If true, a warning will appear in the output if you try to fetch the latest properties while not having HTTP Service enabled.
	IncludeAttributes = true, --Includes the attributes during conversion. [NOTE: When converting into an instance, if a property can't be found, it will automatically be applied as an attribute so I recommend keeping this setting enabled.]
	IncludeTags = true, --Includes CollectionService tags during conversion.
	ExcludedTags = {"ExcludedTag1", "ExcludedTag2", "ExcludedTag3", "etc."}, --(Case Sensitive)
	IncludeObjectVariables = true, --Objects are located using FindFirstChild so make sure your items within the same directory have UNIQUE names! [NOTE: Object variables with DataStoreFriendly DISABLED will reference the ORIGINAL variable so welds and other attachments will not work.]
	Color3Scale = 255, --99% of the time, you should leave this setting alone. I don't suggest changing this setting unless you are using a custom instance table that has a different scale. 255 = Color3.fromRGB | 1 = Color3.new. This NEEDS to match the same scale as the instance table's formatted scale for accurate color reproduction. 
	EnumType = "Enum", --"Enum", "String", or "Int". If set to String, only the EnumItem.Name will be saved. If set to Int, only the EnumItem.Value will be saved. I recommend keeping this on Enum. (Case Sensitive)
	
	--DataStore Compatability Settings--
	DataStoreFriendly = true, --You can disable this if you don't need the table for DataStores. (The table size will be slightly smaller.)
	PrintDataStoreApproximateSize = false, --When converted with DataStoreFriendly enabled, the module will print the approximate size of the table in KB/MB.
	
	--InstanceSettings-- (These settings only apply when converting from Table to Instance)
	DefaultInstanceType = "Folder", --If ClassName is not specified in the table, it will convert the table into this type of instance. (Case Sensitive)
	CarryOverSurfaceAppearances = false, --When converting to INSTANCE, this will carry over ALL POSSIBLE SurfaceAppearance variations for that specific MeshPart if it's found in-game. Command bar/plugins can create SurfaceAppearances from scratch, so keep as false if using a plugin. This option is only needed during runtime scripts. This will increase the cost on performance (loops through every single item in game!), so only enable if you need it!
	--NOTE: CarryOverSurfaceAppearances will currently NOT function until a Roblox bug gets resolved.
	IncludeSurfaceAppearancesOverride = false, --When converting to TABLE, include the SurfaceAppearance if the current security level cannot write the properties for SurfaceAppearance objects. (If you aren't using a plugin, do you still want the SurfaceAppearance data, even though you can't make SurfaceAppearances?)
	AutoConvertMeshParts = true, --Automatically converts any MeshParts into a normal Part with a SpecialMesh object inside ONLY IF the original mesh can't be found in-game. Scripts cannot make MeshParts due to Roblox not providing support for runtime collision rendering. Hopefully Roblox will address this issue in the future so I can remove the need for this setting. If you use this converter outside of runtime (like with a plugin), set this property to false since MeshParts can still be created in edit mode.
	AutoSmoothParts = true, --This automatically makes all part surfaces smooth if there isn't a SurfaceInput specified in the instance table (removes the inlets/stud textures).
	
	
	--Output Settings--
	PrintCompatibilityErrors = true, --If there are any issues with a specific datatype or an instance class, it will print a list of those errors.
	PrintObjectVariableErrors = true, --If an error occurs when setting an object property, a warning will be put in the output. (Typically this will happen if the object is nil or if there are similar names under the same directory.)
	PrintCompletionTime = false, --Prints the amount of time the conversion takes to complete. This does not take into account any server hangups (For example: when converting into a massive directory, it doesn't take into account the delayed time it takes the server to create the instances from Instance.new).
	PrintCleanupAmount = false, --When converting a table into an instance, the source table needs to be cloned. The cleanup function will clean up the copy after using it for conversion. If this setting is enabled, it will print how much background memory in MB was cleaned up (approximate).
}

local SecuritySettings = {
	ModuleCanRunFromTheClient = true
}

local RestrictedSettings = { 
	Color3Scale = {1,255},
	EnumType = {"Enum","String", "Int"},
}

local ServiceList = {"Workspace", "Lighting", "StarterPlayer", "TestService", "SoundService", "Chat", "Terrain"}
local OfflineAPI = require(script.OfflineAPI)
local OfflineProperties = OfflineAPI["APISTRING"]
local DefaultExcludedProperties = {
	"LeftParamA", "LeftParamB","TopParamA", "TopParamB","BottomParamA", "BottomParamB","RightParamA", "RightParamB","FrontParamA", "FrontParamB","BackParamA", "BackParamB",
	"LeftSurfaceInput", "TopSurfaceInput","BottomSurfaceInput", "RightSurfaceInput", "FrontSurfaceInput", "BackSurfaceInput", 
	"CurrentCamera",
	"ResizeableFaces",
	"Parent",
	"clone",
}
local UnsupportedClasses = {"UnionOperation"}

local DefaultInstanceForValueReference = {}
local PreviouslyFetchedProperties = {}

local InstanceNewRefMeshPart = Instance.new("MeshPart")
local CarryoverMeshes = nil
local CanEditSurfaceAppearances = true
local SurfaceAppearanceTest = Instance.new("SurfaceAppearance")
local CollectionService = game:GetService("CollectionService")

local module = {}
module.__index = module

function GetDictionaryLength(Dictionary)
	local Counter = 0
	for i,v in pairs (Dictionary) do
		Counter += 1 
	end
	return Counter
end

function DeepCopy(SourceTable) 
	if type(SourceTable) ~= "table" then
		return SourceTable
	end
	local CopyResult = {}
	for SourceKey, SourceValue in pairs(SourceTable) do
		CopyResult[SourceKey] = DeepCopy(SourceValue)
	end
	return CopyResult
end

local TimeFunction = function()
	return os.clock()
end
local HttpCheckCount = 0
local HttpMaxCheckCount = 20
local HttpEnabled = pcall(function() game:GetService("HttpService"):GetAsync('https://setup.rbxcdn.com/versionQTStudio') end)


function RecheckIfHTTPEnabled()
	HttpCheckCount +=1
	if HttpCheckCount < HttpMaxCheckCount then
		local StartTime = tonumber(TimeFunction())
		local HttpTest, ResponseError = pcall(function() game:GetService("HttpService"):GetAsync('https://setup.rbxcdn.com/versionQTStudio') end)
		HttpEnabled = HttpTest
		local EndTime = tonumber(TimeFunction())
		local ResponseTime = EndTime - StartTime 
		if HttpTest == false and typeof(ResponseError) == "string" then
			if not string.find(ResponseError, " 403") and not string.find(ResponseError, "plugin")  then
				warn(ResponseError)
			end
		else
			if ResponseTime > 3 then
				warn("HTTP Service took a much longer amount of time to connect to connect to https://setup.rbxcdn.com/ than expected. Time taken to receive a repsonse: " ..tostring(math.round(ResponseTime)).. " seconds.")
			end
		end
	end
end


function InsertAlpha(SubjectTable,InsertingStr)
	if typeof(SubjectTable) ~= "table" then return end
	if typeof(InsertingStr) ~= "string" then return end
	local Property = InsertingStr
	local Inserted
	for j = 1, #SubjectTable do
		if Property > SubjectTable[j] then
			Inserted = true
			table.insert(SubjectTable, j, Property)
			break
		end
	end
	if (not Inserted) then
		table.insert(SubjectTable, Property)
	end
end

function RemoveUnwantedCharacters(OldString)
	if OldString == nil then OldString = "" end
	local NewString = tostring(OldString)
	local RejectedNames = {"name", "parent", "classname", "archivable"}
	if table.find(RejectedNames,string.lower(NewString)) then
		NewString = NewString .. "InstanceToTableModuleRenamedMeBecauseIAmANameThatIsAlsoAPropertyYouShouldNotNameYourInstancesAfterPropertiesItIsABadHabit"
	end
	NewString = NewString:gsub('%[VISUAL ONLY%]', '')
	NewString = NewString:gsub('%[OLD%]', '')
	NewString = NewString:gsub('%[PLUGIN REFERENCE DO NOT EDIT%]', '')
	NewString = NewString:gsub('[%W]', '')
	return NewString
end

function FetchSettings(DesiredSettings)
	local AdjustedSettings = {}
	for i,v in pairs(DefaultSettings) do
		AdjustedSettings[i] = v
	end
	if typeof(DesiredSettings) == "table" then
		for i,v in pairs (DesiredSettings) do
			if AdjustedSettings[i] ~= nil then
				if typeof(AdjustedSettings[i]) == typeof(v) then
					if RestrictedSettings[i] ~= nil then
						if table.find(RestrictedSettings[i],v) then
							AdjustedSettings[i] = v
						else
							local Options = "{"
							for _,Option in ipairs(RestrictedSettings[i]) do
								local StringHolder = ""
								if typeof(Option) == "string" then StringHolder = '"' end
								Options = Options ..StringHolder.. tostring(Option) ..StringHolder..","
							end
							Options = Options .. "}"
							warn('ConversionSetting "' ..tostring(i).. '" was given a setting that is not an option. Recieved setting was: ' ..tostring(v).. '.\n Available options for "' ..tostring(i).. '" are: \n' ..Options.. " \n ConversionSetting was reset to its default setting (" ..tostring(AdjustedSettings[i]).. ")" )
						end
					else
						AdjustedSettings[i] = v
					end
				else
					warn('ConversionSetting "' ..tostring(i).. '" is not formatted correctly. Recieved a ' ..string.upper(tostring(typeof(v))).. '. "' ..tostring(i).. '" needs to be a ' ..string.upper(tostring(typeof(AdjustedSettings[i]))).. '.' )
				end
			end
		end
	end
	if AdjustedSettings.IgnoreAttachmentWorldProperties == true and typeof(AdjustedSettings["ExcludedProperties"]) == "table" then
		if not table.find(AdjustedSettings["ExcludedProperties"], "WorldCFrame") then
			table.insert(AdjustedSettings["ExcludedProperties"], "WorldCFrame")
		end
		if not table.find(AdjustedSettings["ExcludedProperties"], "WorldPosition") then
			table.insert(AdjustedSettings["ExcludedProperties"], "WorldPosition")
		end
		if not table.find(AdjustedSettings["ExcludedProperties"], "WorldAxis") then
			table.insert(AdjustedSettings["ExcludedProperties"], "WorldAxis")
		end
		if not table.find(AdjustedSettings["ExcludedProperties"], "WorldOrientation") then
			table.insert(AdjustedSettings["ExcludedProperties"], "WorldOrientation")
		end
		if not table.find(AdjustedSettings["ExcludedProperties"], "WorldSecondaryAxis") then
			table.insert(AdjustedSettings["ExcludedProperties"], "WorldSecondaryAxis")
		end
	end
	return AdjustedSettings
end

function InsertPreviousProperties(IgnoredPropertiesList, PropertyTable, WritableProperties)
	if typeof(IgnoredPropertiesList) ~= "table" or typeof(PropertyTable) ~= "table" then return end
	local ExistingTable = false
	local NumberOfIgnoredProperties = GetDictionaryLength(IgnoredPropertiesList)
	for i,v in pairs (PreviouslyFetchedProperties) do
		if typeof(v) == "table" then
			if typeof(v[1]) == "table" and typeof(v[2]) == "table" then
				if GetDictionaryLength(v[1]) == NumberOfIgnoredProperties then
					local AllThere = true
					for _,PropertyName in pairs(v[1]) do
						if typeof(PropertyName) == "string" then
							if not table.find(IgnoredPropertiesList, PropertyName) then
								AllThere = false
							end
						end
					end
					if AllThere == true and ((not v[3]) == (not WritableProperties)) then
						ExistingTable = true
					end
				end
			end
		end
	end
	if ExistingTable == false then
		table.insert(PreviouslyFetchedProperties, {IgnoredPropertiesList,PropertyTable,(WritableProperties or false)})
	end
end

function FetchPreviousProperties(IgnoredPropertiesList, WritableProperties)
	if typeof(IgnoredPropertiesList) ~= "table" then return nil end
	local ExistingTable = nil
	local NumberOfIgnoredProperties = GetDictionaryLength(IgnoredPropertiesList)
	for i,v in pairs (PreviouslyFetchedProperties) do
		if typeof(v) == "table" then
			if typeof(v[1]) == "table" and typeof(v[2]) == "table" then
				if GetDictionaryLength(v[1]) == NumberOfIgnoredProperties then
					local AllThere = true
					for _,PropertyName in pairs(v[1]) do
						if typeof(PropertyName) == "string" then
							if not table.find(IgnoredPropertiesList, PropertyName) then
								AllThere = false
							end
						else
							AllThere = false
						end
					end
					if AllThere == true and ((not v[3]) == (not WritableProperties)) then
						ExistingTable = v[2]
						break
					end
				end
			end
		end
	end
	return ExistingTable
end

function module:FetchProperties(FetchFromOnlineAPI, IgnoredProperties, PrintingWarning, FetchReadOnlyProperties, FetchALLProperties)
	if typeof(FetchFromOnlineAPI) ~= "boolean" then warn("Fetching Properties function needs a boolean. True = Fetch directly from the Roblox API. | False = Fetch from a Roblox Module scraped from the API.") return {} end
	local RunService = game:GetService("RunService") local IsEdit = false  local RunStatusTest = pcall(function() IsEdit = RunService:IsEdit() end) if IsEdit == true then FetchFromOnlineAPI = true  RecheckIfHTTPEnabled() end
	if FetchFromOnlineAPI == true and not HttpEnabled and IsEdit == true then if PrintingWarning == true then warn("Converter Module: Instance ↔ Table detected that it was called from a plugin. The plugin needs HTTP permissions in order to fetch latest properties.") end  FetchFromOnlineAPI = false end
	if typeof(IgnoredProperties) ~= "table" then IgnoredProperties = {} end
	local HttpService = game:GetService("HttpService")
	local StringToDecode = ""
	if FetchFromOnlineAPI == true then
		local SuccessfulConnection, errMsg = pcall(function()
			local RawAPIVersionData = HttpService:GetAsync("https://setup.rbxcdn.com/versionQTStudio")
			local CurrentAPIVersion = tostring(RawAPIVersionData)
			local SuccessfulDecode , DecodeErr = pcall(function()
				local DecodedAPIVersionData = HttpService:JSONDecode(RawAPIVersionData)
				CurrentAPIVersion = DecodedAPIVersionData
			end)
			StringToDecode = HttpService:GetAsync("https://setup.rbxcdn.com/" ..tostring(CurrentAPIVersion).. "-API-Dump.json")
		end)
		if not SuccessfulConnection then
			warn("COULD NOT FETCH PROPERTIES: " ..errMsg)
			return 
		end 
	elseif FetchFromOnlineAPI == false then
		StringToDecode = OfflineAPI["APISTRING"]
	end
	
	local Decoded = {}

	local SuccessfulConnection, errMsg = pcall(function() 
		local DecodedData = HttpService:JSONDecode(StringToDecode)
		Decoded = DecodedData
	end)
	if not SuccessfulConnection then warn("An error occured while trying to decode properties from the API.") return end
	local ClassProperties = {}
	local function GetClassesFromClassItem(DesiredClassName)
		local ReturningProperties = {}
		for i, v in pairs (Decoded.Classes) do
			if v.Name then
				if v.Name == DesiredClassName then
					if typeof(v.Members) == "table" then
						for i,Subv in pairs(v.Members) do
							if Subv.MemberType then
								if Subv.MemberType == "Property" then 
									if typeof(Subv.Name) == "string" then
										if (not table.find(DefaultExcludedProperties,Subv.Name) and not table.find(IgnoredProperties,Subv.Name) ) or FetchALLProperties == true  then
											if Subv.Tags then
												if not table.find(Subv.Tags, "Hidden") and not table.find(Subv.Tags, "Deprecated") --[[and not table.find(Subv.Tags, "NotReplicated")]]  then
													if table.find(Subv.Tags, "ReadOnly") and FetchReadOnlyProperties == true then --11/16/22
														InsertAlpha(ReturningProperties, Subv.Name)
													elseif not table.find(Subv.Tags, "ReadOnly") or Subv.Name == "ClassName" then
														InsertAlpha(ReturningProperties, Subv.Name)
													end
												end
											else
												InsertAlpha(ReturningProperties, Subv.Name)
											end
										end
									end
								end
							end
						end
					end
					if v.Superclass then
						for i, Subv in pairs (GetClassesFromClassItem(v.Superclass)) do
							if not table.find(ReturningProperties,Subv) then
								InsertAlpha(ReturningProperties,Subv)
							end
						end
					end
				end
			end
		end
		return ReturningProperties
	end
	for i, v in pairs (Decoded.Classes) do
		local SubjectProperties = {}
		if v.Name then
			if typeof(v.Members) == "table" then
				for i,Subv in pairs(v.Members) do
					if Subv.MemberType then
						if Subv.MemberType == "Property" then 
							if typeof(Subv.Name) == "string" then
								if ( not table.find(DefaultExcludedProperties,Subv.Name) and not table.find(IgnoredProperties,Subv.Name) ) or FetchALLProperties == true  then
									if Subv.Tags then
										if not table.find(Subv.Tags, "Hidden") and not table.find(Subv.Tags, "Deprecated") --[[and not table.find(Subv.Tags, "NotReplicated")]] then
											if table.find(Subv.Tags, "ReadOnly") and FetchReadOnlyProperties == true then --11/16/22
												InsertAlpha(SubjectProperties, Subv.Name)
											elseif not table.find(Subv.Tags, "ReadOnly") or Subv.Name == "ClassName" then
												InsertAlpha(SubjectProperties, Subv.Name)
											end
										end
									else
										InsertAlpha(SubjectProperties, Subv.Name)
									end
								end
							end
						end
					end
				end
			end
			if v.Superclass then
				for i,Subv in pairs (GetClassesFromClassItem(v.Name)) do
					if not table.find(SubjectProperties,Subv) then
						InsertAlpha(SubjectProperties,Subv)
					end
				end
			end
			ClassProperties[v.Name] = SubjectProperties
		end
	end
	return ClassProperties
end
local AllPropertiesNoExclusions = nil

function ConvertObjectToString(SelfObject, ReferenceObject, HighestParent)
	if not SelfObject or not ReferenceObject or not HighestParent then return "" end
	local PreSecureCheck = pcall(function() if not ReferenceObject.Parent then error() end end)
	if not PreSecureCheck then return "" end
	local FinalLocationString = "game"
	if ReferenceObject:IsDescendantOf(SelfObject) then
		local SearchingParent = SelfObject
		FinalLocationString = "self"
		repeat
			for i,v in pairs (SearchingParent:GetChildren()) do
				if v then
					if ReferenceObject:IsDescendantOf(v) then
						SearchingParent = v
						FinalLocationString = FinalLocationString.. '.' ..v.Name
					end
				end
			end
			if not ReferenceObject or not SearchingParent then return "" end
		until SearchingParent == ReferenceObject.Parent
		FinalLocationString = FinalLocationString.. '.' ..ReferenceObject.Name
	elseif ReferenceObject:IsDescendantOf(HighestParent) then
		FinalLocationString = "self"
		local DirectSelfParents = {}
		local CurrentFocusedParent = SelfObject.Parent
		repeat 
			table.insert(DirectSelfParents,CurrentFocusedParent)
			CurrentFocusedParent = CurrentFocusedParent.Parent
		until not CurrentFocusedParent:IsDescendantOf(HighestParent) and CurrentFocusedParent ~= HighestParent
		local SimilarParent = nil
		for i = 1, #DirectSelfParents do
			FinalLocationString = FinalLocationString .. ".Parent"
			if DirectSelfParents[i] then
				if ReferenceObject:IsDescendantOf(DirectSelfParents[i]) then
					SimilarParent = DirectSelfParents[i]
					break
				end
			end
		end
		if not SimilarParent then return "" end
		local SearchingParent = SimilarParent
		repeat
			for i,v in pairs (SearchingParent:GetChildren()) do
				if v then
					if ReferenceObject:IsDescendantOf(v) then
						SearchingParent = v
						FinalLocationString = FinalLocationString.. '.' ..v.Name
					end
				end
			end
			if not ReferenceObject or not SearchingParent then return "" end
		until SearchingParent == ReferenceObject.Parent
		FinalLocationString = FinalLocationString.. '.' ..ReferenceObject.Name
	else
		FinalLocationString = "game"
		local SearchingParent = game
		repeat
			for i,v in pairs (SearchingParent:GetChildren()) do
				local SecureCheck = pcall(function() if not v or not v.Parent then error() end end)
				if SecureCheck then
					if ReferenceObject:IsDescendantOf(v) then
						SearchingParent = v
						FinalLocationString = FinalLocationString.. '.' ..v.Name
						break
					end
				end
			end
			if not ReferenceObject or not SearchingParent then return "" end
		until SearchingParent == ReferenceObject.Parent
		FinalLocationString = FinalLocationString.. '.' ..ReferenceObject.Name
	end
	return FinalLocationString
end

function CollectTags(InstanceItem, TagFilter)
	if typeof(InstanceItem) ~= "Instance" then return nil end
	if typeof(TagFilter) ~= "table" then TagFilter = {} end
	local Tags = CollectionService:GetTags(InstanceItem)
	local FilteredTags = {}
	for _, Tag in pairs(Tags) do
		if not table.find(TagFilter,Tag) then
			table.insert(FilteredTags, Tag)
		end
	end
	return FilteredTags
end

function SafelyAddToTable (Table, Key, Value, CurrentSettings, SelfObject, OriginalObject)
	if typeof(Table) ~= "table" then return end
	if typeof(Key) ~= "string" then return end
	if typeof(CurrentSettings) ~= "table" then return end
	local DataStoreFriendly = CurrentSettings["DataStoreFriendly"]
	local DesiredColorScale = CurrentSettings["Color3Scale"] or 1
	local EnumType = CurrentSettings["EnumType"] or "Enum"
	local IncludingObjects = CurrentSettings["IncludeObjectVariables"]
	if typeof(IncludingObjects) ~= "boolean" then IncludingObjects = true end
	if typeof(DataStoreFriendly) ~= "boolean" then return end
	if Value == nil then return end
	local CurrentCount = 1
	local AvailableKey = ""
	if Table[Key] ~= nil then
		repeat CurrentCount +=1
		until Table[Key ..tostring(CurrentCount)] == nil
		AvailableKey = Key ..tostring(CurrentCount)
	else
		AvailableKey = Key
	end
	
	if (typeof(Value) ~= "table" and typeof(Value) ~= "boolean" and typeof(Value) ~= "number" and typeof(Value) ~= "string") and DataStoreFriendly == true then
		if typeof(Value) == "Vector2" then
			Table[AvailableKey] = {["X"] = Value.X, ["Y"] = Value.Y}
		elseif typeof(Value) == "Vector3" then
			Table[AvailableKey] = {["X"] = Value.X, ["Y"] = Value.Y, ["Z"] = Value.Z}
		elseif typeof(Value) == "Color3" then
			if DesiredColorScale == 1 then
				Table[AvailableKey] = {["R"] = Value.R, ["G"] = Value.G, ["B"] = Value.B, ["Scale"] = DesiredColorScale}
			elseif DesiredColorScale == 255 then
				Table[AvailableKey] = {["R"] = math.round(Value.R*DesiredColorScale), ["G"] = math.round(Value.G*DesiredColorScale), ["B"] = math.round(Value.B*DesiredColorScale), ["Scale"] = DesiredColorScale}
			end
		elseif typeof(Value) == "UDim" then
			Table[AvailableKey] = {["Scale"] = Value.Scale, ["Offset"] = Value.Offset}
		elseif typeof(Value) == "UDim2" then
			Table[AvailableKey] = {["X"] = {["Scale"] = Value.X.Scale, ["Offset"] = Value.X.Offset}, ["Y"] = {["Scale"] = Value.Y.Scale, ["Offset"] = Value.Y.Offset}}
		elseif typeof(Value) == "Font" then
			local FontSuccess, FontError = pcall(function()
				if Value.Weight and Value.Style then
					Table[AvailableKey] = {["FontFamily"] = Value.Family, ["FontWeight"] = Value.Weight.Name, ["FontStyle"] = Value.Style.Name}
				else
					Table[AvailableKey] = {["FontFamily"] = Value.Family, ["FontWeight"] = "Regular", ["FontStyle"] = "Normal"}
				end
			end)
			if not FontSuccess and CurrentSettings.PrintCompatibilityErrors then warn(FontError) end
		elseif typeof(Value) == "Rect" then
			Table[AvailableKey] = {["Min"] = {["X"] = Value.Min.X, ["Y"] = Value.Min.Y}, ["Max"] = {["X"] = Value.Max.X, ["Y"] = Value.Max.Y}}
		elseif typeof(Value) == "NumberRange" then
			Table[AvailableKey] = {["Min"] = Value.Min, ["Max"] = Value.Max}
		elseif typeof(Value) == "NumberSequence" then
			local SequenceKeypointTable = {}
			for i = 1, #Value.Keypoints do
				SequenceKeypointTable[tostring(i)] = {["Time"] = Value.Keypoints[i].Time, ["Value"] = Value.Keypoints[i].Value, ["Envelope"] = Value.Keypoints[i].Envelope}
			end
			Table[AvailableKey] = SequenceKeypointTable
		elseif typeof(Value) == "ColorSequence" then
			local SequenceKeypointTable = {}
			for i = 1, #Value.Keypoints do
				SequenceKeypointTable[tostring(i)] = {["Time"] = Value.Keypoints[i].Time, ["R"] = Value.Keypoints[i].Value.R, ["G"] = Value.Keypoints[i].Value.G, ["B"] = Value.Keypoints[i].Value.B}
			end
			Table[AvailableKey] = SequenceKeypointTable
		elseif typeof(Value) == "PhysicalProperties" then
			Table[AvailableKey] = {["Density"] = Value.Density, ["Friction"] = Value.Friction, ["Elasticity"] = Value.Elasticity, ["FrictionWeight"] = Value.FrictionWeight, ["ElasticityWeight"] = Value.ElasticityWeight}
		elseif typeof(Value) == "EnumItem" then
			if string.lower(EnumType) == "string" then
				Table[AvailableKey] = Value.Name
			elseif string.lower(EnumType) == "int" then
				Table[AvailableKey] = Value.Value
			else
				Table[AvailableKey] = {["EnumType"] = tostring(Value.EnumType), ["Name"] = Value.Name}
			end
		elseif typeof(Value) == "CFrame" then
			local Split = string.split(tostring(Value), ",")
			Table[AvailableKey] =  { ["X"] = tonumber(Split[1]), ["Y"] = tonumber(Split[2]), ["Z"] = tonumber(Split[3]), ["R00"] = tonumber(Split[4]), ["R01"] = tonumber(Split[5]), ["R02"] = tonumber(Split[6]), ["R10"] = tonumber(Split[7]), ["R11"] = tonumber(Split[8]), ["R12"] = tonumber(Split[9]), ["R20"] = tonumber(Split[10]), ["R21"] = tonumber(Split[11]), ["R22"] = tonumber(Split[12]) }
		elseif typeof(Value) == "Instance" then
			if IncludingObjects then
				if typeof(SelfObject) == "Instance" and typeof(OriginalObject) == "Instance" then
					Table[AvailableKey] = ConvertObjectToString(SelfObject,Value,OriginalObject)
				end
			end
		elseif typeof(Value) == "BrickColor" then
			Table[AvailableKey] = {["BrickColor"] = Value.Name}
		elseif typeof(Value) == "Axes" then
			Table[AvailableKey] = {["X"] = Value.X, ["Y"] = Value.Y, ["Z"] = Value.Z}
		elseif typeof(Value) == "Ray" then
			Table[AvailableKey] = {["Origin"] = {["X"] = Value.Origin.X, ["Y"] = Value.Origin.Y, ["Z"] = Value.Origin.Z}, ["Direction"] = {["X"] = Value.Direction.X, ["Y"] = Value.Direction.Y, ["Z"] = Value.Direction.Z}}
		elseif typeof(Value) == "Faces" then
			Table[AvailableKey] = {["Top"] = Value.Top, ["Bottom"] = Value.Bottom, ["Left"] = Value.Left, ["Right"] = Value.Right, ["Front"] = Value.Front, ["Back"] = Value.Back}
		elseif typeof(Value) == "TweenInfo" then
			if typeof(CurrentSettings["ErrorTable"]) ~= "table" then CurrentSettings["ErrorTable"] = {} end
			local ErrString = 'Converter Module: Instance ↔ Table does not support ' ..tostring(typeof(Value)).. " values while being DataStoreFriendly. Any " ..tostring(typeof(Value)).. " properties were not saved."
			if not table.find(CurrentSettings["ErrorTable"], ErrString) then
				table.insert(CurrentSettings["ErrorTable"], ErrString)
			end
		else
			if typeof(CurrentSettings["ErrorTable"]) ~= "table" then CurrentSettings["ErrorTable"] = {} end
			if typeof(SelfObject) == "Instance" then
				local ErrString = 'Found new value type. Item Name: ' ..tostring(SelfObject.Name)..' | Value Name: "' ..Key .. '" | Type:' .. tostring(typeof(Value)) .. " | Value: " ..tostring(Value)
				if not table.find(CurrentSettings["ErrorTable"], ErrString) then
					table.insert(CurrentSettings["ErrorTable"], ErrString)
				end
			end
		end
	else
		if typeof(Value) == "EnumItem" then
			if string.lower(EnumType) == "string" then
				Table[AvailableKey] = Value.Name
			elseif string.lower(EnumType) == "int" then
				Table[AvailableKey] = Value.Value
			else
				Table[AvailableKey] = Value
			end
		elseif typeof(Value) == "Instance" then
			if IncludingObjects then
				Table[AvailableKey] = Value
			end
		else
			Table[AvailableKey] = Value
		end
	end
	return Table[AvailableKey]
end

function DoForEveryObject(Object, ParentTableReference, PropertyReference, CurrentSettings, MasterObject)
	if typeof(Object) == "Instance" then
		if CurrentSettings.IncludeProperties == true then
			local CurrentClass = Object.ClassName or "NOTAVAILABLE"
			local ClassNameTest, FailedTest = pcall(function()
				local ClassNameToCheck = Object["ClassName"]
				if typeof(ClassNameToCheck) == "string" then
					if table.find(UnsupportedClasses, ClassNameToCheck) then
						if ClassNameToCheck == "UnionOperation" then CurrentClass = "Part" end
						if typeof(CurrentSettings["ErrorTable"]) ~= "table" then CurrentSettings["ErrorTable"] = {} end
						local ErrString = 'The instance to table conversion contained a '..tostring(ClassNameToCheck).. ' object. ' ..tostring(ClassNameToCheck).. 's are not supported.'
						if not table.find(CurrentSettings["ErrorTable"], ErrString) then
							table.insert(CurrentSettings["ErrorTable"], ErrString)
						end
					end
				end
			end)
			local ClassProperties = nil
			if CurrentSettings.OnlySaveWritableProperties == true then
				ClassProperties = PropertyReference[CurrentClass]
			else
				ClassProperties = AllPropertiesNoExclusions[CurrentClass]
			end
			if typeof(ClassProperties) == "table" then
				local InstanceReference = DefaultInstanceForValueReference[CurrentClass]
				if not InstanceReference then
					local NewInstanceReference = nil
					local InstanceTest = pcall(function()
						NewInstanceReference = Instance.new(CurrentClass)
					end)
					DefaultInstanceForValueReference[CurrentClass] = NewInstanceReference
					InstanceReference = NewInstanceReference
				end
				for i,v in pairs (ClassProperties) do
					if v then
						local HasProperty, err = pcall(function() local Test = Object[v] end)
						local SpecificExcludedProperties = {}
						if typeof(CurrentSettings.SpecificExcludedProperties[CurrentClass]) == "table" then SpecificExcludedProperties = CurrentSettings.SpecificExcludedProperties[CurrentClass] end
						if HasProperty and not table.find(CurrentSettings.ExcludedProperties, v) and not table.find(SpecificExcludedProperties, v) then
							if InstanceReference then
								if InstanceReference[v] ~= Object[v] and Object[v] ~= nil and CurrentSettings.OnlySaveUniqueProperties == true and (v ~= "ClassName" and v ~= "Name") then
									local NewTableValue = SafelyAddToTable(ParentTableReference, v, Object[v], CurrentSettings, Object, MasterObject)
								elseif (v == "ClassName" or v == "Name") then
									if v == "ClassName" and (Object[v] == "UnionOperation" or Object[v] == "NegateOperation" or Object[v] == "PartOperation" or Object[v] == "Union") then
										local NewTableValue = SafelyAddToTable(ParentTableReference, v, "Part", CurrentSettings, Object, MasterObject)
									else
										local NewTableValue = SafelyAddToTable(ParentTableReference, v, Object[v], CurrentSettings, Object, MasterObject)
									end
								elseif CurrentSettings.OnlySaveUniqueProperties == false then
									local NewTableValue = SafelyAddToTable(ParentTableReference, v, Object[v], CurrentSettings, Object, MasterObject)
								end
							else
								local NewTableValue = SafelyAddToTable(ParentTableReference, v, Object[v], CurrentSettings, Object, MasterObject)
							end
						end
					end
				end
			end
		end
		if CurrentSettings.IncludeAttributes == true then
			if Object then
				local ObjectAttributes = Object:GetAttributes()
				for i,v in pairs(ObjectAttributes) do
					local NewTableValue = SafelyAddToTable(ParentTableReference, i, v, CurrentSettings, Object, MasterObject)
				end
			end
		end
		if CurrentSettings.IncludeTags == true then
			if Object then
				local ObjectTags = CollectTags(Object, CurrentSettings.ExcludedTags)
				if #ObjectTags > 0 then
					ParentTableReference["[TAGS]"] = ObjectTags
				end
			end
		end
		if Object then
			local DirectChildren = Object:GetChildren()
			local ObjectClassName = ""
			local Success,Fail = pcall(function() ObjectClassName = Object.ClassName or "" end)
			if #DirectChildren > 0 and (not table.find(ServiceList, ObjectClassName) and ObjectClassName ~= "")then
				for i,v in pairs (DirectChildren) do
					if v then
						if CanEditSurfaceAppearances == false and CurrentSettings["IncludeSurfaceAppearancesOverride"] == true and v.ClassName == "SurfaceAppearance" then
							local vTable = SafelyAddToTable(ParentTableReference, RemoveUnwantedCharacters(v.Name), {}, CurrentSettings)
							DoForEveryObject(v, vTable, PropertyReference, CurrentSettings, MasterObject)
						elseif v.ClassName ~= "SurfaceAppearance" then --11/16/22
							local vTable = SafelyAddToTable(ParentTableReference, RemoveUnwantedCharacters(v.Name), {}, CurrentSettings)
							DoForEveryObject(v, vTable, PropertyReference, CurrentSettings, MasterObject)
						elseif CanEditSurfaceAppearances == true then --11/16/22
							local vTable = SafelyAddToTable(ParentTableReference, RemoveUnwantedCharacters(v.Name), {}, CurrentSettings)
							DoForEveryObject(v, vTable, PropertyReference, CurrentSettings, MasterObject)
						end
					end
				end
			end
		end
	end
	return ParentTableReference
end

function module:ConvertToTable(Object:Instance, ConversionSettings)
	CanEditSurfaceAppearances = pcall(function() SurfaceAppearanceTest.ColorMap = "" end)
	local RunService = game:GetService("RunService") local IsEdit = false local RunStatusTest = pcall(function() IsEdit = RunService:IsEdit() end) if (RunService:IsClient() and (not RunService:IsStudio() or not IsEdit ) ) then if SecuritySettings.ModuleCanRunFromTheClient == false then script:Destroy() error("CONVERTER IS NOT ALLOWED TO BE CALLED FROM THE CLIENT.") end end
	if typeof(Object) ~= "Instance" then if not IsEdit then warn("Supplied object is nil or not an object.") end return nil end
	if typeof(ConversionSettings) ~= "table" and typeof(ConversionSettings) ~= "nil" then warn("Recieved ConversionSettings as a ".. string.upper(tostring(typeof(ConversionSettings)).. " format. ConversionSettings need to be in a dictionary format. ") ) return nil end
	
	local CloneTest, failureMsg = pcall(function()
		local Clone = Object:Clone()
		if Clone then
			Clone:Destroy()
		end
	end)
	if not CloneTest then 
		local ObjClass = ""
		local ObjName = ""
		local Success, Error = pcall(function() ObjClass = Object.ClassName or ""  ObjName = Object.Name or "" end)
		if not table.find(ServiceList, ObjClass) then
			warn('Selected directory "' ..ObjName.. '" is an unsupported service or an unrecognized object type. Converter Module only supports making tables from the following services: ') warn(ServiceList) return nil 
		end
	end
	local ObjectName = Object.Name
	
	local CurrentSettings = FetchSettings(ConversionSettings)
	CurrentSettings.StartTime = tonumber(TimeFunction())
	
	local ClassNameTest, FailedTest = pcall(function()
		local ClassNameToCheck = Object["ClassName"]
		if typeof(ClassNameToCheck) == "string" then
			if table.find(UnsupportedClasses, ClassNameToCheck) then
				if typeof(CurrentSettings["ErrorTable"]) ~= "table" then CurrentSettings["ErrorTable"] = {} end
				local ErrString = 'The instance to table conversion contained a '..tostring(ClassNameToCheck).. ' object. ' ..tostring(ClassNameToCheck).. 's are not supported.'
				if not table.find(CurrentSettings["ErrorTable"], ErrString) then
					table.insert(CurrentSettings["ErrorTable"], ErrString)
				end
			end
		end
	end)
	
	if CurrentSettings.IncludeProperties == true then
		if HttpEnabled == false and CurrentSettings.FetchLatestPropertiesOnline == true and IsEdit == false then RecheckIfHTTPEnabled() end
		if HttpEnabled == false and CurrentSettings.FetchLatestPropertiesOnline == true then if CurrentSettings.ShowHTTPWarning == true then warn("In order for Converter Module: Instance ↔ Table to fetch the latest properties from the API, HTTP service needs to be enabled.") end end
		if HttpEnabled == false then CurrentSettings.FetchLatestPropertiesOnline = false end
	end
	local PropertyReference = nil
	local PreviousPropertyReference = FetchPreviousProperties(CurrentSettings.ExcludedProperties, CurrentSettings.OnlySaveWritableProperties)
	if not AllPropertiesNoExclusions then
		AllPropertiesNoExclusions = module:FetchProperties(CurrentSettings.FetchLatestPropertiesOnline,{}, false, true)
	end
	if not PreviousPropertyReference then
		PropertyReference = module:FetchProperties(CurrentSettings.FetchLatestPropertiesOnline, CurrentSettings.ExcludedProperties, CurrentSettings.ShowHTTPWarning, not CurrentSettings.OnlySaveWritableProperties)
		InsertPreviousProperties(CurrentSettings.ExcludedProperties, PropertyReference, CurrentSettings.OnlySaveWritableProperties)
	else
		PropertyReference = PreviousPropertyReference
	end
	
	local MasterTable = {}
	
	DoForEveryObject(Object,MasterTable,PropertyReference,CurrentSettings,Object)
	
	local function GetStringSizeInBytes(StringToConvert, TrueSize, ExactSize)
		if not StringToConvert or(typeof(StringToConvert) ~= "string" and typeof(StringToConvert) ~= "number") then warn("Got a non-string while trying to index string size in bytes.") return "" end
		local FinalSize = StringToConvert
		local SizeMetric = "BYTES"
		if FinalSize >= 1000 then
			FinalSize = FinalSize/1000
			SizeMetric = "KB"
			if FinalSize >= 1000 then
				FinalSize = FinalSize/1000
				SizeMetric = "MB"
				if FinalSize >= 1000 then
					FinalSize = FinalSize/1000
					SizeMetric = "GB"
					if FinalSize >= 1000 then
						FinalSize = FinalSize/1000
						SizeMetric = "TB"
					end
				end
			end
		end
		if ExactSize ~= true then FinalSize = math.floor((FinalSize*100))/ 100 end
		local ReturningString = tostring(FinalSize) .. " " ..SizeMetric 
		return ReturningString
	end

	if typeof(CurrentSettings.ErrorTable) == "table" and CurrentSettings.PrintCompatibilityErrors == true then
		for i,v in ipairs(CurrentSettings.ErrorTable) do
			warn(v)
		end
	end

	local RunningFrom = "server" local IsEdit = false  local RunStatusTest = pcall(function() IsEdit = RunService:IsEdit() end) if ( RunService:IsClient() and (not RunService:IsStudio() or not IsEdit) ) then RunningFrom = "client" elseif RunService:IsStudio() then RunningFrom = "Roblox Studio handler" end
	if CurrentSettings.PrintCompletionTime == true and typeof(CurrentSettings.StartTime) == "number" and typeof(Object) == "Instance" then
		local TimeTookToComplete = tonumber(TimeFunction()) - CurrentSettings.StartTime
		local CurrentTimeMeasurement = "seconds"
		local FormattedTime = ( math.round( (TimeTookToComplete*10) ) ) / 10
		if FormattedTime >= 60 then FormattedTime = (math.round( (FormattedTime / 60) * 100) ) / 100; if FormattedTime > 1 then CurrentTimeMeasurement = "minutes" else CurrentTimeMeasurement = "minute" end end
		local StringFormattedTime =  tostring( FormattedTime )
		print("It took the " ..RunningFrom.. " " ..StringFormattedTime.. " " ..CurrentTimeMeasurement.. ' to convert the object "' ..ObjectName..'" into a table.')
	end

	local TableSize = string.len(tostring(game:GetService("HttpService"):JSONEncode(MasterTable)))
	local DataStoreMaxSize = 4000000
	local DataStoreMaxSizeConvertedFromBytesToString = "4 MB"
	local TableSizeConvertedFromBytesToString = GetStringSizeInBytes(TableSize)
	local SizeOver = TableSize - DataStoreMaxSize
	local TableSizeOverConvertedFromBytesToString = GetStringSizeInBytes(SizeOver)
	if TableSize >= DataStoreMaxSize and CurrentSettings.DataStoreFriendly == true and IsEdit == false then
		warn("\n"..string.upper("Converted table exceeds DataStore Limit (per key). \n")..  "DataStore Limit: " ..DataStoreMaxSizeConvertedFromBytesToString .. " | "..ObjectName.. "'s Approximate Conversion Size: " ..TableSizeConvertedFromBytesToString.. " (" ..TableSizeOverConvertedFromBytesToString.." above the limit.)\nTry excluding unnecessary properties or try converting an instance with less descendants.")
	else
		if CurrentSettings.PrintDataStoreApproximateSize == true  and CurrentSettings.DataStoreFriendly == true then
			print(ObjectName.. "'s Approximate Conversion Size: " ..TableSizeConvertedFromBytesToString)
		end
	end
	
	return MasterTable
end

function FormatValue(Table, ReturningType)
	if typeof(Table) ~= "table" then return nil end 
	local ReturningValue = nil
	local success, err = pcall(function()
		if ReturningType == "CFrame" then
			ReturningValue = CFrame.new(Table["X"],Table["Y"],Table["Z"],Table["R00"],Table["R01"],Table["R02"],Table["R10"],Table["R11"],Table["R12"],Table["R20"],Table["R21"],Table["R22"])
		elseif ReturningType == "EnumItem" then
			local EnumType = tostring(Table["EnumType"])
			local EnumName = tostring(Table["Name"])
			ReturningValue = Enum[EnumType][EnumName]
		elseif ReturningType == "BrickColor" then
			ReturningValue = BrickColor.new(tostring(Table["BrickColor"]))
		elseif ReturningType == "Color3" then
			local ColorScale = Table["Scale"]
			ReturningValue = Color3.new(Table["R"]/ColorScale,Table["G"]/ColorScale,Table["B"]/ColorScale)
		elseif ReturningType == "Vector3" then
			ReturningValue = Vector3.new(Table["X"],Table["Y"],Table["Z"])
		elseif ReturningType == "Vector2" then
			ReturningValue = Vector2.new(Table["X"],Table["Y"])
		elseif ReturningType == "UDim" then
			ReturningValue = UDim.new(Table["Scale"],Table["Offset"])
		elseif ReturningType == "UDim2" then
			ReturningValue = UDim2.new(Table["X"]["Scale"],Table["X"]["Offset"],Table["Y"]["Scale"],Table["Y"]["Offset"])
		elseif ReturningType == "NumberRange" then
			ReturningValue = NumberRange.new(Table["Min"],Table["Max"])
		elseif ReturningType == "Font" then
			local EnumType = "NONE"
			local EnumTest = pcall(function() 
				if typeof(Table["FontWeight"]) == "string" and typeof(Table["FontStyle"]) == "string" then
					if typeof(Enum.FontWeight[Table["FontWeight"]]) == "EnumItem" and typeof(Enum.FontStyle[Table["FontStyle"]]) == "EnumItem" then
						EnumType = "string"
					end
				--elseif Table["FontWeight"]["EnumType"] == Enum.FontWeight and Table["FontStyle"]["EnumType"] == Enum.FontStyle then --Shouldn't happen since this is a data friendly table. 12/14/22
					--EnumType = "Enum"
				end
			end)
			if EnumType == "string" then
				ReturningValue = Font.new(Table["FontFamily"], Enum.FontWeight[Table["FontWeight"]], Enum.FontStyle[Table["FontStyle"]])
			--elseif EnumType == "Enum" then
				--ReturningValue = Font.new(Table["FontFamily"], Table["FontWeight"], Table["FontStyle"])
			end
		elseif ReturningType == "NumberSequence" then
			local SequencePoints = {}
			for i = 1, GetDictionaryLength(Table) do
				if Table[tostring(i)]["Time"] and Table[tostring(i)]["Value"] and Table[tostring(i)]["Envelope"] then
					table.insert(SequencePoints, NumberSequenceKeypoint.new(Table[tostring(i)]["Time"], Table[tostring(i)]["Value"], Table[tostring(i)]["Envelope"]))
				end
			end
			ReturningValue = NumberSequence.new(SequencePoints)
		elseif ReturningType == "ColorSequence" then
			local SequencePoints = {}
			for i = 1, GetDictionaryLength(Table) do
				if Table[tostring(i)]["Time"] and Table[tostring(i)]["R"] and Table[tostring(i)]["G"] and Table[tostring(i)]["B"] then
					table.insert(SequencePoints, ColorSequenceKeypoint.new(Table[tostring(i)]["Time"], Color3.new(Table[tostring(i)]["R"], Table[tostring(i)]["G"], Table[tostring(i)]["B"]) ))
				end
			end
			ReturningValue = ColorSequence.new(SequencePoints)
		elseif ReturningType == "PhysicalProperties" then
			ReturningValue = PhysicalProperties.new(Table["Density"],Table["Friction"],Table["Elasticity"],Table["FrictionWeight"],Table["ElasticityWeight"])
		elseif ReturningType == "Rect" then
			ReturningValue = Rect.new(Vector2.new(Table["Min"]["X"],Table["Min"]["Y"]), Vector2.new(Table["Max"]["X"],Table["Max"]["Y"]))
		elseif ReturningType == "Axes" then
			local XVal = Table["X"]
			local YVal = Table["Y"]
			local ZVal = Table["Z"]
			local Success = pcall(function() --Wrapping this in a pcall in case it doesnt work since its possible Im supplying "true" variables to the .new function.
				ReturningValue = Axes.new(not XVal or Enum.NormalId.Left, not YVal or Enum.NormalId.Top, not ZVal or Enum.NormalId.Front)
			end)
		elseif ReturningType == "Faces" then
			local FrontVal = Table["Front"]
			local BackVal = Table["Back"]
			local RightVal = Table["Right"]
			local LeftVal = Table["Left"]
			local TopVal = Table["Top"]
			local BottomVal = Table["Bottom"]
			local Success = pcall(function() --Wrapping this in a pcall in case it doesnt work since its possible Im supplying "true" variables to the .new function.
				ReturningValue = Faces.new(not FrontVal or Enum.NormalId.Front, not BackVal or Enum.NormalId.Back, not RightVal or Enum.NormalId.Right, not LeftVal or Enum.NormalId.Left, not TopVal or Enum.NormalId.Top, not BottomVal or Enum.NormalId.Bottom)
			end)
		elseif ReturningType == "Ray" then
			ReturningValue = Ray.new(Vector3.new(Table["Origin"]["X"],Table["Origin"]["Y"],Table["Origin"]["Z"]) , Vector3.new(Table["Direction"]["X"],Table["Direction"]["Y"],Table["Direction"]["Z"]))
		end
	end)
	--if ReturningValue == nil then print(ReturningType) warn(err) end --DEBUG
	return ReturningValue
end

function CheckIfTableIsProprietaryTagFormat(TableReference)
	if typeof(TableReference) ~= "table" then return false end
	local Count = 0
	pcall(function() Count = #TableReference end)
	if Count == nil then return false end
	if Count <= 0 then return false end
	local KeyValueFound = false
	for i,v in pairs(TableReference) do
		if typeof(i) ~= "number" then
			KeyValueFound = true
			break
		end
	end
	return not KeyValueFound
end

function CheckIfTableIsProprietaryFormat(TableReference)
	if typeof(TableReference) ~= "table" then return nil end
	local TableSize = GetDictionaryLength(TableReference)
	
	local function CheckIfTableIsSequence(TableToCheck)
		if typeof(TableToCheck) ~= "table" then return false end
		if GetDictionaryLength(TableToCheck) < 1 then return false end
		local AllPointsHaveTime = true
		local SequenceType = ""
		for i,v in pairs (TableToCheck) do
			if typeof(v) == "table" then
				if not v["Time"] then
					AllPointsHaveTime = false
				else
					if v["Value"] then
						SequenceType = "NumberSequence"
					elseif v["R"] then
						SequenceType = "ColorSequence"
					else
						AllPointsHaveTime = false
					end
				end
			else
				AllPointsHaveTime = false
			end
		end
		if AllPointsHaveTime == false then return false end
		--print('found sequence: ' ..tostring(SequenceType)) --debug
		return SequenceType
	end
	local IsASequence = CheckIfTableIsSequence(TableReference)
	if not IsASequence then
		if TableSize == 1 then
			if typeof(TableReference["BrickColor"]) == "string" then
				return "BrickColor"
			else
				return false
			end
		elseif TableSize == 2 then
			if typeof(TableReference["X"]) == "table" and typeof(TableReference["Y"]) == "table" then
				return "UDim2"
			elseif typeof(TableReference["X"]) == "number" and typeof(TableReference["Y"]) == "number" then
				return "Vector2"
			elseif typeof(TableReference["Min"]) == "table" and typeof(TableReference["Max"]) == "table" then
				return "Rect"
			elseif typeof(TableReference["Min"]) == "number" and typeof(TableReference["Max"]) == "number" then
				return "NumberRange"
			elseif typeof(TableReference["Scale"]) == "number" and typeof(TableReference["Offset"]) == "number" then
				return "UDim"
			elseif typeof(TableReference["Name"]) == "string" and typeof(TableReference["EnumType"]) == "string" then
				return "EnumItem"
			elseif typeof(TableReference["Origin"]) == "table" and typeof(TableReference["Direction"]) == "table" then
				if TableReference["Origin"]["X"] and TableReference["Origin"]["Y"] and TableReference["Origin"]["Z"] and TableReference["Direction"]["X"] and TableReference["Direction"]["Y"] and TableReference["Direction"]["Z"]then
					return "Ray"
				else 
					return false
				end
			else
				return false
			end
		elseif TableSize == 3 then
			if typeof(TableReference["X"]) == "number" and typeof(TableReference["Y"]) == "number" and typeof(TableReference["Z"]) == "number" then
				return "Vector3"
			elseif typeof(TableReference["X"]) == "boolean" and typeof(TableReference["Y"]) == "boolean" and typeof(TableReference["Z"]) == "boolean" then
				return "Axes"
			elseif typeof(TableReference["FontFamily"]) == "string" and typeof(TableReference["FontWeight"]) == "string" and typeof(TableReference["FontStyle"]) == "string" then
				return "Font"
			--elseif typeof(TableReference["FontFamily"]) == "string" and typeof(TableReference["FontWeight"]) == "EnumItem" and typeof(TableReference["FontStyle"]) == "EnumItem" then
				--return "Font"
			else
				return false
			end
		elseif TableSize == 4 then
			if typeof(TableReference["R"]) == "number" and typeof(TableReference["G"]) == "number" and typeof(TableReference["B"]) == "number" and typeof(TableReference["Scale"]) == "number" then
				return "Color3"
			else
				return false
			end
		elseif TableSize == 5 then
			if typeof(TableReference["Density"]) == "number" and typeof(TableReference["Friction"]) == "number" and typeof(TableReference["Elasticity"]) == "number" and typeof(TableReference["FrictionWeight"]) == "number" and typeof(TableReference["ElasticityWeight"]) == "number" then
				return "PhysicalProperties"
			else
				return false
			end
		elseif TableSize == 6 then
			if typeof(TableReference["Top"]) == "boolean" and typeof(TableReference["Bottom"]) == "boolean" and typeof(TableReference["Left"]) == "boolean" and typeof(TableReference["Right"]) == "boolean" and typeof(TableReference["Front"]) == "boolean" and typeof(TableReference["Back"]) == "boolean" then
				return "Faces"
			else
				return false
			end
		elseif TableSize == 12 then
			if typeof(TableReference["X"]) == "number" and typeof(TableReference["Y"]) == "number" and typeof(TableReference["Z"]) == "number" and typeof(TableReference["R00"]) == "number" and typeof(TableReference["R01"]) == "number" and typeof(TableReference["R02"]) == "number" and typeof(TableReference["R10"]) == "number" and typeof(TableReference["R11"]) == "number" and typeof(TableReference["R12"]) == "number" and typeof(TableReference["R20"]) == "number" and typeof(TableReference["R21"]) == "number" and typeof(TableReference["R22"]) == "number" then
				return "CFrame"
			else
				return false
			end
		else
			return false
		end
	else
		return IsASequence
	end
end

function SmoothAllSurfaces(BasePartObject)
	if typeof(BasePartObject) ~= "Instance" then return end
	if not BasePartObject:IsA("BasePart") then return end
	BasePartObject.TopSurface = Enum.SurfaceType.SmoothNoOutlines
	BasePartObject.BottomSurface = Enum.SurfaceType.SmoothNoOutlines
	BasePartObject.LeftSurface = Enum.SurfaceType.SmoothNoOutlines
	BasePartObject.RightSurface = Enum.SurfaceType.SmoothNoOutlines
	BasePartObject.FrontSurface = Enum.SurfaceType.SmoothNoOutlines
	BasePartObject.BackSurface = Enum.SurfaceType.SmoothNoOutlines
end

function DoForEveryInstanceTable(InstanceObject, TableReference, PropertyReference, CurrentSettings, ObjectTable, TableName)
	if typeof(TableReference) ~= "table" then return end
	if typeof(PropertyReference) ~= "table" then return end
	if not InstanceObject then return end
	local ClassType = InstanceObject.ClassName
	local IgnoredClassProperties = CurrentSettings.SpecificExcludedProperties[ClassType]
	if typeof(IgnoredClassProperties) ~= "table" then IgnoredClassProperties = {} end
	if CurrentSettings.IncludeProperties == false then IgnoredClassProperties = {} CurrentSettings.ExcludedProperties = {} end
	
	for i,v in pairs (TableReference) do
		local CurrentPropertyList = PropertyReference[ClassType]
		if typeof(CurrentPropertyList) == "table" then
			if table.find(CurrentPropertyList, i) then
				local CurrentProperty = nil
				local success, fail = pcall(function()
					CurrentProperty = InstanceObject[i]
				end)
				if success then
					local PropertyType = typeof(CurrentProperty)
					if (typeof(v) == PropertyType or typeof(v) == "PhysicalProperties") and not TableReference.EnumType then --Here last
						if CurrentSettings.IncludeProperties == true then
							local success, fail = pcall(function()
								if not table.find(IgnoredClassProperties, i) and not table.find(CurrentSettings.ExcludedProperties, i)  then
									InstanceObject[i] = v
								end
							end)
							if not success then
								if not string.find(tostring(fail), "read only") and not string.find(tostring(fail), "write access") then
									warn("Error setting a property. " ..fail)
								end
							end
						end
					elseif typeof(v) == "table" then
						if CheckIfTableIsProprietaryFormat(v) ~= false then --ProprietaryChange According to type
							local FormattedProperty = FormatValue(v, CheckIfTableIsProprietaryFormat(v))
							if typeof(FormattedProperty) == PropertyType or typeof(FormattedProperty) == "PhysicalProperties" then
								if CurrentSettings.IncludeProperties == true then
									local success, fail = pcall(function()
										if not table.find(IgnoredClassProperties, i) and not table.find(CurrentSettings.ExcludedProperties, i)  then
											InstanceObject[i] = FormattedProperty
										end
									end)
									if not success then
										if not string.find(tostring(fail), "read only") and not string.find(tostring(fail), "write access") then
											warn("Error setting a property. " ..fail)
										end
									end
								end
							end
						end
					elseif (typeof(InstanceObject[i]) == "nil" or typeof(InstanceObject[i]) == "Instance") and typeof(v) == "string" then --ObjectString
						if v:sub(1,4) == "game" or v:sub(1,4) == "self" then --Make sure format matches.
							if not table.find(IgnoredClassProperties, i) and not table.find(CurrentSettings.ExcludedProperties, i) and CurrentSettings.IncludeProperties == true then
								table.insert(ObjectTable, {InstanceObject, i, v})
							end
						else
							local success, fail = pcall(function()
								if CurrentSettings.IncludeAttributes == true then
									InstanceObject:SetAttribute(tostring(i), v) --fallback
								end
							end)
							if not success and not string.find(string.lower(tostring(fail)), "instance is not a supported attribute type") then
								warn("Error setting an attribute. " ..fail)
							end
						end
					elseif typeof(InstanceObject[i]) == "EnumItem" and  typeof(v) == "string" then
						--attempt to set enum using string
						if not table.find(IgnoredClassProperties, i) and not table.find(CurrentSettings.ExcludedProperties, i) and CurrentSettings.IncludeProperties == true then
							local EnumType = tostring(InstanceObject[i].EnumType)
							local success, fail = pcall(function()
								InstanceObject[i] = Enum[EnumType][v]
							end)
							if not success then
								if not string.find(tostring(fail), "read only") and not string.find(tostring(fail), "write access") then
									warn("Error setting an Enum property. " ..fail)
								end
							end
						end
					elseif typeof(InstanceObject[i]) == "EnumItem" and  typeof(v) == "number" then
						--attempt to set enum using number
						if not table.find(IgnoredClassProperties, i) and not table.find(CurrentSettings.ExcludedProperties, i) and CurrentSettings.IncludeProperties == true then
							local EnumType = tostring(InstanceObject[i].EnumType)
							local success, fail = pcall(function()
								InstanceObject[i] = v
							end)
							if not success then
								if not string.find(tostring(fail), "read only") and not string.find(tostring(fail), "write access") then
									warn("Error setting an Enum property. " ..fail)
								end
							end
						end
					elseif typeof(InstanceObject[i]) == "BrickColor" and  typeof(v) == "string" then
						--attempt to set brickcolor using string
						if not table.find(IgnoredClassProperties, i) and not table.find(CurrentSettings.ExcludedProperties, i) and CurrentSettings.IncludeProperties == true then
							local success, fail = pcall(function()
								InstanceObject[i] = BrickColor.new(v)
							end)
							if not success then
								if not string.find(tostring(fail), "read only") and not string.find(tostring(fail), "write access") then
									warn("Error setting an BrickColor property. " ..fail)
								end
							end
						end
					else
						local success, fail = pcall(function()
							if v ~= nil and CurrentSettings.IncludeAttributes == true then
								InstanceObject:SetAttribute(tostring(i), v)
							end
						end)
						if not success and not string.find(string.lower(tostring(fail)), "instance is not a supported attribute type") then
							local FormattedValueTable = {}
							local CurrentSettingsClone = DeepCopy(CurrentSettings)
							CurrentSettings.DataStoreFriendly = true
							SafelyAddToTable(FormattedValueTable, "NewTemporaryMainValue", v, CurrentSettingsClone)
							if typeof(FormattedValueTable.NewTemporaryMainValue) == "table" then
								local NewObject = nil
								local InstanceTestPassed = pcall(function()
									NewObject = Instance.new(CurrentSettings.DefaultInstanceType)
								end)
								if not NewObject or not InstanceTestPassed then
									NewObject = Instance.new("Folder")
								end
								NewObject.Name = tostring(i)
								NewObject.Parent = InstanceObject
								DoForEveryInstanceTable(NewObject, FormattedValueTable.NewTemporaryMainValue, PropertyReference, CurrentSettings, ObjectTable, tostring(i))
							end
							if CurrentSettings.PrintCompatibilityErrors == true then
								warn("Error setting an attribute. " ..fail.. " Created an object (DefaultInstanceType) with its attributes set to the original attempt's data.") 
							end
						end
					end
				else
					--print(i) --Debug
				end
			else
				if typeof(v) == "table" then
					if v["ClassName"] and i ~= "[TAGS]" then
						local NewObject = nil
						local InstanceTestPassed = pcall(function()
							if v["ClassName"] == "MeshPart" and CurrentSettings.IncludeProperties == true then
								if v["MeshId"] and typeof(CurrentSettings.ReferenceMeshes[v["MeshId"]]) == "Instance" then
									local Success, Fail = pcall(function()
										NewObject = CurrentSettings.ReferenceMeshes[v["MeshId"]]:clone()
										if PropertyReference["MeshPart"] then --Here 11/11/22.
											if not InstanceNewRefMeshPart then InstanceNewRefMeshPart = Instance.new("MeshPart") end
											for _,miniv in pairs(PropertyReference["MeshPart"]) do
												if miniv ~= "MeshId" and typeof(miniv) == "string" then
													local PropertySuccess, PropertyFail = pcall(function()
														if InstanceNewRefMeshPart[miniv] ~= nil and NewObject[miniv] ~= InstanceNewRefMeshPart[miniv] then
															NewObject[miniv] = InstanceNewRefMeshPart[miniv]
														elseif InstanceNewRefMeshPart[miniv] == nil and NewObject[miniv] ~= nil then
															NewObject[miniv] = nil
														end
													end)
												end
											end
										end
									end)
									if not Success then
										if typeof(CurrentSettings["ErrorTable"]) ~= "table" then CurrentSettings["ErrorTable"] = {} end
										local ErrString = 'Converter Module: Instance ↔ Table ran into an error cloning one or more MeshParts.'
										if not table.find(CurrentSettings["ErrorTable"], ErrString) then
											table.insert(CurrentSettings["ErrorTable"], ErrString)
										end
										if CurrentSettings.IncludeProperties == true then
											NewObject = Instance.new(v["ClassName"])
										else
											NewObject = Instance.new(CurrentSettings.DefaultInstanceType)
										end
									end
								elseif CurrentSettings.AutoConvertMeshParts == true then
									NewObject = Instance.new("Part")
									local SpecialMesh = Instance.new("SpecialMesh", NewObject)
									SpecialMesh.Name = "Mesh"
								else
									NewObject = Instance.new(v["ClassName"])
								end
							else
								if CurrentSettings.IncludeProperties == true then
									if v["ClassName"] == "SurfaceAppearance" and CanEditSurfaceAppearances == false then --11/16/22
										NewObject = Instance.new(CurrentSettings.DefaultInstanceType)
									else
										NewObject = Instance.new(v["ClassName"])
									end
								else
									NewObject = Instance.new(CurrentSettings.DefaultInstanceType)
								end
							end
						end)
						if not InstanceTestPassed then
							NewObject = Instance.new("Folder")
						end
						if NewObject then
							local AttemptedInsert, FailedInsert = pcall(function() NewObject.Parent = InstanceObject end) --Added 12/9/22
							if not AttemptedInsert then
								warn(FailedInsert)
							end
							if typeof(v["Name"]) == "string" then
								NewObject.Name = v["Name"]
							else
								NewObject.Name = tostring(i)
							end
							if NewObject:IsA("BasePart") then
								if CurrentSettings.AutoSmoothParts == true then
									SmoothAllSurfaces(NewObject)
								end
							end
							if CurrentSettings.IncludeProperties == false then
								for subi, subv in pairs(v) do
									if typeof(PropertyReference[v["ClassName"]]) == "table" then
										if table.find(PropertyReference[v["ClassName"]], subi) then
											if subi ~= "ClassName"  then
												v[subi] = nil
											end
										end
									end
								end
							end
							DoForEveryInstanceTable(NewObject, v, PropertyReference, CurrentSettings, ObjectTable, tostring(i))
						end
					elseif i == "[TAGS]" then --12/4/22
						if CurrentSettings.IncludeTags == true then 
							if CheckIfTableIsProprietaryTagFormat(v) then
								for _, ObjectTag in pairs(v) do
									if typeof(CurrentSettings.ExcludedTags) ~= "table" then --I shouldn't need this because of the prechecks, but just in case... (I don't feel like rereading/tracking down the settings precheck.)
										CurrentSettings.ExcludedTags = {}
									end
									if not table.find(CurrentSettings.ExcludedTags, ObjectTag) then
										CollectionService:AddTag(InstanceObject,ObjectTag)
									end
								end
							end
						end
					else 
						local FormattedValue = v
						local success, fail = pcall(function()
							if  (not table.find(IgnoredClassProperties, i) and not table.find(CurrentSettings.ExcludedProperties, i) and not table.find(DefaultExcludedProperties, i)) --[[ and CurrentSettings.IncludeAttributes == true ]]then
								if typeof(v) == "table" then
									FormattedValue = FormatValue(v, CheckIfTableIsProprietaryFormat(v))
									--print(FormattedValue)--debug
								end
							end
						end)
						if FormattedValue ~= v and FormattedValue ~= nil then --if its proprietary
							local Attributesuccess, Attributefail = pcall(function()
								if CurrentSettings.IncludeAttributes == true then
									InstanceObject:SetAttribute(tostring(i), FormattedValue)
								end
							end)
							if not Attributesuccess and not(i == "RenderFidelity" or i == "CollisionFidelity") then --last here
								if --[[CurrentSettings.IncludeProperties == false]] true then --why did i have IncludeProperties == false here??? ....... aaaaaaaaa I dont remember!!
									local NewInstanceType = CurrentSettings.DefaultInstanceType
									local NewObject = nil
									local InstanceTestPassed = pcall(function()
										NewObject = Instance.new(tostring(NewInstanceType))
									end)
									if not InstanceTestPassed then
										CurrentSettings.DefaultInstanceType = "Folder"
										NewObject = Instance.new("Folder")
									end
									if NewObject then
										NewObject.Parent = InstanceObject
										NewObject.Name = tostring(i)
									end
									for subi, subv in pairs(v) do
										if typeof(subv) == "table" then
											DoForEveryInstanceTable(NewObject, subv, PropertyReference, CurrentSettings, ObjectTable, tostring(subi))
										else
											local subAttributesuccess,subAttributefail = pcall(function()
												if CurrentSettings.IncludeAttributes == true then
													NewObject:SetAttribute(tostring(subi), subv)
												end
											end)
											if not subAttributesuccess then
												warn("Error setting an attribute. " ..subAttributefail)
											end
										end
									end
								else
									--print(i,v) --Debug
									warn("Error setting an attribute. " ..Attributefail)
								end
							end
						else
							local NewInstanceType = CurrentSettings.DefaultInstanceType
							local NewObject = nil
							local InstanceTestPassed = pcall(function()
								NewObject = Instance.new(tostring(NewInstanceType))
							end)
							if not InstanceTestPassed then
								CurrentSettings.DefaultInstanceType = "Folder"
								NewObject = Instance.new("Folder")
							end
							if NewObject then
								NewObject.Parent = InstanceObject
								if typeof(v["Name"]) == "string" then
									NewObject.Name = v["Name"]
								else
									NewObject.Name = tostring(i)
								end
								if NewObject:IsA("BasePart") then
									if CurrentSettings.AutoSmoothParts == true then
										SmoothAllSurfaces(NewObject)
									end
								end
								DoForEveryInstanceTable(NewObject, v, PropertyReference, CurrentSettings, ObjectTable, tostring(i))
							end
						end
						if not success and not string.find(string.lower(tostring(fail)), "instance is not a supported attribute type") then
							warn("Error setting an attribute. " ..fail)
						end
					end
				elseif typeof(v) == "string" and InstanceObject:FindFirstChild("Mesh") and CurrentSettings.AutoConvertMeshParts == true  and (i == "MeshId" or i == "TextureID") then
					if i == "MeshId" then 
						InstanceObject:FindFirstChild("Mesh").MeshId = v
					elseif i == "TextureID" then
						InstanceObject:FindFirstChild("Mesh").TextureId = v
					end
				else
					local success, fail = pcall(function()
						if (not table.find(IgnoredClassProperties, i) and not table.find(CurrentSettings.ExcludedProperties, i) and not table.find(DefaultExcludedProperties, i)) --[[ and CurrentSettings.IncludeAttributes == true ]] then
							if v ~= nil and CurrentSettings.IncludeAttributes == true then
								InstanceObject:SetAttribute(tostring(i), v)
							end
						end
					end)
					if not success and not string.find(string.lower(tostring(fail)), "instance is not a supported attribute type") then
						local FormattedValueTable = {}
						local CurrentSettingsClone = DeepCopy(CurrentSettings)
						CurrentSettings.DataStoreFriendly = true
						SafelyAddToTable(FormattedValueTable, "NewTemporaryMainValue", v, CurrentSettingsClone)
						if typeof(FormattedValueTable.NewTemporaryMainValue) == "table" then
							local NewObject = nil
							local InstanceTestPassed = pcall(function()
								NewObject = Instance.new(CurrentSettings.DefaultInstanceType)
							end)
							if not NewObject or not InstanceTestPassed then
								NewObject = Instance.new("Folder")
							end
							NewObject.Name = tostring(i)
							NewObject.Parent = InstanceObject
							DoForEveryInstanceTable(NewObject, FormattedValueTable.NewTemporaryMainValue, PropertyReference, CurrentSettings, ObjectTable, tostring(i))
							if CurrentSettings.PrintCompatibilityErrors == true then
								warn("Error setting an attribute. " ..fail.. ". Created a "..tostring(NewObject["ClassName"]).. ' object inside "'..tostring(InstanceObject["Name"])..'" with formatted attributes.')
							end
						end
					elseif not success and string.find(string.lower(tostring(fail)), "instance is not a supported attribute type") then
						local InstanceInString = ConvertObjectToString(InstanceObject,v,InstanceObject)
						if typeof(InstanceInString) == "string" then
							InstanceObject:SetAttribute(tostring(i), InstanceInString)
						end
					end
				end
			end
		else
			warn("Error fetching properties for the Class: " ..ClassType)
		end
	end
	if InstanceObject.Name == InstanceObject.ClassName then
		if typeof(TableName) == "string" then
			InstanceObject.Name = TableName
		end
	end
end

function DecodeLocation(LocationString, SelfObject, CurrentSettings)
	if typeof(LocationString) ~= "string" or typeof(SelfObject) ~= "Instance" then return "" end
	local StartingPosition = SelfObject
	local DefaultStartingPlace = 2
	if string.find(LocationString, 'game.') and LocationString:split(".")[1] == "game" then
		local Success,Fail = pcall(function()
			StartingPosition = game:GetService(LocationString:split(".")[2])
		end)
		DefaultStartingPlace = 3
	end
	local LocationFound = StartingPosition
	for i = DefaultStartingPlace, #LocationString:split(".") do
		local PreviousPar = LocationFound
		local PreviousParName = LocationFound.Name
		if LocationString:split(".")[i] == "Parent" then
			local success, fail = pcall(function()
				LocationFound = LocationFound.Parent
			end)
			if not success then LocationFound = nil end
		else
			local success, fail = pcall(function()
				LocationFound = LocationFound:FindFirstChild(LocationString:split(".")[i])
			end)
			if not success then LocationFound = nil end
		end
		if not LocationFound then
			if CurrentSettings.PrintObjectVariableErrors == true and PreviousPar then
				if typeof(CurrentSettings["VariableErrorTable"]) ~= "table" then CurrentSettings["VariableErrorTable"] = {} end
				if typeof(CurrentSettings["ErroredVariables"]) ~= "table" then CurrentSettings["ErroredVariables"] = {} end
				local ErrString = ('While attempting to set an object property, the converter could not find an instance called "' ..LocationString:split(".")[i].. '" inside of "' ..tostring(PreviousParName).. '". Since the object locater uses FindFirstChild(), make sure "' ..tostring(PreviousParName).. '" is a unique name.' )
				if not table.find(CurrentSettings["VariableErrorTable"], ErrString) then
					table.insert(CurrentSettings["VariableErrorTable"], ErrString)
				end
				if not table.find(CurrentSettings["ErroredVariables"], PreviousPar) then
					table.insert(CurrentSettings["ErroredVariables"], {PreviousPar, LocationString:split(".")[i]})
				end
			end
			break
		end
	end
	return LocationFound
end

function GatherMeshIDs(Table, InsertingTable)
	if typeof(Table) ~= "table" or typeof(InsertingTable) ~= "table" then return end
	if Table["ClassName"] == "MeshPart" then
		if typeof(Table["MeshId"]) == "string" then
			if not table.find(InsertingTable,Table["MeshId"]) then
				table.insert(InsertingTable,Table["MeshId"])
			end
		end
	end
	for i,v in pairs(Table) do
		if typeof(v) == "table" then
			GatherMeshIDs(v,InsertingTable)
		end
	end
end

local DefaultMeshPart = Instance.new("MeshPart")
function GatherMeshes(IDList, InsertingTable, FetchSurfaceAppearances)
	if typeof(IDList) ~= "table" or typeof(InsertingTable) ~= "table" then return end
	local GameDesc = game:GetDescendants()
	for i,v in pairs(IDList) do
		if typeof(v) == "string" and InsertingTable[v] == nil then
			local MeshFound = false
			local TempSurfaceHolder = Instance.new("Folder")
			for i,Desc in pairs (GameDesc) do
				if MeshFound == true and FetchSurfaceAppearances == false then break end
				local Success, Fail = pcall(function()
					if Desc:IsA("MeshPart") then
						if Desc.MeshId == v then
							if InsertingTable[v] == nil then
								local MeshClone = Desc:clone()
								MeshClone:ClearAllChildren()
								for Att, AttVal in pairs(MeshClone:GetAttributes()) do
									MeshClone:SetAttribute(Att, nil)
								end
								for _, Tag in pairs(CollectionService:GetTags(MeshClone)) do --12/4/22
									CollectionService:RemoveTag(MeshClone,Tag)
								end
								local MeshPartPropertyTable = AllPropertiesNoExclusions["MeshPart"]
								if typeof(MeshPartPropertyTable) == "table" then
									for _,MeshProp in pairs(MeshPartPropertyTable) do
										if MeshProp ~= "MeshId" then
											local SuccessMesh, FailMesh = pcall(function()
												if DefaultMeshPart[MeshProp] ~= MeshClone[MeshProp] then
													MeshClone[MeshProp] = DefaultMeshPart[MeshProp]
												end
											end)
										end
									end
								end
								InsertingTable[v] = MeshClone
								MeshFound = true
							end
							if FetchSurfaceAppearances == true then
								for _, SubDesc in pairs(Desc:GetDescendants()) do
									if SubDesc:IsA("SurfaceAppearance") then
										local SurfaceIsDifferent = true
										local CanReadSurfaceAppearances = pcall(function() local TestVar = SurfaceAppearanceTest.ColorMap end)
										if CanReadSurfaceAppearances == true then
											local SurfaceSuccess, SurfaceFail = pcall(function()
												for _,SurfaceAppearance in pairs(TempSurfaceHolder:GetChildren()) do
													if SurfaceAppearance.AlphaMode == SubDesc.AlphaMode and SurfaceAppearance.ColorMap == SubDesc.ColorMap and SurfaceAppearance.MetalnessMap == SubDesc.MetalnessMap and SurfaceAppearance.NormalMap == SubDesc.NormalMap and SurfaceAppearance.RoughnessMap == SubDesc.RoughnessMap then
														SurfaceIsDifferent = false
														break
													end
												end
											end)
										end
										if SurfaceIsDifferent == true then
											if CanReadSurfaceAppearances == true then
												SubDesc:clone().Parent = TempSurfaceHolder
											end
										end
									end
								end
							end
						end
					end
				end)
			end
			if typeof(InsertingTable[v]) == "Instance" then
				for _,SurfaceAppearance in pairs(TempSurfaceHolder:GetChildren()) do
					SurfaceAppearance:ClearAllChildren()
					SurfaceAppearance.Parent = InsertingTable[v]
				end
			end
			TempSurfaceHolder:Destroy()
		end
	end
end

function module:ConvertToInstance(Table, ConversionSettings)
	if game:GetService("RunService"):IsRunning() == true and shared.___.___.temp:FindFirstChild(Table.Name) then
		shared.___.___.temp:FindFirstChild(Table.Name):Destroy()
	end
	CanEditSurfaceAppearances = pcall(function() SurfaceAppearanceTest.ColorMap = "" end)
	local RunService = game:GetService("RunService") local IsEdit = false  local RunStatusTest = pcall(function() IsEdit = RunService:IsEdit() end) if (RunService:IsClient() and (not RunService:IsStudio() or not IsEdit) ) then if SecuritySettings.ModuleCanRunFromTheClient == false then script:Destroy() error("CONVERTER IS NOT ALLOWED TO BE CALLED FROM THE CLIENT.") end end
	if typeof(Table) ~= "table" then if not IsEdit then warn("Supplied table is nil or not a dictionary.") end return nil end
	if typeof(ConversionSettings) ~= "table" and typeof(ConversionSettings) ~= "nil" then warn("Recieved ConversionSettings as a ".. string.upper(tostring(typeof(ConversionSettings))).. " format. ConversionSettings need to be in a dictionary format. ")  return nil end
	local CurrentSettings = FetchSettings(ConversionSettings)
	CurrentSettings.StartTime = tonumber(TimeFunction())
	
	if CurrentSettings.IncludeProperties == true then
		if HttpEnabled == false and CurrentSettings.FetchLatestPropertiesOnline == true and IsEdit == false then RecheckIfHTTPEnabled() end
		if HttpEnabled == false and CurrentSettings.FetchLatestPropertiesOnline == true then if CurrentSettings.ShowHTTPWarning == true then warn("In order for Converter Module: Instance ↔ Table to fetch the latest properties from the API, HTTP service needs to be enabled.") end end
		if HttpEnabled == false then CurrentSettings.FetchLatestPropertiesOnline = false end
	end
	
	local PropertyReference = nil
	local PreviousPropertyReference = FetchPreviousProperties({})
	if not AllPropertiesNoExclusions then
		AllPropertiesNoExclusions = module:FetchProperties(CurrentSettings.FetchLatestPropertiesOnline,{}, false, true)
	end
	if not PreviousPropertyReference then
		PropertyReference = module:FetchProperties(CurrentSettings.FetchLatestPropertiesOnline, {}, CurrentSettings.ShowHTTPWarning, true)
		InsertPreviousProperties({}, PropertyReference, false)
	else
		PropertyReference = PreviousPropertyReference
	end
	local MainInstance = nil
	local FirstClassType = nil
	local TableClone = DeepCopy(Table)
	if typeof(CurrentSettings["CleanupTables"]) ~= "table" then CurrentSettings["CleanupTables"] = {} end
	if typeof(CurrentSettings["MeshIDs"]) ~= "table" then CurrentSettings["MeshIDs"] = {} end
	if typeof(CurrentSettings["ReferenceMeshes"]) ~= "table" then CurrentSettings["ReferenceMeshes"] = CarryoverMeshes or {} end
	table.insert(CurrentSettings.CleanupTables, TableClone)
	if CurrentSettings.IncludeProperties == true then
		FirstClassType = Table['ClassName']
	elseif CurrentSettings.IncludeProperties == false then
		FirstClassType = CurrentSettings.DefaultInstanceType
	end
	GatherMeshIDs(TableClone, CurrentSettings["MeshIDs"])
	GatherMeshes(CurrentSettings["MeshIDs"], CurrentSettings["ReferenceMeshes"], CurrentSettings["CarryOverSurfaceAppearances"])
	CarryoverMeshes = DeepCopy(CurrentSettings["ReferenceMeshes"])
	if FirstClassType == nil then FirstClassType = CurrentSettings.DefaultInstanceType end
	local InstanceTestPassed = pcall(function()
		if FirstClassType == "MeshPart" then
			if Table["MeshId"] and typeof(CurrentSettings.ReferenceMeshes[Table["MeshId"]]) == "Instance" then
				local Success, Fail = pcall(function()
					MainInstance = CurrentSettings.ReferenceMeshes[Table["MeshId"]]:clone()
					if PropertyReference["MeshPart"] then
						if not InstanceNewRefMeshPart then InstanceNewRefMeshPart = Instance.new("MeshPart") end
						for _,miniv in pairs(PropertyReference["MeshPart"]) do
							if miniv ~= "MeshId" and typeof(miniv) == "string" then
								local PropertySuccess, PropertyFail = pcall(function()
									if InstanceNewRefMeshPart[miniv] ~= nil and MainInstance[miniv] ~= InstanceNewRefMeshPart[miniv] then
										MainInstance[miniv] = InstanceNewRefMeshPart[miniv]
									elseif InstanceNewRefMeshPart[miniv] == nil and MainInstance[miniv] ~= nil then
										MainInstance[miniv] = nil
									end
								end)
							end
						end
					end
				end)
			elseif CurrentSettings.AutoConvertMeshParts == true then
				MainInstance = Instance.new("Part")
				local SpecialMesh = Instance.new("SpecialMesh", MainInstance)
				SpecialMesh.Name = "Mesh"
			else
				MainInstance = Instance.new(FirstClassType)
			end
		else
			if table.find(ServiceList,FirstClassType) then
				if FirstClassType ~= "Terrain" then
					MainInstance = game:GetService(FirstClassType)
				else
					MainInstance = game:GetService("Workspace").Terrain
				end
			elseif FirstClassType == "SurfaceAppearacne" and CanEditSurfaceAppearances == false then
				MainInstance = Instance.new(CurrentSettings.DefaultInstanceType)
			else
				MainInstance = Instance.new(FirstClassType)
			end
		end
	end)
	if not MainInstance or InstanceTestPassed == false then MainInstance = Instance.new("Folder") CurrentSettings.DefaultInstanceType = "Folder" end
	local ObjectTable = {}
	if typeof(Table["Name"]) == "string" then
		MainInstance.Name = Table["Name"]
	end
	if MainInstance:IsA("BasePart") then
		if CurrentSettings.AutoSmoothParts == true then
			SmoothAllSurfaces(MainInstance)
		end
	end
	DoForEveryInstanceTable(MainInstance, TableClone, PropertyReference, CurrentSettings, ObjectTable)
	for _,v in pairs (ObjectTable) do
		if typeof(v) == "table" then
			if v[1] and v[2] and v[3] then
				local InstanceLocation = DecodeLocation(v[3], v[1], CurrentSettings)
				local success, fail = pcall(function()
					v[1][ tostring(v[2]) ] = InstanceLocation 
				end)
				if not success then
					if not string.find(tostring(fail), "read only") and not string.find(tostring(fail), "write access") then
						warn("Error setting a object property. " ..fail)
					end
				end
			end
		end
	end

	if typeof(CurrentSettings.CleanupTables) == "table" then
		if CurrentSettings.PrintCleanupAmount == true then
			print("Cleaned up " ..tostring(((math.floor(((string.len(tostring(game.HttpService:JSONEncode(CurrentSettings.CleanupTables))))/1000))/1000))).. " MB of conversion background memory.") --checking allocated memory size of the cloned table
		end
		for i,v in pairs (CurrentSettings.CleanupTables) do
			if v then
				if typeof(v) == "table" then
					local function ClearDeepestVal(SourceTable)
						if typeof(SourceTable) ~= "table" then return end
						for subi,subv in pairs(SourceTable) do
							if typeof(subv) == "table" then
								ClearDeepestVal(subv)
								if SourceTable then
									SourceTable[subi] = nil
								end
							else
								if SourceTable then
									SourceTable[subi] = nil
								end
							end
						end
					end
					ClearDeepestVal(v)
				end
			end
			CurrentSettings.CleanupTables[i] = nil
		end
	end

	if typeof(CurrentSettings.VariableErrorTable) == "table" and CurrentSettings.PrintObjectVariableErrors == true then
		for i,v in ipairs(CurrentSettings.VariableErrorTable) do
			warn(v)
		end
	end
	if typeof(CurrentSettings.ErroredVariables) == "table" and CurrentSettings.PrintObjectVariableErrors == true then
		if GetDictionaryLength(CurrentSettings.ErroredVariables) > 0 then
			warn("List of objects (clickable) and the object name that couldn't be found within them: ")
			warn(CurrentSettings.ErroredVariables)
		end
	end

	local RunningFrom = "server" local IsEdit = false  local RunStatusTest = pcall(function() IsEdit = RunService:IsEdit() end) if (RunService:IsClient() and (not RunService:IsStudio() or not IsEdit) ) then RunningFrom = "client" elseif RunService:IsStudio() then RunningFrom = "Roblox Studio handler" end
	if CurrentSettings.PrintCompletionTime == true and typeof(CurrentSettings.StartTime) == "number" and typeof(MainInstance) == "Instance" then
		local TimeTookToComplete = tonumber(TimeFunction()) - CurrentSettings.StartTime
		local CurrentTimeMeasurement = "seconds"
		local FormattedTime = ( math.round( (TimeTookToComplete*10) ) ) / 10
		if FormattedTime >= 60 then FormattedTime = (math.round( (FormattedTime / 60) * 100) ) / 100; if FormattedTime > 1 then CurrentTimeMeasurement = "minutes" else CurrentTimeMeasurement = "minute" end end
		local StringFormattedTime =  tostring( FormattedTime )
		print("It took the " ..RunningFrom.. " " ..StringFormattedTime.. " " ..CurrentTimeMeasurement.. ' to convert "' ..MainInstance.Name..'" into an object.')
	end

	if game:GetService("RunService"):IsRunning() == true then MainInstance.Parent = shared.___.___.temp end
	return MainInstance
end

return module