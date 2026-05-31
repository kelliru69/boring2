## IDs de tiles del atlas — edita aquí las coordenadas según tu TileSet en el editor.
## Cada entrada: { "source": int, "atlas": Vector2i }
class_name MapTileCatalog
extends RefCounted

## No usar "Theme": choca con la clase UI Theme de Godot.
enum MapTheme {
	PRONTERA,
	PAYON,
}

enum SourceId {
	GROUND = 0,
	HILLS = 1,
	PROPS = 2,
}

## Tamaño de celda del tileset descargado (grass/hills/props ≈ 16×16).
const TILE_PX_PRONTERA: int = 16
const TILE_PX_PAYON: int = 32


static func get_tile_px(map_theme: MapTheme) -> int:
	return TILE_PX_PAYON if map_theme == MapTheme.PAYON else TILE_PX_PRONTERA


## --- PRONTERA (grass_tileset.png 176×112 → 11×7 celdas @ 16px) ---
## Suelo: bloque inferior izquierdo. Caminos: manchas superiores. Rocas: esquina inferior derecha.
static func prontera() -> Dictionary:
	return {
		"ground_grass_a": tile(SourceId.GROUND, Vector2i(0, 4)),
		"ground_grass_b": tile(SourceId.GROUND, Vector2i(1, 4)),
		"ground_grass_flowers": tile(SourceId.GROUND, Vector2i(2, 4)),
		"ground_grass_dark": tile(SourceId.GROUND, Vector2i(3, 4)),
		"path_center": tile(SourceId.GROUND, Vector2i(5, 1)),
		"path_edge": tile(SourceId.GROUND, Vector2i(4, 1)),
		"obstacle_rock_small": tile(SourceId.GROUND, Vector2i(8, 5)),
		"obstacle_bush": tile(SourceId.GROUND, Vector2i(9, 5)),
		"border_wall_face": tile(SourceId.HILLS, Vector2i(1, 2)),
		"border_wall_top": tile(SourceId.HILLS, Vector2i(1, 1)),
		"border_corner": tile(SourceId.HILLS, Vector2i(0, 1)),
		"prop_tree_round": tile(SourceId.PROPS, Vector2i(2, 0)),
		"prop_tree_tall": tile(SourceId.PROPS, Vector2i(0, 0)),
		"prop_rock_large": tile(SourceId.PROPS, Vector2i(5, 1)),
		"decor_flower": tile(SourceId.PROPS, Vector2i(7, 2)),
		"decor_grass_tuft": tile(SourceId.GROUND, Vector2i(10, 5)),
	}


## --- PAYON (dungeon procedural 32×32 — índices del atlas 4×2) ---
static func payon() -> Dictionary:
	return {
		"ground_grass_a": tile(SourceId.GROUND, Vector2i(0, 0)),
		"ground_grass_b": tile(SourceId.GROUND, Vector2i(1, 0)),
		"ground_grass_flowers": tile(SourceId.GROUND, Vector2i(2, 0)),
		"ground_grass_dark": tile(SourceId.GROUND, Vector2i(0, 1)),
		"path_center": tile(SourceId.GROUND, Vector2i(1, 1)),
		"path_edge": tile(SourceId.GROUND, Vector2i(2, 1)),
		"obstacle_rock_small": tile(SourceId.GROUND, Vector2i(3, 1)),
		"obstacle_bush": tile(SourceId.GROUND, Vector2i(2, 1)),
		"border_wall_face": tile(SourceId.GROUND, Vector2i(3, 1)),
		"border_wall_top": tile(SourceId.GROUND, Vector2i(3, 1)),
		"border_corner": tile(SourceId.GROUND, Vector2i(3, 1)),
		"prop_tree_round": tile(SourceId.GROUND, Vector2i(3, 1)),
		"prop_tree_tall": tile(SourceId.GROUND, Vector2i(3, 1)),
		"prop_rock_large": tile(SourceId.GROUND, Vector2i(3, 1)),
		"decor_flower": tile(SourceId.GROUND, Vector2i(2, 0)),
		"decor_grass_tuft": tile(SourceId.GROUND, Vector2i(2, 0)),
	}


static func get_tiles(map_theme: MapTheme) -> Dictionary:
	return payon() if map_theme == MapTheme.PAYON else prontera()


static func tile(source_id: int, atlas: Vector2i) -> Dictionary:
	return {"source": source_id, "atlas": atlas}


## Tiles que reciben polígono de colisión al construir el TileSet.
static func collision_tile_keys() -> PackedStringArray:
	return PackedStringArray([
		"border_wall_face",
		"border_wall_top",
		"border_corner",
		"obstacle_rock_small",
		"obstacle_bush",
		"prop_tree_round",
		"prop_tree_tall",
		"prop_rock_large",
	])
