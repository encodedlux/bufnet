const types = require("../types")

const function new()
	const ctx: types.Reader = {
		buff = buffer.create(0),
		cursor = 0,
		refs = {},
		refs_cursor = 0,
	} :: any

	function ctx.load(new_b, new_refs)
		ctx.buff = new_b
		ctx.cursor = 0
		ctx.refs = new_refs or {}
		ctx.refs_cursor = 0
	end

	function ctx.read(size)
		const offset = ctx.cursor
		ctx.cursor += size
		return offset
	end

	function ctx.read_ref()
		ctx.refs_cursor += 1
		return ctx.refs[ctx.refs_cursor]
	end

	return ctx
end

return { new = new }
