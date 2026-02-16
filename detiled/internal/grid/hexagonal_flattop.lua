local M = {}


local function round(x)
	return math.floor(x + 0.5)
end


local function stagger_offset(idx, stagger_index)
	if stagger_index == "even" then
		return 0.5 * (1 - bit.band(idx, 1))
	end
	return 0.5 * bit.band(idx, 1)
end


function M.cell_to_pos(i, j, data)
	local part_size = data.tile.width - data.tile.side
	local two_hex_width = data.tile.side * 2 + part_size
	local stagger_index = data.scene.stagger_index or "odd"

	local x = two_hex_width / 2 * i
	local y = data.tile.height * (j + stagger_offset(i, stagger_index))

	if data.scene.invert_y then
		y = data.scene.size_y - y
	end

	x = x + part_size
	y = y + (data.scene.invert_y and -data.tile.height/2 or data.tile.height/2)

	return x, y
end


function M.pos_to_cell(x, y, map_params)
	local data = map_params
	local stagger_index = data.scene.stagger_index or "odd"

	local part_size = data.tile.width - data.tile.side
	local two_hex_width = data.tile.side * 2 + part_size

	x = x - part_size
	y = y - (data.scene.invert_y and -data.tile.height/2 or data.tile.height/2)

	if data.scene.invert_y then
		y = data.scene.size_y - y
	end

	local i = round(2 * x / two_hex_width)
	local j = round(y / data.tile.height - stagger_offset(i, stagger_index))

	return i, j
end


function M.cell_cube_to_pos(i, j, k, map_params)
	local offset_i, offset_j = M.cube_to_offset(i, j, k, map_params)
	return M.cell_to_pos(offset_i, offset_j, map_params)
end


function M.pos_to_cell_cube(x, y, map_params)
	local offset_i, offset_j = M.pos_to_cell(x, y, map_params)
	return M.offset_to_cube(offset_i, offset_j, map_params)
end


function M.cube_to_offset(i, j, k, map_params)
	return i, k + (i - bit.band(i, 1)) / 2
end


function M.offset_to_cube(i, j, map_params)
	local z = j - (i - bit.band(i, 1)) / 2
	return i, -i - z, z
end


return M
