const RunService = game:GetService("RunService")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Players = game:GetService("Players")

const types = require("../types")
const threadpool = require("./util/threadpool")
const writter = require("./writter")
const reader = require("./reader")

const IS_SERVER = RunService:IsServer()

const ROOT_FOLDER_NAME = "BufNet"

const CALL_POLLING = 1
const CALL_SINGLE_ASYNC = 2
const CALL_SINGLE_SYNC = 3
const CALL_MANY_ASYNC = 4
const CALL_MANY_SYNC = 5
const CALL_FUNCTION = 6

type BufferSave = types.BufferSave

type RingBuffer = {
	buffer: { any },
	head: number,
	tail: number,
	count: number,
	capacity: number,
}

const function create_rb(capacity: number?): RingBuffer
	const cap = capacity or 256
	return {
		buffer = table.create(cap),
		head = 1,
		tail = 1,
		count = 0,
		capacity = cap,
	}
end

const function push(rb: RingBuffer, value: any)
	if rb.count == rb.capacity then
		const new_capacity = rb.capacity * 2
		const new_buffer = table.create(new_capacity)

		if rb.head == 1 then
			table.move(rb.buffer, 1, rb.count, 1, new_buffer)
		else
			local tail_part = rb.capacity - rb.head + 1
			table.move(rb.buffer, rb.head, rb.capacity, 1, new_buffer)
			table.move(rb.buffer, 1, rb.tail - 1, tail_part + 1, new_buffer)
		end

		rb.buffer = new_buffer
		rb.head = 1
		rb.tail = rb.count + 1
		rb.capacity = new_capacity
	end

	rb.buffer[rb.tail] = value
	rb.tail = rb.tail + 1
	if rb.tail > rb.capacity then
		rb.tail = 1
	end
	rb.count = rb.count + 1
end

const function pop(rb: RingBuffer): any
	if rb.count == 0 then
		return nil
	end

	const value = rb.buffer[rb.head]
	rb.buffer[rb.head] = nil

	rb.head = rb.head + 1
	if rb.head > rb.capacity then
		rb.head = 1
	end
	rb.count = rb.count - 1

	return value
end

const function get_remote_name(namespace: string, reliable: boolean)
	return namespace:upper() .. (reliable and "_RELIABLE_REMOTE" or "_UNRELIABLE_REMOTE")
end

const function get_root_folder(parent: Instance): Instance
	const found = parent:FindFirstChild(ROOT_FOLDER_NAME)
	if found then
		return found
	end

	const made = Instance.new("Folder")
	made.Name = ROOT_FOLDER_NAME
	made.Parent = parent
	return made
end

const function setup_remotes(namespace: string)
	const rel_name = get_remote_name(namespace, true)
	const unrel_name = get_remote_name(namespace, false)

	const parent = ReplicatedStorage

	local reliable: RemoteEvent
	local unreliable: UnreliableRemoteEvent

	if IS_SERVER then
		const root = get_root_folder(parent)
		reliable = root:FindFirstChild(rel_name) :: RemoteEvent
		if not reliable then
			reliable = Instance.new("RemoteEvent")
			reliable.Name = rel_name
			reliable.Parent = root
		end

		unreliable = root:FindFirstChild(unrel_name) :: UnreliableRemoteEvent
		if not unreliable then
			unreliable = Instance.new("UnreliableRemoteEvent")
			unreliable.Name = unrel_name
			unreliable.Parent = root
		end
	else
		const root = parent:WaitForChild(ROOT_FOLDER_NAME)
		reliable = root:WaitForChild(rel_name) :: RemoteEvent
		unreliable = root:WaitForChild(unrel_name) :: UnreliableRemoteEvent
	end

	return reliable, unreliable
end

