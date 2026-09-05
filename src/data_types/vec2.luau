--!native
--!optimize 2

const helper = require("../process/helper")
const types = require("../types")

const FLOAT = helper.FLOAT
const SIZE = FLOAT * 2 -- 2 float32, for X and Y

const function write_at(buff, offset, value: Vector2)
	buffer.writef32(buff, offset, value.X)
	buffer.writef32(buff, offset + FLOAT, value.Y)
end

const function read_at(buff, offset)
	return Vector2.new(buffer.readf32(buff, offset), buffer.readf32(buff, offset + FLOAT))
end

const vec2: types.DataType<Vector2> = {
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
	return vec2
end
