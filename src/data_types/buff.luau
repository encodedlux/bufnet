const types = require("../types")

const BYTE_SIZE = 2

type BuffOptions = {
	min: number?,
	max: number?,
}

@native
const function buff(options: BuffOptions?): types.DataType<buffer>
	return {
		write = @native function(ctx, value)
			const length = buffer.len(value)
			const offset = ctx.alloc(BYTE_SIZE + length)
			buffer.writeu16(ctx.buff, offset, length)
			buffer.copy(ctx.buff, offset + BYTE_SIZE, value, 0, length)
		end,
		read = if options
			then @native function(ctx)
				const offset = ctx.read(BYTE_SIZE)
				const length = buffer.readu16(ctx.buff, offset)
				if options.min and length < options.min then
					error(`[BufNet] Expected buffer length to be larger than {options.min}, got {length} instead.`)
				end
				if options.max and length > options.max then
					error(`[BufNet] Expected buffer length to be smaller than {options.max}, got {length} instead.`)
				end
				ctx.read(length)
				const new_buff = buffer.create(length)
				buffer.copy(new_buff, 0, ctx.buff, offset + BYTE_SIZE, length)
				return new_buff
			end
			else @native function(ctx)
				const offset = ctx.read(BYTE_SIZE)
				const length = buffer.readu16(ctx.buff, offset)
				ctx.read(length)
				const new_buff = buffer.create(length)
				buffer.copy(new_buff, 0, ctx.buff, offset + BYTE_SIZE, length)
				return new_buff
			end,
	}
end

return buff
