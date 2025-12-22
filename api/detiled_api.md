# detiled API

> at /detiled/detiled.lua

## Functions

- [set_logger](#set_logger)
- [get_entity_from_map](#get_entity_from_map)
- [load_tileset](#load_tileset)


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

Load a tiled map as a Decore entity
You can add this entity with `world:addEntity(entity)`

- **Parameters:**
	- `map_or_path` *(string|detiled.map)*:

- **Returns:**
	- `` *(entity)*:

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
