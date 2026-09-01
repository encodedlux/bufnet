--!nolint LocalShadow

const t = require("../types")

const function struct<T>(schema: T & {}): t.DataType<t.DataTypeSchema<T>>
	const keys = {}
	for k in schema :: any do
		table.insert(keys, k)
	end
	table.sort(keys)

	return {
		write = @native function(ctx, value: { [string]: any })
			for _, k in keys do
				schema[k].write(ctx, value[k])
			end
		end,
		read = @native function(ctx)
			const result = {}
			for _, k in keys do
				const item = schema[k].read(ctx)
				result[k] = item
			end
			return result :: any
		end,
	}
end

return struct
