# Events
Events are BufNet's version of a `RemoteEvent`. The way of sending data between the server and client.

An event defines how data is sent, which side can fire it, how it is delivered, and how the receiving side consumes it.

## Defining an Event

A event is created by calling `event`:
```luau
return define("game", {
	my_event = event({
		from = "Server",
		type = "Reliable",
		call = "Async",
		value = t.string,
	}),
})
```

### `from`
Decides which side fires the event.

Options: `Server`, `Client`

```luau
from = "Server"
```

Only the server can fire the event.

```luau
from = "Client"
```

Only the client can fire the event.

When `from` is omitted, __both the server and client can fire the event__.

### `type`
Default: `Reliable`

- `Reliable`: Delivery is guaranteed and packets arrive in the order they were sent.
- `Unreliable`: Packets may be dropped or arrive out of order, and are limited to 900 bytes (Roblox limit).

### `call`
Default: `Async`

Sets how the receiving side consumes the event.

- `Sync` - The listener runs synchronously and cannot yield.
- `Async` - The listener runs asynchronously and may yield.
- `Polling` - No listener is registered; events are read manually with `iter()`.

> [!CAUTION]
> Prefer async calls whenever possible.
> If a sync listener yields or errors, the events sent together with it may be dropped.

### `value`

Defines the type of data carried by the event.

```luau
value = t.string
```

Use `t.tuple(...)` when an event needs to carry multiple values:

```luau
value = t.tuple(t.u8, t.string, t.boolean)
```

Use `t.nothing` when the event does not carry any data.

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

Disconnecting:

`on()` returns a cleanup function:

```luau
const disconnect = net_client.my_event.on(function(value)
	-- ...
end)

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