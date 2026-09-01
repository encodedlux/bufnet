const helper = require("../process/helper")
const types = require("../types")

const SIZE = helper.FLOAT * 3 -- 3 float32, for R, G and B

const color3: types.DataType<Color3> = {
	write = @native function(ctx, value)
		const offset = ctx.alloc(SIZE)
		buffer.writef32(ctx.buff, offset, value.R)
		buffer.writef32(ctx.buff, offset + helper.FLOAT, value.G)
		buffer.writef32(ctx.buff, offset + helper.FLOAT * 2, value.B)
	end,
	read = @native function(ctx)
		const offset = ctx.read(SIZE)
		return Color3.new(
			buffer.readf32(ctx.buff, offset),
			buffer.readf32(ctx.buff, offset + helper.FLOAT),
			buffer.readf32(ctx.buff, offset + helper.FLOAT * 2)
		)
	end,
}

return @native function(): types.DataType<Color3>
	return color3
end
