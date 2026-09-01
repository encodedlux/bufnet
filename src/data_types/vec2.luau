const helper = require("../process/helper")
const types = require("../types")

const SIZE = helper.FLOAT * 2 -- 2 float32, for X and Y

type Vec2Options = {
	min: number?,
	max: number?,
}

@native
const function vec2(options: Vec2Options?): types.DataType<Vector2>
	return {
		write = @native function(ctx, value)
			const offset = ctx.alloc(SIZE)
			buffer.writef32(ctx.buff, offset, value.X)
			buffer.writef32(ctx.buff, offset + helper.FLOAT, value.Y)
		end,
		read = if options
			then @native function(ctx)
				const offset = ctx.read(SIZE)
				const vec =
					Vector2.new(buffer.readf32(ctx.buff, offset), buffer.readf32(ctx.buff, offset + helper.FLOAT))
				const length = vec.Magnitude

				if options.min and length < options.min then
					error(`[BufNet] Expected vector2 length to be larger than {options.min}, got {length} instead.`)
				end
				if options.max and length > options.max then
					error(`[BufNet] Expected vector2 length to be smaller than {options.max}, got {length} instead.`)
				end

				return vec
			end
			else @native function(ctx)
				const offset = ctx.read(SIZE)
				return Vector2.new(buffer.readf32(ctx.buff, offset), buffer.readf32(ctx.buff, offset + helper.FLOAT))
			end,
	}
end

return vec2
