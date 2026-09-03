--!native
--!optimize 2
--!nolint LocalShadow

const t = require("../types")

const function struct<T>(schema: T & {}): t.DataType<t.DataTypeSchema<T>>
	const schema = schema :: { [string]: t.DataType<any> }
	const keys = {}
	local total_length = 0
	local has_fastpath = true
	const fields = {}

	for k in schema do
		table.insert(keys, k)
	end
	table.sort(keys)

	for _, k in keys do
		local field_type = schema[k]
		local flen = field_type.length
		local fwa = field_type.write_at
		local fra = field_type.read_at
		if flen and fwa and fra then
			table.insert(fields, {
				name = k,
				length = flen,
				offset = total_length,
				write_at = fwa,
				read_at = fra,
			})
			total_length += flen
		else
			has_fastpath = false
		end
	end

	return if has_fastpath then {
		write = function(ctx, value)
			const offset = ctx.alloc(total_length)
			for i = 1, #fields do
				local f = fields[i]
				f.write_at(ctx, offset + f.offset, value[f.name])
			end
		end,
		read = function(ctx)
			const offset = ctx.read(total_length)
			const result = {}
			for i = 1, #fields do
				local f = fields[i]
				result[f.name] = f.read_at(ctx, offset + f.offset)
			end
			return result
		end,
	} else {
		write = function(ctx, value)
			for _, k in keys do
				schema[k].write(ctx, value[k])
			end
		end,
		read = function(ctx)
			local result = {}
			for _, k in keys do
				result[k] = schema[k].read(ctx)
			end
			return result
		end,
	}
end

return struct
