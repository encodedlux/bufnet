const types = require("../types")

const unknown: types.DataType<any> = {
	write = @native function(ctx, value)
		ctx.add_ref(value)
	end,
	read = @native function(ctx)
		return ctx.read_ref()
	end,
}

return @native function(): types.DataType<any>
	return unknown
end
