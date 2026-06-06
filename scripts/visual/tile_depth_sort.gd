## Orden de dibujo 2D por fila de tile (profundidad top-down estilo RO).
##
## Pantalla: Y menor = tile "arriba" (norte). Y mayor = tile "abajo" (sur).
## - Mobs en fila <= jugador: detrás del jugador.
## - Mobs en fila > jugador: delante del jugador.
class_name TileDepthSort
extends RefCounted

const DEFAULT_TILE_SIZE_PX: float = 32.0
const Z_STRIDE: int = 2
## En la misma fila, el jugador se dibuja por encima del mob.
const PLAYER_SAME_ROW_BIAS: int = 1


static func get_tile_row(world_y: float, tile_size_px: float = DEFAULT_TILE_SIZE_PX) -> int:
	if tile_size_px <= 0.0:
		tile_size_px = DEFAULT_TILE_SIZE_PX
	return int(floor(world_y / tile_size_px))


static func compute_player_z_index(player_row: int) -> int:
	return player_row * Z_STRIDE + PLAYER_SAME_ROW_BIAS


## Telémetros / AoE dibujados en el suelo (sin bias del jugador).
static func compute_ground_telegraph_z_index(world_y: float, tile_size_px: float = DEFAULT_TILE_SIZE_PX) -> int:
	return get_tile_row(world_y, tile_size_px) * Z_STRIDE


static func compute_enemy_z_index(enemy_row: int, player_row: int) -> int:
	var base: int = enemy_row * Z_STRIDE
	if enemy_row > player_row:
		return base + Z_STRIDE
	return base


static func is_enemy_in_front_of_player(enemy_row: int, player_row: int) -> bool:
	return enemy_row > player_row
