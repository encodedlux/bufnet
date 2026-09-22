const define = require("@self/api/define")
const event = require("@self/api/event")
const funct = require("@self/api/funct")
const state = require("@self/api/state")
const data_types = require("@self/data_types")
const types = require("@self/types")

export type DataType<T> = types.DataType<T>
export type DataTypeValue<T> = types.DataTypeValue<T>
export type DataTypeSchema<T> = types.DataTypeSchema<T>
export type SelectTupleValue<I, T> = types.SelectTupleValue<I, T>

return {
	define = define,
	event = event,
	funct = funct,
	state = state,

	t = data_types,
}
