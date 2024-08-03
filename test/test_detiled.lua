local decore = require("decore.decore")

return function()
	describe("Detiled", function()
		---@type detiled
		local detiled = {}

		before(function()
			detiled = require("detiled.detiled")
			decore.register_components("/resources/components.json")
			decore.register_entities("/resources/entities.json")

			decore.set_logger({
				trace = function(_, message, context) print(message) end,
				debug = function(_, message, context) print(message) end,
				info = function(_, message, context) print(message) end,
				warn = function(_, message, context) print(message) end,
				error = function(_, message, context) print(message) end,
			})
		end)

		it("Should init correclty", function()
			local entities_packs_data = detiled.get_entities_packs_data("/resources/tilesets_list.json")
			assert(entities_packs_data)
			assert(entities_packs_data[1])
			assert(entities_packs_data[1].pack_id == "shooting_circle")
			assert(next(entities_packs_data[1].entities))

			if entities_packs_data then
				for _, pack_data in ipairs(entities_packs_data) do
					decore.register_entities(pack_data)
				end
			end

			local worlds_packs_data = detiled.get_worlds_packs_data("/resources/maps_list.json")
			assert(worlds_packs_data)
			assert(worlds_packs_data[1])
			assert(worlds_packs_data[1].pack_id == "tiled")
			assert(next(worlds_packs_data[1].worlds))

			if worlds_packs_data then
				for _, pack_data in ipairs(worlds_packs_data) do
					decore.register_worlds(pack_data)
				end
			end

			decore.print_loaded_packs_debug_info()
		end)
	end)
end
