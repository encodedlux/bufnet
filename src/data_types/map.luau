--!native
--!optimize 2

const types = require("../types")

const function map<K, V>(key_type: types.DataType<K>, value_type: types.DataType<V>): types.DataType<{ [K]: V }>
	const key_write = key_type.write
	const key_read = key_type.read
	const value_write = value_type.write
	const value_read = value_type.read

	return {
		write = function(ctx, value)
			const offset = ctx.alloc(2)

			local count = 0
			for k, v in value do
				count += 1
				key_write(ctx, k)
				value_write(ctx, v)
			end

			buffer.writeu16(ctx.buff, offset, count)
		end,
		read = function(ctx)
			const offset = ctx.read(2)
			const map_length = buffer.readu16(ctx.buff, offset)
			const result = {}

			for _ = 1, map_length do
				const key = key_read(ctx)
				const val = value_read(ctx)
				result[key] = val
			end

			return result
		end,
	}
end

return map
