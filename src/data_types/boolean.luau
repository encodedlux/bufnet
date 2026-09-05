--!native
--!optimize 2

const types = require("../types")

const BYTE_SIZE = 1

const function write_at(buff, offset, value)
	buffer.writeu8(buff, offset, if value then 1 else 0)
end

const function read_at(buff, offset)
	return buffer.readu8(buff, offset) == 1
end

const bool: types.DataType<boolean> = {
	write = function(ctx, value)
		const offset = ctx.alloc(BYTE_SIZE)
		write_at(ctx.buff, offset, value)
	end,
	read = function(ctx)
		const offset = ctx.read(BYTE_SIZE)
		return read_at(ctx.buff, offset)
	end,

	length = BYTE_SIZE,
	write_at = write_at,
	read_at = read_at,
}

return function()
	return bool
end
