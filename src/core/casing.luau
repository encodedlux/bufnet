type DefaultCase = "Snake"
export type Case = "Pascal" | "Camel" | "Snake"

export type function get_casing(case: type?)
	const casing = types.newtable()
	const is_valid = case and case:is("singleton")
	for k, options in Cases:properties() do
		if is_valid and options.read:readproperty(case) then
			casing:setproperty(k, options.read:readproperty(case))
		else
			casing:setproperty(k, options.read:readproperty(DefaultCase))
		end
	end
	return casing
end

const DEFAULT_CASE: DefaultCase = "Snake"

const function build_case<Pascal, Camel, Snake>(
	pascal: Pascal | "",
	camel: Camel | "",
	snake: Snake | ""
): { Pascal: Pascal, Camel: Camel, Snake: Snake }
	return {
		Pascal = pascal,
		Camel = camel,
		Snake = snake,
	}
end

const cases = {
	server = build_case("Server", "server", "server"),
	client = build_case("Client", "client", "client"),
	flush = build_case("Flush", "flush", "flush"),
	fire = build_case("Fire", "fire", "fire"),
	fire_all = build_case("FireAll", "fireAll", "fire_all"),
	fire_list = build_case("FireList", "fireList", "fire_list"),
	fire_except = build_case("FireExcept", "fireExcept", "fire_except"),
	invoke = build_case("Invoke", "invoke", "invoke"),
	on = build_case("On", "on", "on"),
	iter = build_case("Iter", "iter", "iter"),
	derive = build_case("Derive", "derive", "derive"),
	set = build_case("Set", "set", "set"),
	filter = build_case("Filter", "filter", "filter"),
	subscribe = build_case("Subscribe", "subscribe", "subscribe"),
	listen = build_case("Listen", "listen", "listen"),
	get = build_case("Get", "get", "get"),
}

type Cases = typeof(cases)

const function get_casing<C>(case: (C | Case)?): get_casing<C>
	const casing = {}
	for k, options in cases :: any do
		casing[k] = options[case or DEFAULT_CASE]
	end
	return casing :: any
end

return {
	cases = cases,
	get_casing = get_casing,
}
