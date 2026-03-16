---@class detiled.logger
---@field trace fun(_, msg: string, data: any)
---@field debug fun(_, msg: string, data: any)
---@field info fun(_, msg: string, data: any)
---@field warn fun(_, msg: string, data: any)
---@field error fun(_, msg: string, data: any)
local M = {}

local NOOP = function() end
---@type detiled.logger
local empty_logger = {
	trace = NOOP,
	debug = NOOP,
	info = NOOP,
	warn = NOOP,
	error = NOOP,
}


---@type detiled.logger
local default_logger = {
	trace = function(_, msg, data) pprint("TRACE: " .. msg, data) end,
	debug = function(_, msg, data) pprint("DEBUG: " .. msg, data) end,
	info = function(_, msg, data) pprint("INFO: " .. msg, data) end,
	warn = function(_, msg, data) pprint("WARN: " .. msg, data) end,
	error = function(_, msg, data) pprint("ERROR: " .. msg, data) end
}

local METATABLE = { __index = default_logger }

---@param logger detiled.logger|table|nil
function M.set_logger(logger)
	METATABLE.__index = logger or empty_logger
end

return setmetatable(M, METATABLE)

