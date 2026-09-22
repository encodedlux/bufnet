const RunService = game:GetService("RunService")

const constants = require("../constants")
const casing = require("../core/casing")
const lifecycle = require("../core/lifecycle")
const types = require("../types")

type DefOptions = types.DefOptions
type Def<Objects, Options> = types.Def<Objects, Options>
type ServerObjects<Objects, Options> = types.ServerObjects<Objects, Options>
type ClientObjects<Objects, Options> = types.ClientObjects<Objects, Options>

type DefObjects = {
	read [string]: DefObjects | types.Event | types.Funct | types.State,
}

const IS_SERVER = RunService:IsServer()
const ROOT_SCOPE_NAME = constants.ROOT_SCOPE_NAME

const function define<Objects, Options>(
	name: string,
	objects: Objects & DefObjects,
	options: (Options & DefOptions)?
): Def<Objects, Options>
	_G[`_{ROOT_SCOPE_NAME}`] = _G[`_{ROOT_SCOPE_NAME}`] or {}
	if _G[`_{ROOT_SCOPE_NAME}`][name:upper()] then
		error(
			`[{ROOT_SCOPE_NAME}]: A definition is already running with the namespace "{name}". Change the namespace of this definition to avoid conflicts.`
		)
	end
	_G[`_{ROOT_SCOPE_NAME}`][name:upper()] = true

	const opt: DefOptions = options or {}
	const method_names = casing.get_casing(opt.casing)

	local returns: any

	const function resolve_objects()
		if returns then
			return returns
		end

		const function resolve_objects_recursive(node: DefObjects, path: string, lifecycle: lifecycle.Lifecycle): any
			const fn = if IS_SERVER then node.server else node.client
			if typeof(fn) == "function" then
				return fn(opt, path, lifecycle)
			end
			const resolved = {}
			for k, v: DefObjects in node do
				const next_path = path .. "_" .. k
				resolved[k] = resolve_objects_recursive(v, next_path, lifecycle)
			end
			return resolved
		end

		const lifecycle = lifecycle(name, opt.auto_flush)
		returns = resolve_objects_recursive(objects, name, lifecycle)
		returns[method_names["flush"]] = lifecycle.flush
		return table.freeze(returns)
	end

	const function def_server(): ServerObjects<Objects, Options>
		if not IS_SERVER then
			error(`[{ROOT_SCOPE_NAME}]: Server def can only be accessed from the server.`)
		end
		return resolve_objects()
	end

	const function def_client(): ClientObjects<Objects, Options>
		if IS_SERVER then
			error(`[{ROOT_SCOPE_NAME}]: Client def can only be accessed from the client.`)
		end
		return resolve_objects()
	end

	return {
		server = def_server,
		client = def_client,
	}
end

return define
