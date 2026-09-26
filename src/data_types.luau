--!optimize 2

const Players = game:GetService("Players")

const constants = require("./constants")
const t = require("./types")

type DataType<T> = t.DataType<T>
type DataTypeValue<T> = t.DataTypeValue<T>
type DataTypeSchema<T> = t.DataTypeSchema<T>

const BYTE = 1
const SHORT = 2
const INTEGER = 4
const HALF_FLOAT = 2
const FLOAT = 4
const DOUBLE = 8

const ROOT_SCOPE_NAME = constants.ROOT_SCOPE_NAME

const null_ref = newproxy()

const writeu8, readu8 = buffer.writeu8, buffer.readu8
const writeu16, readu16 = buffer.writeu16, buffer.readu16
const writeu32, readu32 = buffer.writeu32, buffer.readu32
const writei8, readi8 = buffer.writei8, buffer.readi8
const writei16, readi16 = buffer.writei16, buffer.readi16
const writei32, readi32 = buffer.writei32, buffer.readi32
const writef32, readf32 = buffer.writef32, buffer.readf32
const writef64, readf64 = buffer.writef64, buffer.readf64
const buffer_create, buffer_copy, buffer_len, writestring, readstring =
	buffer.create, buffer.copy, buffer.len, buffer.writestring, buffer.readstring

const string_len = string.len

const function writef16(b: buffer, offset: number, value: number)
	if value > 65504 then
		writeu16(b, offset, 0b0_11111_0000000000)
	elseif value < -65504 then
		writeu16(b, offset, 0b1_11111_0000000000)
	elseif value ~= value then
		writeu16(b, offset, 0b0_11111_0000000001)
	elseif value == 0 then
		writeu16(b, offset, 0)
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

		writeu16(b, offset, result)
	end
end

const function readf16(b: buffer, offset: number): number
	const encoded = readu16(b, offset)
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

const function measure(size: number | ((any) -> number), value: any): number
	if type(size) == "number" then
		return size
	end
	return size(value)
end

const function create_data_type<T>(
	write_fn: (buff: buffer, offset: number, value: T, refs: { [any]: any }) -> number,
	read_fn: (buff: buffer, offset: number, refs: { [any]: any }) -> (number, T),
	size: ((value: T) -> number) | number
): DataType<T>
	return {
		__T = (nil :: any) :: T,
		write = write_fn,
		read = read_fn,
		size = size,
	}
end

const function refine<T>(value_type: DataType<T>, refine_fn: (value: T) -> (boolean, string?))
	const value_write = value_type.write
	const value_read = value_type.read
	const value_size = value_type.size

	return create_data_type<<T>>(value_write, @native function(buff, offset, refs)
		const size, value = value_read(buff, offset, refs)
		local success, reason = refine_fn(value)
		if not success then
			error(
				`[{ROOT_SCOPE_NAME}]: Failed to validate value '{tostring(value)}'{if reason then `: {reason}` else ""}`
			)
		end
		return size, value
	end, value_size)
end

const u8 = create_data_type<<number>>(@native function(buff, offset, value)
	writeu8(buff, offset, value)
	return BYTE
end, @native function(buff, offset)
	return BYTE, readu8(buff, offset)
end, BYTE)

const u16 = create_data_type<<number>>(@native function(buff, offset, value)
	writeu16(buff, offset, value)
	return SHORT
end, @native function(buff, offset)
	return SHORT, readu16(buff, offset)
end, SHORT)

const u32 = create_data_type<<number>>(@native function(buff, offset, value)
	writeu32(buff, offset, value)
	return INTEGER
end, @native function(buff, offset)
	return INTEGER, readu32(buff, offset)
end, INTEGER)

const i8 = create_data_type<<number>>(@native function(buff, offset, value)
	writei8(buff, offset, value)
	return BYTE
end, @native function(buff, offset)
	return BYTE, readi8(buff, offset)
end, BYTE)

const i16 = create_data_type<<number>>(@native function(buff, offset, value)
	writei16(buff, offset, value)
	return SHORT
end, @native function(buff, offset)
	return SHORT, readi16(buff, offset)
end, SHORT)

const i32 = create_data_type<<number>>(@native function(buff, offset, value)
	writei32(buff, offset, value)
	return INTEGER
end, @native function(buff, offset)
	return INTEGER, readi32(buff, offset)
end, INTEGER)

const f16 = create_data_type<<number>>(@native function(buff, offset, value)
	writef16(buff, offset, value)
	return HALF_FLOAT
end, @native function(buff, offset)
	return HALF_FLOAT, readf16(buff, offset)
end, HALF_FLOAT)

