--!native
--!optimize 2

const types = require("../types")

const BYTE_SIZE = 2

const str: types.DataType<string> = {
	write = function(ctx, value)
		const length = #value
		const offset = ctx.alloc(BYTE_SIZE + length)
		buffer.writeu16(ctx.buff, offset, length)
		buffer.writestring(ctx.buff, offset + BYTE_SIZE, value, length)
	end,
	read = function(ctx)
		const offset = ctx.read(BYTE_SIZE)
		const length = buffer.readu16(ctx.buff, offset)
		ctx.read(length)
		const value = buffer.readstring(ctx.buff, offset + BYTE_SIZE, length)
		return value
	end,
}

return function()
	return str
end
