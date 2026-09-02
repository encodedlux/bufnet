--!nolint LocalShadow

export type BufferSave = {
	size: number,
	cursor: number,
	buff: buffer,
	refs: { any },
}

export type Writter = {
	size: number,
	cursor: number,
	offset: number,
	buff: buffer,
	refs: { any },

	alloc: (bytes: number) -> number,
	save: (out: BufferSave?) -> BufferSave,
	load: (save: BufferSave?) -> (),
	add_ref: (ref: any) -> (),
	append: (save: BufferSave) -> (),
}

export type Reader = {
	buff: buffer,
	cursor: number,
	refs: { any },
	refs_cursor: number,

	load: (new_b: buffer, new_refs: { any }?) -> (),
	read: (size: number) -> number,
	read_ref: () -> any,
}

export type DataType<T...> = {
	write: (ctx: Writter, T...) -> (),
	read: (ctx: Reader) -> T...,
}

export type function DataTypeValue(ty: type)
	const read_fn: type? = ty:readproperty(types.singleton("read"))
	assert(read_fn and read_fn:is("function"), "expected a function")
	const returns = read_fn:returns()
	return returns.head and returns.head[1]
end

export type function DataTypeSchema(fields: type)
	assert(fields:is("table"), "expected a table")
	local result = types.newtable()
	for key, property in fields:properties() do
		result:setproperty(key, DataTypeValue(property.read))
	end
	return result
end

type function data_type_input(ty: type): type
	const read: type? = ty:readproperty(types.singleton("read"))
	assert(read and read:is("function"), "expected a function")
	const returns = read:returns()
	local head = returns.head or {}
	return types.newfunction({ head = {} }, { head = head, tail = returns.tail })
end

export type EventFrom = "Server" | "Client"
export type EventCall = "SingleAsync" | "ManyAsync" | "SingleSync" | "ManySync" | "Polling"
export type EventType = "Reliable" | "Unreliable"

export type EventProps<T... = ...unknown> = {
	read from: EventFrom,
	read type: EventType?,
	read call: EventCall?,
	read value: DataType<T...>,
}

export type FunctProps<T... = ...unknown, R... = ...unknown> = {
	read value: DataType<T...>,
	read returns: DataType<R...>,
}

export type Case = "Pascal" | "Camel" | "Snake"

export type DefOptions = {
	read casing: Case?,
	read default_call: EventCall?,
	read auto_flush: (true | false)?,
}

type SinglePlayer = Player
type PlayersList = { Player }

type function get_player_types()
	return SinglePlayer, PlayersList
end

