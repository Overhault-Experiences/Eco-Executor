local services = {
	RunService = game:GetService("RunService"),
	ReplicatedStorage = game:GetService("ReplicatedStorage"),
	ReplicatedFirst = game:GetService("ReplicatedFirst"),
	CoreGui = game:GetService("CoreGui"),
	StudioService = game:GetService("StudioService"),
	Selection = game:GetService("Selection"),
	TweenService = game:GetService("TweenService"),
	UserInputService = game:GetService("UserInputService"),
	StarterGui = game:GetService("StarterGui"),
	HttpService = game:GetService("HttpService"),
	InsertService = game:GetService("InsertService"),
	ScriptEditorService = game:GetService("ScriptEditorService"),
	Studio = settings().Studio,
	DataStoreService = if game:GetService("RunService"):IsServer() then game:GetService("DataStoreService") else nil,
	LocalizationService = game:GetService("LocalizationService"),
}

return services