const types = require("../types")

type ArrayOptions = {
	min: number?,
	max: number?,
}

@native
const function array<T>(value_type: types.DataType<T>, options: ArrayOptions?): types.DataType<{ T }>
	const value_write = value_type.write
	const value_read = value_type.read

	return {
		write = @native function(ctx, value)
			const length = #value
			const offset = ctx.alloc(2)
			buffer.writeu16(ctx.buff, offset, length)

			for i = 1, length do
				value_write(ctx, value[i])
			end
		end,
		read = @native function(ctx)
			const offset = ctx.read(2)
			const array_length = buffer.readu16(ctx.buff, offset)

			if options and options.min and array_length < options.min then
				error(`[BufNet] Expected array length to be larger than {options.min}, got {array_length} instead.`)
			end
			if options and options.max and array_length > options.max then
				error(`[BufNet] Expected array length to be smaller than {options.max}, got {array_length} instead.`)
			end

			const array = table.create(array_length)
			for i = 1, array_length do
				array[i] = value_read(ctx)
			end
			return array
		end,
	}
end

return array
