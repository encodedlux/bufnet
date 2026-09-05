--!native
--!optimize 2

const helper = require("../process/helper")
const types = require("../types")

const FLOAT = helper.FLOAT
const SIZE = FLOAT * 3 -- 3 float32, for X, Y and Z

const function write_at(buff, offset, value: Vector3)
	buffer.writef32(buff, offset, value.X)
	buffer.writef32(buff, offset + FLOAT, value.Y)
	buffer.writef32(buff, offset + FLOAT * 2, value.Z)
end

const function read_at(buff, offset)
	return Vector3.new(
		buffer.readf32(buff, offset),
		buffer.readf32(buff, offset + FLOAT),
		buffer.readf32(buff, offset + FLOAT * 2)
	)
end

const vec3: types.DataType<Vector3> = {
	write = function(ctx, value)
		const offset = ctx.alloc(SIZE)
		write_at(ctx.buff, offset, value)
	end,
	read = function(ctx)
		const offset = ctx.read(SIZE)
		return read_at(ctx.buff, offset)
	end,

	length = SIZE,
	write_at = write_at,
	read_at = read_at,
}

return function()
	return vec3
end
