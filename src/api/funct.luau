const RunService = game:GetService("RunService")

const net = require("../process/net")
const types = require("../types")

const side: "server" | "client" = RunService:IsServer() and "server" or "client"

type FunctProps<T..., R...> = types.FunctProps<T..., R...>
type Funct<T..., R...> = types.Funct<T..., R...>
type FunctServer<T..., R...> = types.FunctServer<T..., R...>
type FunctClient<T..., R...> = types.FunctClient<T..., R...>
type DefOptions = types.DefOptions

const function funct<T..., R...>(props: FunctProps<T..., R...>): Funct<T..., R...>
	local object: FunctServer<T..., R...> & FunctClient<T..., R...>

	const function funct_server(
		options: DefOptions,
		id: number,
		lifecycle: net.LifecycleServer
	): FunctServer<T..., R...>
		if object then
			return object
		end
		if side ~= "server" then
			error("[BufNet] Function server can only be accessed from the server.")
		end

		const casing = options.casing or types.default_case
		const reader = lifecycle.register_function(id, props.value, props.returns)

		const method_names = types.get_casing(casing :: types.DefaultCase)

		const server_object = {
			[method_names["on"]] = function(callback: (Player, T...) -> R...)
				reader.listeners[1] = callback :: any
				for _, args in reader.queue :: any do
					lifecycle.dispatch(id, true, table.unpack(args) :: any)
				end
				reader.queue = {} :: any
			end,
		} :: any

		object = server_object
		return object
	end

	const function funct_client(
		options: DefOptions,
		id: number,
		lifecycle: net.LifecycleClient
	): FunctClient<T..., R...>
		if object then
			return object
		end
		if side ~= "client" then
			error("[BufNet] Function client can only be accessed from the client.")
		end

		const casing = options.casing or "Snake"
		const invoke = lifecycle.register_function(id, props.value, props.returns)

		const method_names = types.get_casing(casing :: types.DefaultCase)

		const client_object = {
			[method_names["invoke"]] = invoke,
		} :: any

		object = client_object
		return object
	end

	return {
		type = "function",
		reliable = true,
		server = funct_server,
		client = funct_client,
	} :: any
end

return funct
