local base64 = require("detiled.internal.base64")

local LOADED_TILESETS = {}

local M = {}

local TYPE_TABLE = "table"

---Split string by separator
---@param s string
---@param sep string
function M.split(s, sep)
	sep = sep or "%s"
	local t = {}
	local i = 1
	for str in string.gmatch(s, "([^" .. sep .. "]+)") do
		t[i] = str
		i = i + 1
	end
	return t
end


---Check if table contains value
---@param t table
---@param value any
---@return boolean
function M.contains(t, value)
	for index = 1, #t do
		if t[index] == value then
			return true
		end
	end

	return false
end


---Create a copy of lua table
---@param orig table The table to copy
---@return table
function M.deepcopy(orig)
	local copy = orig
	if type(orig) == "table" then
		-- It's faster than copying or JSON serialization
		return sys.deserialize(sys.serialize(orig))
	end

	return copy
end


---Load JSON file from game resources folder (by relative path to game.project)
---Return nil if file not found or error
---@param json_path string
---@return table|nil
function M.load_json(json_path)
	local resource, is_error = sys.load_resource(json_path)
	if is_error or not resource then
		return nil
	end

	return json.decode(resource)
end


-- Get the filename (image) when given a complete path
function M.get_filename(path)
	local parts = M.split(path, "/")
	local name = parts[#parts]
	local basename = M.split(name, ".")[1]
	return basename
end


-- Get the filename (image) when given a complete path
function M.get_extname(path)
	local parts = M.split(path, "/")
	local name = parts[#parts]
	local basename = M.split(name, ".")[2]
	return basename
end


---@param source string
---@return detiled.tileset|nil
function M.get_tileset_by_source(source)
	local tileset_name = M.get_filename(source)

	if LOADED_TILESETS[tileset_name] then
		return LOADED_TILESETS[tileset_name]
	end

	return nil
end


---@param game_project_field_id string @field id from game.project with resource path to json
---@param callback fun(file_data: table) @callback function with file data
function M.split_json_resources(game_project_field_id, callback)
	local json_path = sys.get_config_string(game_project_field_id, "")
	if json_path == "" then
		return
	end

	local paths = M.split(json_path, ",")
	for index = 1, #paths do
		local path = paths[index]
		local data = M.load_json(path)
		if data then
			callback(data)
		end
	end
end


---@param tileset detiled.tileset
---@return detiled.tileset
function M.load_tileset(tileset)
	if LOADED_TILESETS[tileset.name] then
		return LOADED_TILESETS[tileset.name]
	end

	LOADED_TILESETS[tileset.name] = tileset

	return tileset
end


local GID_FLIP_H = 0x80000000
local GID_FLIP_V = 0x40000000
local GID_FLIP_D = 0x20000000
local GID_MASK = 0x0FFFFFFF

---Parse Tiled global tile ID into cleared id and flip flags (see https://doc.mapeditor.org/en/stable/reference/global-tile-ids/)
---@param gid number
---@return number cleared_gid, boolean flip_h, boolean flip_v, boolean flip_d
function M.parse_gid_flags(gid)
	local flip_h = (bit.band(gid, GID_FLIP_H) ~= 0)
	local flip_v = (bit.band(gid, GID_FLIP_V) ~= 0)
	local flip_d = (bit.band(gid, GID_FLIP_D) ~= 0)
	local cleared = bit.band(gid, GID_MASK)
	return cleared, flip_h, flip_v, flip_d
end


---@param map detiled.map
---@param tile_global_id number
---@return detiled.tileset.tile|nil, detiled.tileset|nil
function M.get_tile_by_gid(map, tile_global_id)
	for tileset_index = #map.tilesets, 1, -1 do
		local tileset = map.tilesets[tileset_index]
		local first_gid = tileset.firstgid
		if tile_global_id >= first_gid then
			local tile_id = tile_global_id - first_gid

			local tileset_data = M.get_tileset_by_source(tileset.source)
			if not tileset_data then
				return nil, nil
			end

			local tile = nil
			for index = 1, #tileset_data.tiles do
				if tileset_data.tiles[index].id == tile_id then
					tile = tileset_data.tiles[index]
					break
				end
			end

			return tile, tileset_data
		end
	end

	return nil
end


---@param properties detiled.map.property[]
---@param property_name string
---@return any|nil
function M.get_property_value(properties, property_name)
	if not properties then
		return nil
	end

	for index = 1, #properties do
		local property = properties[index]
		if property.name == property_name then
			return property.value
		end
	end

	return nil
end


---@param components detiled.map.property[]|nil
---@return table|nil
function M.get_components_property(components)
	if not components then
		return nil
	end

	local parsed_components = {}

	for index = 1, #components do
		local component = components[index]
		if component.propertytype == component.name then
			-- It's a component
			parsed_components[component.name] = component.value
		end

		if not component.propertytype then
			-- It's a property
			parsed_components[component.name] = component.value
		end
	end

	return parsed_components
end


--- Merge one table into another recursively
---@param t1 table
---@param t2 any
function M.merge_tables(t1, t2)
	for k, v in pairs(t2) do
		if type(v) == "table" and type(t1[k]) == "table" then
			M.merge_tables(t1[k], v)
		else
			t1[k] = v
		end
	end
end


---@param entity table<string, any>
---@param components table<string, any>
function M.apply_components(entity, components)
	for component_id, component_data in pairs(components) do
		if type(component_data) == TYPE_TABLE then
			entity[component_id] = entity[component_id] or {}
			M.merge_tables(entity[component_id], component_data)
		else
			entity[component_id] = component_data
		end
	end
end


---@param entity detiled.entity
---@param tile detiled.tileset.tile|nil
function M.apply_tile_properties_to_entity(entity, tile)
	if not tile or not tile.properties then return end
	local tiled_components = M.get_components_property(tile.properties)
	if tiled_components then
		M.apply_components(entity, tiled_components)
	end
end


---@param entity detiled.entity
---@param object detiled.map.object
function M.apply_object_properties_to_entity(entity, object)
	if not object.properties then return end
	local tiled_components = M.get_components_property(object.properties)
	if not tiled_components then return end
	if tiled_components.position_z then
		entity.position_z = (entity.position_z or 0) + tiled_components.position_z
		tiled_components.position_z = nil
	end
	M.apply_components(entity, tiled_components)
end


---@param tiled_map detiled.map
---@param layer_name string
---@return boolean
function M.is_layer_excluded(tiled_map, layer_name)
	for index = 1, #tiled_map.layers do
		local layer = tiled_map.layers[index]
		if layer.name == layer_name then
			return M.get_property_value(layer.properties, "exclude") or false
		end
	end
	return false
end


---@param tile detiled.tileset.tile
---@return string|nil
function M.get_prefab_id_from_tile(tile)
	local prefab_id = tile.class or tile.type
	if not prefab_id or prefab_id == "" then
		local image_path = tile.image
		if image_path and image_path ~= "" then
			prefab_id = M.get_filename(image_path)
		end
	end
	return prefab_id
end


---@param tile detiled.tileset.tile
---@param tileset detiled.tileset
---@return string|nil
function M.get_image_name_from_tile(tile, tileset)
	local image_path = tile.image or (tileset and tileset["image"])
	if not image_path or image_path == "" then
		return nil
	end
	return M.get_filename(image_path)
end


---@param layer detiled.map.layer
---@return number[]|string layer data as array of GIDs or raw data
function M.unpack_tile_layer_data(layer)
	local layer_data = layer.data
	if layer.encoding == "base64" then
		local decoded_data = base64.decode(layer_data) --[[ @as string ]]
		if layer.compression == "zlib" then
			local inflated_data = zlib.inflate(decoded_data)
			local tiles = {}
			for i = 1, #inflated_data, 4 do
				local b1, b2, b3, b4 = inflated_data:byte(i, i + 3)
				local gid = b1 + b2 * 256 + b3 * 65536 + b4 * 16777216
				table.insert(tiles, gid)
			end
			layer_data = tiles
		end
	end
	return layer_data
end


---Rotated and scaled 2D offset (anchor or anchor relative to origin).
---@param ax number
---@param ay number
---@param scale_x number
---@param scale_y number
---@param cos number
---@param sin number
---@return number, number
function M.rotated_anchor_offset(ax, ay, scale_x, scale_y, cos, sin)
	local rx = ax * cos + ay * sin
	local ry = -ax * sin + ay * cos
	return rx * scale_x, ry * scale_y
end


return M
