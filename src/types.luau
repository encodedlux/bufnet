const casing = require("./core/casing")

export type Case = casing.Case
export type get_casing<T> = casing.get_casing<T>

export type DataType<T = unknown, V = T> = {
	read infer: T,
	read write: (buff: buffer, offset: number, value: V, refs: { [any]: any }) -> number,
	read read: (buff: buffer, offset: number, refs: { [any]: any }) -> (number, T),
	read size: number | (value: V) -> number,
}

export type Infer<T> = index<T, "infer">

export type function InferFromFields(fields: type)
	assert(fields:is("table"), "expected a table")
	local result = types.newtable()
	for key, value in fields:properties() do
		if value.read then
			result:setproperty(key, Infer(value.read))
		end
	end
	return result
end

export type function InferFromTuple(tuple_ty: type, i: type)
	assert(tuple_ty:is("function"), "expected a t.tuple")
	const returns = tuple_ty:returns()
	if i == types.singleton("#") then
		return types.singleton(tostring(#(returns.head or {})))
	end
	const pos = assert(i and i:is("singleton") and tonumber(i:value()), "expected a pos selection")
	const arg_ty = (returns.head and returns.head[pos :: any]) :: type
	assert(arg_ty, "pos selection is out of bounds")
	return Infer(arg_ty)
end

type function data_type_input(ty: type)
	if not ty then
		return types.newfunction()
	end
	if ty:is("table") then
		return types.newfunction({ head = { Infer(ty) } })
	end
	if not ty:is("function") then
		return types.newfunction()
	end
	const returns = ty:returns()
	const head = returns.head or {}
	const new_head = {}
	for i, value in head do
		new_head[i] = Infer(value)
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
	read initial: Infer<T>,
}

export type DefOptions = {
	read casing: Case?,
	read default_call: EventCall?,
	read auto_flush: (true | false)?,
}

type function merge(...: type)
	const result = types.newtable()
	const function copy_props(target: type)
		if target:is("table") then
			for k, prop in target:properties() do
				if prop.read then
					result:setproperty(k, prop.read)
				end
			end
		elseif target:is("intersection") then
			for _, component in target:components() do
				copy_props(component)
			end
		end
	end
	for i = 1, select("#", ...) do
		const t = select(i, ...)
		if t then
			copy_props(t)
		end
	end
	return result
end

type FireOnServer<T...> = {
	fire: (player: Player, T...) -> (),
	fire_all: (T...) -> (),
	fire_list: (players: { Player }, T...) -> (),
	fire_except: (player: Player, T...) -> (),
}

type FireOnClient<T...> = {
	fire: (T...) -> (),
}

type ListenOnServer<T...> = {
	on: (callback: (player: Player, T...) -> ()) -> Cleanup,
}

type ListenOnClient<T...> = {
	on: (callback: (T...) -> ()) -> Cleanup,
}

type IterOnServer<T...> = {
	iter: () -> () -> (number, Player, T...),
}

type IterOnClient<T...> = {
	iter: () -> () -> (number, T...),
}

export type function EventServer(props: type, options: type)
	const from = props:readproperty(types.singleton("from"))
	const value = props:readproperty(types.singleton("value")) or types.singleton(nil)
	const call = props:readproperty(types.singleton("call"))
	const default_call = options:is("table") and options:readproperty(types.singleton("default_call"))
	const use_polling = (call == types.singleton("Polling")) or (default_call == types.singleton("Polling"))
	const value_args = data_type_input(value):parameters().head or {}
	local result = types.newtable()
	if from ~= types.singleton("Client") then
		result = merge(result, FireOnServer(table.unpack(value_args)))
	end
	if from ~= types.singleton("Server") then
		if use_polling then
			result = merge(result, IterOnServer(table.unpack(value_args)))
		else
			result = merge(result, ListenOnServer(table.unpack(value_args)))
		end
	end
	return result
end

export type function EventClient(props: type, options: type)
	const from = props:readproperty(types.singleton("from"))
	const value = props:readproperty(types.singleton("value")) or types.singleton(nil)
	const call = props:readproperty(types.singleton("call"))
	const default_call = options:is("table") and options:readproperty(types.singleton("default_call"))
	const use_polling = (call == types.singleton("Polling")) or (default_call == types.singleton("Polling"))
	const value_args = data_type_input(value):parameters().head or {}
	local result = types.newtable()
	if from ~= types.singleton("Server") then
		result = merge(result, FireOnClient(table.unpack(value_args)))
	end
	if from ~= types.singleton("Client") then
		if use_polling then
			result = merge(result, IterOnClient(table.unpack(value_args)))
		else
			result = merge(result, ListenOnClient(table.unpack(value_args)))
		end
	end
	return result
end

export type Event<Props = EventProps, Options = DefOptions> = {
	type: "event",
	props: Props,
	server: (options: Options & DefOptions, path: string, lifecycle: any) -> EventServer<Props, Options>,
	client: (options: Options & DefOptions, path: string, lifecycle: any) -> EventClient<Props, Options>,
}

type player = Player

export type function FunctServer(props: type)
	const value = props:readproperty(types.singleton("value")) or types.singleton(nil)
	const ret = props:readproperty(types.singleton("ret")) or types.singleton(nil)
	const value_params = data_type_input(value):parameters()
	const ret_params = data_type_input(ret):parameters()
	const result = types.newtable()
	const head = { player }
	if value_params.head then
		table.move(value_params.head, 1, #value_params.head, #head + 1, head)
	end
	const cb_fn = types.newfunction({ head = head }, ret_params)
	result:setproperty(types.singleton("on"), types.newfunction({ head = { cb_fn } }))
	return result
end

export type function FunctClient(props: type)
	const value = props:readproperty(types.singleton("value")) or types.singleton(nil)
	const ret = props:readproperty(types.singleton("ret")) or types.singleton(nil)
	const value_params = data_type_input(value):parameters()
	const ret_params = data_type_input(ret):parameters()
	const result = types.newtable()
	result:setproperty(types.singleton("invoke"), types.newfunction(value_params, ret_params))
	return result
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
