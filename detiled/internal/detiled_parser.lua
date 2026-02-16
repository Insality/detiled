local detiled_internal = require("detiled.internal.detiled_internal")
local logger = require("detiled.internal.detiled_logger")

local floor = math.floor
local math_rad = math.rad
local math_cos = math.cos
local math_sin = math.sin
local table_insert = table.insert

local M = {}

local function get_object_type(object)
	if object.point then
		return "point"
	end
	if object.ellipse then
		return "ellipse"
	end
	if object.polyline and #object.polyline > 0 then
		return "polyline"
	end
	if object.polygon and #object.polygon > 0 then
		return "polygon"
	end
	if not object.gid and (object.width and object.width > 0 or object.height and object.height > 0) then
		return "rectangle"
	end
	return nil
end


local GRID_MODULES = {
	["orthogonal"] = require("detiled.internal.grid.orthogonal"),
	["isometric"] = require("detiled.internal.grid.isometric"),
	["staggered"] = require("detiled.internal.grid.isometric_staggered"),
	["hexagonal"] = require("detiled.internal.grid.hexagonal_staggered"),
}


---@param layer detiled.map.layer
---@param position_z number
---@param prefab_id string|nil
---@param position_x number
---@param position_y number
---@param scale_x number
---@param scale_y number
---@param rotation number
---@param object detiled.map.object|nil
---@return detiled.entity
local function make_entity(layer, position_z, prefab_id, position_x, position_y, scale_x, scale_y, rotation, object)
	---@type detiled.entity
	local entity = {
		prefab_id = prefab_id,
		position_x = position_x,
		position_y = position_y,
		position_z = position_z,
		tiled_layer_id = layer.name,
		scale_x = scale_x ~= 1 and scale_x or nil,
		scale_y = scale_y ~= 1 and scale_y or nil,
		rotation = rotation ~= 0 and rotation or nil,
	}

	if object then
		entity.name = object.name ~= "" and object.name or nil
		entity.tiled_id = tonumber(object.id)
		entity.size_x = object.width
		entity.size_y = object.height
		entity.object_type = get_object_type(object)
		if object.polyline then
			entity.polyline = object.polyline
		end
		if object.polygon then
			entity.polygon = object.polygon
		end
	end

	return entity
end


---@param layer detiled.map.layer
---@param map detiled.map
---@param grid_module table
---@param map_params detiled.map_params
---@return detiled.entity[]
local function get_entities_from_tile_layer(layer, map, grid_module, map_params)
	---@type detiled.entity[]
	local entities = {}

	local position_z = detiled_internal.get_property_value(layer.properties, "position_z") or 0
	local layer_data = detiled_internal.unpack_tile_layer_data(layer)

	for tile_index = 1, #layer_data do
		local tile_gid = layer_data[tile_index]
		local cleared_gid, flip_h, flip_v, flip_d = detiled_internal.parse_gid_flags(tile_gid)
		local tile, tileset = detiled_internal.get_tile_by_gid(map, cleared_gid)
		if tile and tileset then
			local tile_i = ((tile_index - 1) % map.width)
			local tile_j = (floor((tile_index - 1) / map.width))
			local pos_x, pos_y = grid_module.cell_to_pos(tile_i, tile_j, map_params)
			local prefab_id = detiled_internal.get_prefab_id_from_tile(tile)

			local scale_x = flip_h and -1 or 1
			local scale_y = flip_v and -1 or 1
			local rotation = flip_d and -90 or 0
			local entity = make_entity(layer, position_z, prefab_id, pos_x, pos_y, scale_x, scale_y, rotation, nil)
			detiled_internal.apply_tile_properties_to_entity(entity, tile)

			table_insert(entities, entity)
		end
	end

	return entities
end


---@param layer detiled.map.layer
---@param map detiled.map
---@param grid_module table
---@param map_params detiled.map_params
---@return detiled.entity[]
local function get_entities_from_object_layer(layer, map, grid_module, map_params)
	---@type detiled.entity[]
	local entities = {}

	local map_width = map_params.scene.size_x
	local map_height = map_params.scene.size_y
	local position_z = detiled_internal.get_property_value(layer.properties, "position_z") or 0
	local offset_x = layer.offsetx or 0
	local offset_y = layer.offsety or 0

	for object_index = 1, #layer.objects do
		local object = layer.objects[object_index]
		local rotation = -(object.rotation or 0)
		local object_gid = object.gid

		if object_gid then
			local cleared_gid, flip_h, flip_v, flip_d = detiled_internal.parse_gid_flags(object_gid)
			local tile, tileset = detiled_internal.get_tile_by_gid(map, cleared_gid)
			if not tile or not tileset then
				logger:warn("Tile is not found in tileset", {
					gid = object_gid,
					class = object.class,
					name = object.name,
					id = object.id,
				})
			else
				local position_x, position_y, scale_x, scale_y = M.get_defold_position_from_tiled_object(object, tile, map_width, map_height, map_params)
				position_x = position_x + offset_x
				position_y = position_y - offset_y
				if flip_h then scale_x = -scale_x end
				if flip_v then scale_y = -scale_y end
				if flip_d then rotation = rotation - 90 end
				local prefab_id = detiled_internal.get_prefab_id_from_tile(tile)

				local entity = make_entity(layer, position_z, prefab_id, position_x, position_y, scale_x, scale_y, rotation, object)
				detiled_internal.apply_tile_properties_to_entity(entity, tile)
				detiled_internal.apply_object_properties_to_entity(entity, object)
				table_insert(entities, entity)
			end
		else
			local position_x, position_y, scale_x, scale_y = M.get_defold_position_from_tiled_object(object, nil, map_width, map_height, map_params)
			position_x = position_x + offset_x
			position_y = position_y - offset_y - object.height

			local prefab_id = (object.class and object.class ~= "") and object.class or (object.type ~= "" and object.type or nil)
			local use_scale = object.class and object.class ~= ""
			local entity_scale_x = use_scale and scale_x or 1
			local entity_scale_y = use_scale and scale_y or 1
			local entity = make_entity(layer, position_z, prefab_id, position_x, position_y, entity_scale_x, entity_scale_y, rotation, object)
			detiled_internal.apply_object_properties_to_entity(entity, object)
			table_insert(entities, entity)
		end
	end

	return entities
