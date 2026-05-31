## Mapa pintado a mano en el editor de TileMap de Godot (sin generación procedural).
class_name HandcraftedMapBackground
extends Node2D

const _MapBounds = preload("res://scripts/world/arena_map_bounds.gd")
const _ArenaWalls = preload("res://scripts/world/arena_boundary_walls.gd")

@export_group("Arena (límites de juego)")
## Tamaño de cada celda del tileset (16 para Sprout Lands, 32 para dungeon procedural).
@export var tile_px: int = 16
## Escala visual del nodo (2.0 si tus tiles son 16px y quieres que se vean como 32px).
@export var map_visual_scale: float = 2.0
## Mitad del mapa en celdas: el área jugable va de -N a N-1.
@export var arena_half_tiles: int = 36
## Celdas de borde que cuentan como muralla (colisión + límite del jugador).
@export var border_tiles: int = 3

@export_group("Capas TileMapLayer")
@export var ground_layer: TileMapLayer
@export var path_layer: TileMapLayer
@export var obstacle_layer: TileMapLayer
@export var decor_layer: TileMapLayer
@export var border_layer: TileMapLayer

@export var setup_static_walls: bool = true

var _camera: Camera2D = null


func _ready() -> void:
	scale = Vector2(map_visual_scale, map_visual_scale)
	z_index = -100
	_apply_layer_z_order()
	_setup_arena()


func bind_camera(camera: Camera2D) -> void:
	_camera = camera


## Mapas manuales no usan MapGenerator; Main cae back a Arena para spawns.
func get_map_generator() -> MapGenerator:
	return null


func get_playable_center() -> Vector2:
	return Arena.get_center() if Arena.is_ready() else Vector2.ZERO


func _apply_layer_z_order() -> void:
	if ground_layer:
		ground_layer.z_index = -100
		ground_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if path_layer:
		path_layer.z_index = -95
		path_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if decor_layer:
		decor_layer.z_index = -90
		decor_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if obstacle_layer:
		obstacle_layer.z_index = -85
		obstacle_layer.y_sort_enabled = true
		obstacle_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if border_layer:
		border_layer.z_index = -80
		border_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _setup_arena() -> void:
	var effective_px: int = _get_effective_tile_px()
	_MapBounds.apply_to_arena(arena_half_tiles, border_tiles, effective_px)
	if setup_static_walls:
		var walls: StaticBody2D = get_node_or_null("BoundaryWalls") as StaticBody2D
		if walls:
			_ArenaWalls.rebuild(walls, float(effective_px))


func _get_effective_tile_px() -> int:
	return maxi(int(round(float(tile_px) * maxf(absf(scale.x), absf(scale.y)))), 1)
