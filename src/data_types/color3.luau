const types = require("../types")

const color3: types.DataType<Color3> = {
	write = @native function(ctx, value)
		const offset = ctx.alloc(3)
		buffer.writeu8(ctx.buff, offset, value.R * 255)
		buffer.writeu8(ctx.buff, offset + 1, value.G * 255)
		buffer.writeu8(ctx.buff, offset + 2, value.B * 255)
	end,
	read = @native function(ctx)
		const offset = ctx.read(3)
		return Color3.fromRGB(
			buffer.readu8(ctx.buff, offset),
			buffer.readu8(ctx.buff, offset + 1),
			buffer.readu8(ctx.buff, offset + 2)
		)
	end,
}

return @native function(): types.DataType<Color3>
	return color3
end
