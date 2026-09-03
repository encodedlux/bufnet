--!native
--!optimize 2

const t = require("../types")

const struct = require("./struct")

type DataTypeSchema<T> = t.DataTypeSchema<T>

type UnitEnum = (enum_type: "Unit", definitions: { string }) -> t.DataType<string>

const function unit_enum(definitions: { string }): t.DataType<string>
	const value_to_index = {}
	const index_to_value = {}
	for i, v in definitions do
		value_to_index[v] = i
		index_to_value[i] = v
	end

	const function write_at(ctx, offset, value)
		const index = value_to_index[value]
		buffer.writeu8(ctx.buff, offset, index)
	end

	const function read_at(ctx, offset)
		const index = buffer.readu8(ctx.buff, offset)
		return index_to_value[index]
	end

	return {
		write =  function(ctx, value)
			const offset = ctx.alloc(1)
			write_at(ctx, offset, value)
		end,
		read =  function(ctx)
			const offset = ctx.read(1)
			return read_at(ctx, offset)
		end,
		length = 1,
		write_at = write_at,
		read_at = read_at,
	}
end

type function make_tagged_enum_type(ty: type, data_ty: type)
	const tbl = types.newtable()
	tbl:setproperty(types.singleton("type"), ty)
	for k, v in data_ty:properties() do
		assert(typeof(k:value()) == "string", "key must be a string")
		tbl:setproperty(k, v.read)
	end
	return tbl
end

type TaggedEnumType<Type = string, Data = {[string]: t.DataType<any>}> = make_tagged_enum_type<Type, Data>

type function union_of_fields(ty: type)
	assert(ty:is("table"), "requires a table type")

	local union = nil

    for tag, v in ty:properties() do
		const fields = v.read
		assert(fields and fields:is("table"), "requires a table value")
		const tagged_fields = TaggedEnumType(tag, DataTypeSchema(fields))
        union = if union then types.unionof(union, tagged_fields) else tagged_fields
    end

    return if union then union else types.singleton(nil)
end


type TaggedEnum = <T>(enum_type: "Tagged", definition: T) -> t.DataType<union_of_fields<T>>

const function tagged_enum(definition: any): t.DataType<TaggedEnumType>
	const struct_values: {[string]: t.DataType<any>} = {}
	const tags = {}
	for tag, variant_def in definition do
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

	return {
		write =  function(ctx, value)
			const tag = value.type
			const tag_index = tag_to_index[tag]

			const offset = ctx.alloc(1)
			buffer.writeu8(ctx.buff, offset, tag_index)

			struct_values[tag].write(ctx, value)
		end,
		read =  function(ctx)
			const offset = ctx.read(1)
			const tag_index = buffer.readu8(ctx.buff, offset)
			const tag = tags[tag_index]

			const struct_val = struct_values[tag].read(ctx)
			struct_val.type = tag

			return struct_val
		end,
	}
end

const function enum(enum_type: "Unit" | "Tagged", ...): t.DataType<any>
	if enum_type == "Unit" then
		return unit_enum(...)
	else
		return tagged_enum(...)
	end
end

return enum :: UnitEnum & TaggedEnum
