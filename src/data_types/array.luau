--!native
--!optimize 2

const types = require("../types")

const function array_generic<T>(value_type: types.DataType<T>): types.DataType<{ T }>
	const value_write = value_type.write
	const value_read = value_type.read

	return {
		write = function(ctx, value)
			const length = #value
			const offset = ctx.alloc(2)
			buffer.writeu16(ctx.buff, offset, length)
			for i = 1, length do
				value_write(ctx, value[i])
			end
		end,
		read = function(ctx)
			const offset = ctx.read(2)
			const array_length = buffer.readu16(ctx.buff, offset)
			const array = table.create(array_length)
			for i = 1, array_length do
				array[i] = value_read(ctx)
			end
			return array
		end,
	}
end

const function array_len<T>(value_type: types.DataType<T>): types.DataType<{ T }>
	const value_write_at = value_type.write_at :: (buff: buffer, offset: number, value: T) -> ()
	const value_read_at = value_type.read_at :: (buff: buffer, offset: number) -> T
	const length = value_type.length :: number

	return {
		write = function(ctx, value)
			const array_length = #value
			const offset = ctx.alloc(2 + array_length * length)
			const buff = ctx.buff
			buffer.writeu16(buff, offset, array_length)
			for i = 1, array_length do
				value_write_at(buff, (offset + 2) + (i - 1) * length, value[i])
			end
		end,
		read = function(ctx)
			const offset = ctx.read(2)
			const buff = ctx.buff
			const array_length = buffer.readu16(buff, offset)
			const array_offset = ctx.read(array_length * length)
			const array = table.create(array_length)
			for i = 1, array_length do
				array[i] = value_read_at(buff, array_offset + (i - 1) * length)
			end
			return array
		end,
	}
end

const function array<T>(value_type: types.DataType<T>): types.DataType<{ T }>
	return if value_type.length
			and value_type.write_at
			and value_type.read_at
		then array_len(value_type)
		else array_generic(value_type)
end

return array