const f32 = create_data_type<<number>>(@native function(buff, offset, value)
	writef32(buff, offset, value)
	return FLOAT
end, @native function(buff, offset)
	return FLOAT, readf32(buff, offset)
end, FLOAT)

const f64 = create_data_type<<number>>(@native function(buff, offset, value)
	writef64(buff, offset, value)
	return DOUBLE
end, @native function(buff, offset)
	return DOUBLE, readf64(buff, offset)
end, DOUBLE)

const boolean = create_data_type<<boolean>>(@native function(buff, offset, value)
	writeu8(buff, offset, value and 1 or 0)
	return BYTE
end, @native function(buff, offset)
	return BYTE, readu8(buff, offset) == 1
end, BYTE)

const string_dt = create_data_type<<string>>(@native function(buff, offset, value)
	const len = string_len(value)
	writeu16(buff, offset, len)
	writestring(buff, offset + SHORT, value)
	return SHORT + len
end, @native function(buff, offset)
	const len = readu16(buff, offset)
	return SHORT + len, readstring(buff, offset + SHORT, len)
end, @native function(value: string)
	return SHORT + string_len(value)
end)

const buffer_dt = create_data_type<<buffer>>(@native function(buff, offset, value)
	const len = buffer_len(value)
	writeu16(buff, offset, len)
	buffer_copy(buff, offset + SHORT, value, 0, len)
	return SHORT + len
end, @native function(buff, offset)
	const len = readu16(buff, offset)
	local new_buff = buffer_create(len)
	buffer_copy(new_buff, 0, buff, offset + SHORT, len)
	return SHORT + len, new_buff
end, @native function(value: buffer)
	return SHORT + buffer_len(value)
end)

const vec2 = create_data_type<<Vector2>>(@native function(buff, offset, value)
	writef32(buff, offset, value.X)
	writef32(buff, offset + FLOAT, value.Y)
	return FLOAT * 2
end, @native function(buff, offset)
	return FLOAT * 2, Vector2.new(readf32(buff, offset), readf32(buff, offset + FLOAT))
end, FLOAT * 2)

const vec3 = create_data_type<<Vector3>>(@native function(buff, offset, value)
	writef32(buff, offset, value.X)
	writef32(buff, offset + FLOAT, value.Y)
	writef32(buff, offset + FLOAT * 2, value.Z)
	return FLOAT * 3
end, @native function(buff, offset)
	return FLOAT * 3,
		Vector3.new(readf32(buff, offset), readf32(buff, offset + FLOAT), readf32(buff, offset + FLOAT * 2))
end, FLOAT * 3)

const cframe = create_data_type<<CFrame>>(@native function(buff, offset, value)
	local x, y, z = value.X, value.Y, value.Z
	local axis, angle = value:ToAxisAngle()
	axis *= angle
	local rx, ry, rz = axis.X, axis.Y, axis.Z

	writef32(buff, offset, x)
	writef32(buff, offset + FLOAT, y)
	writef32(buff, offset + FLOAT * 2, z)
	writef32(buff, offset + FLOAT * 3, rx)
	writef32(buff, offset + FLOAT * 4, ry)
	writef32(buff, offset + FLOAT * 5, rz)

	return FLOAT * 6
end, @native function(buff, offset)
	local x = readf32(buff, offset)
	local y = readf32(buff, offset + FLOAT)
	local z = readf32(buff, offset + FLOAT * 2)
	local rx = readf32(buff, offset + FLOAT * 3)
	local ry = readf32(buff, offset + FLOAT * 4)
	local rz = readf32(buff, offset + FLOAT * 5)

	local axis = Vector3.new(rx, ry, rz)
	local angle = axis.Magnitude

	return FLOAT * 6,
		if angle ~= 0 then CFrame.new(x, y, z) * CFrame.fromAxisAngle(axis, angle) else CFrame.new(x, y, z)
end, FLOAT * 6)

const color3 = create_data_type<<Color3>>(@native function(buff, offset, value)
	writeu8(buff, offset, math.round(value.R * 255))
	writeu8(buff, offset + 1, math.round(value.G * 255))
	writeu8(buff, offset + 2, math.round(value.B * 255))
	return BYTE * 3
end, @native function(buff, offset)
	return BYTE * 3, Color3.fromRGB(readu8(buff, offset), readu8(buff, offset + 1), readu8(buff, offset + 2))
end, BYTE * 3)