end


---@param tiled_map detiled.map
---@return detiled.entity[], detiled.map_params|nil
function M.get_entities(tiled_map)
	---@type detiled.entity[]
	local entities = {}

	local grid_module = GRID_MODULES[tiled_map.orientation]
	local map_params = grid_module and grid_module.get_map_params_from_tiled(tiled_map) or nil

	for layer_index = 1, #tiled_map.layers do
		local layer = tiled_map.layers[layer_index]
		if not detiled_internal.is_layer_excluded(tiled_map, layer.name) then
			if layer.type == "tilelayer" then
				local layer_entities = get_entities_from_tile_layer(layer, tiled_map, grid_module, map_params)
				for index = 1, #layer_entities do
					table_insert(entities, layer_entities[index])
				end
			end

			if layer.type == "objectgroup" then
				local layer_entities = get_entities_from_object_layer(layer, tiled_map, grid_module, map_params)
				for index = 1, #layer_entities do
					table_insert(entities, layer_entities[index])
				end
			end
		end
	end

	return entities, map_params
end


---@param map_params detiled.map_params
---@param i number
---@param j number
---@return number, number
function M.cell_to_pos(map_params, i, j)
	local grid = GRID_MODULES[map_params.orientation]
	return grid.cell_to_pos(i, j, map_params)
end


---@param map_params detiled.map_params
---@param x number
---@param y number
---@return number, number
function M.pos_to_cell(map_params, x, y)
	local grid = GRID_MODULES[map_params.orientation]
	return grid.pos_to_cell(x, y, map_params)
end


---@param object detiled.map.object
---@param tile detiled.tileset.tile|nil
---@param map_width number|nil
---@param map_height number|nil
---@param map_params detiled.map_params|nil
---@return number, number, number, number
function M.get_defold_position_from_tiled_object(object, tile, map_width, map_height, map_params)
	map_height = map_height or 0
	map_width = map_width or 0

	if not tile and (not object.width or object.width == 0 or not object.height or object.height == 0) then
		local grid = map_params and GRID_MODULES[map_params.orientation]
		if grid and grid.convert_object_position and map_params then
			local position_x, position_y = grid.convert_object_position(object.x, object.y, map_params)
			return position_x, position_y, 1, 1
		end
		local position_y = object.y
		if map_params and map_params.scene.invert_y then
			position_y = map_height - position_y
		end
		return object.x, position_y, 1, 1
	end

	-- Offset from object point in Tiled to sprite anchor (default center). Origin (0,0) at map left bottom.
	local base_width = tile and tile.imagewidth or object.width
	local base_height = tile and tile.imageheight or object.height
	local scale_x = 1
	local scale_y = 1
	local anchor_x = 0
	local anchor_y = 0

	if not base_width or not base_height then
		logger:warn("Base width or height is not set", {
			base_width = base_width,
			base_height = base_height,
			object = object,
			tile = tile,
		})
		return 0, 0, 1, 1
	end

	if base_width > 0 and base_height > 0 then
		scale_x = object.width / base_width
		scale_y = object.height / base_height
	end

	anchor_x = base_width / 2
	anchor_y = base_height / 2

	-- Find the object point in Tiled to sprite anchor
	if tile and tile.objectgroup then
		for index = 1, #tile.objectgroup.objects do
			local tile_object = tile.objectgroup.objects[index]
			if tile_object.point then
				anchor_x = tile_object.x
				anchor_y = base_height - tile_object.y
				break
			end
		end
	end

	local rotation_rad = math_rad(object.rotation)
	local cos = math_cos(rotation_rad)
	local sin = math_sin(rotation_rad)

	local position_x, position_y
	local grid = map_params and GRID_MODULES[map_params.orientation]

	if grid and grid.convert_object_position and map_params then
		position_x, position_y = grid.convert_object_position(object.x, object.y, map_params)
		anchor_x = anchor_x - base_width / 2

		local offset_x, offset_y = detiled_internal.rotated_anchor_offset(anchor_x, anchor_y, scale_x, scale_y, cos, sin)
		position_x = position_x + offset_x
		position_y = position_y + offset_y
	else
		local offset_x, offset_y = detiled_internal.rotated_anchor_offset(anchor_x, anchor_y, scale_x, scale_y, cos, sin)
		position_x = object.x + offset_x
		position_y = object.y - offset_y
		if map_params and map_params.scene.invert_y then
			position_y = map_height - position_y
		end
	end

	return position_x, position_y, scale_x, scale_y
end


---@param tileset_path string
---@return detiled.tileset
function M.load_tileset(tileset_path)
	local tileset = detiled_internal.load_json(tileset_path)
	if not tileset then
		logger:error("Failed to load tileset", tileset_path)
		return {}
	end

	logger:debug("Loaded tileset", tileset_path)
	detiled_internal.load_tileset(tileset)

	return tileset
end


return M
