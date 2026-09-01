const helper = require("../process/helper")
const types = require("../types")

const SIZE = helper.FLOAT * 3 -- 3 float32, for X, Y and Z

type Vec3Options = {
	min: number?,
	max: number?,
}

@native
const function vec3(options: Vec3Options?): types.DataType<Vector3>
	return {
		write = @native function(ctx, value)
			const offset = ctx.alloc(SIZE)
			buffer.writef32(ctx.buff, offset, value.X)
			buffer.writef32(ctx.buff, offset + helper.FLOAT, value.Y)
			buffer.writef32(ctx.buff, offset + helper.FLOAT * 2, value.Z)
		end,
		read = if options
			then @native function(ctx)
				const offset = ctx.read(SIZE)
				const vec = Vector3.new(
					buffer.readf32(ctx.buff, offset),
					buffer.readf32(ctx.buff, offset + helper.FLOAT),
					buffer.readf32(ctx.buff, offset + helper.FLOAT * 2)
				)
				const length = vec.Magnitude

				if options.min and length < options.min then
					error(`[BufNet] Expected vector3 length to be larger than {options.min}, got {length} instead.`)
				end
				if options.max and length > options.max then
					error(`[BufNet] Expected vector3 length to be smaller than {options.max}, got {length} instead.`)
				end

				return vec
			end
			else @native function(ctx)
				const offset = ctx.read(SIZE)
				return Vector3.new(
					buffer.readf32(ctx.buff, offset),
					buffer.readf32(ctx.buff, offset + helper.FLOAT),
					buffer.readf32(ctx.buff, offset + helper.FLOAT * 2)
				)
			end,
	}
end

return vec3
