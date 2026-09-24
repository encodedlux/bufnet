--!native
--!optimize 2

const Players = game:GetService("Players")
const RunService = game:GetService("RunService")

const constants = require("../constants")
const casing = require("../core/casing")
const lifecycle = require("../core/lifecycle")
const serdes = require("../core/serdes")
const data_types = require("../data_types")
const types = require("../types")

type StateProps<T> = types.StateProps<T>
type State<T> = types.State<T>
type StateShared<T> = types.StateShared<T>
type StateServer<T> = types.StateServer<T>
type StateClient<T> = types.StateClient<T>
type DefOptions = types.DefOptions
type StateGetter<T, R> = types.StateGetter<T, R>
type Cleanup = types.Cleanup

const IS_SERVER = RunService:IsServer()
const ROOT_SCOPE_NAME = constants.ROOT_SCOPE_NAME

const function is_derive<T>(getter: StateGetter<T, any>): boolean
	return debug.info(getter, "n") == "derive_oper"
end

const function state<T>(props: StateProps<T>): State<T>
	const value_type = props.value
	const initial_value = props.initial

	const value_args = {
		data_types.tagged({
			request = {
				value = data_types.nothing,
			},
			dispatch = {
				value = value_type,
			},
		}) :: any,
	}

	local cache = initial_value
	const subs: { (T) -> () } = {}

	local filter_fn: ((value: T, player: Player) -> T)?
	local send_fn: ((value: T) -> ())?

	const function state_set(new_value: T)
		if new_value == cache then
			return
		end
		cache = new_value
		for _, sub in subs do
			task.spawn(sub, new_value)
		end
		if send_fn then
			send_fn(new_value)
		end
	end

	const state_derive: index<StateShared<T>, "derive"> = function(...)
		if select("#", ...) == 2 then
			local last_valueA
			local last_valueB
			const getterA, getterB = ...

			const function derive_oper(value): any
				const current_valueA = getterA(value)
				if last_valueA == current_valueA then
					return last_valueB
				end
				last_valueA = current_valueA
				last_valueB = getterB(current_valueA, last_valueB)
				return last_valueB
			end

			return derive_oper
		end
		local last_cache: T
		local last_value
		const getter = ...

		const function derive_oper(value): any
			if last_cache == value then
				return last_value
			end
			last_cache = value
			last_value = getter(value, last_value)
			return last_value
		end

		return derive_oper
	end

	const function state_sub<R>(callback: (new: R, prev: R?) -> (), getter: StateGetter<T, R>?)
		local current
		const tracked: StateGetter<T, any> = getter
			and if is_derive(getter) then getter else state_derive(getter :: any) :: any
		const function sub(value)
			const previous = current
			current = if tracked then tracked(value) else value
			if current ~= previous then
				callback(current, previous)
			end
		end
		current = if tracked then tracked(cache) else cache
		table.insert(subs, sub)
		return function()
			const idx = table.find(subs, sub)
			if idx then
				table.remove(subs, idx)
			end
		end
	end

	const state_subscribe: index<StateShared<T>, "subscribe"> = function(...)
		if select("#", ...) == 2 then
			const getter, callback = ...
			return state_sub(callback, getter)
		end
		const callback = ...
		return state_sub(callback)
	end

	const state_listen: index<StateShared<T>, "listen"> = function(...)
		if select("#", ...) == 2 then
			const getter, callback = ...
			const last_value = getter(cache)
			callback(last_value, nil)
			return state_sub(callback, getter)
		end
		const callback = ...
		callback(cache, nil)
		return state_sub(callback)
	end

	const state_get: index<StateShared<T>, "get"> = function(getter)
		if getter then
			return getter(cache)
		end
		return cache
	end :: any

	local object: StateServer<T> & StateClient<T>

	const function state_server(options: DefOptions, path: string, lifecycle: lifecycle.Lifecycle): StateServer<T>
		if object then
			return object
		end
		if not IS_SERVER then
			error(`[{ROOT_SCOPE_NAME}]: State server can only be accessed from the server.`)
		end

		const saves = lifecycle.players_reliable
		const method_names = casing.get_casing(options.casing)
		const _id, reader, write = lifecycle.register_event(path, true, "Sync", value_args)

		reader.listeners[1] = function(player: Player, data)
			if data.type == "request" then
				write(saves[player], {
					type = "dispatch",
					value = if filter_fn then filter_fn(cache, player) else cache,
				})
			end
		end

		const function send_all(value: T)
			if filter_fn then
				for _, player in Players:GetPlayers() do
					write(saves[player], { type = "dispatch", value = filter_fn(value, player) })
				end
			else
				serdes.write_event_to_players(
					Players:GetPlayers(),
					saves,
					write,
					nil,
					{ type = "dispatch", value = value }
				)
			end
		end

		send_fn = send_all

		const server_object = {
			[method_names["set"]] = function(value_or_cb)
				if typeof(value_or_cb) == "function" then
					const new_value = value_or_cb(cache)
					if new_value == false then
						return
					end
					state_set(new_value)
				else
					state_set(value_or_cb)
				end
			end,
			[method_names["filter"]] = function(callback: (value: T, player: Player) -> T)
				filter_fn = callback
			end,
			[method_names["derive"]] = state_derive,
			[method_names["subscribe"]] = state_subscribe,
			[method_names["listen"]] = state_listen,
			[method_names["get"]] = state_get,
		}
		object = server_object :: any
		return object
	end

	const function state_client(options: DefOptions, path: string, lifecycle: lifecycle.Lifecycle): StateClient<T>
		if object then
			return object
		end
		if IS_SERVER then
			error(`[{ROOT_SCOPE_NAME}]: State client can only be accessed from the client.`)
		end

		const method_names = casing.get_casing(options.casing)
		const _id, reader, write = lifecycle.register_event(path, true, "Sync", value_args)

		write(lifecycle.get_client_reliable(), { type = "request" })

		reader.listeners[1] = function(data)
			if data.type == "dispatch" then
				state_set(data.value)
			end
		end

		const client_object = {
			[method_names["derive"]] = state_derive,
			[method_names["subscribe"]] = state_subscribe,
			[method_names["listen"]] = state_listen,
			[method_names["get"]] = state_get,
		}
		object = client_object :: any
		return object
	end

	return {
		type = "state",
		props = props,
		server = state_server,
		client = state_client,
	}
end

return state
