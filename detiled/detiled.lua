local logger = require("detiled.internal.detiled_logger")
local detiled_internal = require("detiled.internal.detiled_internal")
local detiled_parser = require("detiled.internal.detiled_parser")

---@class detiled
local M = {}


---Set a logger instance
---@param logger_instance detiled.logger|table|nil
function M.set_logger(logger_instance)
	logger.set_logger(logger_instance)
end


---Load a tiled map as a Decore entity
---You can add this entity with `world:addEntity(entity)`
---@param map_or_path detiled.map|string
---@return detiled.get_entity_from_map_result
function M.get_entity_from_map(map_or_path)
	local memory = collectgarbage("count")

	local map = map_or_path
	if type(map_or_path) == "string" then
		map = detiled_internal.load_json(map_or_path) --[[@as detiled.map]]
		if not map then
			logger:error("Failed to load map", map_or_path)
			return { map_params = nil, entities = {} }
		end
	end

	print("Memory after load map", collectgarbage("count") - memory)
	memory = collectgarbage("count")

	---@cast map detiled.map

	local result = detiled_parser.get_entities(map)

	print("Memory after get entities", collectgarbage("count") - memory)

	return result
end


---Convert cell indices to world position
---@param map_params detiled.map_params
---@param i number
---@param j number
---@return number, number
function M.cell_to_pos(map_params, i, j)
	return detiled_parser.cell_to_pos(map_params, i, j)
end


---Convert world position to cell indices
---@param map_params detiled.map_params
---@param x number
---@param y number
---@return number, number
function M.pos_to_cell(map_params, x, y)
	return detiled_parser.pos_to_cell(map_params, x, y)
end


---Load a tileset
---@param tileset_or_path detiled.tileset|string
---@return detiled.tileset
function M.load_tileset(tileset_or_path)
	local tileset = tileset_or_path
	if type(tileset_or_path) == "string" then
		tileset = detiled_internal.load_json(tileset_or_path) --[[@as detiled.tileset]]
	end
	---@cast tileset detiled.tileset

	return detiled_internal.load_tileset(tileset)
end


return M
