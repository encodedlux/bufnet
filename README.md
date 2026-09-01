<h1 align="center">BufNet</h1>

<p align="center">Strictly typed buffer networking library for Luau/Roblox</p>

```lua
-- net.luau, required by both sides
const define = bufnet.define
const event = bufnet.event
const funct = bufnet.funct
const t = bufnet.t

return define("game", {
	MyEvent = event({
		from = "Server",
		type = "Reliable",
		call = "SingleAsync",
		value = t.u8(),
	}),
	MyFunction = funct({
		call = "Async",
		value = t.u8(),
		returns = t.u16(),
	})
}, {
	casing = "Snake", -- Default: "Snake". Options: "Pascal", "Camel", "Snake". Controls the casing with which event/function methods generate.
	default_call = "SingleAsync", -- Default: "SingleAsync". The default call type for events that do not specify a call type.
	auto_flush = true, -- Default: true. When set to false automatic flushing will be disabled and a flush function can be manually called.
})
```
