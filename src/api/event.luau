--!nolint LocalShadow

const Players = game:GetService("Players")
const RunService = game:GetService("RunService")

const net = require("../process/net")
const writter = require("../process/writter")
const types = require("../types")
const cases = require("../util/cases")

const side: "server" | "client" = RunService:IsServer() and "server" or "client"

type EventProps<T...> = types.EventProps<T...>
type Event<Props, Options, T...> = types.Event<Props, Options, T...>
type EventServer<Props, Options, T...> = types.EventServer<Props, Options, T...>
type EventClient<Props, Options, T...> = types.EventClient<Props, Options, T...>
type DefOptions = types.DefOptions

const function event<Props, Options, T...>(props: Props | EventProps<T...>): Event<Props, Options, T...>
	const props = props :: EventProps<T...>
	local object: EventServer<Props, Options, T...> | EventClient<Props, Options, T...>
	const from = props.from
	const is_reliable = props.type ~= "Unreliable"

	const function write_id(w: types.Writter, id: number)
		const cursor = w.alloc(1)
		buffer.writeu8(w.buff, cursor, id)
	end

	const function write_unreliable(w: types.Writter, id: number, ...)
		w.load()
		write_id(w, id)
		props.value.write(w, ...)
		const snapshot = w.save()
		const buff = buffer.create(snapshot.cursor)
		buffer.copy(buff, 0, snapshot.buff, 0, snapshot.cursor)
		return buff, snapshot.refs
	end

	const function event_server(
		options: DefOptions,
		id: number,
		lifecycle: net.LifecycleServer
	): EventServer<Props, Options, T...>
		if object then
			return object
		end
		if side ~= "server" then
			error("[BufNet] Event server can only be accessed from the server.")
		end

		const casing = options.casing or "Snake"
		const call = props.call or options.default_call or "SingleAsync"
		const use_polling = call == "Polling"

		const unreliable = lifecycle.unreliable

		local event: EventServer<Props, Options, T...>
		if from == "Server" then
			const broadcast_snapshot = writter.create()

			event = {
				[cases.to_case("fire", casing)] = if is_reliable
					then function(player: Player, ...: T...)
						lifecycle.load(player)
						write_id(lifecycle.writter, id)
						props.value.write(lifecycle.writter, ...)
						lifecycle.save(player)
					end
					else function(player: Player, ...: T...)
						const buff, refs = write_unreliable(lifecycle.writter, id, ...)
						unreliable:FireClient(player, buff, refs)
					end,
				[cases.to_case("fire_all", casing)] = if is_reliable
					then function(...: T...)
						lifecycle.writter.load()
						write_id(lifecycle.writter, id)
						props.value.write(lifecycle.writter, ...)
						const snapshot = lifecycle.writter.save()

						for _, p in Players:GetPlayers() do
							lifecycle.load(p)
							lifecycle.writter.append(snapshot)
							lifecycle.save(p)
						end
					end
					else function(...: T...)
						const buff, refs = write_unreliable(lifecycle.writter, id, ...)
						unreliable:FireAllClients(buff, refs)
					end,
				[cases.to_case("fire_except", casing)] = if is_reliable
					then function(except: Player, ...: T...)
						lifecycle.writter.load()
						write_id(lifecycle.writter, id)
						props.value.write(lifecycle.writter, ...)
						lifecycle.writter.save(broadcast_snapshot)

						for _, player in Players:GetPlayers() do
							if player ~= except then
								lifecycle.load(player)
								lifecycle.writter.append(broadcast_snapshot)
								lifecycle.save(player)
							end
						end
					end
					else function(except: Player, ...: T...)
						const buff, refs = write_unreliable(lifecycle.writter, id, ...)
						for _, player in Players:GetPlayers() do
							if player == except then
								continue
							end
							unreliable:FireClient(player, buff, refs)
						end
					end,
				[cases.to_case("fire_list", casing)] = if is_reliable
					then function(players: { Player }, ...: T...)
						lifecycle.writter.load()
						write_id(lifecycle.writter, id)
						props.value.write(lifecycle.writter, ...)
						lifecycle.writter.save(broadcast_snapshot)

						for _, p in players do
							lifecycle.load(p)
							lifecycle.writter.append(broadcast_snapshot)
							lifecycle.save(p)
						end
					end
					else function(players: { Player }, ...: T...)
						const buff, refs = write_unreliable(lifecycle.writter, id, ...)
						for _, player in players do
							unreliable:FireClient(player, buff, refs)
						end
					end,
			} :: any
		elseif from == "Client" then
			const reader = lifecycle.register_event(id, is_reliable, call, props.value)

			if use_polling then
				event = {
					[cases.to_case("iter", casing)] = function()
						local index = 0
						return function()
							index += 1
							const args = net.queue_pop(reader.queue)
							if args then
								return index, table.unpack(args, 1, args.n)
							end
							return nil :: any
						end
					end,
				} :: any
			else
				event = {
					[cases.to_case("on", casing)] = function(callback: (player: Player, T...) -> ())
						if call == "ManyAsync" or call == "ManySync" then
							table.insert(reader.listeners, callback)
						else
							reader.listeners[1] = callback :: any
						end

						return function()
							if call == "ManyAsync" or call == "ManySync" then
								const index = table.find(reader.listeners, callback)
								if index then
									table.remove(reader.listeners, index)
								end
							else
								if reader.listeners[1] == callback then
									reader.listeners[1] = nil
								end
							end
						end
					end,
				} :: any
			end
		end

		object = event
		return object
	end
	const function event_client(
		options: DefOptions,
		id: number,
		lifecycle: net.LifecycleClient
	): EventClient<Props, Options, T...>
		if object then
			return object
		end
		if side ~= "client" then
			error("[BufNet] Event client can only be accessed from the client.")
		end

		const from = props.from
		const casing = options.casing or "Snake"
		const call = props.call or options.default_call or "SingleAsync"
		const use_polling = call == "Polling"

		const unreliable = lifecycle.unreliable

		local event: EventClient<Props, Options, T...>
		if from == "Server" then
			const reader = lifecycle.register_event(id, is_reliable, call, props.value)

			if use_polling then
				event = {
					[cases.to_case("iter", casing)] = function()
						local index = 0
						return function()
							index += 1
							const args = net.queue_pop(reader.queue)
							if args then
								return index, table.unpack(args, 1, args.n)
							end
							return nil :: any
						end
					end,
				} :: any
			else
				event = {
					[cases.to_case("on", casing)] = function(callback: (T...) -> ())
						if call == "ManyAsync" or call == "ManySync" then
							table.insert(reader.listeners, callback :: any)
						else
							reader.listeners[1] = callback :: any
						end

						const event_queue = reader.queue
						reader.queue = {} :: any
						for _, args in event_queue do
							lifecycle.dispatch(id, is_reliable, table.unpack(args, 1, args.n) :: any)
						end

						return function()
							if call == "ManyAsync" or call == "ManySync" then
								const index = table.find(reader.listeners, callback :: any)
								if index then
									table.remove(reader.listeners, index)
								end
							else
								if reader.listeners[1] == callback then
									reader.listeners[1] = nil
								end
							end
						end
					end,
				} :: any
			end
		elseif from == "Client" then
			const unreliable_save = writter.create()

			event = {
				[cases.to_case("fire", casing)] = if is_reliable
					then function(...: T...)
						write_id(lifecycle.writter, id)
						props.value.write(lifecycle.writter, ...)
					end
					else function(...: T...)
						lifecycle.writter.save(unreliable_save)
						const buff, refs = write_unreliable(lifecycle.writter, id, ...)
						unreliable:FireServer(buff, refs)
						lifecycle.writter.load(unreliable_save)
					end,
			} :: any
		end

		object = event
		return object
	end

	return {
		type = "event",
		reliable = is_reliable,
		server = event_server,
		client = event_client,
	} :: any
end

return event
