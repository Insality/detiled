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


---Get layers and map params from a map. Each layer has entities, properties, layer_id, visible, position (offset).
---@param map_or_path detiled.map|string
---@return detiled.layers, detiled.map_params|nil
function M.parse(map_or_path)
	local map = map_or_path
	if type(map_or_path) == "string" then
		logger:debug("Loading map", map_or_path)
		map = detiled_internal.load_json(map_or_path) --[[@as detiled.map]]
		logger:debug("Map loaded")

		if not map then
			logger:error("Failed to load map", map_or_path)
			return {}, nil
		end
	end

	---@cast map -string
	local layers, map_params = detiled_parser.parse(map)

	return layers, map_params
end


---Convert cell indices to world position
---@param i number
---@param j number
---@param map_params detiled.map_params
---@return number, number
function M.cell_to_pos(i, j, map_params)
	return detiled_parser.cell_to_pos(i, j, map_params)
end


---Convert world position to cell indices
---@param x number
---@param y number
---@param map_params detiled.map_params
---@return number, number
function M.pos_to_cell(x, y, map_params)
	return detiled_parser.pos_to_cell(x, y, map_params)
end


---Load a tileset to internal cache, so maps can reference it by name while parsing
---@param tileset_or_path detiled.tileset|string Path to tileset JSON file or tileset table
---@return detiled.tileset
function M.load_tileset(tileset_or_path)
	local tileset = tileset_or_path
	if type(tileset_or_path) == "string" then
		tileset = detiled_internal.load_json(tileset_or_path) --[[@as detiled.tileset]]
	end

	---@cast tileset -string
	return detiled_internal.load_tileset(tileset)
end


return M
