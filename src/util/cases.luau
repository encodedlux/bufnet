export type function ToSnakeCase(ty: type): type
	if ty:is("singleton") or ty:is("singletonstring") then
		const val = ty:value()
		if typeof(val) == "string" then
			const res = val:gsub("(%u+)(%u%l)", "%1_%2"):gsub("(%l)(%u)", "%1_%2"):gsub("[%s-]+", "_"):lower()
			return types.singleton(res)
		end
	end
	return types.string
end

export type function ToPascalCase(ty: type): type
	if ty:is("singleton") or ty:is("singletonstring") then
		const val = ty:value()
		if typeof(val) == "string" then
			const snake = val:gsub("(%u+)(%u%l)", "%1_%2"):gsub("(%l)(%u)", "%1_%2"):gsub("[%s-]+", "_"):lower()
			const with_caps = snake:gsub("_(%l)", function(c)
				return c:upper()
			end)
			const pascal = with_caps:sub(1, 1):upper() .. with_caps:sub(2)
			return types.singleton(pascal)
		end
	end
	return types.string
end

export type function ToCamelCase(ty: type): type
	if ty:is("singleton") or ty:is("singletonstring") then
		const val = ty:value()
		if typeof(val) == "string" then
			const snake = val:gsub("(%u+)(%u%l)", "%1_%2"):gsub("(%l)(%u)", "%1_%2"):gsub("[%s-]+", "_"):lower()
			const with_caps = snake:gsub("_(%l)", function(c)
				return c:upper()
			end)
			const camel = with_caps:sub(1, 1):lower() .. with_caps:sub(2)
			return types.singleton(camel)
		end
	end
	return types.string
end

export type function ToCase(str_ty: type, case_ty: type): type
	if case_ty:is("singleton") or case_ty:is("singletonstring") then
		const case_val = case_ty:value()
		if case_val == "Camel" then
			return ToCamelCase(str_ty)
		elseif case_val == "Snake" then
			return ToSnakeCase(str_ty)
		else
			return ToPascalCase(str_ty)
		end
	end
	return types.string
end

export type Case = "Pascal" | "Camel" | "Snake"

const function to_snake_case<T>(str: T): ToSnakeCase<T>
	return (str :: any):gsub("(%u+)(%u%l)", "%1_%2"):gsub("(%l)(%u)", "%1_%2"):gsub("[%s-]+", "_"):lower() :: any
end

const function to_pascal_case<T>(str: T): ToPascalCase<T>
	const snake = to_snake_case(str :: any) :: any
	const with_caps = snake:gsub("_(%l)", function(c)
		return c:upper()
	end)
	return (with_caps:sub(1, 1):upper() .. with_caps:sub(2)) :: any
end

const function to_camel_case<T>(str: T): ToCamelCase<T>
	const snake = to_snake_case(str :: any) :: any
	const with_caps = snake:gsub("_(%l)", function(c)
		return c:upper()
	end)
	return (with_caps:sub(1, 1):lower() .. with_caps:sub(2)) :: any
end

const function to_case<T, C>(str: T, case_format: C & Case): ToCase<T, C>
	if case_format == "Camel" then
		return to_camel_case(str :: any) :: any
	elseif case_format == "Snake" then
		return to_snake_case(str :: any) :: any
	else
		return to_pascal_case(str :: any) :: any
	end
end

return {
	to_snake_case = to_snake_case,
	to_pascal_case = to_pascal_case,
	to_camel_case = to_camel_case,
	to_case = to_case,
}
