const bufnet = require("./bufnet")

const define = bufnet.define
const event = bufnet.event
const funct = bufnet.funct
const state = bufnet.state
const t = bufnet.t

return define("test", {
	my_event = event({
		from = "Server",
		value = t.tuple(t.u8, t.string),
	}),
	other = event({
		from = "Client",
		call = "Polling",
		value = t.tuple(t.u8, t.string),
	}),
	scope = {
		my_func = funct({
			value = t.tuple(t.string, t.boolean),
			ret = t.literals("foo" :: "foo", "bar" :: "bar"),
		}),
	},
	my_state = state({
		value = t.struct({
			count = t.u8,
		}),
		initial = {
			count = 0,
		},
	}),
}, {
	casing = "Snake",
	default_call = "Sync",
	auto_flush = true,
})
