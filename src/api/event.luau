--!native
--!optimize 2
--!nolint LocalShadow

const Players = game:GetService("Players")
const RunService = game:GetService("RunService")

const net = require("../process/net")
const types = require("../types")

const side: "server" | "client" = RunService:IsServer() and "server" or "client"

type EventProps<T...> = types.EventProps<T...>
type Event<Props, Options, T...> = types.Event<Props, Options, T...>
type EventServer<Props, Options, T...> = types.EventServer<Props, Options, T...>
type EventClient<Props, Options, T...> = types.EventClient<Props, Options, T...>
type DefOptions = types.DefOptions

const function event<Props, Options, T...>(props: Props & EventProps<T...>): Event<Props, Options, T...>
	const props = props :: EventProps<T...>
	local object: EventServer<Props, Options, T...> & EventClient<Props, Options, T...>
	const from = props.from
	const is_reliable = props.type ~= "Unreliable"

	const function write_unreliable(w: types.Writter, id: number, ...)
		w.load()
		const cursor = w.alloc(1)
		buffer.writeu8(w.buff, cursor, id)
		props.value.write(w, ...)
		const buff, offset, refs = w.buff, w.cursor, w.refs
		const new_buff = buffer.create(offset)
		buffer.copy(new_buff, 0, buff, 0, offset)
		return new_buff, refs
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

		const casing = options.casing or types.default_case
		const call = props.call or options.default_call or types.default_call
		const use_polling = call == "Polling"

		const method_names = types.get_casing(casing :: types.DefaultCase)

		const unreliable = lifecycle.unreliable

		const w = lifecycle.writter

		local event: EventServer<Props, Options, T...>
		if from == "Server" then
			event = {
				[method_names["fire"]] = if is_reliable
					then function(player: Player, ...: T...)
						lifecycle.load(player)
						const cursor = w.alloc(1)
						buffer.writeu8(w.buff, cursor, id)
						props.value.write(w, ...)
						lifecycle.save(player)
					end
					else function(player: Player, ...: T...)
						unreliable:FireClient(player, write_unreliable(w, id, ...))
					end,
				[method_names["fire_all"]] = if is_reliable
					then function(...: T...)
						w.load()
						const cursor = w.alloc(1)
						buffer.writeu8(w.buff, cursor, id)
						props.value.write(w, ...)
						const buff, cursor, refs = w.buff, w.cursor, w.refs

						for _, p in Players:GetPlayers() do
							lifecycle.load(p)
							const new_offset = w.alloc(cursor)
							buffer.copy(w.buff, new_offset, buff, 0, cursor)
							table.move(refs, 1, #refs, #w.refs + 1, w.refs)
							lifecycle.save(p)
						end
					end
					else function(...: T...)
						unreliable:FireAllClients(write_unreliable(w, id, ...))
					end,
				[method_names["fire_except"]] = if is_reliable
					then function(except: Player, ...: T...)
						w.load()
						const cursor = w.alloc(1)
						buffer.writeu8(w.buff, cursor, id)
						props.value.write(w, ...)
						const buff, cursor, refs = w.buff, w.cursor, w.refs

						for _, player in Players:GetPlayers() do
							if player ~= except then
								lifecycle.load(player)
								const new_offset = w.alloc(cursor)
								buffer.copy(w.buff, new_offset, buff, 0, cursor)
								table.move(refs, 1, #refs, #w.refs + 1, w.refs)
								lifecycle.save(player)
							end
						end
					end
					else function(except: Player, ...: T...)
						const buff, refs = write_unreliable(w, id, ...)
						for _, player in Players:GetPlayers() do
							if player == except then
								continue
							end
							unreliable:FireClient(player, buff, refs)
						end
					end,
				[method_names["fire_list"]] = if is_reliable
					then function(players: { Player }, ...: T...)
						w.load()
						const cursor = w.alloc(1)
						buffer.writeu8(w.buff, cursor, id)
						props.value.write(w, ...)
						const buff, cursor, refs = w.buff, w.cursor, w.refs

						for _, p in players do
							lifecycle.load(p)
							const new_offset = w.alloc(cursor)
							buffer.copy(w.buff, new_offset, buff, 0, cursor)
							table.move(refs, 1, #refs, #w.refs + 1, w.refs)
							lifecycle.save(p)
						end
					end
					else function(players: { Player }, ...: T...)
						const buff, refs = write_unreliable(w, id, ...)
						for _, player in players do
							unreliable:FireClient(player, buff, refs)
						end
					end,
			} :: any
		elseif from == "Client" then
			const reader = lifecycle.register_event(id, is_reliable, call, props.value)

			if use_polling then
				event = {
					[method_names["iter"]] = function()
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
					[method_names["on"]] = if call == "ManyAsync" or call == "ManySync"
						then function(callback: (player: Player, T...) -> ())
							table.insert(reader.listeners, callback)
							return function()
								table.remove(reader.listeners, table.find(reader.listeners, callback))
							end
						end
						else function(callback: (player: Player, T...) -> ())
							reader.listeners[1] = callback :: any
							return function()
								reader.listeners[1] = nil
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
		const casing = options.casing or types.default_case
		const call = props.call or options.default_call or types.default_call
		const use_polling = call == "Polling"

		const method_names = types.get_casing(casing :: types.DefaultCase)

		const unreliable = lifecycle.unreliable

		const w = lifecycle.writter

		local event: EventClient<Props, Options, T...>
		if from == "Server" then
			const reader = lifecycle.register_event(id, is_reliable, call, props.value)

			if use_polling then
				event = {
					[method_names["iter"]] = function()
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
					[method_names["on"]] = if call == "ManyAsync" or call == "ManySync"
						then function(callback: (T...) -> ())
							table.insert(reader.listeners, callback)
							for _, args in reader.queue do
								lifecycle.dispatch(id, is_reliable, table.unpack(args, 1, args.n) :: any)
							end
							reader.queue = {} :: any
							return function()
								table.remove(reader.listeners, table.find(reader.listeners, callback))
							end
						end
						else function(callback: (T...) -> ())
							reader.listeners[1] = callback :: any
							const event_queue = reader.queue
							reader.queue = {} :: any
							for _, args in event_queue do
								lifecycle.dispatch(id, is_reliable, table.unpack(args, 1, args.n) :: any)
							end
							return function()
								reader.listeners[1] = nil
							end
						end,
				} :: any
			end
		elseif from == "Client" then
			event = {
				[method_names["fire"]] = if is_reliable
					then function(...: T...)
						const cursor = w.alloc(1)
						buffer.writeu8(w.buff, cursor, id)
						props.value.write(w, ...)
					end
					else function(...: T...)
						const snapshot = w.save()
						const buff, refs = write_unreliable(w, id, ...)
						unreliable:FireServer(buff, refs)
						w.load(snapshot)
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
