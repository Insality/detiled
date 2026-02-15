local detiled_internal = require("detiled.internal.detiled_internal")
local logger = require("detiled.internal.detiled_logger")
local base64 = require("detiled.internal.base64")

local M = {}

local GRID_MODULES = {
	["orthogonal"] = require("detiled.internal.grid.orthogonal"),
	["isometric"] = require("detiled.internal.grid.isometric"),
	["staggered"] = require("detiled.internal.grid.isometric_staggered"),
	["hexagonal"] = require("detiled.internal.grid.hexagonal_staggered"),
}


---@param layer detiled.map.layer
---@param map detiled.map
---@return detiled.entity[]
local function get_entities_from_tile_layer(layer, map)
	---@type detiled.entity[]
	local entities = {}

	local grid_module = GRID_MODULES[map.orientation]
	local map_params = grid_module.get_map_params_from_tiled(map)

	local position_z = detiled_internal.get_property_value(layer.properties, "position_z") or 0

	local layer_data = layer.data

	if layer.encoding == "base64" then
		local decoded_data  = base64.decode(layer_data) --[[ @as string ]]

		if layer.compression == "zlib" then
			local inflated_data = zlib.inflate(decoded_data)
			local tiles = {}

			for i = 1, #inflated_data, 4 do
				local b1, b2, b3, b4 = inflated_data:byte(i, i+3)
				local gid = b1 + b2*256 + b3*65536 + b4*16777216
				table.insert(tiles, gid)
			end

			layer_data = tiles
		end
	end

	for tile_index = 1, #layer_data do
		local tile_gid = layer_data[tile_index]
		local cleared_gid, flip_h, flip_v, flip_d = detiled_internal.parse_gid_flags(tile_gid)
		local tile, tileset = detiled_internal.get_tile_by_gid(map, cleared_gid)
		if tile and tileset then
			local tile_i = ((tile_index - 1) % map.width)
			local tile_j = (math.floor((tile_index - 1) / map.width))
			local pos_x, pos_y = grid_module.cell_to_pos(tile_i, tile_j, map_params)

			local prefab_id = tile.class or tile.type
			if not prefab_id or prefab_id == "" then
				-- Take from tile.image as a default prefab_id and strip path + extension
				local image_path = tile.image
				if image_path and image_path ~= "" then
					prefab_id = detiled_internal.get_filename(image_path)
				end
			end

			local scale_x = flip_h and -1 or 1
			local scale_y = flip_v and -1 or 1
			local rotation = flip_d and -90 or 0
			local transform = {
				position_x = pos_x,
				position_y = pos_y,
				position_z = position_z,
			}
			if scale_x ~= 1 then transform.scale_x = scale_x end
			if scale_y ~= 1 then transform.scale_y = scale_y end
			if rotation ~= 0 then transform.rotation = rotation end

			---@type detiled.entity
			local entity = {
				prefab_id = prefab_id,
				components = {
					prefab_id = prefab_id,
					tiled_layer_id = layer.name,
					transform = transform,
				}
			}

			table.insert(entities, entity)
		end
	end

	return entities
end


