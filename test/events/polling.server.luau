const RunService = game:GetService("RunService")

const net_server = require("../net/net_server")

RunService.Heartbeat:Connect(function()
	for index, player, num, str in net_server.other.iter() do
		print(index, player, num, str)
	end
end)
