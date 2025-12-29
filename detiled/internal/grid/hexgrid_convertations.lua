local M = {}


local function round(x)
	return math.floor(x + 0.5)
end


function M.cell_to_pos_flattop(i, j, data)
	local part_size = data.tile.width - data.tile.side
	local two_hex_width = data.tile.width + data.tile.side

	local x = two_hex_width / 2 * i
	local y = data.tile.height * (j + 0.5 * (bit.band(i, 1)))

	if data.scene.invert_y then
		y = data.scene.size_y - y
	end

	x = x + part_size
	y = y + (data.scene.invert_y and -data.tile.height/2 or data.tile.height/2)

	return x, y
end


function M.cell_to_pos_pointytop(i, j, data)
	local part_size = data.tile.height - data.tile.side
	local two_hex_height = data.tile.height + data.tile.side

	local x = data.tile.width * (i + 0.5 * (bit.band(j, 1)))
	local y = two_hex_height / 2 * j

	if data.scene.invert_y then
		y = data.scene.size_y - y
	end

	x = x + data.tile.width/2
	y = y + (data.scene.invert_y and -part_size or part_size)

	return x, y
end


function M.pos_to_cell_flattop(x, y, map_params)
	local data = map_params

	local part_size = data.tile.width - data.tile.side
	local two_hex_width = data.tile.width + data.tile.side

	x = x - part_size
	y = y - (data.scene.invert_y and -data.tile.height/2 or data.tile.height/2)

	if data.scene.invert_y then
		y = data.scene.size_y - y
	end

	local i = round(2 * x / two_hex_width)
	local j = round(y / data.tile.height - 0.5 * bit.band(i, 1))

	return i, j
end


function M.pos_to_cell_pointytop(x, y, map_params)
	local data = map_params

	local part_size = data.tile.height - data.tile.side
	local two_hex_height = data.tile.height + data.tile.side

	x = x - data.tile.width/2
	y = y - (data.scene.invert_y and -part_size or part_size)

	if data.scene.invert_y then
		y = data.scene.size_y - y
	end

	local j = round(2 * y / two_hex_height)
	local i = round(x / data.tile.width - 0.5 * bit.band(j, 1))

	return i, j
end


function M.cell_cube_to_pos_pointytop(i, j, k, map_params)
	local offset_i, offset_j = M.cube_to_offset_pointytop(i, j, k, map_params)
	return M.cell_to_pos_pointytop(offset_i, offset_j, map_params)
end


function M.cell_cube_to_pos_flattop(i, j, k, map_params)
	local offset_i, offset_j = M.cube_to_offset_flattop(i, j, k, map_params)
	return M.cell_to_pos_flattop(offset_i, offset_j, map_params)
end


function M.pos_to_cell_cube_pointytop(x, y, map_params)
	local offset_i, offset_j = M.pos_to_cell_pointytop(x, y, map_params)
	return M.offset_to_cube_pointytop(offset_i, offset_j, map_params)
end


function M.pos_to_cell_cube_flattop(x, y, map_params)
	local offset_i, offset_j = M.pos_to_cell_flattop(x, y, map_params)
	return M.offset_to_cube_flattop(offset_i, offset_j, map_params)
end


function M.cube_to_offset_pointytop(i, j, k, map_params)
	return i + (k - bit.band(k, 1)) / 2, k
end


function M.cube_to_offset_flattop(i, j, k, map_params)
	return i, k + (i - bit.band(i, 1)) / 2
end


function M.offset_to_cube_pointytop(i, j, map_params)
	local x = i - (j - bit.band(j, 1)) / 2

	return x, -x - j, j
end


function M.offset_to_cube_flattop(i, j, map_params)
	local z = j - (i - bit.band(i, 1)) / 2

	return i, -i - z, z
end


return M

