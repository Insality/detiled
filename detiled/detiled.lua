local detiled_internal = require("detiled.detiled_internal")
local detiled_decore = require("detiled.detiled_decore")

---@class detiled
local M = {}


---Set a logger instance
---@param logger_instance detiled.logger|table|nil
function M.set_logger(logger_instance)
	detiled_internal.logger = logger_instance or detiled_internal.empty_logger
end


---Load a tiled map as a Decore entity
---You can add this entity with `world:addEntity(entity)`
---@param map_or_path detiled.map|string
---@return entity
function M.get_entity_from_map(map_or_path)
	local map = map_or_path
	if type(map_or_path) == "string" then
		map = detiled_internal.load_json(map_or_path) --[[@as detiled.map]]
		if not map then
			detiled_internal.logger:error("Failed to load map", map_or_path)
			return {}
		end
	end
	---@cast map detiled.map

	local entities = detiled_decore.get_entities(map)
	return {
		child_instancies = entities,
	}
end


---Load a tileset
---@param tileset_or_path detiled.tileset|string
function M.load_tileset(tileset_or_path)
	local tileset = tileset_or_path
	if type(tileset_or_path) == "string" then
		tileset = detiled_internal.load_json(tileset_or_path) --[[@as detiled.tileset]]
	end
	---@cast tileset detiled.tileset

	detiled_internal.load_tileset(tileset)
end


return M
