--!native
--!optimize 2

const RunService = game:GetService("RunService")

const constants = require("../constants")
const types = require("../types")

type BufferSave = types.BufferSave
type DataType = types.DataType

const IS_DEV = RunService:IsStudio()
const ROOT_SCOPE_NAME = constants.ROOT_SCOPE_NAME

const writeu8, readu8 = buffer.writeu8, buffer.readu8
const buffer_create, buffer_copy, buffer_len = buffer.create, buffer.copy, buffer.len

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

const function compile_write_args(args: { DataType }): (buffer, number, { [any]: any }, ...any) -> number
	const count = #args
	if count == 2 then
		const write1, write2 = args[1].write, args[2].write
		return function(buff, offset, refs, a1, a2)
			const len1 = write1(buff, offset, a1, refs)
			const len2 = write2(buff, offset + len1, a2, refs)
			return len1 + len2
		end
	elseif count == 3 then
		const write1, write2, write3 = args[1].write, args[2].write, args[3].write
		return function(buff, offset, refs, a1, a2, a3)
			const len1 = write1(buff, offset, a1, refs)
			const len2 = write2(buff, offset + len1, a2, refs)
			const len3 = write3(buff, offset + len1 + len2, a3, refs)
			return len1 + len2 + len3
		end
	elseif count == 4 then
		const write1, write2, write3, write4 = args[1].write, args[2].write, args[3].write, args[4].write
		return function(buff, offset, refs, a1, a2, a3, a4)
			const len1 = write1(buff, offset, a1, refs)
			const len2 = write2(buff, offset + len1, a2, refs)
			const len3 = write3(buff, offset + len1 + len2, a3, refs)
			const len4 = write4(buff, offset + len1 + len2 + len3, a4, refs)
			return len1 + len2 + len3 + len4
		end
	elseif count == 5 then
		const write1, write2, write3, write4, write5 =
			args[1].write, args[2].write, args[3].write, args[4].write, args[5].write
		return function(buff, offset, refs, a1, a2, a3, a4, a5)
			const len1 = write1(buff, offset, a1, refs)
			const len2 = write2(buff, offset + len1, a2, refs)
			const len3 = write3(buff, offset + len1 + len2, a3, refs)
			const len4 = write4(buff, offset + len1 + len2 + len3, a4, refs)
			const len5 = write5(buff, offset + len1 + len2 + len3 + len4, a5, refs)
			return len1 + len2 + len3 + len4 + len5
		end
	elseif count == 6 then
		const write1, write2, write3, write4, write5, write6 =
			args[1].write, args[2].write, args[3].write, args[4].write, args[5].write, args[6].write
		return function(buff, offset, refs, a1, a2, a3, a4, a5, a6)
			const len1 = write1(buff, offset, a1, refs)
			const len2 = write2(buff, offset + len1, a2, refs)
			const len3 = write3(buff, offset + len1 + len2, a3, refs)
			const len4 = write4(buff, offset + len1 + len2 + len3, a4, refs)
			const len5 = write5(buff, offset + len1 + len2 + len3 + len4, a5, refs)
			const len6 = write6(buff, offset + len1 + len2 + len3 + len4 + len5, a6, refs)
			return len1 + len2 + len3 + len4 + len5 + len6
		end
	elseif count == 7 then
		const write1, write2, write3, write4, write5, write6, write7 =
			args[1].write, args[2].write, args[3].write, args[4].write, args[5].write, args[6].write, args[7].write
		return function(buff, offset, refs, a1, a2, a3, a4, a5, a6, a7)
			const len1 = write1(buff, offset, a1, refs)
			const len2 = write2(buff, offset + len1, a2, refs)
			const len3 = write3(buff, offset + len1 + len2, a3, refs)
			const len4 = write4(buff, offset + len1 + len2 + len3, a4, refs)
			const len5 = write5(buff, offset + len1 + len2 + len3 + len4, a5, refs)
			const len6 = write6(buff, offset + len1 + len2 + len3 + len4 + len5, a6, refs)
			const len7 = write7(buff, offset + len1 + len2 + len3 + len4 + len5 + len6, a7, refs)
			return len1 + len2 + len3 + len4 + len5 + len6 + len7
		end
	elseif count == 8 then
		const write1, write2, write3, write4, write5, write6, write7, write8 =
			args[1].write,
			args[2].write,
			args[3].write,
			args[4].write,
			args[5].write,
			args[6].write,
			args[7].write,
			args[8].write
		return function(buff, offset, refs, a1, a2, a3, a4, a5, a6, a7, a8)
			const len1 = write1(buff, offset, a1, refs)
			const len2 = write2(buff, offset + len1, a2, refs)
			const len3 = write3(buff, offset + len1 + len2, a3, refs)
			const len4 = write4(buff, offset + len1 + len2 + len3, a4, refs)
			const len5 = write5(buff, offset + len1 + len2 + len3 + len4, a5, refs)
			const len6 = write6(buff, offset + len1 + len2 + len3 + len4 + len5, a6, refs)
			const len7 = write7(buff, offset + len1 + len2 + len3 + len4 + len5 + len6, a7, refs)
			const len8 = write8(buff, offset + len1 + len2 + len3 + len4 + len5 + len6 + len7, a8, refs)
			return len1 + len2 + len3 + len4 + len5 + len6 + len7 + len8
		end
	elseif count == 9 then
		const write1, write2, write3, write4, write5, write6, write7, write8, write9 =
			args[1].write,
			args[2].write,
			args[3].write,
			args[4].write,
			args[5].write,
			args[6].write,
			args[7].write,
			args[8].write,
			args[9].write
		return function(buff, offset, refs, a1, a2, a3, a4, a5, a6, a7, a8, a9)
			const len1 = write1(buff, offset, a1, refs)
			const len2 = write2(buff, offset + len1, a2, refs)
			const len3 = write3(buff, offset + len1 + len2, a3, refs)
			const len4 = write4(buff, offset + len1 + len2 + len3, a4, refs)
			const len5 = write5(buff, offset + len1 + len2 + len3 + len4, a5, refs)
			const len6 = write6(buff, offset + len1 + len2 + len3 + len4 + len5, a6, refs)
			const len7 = write7(buff, offset + len1 + len2 + len3 + len4 + len5 + len6, a7, refs)
			const len8 = write8(buff, offset + len1 + len2 + len3 + len4 + len5 + len6 + len7, a8, refs)
			const len9 = write9(buff, offset + len1 + len2 + len3 + len4 + len5 + len6 + len7 + len8, a9, refs)
			return len1 + len2 + len3 + len4 + len5 + len6 + len7 + len8 + len9
		end
	elseif count == 10 then
		const write1, write2, write3, write4, write5, write6, write7, write8, write9, write10 =
			args[1].write,
			args[2].write,
			args[3].write,
			args[4].write,
			args[5].write,
			args[6].write,
			args[7].write,
			args[8].write,
			args[9].write,
			args[10].write
		return function(buff, offset, refs, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
			const len1 = write1(buff, offset, a1, refs)
			const len2 = write2(buff, offset + len1, a2, refs)
			const len3 = write3(buff, offset + len1 + len2, a3, refs)
			const len4 = write4(buff, offset + len1 + len2 + len3, a4, refs)
			const len5 = write5(buff, offset + len1 + len2 + len3 + len4, a5, refs)
			const len6 = write6(buff, offset + len1 + len2 + len3 + len4 + len5, a6, refs)
			const len7 = write7(buff, offset + len1 + len2 + len3 + len4 + len5 + len6, a7, refs)
			const len8 = write8(buff, offset + len1 + len2 + len3 + len4 + len5 + len6 + len7, a8, refs)
			const len9 = write9(buff, offset + len1 + len2 + len3 + len4 + len5 + len6 + len7 + len8, a9, refs)
			const len10 =
				write10(buff, offset + len1 + len2 + len3 + len4 + len5 + len6 + len7 + len8 + len9, a10, refs)
			return len1 + len2 + len3 + len4 + len5 + len6 + len7 + len8 + len9 + len10
		end
	end

	return function(buff, offset, refs, ...)
		local bytes = 0
		for i = 1, count do
			bytes += args[i].write(buff, offset + bytes, select(i, ...), refs)
		end
		return bytes
	end
end

const function compile_read_args(args: { DataType }): (buffer, number, { [any]: any }) -> (number, ...any)
	const count = #args
	if count == 1 then
		return args[1].read
	elseif count == 2 then
		const read1, read2 = args[1].read, args[2].read
		return function(buff, offset, refs)
			const len1, val1 = read1(buff, offset, refs)
			const len2, val2 = read2(buff, offset + len1, refs)
			return len1 + len2, val1, val2
		end
	elseif count == 3 then
		const read1, read2, read3 = args[1].read, args[2].read, args[3].read
		return function(buff, offset, refs)
			const len1, val1 = read1(buff, offset, refs)
			const len2, val2 = read2(buff, offset + len1, refs)
			const len3, val3 = read3(buff, offset + len1 + len2, refs)
			return len1 + len2 + len3, val1, val2, val3
		end
	elseif count == 4 then
		const read1, read2, read3, read4 = args[1].read, args[2].read, args[3].read, args[4].read
		return function(buff, offset, refs)
			const len1, val1 = read1(buff, offset, refs)
			const len2, val2 = read2(buff, offset + len1, refs)
			const len3, val3 = read3(buff, offset + len1 + len2, refs)
			const len4, val4 = read4(buff, offset + len1 + len2 + len3, refs)
			return len1 + len2 + len3 + len4, val1, val2, val3, val4
		end
	elseif count == 5 then
		const read1, read2, read3, read4, read5 = args[1].read, args[2].read, args[3].read, args[4].read, args[5].read
		return function(buff, offset, refs)
			const len1, val1 = read1(buff, offset, refs)
			const len2, val2 = read2(buff, offset + len1, refs)
			const len3, val3 = read3(buff, offset + len1 + len2, refs)
			const len4, val4 = read4(buff, offset + len1 + len2 + len3, refs)
			const len5, val5 = read5(buff, offset + len1 + len2 + len3 + len4, refs)
			return len1 + len2 + len3 + len4 + len5, val1, val2, val3, val4, val5
		end
	elseif count == 6 then
		const read1, read2, read3, read4, read5, read6 =
			args[1].read, args[2].read, args[3].read, args[4].read, args[5].read, args[6].read
		return function(buff, offset, refs)
			const len1, val1 = read1(buff, offset, refs)
			const len2, val2 = read2(buff, offset + len1, refs)
			const len3, val3 = read3(buff, offset + len1 + len2, refs)
			const len4, val4 = read4(buff, offset + len1 + len2 + len3, refs)
			const len5, val5 = read5(buff, offset + len1 + len2 + len3 + len4, refs)
			const len6, val6 = read6(buff, offset + len1 + len2 + len3 + len4 + len5, refs)
			return len1 + len2 + len3 + len4 + len5 + len6, val1, val2, val3, val4, val5, val6
		end
	elseif count == 7 then
		const read1, read2, read3, read4, read5, read6, read7 =
			args[1].read, args[2].read, args[3].read, args[4].read, args[5].read, args[6].read, args[7].read
		return function(buff, offset, refs)
			const len1, val1 = read1(buff, offset, refs)
			const len2, val2 = read2(buff, offset + len1, refs)
			const len3, val3 = read3(buff, offset + len1 + len2, refs)
			const len4, val4 = read4(buff, offset + len1 + len2 + len3, refs)
			const len5, val5 = read5(buff, offset + len1 + len2 + len3 + len4, refs)
			const len6, val6 = read6(buff, offset + len1 + len2 + len3 + len4 + len5, refs)
			const len7, val7 = read7(buff, offset + len1 + len2 + len3 + len4 + len5 + len6, refs)
			return len1 + len2 + len3 + len4 + len5 + len6 + len7, val1, val2, val3, val4, val5, val6, val7
		end
	elseif count == 8 then
		const read1, read2, read3, read4, read5, read6, read7, read8 =
			args[1].read,
			args[2].read,
			args[3].read,
			args[4].read,
			args[5].read,
			args[6].read,
			args[7].read,
			args[8].read
		return function(buff, offset, refs)
			const len1, val1 = read1(buff, offset, refs)
			const len2, val2 = read2(buff, offset + len1, refs)
			const len3, val3 = read3(buff, offset + len1 + len2, refs)
			const len4, val4 = read4(buff, offset + len1 + len2 + len3, refs)
			const len5, val5 = read5(buff, offset + len1 + len2 + len3 + len4, refs)
			const len6, val6 = read6(buff, offset + len1 + len2 + len3 + len4 + len5, refs)
			const len7, val7 = read7(buff, offset + len1 + len2 + len3 + len4 + len5 + len6, refs)
			const len8, val8 = read8(buff, offset + len1 + len2 + len3 + len4 + len5 + len6 + len7, refs)
			return len1 + len2 + len3 + len4 + len5 + len6 + len7 + len8, val1, val2, val3, val4, val5, val6, val7, val8
		end
	elseif count == 9 then
		const read1, read2, read3, read4, read5, read6, read7, read8, read9 =
			args[1].read,
			args[2].read,
			args[3].read,
			args[4].read,
			args[5].read,
			args[6].read,
			args[7].read,
			args[8].read,
			args[9].read
		return function(buff, offset, refs)
			const len1, val1 = read1(buff, offset, refs)
			const len2, val2 = read2(buff, offset + len1, refs)
			const len3, val3 = read3(buff, offset + len1 + len2, refs)
			const len4, val4 = read4(buff, offset + len1 + len2 + len3, refs)
			const len5, val5 = read5(buff, offset + len1 + len2 + len3 + len4, refs)
			const len6, val6 = read6(buff, offset + len1 + len2 + len3 + len4 + len5, refs)
			const len7, val7 = read7(buff, offset + len1 + len2 + len3 + len4 + len5 + len6, refs)
			const len8, val8 = read8(buff, offset + len1 + len2 + len3 + len4 + len5 + len6 + len7, refs)
			const len9, val9 = read9(buff, offset + len1 + len2 + len3 + len4 + len5 + len6 + len7 + len8, refs)
			return len1 + len2 + len3 + len4 + len5 + len6 + len7 + len8 + len9,
				val1,
				val2,
				val3,
				val4,
				val5,
				val6,
				val7,
				val8,
				val9
		end
	elseif count == 10 then
		const read1, read2, read3, read4, read5, read6, read7, read8, read9, read10 =
			args[1].read,
			args[2].read,
			args[3].read,
			args[4].read,
			args[5].read,
			args[6].read,
			args[7].read,
			args[8].read,
			args[9].read,
			args[10].read
		return function(buff, offset, refs)
			const len1, val1 = read1(buff, offset, refs)
			const len2, val2 = read2(buff, offset + len1, refs)
			const len3, val3 = read3(buff, offset + len1 + len2, refs)
			const len4, val4 = read4(buff, offset + len1 + len2 + len3, refs)
			const len5, val5 = read5(buff, offset + len1 + len2 + len3 + len4, refs)
			const len6, val6 = read6(buff, offset + len1 + len2 + len3 + len4 + len5, refs)
			const len7, val7 = read7(buff, offset + len1 + len2 + len3 + len4 + len5 + len6, refs)
			const len8, val8 = read8(buff, offset + len1 + len2 + len3 + len4 + len5 + len6 + len7, refs)
			const len9, val9 = read9(buff, offset + len1 + len2 + len3 + len4 + len5 + len6 + len7 + len8, refs)
			const len10, val10 =
				read10(buff, offset + len1 + len2 + len3 + len4 + len5 + len6 + len7 + len8 + len9, refs)
			return len1 + len2 + len3 + len4 + len5 + len6 + len7 + len8 + len9 + len10,
				val1,
				val2,
				val3,
				val4,
				val5,
				val6,
				val7,
				val8,
				val9,
				val10
		end
	end
	return function(buff, offset, refs)
		local bytes = 0
		const results = table.create(count)
		for i = 1, count do
			local len, value = args[i].read(buff, offset + bytes, refs)
			bytes += len
			results[i] = value
		end
		return bytes, table.unpack(results, 1, count)
	end
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

const function compile_write_event(args: { DataType }, id: number)
	const count = #args
	const args_size = compile_args_size(args)

	if count == 1 then
		const write1 = args[1].write
		if type(args_size) == "number" then
			const total = 1 + args_size
			return function(save: BufferSave, value)
				if not save then
					return
				end
				ensure(save, total)
				const offset = save.cursor
				const buff = save.buff
				const refs = save.refs
				writeu8(buff, offset, id)
				const bytes = 1 + write1(buff, offset + 1, value, refs)
				save.cursor += bytes
				if IS_DEV and total ~= bytes then
					warn(`[{ROOT_SCOPE_NAME}]: Data size mismatch, expected {total} but got {bytes}`)
				end
			end
		end
		return function(save: BufferSave, value)
			if not save then
				return
			end
			const total = 1 + args_size(value)
			ensure(save, total)
			const offset = save.cursor
			const buff = save.buff
			const refs = save.refs
			writeu8(buff, offset, id)
			const bytes = 1 + write1(buff, offset + 1, value, refs)
			save.cursor += bytes
			if IS_DEV and total ~= bytes then
				warn(`[{ROOT_SCOPE_NAME}]: Data size mismatch, expected {total} but got {bytes}`)
			end
		end
	end

	const write_values = compile_write_args(args)
	if type(args_size) == "number" then
		const total = 1 + args_size
		return function(save: BufferSave, ...)
			if not save then
				return
			end
			ensure(save, total)
			const offset = save.cursor
			const buff = save.buff
			const refs = save.refs
			writeu8(buff, offset, id)
			const bytes = 1 + write_values(buff, offset + 1, refs, ...)
			save.cursor += bytes
			if IS_DEV and total ~= bytes then
				warn(`[{ROOT_SCOPE_NAME}]: Data size mismatch, expected {total} but got {bytes}`)
			end
		end
	end
	return function(save: BufferSave, ...)
		if not save then
			return
		end
		const total = 1 + args_size(...)
		ensure(save, total)
		const offset = save.cursor
		const buff = save.buff
		const refs = save.refs
		writeu8(buff, offset, id)
		const bytes = 1 + write_values(buff, offset + 1, refs, ...)
		save.cursor += bytes
		if IS_DEV and total ~= bytes then
			warn(`[{ROOT_SCOPE_NAME}]: Data size mismatch, expected {total} but got {bytes}`)
		end
	end
end

const function compile_write_funct_invoke(args: { DataType }, id: number)
	const count = #args
	const args_size = compile_args_size(args)

	if count == 1 then
		const write1 = args[1].write
		if type(args_size) == "number" then
			const total = 2 + args_size
			return function(save: BufferSave, invoke_id: number, value)
				if not save then
					return
				end
				ensure(save, total)
				const offset = save.cursor
				const buff = save.buff
				const refs = save.refs
				writeu8(buff, offset, id)
				writeu8(buff, offset + 1, invoke_id)
				const bytes = 2 + write1(buff, offset + 2, value, refs)
				save.cursor += bytes
				if IS_DEV and total ~= bytes then
					warn(`[{ROOT_SCOPE_NAME}]: Data size mismatch, expected {total} but got {bytes}`)
				end
			end
		end
		return function(save: BufferSave, invoke_id: number, value)
			if not save then
				return
			end
			const total = 2 + args_size(value)
			ensure(save, total)
			const offset = save.cursor
			const buff = save.buff
			const refs = save.refs
			writeu8(buff, offset, id)
			writeu8(buff, offset + 1, invoke_id)
			const bytes = 2 + write1(buff, offset + 2, value, refs)
			save.cursor += bytes
			if IS_DEV and total ~= bytes then
				warn(`[{ROOT_SCOPE_NAME}]: Data size mismatch, expected {total} but got {bytes}`)
			end
		end
	end

	const write_args = compile_write_args(args)
	if type(args_size) == "number" then
		const total = 2 + args_size
		return function(save: BufferSave, invoke_id: number, ...)
			if not save then
				return
			end
			ensure(save, total)
			const offset = save.cursor
			const buff = save.buff
			const refs = save.refs
			writeu8(buff, offset, id)
			writeu8(buff, offset + 1, invoke_id)
			const bytes = 2 + write_args(buff, offset + 2, refs, ...)
			save.cursor += bytes
			if IS_DEV and total ~= bytes then
				warn(`[{ROOT_SCOPE_NAME}]: Data size mismatch, expected {total} but got {bytes}`)
			end
		end
	end
	return function(save: BufferSave, invoke_id: number, ...)
		if not save then
			return
		end
		const total = 2 + args_size(...)
		ensure(save, total)
		const offset = save.cursor
		const buff = save.buff
		const refs = save.refs
		writeu8(buff, offset, id)
		writeu8(buff, offset + 1, invoke_id)
		const bytes = 2 + write_args(buff, offset + 2, refs, ...)
		save.cursor += bytes
		if IS_DEV and total ~= bytes then
			warn(`[{ROOT_SCOPE_NAME}]: Data size mismatch, expected {total} but got {bytes}`)
		end
	end
end

const function compile_write_funct_ret(args: { DataType }, id: number)
	const count = #args
	const args_size = compile_args_size(args)
	const success_total = if type(args_size) == "number" then 3 + args_size else nil

	if count == 1 then
		const write1 = args[1].write
		return function(save: BufferSave, invoke_id: number, success: boolean, err: string?, value)
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
			const total = success_total or (3 + (args_size :: (...any) -> number)(value))
			ensure(save, total)
			const offset = save.cursor
			const buff = save.buff
			const refs = save.refs
			writeu8(buff, offset, id)
			writeu8(buff, offset + 1, invoke_id)
			writeu8(buff, offset + 2, 1)
			const bytes = 3 + write1(buff, offset + 3, value, refs)
			save.cursor += bytes
			if IS_DEV and total ~= bytes then
				warn(`[{ROOT_SCOPE_NAME}]: Data size mismatch, expected {total} but got {bytes}`)
			end
		end
	end

	const write_args = compile_write_args(args)
	return function(save: BufferSave, invoke_id: number, success: boolean, err: string?, ...)
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
		const total = success_total or (3 + (args_size :: (...any) -> number)(...))
		ensure(save, total)
		const offset = save.cursor
		const buff = save.buff
		const refs = save.refs
		writeu8(buff, offset, id)
		writeu8(buff, offset + 1, invoke_id)
		writeu8(buff, offset + 2, 1)
		const bytes = 3 + write_args(buff, offset + 3, refs, ...)
		save.cursor += bytes
		if IS_DEV and total ~= bytes then
			warn(`[{ROOT_SCOPE_NAME}]: Data size mismatch, expected {total} but got {bytes}`)
		end
	end
end

const function write_event_to_players(
	players: { Player },
	saves: { [Player]: BufferSave },
	write: (BufferSave, ...any) -> (),
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
			write(save, ...)
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
	compile_read_args = compile_read_args,
	compile_write_event = compile_write_event,
	compile_write_funct_invoke = compile_write_funct_invoke,
	compile_write_funct_ret = compile_write_funct_ret,
	write_event_to_players = write_event_to_players,
	process_incoming_server = process_incoming_server,
	process_incoming_client = process_incoming_client,
}
