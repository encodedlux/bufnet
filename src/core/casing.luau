type DefaultCase = "Snake"
export type Case = "Pascal" | "Camel" | "Snake"

export type function get_casing(case: type?)
	const casing = types.newtable()
	for k, options in Cases:properties() do
		if case and (case:is("string") or case:is("Singleton")) then
			casing:setproperty(k, options.read:readproperty(case))
		else
			casing:setproperty(k, options.read:readproperty(DefaultCase))
		end
	end
	return casing
end

const DEFAULT_CASE: DefaultCase = "Snake"

const function build_case<P, C, S>(pascal: P, camel: C, snake: S): { Pascal: P, Camel: C, Snake: S }
	return {
		Pascal = pascal,
		Camel = camel,
		Snake = snake,
	}
end

const cases = {
	flush = build_case("Flush" :: "Flush", "flush" :: "flush", "flush" :: "flush"),
	fire = build_case("Fire" :: "Fire", "fire" :: "fire", "fire" :: "fire"),
	fire_all = build_case("FireAll" :: "FireAll", "fireAll" :: "fireAll", "fire_all" :: "fire_all"),
	fire_list = build_case("FireList" :: "FireList", "fireList" :: "fireList", "fire_list" :: "fire_list"),
	fire_except = build_case(
		"FireExcept" :: "FireExcept",
		"fireExcept" :: "fireExcept",
		"fire_except" :: "fire_except"
	),
	invoke = build_case("Invoke" :: "Invoke", "invoke" :: "invoke", "invoke" :: "invoke"),
	on = build_case("On" :: "On", "on" :: "on", "on" :: "on"),
	iter = build_case("Iter" :: "Iter", "iter" :: "iter", "iter" :: "iter"),
	derive = build_case("Derive" :: "Derive", "derive" :: "derive", "derive" :: "derive"),
	set = build_case("Set" :: "Set", "set" :: "set", "set" :: "set"),
	filter = build_case("Filter" :: "Filter", "filter" :: "filter", "filter" :: "filter"),
	subscribe = build_case("Subscribe" :: "Subscribe", "subscribe" :: "subscribe", "subscribe" :: "subscribe"),
	listen = build_case("Listen" :: "Listen", "listen" :: "listen", "listen" :: "listen"),
	get = build_case("Get" :: "Get", "get" :: "get", "get" :: "get"),
}

type Cases = typeof(cases)

const function get_casing<C>(case: (C & Case)?): get_casing<C>
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
