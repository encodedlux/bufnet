--!native
--!optimize 2

const helper = require("../process/helper")
const types = require("../types")

const SIZE = helper.FLOAT * 3 -- 3 float32, for X, Y and Z

const function write_at(ctx, offset, value: Vector3)
	buffer.writef32(ctx.buff, offset, value.X)
	buffer.writef32(ctx.buff, offset + helper.FLOAT, value.Y)
	buffer.writef32(ctx.buff, offset + helper.FLOAT * 2, value.Z)
end

const function read_at(ctx, offset)
	return Vector3.new(
		buffer.readf32(ctx.buff, offset),
		buffer.readf32(ctx.buff, offset + helper.FLOAT),
		buffer.readf32(ctx.buff, offset + helper.FLOAT * 2)
	)
end

const vec3: types.DataType<Vector3> = {
	write = function(ctx, value)
		const offset = ctx.alloc(SIZE)
		write_at(ctx, offset, value)
	end,
	read = function(ctx)
		const offset = ctx.read(SIZE)
		return read_at(ctx, offset)
	end,

	length = SIZE,
	write_at = write_at,
	read_at = read_at,
}

return function()
	return vec3
end