@native
const function create_lifecycle_server(namespace: string, auto_flush: boolean?)
	const reliable, unreliable = setup_remotes(namespace)

	const reliable_listeners = table.create(256) :: { [number]: { (Player, ...any) -> ...any } }
	const reliable_queues = table.create(256) :: { [number]: RingBuffer }
	const reliable_read_fns = table.create(256) :: { [number]: index<types.DataType<any>, "read"> }
	const reliable_custom_dispatch = table.create(256) :: { [number]: (Player, ...any) -> ...any }
	const reliable_call_tag = buffer.create(256)

	const unreliable_listeners = table.create(256) :: { [number]: { (Player, ...any) -> ...any } }
	const unreliable_queues = table.create(256) :: { [number]: RingBuffer }
	const unreliable_read_fns = table.create(256) :: { [number]: index<types.DataType<any>, "read"> }
	const unreliable_call_tag = buffer.create(256)

	const w, r = writter.new(), reader.new()

	const players_saves: { [Player]: BufferSave } = {}

	Players.PlayerRemoving:Connect(function(player)
		players_saves[player] = nil
	end)

	const function load_player(player: Player)
		w.load(players_saves[player])
	end

	const function save_player(player: Player)
		players_saves[player] = w.save(players_saves[player])
	end

	const function flush()
		for player, save in players_saves do
			if save.cursor <= 0 then
				continue
			end

			const b = buffer.create(save.cursor)
			buffer.copy(b, 0, save.buff, 0, save.cursor)
			reliable:FireClient(player, b, save.refs)

			save.size = 64
			save.cursor = 0
			save.buff = buffer.create(64)
			table.clear(save.refs)
		end
	end

	if auto_flush ~= false then
		RunService.Heartbeat:Connect(flush)
	end

	const function dispatch(id: number, is_reliable: boolean, player: Player, ...)
		const i = id + 1
		const queue = is_reliable and reliable_queues[i] or unreliable_queues[i]
		const listeners = is_reliable and reliable_listeners[i] or unreliable_listeners[i]
		const tag = buffer.readu8(is_reliable and reliable_call_tag or unreliable_call_tag, id)
		if tag == CALL_POLLING then
			push(queue, table.pack(player, ...))
		elseif tag == CALL_SINGLE_ASYNC then
			if listeners[1] then
				threadpool.spawn(listeners[1], player, ...)
			end
		elseif tag == CALL_SINGLE_SYNC then
			if listeners[1] then
				(listeners[1])(player, ...)
			end
		elseif tag == CALL_MANY_ASYNC then
			threadpool.spawn_callbacks(listeners, player, ...)
		elseif tag == CALL_MANY_SYNC then
			for _, listener in listeners do
				listener(player, ...)
			end
		elseif tag == CALL_FUNCTION and is_reliable then
			reliable_custom_dispatch[i](player, ...)
		end
	end

	local serdes_thread: thread?

	const function make_process_incoming(is_reliable: boolean)
		const read_fns = is_reliable and reliable_read_fns or unreliable_read_fns
		return function(player: Player, b: buffer, refs: { any })
			r.cursor = 0
			r.buff = b
			r.refs = refs
			r.refs_cursor = 0
			const size = buffer.len(r.buff)
			if serdes_thread and coroutine.status(serdes_thread) == "suspended" then
				warn("[BufNet]: Yielded in a Sync call. Consider using an Async call instead.")
				coroutine.close(serdes_thread)
			end
			serdes_thread = coroutine.running()
			while r.cursor < size do
				const offset = r.read(1)
				const id = buffer.readu8(r.buff, offset)
				const i = id + 1
				const read_fn = read_fns[i]
				if not read_fn then
					warn(`[BufNet]: Unknown event ID {id} received.`)
					break
				end
				dispatch(id, is_reliable, player, read_fn(r))
			end
		end
	end

	reliable.OnServerEvent:Connect(make_process_incoming(true))
	unreliable.OnServerEvent:Connect(make_process_incoming(false))

	const function register_event(
		id: number,
		is_reliable: boolean,
		call_type: types.EventCall,
		data_type: types.DataType<any>
	)
		const read_fns = is_reliable and reliable_read_fns or unreliable_read_fns
		const queues = is_reliable and reliable_queues or unreliable_queues
		const listeners = is_reliable and reliable_listeners or unreliable_listeners
		const call_tag = is_reliable and reliable_call_tag or unreliable_call_tag

		local tag
		if call_type == "Polling" then
			tag = CALL_POLLING
		elseif call_type == "SingleAsync" then
			tag = CALL_SINGLE_ASYNC
		elseif call_type == "SingleSync" then
			tag = CALL_SINGLE_SYNC
		elseif call_type == "ManyAsync" then
			tag = CALL_MANY_ASYNC
		elseif call_type == "ManySync" then
			tag = CALL_MANY_SYNC
		else
			error("[BufNet]: Unknown call type " .. call_type :: any)
		end
		buffer.writeu8(call_tag, id, tag)

		local i = id + 1
		listeners[i] = table.create(if tag == CALL_SINGLE_ASYNC or tag == CALL_SINGLE_SYNC then 1 else 256) :: any
		if call_type == "Polling" then
			queues[i] = create_rb()
		end
		read_fns[i] = data_type.read

		return {
			listeners = listeners[i],
			queue = queues[i],
		}
	end

	const function register_function(id: number, data_type: types.DataType<any>, return_type: types.DataType<any>)
		buffer.writeu8(reliable_call_tag, id, CALL_FUNCTION)

		local i = id + 1
		reliable_listeners[i] = table.create(1) :: any
		reliable_queues[i] = table.create(256) :: any
		reliable_read_fns[i] = function(ctx: types.Reader)
			const offset = ctx.read(1)
			const invocation_id = buffer.readu8(ctx.buff, offset)
			return invocation_id, data_type.read(ctx)
		end :: any

		reliable_custom_dispatch[i] = function(player: Player, invocation_id: number, ...)
			const listener = reliable_listeners[i][1]
			if listener then
				threadpool.spawn(function(...)
					local ret_results: any
					const success, err = pcall(function(...)
						ret_results = table.pack(listener(player, ...))
					end, ...)
					load_player(player)
					const position = w.alloc(3)
					buffer.writeu8(w.buff, position, id)
					buffer.writeu8(w.buff, position + 1, invocation_id)
					if success ~= true then
						buffer.writeu8(w.buff, position + 2, 0)
						warn(`[BufNet] A function encountered an error, {err}`)
					else
						buffer.writeu8(w.buff, position + 2, 1)
						return_type.write(w, table.unpack(ret_results, 1, ret_results.n))
					end
					save_player(player)
				end, ...)
			else
				local q = reliable_queues[i] :: { any }
				if #q > 256 then
					warn("[BufNet]: Reliable queue exceeded 256, did you forget to implement a listener?")
				end
				table.insert(q, table.pack(player, invocation_id, ...))
			end
		end
		return {
			listeners = reliable_listeners[i],
			queue = reliable_queues[i],
		}
	end

	return {
		writter = w,
		reader = r,
		load = load_player,
		save = save_player,
		flush = if auto_flush == false then flush else nil,
		dispatch = dispatch,
		unreliable = unreliable,
		register_event = register_event,
		register_function = register_function,
	}