type function build_fire_from_server(returns)
	const player_type, players_list_type = get_player_types()
	const head: { any } = returns.head or {}
	-- fire: (player: Player, T...) -> ()
	const fire_head: { any } = { player_type }
	table.move(head, 1, #head, #fire_head + 1, fire_head)
	const fire_fn = types.newfunction({ head = fire_head, tail = returns.tail }, { head = {} })
	-- fire_all: (T...) -> ()
	const fire_all_fn = types.newfunction({ head = head, tail = returns.tail }, { head = {} })
	-- fire_list: (players: { Player }, T...) -> ()
	const list_head: { any } = { players_list_type }
	table.move(head, 1, #head, #list_head + 1, list_head)
	const fire_list_fn = types.newfunction({ head = list_head, tail = returns.tail }, { head = {} })
	-- fire_except: (player: Player, T...) -> ()
	const fire_except_fn = types.newfunction({ head = fire_head, tail = returns.tail }, { head = {} })
	const tbl = types.newtable()
	tbl:setproperty(types.singleton("fire"), fire_fn)
	tbl:setproperty(types.singleton("fire_all"), fire_all_fn)
	tbl:setproperty(types.singleton("fire_list"), fire_list_fn)
	tbl:setproperty(types.singleton("fire_except"), fire_except_fn)
	return tbl
end

type function build_listen_from_server(returns)
	const player_type = get_player_types()
	const head: { any } = returns.head or {}
	-- callback: (player: Player, T...) -> ()
	const cb_head: { any } = { player_type }
	table.move(head, 1, #head, #cb_head + 1, cb_head)
	const cb_fn = types.newfunction({ head = cb_head, tail = returns.tail }, { head = {} })
	-- disconnect: () -> ()
	const disconnect_fn = types.newfunction({ head = {} }, { head = {} })
	-- on: (callback) -> disconnect
	const on_fn = types.newfunction({ head = { cb_fn } }, { head = { disconnect_fn } })
	const tbl = types.newtable()
	tbl:setproperty(types.singleton("on"), on_fn)
	return tbl
end

type function build_iter_from_server(returns)
	const player_type = get_player_types()
	const head: { any } = returns.head or {}
	-- next: () -> (number, Player, T...)
	const iter_ret_head: { any } = { types.number, player_type }
	table.move(head, 1, #head, #iter_ret_head + 1, iter_ret_head)
	const next_fn = types.newfunction({ head = {} }, { head = iter_ret_head, tail = returns.tail })
	-- iter: () -> next
	const iter_fn = types.newfunction({ head = {} }, { head = { next_fn } })
	const tbl = types.newtable()
	tbl:setproperty(types.singleton("iter"), iter_fn)
	return tbl
end

type function build_fire_from_client(returns)
	-- fire: (T...) -> ()
	const fire_fn = types.newfunction({ head = returns.head, tail = returns.tail }, { head = {} })
	const tbl = types.newtable()
	tbl:setproperty(types.singleton("fire"), fire_fn)
	return tbl
end

type function build_listen_from_client(returns)
	-- callback: (T...) -> ()
	const cb_fn = types.newfunction({ head = returns.head, tail = returns.tail }, { head = {} })
	-- disconnect: () -> ()
	const disconnect_fn = types.newfunction({ head = {} }, { head = {} })
	-- on: (callback) -> disconnect
	const on_fn = types.newfunction({ head = { cb_fn } }, { head = { disconnect_fn } })
	const tbl = types.newtable()
	tbl:setproperty(types.singleton("on"), on_fn)
	return tbl
end

type function build_iter_from_client(returns)
	const head: { any } = returns.head or {}
	-- next: () -> (number, T...)
	const iter_ret_head: { any } = { types.number }
	table.move(head, 1, #head, #iter_ret_head + 1, iter_ret_head)
	const next_fn = types.newfunction({ head = {} }, { head = iter_ret_head, tail = returns.tail })
	-- iter: () -> next
	const iter_fn = types.newfunction({ head = {} }, { head = { next_fn } })
	const tbl = types.newtable()
	tbl:setproperty(types.singleton("iter"), iter_fn)
	return tbl
end

export type function build_event_server(props: type, options: type, input: typeof(types.newfunction()))
	const input_returns = input:returns()

	const from = read_property(props, "from")
	const call = read_property(props, "call")
	const default_call = read_property(options, "default_call")
	const polling = (call == types.singleton("Polling")) or (default_call == types.singleton("Polling"))

	if from == types.singleton("Server") then
		return build_fire_from_server(input_returns)
	elseif from == types.singleton("Client") then
		if polling then
			return build_iter_from_server(input_returns)
		end
		return build_listen_from_server(input_returns)
	end
	return types.intersectionof(
		build_fire_from_server(input_returns),
		build_listen_from_server(input_returns),
		build_iter_from_server(input_returns)
	)
end

export type function build_event_client(props: type, options: type, input: typeof(types.newfunction()))
	const input_returns = input:returns()

	const from = read_property(props, "from")
	const call = read_property(props, "call")
	const default_call = read_property(options, "default_call")
	const polling = (call == types.singleton("Polling")) or (default_call == types.singleton("Polling"))

	if from == types.singleton("Server") then
		if polling then
			return build_iter_from_client(input_returns)
		end
		return build_listen_from_client(input_returns)
	elseif from == types.singleton("Client") then
		return build_fire_from_client(input_returns)
	end
	return types.intersectionof(
		build_fire_from_client(input_returns),
		build_listen_from_client(input_returns),
		build_iter_from_client(input_returns)
	)
end

export type EventServer<Props, Options, T...> = build_event_server<Props, Options, () -> T...>
export type EventClient<Props, Options, T...> = build_event_client<Props, Options, () -> T...>

export type Event<Props = EventProps, Options = DefOptions, T... = ...unknown> = {
	type: "event",
	props: Props, -- only for type checking
	server: (options: Options) -> EventServer<Props, Options, T...>,
	client: (options: Options) -> EventClient<Props, Options, T...>,
}

export type FunctServer<T..., R...> = {
	on: (callback: (player: Player, T...) -> R...) -> (),
}
export type FunctClient<T..., R...> = {
	invoke: (T...) -> R...,
}

export type Funct<T... = ...unknown, R... = ...unknown> = {
	type: "function",
	server: (options: DefOptions) -> FunctServer<T..., R...>,
	client: (options: DefOptions) -> FunctClient<T..., R...>,
}

type function read_property(t: type?, name: string): type?
	if not t or not t:is("table") then
		return nil
	end
	return t:readproperty(types.singleton(name))
end

type function format_interface_casing(c: type, tbl: type)
	const casing = get_casing(c)
	const new_table = types.newtable()
	for k, prop in tbl:properties() do
		new_table:setproperty(casing:readproperty(k), prop.read or prop.write)
	end
	return new_table
end

type function resolve_objects(objects: type, options: type, is_server: boolean)
	assert(objects:is("table"), "Expected a table")

	const casing = read_property(options, "casing") or types.singleton(DefaultCase)
	const auto_flush = read_property(options, "auto_flush")

	const build_event = is_server and build_event_server or build_event_client

	const function resolve_objects_recursive(t: type): type
		if t:is("table") then
			const kind = read_property(t, "type")
			local ret
			if kind == types.singleton("event") then
				const props = read_property(t, "props")
				const value = props and read_property(props, "value")
				ret = value and build_event(props, options, data_type_input(value))
			else
				const fn = read_property(t, is_server and "server" or "client")
				const returns = fn and fn:returns()
				ret = returns and returns.head and returns.head[1]
			end
			if ret then
				return format_interface_casing(casing, ret)
			end

			const new = types.newtable()
			for k, prop in t:properties() do
				if prop.read then
					new:setproperty(k, resolve_objects_recursive(prop.read))
				end
			end
			return new
		end

		return t
	end

	const returns = resolve_objects_recursive(objects)
	if auto_flush == types.singleton(false) then
		returns:setproperty(get_casing(casing):readproperty(types.singleton("flush")), types.newfunction())
	end
	return returns
end

export type function ServerObjects(objects: type, options: type)
	return resolve_objects(objects, options, true)
end

export type function ClientObjects(objects: type, options: type)
	return resolve_objects(objects, options, false)
end

export type Def<Objects, Options> = {
	server: () -> ServerObjects<Objects, Options>,
	client: () -> ClientObjects<Objects, Options>,
}

const function build_case<P, C, S>(pascal: P, camel: C, snake: S): { Pascal: P, Camel: C, Snake: S }
	return {
		Pascal = pascal,
		Camel = camel,
		Snake = snake,
	}
end

const cases = {
	on = build_case("On" :: "On", "on" :: "on", "on" :: "on"),
	invoke = build_case("Invoke" :: "Invoke", "invoke" :: "invoke", "invoke" :: "invoke"),
	fire = build_case("Fire" :: "Fire", "fire" :: "fire", "fire" :: "fire"),
	fire_all = build_case("FireAll" :: "FireAll", "fireAll" :: "fireAll", "fire_all" :: "fire_all"),
	fire_list = build_case("FireList" :: "FireList", "fireList" :: "fireList", "fire_list" :: "fire_list"),
	fire_except = build_case(
		"FireExcept" :: "FireExcept",
		"fireExcept" :: "fireExcept",
		"fire_except" :: "fire_except"
	),
	flush = build_case("Flush" :: "Flush", "flush" :: "flush", "flush" :: "flush"),
	iter = build_case("Iter" :: "Iter", "iter" :: "iter", "iter" :: "iter"),
}

type Cases = typeof(cases)

export type function get_casing(case: type)
	const casing = types.newtable()
	for k, options in Cases:properties() do
		casing:setproperty(k, options.read:readproperty(case))
	end
	return casing
end

const function get_casing<C>(case: C & Case): get_casing<C>
	const casing = {}
	for k, options in cases :: any do
		casing[k] = options[case]
	end
	return casing :: any
end

export type DefaultCase = "Snake"
export type DefaultCall = "SingleAsync"

return {
	cases = cases,

	default_case = "Snake" :: DefaultCase,
	default_call = "SingleAsync" :: DefaultCall,

	get_casing = get_casing,
}
