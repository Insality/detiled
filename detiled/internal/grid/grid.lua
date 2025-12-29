local M = {}


local function get_scene_size(map_params)
	local data = map_params

	local width = data.scene.tiles_x * data.tile.width
	local height = data.scene.tiles_y * data.tile.height
	return width, height
end


---@param tiled_data detiled.map
---@return table
function M.get_map_params_from_tiled(tiled_data)
	local map_params = {}
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
---@param map_params table
---@return number, number
function M.cell_to_pos(i, j, map_params)
	local data = map_params

	local x = data.tile.width * i
	local y = data.tile.height * j

	if data.scene.invert_y then
		y = data.scene.size_y - y
	end

	x = x + data.tile.width/2
	y = y + (data.scene.invert_y and -data.tile.height/2 or data.tile.height/2)

	return x, y
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

