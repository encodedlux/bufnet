const types = require("../types")

const bool: types.DataType<boolean> = {
	write = @native function(ctx, value)
		const offset = ctx.alloc(1)
		buffer.writeu8(ctx.buff, offset, if value then 1 else 0)
	end,
	read = @native function(ctx)
		const offset = ctx.read(1)
		return buffer.readu8(ctx.buff, offset) == 1
	end,
}

return @native function(): types.DataType<boolean>
	return bool
end
