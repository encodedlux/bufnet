<h1 align="center">BufNet</h1>

<p align="center">Strictly typed buffer networking library for Luau/Roblox</p>

# Installation
## Wally
Add **BufNet** to your `wally.toml` dependencies:
```toml
[dependencies]
bufnet = "encodedlux/bufnet@1.0.0"
```
Then, run `wally install` in your project folder.

# Getting Started

## Writing a network definition
Create a shared file (where both client and server can access it) with the following structure:

```luau
-- net.luau
const define = bufnet.define
const event = bufnet.event
const t = bufnet.t

return define("game", {
	my_event = event({
		from = "Server",
		type = "Reliable",
		call = "SingleAsync",
		value = t.string(),
	}),
})
```

## Basic Usage

Optionally, you can create a networking server file:
```luau
-- net_server.luau
const net = require(path.to.net)
return net.server()
```

And a client file:
```luau
-- net_client.luau
const net = require(path.to.net)
return net.client()
```

Or, you can just require the shared file and do `.server()` or `.client()`:
```luau
const net = require(path.to.net)

const net_server = net.server() -- for server-side only
const net_client = net.client() -- for client-side only
```

From these files you can fire and listen to events, and invoke or handle functs.

Server:
```luau
const net_server = require(path.to.net_server)

net_server.my_event.fire_all("First message")
```

Client:
```luau
const net_client = require(path.to.net_client)

net_client.my_event.on(function(message)
    print(message)
end)
```

# Options

## `casing`
Default: `Snake`
Options: `Snake`, `Camel`, `Pascal`

Sets the naming convention of every generated method from events/functs.
```luau
return define("game", {
	...
}, {
    casing = "Camel",
})
```

## `default_call`
Default: `SingleAsync`
Options: `SingleAsync`, `ManyAsync`, `SingleSync`, `ManySync`, `Polling`

Call mode assumed by any event that doesn't declare its own `call`.

## `auto_flush`
Default: `true`

Reliable calls are combined into a single delivery once per frame. When set to `false`, the automatic send is disabled and you become responsible for calling `flush()` — exposed on both `.server()` and `.client()` returns.

Server:
```luau
RunService.Heartbeat:Connect(function()
	net_server.flush() -- delivers every event/funct manually
end)
```
Client:
```luau
RunService.Heartbeat:Connect(function()
	net_client.flush() -- delivers every event/funct manually
end)
```

# Events
Events are BufNet's version of a `RemoteEvent`. The `from` prop decides which side fires and which side listens, and unlike Roblox remotes you never create an instance yourself — every event in the namespace shares the same two remotes (reliable and unreliable).

## Defining an Event

An event is created by calling `event`:
```luau
return define("game", {
	my_event = event({
		from = "Server",
		type = "Reliable",
		call = "SingleAsync",
		value = t.string(),
	}),
})
```

## `from`
Options: `Server`, `Client`

Decides which side fires the event.

## `type`
Default: `Reliable`

- `Reliable`: Delivery is guaranteed and packets arrive in the order they were sent.
- `Unreliable`: Packets may be dropped or arrive out of order, and are limited to 900 bytes (Roblox limit). Unreliable events are sent immediately instead of being grouped with the frame delivery.

## `call`
Default: `SingleAsync`

Sets how the receiving side consumes the event.

- `SingleSync` - One listener per event; the callback cannot yield.
- `ManySync` - Multiple listeners per event, all of which run; no callback can yield.
- `SingleAsync` - One listener per event; the callback may yield.
- `ManyAsync` - Multiple listeners per event, all of which run; each callback may yield.
- `Polling` - No listener runs; events are queued and read manually with `iter()`.

> [!CAUTION]
> Prefer async calls whenever possible.
> If a sync listener yields or errors, the events sent together with it may be dropped.

## `value`

Sets the event's payload type. Use `t.tuple(...)` to send more than one value at once, and `t.null` when the event carries no payload.

## Usage

Firing:
```luau
-- client.luau
net_client.my_event.fire(8)
net_client.my_tuple_event.fire(8, "foo", true)
```
```luau
-- server.luau
net_server.my_event.fire(player, 8)
net_server.my_event.fire_all(8)
net_server.my_event.fire_list({ player }, 8)
net_server.my_event.fire_except(player, 8)
```

Listening:
```luau
-- client.luau
net_client.my_event.on(function(value)
	-- ...
end)
net_client.my_tuple_event.on(function(num, str, bool)
	-- ...
end)
```
```luau
-- server.luau
net_server.my_event.on(function(player, value)
	-- ...
end)
net_server.my_tuple_event.on(function(player, num, str, bool)
	-- ...
end)
```
```luau
-- disconnect
const disconnect = my_event.on(...)
disconnect()
```

