## Generador procedural de mapas para TileMapLayer (Prontera / Payon).
## Adjunta este nodo bajo el fondo del mapa y asigna las capas en el Inspector.
class_name MapGenerator
extends Node

signal generation_finished(result: MapGenerationResult)

enum CellKind {
	EMPTY,
	GROUND,
	PATH,
	OBSTACLE,
	WALL,
}

@export_group("Tema")
@export var map_theme: MapTileCatalog.MapTheme = MapTileCatalog.MapTheme.PRONTERA
@export var generate_on_ready: bool = false
@export var map_seed: int = 0

@export_group("Tamaño del mapa")
## Mitad del mapa en celdas. 50 → 100×100 celdas centradas en (0,0).
@export var map_half_size: int = 36
## Grosor del borde con colisión (muralla perimetral).
@export var border_thickness: int = 3

@export_group("Capas TileMapLayer")
@export var ground_layer: TileMapLayer
@export var path_layer: TileMapLayer
@export var obstacle_layer: TileMapLayer
@export var decor_layer: TileMapLayer
@export var border_layer: TileMapLayer

@export_group("Suelo (FastNoiseLite)")
@export var ground_noise_frequency: float = 0.07
@export var ground_noise_threshold: float = 0.0

@export_group("Caminos")
@export var path_count: int = 2
@export var path_walk_steps: int = 280
@export var path_half_width: int = 2

@export_group("Obstáculos (clústers)")
## Número de bosques / grupos de rocas. Sube para más cuellos de botella.
@export var obstacle_cluster_count: int = 14
## Radio de cada clúster en celdas.
@export var obstacle_cluster_radius: int = 5
## Densidad dentro del clúster (0.0–1.0). Más alto = más árboles/piedras.
@export var obstacle_cluster_fill: float = 0.62
## Distancia mínima del centro del mapa para colocar un clúster.
@export var obstacle_min_dist_from_center: int = 12
@export var decor_scatter_chance: float = 0.035

@export_group("Arena / límites")
@export var setup_arena_bounds: bool = true
@export var rebuild_static_walls: bool = true
@export var static_walls_path: NodePath = ^"../BoundaryWalls"

const _Catalog = preload("res://data/map_tile_catalog.gd")
const _TilesetBuilder = preload("res://scripts/world/map_tileset_builder.gd")
const _MapBounds = preload("res://scripts/world/arena_map_bounds.gd")
const _ArenaWalls = preload("res://scripts/world/arena_boundary_walls.gd")

var last_result: MapGenerationResult = null

var _grid: Dictionary = {}
var _tiles: Dictionary = {}
var _tile_px: int = 16
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _noise: FastNoiseLite = FastNoiseLite.new()
var _min_cell: int = 0
var _max_cell: int = 0


func _ready() -> void:
	if generate_on_ready:
		generate()


func generate(custom_seed: int = -1) -> MapGenerationResult:
	if not _resolve_layers():
		push_error("MapGenerator: asigna las capas TileMapLayer en el Inspector o como hijos del padre.")
		return null
	_clear_layers()
	_tiles = MapTileCatalog.get_tiles(map_theme)
	_tile_px = MapTileCatalog.get_tile_px(map_theme)
	_min_cell = -map_half_size
	_max_cell = map_half_size - 1

	if custom_seed >= 0:
		map_seed = custom_seed
	elif map_seed == 0:
		map_seed = int(Time.get_ticks_usec() & 0x7FFFFFFF)

	_rng.seed = map_seed
	_setup_noise()
	_apply_tileset_to_layers()

	_grid.clear()
	_fill_ground()
	_carve_paths()
	_place_border_walls()
	_place_obstacle_clusters()
	_scatter_decor()
	_paint_all_layers()

	last_result = MapGenerationResult.new()
	last_result.map_seed = map_seed
	last_result.map_theme = map_theme
	last_result.tile_px = _tile_px
	last_result.map_rect = Rect2i(_min_cell, _min_cell, map_half_size * 2, map_half_size * 2)
	last_result.free_spawn_cells = _collect_free_spawn_cells()
	last_result.playable_rect = _compute_playable_rect()

	if setup_arena_bounds:
		_MapBounds.apply_to_arena(map_half_size, border_thickness, _get_effective_tile_px())
	if rebuild_static_walls:
		var walls: StaticBody2D = get_node_or_null(static_walls_path) as StaticBody2D
		if walls:
			_ArenaWalls.rebuild(walls, float(_get_effective_tile_px()))

	generation_finished.emit(last_result)
	if ground_layer and ground_layer.get_used_cells().is_empty():
		push_warning("MapGenerator: GroundLayer quedó vacío — revisa tileset y map_tile_catalog.gd")
	return last_result


