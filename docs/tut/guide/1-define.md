# Getting Started

## Creating a definition
Start by creating a shared module that contains the networking definitions used by your game.

BufNet lets you define objects in one place, with their data types described explicitly.

```luau
-- net.luau
const define = bufnet.define
const event = bufnet.event
const t = bufnet.t

return define("game", {
	my_event = event({
		from = "Server",
		type = "Reliable",
		call = "Async",
		value = t.string,
	}),
})
```

## Accessing the definition

A definition exposes `.server()` and `.client()`:

```luau
const net = require(path.to.net)

const server = net.server() -- for server-side only
const client = net.client() -- for client-side only
```

Both return the same network definition, with the appropriate interface for each environment.

This allows the same definition to be shared between server and client code without maintaining separate network declarations.

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

## Options

### `casing`
Controls the naming convention used by the generated API.

Default: `Snake`
Options: `Snake`, `Camel`, `Pascal`

```luau
return define("game", {
	...
}, {
    casing = "Camel",
})
```

### `default_call`
Call mode assumed by any event that doesn't declare its own `call`.

Default: `Async`
Options: `Async`, `Sync`, `Polling`

### `auto_flush`
Reliable and Unreliable calls are combined into a single delivery once per frame. When set to `false`, the automatic send is disabled and you become responsible for calling `flush()` — exposed on both `.server()` and `.client()` returns.

Default: `true`

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