const player = create_data_type<<Player>>(@native function(buff, offset, player)
	writef64(buff, offset, player.UserId)
	return DOUBLE
end, @native function(buff, offset)
	return DOUBLE, Players:GetPlayerByUserId(readf64(buff, offset)) :: any
end, DOUBLE)

const instance = create_data_type<<Instance>>(@native function(buff, offset, value, refs)
	table.insert(refs, value or null_ref)
	return 0
end, @native function(buff, offset, refs)
	refs.cursor += 1
	const instance: Instance = refs[refs.cursor]
	assert(typeof(instance) == "Instance", "Expected instance, but got " .. typeof(instance))
	return 0, instance
end, 0)

const unknown = create_data_type<<unknown>>(@native function(buff, offset, value, refs)
	table.insert(refs, value or null_ref)
	return 0
end, @native function(buff, offset, refs)
	refs.cursor += 1
	return 0, refs[refs.cursor]
end, 0)

const nothing = create_data_type<<nil>>(@native function(buff, offset, value)
	return 0
end, @native function(buff, offset)
	return 0, nil
end, 0)

const function optional<T>(value_type: DataType<T>)
	const value_write = value_type.write
	const value_read = value_type.read
	const value_size = value_type.size

	const size_fn = if type(value_size) == "number"
		then @native function(value)
			return if value == nil then BYTE else BYTE + value_size
		end
		else @native function(value)
			return if value == nil then BYTE else BYTE + value_size(value)
		end

	return create_data_type<<T?>>(@native function(buff, offset, value, refs)
		if value == nil then
			writeu8(buff, offset, 0)
			return BYTE
		end
		const length = value_write(buff, offset + BYTE, value, refs)
		writeu8(buff, offset, BYTE)
		return length + BYTE
	end, @native function(buff, offset, refs)
		const is_present = readu8(buff, offset)
		if is_present == 0 then
			return BYTE, nil
		end
		const length, value = value_read(buff, offset + BYTE, refs)
		return length + BYTE, value
	end, size_fn)
end

