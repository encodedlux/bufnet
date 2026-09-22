--!native
--!optimize 2

const Players = game:GetService("Players")
const RunService = game:GetService("RunService")

const constants = require("../constants")
const casing = require("../core/casing")
const lifecycle = require("../core/lifecycle")
const queue = require("../core/queue")
const serdes = require("../core/serdes")
const types = require("../types")

type EventProps = types.EventProps
type Event<Props, Options> = types.Event<Props, Options>
type EventServer<Props, Options> = types.EventServer<Props, Options>
type EventClient<Props, Options> = types.EventClient<Props, Options>
type DefOptions = types.DefOptions

const IS_SERVER = RunService:IsServer()
const ROOT_SCOPE_NAME = constants.ROOT_SCOPE_NAME

const function event<Props, Options>(props: Props & EventProps): Event<Props, Options>
	props = props :: EventProps
	const from = props.from
	const is_reliable = props.type ~= "Unreliable"
	const args: { types.DataType } = if typeof(props.value) == "function"
		then { (props :: any).value() }
		elseif props.value ~= nil then { props.value }
		else {}

	local object: EventServer<Props, Options> & EventClient<Props, Options>

	const function event_server(
		options: DefOptions,
		path: string,
		lifecycle: lifecycle.Lifecycle
	): EventServer<Props, Options>
		if object then
			return object
		end
		if not IS_SERVER then
			error(`[{ROOT_SCOPE_NAME}]: Event server can only be accessed from the server.`)
		end

		const saves = if is_reliable then lifecycle.players_reliable else lifecycle.players_unreliable
		const call = props.call or options.default_call or constants.default_call
		const method_names = casing.get_casing(options.casing)
		const id, reader = lifecycle.register_event(path, is_reliable, call, args, from ~= "Server")

		const server_object: { [string]: any } = {}
		if from ~= "Client" then
			server_object[method_names["fire"]] = function(player: Player, ...)
				serdes.write_event(saves[player], args, id, ...)
			end
			server_object[method_names["fire_all"]] = function(...)
				serdes.write_event_to_players(Players:GetPlayers(), args, id, saves, nil, ...)
			end
			server_object[method_names["fire_except"]] = function(except: Player, ...)
				serdes.write_event_to_players(Players:GetPlayers(), args, id, saves, except, ...)
			end
			server_object[method_names["fire_list"]] = function(players: { Player }, ...)
				serdes.write_event_to_players(players, args, id, saves, nil, ...)
			end
		end
		if from ~= "Server" then
			if call == "Polling" then
				server_object[method_names["iter"]] = function()
					local index = 0
					return function()
						index += 1
						const args = queue.pop(reader.polling_queue)
						if args then
							return index, table.unpack(args, 1, args.n)
						end
						return nil :: any
					end
				end
			else
				server_object[method_names["on"]] = function(callback)
					table.insert(reader.listeners, callback)
					for _, args in reader.queue do
						lifecycle.dispatch(id, is_reliable, table.unpack(args, 1, args.n))
					end
					table.clear(reader.queue)
					return function()
						const idx = table.find(reader.listeners, callback)
						if idx then
							table.remove(reader.listeners, idx)
						end
					end
				end
			end
		end

		object = server_object :: any
		return object
	end

	const function event_client(
		options: DefOptions,
		path: string,
		lifecycle: lifecycle.Lifecycle
	): EventClient<Props, Options>
		if object then
			return object
		end
		if IS_SERVER then
			error(`[{ROOT_SCOPE_NAME}]: Event client can only be accessed from the client.`)
		end

		const save = is_reliable and lifecycle.get_client_reliable() or lifecycle.get_client_unreliable()
		const call = props.call or options.default_call or constants.default_call
		const method_names = casing.get_casing(options.casing)
		const id, reader = lifecycle.register_event(path, is_reliable, call, args, from ~= "Client")

		const client_object: { [string]: any } = {}
		if from ~= "Client" then
			if call == "Polling" then
				client_object[method_names["iter"]] = function()
					local index = 0
					return function()
						index += 1
						const args = queue.pop(reader.polling_queue)
						if args then
							return index, table.unpack(args, 1, args.n)
						end
						return nil :: any
					end
				end
			else
				client_object[method_names["on"]] = function(callback)
					table.insert(reader.listeners, callback)
					for _, args in reader.queue do
						lifecycle.dispatch(id, is_reliable, table.unpack(args, 1, args.n))
					end
					table.clear(reader.queue)
					return function()
						const idx = table.find(reader.listeners, callback)
						if idx then
							table.remove(reader.listeners, idx)
						end
					end
				end
			end
		end
		if from ~= "Server" then
			client_object[method_names["fire"]] = function(...)
				serdes.write_event(save, args, id, ...)
			end
		end

		object = client_object :: any
		return object
	end

	return {
		type = "event",
		props = props,
		server = event_server,
		client = event_client,
	}
end

return event
