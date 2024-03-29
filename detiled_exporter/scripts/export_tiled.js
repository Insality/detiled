const fs = require("fs");
const os = require("os");
const path = require("path");
const rimraf = require("rimraf");
const process = require("process");
const helper = require("../helper");
const Quaternion = require('quaternion');
const constants = require("../constants");
const { execSync } = require('child_process');
const defold_parser = require("defold-parser");

const tilesets = require("./process_tilesets")
const maps = require("./process_maps")

const COLLECTION_TEMPLATE = fs.readFileSync(path.join(__dirname, "templates/collection.template")).toString('utf8')

let TILED_PATH = process.env.TILED || "/Applications/Tiled.app/Contents/MacOS/Tiled"


function process_tileset(data, output_path, mapping) {
	tilesets.generate_factories(data, output_path, mapping)
}


function get_object_info(map_data, object) {
	let tilesets = map_data.tilesets

	let info = {
		name: "",
		object_id: "0",
	}
	for (let i in tilesets) {
		if (object.gid >= tilesets[i].firstgid) {
			info.name = tilesets[i].name
			info.object_id = (object.gid - tilesets[i].firstgid)
		}
	}

	return info
}


function autofill_detiled_properties(object, mapping_info) {
	if (!mapping_info.properties) {
		return
	}

	for (key in mapping_info.properties) {
		let property_path = key.split(":")
		if (property_path[2] == "detiled_init_image") {
			object.properties = object.properties || []
			object.properties.push({
				name: key,
				type: "string",
				value: mapping_info.image_name
			})
		}
		if (property_path[2] == "detiled_image_url") {
			object.properties = object.properties || []
			object.properties.push({
				name: key,
				type: "string",
				value: mapping_info.image_url
			})
		}
	}
}


function get_properties_for_collection(object, mapping_info) {
	let properties_by_go = {}
	let result = []

	autofill_detiled_properties(object, mapping_info)

	if (object.properties) {
		for (let index in object.properties) {
			let property = object.properties[index]
			let property_info = helper.tiled_to_defold_property(property.name, property.value, property.type)
			let property_path = property_info.key.split(":")
			properties_by_go[property_path[0]] = properties_by_go[property_path[0]] || []
			properties_by_go[property_path[0]].push({
				id: [ property_path[1] ],
				properties: [{
					id: [ property_path[2] ],
					value: [ property_info.value ],
					type: [ property_info.type ]
				}]
			})
		}
	}

	for (let key in properties_by_go) {
		result.push({
			id: [ key ],
			properties: properties_by_go[key]
		})
	}

	return result
}


function get_properties_for_object(object, mapping_info) {
	let result = []

	autofill_detiled_properties(object, mapping_info)

	if (object.properties) {
		for (let index in object.properties) {
			let property = object.properties[index]
			let property_info = helper.tiled_to_defold_property(property.name, property.value, property.type)
			let property_path = property_info.key.split(":")
			result.push({
				id: [ property_path[1] ],
				properties: [{
					id: [ property_path[2] ],
					value: [ property_info.value ],
					type: [ property_info.type ]
				}]
			})
		}
	}

	return result
}


