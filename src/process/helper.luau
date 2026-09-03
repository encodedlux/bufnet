--!native
--!optimize 2

const types = require("../types")

const BYTE = 1
const SHORT = 2
const INTEGER = 4
const HALF_FLOAT = 2
const FLOAT = 4
const DOUBLE = 8

const function generate_number_data_type(
	size: number,
	write_fn: (b: buffer, offset: number, value: number) -> (),
	read_fn: (b: buffer, offset: number) -> number
)
	const num: types.DataType<number> = {
		write = function(ctx, value)
			const offset = ctx.alloc(size)
			write_fn(ctx.buff, offset, value)
		end,
		read = function(ctx)
			const offset = ctx.read(size)
			return read_fn(ctx.buff, offset)
		end,

		length = size,
		write_at = function(ctx, offset, value)
			write_fn(ctx.buff, offset, value)
		end,
		read_at = function(ctx, offset)
			return read_fn(ctx.buff, offset)
		end,
	}

	return function()
		return num
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
