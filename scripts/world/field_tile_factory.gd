## Texturas de suelo estilo campos de Ragnarok (hierba, tierra, flores).
class_name FieldTileFactory
extends RefCounted

enum TileId {
	GRASS_A,
	GRASS_B,
	GRASS_FLOWERS,
	DIRT,
	DIRT_PATCH,
	WATER_SHALLOW,
	BORDER_FENCE,
}

const TILE_PX: int = 32
const ATLAS_COLS: int = 4
const TILE_COUNT: int = 7


static func build_tileset() -> TileSet:
	var atlas_tex: ImageTexture = _build_atlas_texture()
	var atlas: TileSetAtlasSource = TileSetAtlasSource.new()
	atlas.texture = atlas_tex
	atlas.texture_region_size = Vector2i(TILE_PX, TILE_PX)
	for tile_id: int in TILE_COUNT:
		var col: int = tile_id % ATLAS_COLS
		var row: int = int(tile_id / float(ATLAS_COLS))
		atlas.create_tile(Vector2i(col, row))
	var tile_set: TileSet = TileSet.new()
	tile_set.add_source(atlas, 0)
	return tile_set


static func pick_tile_for_cell(world_cell: Vector2i) -> TileId:
	var n: float = _hash_noise(world_cell)
	var path: float = _path_noise(world_cell)
	if path > 0.72:
		return TileId.DIRT if n > 0.5 else TileId.DIRT_PATCH
	if n > 0.88 and path < 0.35:
		return TileId.WATER_SHALLOW
	if n > 0.82:
		return TileId.GRASS_FLOWERS
	if n > 0.45:
		return TileId.GRASS_B
	return TileId.GRASS_A


static func _build_atlas_texture() -> ImageTexture:
	var cols: int = ATLAS_COLS
	var rows: int = int(ceil(float(TILE_COUNT) / float(cols)))
	var image: Image = Image.create(cols * TILE_PX, rows * TILE_PX, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_paint_tile(image, 0, 0, _make_grass_tile(Color(0.55, 0.78, 0.38), Color(0.45, 0.68, 0.32)))
	_paint_tile(image, 1, 0, _make_grass_tile(Color(0.50, 0.72, 0.34), Color(0.40, 0.62, 0.28)))
	_paint_tile(image, 2, 0, _make_grass_flowers_tile())
	_paint_tile(image, 0, 1, _make_dirt_tile(Color(0.72, 0.58, 0.38), Color(0.62, 0.48, 0.30)))
	_paint_tile(image, 1, 1, _make_dirt_tile(Color(0.66, 0.52, 0.34), Color(0.56, 0.44, 0.28)))
	_paint_tile(image, 2, 1, _make_water_tile())
	_paint_tile(image, 3, 1, _make_border_fence_tile())
	return ImageTexture.create_from_image(image)


static func get_border_tile_coords() -> Vector2i:
	var tile_id: int = TileId.BORDER_FENCE
	return Vector2i(tile_id % ATLAS_COLS, int(tile_id / float(ATLAS_COLS)))


static func _make_grass_tile(base: Color, dark: Color) -> Image:
	var img: Image = Image.create(TILE_PX, TILE_PX, false, Image.FORMAT_RGBA8)
	img.fill(base)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 101
	for _i: int in 48:
		var x: int = rng.randi_range(0, TILE_PX - 1)
		var y: int = rng.randi_range(0, TILE_PX - 1)
		img.set_pixel(x, y, dark)
	for _i: int in 12:
		var x2: int = rng.randi_range(0, TILE_PX - 1)
		var y2: int = rng.randi_range(0, TILE_PX - 1)
		img.set_pixel(x2, y2, base.lightened(0.08))
	return img


static func _make_grass_flowers_tile() -> Image:
	var img: Image = _make_grass_tile(Color(0.52, 0.76, 0.36), Color(0.42, 0.66, 0.30))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 202
	for _i: int in 6:
		var cx: int = rng.randi_range(4, TILE_PX - 5)
		var cy: int = rng.randi_range(4, TILE_PX - 5)
		var flower: Color = Color(1.0, 0.55, 0.72) if rng.randf() > 0.5 else Color(1.0, 0.88, 0.35)
		for dy: int in range(-1, 2):
			for dx: int in range(-1, 2):
				if abs(dx) + abs(dy) <= 1:
					img.set_pixel(cx + dx, cy + dy, flower)
	return img


static func _make_dirt_tile(base: Color, dark: Color) -> Image:
	var img: Image = Image.create(TILE_PX, TILE_PX, false, Image.FORMAT_RGBA8)
	img.fill(base)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 303
	for _i: int in 60:
		var x: int = rng.randi_range(0, TILE_PX - 1)
		var y: int = rng.randi_range(0, TILE_PX - 1)
		img.set_pixel(x, y, dark if rng.randf() > 0.4 else base.lightened(0.06))
	return img


static func _make_border_fence_tile() -> Image:
	var img: Image = Image.create(TILE_PX, TILE_PX, false, Image.FORMAT_RGBA8)
	var wood: Color = Color(0.52, 0.38, 0.24, 1.0)
	var wood_dark: Color = Color(0.38, 0.26, 0.16, 1.0)
	var grass_edge: Color = Color(0.42, 0.62, 0.30, 1.0)
	for y: int in TILE_PX:
		for x: int in TILE_PX:
			if y >= TILE_PX - 5:
				img.set_pixel(x, y, grass_edge)
			elif x % 6 < 2:
				img.set_pixel(x, y, wood_dark)
			else:
				img.set_pixel(x, y, wood)
	# Postes verticales
	for y: int in range(2, TILE_PX - 6):
		img.set_pixel(4, y, wood_dark)
		img.set_pixel(15, y, wood_dark)
		img.set_pixel(26, y, wood_dark)
	return img


static func _make_water_tile() -> Image:
	var img: Image = Image.create(TILE_PX, TILE_PX, false, Image.FORMAT_RGBA8)
	var shallow: Color = Color(0.38, 0.68, 0.82)
	var deep: Color = Color(0.28, 0.55, 0.72)
	for y: int in TILE_PX:
		for x: int in TILE_PX:
			var wave: float = sin(float(x) * 0.55 + float(y) * 0.35) * 0.5 + 0.5
			img.set_pixel(x, y, shallow.lerp(deep, wave))
	return img


static func _paint_tile(atlas: Image, col: int, row: int, tile: Image) -> void:
	for y: int in TILE_PX:
		for x: int in TILE_PX:
			atlas.set_pixel(col * TILE_PX + x, row * TILE_PX + y, tile.get_pixel(x, y))


static func cell_noise(cell: Vector2i) -> float:
	return _hash_noise(cell)


static func _hash_noise(cell: Vector2i) -> float:
	var v: int = cell.x * 374761393 + cell.y * 668265263
	v = (v ^ (v >> 13)) * 1274126177
	return float(v & 0xFFFFFF) / float(0xFFFFFF)


static func _path_noise(cell: Vector2i) -> float:
	var fx: float = float(cell.x) * 0.09
	var fy: float = float(cell.y) * 0.09
	var wave: float = abs(sin(fx) + sin(fy * 0.85))
	return wave * 0.5 + _hash_noise(cell) * 0.5
