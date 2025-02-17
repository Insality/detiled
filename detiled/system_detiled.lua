local decore = require("decore.decore")

local ecs = require("decore.ecs")

---@class entity
---@field name string
---@field tiled_id number
---@field tiled_layer_id string

decore.register_component("name", "")
decore.register_component("tiled_id", false)
decore.register_component("tiled_layer_id", false)


---@class system.detiled: system
local M = {}


---@return system.detiled
function M.create_system()
	local system = setmetatable(ecs.system({id = "detiled"}), { __index = M })
	return system
end


return M
