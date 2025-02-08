local nilinstances = {}
game.DescendantRemoving:Connect(function(d)
	if typeof(d) == "Instance" and d.Name ~= "Proxy" and d.Name ~= "RobloxReplicatedStorage" then
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
repeat task.wait() until shared.___ ~= nil
local get = shared.___.___.memory:WaitForChild("eAPI",math.huge):WaitForChild"InstanceService";local IS = game:GetService("ReplicatedStorage"):WaitForChild("IS",math.huge)
get.OnInvoke = function(method, args, h_args)
	if method == "getnils" then
		return nilinstances
	elseif method == "save" then
		IS:InvokeServer("___1___", method,args)
	elseif method == "request" then
		return IS:InvokeServer("___1___", method,args)
	elseif method == "request_saves" then
		return IS:InvokeServer("___1___", method)
	elseif method == "reset_saves" then
		IS:InvokeServer("___1___", method)
	elseif method == "GetObject" then
		return IS:InvokeServer("___1___", method,args)
	elseif method == "HttpGet" then
		return IS:InvokeServer("___1___", method,args, h_args)
	elseif method == "save_script" then
		return IS:InvokeServer("___1___", method, args, h_args)
	end
end

return {}