function process_map(map_path, data, output_path, mapping) {
	let name = path.basename(map_path, ".json")
	console.log("Process map", name)
	maps.generate_spawners(name, data, output_path)

	// Add tilesource name to the map
	for (let i in data.tilesets) {
		let d = data.tilesets[i]
		d.name = path.basename(d.source, ".tsx")
	}

	let map_name_collection = name + ".collection"
	let map_folder = path.join(output_path, "maps", name)
	let map_collection_path = path.join(map_folder, map_name_collection)

	let is_export_collection = helper.is_export_collection(data)
	if (is_export_collection) {
		let collection_path = path.join(map_collection_path)
		let collection_parsed = defold_parser.load_from_file(collection_path)

		// Add objects
		let tilelayer_counter = 0
		for (let index in data.layers) {
			let layer = data.layers[index]
			if (layer.type == "tilelayer") {
				tilelayer_counter += 1
			}
			if (layer.type == "objectgroup") {
				let is_no_export = helper.get_property(layer.properties, "no_export", false)
				if (is_no_export) {
					helper.log("Skip export of layer " + layer.name + " due property no_export")
					continue;
				}

				// Create collection with this layer
				let layer_name = layer.name.replaceAll(" ", "_").toLowerCase()
				let collection_layer_name = name + "_" + layer_name
				let collection_layer = COLLECTION_TEMPLATE.replace("{1}", collection_layer_name)
				let collection_layer_data = defold_parser.decode_object(collection_layer)

				for (o_key in layer.objects) {
					let object = layer.objects[o_key]
					let object_info = get_object_info(data, object)
					let mapping_info = mapping[object_info.name]["" + object_info.object_id]
					if (!mapping_info) {
						console.log("Error wrong object on layer", object_info, layer.name)
						continue
					}

					let height = data.height * data.tileheight
					let object_name = object.name.length > 0 && object.name || mapping_info.object_name
					let object_id = object_name + "_" + object.id

					let rotation = object.rotation * Math.PI/180
					let scale_x = object.width / mapping_info.width
					let scale_y = object.height / mapping_info.height

					// TODO: This should be in module Grid. Need to Fill hexgrid and isogrid also

					// Get offset from object point in Tiled to Defold assets object
					// Tiled point in left bottom, Defold - in object center
					// And add sprite anchor.x for visual correct posing from tiled (In Tiled we pos the image)
					let offset = {
						x: (mapping_info.width/2 + mapping_info.anchor.x) * scale_x,
						y: (mapping_info.height/2 - mapping_info.anchor.y) * scale_y,
					}
					// Rotate offset in case of rotated object
					let rotated_offset = {
						x: offset.x * Math.cos(rotation) + offset.y * Math.sin(rotation),
						y: offset.x * Math.sin(rotation) - offset.y * Math.cos(rotation),
					}

					let object_x = object.x + rotated_offset.x
					// Height - {} is only if Y coords are inverted (In Tiled it's true)
					let object_y = (height - (object.y + rotated_offset.y))

					// Parse radians to Quaternion. In Defold collections GO have vector4 with quat value
					let quat_rotation = Quaternion.fromEuler(-rotation, 0, 0).normalize()
					if (mapping_info.is_collection) {
						let properties = get_properties_for_collection(object, mapping_info)
						collection_layer_data.collection_instances = collection_layer_data.collection_instances || []
						collection_layer_data.collection_instances.push({
							id: [ object_id ],
							instance_properties: properties,
							collection: [ mapping_info.go_path ],
							position: [{ x: [ object_x ], y: [ object_y ], z: [ 0 ] }],
							rotation: [{ x: [ quat_rotation.x ], y: [ quat_rotation.y ], z: [ quat_rotation.z ], w: [ quat_rotation.w ] }],
							scale3: [{ x: [ scale_x ], y: [ scale_y ], z: [ 1 ] }]
						})
					} else {
						collection_layer_data.instances = collection_layer_data.instances || []
						let properties = get_properties_for_object(object, mapping_info)
						collection_layer_data.instances.push({
							id: [ object_id ],
							component_properties: properties,
							prototype: [ mapping_info.go_path ],
							position: [{ x: [ object_x ], y: [ object_y ], z: [ 0 ] }],
							rotation: [{ x: [ quat_rotation.x ], y: [ quat_rotation.y ], z: [ quat_rotation.z ], w: [ quat_rotation.w ] }],
							scale3: [{ x: [ scale_x ], y: [ scale_y ], z: [ 1 ] }]
						})
					}
				}

				let layer_collection_path = path.join(map_folder, collection_layer_name + ".collection")
				defold_parser.save_to_file(layer_collection_path, collection_layer_data)

				let object_layer_z = helper.get_property(layer.properties, "z", 0.0001 * tilelayer_counter)
				// Add layer collection
				let layer_object_instance = {
					id: [ layer_name ],
					collection: [ "/" + path.relative(process.cwd(), layer_collection_path) ],
					position: [ { x: [ 0 ], y: [ 0 ], z: [ object_layer_z ] } ],
					rotation: [ { x: [ 0 ], y: [ 0 ], z: [ 0 ], w: [ 0 ] } ],
					scale3: [ { x: [ 0 ], y: [ 0 ], z: [ 0 ] } ],
				}
				collection_parsed.collection_instances = collection_parsed.collection_instances || []
				collection_parsed.collection_instances.push(layer_object_instance)
			}
		}

		collection_parsed.name = [ name ]
		defold_parser.save_to_file(collection_path, collection_parsed)
	}

	fs.mkdirSync(map_folder, { recursive: true })
	let map_output_path = path.join(output_path, "json_maps")
	fs.mkdirSync(map_output_path, { recursive: true })
	fs.writeFileSync(path.join(map_output_path, path.basename(map_path)), JSON.stringify(data))
}


