--!native
--!optimize 2

const types = require("../types")

const instance: types.DataType<Instance> = {
	write = function(ctx, value)
		ctx.add_ref(value)
	end,
	read = function(ctx)
		return ctx.read_ref()
	end,
}

return function()
	return instance
end