end

@native
const function create_lifecycle_client(namespace: string, auto_flush: boolean?)
	const reliable, unreliable = setup_remotes(namespace)

	const reliable_listeners = table.create(256) :: { [number]: { (...any) -> ...any } }
	const reliable_queues = table.create(256) :: { [number]: { [any]: any } }
	const reliable_read_fns = table.create(256) :: { [number]: index<types.DataType<any>, "read"> }
	const reliable_custom_dispatch = table.create(256) :: { [number]: (...any) -> ...any }
	const reliable_call_tag = buffer.create(256)

	const unreliable_listeners = table.create(256) :: { [number]: { (...any) -> ...any } }
	const unreliable_queues = table.create(256) :: { [number]: { [any]: any } }
	const unreliable_read_fns = table.create(256) :: { [number]: index<types.DataType<any>, "read"> }
	const unreliable_call_tag = buffer.create(256)

	const w, r = writter.new(), reader.new()

	const function flush()
		if w.cursor <= 0 then
			return
		end

		const b = buffer.create(w.cursor)
		buffer.copy(b, 0, w.buff, 0, w.cursor)
		reliable:FireServer(b, w.refs)

		w.size = 64
		w.cursor = 0
		w.offset = 0
		w.buff = buffer.create(64)
		table.clear(w.refs)
	end

	if auto_flush ~= false then
		RunService.Heartbeat:Connect(flush)
	end

	const function push_args_to_queue(queue: { any }, ...)
		if #queue > 256 then
			warn("[BufNet]: Event queue exceeded 256, did you forget to implement a listener?")
		end
		table.insert(queue, table.pack(...))
	end

	const function dispatch(id: number, is_reliable: boolean, ...)
		const i = id + 1
		const queue = is_reliable and reliable_queues[i] or unreliable_queues[i]
		const listeners = is_reliable and reliable_listeners[i] or unreliable_listeners[i]
		const tag = buffer.readu8(is_reliable and reliable_call_tag or unreliable_call_tag, id)
		if tag == CALL_POLLING then
			push(queue, table.pack(...))
		elseif tag == CALL_SINGLE_ASYNC then
			if not listeners[1] then
				push_args_to_queue(queue, ...)
				return
			end
			threadpool.spawn(listeners[1], ...)
		elseif tag == CALL_SINGLE_SYNC then
			if not listeners[1] then
				push_args_to_queue(queue, ...)
				return
			end
			listeners[1](...)
		elseif tag == CALL_MANY_ASYNC then
			if #listeners == 0 then
				push_args_to_queue(queue, ...)
				return
			end
			threadpool.spawn_callbacks(listeners, ...)
		elseif tag == CALL_MANY_SYNC then
			if #listeners == 0 then
				push_args_to_queue(queue, ...)
				return
			end
			for _, listener in listeners do
				listener(...)
			end
		elseif tag == CALL_FUNCTION and is_reliable then
			reliable_custom_dispatch[i](...)
		end
	end

	local serdes_thread: thread?

	const function make_process_incoming(is_reliable: boolean)
		const read_fns = is_reliable and reliable_read_fns or unreliable_read_fns

		return function(b: buffer, refs: { any })
			r.cursor = 0
			r.buff = b
			r.refs = refs
			r.refs_cursor = 0
			const size = buffer.len(r.buff)
			if serdes_thread and coroutine.status(serdes_thread) == "suspended" then
				warn("[BufNet]: Yielded in a Sync call. Consider using an Async call instead.")
				coroutine.close(serdes_thread)
			end
			serdes_thread = coroutine.running()
			while r.cursor < size do
				const offset = r.read(1)
				const id = buffer.readu8(r.buff, offset)
				const i = id + 1
				const read_fn = read_fns[i]
				if not read_fn then
					warn(`[BufNet]: Unknown event ID {id} received.`)
					break
				end
				dispatch(id, is_reliable, read_fn(r))
			end
		end
	end

	reliable.OnClientEvent:Connect(make_process_incoming(true))
	unreliable.OnClientEvent:Connect(make_process_incoming(false))

	const function register_event(
		id: number,
		is_reliable: boolean,
		call_type: types.EventCall,
		data_type: types.DataType<any>
	)
		const read_fns = is_reliable and reliable_read_fns or unreliable_read_fns
		const queues = is_reliable and reliable_queues or unreliable_queues
		const listeners = is_reliable and reliable_listeners or unreliable_listeners
		const call_tag = is_reliable and reliable_call_tag or unreliable_call_tag

		local tag
		if call_type == "Polling" then
			tag = CALL_POLLING
		elseif call_type == "SingleAsync" then
			tag = CALL_SINGLE_ASYNC
		elseif call_type == "SingleSync" then
			tag = CALL_SINGLE_SYNC
		elseif call_type == "ManyAsync" then
			tag = CALL_MANY_ASYNC
		elseif call_type == "ManySync" then
			tag = CALL_MANY_SYNC
		else
			error("[BufNet]: Unknown call type " .. call_type :: any)
		end
		buffer.writeu8(call_tag, id, tag)

		local i = id + 1
		listeners[i] = table.create(if tag == CALL_SINGLE_ASYNC or tag == CALL_SINGLE_SYNC then 1 else 256) :: any
		queues[i] = if call_type == "Polling" then create_rb() :: any else table.create(256)
		read_fns[i] = data_type.read

		return {
			listeners = listeners[i],
			queue = queues[i],
		}
	end

	local invocations = 0
	const calls: { [number]: thread } = {}

	const function invoke()
		if invocations == 255 then
			invocations = 0
		end
		const id = invocations
		invocations += 1
		return id
	end

	const function register_function(id: number, data_type: types.DataType<any>, return_type: types.DataType<any>)
		buffer.writeu8(reliable_call_tag, id, CALL_FUNCTION)

		local i = id + 1
		reliable_read_fns[i] = function(ctx: types.Reader)
			const offset = ctx.read(2)
			const invocation_id = buffer.readu8(ctx.buff, offset)
			const success = buffer.readu8(ctx.buff, offset + 1) == 1
			return success, invocation_id, if success then return_type.read(ctx) else "Server encountered an error."
		end :: any
		reliable_custom_dispatch[i] = function(success: boolean, invocation_id: number, ...)
			if calls[invocation_id] ~= nil then
				task.spawn(calls[invocation_id], success, ...)
				calls[invocation_id] = nil
			end
		end

		-- invoke function
		return function(...: any): any
			const invocation_id = invoke()
			if calls[invocation_id] then
				invocations -= 1
				error("[BufNet]: More than 256 pending calls. Packet dropped.")
			end

			const offset = w.alloc(2)
			buffer.writeu8(w.buff, offset, id)
			buffer.writeu8(w.buff, offset + 1, invocation_id)
			data_type.write(w, ...)

			calls[invocation_id] = coroutine.running()

			const function handle_result(success, ...)
				if not success then
					error(`[BufNet]: There was an exception while processing a Function on the Server.`)
				end
				return ...
			end
			return handle_result(coroutine.yield())
		end
	end

	return {
		writter = w,
		reader = r,
		flush = if auto_flush == false then flush else nil,
		unreliable = unreliable,
		dispatch = dispatch,
		register_event = register_event,
		register_function = register_function,
	}
end

export type LifecycleServer = typeof(create_lifecycle_server(""))
export type LifecycleClient = typeof(create_lifecycle_client(""))

return {
	queue_pop = pop,
	create_lifecycle_server = create_lifecycle_server,
	create_lifecycle_client = create_lifecycle_client,
}
