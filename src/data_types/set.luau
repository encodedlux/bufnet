--!native
--!optimize 2

const types = require("../types")

const function set<K>(key_type: types.DataType<K>): types.DataType<{ [K]: boolean }>
	const key_write = key_type.write
	const key_read = key_type.read

	return {
		write = function(ctx, value)
			const offset = ctx.alloc(2)

			local count = 0
			for k in value do
				count += 1
				key_write(ctx, k)
			end

			buffer.writeu16(ctx.buff, offset, count)
		end,
		read = function(ctx)
			const offset = ctx.read(2)
			const set_length = buffer.readu16(ctx.buff, offset)

			const result = {}
			for _ = 1, set_length do
				const key = key_read(ctx)
				result[key] = true
			end
			return result
		end,
	}
end

return set
