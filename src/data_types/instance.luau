const types = require("../types")

const instace: types.DataType<Instance> = {
	write = @native function(ctx, value)
		ctx.add_ref(value)
	end,
	read = @native function(ctx)
		return ctx.read_ref()
	end,
}

return @native function(): types.DataType<Instance>
	return instace
end
