--!native
--!optimize 2

const helper = require("../process/helper")

const function write_f16(b: buffer, offset: number, value: number)
	if value > 65504 then
		buffer.writeu16(b, offset, 0b0_11111_0000000000)
	elseif value < -65504 then
		buffer.writeu16(b, offset, 0b1_11111_0000000000)
	elseif value ~= value then
		buffer.writeu16(b, offset, 0b0_11111_0000000001)
	elseif value == 0 then
		buffer.writeu16(b, offset, 0)
	else
		const absValue = math.abs(value)
		const interval = math.ldexp(1, math.floor(math.log(absValue, 2)) - 10)
		const rounded_value = (absValue // interval) * interval
		local fraction, exponent = math.frexp(rounded_value)
		exponent += 14
		const mantissa = math.round(
			if exponent <= 0 then fraction * 0x400 / math.ldexp(1, math.abs(exponent)) else fraction * 0x800
		) % 0x400

		const result = mantissa + math.max(exponent, 0) * 0x400 + if value < 0 then 0x8000 else 0

		buffer.writeu16(b, offset, result)
	end
end

const function read_f16(b: buffer, offset: number): number
	const encoded = buffer.readu16(b, offset)
	const mantissa_exponent = encoded % 0x8000

	if mantissa_exponent == 0b0_11111_0000000000 then
		return if encoded // 0x8000 == 1 then -math.huge else math.huge
	elseif mantissa_exponent > 0b0_11111_0000000000 then
		return 0 / 0
	elseif mantissa_exponent == 0 then
		return 0
	else
		const mantissa = mantissa_exponent % 0x400
		const exponent = mantissa_exponent // 0x400
		local fraction
		if exponent == 0 then
			fraction = mantissa / 0x400
		else
			fraction = mantissa / 0x800 + 0.5
		end
		const result = math.ldexp(fraction, exponent - 14)
		return if encoded // 0x8000 == 1 then -result else result
	end
end

return helper.generate_number_data_type(helper.HALF_FLOAT, write_f16, read_f16)
