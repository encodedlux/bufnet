const RunService = game:GetService("RunService")

const types = require("../types")
const net = require("../process/net")

const IS_SERVER = RunService:IsServer()

type DefOptions = types.DefOptions
type Def<Objects, Options> = types.Def<Objects, Options>
type ServerObjects<Objects, Options> = types.ServerObjects<Objects, Options>
type ClientObjects<Objects, Options> = types.ClientObjects<Objects, Options>

const function define<Objects, Options>(name: string, objects: Objects & {}, options: (Options | DefOptions)?): Def<Objects, Options>
	const opt: DefOptions = options or {}

	_G._BUFNET = _G._BUFNET or {}
	if _G._BUFNET[name:upper()] then
		error(
			`[BufNet]: A def is already running with the namespace "{name}". Change the namespace of this def to avoid conflicts.`
		)
	end
	_G._BUFNET[name:upper()] = true

	const function extract_paths(
		node: any,
		current_path: string,
		reliable_paths: { string },
		unreliable_paths: { string }
	)
		if typeof(node) == "table" then
			if typeof(node.server) == "function" or typeof(node.client) == "function" then
				if node.reliable then
					table.insert(reliable_paths, current_path)
				else
					table.insert(unreliable_paths, current_path)
				end
				return
			end

			for k, v in node do
				local next_path = if current_path == "" then k else current_path .. "." .. k
				extract_paths(v, next_path, reliable_paths, unreliable_paths)
			end
		end
	end

	const function build_id_maps(objects: any): ({ [string]: number }, { [string]: number })
		local reliable_paths = {}
		local unreliable_paths = {}
		extract_paths(objects, "", reliable_paths, unreliable_paths)
		table.sort(reliable_paths)
		table.sort(unreliable_paths)

		local reliable_map = {}
		for id, path in reliable_paths do
			reliable_map[path] = id - 1 -- starts at 0 instead of 1 for buffer indices
		end

		local unreliable_map = {}
		for id, path in unreliable_paths do
			unreliable_map[path] = id - 1
		end

		return reliable_map, unreliable_map
	end

	const reliable_id_map, unreliable_id_map = build_id_maps(objects)

	local returns: any

	const function resolve_objects(objects: Objects, is_server: boolean)
		if returns then
			return returns
		end

		const function resolve_objects_recursive(node: any, current_path: string, lifecycle)
			local fn = if is_server then node.server else node.client
			if typeof(fn) == "function" :: any then
				local id_map = if node.reliable then reliable_id_map else unreliable_id_map
				const id = id_map[current_path]
				return fn(opt, id, lifecycle)
			end
			const resolved = {}
			for k, v in node do
				local next_path = if current_path == "" then k else current_path .. "." .. k
				resolved[k] = resolve_objects_recursive(v, next_path, lifecycle)
			end
			return resolved
		end

		local create_lifecycle = if is_server then net.create_lifecycle_server else net.create_lifecycle_client

		const lifecycle = create_lifecycle(name, opt.auto_flush)
		returns = resolve_objects_recursive(objects, "", lifecycle)
		returns.flush = lifecycle.flush

		return table.freeze(returns)
	end

	const function def_server(): ServerObjects<Objects, Options>
		if not IS_SERVER then
			error("[BufNet] Server def can only be accessed from the server.")
		end
		return resolve_objects(objects, true)
	end

	const function def_client(): ClientObjects<Objects, Options>
		if IS_SERVER then
			error("[BufNet] Client def can only be accessed from the client.")
		end
		return resolve_objects(objects, false)
	end

	return {
		server = def_server,
		client = def_client,
	}
end

return define
