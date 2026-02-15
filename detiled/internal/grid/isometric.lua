local M = {}


local function get_scene_size(map_params)
	local data = map_params
	local w = data.scene.tiles_x
	local h = data.scene.tiles_y
	local tw = data.tile.width
	local th = data.tile.height
	local size_x = (w + h) * (tw / 2)
	local size_y = (w + h) * (th / 2)

	return size_x, size_y
end


---@param tiled_data detiled.map
---@return detiled.map_params
function M.get_map_params_from_tiled(tiled_data)
	local map_params = {}
	map_params.orientation = "isometric"
	map_params.tile = {
		width = tiled_data.tilewidth,
		height = tiled_data.tileheight,
	}
	map_params.scene = {
		invert_y = true,
		tiles_x = tiled_data.width,
		tiles_y = tiled_data.height,
		size_x = 0,
		size_y = 0,
	}

	local size_x, size_y = get_scene_size(map_params)
	map_params.scene.size_x = size_x
	map_params.scene.size_y = size_y

	return map_params
end


---@param i number
---@param j number
---@param map_params detiled.map_params
---@return number, number
function M.cell_to_pos(i, j, map_params)
	local data = map_params
	local tile_count_y = data.scene.tiles_y
	local tile_width = data.tile.width
	local tile_height = data.tile.height

	local x = (i - j + tile_count_y) * (tile_width / 2) + 1
	local y = (i + j) * (tile_height / 2)

	if data.scene.invert_y then
		y = data.scene.size_y - y
	end

	y = y + (data.scene.invert_y and -tile_height / 2 or tile_height / 2)

	return x, y
end


---@param x number
---@param y number
---@param map_params detiled.map_params
---@return number, number
function M.pos_to_cell(x, y, map_params)
	local data = map_params
	local tile_count_y = data.scene.tiles_y
	local tile_width = data.tile.width
	local tile_height = data.tile.height

	local sum_ij
	if data.scene.invert_y then
		sum_ij = 2 * (data.scene.size_y - tile_height / 2 - y) / tile_height
	else
		y = y - tile_height / 2
		sum_ij = 2 * y / tile_height
	end

	local diff_ij = 2 * x / tile_width - tile_count_y
	local i = (sum_ij + diff_ij) / 2
	local j = (sum_ij - diff_ij) / 2

	return math.floor(i + 0.5), math.floor(j + 0.5)
end


--- Get object position from Tiled, convert to defold map position
--- @param x number
--- @param y number
--- @param map_params detiled.map_params
--- @return number, number
function M.convert_object_position(x, y, map_params)
	local tile_count_y = map_params.scene.tiles_y
	local tw = map_params.tile.width
	local th = map_params.tile.height

	local origin_x = (tile_count_y) * (tw / 2) + 1
	local origin_y = map_params.scene.size_y - th / 2

	local offset_x = x - y
	local offset_y = (th - x - y)/2

	local out_x = origin_x + offset_x
	local out_y = origin_y + offset_y
	return out_x, out_y
end


---@param i number
---@param j number
---@param z_layer number|nil
---@param map_params detiled.map_params
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
