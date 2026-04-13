# detiled API

> at /detiled/detiled.lua

## Functions

- [set_logger](#set_logger)
- [parse](#parse)
- [load_tileset](#load_tileset)
- [cell_to_pos](#cell_to_pos)
- [pos_to_cell](#pos_to_cell)


### set_logger

---
```lua
detiled.set_logger([logger_instance])
```

Set a logger instance

- **Parameters:**
	- `[logger_instance]` *(table|detiled.logger|nil)*:

### parse

---
```lua
local layers, map_params = detiled.parse(map_or_path)
```

Load a tiled map and return layers (keyed by layer id) and map params. Entity positions do not include layer offset; add `layer_data.position` when spawning if needed.

Each key in `layers` is a layer id (string). Each value is `detiled.layer_data`: `entities` (array), `properties`, `layer_id`, `visible`, `position` (vmath.vector3: offset_x, offset_y, position_z from layer).

Each entity: `prefab_id`, `position` (vmath.vector3), `scale` (vmath.vector3); optional `image`, `rotation`; optional `name`, `tiled_id`, `size_x`, `size_y`; plus any custom properties from Tiled.

- **Parameters:**
	- `map_or_path` *(string|detiled.map)*:

- **Returns:**
	- *(table<string, detiled.layer_data>)* layers
	- *(detiled.map_params|nil)* map_params

### load_tileset

---
```lua
detiled.load_tileset(tileset_or_path)
```

Load a tileset

- **Parameters:**
	- `tileset_or_path` *(string|detiled.tileset)*:

- **Returns:**
	- `` *(detiled.tileset)*:

### cell_to_pos

---
```lua
detiled.cell_to_pos(i, j, map_params)
```

Convert cell indices to world position. Requires `map_params` from `parse` (same orientation as the map).

- **Parameters:**
	- `i` *(number)*: column index
	- `j` *(number)*: row index
	- `map_params` *(detiled.map_params)*:

- **Returns:**
	- *(number, number)*: x, y

### pos_to_cell

---
```lua
detiled.pos_to_cell(x, y, map_params)
```

Convert world position to cell indices. Requires `map_params` from `parse`.

- **Parameters:**
	- `x` *(number)*: world x
	- `y` *(number)*: world y
	- `map_params` *(detiled.map_params)*:

- **Returns:**
	- *(number, number)*: i, j