const function array<T>(value_type: DataType<T>)
	const value_write = value_type.write
	const value_read = value_type.read
	const value_size = value_type.size

	const size_fn = if type(value_size) == "number"
		then @native function(value: { T }): number
			return SHORT + value_size * #value
		end
		else @native function(value: { T }): number
			local total = SHORT
			for i = 1, #value do
				total += value_size(value[i])
			end
			return total
		end

	return create_data_type<<{ T }>>(@native function(buff, offset, value, refs)
		writeu16(buff, offset, #value)
		local current_offset = offset + SHORT
		for i = 1, #value do
			current_offset += value_write(buff, current_offset, value[i], refs)
		end
		return current_offset - offset
	end, @native function(buff, offset, refs)
		const array_length = readu16(buff, offset)
		assert(
			array_length <= 2000,
			`[{ROOT_SCOPE_NAME}]:Expected "array_length" to be smaller than 2000, got {array_length} instead.`
		)
		local current_offset = offset + SHORT
		const array = table.create(array_length)
		for i = 1, array_length do
			const length, value = value_read(buff, current_offset, refs)
			current_offset += length
			array[i] = value
		end
		return current_offset - offset, array
	end, size_fn)
end

const function struct<T>(schema: T & { read [string]: DataType<any> })
	const keys: { string } = {}
	const value_writes: { index<DataType<DataTypeSchema<T>>, "write"> } = {}
	const value_reads: { index<DataType<DataTypeSchema<T>>, "read"> } = {}
	const value_sizes: { index<DataType<DataTypeSchema<T>>, "size"> } = {}

	for key in schema :: any do
		keys[#keys + 1] = key
	end
	table.sort(keys)

	for idx, key in keys do
		value_writes[idx] = schema[key].write
		value_reads[idx] = schema[key].read
		value_sizes[idx] = schema[key].size
	end

	local fixed_total = 0
	const variable_indices = {}
	for i, s in value_sizes do
		if type(s) == "number" then
			fixed_total += s
		else
			table.insert(variable_indices, i)
		end
	end

	const size = if #variable_indices == 0
		then fixed_total
		else @native function(value)
			local total = fixed_total
			for i = 1, #variable_indices do
				const idx = variable_indices[i]
				total += (value_sizes[idx] :: any)(value[keys[idx]])
			end
			return total
		end

	return create_data_type<<DataTypeSchema<T>>>(@native function(buff, offset, value, refs)
		local current_offset = offset
		for i = 1, #value_writes do
			current_offset += value_writes[i](buff, current_offset, (value :: any)[keys[i]], refs)
		end
		return current_offset - offset
	end, @native function(buff, offset, refs)
		local current_offset = offset
		const data = {}
		for i = 1, #value_writes do
			const length, value = value_reads[i](buff, current_offset, refs)
			current_offset += length
			data[keys[i]] = value
		end
		return current_offset - offset, data :: any
	end, size)
end

const function map<K, V>(key_type: DataType<K>, value_type: DataType<V>)
	const key_write = key_type.write
	const key_read = key_type.read
	const key_size = key_type.size
	const value_write = value_type.write
	const value_read = value_type.read
	const value_size = value_type.size

	return create_data_type<<{ [K]: V }>>(@native function(buff, offset, value, refs)
		local current_offset = offset + SHORT
		local map_length = 0
		for k, v in value do
			map_length += 1
			current_offset += key_write(buff, current_offset, k, refs)
			current_offset += value_write(buff, current_offset, v, refs)
		end
		writeu16(buff, offset, map_length)
		return current_offset - offset
	end, @native function(buff, offset, refs)
		local current_offset = offset + SHORT
		const map_length = readu16(buff, offset)
		const result = {}
		for _ = 1, map_length do
			const key_length, key = key_read(buff, current_offset, refs)
			current_offset += key_length
			const val_length, value = value_read(buff, current_offset, refs)
			current_offset += val_length
			result[key] = value
		end
		return current_offset - offset, result
	end, @native function(value)
		local total = SHORT
		for k, v in value do
			total += measure(key_size, k) + measure(value_size, v)
		end
		return total
	end)
end

const function set<K>(key_type: DataType<K>)
	const key_write = key_type.write
	const key_read = key_type.read
	const key_size = key_type.size

	return create_data_type<<{ [K]: boolean }>>(@native function(buff, offset, value, refs)
		local current_offset = offset + SHORT
		local set_length = 0
		for k in value do
			set_length += 1
			current_offset += key_write(buff, current_offset, k, refs)
		end
		writeu16(buff, offset, set_length)
		return current_offset - offset
	end, @native function(buff, offset, refs)
		local current_offset = offset + SHORT
		const set_length = readu16(buff, offset)
		const result = {}
		for _ = 1, set_length do
			const key_length, key = key_read(buff, current_offset, refs)
			current_offset += key_length
			result[key] = true
		end
		return current_offset - offset, result
	end, @native function(value)
		local total = SHORT
		for k in value do
			total += measure(key_size, k)
		end
		return total
	end)
end

type function union_of_literals(ty: typeof(types.newfunction())): type
	const returns = ty:returns()
	const head = returns.head or {}
	local union = nil
	for i = 1, #head do
		const value_ty = head[i]
		union = if union then types.unionof(union, value_ty) else value_ty
	end
	if returns.tail then
		union = if union then types.unionof(union, returns.tail) else returns.tail
	end
	return if union then union else types.singleton(nil)
end

const function literals<T...>(...: T...)
	const values = table.pack(... :: any)
	const value_map: { [any]: number } = {}
	for i = 1, values.n do
		value_map[values[i]] = i
	end

	return create_data_type<<union_of_literals<() -> T...>>>(@native function(buff, offset, value)
		writeu8(buff, offset, value_map[value])
		return BYTE
	end, @native function(buff, offset)
		return BYTE, values[readu8(buff, offset)]
	end, BYTE)
end

type function tagged_type(ty: type, data_ty: type)
	data_ty:setproperty(types.singleton("type"), ty)
	return data_ty
end

type TaggedType<Type = string, Data = { [string]: any }> = tagged_type<Type, Data>

type function union_of_fields(ty: type)
	assert(ty:is("table"), "requires a table type")
	local union = nil
	for tag, v in ty:properties() do
		const fields = v.read
		assert(fields and fields:is("table"), "requires a table value")
		const tagged_fields = TaggedType(tag, DataTypeSchema(fields))
		union = if union then types.unionof(union, tagged_fields) else tagged_fields
	end
	return if union then union else types.singleton(nil)
end

const function tagged<T>(definition: T & { read [string]: { read [string]: DataType<any> } })
	const struct_values: { [string]: DataType<any> } = {}
	const tags: { string } = {}
	for tag, variant_def in definition :: any do
		table.insert(tags, tag)
		if type(variant_def) == "table" and not variant_def.write then
			struct_values[tag] = (struct :: any)(variant_def)
		end
	end
	table.sort(tags)

	const tag_to_index = {}
	for i, tag in tags do
		tag_to_index[tag] = i
	end

	return create_data_type<<union_of_fields<T>>>(@native function(buff, offset, value: TaggedType, refs)
		const tag = value.type
		const tag_index = tag_to_index[tag]
		writeu8(buff, offset, tag_index)
		const length = struct_values[tag].write(buff, offset + 1, value, refs)
		return length + 1
	end, @native function(buff, offset, refs)
		const tag_index = readu8(buff, offset)
		const tag = tags[tag_index]
		const length, struct_val = struct_values[tag].read(buff, offset + 1, refs)
		struct_val.type = tag
		return length + 1, struct_val
	end, @native function(value: TaggedType)
		return BYTE + measure(struct_values[value.type].size, value)
	end)
end

type TupleFn =
	(<A>(DataType<A>) -> () -> DataType<A>)
	& (<A, B>(DataType<A>, DataType<B>) -> () -> (DataType<A>, DataType<B>))
	& (<A, B, C>(DataType<A>, DataType<B>, DataType<C>) -> () -> (DataType<A>, DataType<B>, DataType<C>))
	& (<A, B, C, D>(
		DataType<A>,
		DataType<B>,
		DataType<C>,
		DataType<D>
	) -> () -> (DataType<A>, DataType<B>, DataType<C>, DataType<D>))
	& (<A, B, C, D, E>(
		DataType<A>,
		DataType<B>,
		DataType<C>,
		DataType<D>,
		DataType<E>
	) -> () -> (DataType<A>, DataType<B>, DataType<C>, DataType<D>, DataType<E>))
	& (<A, B, C, D, E, F>(
		DataType<A>,
		DataType<B>,
		DataType<C>,
		DataType<D>,
		DataType<E>,
		DataType<F>
	) -> () -> (DataType<A>, DataType<B>, DataType<C>, DataType<D>, DataType<E>, DataType<F>))
	& (<A, B, C, D, E, F, G>(
		DataType<A>,
		DataType<B>,
		DataType<C>,
		DataType<D>,
		DataType<E>,
		DataType<F>,
		DataType<G>
	) -> () -> (DataType<A>, DataType<B>, DataType<C>, DataType<D>, DataType<E>, DataType<F>, DataType<G>))
	& (<A, B, C, D, E, F, G, H>(
		DataType<A>,
		DataType<B>,
		DataType<C>,
		DataType<D>,
		DataType<E>,
		DataType<F>,
		DataType<G>,
		DataType<H>
	) -> () -> (DataType<A>, DataType<B>, DataType<C>, DataType<D>, DataType<E>, DataType<F>, DataType<G>, DataType<H>))
	& (<A, B, C, D, E, F, G, H, I>(
		DataType<A>,
		DataType<B>,
		DataType<C>,
		DataType<D>,
		DataType<E>,
		DataType<F>,
		DataType<G>,
		DataType<H>,
		DataType<I>
	) -> (
	) -> (
		DataType<A>,
		DataType<B>,
		DataType<C>,
		DataType<D>,
		DataType<E>,
		DataType<F>,
		DataType<G>,
		DataType<H>,
		DataType<I>
	))
	& (<A, B, C, D, E, F, G, H, I, J>(
		DataType<A>,
		DataType<B>,
		DataType<C>,
		DataType<D>,
		DataType<E>,
		DataType<F>,
		DataType<G>,
		DataType<H>,
		DataType<I>,
		DataType<J>
	) -> (
	) -> (
		DataType<A>,
		DataType<B>,
		DataType<C>,
		DataType<D>,
		DataType<E>,
		DataType<F>,
		DataType<G>,
		DataType<H>,
		DataType<I>,
		DataType<J>
	))
	& ((...DataType<any>) -> () -> ...DataType<any>)

const tuple: TupleFn = function(...)
	const args = { ... }
	return @native function()
		return table.unpack(args)
	end
end

return {
	create = create_data_type,
	refine = refine,

	null_ref = null_ref,

	-- primitives
	u8 = u8,
	u16 = u16,
	u32 = u32,
	i8 = i8,
	i16 = i16,
	i32 = i32,
	f16 = f16,
	f32 = f32,
	f64 = f64,
	boolean = boolean,
	string = string_dt,
	buffer = buffer_dt,
	vec2 = vec2,
	vec3 = vec3,
	cframe = cframe,
	color3 = color3,
	player = player,
	instance = instance,
	unknown = unknown,
	nothing = nothing,

	-- specials
	optional = optional,
	array = array,
	struct = struct,
	map = map,
	set = set,
	literals = literals,
	tagged = tagged,
	tuple = tuple,
}
