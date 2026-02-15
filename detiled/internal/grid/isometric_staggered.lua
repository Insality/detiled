local M = {}

local STAGGER_AXIS = {
	X = "x",
	Y = "y",
}


local function stagger_offset(idx, stagger_index)
	if stagger_index == "even" then
		return 0.5 * (1 - bit.band(idx, 1))
	end
	return 0.5 * bit.band(idx, 1)
end


local function get_scene_size(map_params)
	local data = map_params
	local tw = data.tile.width
	local th = data.tile.height
	local nx = data.scene.tiles_x
	local ny = data.scene.tiles_y
	local axis = data.scene.stagger_axis or STAGGER_AXIS.Y

	if axis == STAGGER_AXIS.X then
		local width = nx * tw
		local height = ny * (th / 2) + th / 2
		return width, height
	end

	local width = nx * tw + tw / 2
	local height = th + (ny - 1) * (th / 2)
	return width, height
end


---@param tiled_data detiled.map
---@return detiled.map_params
function M.get_map_params_from_tiled(tiled_data)
	local stagger_axis = tiled_data.staggeraxis or "y"
	local stagger_index = tiled_data.staggerindex or "odd"

	local map_params = {}
	map_params.orientation = "staggered"
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
		stagger_axis = stagger_axis,
		stagger_index = stagger_index,
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
	local axis = data.scene.stagger_axis or STAGGER_AXIS.Y
	local stagger_index = data.scene.stagger_index or "odd"
	local x, y

	if axis == STAGGER_AXIS.X then
		x = data.tile.width * i
		y = data.tile.height / 2 * (j + stagger_offset(i, stagger_index))
	else
		x = data.tile.width * (i + stagger_offset(j, stagger_index))
		y = data.tile.height / 2 * j
	end

	if data.scene.invert_y then
		y = data.scene.size_y - y
	end

	x = x + data.tile.width / 2
	y = y + (data.scene.invert_y and -data.tile.height / 2 or data.tile.height / 2)

	return x, y
end


---@param x number
---@param y number
---@param map_params detiled.map_params
---@return number, number
function M.pos_to_cell(x, y, map_params)
	local data = map_params
	local axis = data.scene.stagger_axis or STAGGER_AXIS.Y
	local stagger_index = data.scene.stagger_index or "odd"

	x = x - data.tile.width / 2
	y = y - (data.scene.invert_y and -data.tile.height / 2 or data.tile.height / 2)

	if data.scene.invert_y then
		y = data.scene.size_y - y
	end

	local i, j
	if axis == STAGGER_AXIS.X then
		i = math.floor(x / data.tile.width + 0.5)
		j = math.floor(2 * y / data.tile.height - stagger_offset(i, stagger_index) + 0.5)
	else
		j = math.floor(2 * y / data.tile.height + 0.5)
		i = math.floor(x / data.tile.width - stagger_offset(j, stagger_index) + 0.5)
	end

	return i, j
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
