const types = require("../types")

const NOOP = function() end

const null: types.DataType<nil> = {
	write = NOOP,
	read = NOOP :: any,
}

return null
