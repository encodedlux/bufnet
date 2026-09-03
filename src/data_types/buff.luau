--!native
--!optimize 2

const types = require("../types")

const BYTE_SIZE = 2

const buff: types.DataType<buffer> = {
	write = function(ctx, value)
		const length = buffer.len(value)
		const offset = ctx.alloc(BYTE_SIZE + length)
		buffer.writeu16(ctx.buff, offset, length)
		buffer.copy(ctx.buff, offset + BYTE_SIZE, value, 0, length)
	end,
	read = function(ctx)
		const offset = ctx.read(BYTE_SIZE)
		const length = buffer.readu16(ctx.buff, offset)
		ctx.read(length)
		const new_buff = buffer.create(length)
		buffer.copy(new_buff, 0, ctx.buff, offset + BYTE_SIZE, length)
		return new_buff
	end,
}

return function()
	return buff
end
