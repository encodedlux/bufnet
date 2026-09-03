--!native
--!optimize 2

const types = require("../types")

const function optional<T>(value_type: types.DataType<T>): types.DataType<T?>
	const value_write = value_type.write
	const value_read = value_type.read

	return {
		write = function(ctx, value)
			const offset = ctx.alloc(1)
			if value == nil then
				buffer.writeu8(ctx.buff, offset, 0)
			else
				buffer.writeu8(ctx.buff, offset, 1)
				value_write(ctx, value)
			end
		end,
		read = function(ctx)
			const offset = ctx.read(1)
			const is_present = buffer.readu8(ctx.buff, offset)
			if is_present == 0 then
				return nil
			end
			return value_read(ctx)
		end,
	}
end

return optional