function process_json(json_path, output_path, mapping) {
	let json_content = JSON.parse(fs.readFileSync(json_path))
	let json_type = json_content.type

	if (json_type == "tileset") {
		process_tileset(json_content, output_path, mapping)
	}
	if (json_type == "map") {
		process_map(json_path, json_content, output_path, mapping)
	}
	console.log("")
}


function convert_tilesets_to_json(tiled_tilesets_path, temp_tilesets_folder) {
	let tilesets = fs.readdirSync(tiled_tilesets_path)
		.filter(name => name.endsWith(".tsx"))

	for (let i in tilesets) {
		let tileset_name = tilesets[i]
		let tileset_path = path.join(tiled_tilesets_path, tileset_name)
		let tileset_name_json = path.basename(tileset_name, ".tsx") + ".json"

		let temp_tileset_path = path.join(temp_tilesets_folder, tileset_name_json)
		execSync(`${TILED_PATH} --export-tileset "${tileset_path}" "${temp_tileset_path}"`)
	}
}


function convert_maps_to_json(tiled_maps_path, temp_maps_folder, output_collection_path) {
	let maps = fs.readdirSync(tiled_maps_path)
		.filter(name => name.endsWith(".tmx"))

	for (let i in maps) {
		let map_name = maps[i]
		let map_basename = path.basename(map_name, ".tmx")
		let map_path = path.join(tiled_maps_path, map_name)
		let map_name_json = map_basename + ".json"
		let map_name_collection = map_basename + ".collection"

		let temp_map_json_path = path.join(temp_maps_folder, map_name_json)
		execSync(`${TILED_PATH} --export-map "${map_path}" "${temp_map_json_path}"`, {stdio: 'inherit'})

		let json_content = JSON.parse(fs.readFileSync(temp_map_json_path))
		let is_export_collection = helper.is_export_collection(json_content)

		if (is_export_collection) {
			let map_folder = path.join(output_collection_path, map_basename)
			let map_collection_path = path.join(map_folder, map_name_collection)
			fs.mkdirSync(map_folder, { recursive: true })
			execSync(`${TILED_PATH} --export-map "${map_path}" "${map_collection_path}"`, {stdio: 'inherit'})
		}
	}
}


function start_process_dir(tilesets_path, maps_path, output_path) {
	rimraf.sync(output_path)
	fs.mkdirSync(output_path, { recursive: true })

	let jsons = []

	let temp_tilesets_folder = fs.mkdtempSync(os.tmpdir())
	convert_tilesets_to_json(tilesets_path, temp_tilesets_folder)
	let tilesets = fs.readdirSync(temp_tilesets_folder)
		.filter(name => name.endsWith(".json"))
		.map(name => path.join(temp_tilesets_folder, name))

	let temp_maps_folder = fs.mkdtempSync(os.tmpdir())
	let map_output_folder = path.join(output_path, "maps")
	convert_maps_to_json(maps_path, temp_maps_folder, map_output_folder)
	let maps = fs.readdirSync(temp_maps_folder)
		.filter(name => name.endsWith(".json"))
		.map(name => path.join(temp_maps_folder, name))

	jsons = tilesets.concat(maps)

	console.log("Process next files:", jsons)

	let mapping = {}
	for (let i in jsons) {
		process_json(jsons[i], output_path, mapping)
	}

	let mapping_path = path.join(output_path, "mapping.json")
	fs.writeFileSync(mapping_path, JSON.stringify(mapping, null, 4))
	console.log("Write", mapping_path)

	fs.rmSync(temp_tilesets_folder, { recursive: true });
	fs.rmSync(temp_maps_folder, { recursive: true });
}


function start(tilesets_folder_path, maps_folder_path, output_folder_path) {
	console.log("Start tiled generator")

	let tilesets_path = path.join(path.resolve(tilesets_folder_path), constants.TILESETS_FOLDER_NAME)
	let maps_path = path.resolve(maps_folder_path)
	let output_path = path.resolve(output_folder_path)
	start_process_dir(tilesets_path, maps_path, output_path)
}

module.exports.start = start
