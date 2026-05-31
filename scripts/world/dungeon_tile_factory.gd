## Baldosas oscuras estilo calabozo (Payon Dungeon).
class_name DungeonTileFactory
extends RefCounted

enum TileId { STONE_A, STONE_B, MOSS, CRACK, PIT, RUBBLE, BORDER }

const TILE_PX: int = 32
const ATLAS_COLS: int = 4
const TILE_COUNT: int = 7


static func build_tileset() -> TileSet:
	var atlas_tex: ImageTexture = _build_atlas_texture()
	var atlas: TileSetAtlasSource = TileSetAtlasSource.new()
	atlas.texture = atlas_tex
	atlas.texture_region_size = Vector2i(TILE_PX, TILE_PX)
	for tile_id: int in TILE_COUNT:
		atlas.create_tile(Vector2i(tile_id % ATLAS_COLS, int(tile_id / float(ATLAS_COLS))))
	var tile_set: TileSet = TileSet.new()
	tile_set.add_source(atlas, 0)
	return tile_set


static func pick_tile_for_cell(world_cell: Vector2i) -> TileId:
	var n: float = FieldTileFactory.cell_noise(world_cell + Vector2i(900, 200))
	if n > 0.9:
		return TileId.PIT
	if n > 0.78:
		return TileId.MOSS
	if n > 0.55:
		return TileId.STONE_B
	return TileId.STONE_A


static func get_border_tile_coords() -> Vector2i:
	return Vector2i(3, 1)


static func cell_noise(cell: Vector2i) -> float:
	return FieldTileFactory.cell_noise(cell)


static func _build_atlas_texture() -> ImageTexture:
	var image: Image = Image.create(ATLAS_COLS * TILE_PX, 2 * TILE_PX, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_paint(image, 0, 0, Color(0.22, 0.24, 0.28), Color(0.16, 0.18, 0.22))
	_paint(image, 1, 0, Color(0.18, 0.20, 0.24), Color(0.14, 0.16, 0.20))
	_paint(image, 2, 0, Color(0.20, 0.28, 0.22), Color(0.14, 0.20, 0.16))
	_paint(image, 0, 1, Color(0.12, 0.12, 0.16), Color(0.08, 0.08, 0.12))
	_paint(image, 1, 1, Color(0.25, 0.22, 0.20), Color(0.18, 0.16, 0.14))
	_paint(image, 2, 1, Color(0.10, 0.12, 0.18), Color(0.06, 0.08, 0.14))
	_paint(image, 3, 1, Color(0.35, 0.30, 0.28), Color(0.28, 0.24, 0.22))
	return ImageTexture.create_from_image(image)


static func _paint(image: Image, col: int, row: int, c1: Color, c2: Color) -> void:
	var ox: int = col * TILE_PX
	var oy: int = row * TILE_PX
	for y: int in TILE_PX:
		for x: int in TILE_PX:
			var t: float = float(x + y) / float(TILE_PX * 2)
			image.set_pixel(ox + x, oy + y, c1.lerp(c2, t))
