const helper = require("../process/helper")
const types = require("../types")

const SIZE = helper.FLOAT * 6 -- 6 float32, for X, Y, Z and Rx, Ry and Rz

const cframe: types.DataType<CFrame> = {
	write = @native function(ctx, value)
		local x, y, z = value.X, value.Y, value.Z
		local axis, angle = value:ToAxisAngle()
		axis *= angle
		local rx, ry, rz = axis.X, axis.Y, axis.Z

		const offset = ctx.alloc(SIZE)
		buffer.writef32(ctx.buff, offset, x)
		buffer.writef32(ctx.buff, offset + helper.FLOAT, y)
		buffer.writef32(ctx.buff, offset + helper.FLOAT * 2, z)
		buffer.writef32(ctx.buff, offset + helper.FLOAT * 3, rx)
		buffer.writef32(ctx.buff, offset + helper.FLOAT * 4, ry)
		buffer.writef32(ctx.buff, offset + helper.FLOAT * 5, rz)
	end,
	read = @native function(ctx)
		const offset = ctx.read(SIZE)
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
	end,
}

return @native function(): types.DataType<CFrame>
	return cframe
end
