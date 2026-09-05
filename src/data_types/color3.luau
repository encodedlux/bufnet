--!native
--!optimize 2

const types = require("../types")

const BYTE_SIZE = 3

const function write_at(buff, offset, value: Color3)
	buffer.writeu8(buff, offset, value.R * 255)
	buffer.writeu8(buff, offset + 1, value.G * 255)
	buffer.writeu8(buff, offset + 2, value.B * 255)
end

const function read_at(buff, offset)
	return Color3.fromRGB(buffer.readu8(buff, offset), buffer.readu8(buff, offset + 1), buffer.readu8(buff, offset + 2))
end

const color3: types.DataType<Color3> = {
	write = function(ctx, value)
		const offset = ctx.alloc(BYTE_SIZE)
		write_at(ctx.buff, offset, value)
	end,
	read = function(ctx)
		const offset = ctx.read(BYTE_SIZE)
		return read_at(ctx.buff, offset)
	end,

	length = BYTE_SIZE,
	write_at = write_at,
	read_at = read_at,
}

return function()
	return color3
end
