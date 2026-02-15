# detiled API

> at /detiled/detiled.lua

## Functions

- [set_logger](#set_logger)
- [get_entity_from_map](#get_entity_from_map)
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

### get_entity_from_map

---
```lua
detiled.get_entity_from_map(map_or_path)
```

Load a tiled map and return map params and entities. Use `result.entities` to spawn and `result.map_params` for coordinate conversion.

- **Parameters:**
	- `map_or_path` *(string|detiled.map)*:

- **Returns:**
	- *(table)* `{ map_params = table|nil, entities = detiled.entity[] }`

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
detiled.cell_to_pos(map_params, i, j)
```

Convert cell indices to world position. Requires `map_params` from `get_entity_from_map` (same orientation as the map).

- **Parameters:**
	- `map_params` *(table)*:
	- `i` *(number)*: column index
	- `j` *(number)*: row index

- **Returns:**
	- *(number, number)*: x, y

### pos_to_cell

---
```lua
detiled.pos_to_cell(map_params, x, y)
```

Convert world position to cell indices. Requires `map_params` from `get_entity_from_map`.

- **Parameters:**
	- `map_params` *(table)*:
	- `x` *(number)*: world x
	- `y` *(number)*: world y

- **Returns:**
	- *(number, number)*: i, j
