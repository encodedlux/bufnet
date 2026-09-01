const types = require("../types")

const BYTE = 1
const SHORT = 2
const INTEGER = 4
const HALF_FLOAT = 2
const FLOAT = 4
const DOUBLE = 8

type NumberOptions = {
	min: number?,
	max: number?,
}

const function generate_number_data_type(
	size: number,
	write_fn: (b: buffer, offset: number, value: number) -> (),
	read_fn: (b: buffer, offset: number) -> number
)
	return @native function(options: NumberOptions?): types.DataType<number>
		return {
			write = @native function(ctx, value)
				const offset = ctx.alloc(size)
				write_fn(ctx.buff, offset, value)
			end,
			read = if options and (options.min or options.max)
				then @native function(ctx)
					const offset = ctx.read(size)
					const value = read_fn(ctx.buff, offset)
					if options.min and value < options.min then
						error(`[BufNet] Expected "value" to be larger than {options.min}, got {value} instead.`)
					end
					if options.max and value > options.max then
						error(`[BufNet] Expected "value" to be smaller than {options.max}, got {value} instead.`)
					end
					return value
				end
				else @native function(ctx)
					const offset = ctx.read(size)
					return read_fn(ctx.buff, offset)
				end,
		}
	end
end

return {
	BYTE = BYTE,
	SHORT = SHORT,
	INTEGER = INTEGER,
	HALF_FLOAT = HALF_FLOAT,
	FLOAT = FLOAT,
	DOUBLE = DOUBLE,

	generate_number_data_type = generate_number_data_type,
}
