--!native
--!optimize 2

const RunService = game:GetService("RunService")

const constants = require("../constants")
const types = require("../types")

type BufferSave = types.BufferSave
type DataType = types.DataType

const IS_DEV = RunService:IsStudio()
const ROOT_SCOPE_NAME = constants.ROOT_SCOPE_NAME

const args_sizes: { [{ DataType }]: index<DataType, "size"> } = {}

const writeu8, readu8 = buffer.writeu8, buffer.readu8
const buffer_create, buffer_copy, buffer_len = buffer.create, buffer.copy, buffer.len

const function create_save(): BufferSave
	return { size = 256, cursor = 0, buff = buffer_create(256), refs = {} }
end

const function ensure(save: BufferSave, bytes: number)
	const required = save.cursor + bytes
	if required <= save.size then
		return
	end
	local new_size = save.size
	while new_size < required do
		new_size *= 2
	end
	const new_buff = buffer_create(new_size)
	buffer_copy(new_buff, 0, save.buff, 0, save.cursor)
	save.buff = new_buff
	save.size = new_size
end

const function compile_args_size(args: { DataType }): index<DataType, "size">
	local fixed_total = 0
	const variable_indices: { number } = {}
	const variable_fns: { (any) -> number } = {}
	for i, value_type in args do
		const s = value_type.size
		if type(s) == "number" then
			fixed_total += s
		else
			table.insert(variable_indices, i)
			table.insert(variable_fns, s :: (any) -> number)
		end
	end
	if #variable_indices == 0 then
		return fixed_total
	end
	return function(...)
		local total = fixed_total
		for idx, i in variable_indices do
			total += variable_fns[idx](select(i, ...))
		end
		return total
	end
end

const function get_args_size(args: { DataType }): index<DataType, "size">
	local compiled = args_sizes[args]
	if compiled == nil then
		compiled = compile_args_size(args)
		args_sizes[args] = compiled
	end
	return compiled
end

const function write_event(save: BufferSave, args: { DataType }, id: number, ...)
	if not save then
		return
	end

	local total = 1
	const args_size = get_args_size(args)
	if type(args_size) == "number" then
		total += args_size
	else
		total += args_size(...)
	end
	ensure(save, total)

	const offset = save.cursor
	const buff = save.buff
	const refs = save.refs

	writeu8(buff, offset, id)
	local bytes = 1

	for i, value_type in args do
		const value = select(i, ...)
		bytes += value_type.write(buff, offset + bytes, value, refs)
	end
	save.cursor += bytes

	if total ~= bytes and IS_DEV then
		warn(`[{ROOT_SCOPE_NAME}]: Data size mismatch, expected {total} but got {bytes}`)
	end
end

const function write_funct_invoke(save: BufferSave, args: { DataType }, id: number, invoke_id: number, ...)
	if not save then
		return
	end

	local total = 2
	const args_size = get_args_size(args)
	if type(args_size) == "number" then
		total += args_size
	else
		total += args_size(...)
	end
	ensure(save, total)

	const offset = save.cursor
	const buff = save.buff
	const refs = save.refs

	writeu8(buff, offset, id)
	writeu8(buff, offset + 1, invoke_id)
	local bytes = 2

	for i, value_type in args do
		const value = select(i, ...)
		bytes += value_type.write(buff, offset + bytes, value, refs)
	end
	save.cursor += bytes

	if total ~= bytes and IS_DEV then
		warn(`[{ROOT_SCOPE_NAME}]: Data size mismatch, expected {total} but got {bytes}`)
	end
end

const function write_funct_ret(
	save: BufferSave,
	args: { DataType },
	id: number,
	invoke_id: number,
	success: boolean,
	err: string?,
	...
)
	if not save then
		return
	end

	if not success then
		ensure(save, 3)
		const offset = save.cursor
		const buff = save.buff
		writeu8(buff, offset, id)
		writeu8(buff, offset + 1, invoke_id)
		writeu8(buff, offset + 2, 0)
		save.cursor += 3
		warn(`[{ROOT_SCOPE_NAME}]: A function encountered an error, {err}`)
		return
	end

	local total = 3
	const args_size = get_args_size(args)
	if type(args_size) == "number" then
		total += args_size
	else
		total += args_size(...)
	end
	ensure(save, total)

	const offset = save.cursor
	const buff = save.buff
	const refs = save.refs

	writeu8(buff, offset, id)
	writeu8(buff, offset + 1, invoke_id)
	writeu8(buff, offset + 2, 1)
	local bytes = 3

	for i, value_type in args do
		const value = select(i, ...)
		bytes += value_type.write(buff, offset + bytes, value, refs)
	end
	save.cursor += bytes

	if total ~= bytes and IS_DEV then
		warn(`[{ROOT_SCOPE_NAME}]: Data size mismatch, expected {total} but got {bytes}`)
	end
