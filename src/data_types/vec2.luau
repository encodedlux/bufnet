--!native
--!optimize 2

const helper = require("../process/helper")
const types = require("../types")

const SIZE = helper.FLOAT * 2 -- 2 float32, for X and Y

const function write_at(ctx, offset, value: Vector2)
	buffer.writef32(ctx.buff, offset, value.X)
	buffer.writef32(ctx.buff, offset + helper.FLOAT, value.Y)
end

const function read_at(ctx, offset)
	return Vector2.new(buffer.readf32(ctx.buff, offset), buffer.readf32(ctx.buff, offset + helper.FLOAT))
end

const vec2: types.DataType<Vector2> = {
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
	return vec2
end