---@param layer detiled.map.layer
---@param map detiled.map
---@return detiled.entity[]
local function get_entities_from_object_layer(layer, map)
	---@type detiled.entity[]
	local entities = {}

	local grid_module = GRID_MODULES[map.orientation]
	local map_params = grid_module.get_map_params_from_tiled(map)

	local map_width = map_params.scene.size_x
	local map_height = map_params.scene.size_y
	local position_z = detiled_internal.get_property_value(layer.properties, "position_z") or 0

	for object_index = 1, #layer.objects do
		local object = layer.objects[object_index]
		local rotation = -(object.rotation or 0)

		local object_gid = object.gid
		if object_gid then -- If object has a tileset, spawn from tileset
			local cleared_gid, flip_h, flip_v, flip_d = detiled_internal.parse_gid_flags(object_gid)
			local tile, tileset = detiled_internal.get_tile_by_gid(map, cleared_gid)
			if tile and tileset then
				local entity = {}
				local position_x, position_y, scale_x, scale_y = M.get_defold_position_from_tiled_object(object, tile, map_width, map_height, map_params)
				position_x = position_x + (layer.offsetx or 0)
				position_y = position_y - (layer.offsety or 0)

				if flip_h then scale_x = -scale_x end
				if flip_v then scale_y = -scale_y end
				if flip_d then rotation = rotation - 90 end

				local prefab_id = tile.class or tile.type

				if not prefab_id or prefab_id == "" then
					-- Take from tile.image as a default prefab_id and strip path + extension
					local image_path = tile.image
					if image_path and image_path ~= "" then
						prefab_id = detiled_internal.get_filename(image_path)
					end
				end

				local components = {
					name = object.name ~= "" and object.name or nil,
					prefab_id = prefab_id,
					tiled_id = tostring(object.id),
					tiled_layer_id = layer.name,

					transform = {
						position_x = position_x,
						position_y = position_y,
						position_z = position_z,
						size_x = scale_x ~= 1 and object.width or nil,
						size_y = scale_y ~= 1 and object.height or nil,
						scale_x = scale_x ~= 1 and scale_x or nil,
						scale_y = scale_y ~= 1 and scale_y or nil,
						rotation = rotation,
					}
				}

				if tile.properties then
					local tiled_components = detiled_internal.get_components_property(tile.properties)
					if tiled_components then
						detiled_internal.apply_components(components, tiled_components)
					end
				end

				if object.properties then
					local tiled_components = detiled_internal.get_components_property(object.properties)
					if tiled_components then
						-- Unique case
						if tiled_components.position_z then
							components.transform.position_z = components.transform.position_z + tiled_components.position_z
							tiled_components.position_z = nil
						end

						detiled_internal.apply_components(components, tiled_components)
					end
				end

				entity.prefab_id = prefab_id
				entity.components = components

				table.insert(entities, entity)
			else
				logger:warn("Tile is not found in tileset", {
					gid = object_gid,
					class = object.class,
					name = object.name,
					id = object.id,
				})
			end
		elseif object.class and object.class ~= "" then -- If object is map-created-object and has a prefab to spawn instead
			local entity = {}
			local position_x, position_y, scale_x, scale_y = M.get_defold_position_from_tiled_object(object, nil, map_width, map_height, map_params)
			--position_y = map_height - position_y
			position_x = position_x + (layer.offsetx or 0)
			position_y = position_y - (layer.offsety or 0)
			position_y = position_y - object.height

			local components = {
				name = object.name ~= "" and object.name or nil,
				prefab_id = object.class ~= "" and object.class or nil,
				tiled_id = tostring(object.id),
				tiled_layer_id = layer.name,

				transform = {
					position_x = position_x,
					position_y = position_y,
					position_z = position_z,
					size_x = object.width,
					size_y = object.height,
					scale_x = scale_x ~= 1 and scale_x or nil,
					scale_y = scale_y ~= 1 and scale_y or nil,
					rotation = rotation,
				}
			}

			if object.properties then
				local tiled_components = detiled_internal.get_components_property(object.properties)
				if tiled_components then
					-- Unique case
					if tiled_components.position_z then
						components.transform.position_z = components.transform.position_z + tiled_components.position_z
						tiled_components.position_z = nil
					end

					detiled_internal.apply_components(components, tiled_components)
				end
			end

			entity.prefab_id = object.class
			entity.components = components

			table.insert(entities, entity)
		else -- Empty object from tiled without any prefabs
			local position_x, position_y, scale_x, scale_y = M.get_defold_position_from_tiled_object(object, nil, map_width, map_height, map_params)
			position_x = position_x + (layer.offsetx or 0)
			position_y = position_y - (layer.offsety or 0)
			position_y = position_y - object.height

			local entity = {
				components = {
					name = object.name ~= "" and object.name or nil,
					prefab_id = object.type ~= "" and object.type or nil,
					tiled_id = tostring(object.id),
					tiled_layer_id = layer.name,

					transform = {
						position_x = position_x,
						position_y = position_y,
						position_z = position_z,
						size_x = object.width,
						size_y = object.height,
						rotation = rotation,
					}
				}
			}

			if object.properties then
				local tiled_components = detiled_internal.get_components_property(object.properties)
				if tiled_components then
					-- Unique case
					if tiled_components.position_z then
						entity.components.transform.position_z = (entity.components.transform.position_z or 0) + tiled_components.position_z
						tiled_components.position_z = nil
					end

					detiled_internal.apply_components(entity.components, tiled_components)
				end
			end

			entity.prefab_id = entity.components.prefab_id

			table.insert(entities, entity)
		end
	end

	return entities
end


---@param tiled_map detiled.map
---@return detiled.get_entity_from_map_result
function M.get_entities(tiled_map)
	---@type detiled.entity[]
	local entities = {}

	local grid_module = GRID_MODULES[tiled_map.orientation]
	local map_params = grid_module and grid_module.get_map_params_from_tiled(tiled_map) or nil

	for layer_index = 1, #tiled_map.layers do
		local layer = tiled_map.layers[layer_index]

		if layer.type == "tilelayer" then
			local layer_entities = get_entities_from_tile_layer(layer, tiled_map)
			for index = 1, #layer_entities do
				table.insert(entities, layer_entities[index])
			end
		end

		if layer.type == "objectgroup" then
			local layer_entities = get_entities_from_object_layer(layer, tiled_map)
			for index = 1, #layer_entities do
				table.insert(entities, layer_entities[index])
			end
		end
	end

	return { map_params = map_params, entities = entities }
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


---@param tiled_map detiled.map
---@param layer_name string
function M.is_layer_excluded(tiled_map, layer_name)
	for index = 1, #tiled_map.layers do
		local layer = tiled_map.layers[index]
		if layer.name == layer_name then
			return detiled_internal.get_property_value(layer.properties, "exclude") or false
		end
	end

	return false
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

	do -- Search anchor
		-- If object has anchor point, use it instead
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
	end

	-- Rotate offset in case of rotated object
	local rotation_rad = math.rad(object.rotation)
	local sin = math.sin(rotation_rad)
	local cos = math.cos(rotation_rad)

	local rotated_offset_x = anchor_x * cos + anchor_y * sin
	local rotated_offset_y = -anchor_x * sin + anchor_y * cos

	rotated_offset_x = rotated_offset_x * scale_x
	rotated_offset_y = rotated_offset_y * scale_y

	local position_x = object.x + rotated_offset_x
	local position_y = object.y - rotated_offset_y

	if map_params and map_params.scene.invert_y then
		position_y = map_height - position_y
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

---@param tiled_tileset detiled.tileset
---@return table<string, entity> entities Key is prefab_id
function M.get_decore_entities(tiled_tileset)
	---@type entity[]
	local entities = {}

	local tiles = tiled_tileset.tiles
	for index = 1, #tiles do
		local tile = tiles[index]
		local prefab_id = tile.type
		---@type entity
		local entity = detiled_internal.get_components_property(tile.properties) or {}
		assert(prefab_id, "The class field in entity in tiled tileset should be set")
		entities[prefab_id] = entity
	end

	return entities
end



return M
