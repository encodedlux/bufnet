const casing = require("./core/casing")

export type Case = casing.Case
export type get_casing<T> = casing.get_casing<T>

export type DataType<T = unknown> = {
	read __T: T,
	read write: (buff: buffer, offset: number, value: T, refs: { [any]: any }) -> number,
	read read: (buff: buffer, offset: number, refs: { [any]: any }) -> (number, T),
	read size: number | (value: T) -> number,
}

export type DataTypeValue<T> = index<T, "__T">

export type function DataTypeSchema(schema: type)
	assert(schema:is("table"), "expected a table")
	local result = types.newtable()
	for key, value in schema:properties() do
		if value.read then
			result:setproperty(key, DataTypeValue(value.read))
		end
	end
	return result
end

export type function SelectTupleValue(i: type, ty: type)
	assert(ty:is("function"), "expected a t.tuple")
	const returns = ty:returns()
	if i == types.singleton("#") then
		return types.singleton(tostring(#(returns.head or {})))
	end
	const pos = assert(i and i:is("singleton") and tonumber(i:value()), "expected a pos selection")
	const arg_ty = (returns.head and returns.head[pos :: any]) :: type
	assert(arg_ty, "pos selection is out of bounds")
	return DataTypeValue(arg_ty)
end

type function data_type_input(ty: type)
	if not ty then
		return types.newfunction()
	end
	if ty:is("table") then
		return types.newfunction({ head = { DataTypeValue(ty) } })
	end
	if not ty:is("function") then
		return types.newfunction()
	end
	const returns = ty:returns()
	const head = returns.head or {}
	const new_head = {}
	for i, value in head do
		new_head[i] = DataTypeValue(value)
	end
	return types.newfunction({ head = new_head, tail = returns.tail })
end

export type BufferSave = {
	size: number,
	cursor: number,
	buff: buffer,
	refs: { any },
}

export type EventCall = "Sync" | "Async" | "Polling"

export type EventProps = {
	read from: ("Server" | "Client")?,
	read type: ("Reliable" | "Unreliable")?,
	read call: EventCall?,
	read value: any,
}

export type FunctProps = {
	read value: any,
	read ret: any,
}

export type StateProps<T> = {
	read value: T,
	read initial: DataTypeValue<T>,
}

export type DefOptions = {
	read casing: Case?,
	read default_call: EventCall?,
	read auto_flush: (true | false)?,
}

type GetPlayerType<T = "player"> = index<{
	player: Player,
	list: { Player },
}, T>

type function build_fire(is_server: boolean, tbl: typeof(types.newtable()), value_fn: type)
	const value = value_fn:parameters()
	const head: { any } = value.head or {}
	if is_server then
		-- fire: (player: Player, T...) -> ()
		const fire_head = { GetPlayerType() :: any }
		table.move(head, 1, #head, #fire_head + 1, fire_head)
		const fire_fn = types.newfunction({ head = fire_head, tail = value.tail })
		-- fire_all: (T...) -> ()
		const fire_all_fn = types.newfunction({ head = head, tail = value.tail })
		-- fire_list: (players: { Player }, T...) -> ()
		const list_head = { GetPlayerType(types.singleton("list")) :: any }
		table.move(head, 1, #head, #list_head + 1, list_head)
		const fire_list_fn = types.newfunction({ head = list_head, tail = value.tail })
		-- fire_except: (player: Player, T...) -> ()
		const fire_except_fn = types.newfunction({ head = fire_head, tail = value.tail })
		tbl:setproperty(types.singleton("fire"), fire_fn)
		tbl:setproperty(types.singleton("fire_all"), fire_all_fn)
		tbl:setproperty(types.singleton("fire_list"), fire_list_fn)
		tbl:setproperty(types.singleton("fire_except"), fire_except_fn)
	else
		-- fire: (T...) -> ()
		const fire_fn = types.newfunction({ head = value.head, tail = value.tail })
		tbl:setproperty(types.singleton("fire"), fire_fn)
	end
	return tbl
end

type function build_listen(is_server: boolean, tbl: typeof(types.newtable()), value_fb: type)
	const value = value_fb:parameters()
	const head: { any } = value.head or {}
	local cb_head
	if is_server then
		-- callback: (player: Player, T...) -> ()
		cb_head = { GetPlayerType() :: any }
		table.move(head, 1, #head, #cb_head + 1, cb_head)
	else
		-- callback: (T...) -> ()
		cb_head = head
	end
	const cb_fn = types.newfunction({ head = cb_head, tail = value.tail })
	-- disconnect: () -> ()
	const disconnect_fn = types.newfunction()
	-- on: (callback) -> disconnect
	const on_fn = types.newfunction({ head = { cb_fn } }, { head = { disconnect_fn } })
	tbl:setproperty(types.singleton("on"), on_fn)
	return tbl
end

type function build_iter(is_server: boolean, tbl: typeof(types.newtable()), value_fn: type)
	const value = value_fn:parameters()
	const head = value.head or {}
	-- next: () -> (number, Player, T...) | (number, T...)
	const iter_ret_head = if is_server then { types.number, GetPlayerType() } else { types.number }
	table.move(head, 1, #head, #iter_ret_head + 1, iter_ret_head)
	const next_fn = types.newfunction({}, { head = iter_ret_head, tail = value.tail })
	-- iter: () -> next
	const iter_fn = types.newfunction({}, { head = { next_fn } })
	tbl:setproperty(types.singleton("iter"), iter_fn)
	return tbl
end

export type function EventServer(props: type, options: type)
	const from = props:readproperty(types.singleton("from"))
	const value = props:readproperty(types.singleton("value")) or types.singleton(nil)
	const call = props:readproperty(types.singleton("call"))
	const default_call = options:is("table") and options:readproperty(types.singleton("default_call"))
	const use_polling = (call == types.singleton("Polling")) or (default_call == types.singleton("Polling"))
	const value_fn = data_type_input(value)
	const tbl = types.newtable()
	if from ~= types.singleton("Client") then
		build_fire(true, tbl, value_fn)
	end
	if from ~= types.singleton("Server") then
		if use_polling then
			build_iter(true, tbl, value_fn)
		else
			build_listen(true, tbl, value_fn)
		end
	end
	return tbl
end

export type function EventClient(props: type, options: type)
	const from = props:readproperty(types.singleton("from"))
	const value = props:readproperty(types.singleton("value")) or types.singleton(nil)
	const call = props:readproperty(types.singleton("call"))
	const default_call = options:is("table") and options:readproperty(types.singleton("default_call"))
	const use_polling = (call == types.singleton("Polling")) or (default_call == types.singleton("Polling"))
	const value_fn = data_type_input(value)
	const tbl = types.newtable()
	if from ~= types.singleton("Server") then
		build_fire(false, tbl, value_fn)
	end
	if from ~= types.singleton("Client") then
		if use_polling then
			build_iter(false, tbl, value_fn)
		else
			build_listen(false, tbl, value_fn)
		end
	end
	return tbl
end

export type Event<Props = EventProps, Options = DefOptions> = {
	type: "event",
	props: Props,
	server: (options: Options & DefOptions, path: string, lifecycle: any) -> EventServer<Props, Options>,
	client: (options: Options & DefOptions, path: string, lifecycle: any) -> EventClient<Props, Options>,
}

type function build_funct_on(value_fn: type, ret_fn: type)
	const value = value_fn:parameters()
	const ret = ret_fn:parameters()
	-- callback: (player, T...) -> R...
	const cb_head: { any } = { GetPlayerType() }
	const in_head = value.head or {}
	table.move(in_head, 1, #in_head, #cb_head + 1, cb_head)
	const cb_fn = types.newfunction({ head = cb_head, tail = value.tail }, { head = ret.head, tail = ret.tail })
	-- on: (callback) -> ()
	const on_fn = types.newfunction({ head = { cb_fn } })
	const tbl = types.newtable()
	tbl:setproperty(types.singleton("on"), on_fn)
	return tbl
end

type function build_funct_invoke(value_fn: type, ret_fn: type)
	const value = value_fn:parameters()
	const ret = ret_fn:parameters()
	-- invoke: (T...) -> R...
	const invoke_fn = types.newfunction({ head = value.head, tail = value.tail }, { head = ret.head, tail = ret.tail })
	const tbl = types.newtable()
	tbl:setproperty(types.singleton("invoke"), invoke_fn)
	return tbl
end

export type function FunctServer(props: type)
	const value = props:readproperty(types.singleton("value")) or types.singleton(nil)
	const ret = props:readproperty(types.singleton("ret")) or types.singleton(nil)
	const value_fn = data_type_input(value)
	const ret_fn = data_type_input(ret)
	return build_funct_on(value_fn, ret_fn)
end

export type function FunctClient(props: type)
	const value = props:readproperty(types.singleton("value")) or types.singleton(nil)
	const ret = props:readproperty(types.singleton("ret")) or types.singleton(nil)
	const value_fn = data_type_input(value)
	const ret_fn = data_type_input(ret)
	return build_funct_invoke(value_fn, ret_fn)
end

export type Funct<Props = FunctProps> = {
	type: "function",
	props: Props,
	server: (options: DefOptions, path: string, lifecycle: any) -> FunctServer<Props>,
	client: (options: DefOptions, path: string, lifecycle: any) -> FunctClient<Props>,
}

export type StateGetter<T, R> = (value: T) -> R
export type Cleanup = () -> ()

export type StateShared<T> = {
	derive: (<R>(getter: (value: T, prev: R?) -> R) -> StateGetter<T, R>)
		& (<RI, R0>(getterA: StateGetter<T, RI>, getterB: (value: RI, prev: R0?) -> R0) -> StateGetter<T, R0>),
	subscribe: ((callback: (new: T, prev: T?) -> ()) -> Cleanup)
		& (<R>(getter: StateGetter<T, R>, callback: (new: R, prev: R?) -> ()) -> Cleanup),
	listen: index<StateShared<T>, "subscribe">,
	get: (() -> T) & (<R>(getter: StateGetter<T, R>) -> R),
}

export type StateServer<T> = {
	set: ((value: T) -> ()) & ((callback: (value: T) -> T | false) -> ()),
	filter: (callback: (value: T, player: Player) -> T) -> (),
	derive: index<StateShared<T>, "derive">,
	subscribe: index<StateShared<T>, "subscribe">,
	listen: index<StateShared<T>, "listen">,
	get: index<StateShared<T>, "get">,
}

export type StateClient<T> = StateShared<T>

export type State<T = unknown> = {
	type: "state",
	server: (options: DefOptions, path: string, lifecycle: any) -> StateServer<T>,
	client: (options: DefOptions, path: string, lifecycle: any) -> StateClient<T>,
}

type function format_interface_casing(tbl: type, method_names: type)
	const returns = types.newtable()
	for k, prop in tbl:properties() do
		const format_key = method_names:readproperty(k) :: type
		if prop.read then
			returns:setproperty(format_key, prop.read)
		end
	end
	return returns
end

type function resolve_objects(objects: type, options: type, from: type)
	assert(objects:is("table"), "Expected a table")
	const casing = options:is("table") and options:readproperty(types.singleton("casing")) or types.unknown
	const auto_flush = options:is("table") and options:readproperty(types.singleton("auto_flush"))
	const is_server = (from == types.singleton("Server"))
	const method_names = get_casing(casing)
	const function resolve_objects_recursive(t: type): type
		if t:is("table") then
			const kind = t:readproperty(types.singleton("type"))
			local ret: type?
			if kind == types.singleton("event") then
				const props = t:readproperty(types.singleton("props"))
				const build_event = is_server and EventServer or EventClient
				ret = props and build_event(props, options)
			elseif kind == types.singleton("function") then
				const props = t:readproperty(types.singleton("props"))
				const build_fn = is_server and FunctServer or FunctClient
				ret = props and build_fn(props)
			else
				const fn = t:readproperty(types.singleton(is_server and "server" or "client"))
				const returns = fn and fn:returns()
				ret = returns and returns.head and returns.head[1] :: any
			end
			if ret then
				return format_interface_casing(ret, method_names)
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
		returns:setproperty(method_names:readproperty(types.singleton("flush")), types.newfunction())
	end
	return returns
end

export type ServerObjects<Objects, Options> = resolve_objects<Objects, Options, "Server">
export type ClientObjects<Objects, Options> = resolve_objects<Objects, Options, "Client">

export type Define<Objects, Options> = {
	server: ServerObjects<Objects, Options>,
	client: ClientObjects<Objects, Options>,
}

return nil
