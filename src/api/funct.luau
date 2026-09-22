--!native
--!optimize 2

const RunService = game:GetService("RunService")

const constants = require("../constants")
const casing = require("../core/casing")
const lifecycle = require("../core/lifecycle")
const types = require("../types")

type FunctProps = types.FunctProps
type Funct<Props> = types.Funct<Props>
type FunctServer<Props> = types.FunctServer<Props>
type FunctClient<Props> = types.FunctClient<Props>
type DefOptions = types.DefOptions

const IS_SERVER = RunService:IsServer()
const ROOT_SCOPE_NAME = constants.ROOT_SCOPE_NAME

const function funct<Props>(props: Props & FunctProps): Funct<Props>
	props = props :: FunctProps

	const value_args = if typeof(props.value) == "function"
		then { (props :: any).value() }
		elseif props.value ~= nil then { props.value }
		else {}
	const ret_args = if typeof(props.ret) == "function"
		then { (props :: any).ret() }
		elseif props.ret ~= nil then { props.ret }
		else {}

	local object: FunctServer<Props> & FunctClient<Props>

	const function funct_server(options: DefOptions, path: string, lifecycle: lifecycle.Lifecycle): FunctServer<Props>
		if object then
			return object
		end
		if not IS_SERVER then
			error(`[{ROOT_SCOPE_NAME}]: Function server can only be accessed from the server.`)
		end

		const method_names = casing.get_casing(options.casing)
		const on_fn = lifecycle.register_funct_server(path, value_args, ret_args)

		const server_object = {
			[method_names["on"]] = on_fn,
		} :: any

		object = server_object
		return object
	end

	const function funct_client(options: DefOptions, path: string, lifecycle: lifecycle.Lifecycle): FunctClient<Props>
		if object then
			return object
		end
		if IS_SERVER then
			error(`[{ROOT_SCOPE_NAME}]: Function client can only be accessed from the client.`)
		end

		const method_names = casing.get_casing(options.casing)
		const invoke_fn = lifecycle.register_funct_client(path, value_args, ret_args)

		const client_object = {
			[method_names["invoke"]] = invoke_fn,
		} :: any

		object = client_object
		return object
	end

	return {
		type = "function",
		props = props,
		server = funct_server,
		client = funct_client,
	}
end

return funct