Polling:
```luau
-- client.luau
for index, value in net_client.my_event.iter() do
	-- ...
end
for index, num, str, bool in net_client.my_tuple_event.iter() do
	-- ...
end
```
```luau
-- server.luau
for index, player, value in net_server.my_event.iter() do
	-- ...
end
for index, player, num, str, bool in net_server.my_tuple_event.iter() do
	-- ...
end
```

# Functs
Functs are BufNet's version of a `RemoteFunction`. The client calls `invoke(...)` and yields until the server's handler returns a value.

## Defining a Funct
```luau
return define("game", {
	my_funct = funct({
		value = t.u8(),
		returns = t.u8(),
	}),
})
```

## `value`
The payload the client sends to the server.

## `returns`
The payload the server sends back to the client.

## Usage

### Invoking (client)
```luau
-- client.luau
const value = net_client.my_funct.invoke(5)
```

### Handling (server)
```luau
-- server.luau
net_server.my_funct.on(function(player, value)
	return value * 2
end)
```

# Scopes
Scopes nest related events and functs under a shared table, both in the definition file and in the resulting API.

```luau
return define("game", {
	example_scope = {
		my_event = event({
			from = "Server",
			type = "Reliable",
			call = "SingleAsync",
			value = t.string(),
		}),
	},
})
```

## Usage

```luau
const net_server = require(path.to.net_server)

net_server.example_scope.my_event.fire_all("Hello World")
```

# Custom Types

The built-in data types cover most cases, but sometimes you need something specific. A custom
data type is just a table with two functions: `write` (turn a value into bytes) and `read`
(turn bytes back into a value). BufNet treats it exactly like any built-in type — you can use it
as an event's `value`, a funct's `value`/`returns`, and anywhere inside `t.struct`, `t.array`,
`t.map` and the other composite types.

```luau
export type DataType<T...> = {
	write: (ctx: Writter, T...) -> (),
	read: (ctx: Reader) -> T...,
}
```

`write` receives the value being sent; `read` returns the value received. Both receive a `ctx`
object that you use to write to / read from the outgoing packet's buffer.

## Writing bytes

- `ctx.alloc(bytes) -> offset`: Reserves `bytes` in the packet and returns the position. Write
  with `buffer.write*` on `ctx.buff` at that position, like you would in a normal `buffer`.
- `ctx.add_ref(ref)`: Sends a value **outside** the main buffer — Instances and other Roblox
  objects can't be stored as bytes, so they travel as references and are sent along with the
  packet automatically.

## Reading bytes

- `ctx.read(bytes) -> offset`: Moves the read cursor forward by `bytes` and returns the position
  where the data starts. Read with `buffer.read*` on `ctx.buff`.
- `ctx.read_ref() -> any`: Retrieves the next value that was sent as a reference with
  `add_ref`, in the same order.

## Example: packing a smaller value

`t.color3()` stores each channel as a float32 (12 bytes). This type stores a `Color3` in 3 bytes
by saving each channel as a 0-255 integer:

```luau
const color_u8: DataType<Color3> = {
	write = function(ctx, value)
		const offset = ctx.alloc(3) -- 1 byte per channel (r, g, b)
		buffer.writeu8(ctx.buff, offset, value.R * 255)
		buffer.writeu8(ctx.buff, offset + 1, value.G * 255)
		buffer.writeu8(ctx.buff, offset + 2, value.B * 255)
	end,
	read = function(ctx)
		const offset = ctx.read(3)
		const r = buffer.readu8(ctx.buff, offset)
		const g = buffer.readu8(ctx.buff, offset + 1)
		const b = buffer.readu8(ctx.buff, offset + 2)
		return Color3.fromRGB(r, g, b)
	end,
}
```

## Example: sending Instances

Instances can't be written as bytes. Use `add_ref` to send them as references, and `read_ref` to
retrieve them on the other side. This wraps `t.instance()` with a class check for extra safety:

```luau
const function instance_with_class_name<T>(class_name: string): DataType<T>
	return {
		write = function(ctx, value)
			ctx.add_ref(value)
		end,
		read = function(ctx)
			const ref = ctx.read_ref()
			assert(ref:IsA(class_name), "Expected a " .. class_name)
			return ref
		end,
	}
end
```

A custom type is used like any other: as the `value` and `returns` of a funct, the `value` of an
event, or inside any composite type.

```luau
return define("game", {
	find_block_with_color = funct({
		value = color_u8,
		returns = instance_with_class_name<<BasePart>>("BasePart"),
	}),
})
```