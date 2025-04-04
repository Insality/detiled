local decore = require("decore.decore")

---@class entity
---@field name string|nil
---@field tiled_id string|nil
---@field tiled_layer_id string|nil

decore.register_component("name", "")
decore.register_component("tiled_id", false)
decore.register_component("tiled_layer_id", false)


---@class system.detiled: system
local M = {}


---@return system.detiled
function M.create_system()
	return decore.system(M, "detiled")
end


return M
