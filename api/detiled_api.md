# detiled API

> at /detiled/detiled.lua

## Functions

- [set_logger](#set_logger)
- [parse](#parse)
- [cell_to_pos](#cell_to_pos)
- [pos_to_cell](#pos_to_cell)
- [load_tileset](#load_tileset)


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
detiled.parse(map_or_path)
```

Get layers and map params from a map. Each layer has entities, properties, layer_id, visible, position (offset).

- **Parameters:**
	- `map_or_path` *(string|detiled.map)*:

- **Returns:**
	- `` *(table<string, detiled.layer_data>)*:
	- `` *(detiled.map_params|nil)*:

### cell_to_pos

---
```lua
detiled.cell_to_pos(i, j, map_params)
```

Convert cell indices to world position

- **Parameters:**
	- `i` *(number)*:
	- `j` *(number)*:
	- `map_params` *(detiled.map_params)*:

- **Returns:**
	- `` *(number)*:
	- `` *(number)*:

### pos_to_cell

---
```lua
detiled.pos_to_cell(x, y, map_params)
```

Convert world position to cell indices

- **Parameters:**
	- `x` *(number)*:
	- `y` *(number)*:
	- `map_params` *(detiled.map_params)*:

- **Returns:**
	- `` *(number)*:
	- `` *(number)*:

### load_tileset

---
```lua
detiled.load_tileset(tileset_or_path)
```

Load a tileset to internal cache, so maps can reference it by name while parsing

- **Parameters:**
	- `tileset_or_path` *(string|detiled.tileset)*: Path to tileset JSON file or tileset table

- **Returns:**
	- `` *(detiled.tileset)*:

