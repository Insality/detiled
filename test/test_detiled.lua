return function()
	describe("Detiled", function()
		---@type detiled
		local detiled = {}

		before(function()
			detiled = require("detiled.detiled")
		end)

		it("Should init correclty", function()
			detiled.load_tileset("/resources/tilesets/shooting_circle.json")
			local entities, map_params = detiled.get_entity_from_map("/resources/maps/game.json")
			assert(entities)
			assert(map_params)
		end)
	end)
end
