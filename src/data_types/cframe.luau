--!native
--!optimize 2

const helper = require("../process/helper")
const types = require("../types")

const SIZE = helper.FLOAT * 6 -- 6 float32, for X, Y, Z and Rx, Ry and Rz

const function write_at(ctx, offset, value: CFrame)
	local x, y, z = value.X, value.Y, value.Z
	local axis, angle = value:ToAxisAngle()
	axis *= angle
	local rx, ry, rz = axis.X, axis.Y, axis.Z

	buffer.writef32(ctx.buff, offset, x)
	buffer.writef32(ctx.buff, offset + helper.FLOAT, y)
	buffer.writef32(ctx.buff, offset + helper.FLOAT * 2, z)
	buffer.writef32(ctx.buff, offset + helper.FLOAT * 3, rx)
	buffer.writef32(ctx.buff, offset + helper.FLOAT * 4, ry)
	buffer.writef32(ctx.buff, offset + helper.FLOAT * 5, rz)
end

const function read_at(ctx, offset)
	local x = buffer.readf32(ctx.buff, offset)
	local y = buffer.readf32(ctx.buff, offset + helper.FLOAT)
	local z = buffer.readf32(ctx.buff, offset + helper.FLOAT * 2)
	local rx = buffer.readf32(ctx.buff, offset + helper.FLOAT * 3)
	local ry = buffer.readf32(ctx.buff, offset + helper.FLOAT * 4)
	local rz = buffer.readf32(ctx.buff, offset + helper.FLOAT * 5)

	local axis = Vector3.new(rx, ry, rz)
	local angle = axis.Magnitude

	if angle ~= 0 then
		return CFrame.new(x, y, z) * CFrame.fromAxisAngle(axis, angle)
	end
	return CFrame.new(x, y, z)
end

const cframe: types.DataType<CFrame> = {
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
	return cframe
end