func _resolve_layers() -> bool:
	var parent: Node = get_parent()
	if ground_layer == null and parent:
		ground_layer = parent.get_node_or_null("GroundLayer") as TileMapLayer
	if path_layer == null and parent:
		path_layer = parent.get_node_or_null("PathLayer") as TileMapLayer
	if obstacle_layer == null and parent:
		obstacle_layer = parent.get_node_or_null("ObstacleLayer") as TileMapLayer
	if decor_layer == null and parent:
		decor_layer = parent.get_node_or_null("DecorLayer") as TileMapLayer
	if border_layer == null and parent:
		border_layer = parent.get_node_or_null("BorderLayer") as TileMapLayer
	return ground_layer != null


func get_last_result() -> MapGenerationResult:
	return last_result


## Posición mundial aleatoria en celda libre (sin obstáculos ni borde).
func get_random_free_world_position(margin_cells: int = 2) -> Vector2:
	if last_result == null or last_result.free_spawn_cells.is_empty():
		return Vector2.ZERO
	var pool: Array[Vector2i] = last_result.free_spawn_cells
	if margin_cells > 0:
		pool = _filter_cells_with_margin(pool, margin_cells)
	if pool.is_empty():
		pool = last_result.free_spawn_cells
	var cell: Vector2i = pool[_rng.randi_range(0, pool.size() - 1)]
	return _cell_to_world(cell)


## Spawn enemigo fuera del jugador pero en celda transitable (borde del anillo).
func get_enemy_spawn_position(player_world_pos: Vector2, min_distance: float = 320.0) -> Vector2:
	if last_result == null:
		return player_world_pos + Vector2(min_distance, 0.0)
	var candidates: Array[Vector2i] = last_result.free_spawn_cells
	if candidates.is_empty():
		return Arena.random_point_outside_playable(80.0) if Arena.is_ready() else player_world_pos
	for _attempt: int in 32:
		var cell: Vector2i = candidates[_rng.randi_range(0, candidates.size() - 1)]
		var world_pos: Vector2 = _cell_to_world(cell)
		if world_pos.distance_to(player_world_pos) >= min_distance:
			return world_pos
	return _cell_to_world(candidates[_rng.randi_range(0, candidates.size() - 1)])


func is_cell_walkable(world_cell: Vector2i) -> bool:
	var kind: int = int(_grid.get(world_cell, CellKind.EMPTY))
	return kind == CellKind.GROUND or kind == CellKind.PATH


func is_cell_blocked(world_cell: Vector2i) -> bool:
	var kind: int = int(_grid.get(world_cell, CellKind.EMPTY))
	return kind == CellKind.OBSTACLE or kind == CellKind.WALL


func _setup_noise() -> void:
	_noise.seed = map_seed
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = ground_noise_frequency


func _apply_tileset_to_layers() -> void:
	var tile_set: TileSet = _TilesetBuilder.build(map_theme)
	if tile_set == null or tile_set.get_source_count() == 0:
		push_error("MapGenerator: no se pudo construir el TileSet (revisa PNG en assets/tiles/prontera/).")
		return
	for layer: TileMapLayer in _all_layers():
		if layer:
			layer.tile_set = tile_set
			layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			layer.y_sort_enabled = map_theme == MapTileCatalog.MapTheme.PRONTERA


func _all_layers() -> Array[TileMapLayer]:
	return [ground_layer, path_layer, obstacle_layer, decor_layer, border_layer]


func _clear_layers() -> void:
	for layer: TileMapLayer in _all_layers():
		if layer:
			layer.clear()


func _fill_ground() -> void:
	for cell_y: int in range(_min_cell, _max_cell + 1):
		for cell_x: int in range(_min_cell, _max_cell + 1):
			var cell: Vector2i = Vector2i(cell_x, cell_y)
			_grid[cell] = CellKind.GROUND


func _carve_paths() -> void:
	var center: Vector2i = Vector2i.ZERO
	for path_index: int in path_count:
		var start: Vector2i = center if path_index == 0 else _random_interior_cell(8)
		var cursor: Vector2i = start
		for _step: int in path_walk_steps:
			_stamp_path_disk(cursor, path_half_width)
			cursor += _random_cardinal_dir()
			cursor.x = clampi(cursor.x, _min_cell + border_thickness + 2, _max_cell - border_thickness - 2)
			cursor.y = clampi(cursor.y, _min_cell + border_thickness + 2, _max_cell - border_thickness - 2)


