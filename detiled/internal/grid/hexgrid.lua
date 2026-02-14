local hexgrid_convert = require("detiled.internal.grid.hexgrid_convertations")

local M = {}

local HEXMAP_TYPE = {
	POINTYTOP = "pointytop",
	FLATTOP = "flattop",
}


local function get_scene_size_pointytop(data)
	local double_size = data.tile.height + data.tile.side
	local part_size = data.tile.height - data.tile.side

	local width = (data.scene.tiles_x + 0.5) * data.tile.width
	local height = (data.scene.tiles_y / 2 * double_size) + 2 * part_size
	return width, height
end


local function get_scene_size_flattop(data)
	local tile_width = data.tile.width
	local tile_height = data.tile.height
	local tile_side = data.tile.side
	local tile_angle = tile_width - tile_side - 1
	local tile_angle_half = tile_angle / 2

	local tile_count_x = data.scene.tiles_x
	local tile_count_y = data.scene.tiles_y

	local width = (tile_count_x * tile_side) + ((tile_count_x + 1) * tile_angle_half)
	local height = (tile_count_y * tile_height) + tile_height/2

	return width, height
end


local function get_scene_size(map_params)
	local data = map_params

	if data.scene.hexmap_type == HEXMAP_TYPE.FLATTOP then
		return get_scene_size_flattop(data)
	else
		return get_scene_size_pointytop(data)
	end
end


---@param tiled_data detiled.map
---@return table
function M.get_map_params_from_tiled(tiled_data)
	local hexmap_type = HEXMAP_TYPE.POINTYTOP
	if tiled_data.staggeraxis == "x" then
		hexmap_type = HEXMAP_TYPE.FLATTOP
	end

	local map_params = {}
	map_params.tile = {
		width = tiled_data.tilewidth,
		height = tiled_data.tileheight,
		side = tiled_data.hexsidelength or 0,
	}
	map_params.scene = {
		invert_y = true,
		tiles_x = tiled_data.width,
		tiles_y = tiled_data.height,
		size_x = 0,
		size_y = 0,
		hexmap_type = hexmap_type,
	}

	local size_x, size_y = get_scene_size(map_params)
	map_params.scene.size_x = size_x
	map_params.scene.size_y = size_y

	return map_params
end


---@param i number
---@param j number
---@param map_params table
---@return number, number
function M.cell_to_pos(i, j, map_params)
	if map_params.scene.hexmap_type == HEXMAP_TYPE.POINTYTOP then
		return hexgrid_convert.cell_to_pos_pointytop(i, j, map_params)
	end
	if map_params.scene.hexmap_type == HEXMAP_TYPE.FLATTOP then
		return hexgrid_convert.cell_to_pos_flattop(i, j, map_params)
	end

	return 0, 0
end


---@param i number
---@param j number
---@param z_layer number|nil
---@param map_params table
---@return number, number, number
function M.get_tile_pos(i, j, z_layer, map_params)
	z_layer = z_layer or 0
	local x, y = M.cell_to_pos(i, j, map_params)

	local y_value = (y - z_layer * 100000)
	y_value = map_params.scene.size_y - y_value
	local z_pos = y_value / 100000

	return x, y, z_pos
end


return M