end

const function write_event_to_players(
	players: { Player },
	args: { DataType },
	id: number,
	saves: { [Player]: BufferSave },
	exclude: Player?,
	...
)
	local serialized_buff: buffer
	local serialized_offset: number
	local serialized_bytes: number
	local source_refs: { any }
	local refs_start: number
	local refs_count: number = 0
	local is_serialized = false

	for _, player in players do
		if player == exclude then
			continue
		end
		const save = saves[player]
		if not save then
			continue
		end

		if is_serialized then
			ensure(save, serialized_bytes)
			const target_offset = save.cursor
			buffer_copy(save.buff, target_offset, serialized_buff, serialized_offset, serialized_bytes)
			save.cursor += serialized_bytes
			if refs_count > 0 then
				table.move(source_refs, refs_start, refs_start + refs_count - 1, #save.refs + 1, save.refs)
			end
		else
			const start_cursor = save.cursor
			const start_refs_count = #save.refs
			write_event(save, args, id, ...)
			serialized_buff = save.buff
			serialized_offset = start_cursor
			serialized_bytes = save.cursor - start_cursor
			source_refs = save.refs
			refs_start = start_refs_count + 1
			refs_count = #save.refs - start_refs_count
			is_serialized = true
		end
	end
end

const function read_args(args: { DataType }, buff: buffer, offset: number, refs: { [any]: any }): (number, ...any)
	-- fast paths for 1-8 args
	const count = #args
	if count == 1 then
		return args[1].read(buff, offset, refs)
	elseif count == 2 then
		const len1, val1 = args[1].read(buff, offset, refs)
		const len2, val2 = args[2].read(buff, offset + len1, refs)
		return len1 + len2, val1, val2
	elseif count == 3 then
		const len1, val1 = args[1].read(buff, offset, refs)
		const len2, val2 = args[2].read(buff, offset + len1, refs)
		const len3, val3 = args[3].read(buff, offset + len1 + len2, refs)
		return len1 + len2 + len3, val1, val2, val3
	elseif count == 4 then
		const len1, val1 = args[1].read(buff, offset, refs)
		const len2, val2 = args[2].read(buff, offset + len1, refs)
		const len3, val3 = args[3].read(buff, offset + len1 + len2, refs)
		const len4, val4 = args[4].read(buff, offset + len1 + len2 + len3, refs)
		return len1 + len2 + len3 + len4, val1, val2, val3, val4
	elseif count == 5 then
		const len1, val1 = args[1].read(buff, offset, refs)
		const len2, val2 = args[2].read(buff, offset + len1, refs)
		const len3, val3 = args[3].read(buff, offset + len1 + len2, refs)
		const len4, val4 = args[4].read(buff, offset + len1 + len2 + len3, refs)
		const len5, val5 = args[5].read(buff, offset + len1 + len2 + len3 + len4, refs)
		return len1 + len2 + len3 + len4 + len5, val1, val2, val3, val4, val5
	elseif count == 6 then
		const len1, val1 = args[1].read(buff, offset, refs)
		const len2, val2 = args[2].read(buff, offset + len1, refs)
		const len3, val3 = args[3].read(buff, offset + len1 + len2, refs)
		const len4, val4 = args[4].read(buff, offset + len1 + len2 + len3, refs)
		const len5, val5 = args[5].read(buff, offset + len1 + len2 + len3 + len4, refs)
		const len6, val6 = args[6].read(buff, offset + len1 + len2 + len3 + len4 + len5, refs)
		return len1 + len2 + len3 + len4 + len5 + len6, val1, val2, val3, val4, val5, val6
	elseif count == 7 then
		const len1, val1 = args[1].read(buff, offset, refs)
		const len2, val2 = args[2].read(buff, offset + len1, refs)
		const len3, val3 = args[3].read(buff, offset + len1 + len2, refs)
		const len4, val4 = args[4].read(buff, offset + len1 + len2 + len3, refs)
		const len5, val5 = args[5].read(buff, offset + len1 + len2 + len3 + len4, refs)
		const len6, val6 = args[6].read(buff, offset + len1 + len2 + len3 + len4 + len5, refs)
		const len7, val7 = args[7].read(buff, offset + len1 + len2 + len3 + len4 + len5 + len6, refs)
		return len1 + len2 + len3 + len4 + len5 + len6 + len7, val1, val2, val3, val4, val5, val6, val7
	elseif count == 8 then
		const len1, val1 = args[1].read(buff, offset, refs)
		const len2, val2 = args[2].read(buff, offset + len1, refs)
		const len3, val3 = args[3].read(buff, offset + len1 + len2, refs)
		const len4, val4 = args[4].read(buff, offset + len1 + len2 + len3, refs)
		const len5, val5 = args[5].read(buff, offset + len1 + len2 + len3 + len4, refs)
		const len6, val6 = args[6].read(buff, offset + len1 + len2 + len3 + len4 + len5, refs)
		const len7, val7 = args[7].read(buff, offset + len1 + len2 + len3 + len4 + len5 + len6, refs)
		const len8, val8 = args[8].read(buff, offset + len1 + len2 + len3 + len4 + len5 + len6 + len7, refs)
		return len1 + len2 + len3 + len4 + len5 + len6 + len7 + len8, val1, val2, val3, val4, val5, val6, val7, val8
	end
	-- dynamic paths
	local bytes = 0
	const results = table.create(count)
	for i = 1, count do
		local len, value = args[i].read(buff, offset + bytes, refs)
		bytes += len
		results[i] = value
	end
	return bytes, table.unpack(results, 1, count)
end

const function process_incoming_server(
	read_fns: { [number]: index<DataType, "read"> },
	dispatches: { [number]: (...any) -> () }
)
	local serdes_thread: thread?

	const function handle_dispatch(id: number, player: Player, bytes: number, ...)
		dispatches[id](player, ...)
		return bytes
	end

	return function(player: Player, buff: buffer, refs: { [any]: any }?)
		refs = refs or {}
		refs.cursor = 0
		const size = buffer_len(buff)
		local offset = 0
		if serdes_thread and coroutine.status(serdes_thread) == "suspended" then
			warn(
				`[{ROOT_SCOPE_NAME}]: Yielded in a Sync call. An Event uses a Sync call, consider using an Async call instead.`
			)
			coroutine.close(serdes_thread)
		end
		serdes_thread = coroutine.running()
		while offset < size do
			const id = readu8(buff, offset)
			offset += 1
			const read_fn = read_fns[id]
			if not read_fn then
				warn(`[{ROOT_SCOPE_NAME}]: Unknown event ID {id} received.`)
				break
			end
			offset += handle_dispatch(id, player, read_fn(buff, offset, refs))
		end
	end
end

const function process_incoming_client(
	read_fns: { [number]: index<DataType, "read"> },
	dispatches: { [number]: (...any) -> () }
)
	local serdes_thread: thread?

	const function handle_dispatch(id: number, bytes: number, ...)
		dispatches[id](...)
		return bytes
	end

	return function(buff: buffer, refs: { [any]: any }?)
		refs = refs or {}
		refs.cursor = 0
		const size = buffer_len(buff)
		local offset = 0
		if serdes_thread and coroutine.status(serdes_thread) == "suspended" then
			warn(
				`[{ROOT_SCOPE_NAME}]: Yielded in a Sync call. An Event uses a Sync call, consider using an Async call instead.`
			)
			coroutine.close(serdes_thread)
		end
		serdes_thread = coroutine.running()
		while offset < size do
			const id = readu8(buff, offset)
			offset += 1
			const read_fn = read_fns[id]
			if not read_fn then
				warn(`[{ROOT_SCOPE_NAME}]: Unknown event ID {id} received.`)
				break
			end
			offset += handle_dispatch(id, read_fn(buff, offset, refs))
		end
	end
end

return {
	create_save = create_save,
	read_args = read_args,
	write_event = write_event,
	write_funct_invoke = write_funct_invoke,
	write_funct_ret = write_funct_ret,
	write_event_to_players = write_event_to_players,
	process_incoming_server = process_incoming_server,
	process_incoming_client = process_incoming_client,
}