func _stamp_path_disk(center: Vector2i, half_width: int) -> void:
	for dy: int in range(-half_width, half_width + 1):
		for dx: int in range(-half_width, half_width + 1):
			if Vector2(dx, dy).length() > float(half_width) + 0.35:
				continue
			var cell: Vector2i = center + Vector2i(dx, dy)
			if _grid.has(cell) and int(_grid[cell]) != CellKind.WALL:
				_grid[cell] = CellKind.PATH


func _place_border_walls() -> void:
	for cell_y: int in range(_min_cell, _max_cell + 1):
		for cell_x: int in range(_min_cell, _max_cell + 1):
			var dist: int = _distance_to_edge(cell_x, cell_y)
			if dist < border_thickness:
				_grid[Vector2i(cell_x, cell_y)] = CellKind.WALL


func _place_obstacle_clusters() -> void:
	for _cluster: int in obstacle_cluster_count:
		var center: Vector2i = _pick_cluster_center()
		if center == Vector2i(-9999, -9999):
			continue
		for dy: int in range(-obstacle_cluster_radius, obstacle_cluster_radius + 1):
			for dx: int in range(-obstacle_cluster_radius, obstacle_cluster_radius + 1):
				var cell: Vector2i = center + Vector2i(dx, dy)
				if not _grid.has(cell):
					continue
				var kind: int = int(_grid[cell])
				if kind == CellKind.WALL or kind == CellKind.PATH:
					continue
				var dist: float = Vector2(dx, dy).length()
				if dist > float(obstacle_cluster_radius):
					continue
				var falloff: float = 1.0 - (dist / float(maxi(obstacle_cluster_radius, 1)))
				if _rng.randf() <= obstacle_cluster_fill * falloff:
					_grid[cell] = CellKind.OBSTACLE


func _scatter_decor() -> void:
	if decor_layer == null:
		return
	for cell_y: int in range(_min_cell, _max_cell + 1):
		for cell_x: int in range(_min_cell, _max_cell + 1):
			var cell: Vector2i = Vector2i(cell_x, cell_y)
			if int(_grid.get(cell, CellKind.EMPTY)) != CellKind.GROUND:
				continue
			if _rng.randf() > decor_scatter_chance:
				continue
			_set_layer_cell(decor_layer, cell, _tiles["decor_grass_tuft"])


func _paint_all_layers() -> void:
	for cell_y: int in range(_min_cell, _max_cell + 1):
		for cell_x: int in range(_min_cell, _max_cell + 1):
			var cell: Vector2i = Vector2i(cell_x, cell_y)
			match int(_grid.get(cell, CellKind.EMPTY)):
				CellKind.GROUND:
					_paint_ground_cell(cell)
				CellKind.PATH:
					_paint_ground_cell(cell)
					if path_layer:
						_set_layer_cell(path_layer, cell, _tiles["path_center"])
				CellKind.OBSTACLE:
					_paint_ground_cell(cell)
					_paint_obstacle_cell(cell)
				CellKind.WALL:
					_paint_wall_cell(cell)


func _paint_ground_cell(cell: Vector2i) -> void:
	if ground_layer == null:
		return
	var n: float = _noise.get_noise_2d(float(cell.x), float(cell.y))
	var ref: Dictionary
	if int(_grid.get(cell, CellKind.EMPTY)) == CellKind.PATH:
		ref = _tiles["path_center"]
	elif n > ground_noise_threshold + 0.25:
		ref = _tiles["ground_grass_flowers"]
	elif n > ground_noise_threshold:
		ref = _tiles["ground_grass_b"]
	elif n < ground_noise_threshold - 0.35:
		ref = _tiles["ground_grass_dark"]
	else:
		ref = _tiles["ground_grass_a"]
	_set_layer_cell(ground_layer, cell, ref)


func _paint_obstacle_cell(cell: Vector2i) -> void:
	if obstacle_layer == null:
		return
	var use_tree: bool = _rng.randf() > 0.42
	var ref: Dictionary
	if use_tree:
		ref = _tiles["prop_tree_round"] if _rng.randf() > 0.5 else _tiles["prop_tree_tall"]
	else:
		ref = _tiles["prop_rock_large"] if _rng.randf() > 0.35 else _tiles["obstacle_rock_small"]
	_set_layer_cell(obstacle_layer, cell, ref)


