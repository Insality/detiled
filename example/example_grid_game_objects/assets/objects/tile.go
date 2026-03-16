components {
  id: "set_sprite"
  component: "/example/assets/hexgrid/set_sprite.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"tile_0000\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/example/example_grid_game_objects/assets/grid_game_objects.atlas\"\n"
  "}\n"
  ""
}
