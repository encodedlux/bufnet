const types = require("../types")

const null = newproxy()

const function new()
	const ctx: types.Writter = {
		size = 64,
		cursor = 0,
		offset = 0,
		buff = buffer.create(64),
		refs = {},
	} :: any

	function ctx.alloc(bytes)
		const in_use = ctx.cursor + bytes
		if in_use > ctx.size then
			while in_use > ctx.size do
				ctx.size *= 1.5
			end
			const new_buff = buffer.create(ctx.size)
			buffer.copy(new_buff, 0, ctx.buff, 0, ctx.cursor)
			ctx.buff = new_buff
		end
		ctx.offset = ctx.cursor
		ctx.cursor += bytes
		return ctx.offset
	end

	function ctx.save(out)
		if out then
			out.size, out.cursor, out.buff, out.refs = ctx.size, ctx.cursor, ctx.buff, ctx.refs
			return out
		end
		return { size = ctx.size, cursor = ctx.cursor, buff = ctx.buff, refs = ctx.refs }
	end

	function ctx.load(save)
		if save then
			ctx.size, ctx.cursor, ctx.offset, ctx.buff, ctx.refs =
				save.size, save.cursor, save.cursor, save.buff, save.refs
		else
			ctx.size, ctx.cursor, ctx.offset, ctx.buff, ctx.refs = 64, 0, 0, buffer.create(64), {}
		end
	end

	function ctx.add_ref(ref)
		const refs = ctx.refs
		refs[#refs + 1] = ref or null
	end

	function ctx.append(save)
		if save.cursor <= 0 then
			return
		end
		const new_offset = ctx.alloc(save.cursor)
		buffer.copy(ctx.buff, new_offset, save.buff, 0, save.cursor)
		if #save.refs > 0 then
			table.move(save.refs, 1, #save.refs, #ctx.refs + 1, ctx.refs)
		end
	end

	return ctx
end

const function create_save(): types.BufferSave
	return { size = 64, cursor = 0, buff = buffer.create(64), refs = {} }
end

return { new = new, create = create_save }
