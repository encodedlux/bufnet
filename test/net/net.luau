const bufnet = require("../../bufnet")

const define = bufnet.define
const event = bufnet.event
const funct = bufnet.funct
const t = bufnet.t

return define("test", {
	my_event = event({
		from = "Server",
		value = t.tuple(t.u8({ min = 1, max = 10 }), t.string()),
	}),
	other = event({
		from = "Client",
		call = "Polling",
		value = t.tuple(t.u8(), t.string()),
	}),
	scope = {
		my_func = funct({
			call = "Async",
			value = t.tuple(t.string(), t.boolean()),
			returns = t.string(),
		}),
	},
}, {
	casing = "Snake",
	default_call = "SingleAsync",
	auto_flush = true,
})
