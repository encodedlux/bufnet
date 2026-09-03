--!native
--!optimize 2

const types = require("../types")

const function new()
	const ctx: types.Reader = {
		buff = buffer.create(0),
		cursor = 0,
		refs = {},
		refs_cursor = 0,
	} :: any

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