func _paint_wall_cell(cell: Vector2i) -> void:
	if border_layer == null:
		return
	var ref: Dictionary = _tiles["border_wall_top"]
	if _distance_to_edge(cell.x, cell.y) <= 1:
		ref = _tiles["border_wall_face"]
	elif _is_corner_cell(cell):
		ref = _tiles["border_corner"]
	_set_layer_cell(border_layer, cell, ref)
	if ground_layer:
		_set_layer_cell(ground_layer, cell, _tiles["ground_grass_dark"])


func _set_layer_cell(layer: TileMapLayer, cell: Vector2i, ref: Dictionary) -> void:
	if layer == null or ref.is_empty():
		return
	layer.set_cell(cell, int(ref["source"]), ref["atlas"] as Vector2i)


func _collect_free_spawn_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell_y: int in range(_min_cell, _max_cell + 1):
		for cell_x: int in range(_min_cell, _max_cell + 1):
			var cell: Vector2i = Vector2i(cell_x, cell_y)
			if _is_spawnable_cell(cell):
				result.append(cell)
	return result


func _is_spawnable_cell(cell: Vector2i) -> bool:
	var kind: int = int(_grid.get(cell, CellKind.EMPTY))
	if kind != CellKind.GROUND and kind != CellKind.PATH:
		return false
	return _distance_to_edge(cell.x, cell.y) >= border_thickness + 1


func _filter_cells_with_margin(cells: Array[Vector2i], margin: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell: Vector2i in cells:
		if _has_clearance(cell, margin):
			result.append(cell)
	return result


func _has_clearance(cell: Vector2i, margin: int) -> bool:
	for dy: int in range(-margin, margin + 1):
		for dx: int in range(-margin, margin + 1):
			var other: Vector2i = cell + Vector2i(dx, dy)
			if is_cell_blocked(other):
				return false
	return true


func _compute_playable_rect() -> Rect2:
	var tile_px: int = _get_effective_tile_px()
	var inner_min: int = _min_cell + border_thickness
	var inner_max: int = _max_cell - border_thickness
	var left: float = float(inner_min * tile_px)
	var top: float = float(inner_min * tile_px)
	var right: float = float(inner_max + 1) * float(tile_px)
	var bottom: float = float(inner_max + 1) * float(tile_px)
	return Rect2(left, top, right - left, bottom - top)


func _get_effective_tile_px() -> int:
	var scale_factor: float = 1.0
	var parent_node: Node2D = get_parent() as Node2D
	if parent_node:
		scale_factor = maxf(absf(parent_node.scale.x), absf(parent_node.scale.y))
	return maxi(int(round(float(_tile_px) * scale_factor)), 1)


func _pick_cluster_center() -> Vector2i:
	for _attempt: int in 48:
		var cell: Vector2i = _random_interior_cell(obstacle_min_dist_from_center)
		if int(_grid.get(cell, CellKind.EMPTY)) == CellKind.GROUND:
			if cell.length() >= obstacle_min_dist_from_center:
				return cell
	return Vector2i(-9999, -9999)


func _random_interior_cell(min_margin: int) -> Vector2i:
	var lo: int = _min_cell + min_margin
	var hi: int = _max_cell - min_margin
	return Vector2i(_rng.randi_range(lo, hi), _rng.randi_range(lo, hi))


func _random_cardinal_dir() -> Vector2i:
	var dirs: Array[Vector2i] = [
		Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN
	]
	return dirs[_rng.randi_range(0, dirs.size() - 1)]


func _distance_to_edge(cell_x: int, cell_y: int) -> int:
	return mini(
		mini(cell_x - _min_cell, _max_cell - cell_x),
		mini(cell_y - _min_cell, _max_cell - cell_y)
	)


func _is_corner_cell(cell: Vector2i) -> bool:
	var d_x: int = mini(cell.x - _min_cell, _max_cell - cell.x)
	var d_y: int = mini(cell.y - _min_cell, _max_cell - cell.y)
	return d_x < border_thickness and d_y < border_thickness


func _cell_to_world(cell: Vector2i) -> Vector2:
	var layer: TileMapLayer = ground_layer if ground_layer else path_layer
	if layer == null:
		return Vector2(float(cell.x * _tile_px), float(cell.y * _tile_px))
	return layer.to_global(layer.map_to_local(cell))


## Resultado expuesto al spawner y otros sistemas.
class MapGenerationResult:
	var map_seed: int = 0
	var map_theme: MapTileCatalog.MapTheme = MapTileCatalog.MapTheme.PRONTERA
	var tile_px: int = 16
	var map_rect: Rect2i = Rect2i()
	var playable_rect: Rect2 = Rect2()
	var free_spawn_cells: Array[Vector2i] = []

	func get_free_cell_count() -> int:
		return free_spawn_cells.size()
