## Payon Dungeon — mapa procedural (misma escala visual que Prontera).
extends HandcraftedMapBackground

const _TilesetBuilder = preload("res://scripts/world/map_tileset_builder.gd")
const _MapGenerator = preload("res://scripts/world/map_generator.gd")

@export var auto_assign_tileset: bool = true
@export var generate_map_on_ready: bool = true
@export var procedural_seed: int = 0

var _map_generator: MapGenerator = null


func _ready() -> void:
	modulate = Color.WHITE
	if auto_assign_tileset:
		_ensure_tileset_on_layers()
	super._ready()
	_setup_map_generator()
	if generate_map_on_ready:
		call_deferred("_run_map_generation")


func get_map_generator() -> MapGenerator:
	return _map_generator


func _setup_map_generator() -> void:
	if _map_generator != null:
		return
	_map_generator = MapGenerator.new()
	_map_generator.name = "MapGenerator"
	add_child(_map_generator)
	_map_generator.map_theme = MapTileCatalog.MapTheme.PAYON
	_map_generator.map_half_size = arena_half_tiles
	_map_generator.border_thickness = border_tiles
	_map_generator.map_seed = procedural_seed
	_map_generator.ground_layer = ground_layer
	_map_generator.path_layer = path_layer
	_map_generator.obstacle_layer = obstacle_layer
	_map_generator.decor_layer = decor_layer
	_map_generator.border_layer = border_layer
	_map_generator.setup_arena_bounds = true
	_map_generator.rebuild_static_walls = true
	_map_generator.static_walls_path = NodePath("BoundaryWalls")


func _run_map_generation() -> void:
	if _map_generator:
		_map_generator.generate()


func _ensure_tileset_on_layers() -> void:
	var tile_set: TileSet = _TilesetBuilder.build(MapTileCatalog.MapTheme.PAYON)
	if tile_set == null:
		return
	for layer: TileMapLayer in [ground_layer, path_layer, obstacle_layer, decor_layer, border_layer]:
		if layer and layer.tile_set == null:
			layer.tile_set = tile_set
