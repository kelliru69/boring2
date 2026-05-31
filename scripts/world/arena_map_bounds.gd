## Calcula el rectángulo jugable alineado con el borde visible del tilemap.
class_name ArenaMapBounds
extends RefCounted


static func get_world_rect(arena_half_tiles: int, tile_px: int) -> Rect2:
	var half_px: float = float(arena_half_tiles * tile_px)
	return Rect2(Vector2(-half_px, -half_px), Vector2(half_px * 2.0, half_px * 2.0))


static func get_playable_rect(arena_half_tiles: int, border_tiles: int, tile_px: int) -> Rect2:
	var inner_min_cell: int = -arena_half_tiles + border_tiles
	var inner_max_cell: int = arena_half_tiles - 1 - border_tiles
	var left: float = float(inner_min_cell * tile_px)
	var top: float = float(inner_min_cell * tile_px)
	var right: float = float(inner_max_cell + 1) * float(tile_px)
	var bottom: float = float(inner_max_cell + 1) * float(tile_px)
	return Rect2(left, top, right - left, bottom - top)


static func apply_to_arena(arena_half_tiles: int, border_tiles: int, tile_px: int) -> void:
	Arena.setup_tilemap(
		get_world_rect(arena_half_tiles, tile_px),
		get_playable_rect(arena_half_tiles, border_tiles, tile_px)
	)
