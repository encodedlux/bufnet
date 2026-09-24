--!native
--!optimize 2

const HttpService = game:GetService("HttpService")
const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")

const constants = require("../constants")
const t = require("../types")
const queue = require("./queue")
const serdes = require("./serdes")
const threadpool = require("./threadpool")

type BufferSave = t.BufferSave
type DataType = t.DataType
type Queue = queue.Queue

const IS_SERVER = RunService:IsServer()
const ROOT_SCOPE_NAME = constants.ROOT_SCOPE_NAME
const ROOT_SCRIPT = constants.ROOT_SCRIPT

const push = queue.push
const create_queue = queue.create
const read_args = serdes.read_args
const spawn = threadpool.spawn
const spawn_callbacks = threadpool.spawn_callbacks

const readu8 = buffer.readu8
const buffer_create, buffer_copy = buffer.create, buffer.copy

const function create_save(): BufferSave
	return { size = 256, cursor = 0, buff = buffer_create(256), refs = {} }
end

const function get_root_folder(parent: Instance): Instance
	const folder_name = ROOT_SCOPE_NAME .. "Remotes"

	if not IS_SERVER then
		return parent:WaitForChild(folder_name)
	end
	const found = parent:FindFirstChild(folder_name)
	if found then
		return found
	end

	const made = Instance.new("Folder")
	made.Name = folder_name
	made.Parent = parent
	return made
end

const function get_remote_names(namespace: string)
	const rel_attribute = namespace .. "_rel"
	const unrel_attribute = namespace .. "_unrel"

	local rel_name: string
	local unrel_name: string

	if IS_SERVER then
		rel_name = HttpService:GenerateGUID(false)
		unrel_name = HttpService:GenerateGUID(false)
		ROOT_SCRIPT:SetAttribute(rel_attribute, rel_name)
		ROOT_SCRIPT:SetAttribute(unrel_attribute, unrel_name)
	else
		rel_name = ROOT_SCRIPT:GetAttribute(rel_attribute) :: string
		if not rel_name then
			ROOT_SCRIPT:GetAttributeChangedSignal(rel_attribute):Wait()
			rel_name = ROOT_SCRIPT:GetAttribute(rel_attribute) :: string
		end
		unrel_name = ROOT_SCRIPT:GetAttribute(unrel_attribute) :: string
		if not unrel_name then
			ROOT_SCRIPT:GetAttributeChangedSignal(unrel_attribute):Wait()
			unrel_name = ROOT_SCRIPT:GetAttribute(unrel_attribute) :: string
		end
	end

	return rel_name, unrel_name
end

const function setup_remotes(namespace: string)
	const rel_name, unrel_name = get_remote_names(namespace)
	const root = get_root_folder(ReplicatedStorage)

	local reliable: RemoteEvent
	local unreliable: UnreliableRemoteEvent

	if IS_SERVER then
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
		reliable = root:WaitForChild(rel_name) :: RemoteEvent
		unreliable = root:WaitForChild(unrel_name) :: UnreliableRemoteEvent
	end

	return reliable, unreliable
end

