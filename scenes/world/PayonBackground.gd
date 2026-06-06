## Payon Dungeon — copia base de Prontera para editar a mano en el editor (TileMapLayer).
extends HandcraftedMapBackground

const _TilesetBuilder = preload("res://scripts/world/map_tileset_builder.gd")

@export_group("TileSet")
## Si las capas no tienen TileSet, asigna uno desde los PNG de assets/tiles/prontera/.
@export var auto_assign_tileset: bool = true


func _ready() -> void:
	if auto_assign_tileset:
		_ensure_tileset_on_layers()
	super._ready()


func _ensure_tileset_on_layers() -> void:
	var tile_set: TileSet = _TilesetBuilder.build(MapTileCatalog.MapTheme.PRONTERA)
	if tile_set == null:
		return
	for layer: TileMapLayer in [ground_layer, path_layer, obstacle_layer, decor_layer, border_layer]:
		if layer and layer.tile_set == null:
			layer.tile_set = tile_set
