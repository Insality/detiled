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
	local part_size = data.tile.height - data.tile.side
	local two_hex_height = data.tile.side * 2 + part_size
	local stagger_index = data.scene.stagger_index or "odd"

	local x = data.tile.width * (i + stagger_offset(j, stagger_index))
	local y = two_hex_height / 2 * j

	if data.scene.invert_y then
		y = data.scene.size_y - y
	end

	x = x + data.tile.width/2
	y = y + (data.scene.invert_y and -part_size or part_size)

	return x, y
end


function M.pos_to_cell(x, y, map_params)
	local data = map_params
	local stagger_index = data.scene.stagger_index or "odd"

	local part_size = data.tile.height - data.tile.side
	local two_hex_height = data.tile.side * 2 + part_size

	x = x - data.tile.width/2
	y = y - (data.scene.invert_y and -part_size or part_size)

	if data.scene.invert_y then
		y = data.scene.size_y - y
	end

	local j = round(2 * y / two_hex_height)
	local i = round(x / data.tile.width - stagger_offset(j, stagger_index))

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
	return i + (k - bit.band(k, 1)) / 2, k
end


function M.offset_to_cube(i, j, map_params)
	local x = i - (j - bit.band(j, 1)) / 2
	return x, -x - j, j
end


return M
