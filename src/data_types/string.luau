const types = require("../types")

const BYTE_SIZE = 2

type StringOptions = {
	min: number?,
	max: number?,
}

@native
const function str(options: StringOptions?): types.DataType<string>
	return {
		write = @native function(ctx, value)
			const length = #value
			const offset = ctx.alloc(BYTE_SIZE + length)
			buffer.writeu16(ctx.buff, offset, length)
			buffer.writestring(ctx.buff, offset + BYTE_SIZE, value, length)
		end,
		read = if options
			then @native function(ctx)
				const offset = ctx.read(BYTE_SIZE)
				const length = buffer.readu16(ctx.buff, offset)
				if options.min and length < options.min then
					error(`[BufNet] Expected string length to be larger than {options.min}, got {length} instead.`)
				end
				if options.max and length > options.max then
					error(`[BufNet] Expected string length to be smaller than {options.max}, got {length} instead.`)
				end
				ctx.read(length)
				const value = buffer.readstring(ctx.buff, offset + BYTE_SIZE, length)
				return value
			end
			else @native function(ctx)
				const offset = ctx.read(BYTE_SIZE)
				const length = buffer.readu16(ctx.buff, offset)
				ctx.read(length)
				const value = buffer.readstring(ctx.buff, offset + BYTE_SIZE, length)
				return value
			end,
	}
end

return str