const function lifecycle(namespace: string, auto_flush: boolean?)
	const reliable, unreliable = setup_remotes(namespace)
	local reliable_id_count = 0
	local unreliable_id_count = 0
	const listeners_reliable = table.create<<{ (...any) -> ...any }>>(256)
	const listeners_unreliable = table.create<<{ (...any) -> ...any }>>(256)
	const polling_queues_reliable: { [number]: Queue } = {}
	const polling_queues_unreliable: { [number]: Queue } = {}
	const queues_reliable = table.create<<{ any }>>(256)
	const queues_unreliable = table.create<<{ any }>>(256)
	const read_fns_reliable = table.create<<(...any) -> (number, ...any)>>(256)
	const read_fns_unreliable = table.create<<(...any) -> (number, ...any)>>(256)
	const dispatches_reliable = table.create<<(...any) -> ()>>(256)
	const dispatches_unreliable = table.create<<(...any) -> ()>>(256)

	const registered_names: { [string]: true } = {}

	local players_reliable: { [Player]: BufferSave }
	local players_unreliable: { [Player]: BufferSave }
	local client_reliable: BufferSave
	local client_unreliable: BufferSave

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

	local flush_fn

	if IS_SERVER then
		players_reliable = {}
		players_unreliable = {}

		const function on_player_added(player: Player)
			players_reliable[player] = create_save()
			players_unreliable[player] = create_save()
		end

		Players.PlayerAdded:Connect(on_player_added)
		Players.PlayerRemoving:Connect(function(player)
			players_reliable[player] = nil
			players_unreliable[player] = nil
		end)

		for _, player in Players:GetPlayers() do
			on_player_added(player)
		end

		const function flush()
			for player, save in players_unreliable do
				if save.cursor > 0 then
					const has_refs = #save.refs > 0
					const size = save.cursor
					const buff = buffer_create(size)
					buffer_copy(buff, 0, save.buff, 0, size)
					unreliable:FireClient(player, buff, has_refs and save.refs or nil)
					save.cursor = 0
					if has_refs then
						table.clear(save.refs)
					end
				end
			end
			for player, save in players_reliable do
				if save.cursor > 0 then
					const has_refs = #save.refs > 0
					const size = save.cursor
					const buff = buffer_create(size)
					buffer_copy(buff, 0, save.buff, 0, size)
					reliable:FireClient(player, buff, has_refs and save.refs or nil)
					save.cursor = 0
					if has_refs then
						table.clear(save.refs)
					end
				end
			end
		end

		if auto_flush ~= false then
			RunService.PostSimulation:Connect(flush)
		else
			flush_fn = flush
		end
		reliable.OnServerEvent:Connect(serdes.process_incoming_server(read_fns_reliable, dispatches_reliable))
		unreliable.OnServerEvent:Connect(serdes.process_incoming_server(read_fns_unreliable, dispatches_unreliable))
	else
		client_reliable = create_save()
		client_unreliable = create_save()

		const function flush()
			if client_unreliable.cursor > 0 then
				const has_refs = #client_unreliable.refs > 0
				const size = client_unreliable.cursor
				const buff = buffer_create(size)
				buffer_copy(buff, 0, client_unreliable.buff, 0, size)
				unreliable:FireServer(buff, has_refs and client_unreliable.refs or nil)
				client_unreliable.cursor = 0
				if has_refs then
					table.clear(client_unreliable.refs)
				end
			end
			if client_reliable.cursor > 0 then
				const has_refs = #client_reliable.refs > 0
				const size = client_reliable.cursor
				const buff = buffer_create(size)
				buffer_copy(buff, 0, client_reliable.buff, 0, size)
				reliable:FireServer(buff, has_refs and client_reliable.refs or nil)
				client_reliable.cursor = 0
				if has_refs then
					table.clear(client_reliable.refs)
				end
			end
		end

		if auto_flush ~= false then
			RunService.PostSimulation:Connect(flush)
		else
			flush_fn = flush
		end
		reliable.OnClientEvent:Connect(serdes.process_incoming_client(read_fns_reliable, dispatches_reliable))
		unreliable.OnClientEvent:Connect(serdes.process_incoming_client(read_fns_unreliable, dispatches_unreliable))
	end

	const function dispatch(id: number, is_reliable: boolean, ...)
		const dispatch_id = is_reliable and dispatches_reliable[id] or dispatches_unreliable[id]
		dispatch_id(...)
	end

	const function get_rel_id(name: string): number
		if IS_SERVER then
			const id = reliable_id_count
			if id >= 256 then
				error(`[{ROOT_SCOPE_NAME}]: Max number of reliable events reached`)
			end
			reliable_id_count += 1
			reliable:SetAttribute(name, id)
			return id
		end

		local id = reliable:GetAttribute(name)
		if not id then
			reliable:GetAttributeChangedSignal(name):Wait()
			id = reliable:GetAttribute(name)
		end
		if not id then
			error(`[{ROOT_SCOPE_NAME}]: Unable to get reliable id for {name}`)
		end
		return id :: number
	end

	const function get_unrel_id(name: string): number
		if IS_SERVER then
			const id = unreliable_id_count
			if id >= 256 then
				error(`[{ROOT_SCOPE_NAME}]: Max number of unreliable events reached`)
			end
			unreliable_id_count += 1
			unreliable:SetAttribute(name, id)
			return id
		end

		local id = unreliable:GetAttribute(name)
		if not id then
			unreliable:GetAttributeChangedSignal(name):Wait()
			id = unreliable:GetAttribute(name)
		end
		if not id then
			error(`[{ROOT_SCOPE_NAME}]: Unable to get unreliable id for {name}`)
		end
		return id :: number
	end

	const function register_event(path: string, is_reliable: boolean, call: t.EventCall, event_args: { DataType })
		assert(registered_names[path] == nil, `[{ROOT_SCOPE_NAME}]: Event "{path}" is already registered`)
		registered_names[path] = true

		const id = is_reliable and get_rel_id(path) or get_unrel_id(path)

		const listeners = is_reliable and listeners_reliable or listeners_unreliable
		const polling_queues = is_reliable and polling_queues_reliable or polling_queues_unreliable
		const queues = is_reliable and queues_reliable or queues_unreliable
		const read_fns = is_reliable and read_fns_reliable or read_fns_unreliable
		const dispatches = is_reliable and dispatches_reliable or dispatches_unreliable

		const write_event = serdes.compile_write_event(event_args, id)

		read_fns[id] = function(buff, offset, refs)
			return read_args(event_args, buff, offset, refs)
		end

		const event_listeners = {} :: { (...any) -> ...any }
		const event_polling_queue = (if call == "Polling" then create_queue() else nil) :: Queue
		const event_queue = {} :: { any }

		listeners[id] = event_listeners
		polling_queues[id] = event_polling_queue
		queues[id] = event_queue
		dispatches[id] = if call == "Polling"
			then function(...)
				push(event_polling_queue, table.pack(...))
			end
			elseif call == "Sync" then function(...)
				if #event_listeners == 0 then
					if #event_queue > 256 then
						warn(`[{ROOT_SCOPE_NAME}]: Queue exceeded 256, did you forget to implement a listener?`)
					end
					table.insert(event_queue, table.pack(...))
					return
				end
				for _, listener in event_listeners do
					listener(...)
				end
			end
			else function(...)
				if #event_listeners == 0 then
					if #event_queue > 256 then
						warn(`[{ROOT_SCOPE_NAME}]: Queue exceeded 256, did you forget to implement a listener?`)
					end
					table.insert(event_queue, table.pack(...))
					return
				end
				spawn_callbacks(event_listeners, ...)
			end

		const returns = {
			listeners = event_listeners,
			polling_queue = event_polling_queue,
			queue = event_queue,
		}

		return id, returns, write_event
	end

	const function register_funct_server(path: string, value_args: { DataType }, ret_args: { DataType })
		assert(registered_names[path] == nil, `[{ROOT_SCOPE_NAME}]: Function "{path}" is already registered`)
		registered_names[path] = true

		const id = get_rel_id(path)
		const write_funct_ret = serdes.compile_write_funct_ret(ret_args, id)

		const function handle_funct_return(invocation_id: number, bytes: number, ...)
			return 1 + bytes, invocation_id, ...
		end

		read_fns_reliable[id] = function(buff, offset, refs)
			const invocation_id = readu8(buff, offset)
			return handle_funct_return(invocation_id, read_args(value_args, buff, offset + 1, refs))
		end :: any

		const funct_listeners = {} :: { (...any) -> ...any }
		const funct_queue = {} :: { any }

		listeners_reliable[id] = funct_listeners
		queues_reliable[id] = funct_queue
		dispatches_reliable[id] = function(...)
			if funct_listeners[1] then
				spawn(funct_listeners[1], ...)
			else
				if #funct_queue > 256 then
					warn(`[{ROOT_SCOPE_NAME}]: Queue exceeded 256, did you forget to implement a listener?`)
				end
				table.insert(funct_queue, table.pack(...))
			end
		end

		return function(callback)
			funct_listeners[1] = function(player: Player, invocation_id: number, ...)
				local ret_results
				const success, err = pcall(function(...)
					ret_results = table.pack(callback(player, ...))
				end, ...)
				write_funct_ret(
					players_reliable[player],
					invocation_id,
					success == true,
					tostring(err),
					if ret_results then table.unpack(ret_results, 1, ret_results.n) else nil
				)
			end
			task.spawn(function(): ()
				const queue = funct_queue or {}
				queues_reliable[id] = nil
				for _, args in queue do
					funct_listeners[1](table.unpack(args, 1, args.n))
				end
			end)
		end
	end

	const function register_funct_client(path: string, value_args: { DataType }, ret_args: { DataType })
		assert(registered_names[path] == nil, `[{ROOT_SCOPE_NAME}]: Function "{path}" is already registered`)
		registered_names[path] = true

		const id = get_rel_id(path)
		const write_funct_invoke = serdes.compile_write_funct_invoke(value_args, id)

		const function handle_funct_return(invocation_id: number, success: boolean, bytes: number, ...)
			return 2 + bytes, success, invocation_id, ...
		end

		read_fns_reliable[id] = function(buff, offset, refs)
			const invocation_id = readu8(buff, offset)
			const success = readu8(buff, offset + 1) == 1
			if not success then
				return 2, false, invocation_id
			end
			return handle_funct_return(invocation_id, success, read_args(ret_args, buff, offset + 2, refs))
		end :: any

		dispatches_reliable[id] = function(success, invocation_id, ...)
			const thread = calls[invocation_id]
			if thread ~= nil then
				calls[invocation_id] = nil
				task.spawn(thread, success, ...)
			end
		end

		const function handle_result(success, ...)
			if success ~= true then
				error(`[{ROOT_SCOPE_NAME}]: There was an exception while processing a Function on the Server.`)
			end
			return ...
		end

		return function(...)
			const invocation_id = invoke()
			if calls[invocation_id] then
				invocations -= 1
				error(`[{ROOT_SCOPE_NAME}]: More than 256 pending calls. Packet dropped.`)
			end
			write_funct_invoke(client_reliable, invocation_id, ...)
			calls[invocation_id] = coroutine.running()
			return handle_result(coroutine.yield())
		end
	end

	return {
		flush = flush_fn,
		dispatch = dispatch,
		players_reliable = players_reliable,
		players_unreliable = players_unreliable,
		get_client_reliable = function()
			return client_reliable
		end,
		get_client_unreliable = function()
			return client_unreliable
		end,
		register_event = register_event,
		register_funct_server = register_funct_server,
		register_funct_client = register_funct_client,
	}
end

export type Lifecycle = typeof(lifecycle(""))

return lifecycle
