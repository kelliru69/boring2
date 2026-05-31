## Construye un TileSet multi-atlas con Physics Layer para MapGenerator.
class_name MapTilesetBuilder
extends RefCounted

const _Catalog = preload("res://data/map_tile_catalog.gd")
const _DungeonFactory = preload("res://scripts/world/dungeon_tile_factory.gd")

const PRONTERA_GRASS: String = "res://assets/tiles/prontera/grass_tileset.png"
const PRONTERA_HILLS: String = "res://assets/tiles/prontera/hills_tileset.png"
const PRONTERA_PROPS: String = "res://assets/tiles/prontera/props_things.png"


static func build(map_theme: MapTileCatalog.MapTheme) -> TileSet:
	if map_theme == MapTileCatalog.MapTheme.PAYON:
		return _build_payon()
	return _build_prontera()


static func _build_payon() -> TileSet:
	var tile_px: int = MapTileCatalog.TILE_PX_PAYON
	var tile_set: TileSet = _DungeonFactory.build_tileset()
	tile_set.add_physics_layer(0)
	tile_set.set_physics_layer_collision_layer(0, 1)
	tile_set.set_physics_layer_collision_mask(0, 0)
	var atlas: TileSetAtlasSource = tile_set.get_source(0) as TileSetAtlasSource
	if atlas:
		var tiles: Dictionary = MapTileCatalog.payon()
		for key: String in MapTileCatalog.collision_tile_keys():
			if tiles.has(key):
				_add_full_collision(atlas, tiles[key]["atlas"] as Vector2i, tile_px)
	return tile_set


static func _build_prontera() -> TileSet:
	var tile_px: int = MapTileCatalog.TILE_PX_PRONTERA
	var tile_set: TileSet = TileSet.new()
	tile_set.tile_size = Vector2i(tile_px, tile_px)
	tile_set.add_physics_layer(0)
	tile_set.set_physics_layer_collision_layer(0, 1)
	tile_set.set_physics_layer_collision_mask(0, 0)

	var grass_src: TileSetAtlasSource = _add_atlas_source(tile_set, PRONTERA_GRASS, tile_px, 0)
	var hills_src: TileSetAtlasSource = _add_atlas_source(tile_set, PRONTERA_HILLS, tile_px, 1)
	var props_src: TileSetAtlasSource = _add_atlas_source(
		tile_set, PRONTERA_PROPS, tile_px, 2, false
	)

	var tiles: Dictionary = MapTileCatalog.prontera()
	for key: String in MapTileCatalog.collision_tile_keys():
		if not tiles.has(key):
			continue
		var ref: Dictionary = tiles[key]
		var src: TileSetAtlasSource = _source_for_id(grass_src, hills_src, props_src, int(ref["source"]))
		if src:
			_add_full_collision(src, ref["atlas"] as Vector2i, tile_px)
	return tile_set


static func _add_atlas_source(
	tile_set: TileSet,
	texture_path: String,
	tile_px: int,
	source_id: int,
	required: bool = true
) -> TileSetAtlasSource:
	if not ResourceLoader.exists(texture_path):
		if required:
			push_warning("MapTilesetBuilder: falta textura obligatoria %s" % texture_path)
		return null
	var tex: Texture2D = load(texture_path) as Texture2D
	if tex == null:
		return null
	var cols: int = maxi(int(tex.get_width() / float(tile_px)), 1)
	var rows: int = maxi(int(tex.get_height() / float(tile_px)), 1)
	var atlas: TileSetAtlasSource = TileSetAtlasSource.new()
	atlas.texture = tex
	atlas.texture_region_size = Vector2i(tile_px, tile_px)
	for row: int in rows:
		for col: int in cols:
			atlas.create_tile(Vector2i(col, row))
	tile_set.add_source(atlas, source_id)
	return atlas


static func _source_for_id(
	grass: TileSetAtlasSource,
	hills: TileSetAtlasSource,
	props: TileSetAtlasSource,
	source_id: int
) -> TileSetAtlasSource:
	match source_id:
		MapTileCatalog.SourceId.GROUND:
			return grass
		MapTileCatalog.SourceId.HILLS:
			return hills
		MapTileCatalog.SourceId.PROPS:
			return props
		_:
			return grass


static func _add_full_collision(
	atlas: TileSetAtlasSource,
	coords: Vector2i,
	tile_px: int
) -> void:
	if atlas == null or not atlas.has_tile(coords):
		return
	var data: TileData = atlas.get_tile_data(coords, 0)
	if data == null:
		return
	data.add_collision_polygon(0)
	var half: float = float(tile_px) * 0.5
	data.set_collision_polygon_points(
		0,
		0,
		PackedVector2Array([
			Vector2(-half, -half),
			Vector2(half, -half),
			Vector2(half, half),
			Vector2(-half, half),
		])
	)
