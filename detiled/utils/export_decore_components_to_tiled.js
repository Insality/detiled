const fs = require("fs");
const path = require("path");

console.log("Export components to tiled")

let tiled_project_path = "./tiled/tiled.tiled-project";
let decore_components_path = "./resources/ecs/components.json";

let tiled_project = JSON.parse(fs.readFileSync(tiled_project_path, 'utf8'));
let decore_components = JSON.parse(fs.readFileSync(decore_components_path, 'utf8'));

console.log(tiled_project)

let components = {}

//for (let component of decore_components.components) {
//	console.log(component
//}

// decore components - key value pairs, key is a name - value is a table of properties. can be string, number, or table
for (let component_name in decore_components.components) {
	let component = {
		name: component_name,
		type: "class",
		useAs: [ "property" ],
		members: [],
	}

	let components_table = decore_components.components[component_name];
	for (let key in components_table) {
		let value = components_table[key];
		if (value == null) {
			continue;
		}

		let value_type = typeof value;
		// float string bool class enum color object

		let member_type = "string";
		if (value_type == "number") {
			member_type = "float";
		}
		if (value_type == "object") {
			member_type = "object";
		}
		if (value_type == "boolean") {
			member_type = "bool";
		}

		console.log(value_type, value);

		let member = {
			name: key,
			type: member_type,
			value: value,
		}
		component.members.push(member);
	}
	console.log(component.members);

	components[component_name] = component;
}

console.log(components);
