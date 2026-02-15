return function()
	describe("Detiled", function()
		---@type detiled
		local detiled = {}

		before(function()
			detiled = require("detiled.detiled")
		end)

		it("Should init correclty", function()
			detiled.load_tileset("/resources/tilesets/shooting_circle.json")
			local result = detiled.get_entity_from_map("/resources/maps/game.json")
			assert(result)
			assert(result.entities)
			assert(result.map_params)
		end)
	end)
end
