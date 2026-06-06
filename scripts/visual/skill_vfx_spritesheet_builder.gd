## Construye AtlasTexture / SpriteFrames desde hojas 32×32 y aplica escala pixel-art 16×16.
class_name SkillVfxSpritesheetBuilder
extends RefCounted

const _Config = preload("res://scripts/visual/skill_vfx_sheet_config.gd")

## Celdas nativas del pack descargado.
const SOURCE_CELL_PX: Vector2i = Vector2i(32, 32)
## Escala recomendada: 1.0 = celdas 32×32 a tamaño nativo en pantalla.
const WORLD_SCALE_32_TO_16: Vector2 = Vector2(1.0, 1.0)

static var _sprite_frames_cache: Dictionary = {}


static func apply_pixel_art_filter(item: CanvasItem) -> void:
	if item == null:
		return
	# Inspector Godot 4: CanvasItem → Texture Filter → "Nearest"
	# Evita blur al escalar hojas pixel-art.
	item.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


static func apply_world_scale(node: Node2D, scale_factor: Vector2 = WORLD_SCALE_32_TO_16) -> void:
	if node == null:
		return
	node.scale = scale_factor


static func load_sheet_texture(texture_path: String) -> Texture2D:
	if texture_path.is_empty() or not ResourceLoader.exists(texture_path):
		return null
	return load(texture_path) as Texture2D


static func build_atlas_frame(sheet: Texture2D, cell: Vector2i, cell_size: Vector2i = SOURCE_CELL_PX) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(
		float(cell.x * cell_size.x),
		float(cell.y * cell_size.y),
		float(cell_size.x),
		float(cell_size.y)
	)
	return atlas


static func build_sprite_frames(config: SkillVfxSheetConfig) -> SpriteFrames:
	if config == null or not config.is_valid():
		return null
	var cache_key: String = _cache_key(config)
	if _sprite_frames_cache.has(cache_key):
		return _sprite_frames_cache[cache_key] as SpriteFrames
	var sheet: Texture2D = load_sheet_texture(config.texture_path)
	if sheet == null:
		return null
	var frames := SpriteFrames.new()
	var anim: StringName = config.animation_name
	if anim.is_empty():
		anim = &"default"
	frames.add_animation(anim)
	frames.set_animation_speed(anim, config.fps)
	frames.set_animation_loop(anim, config.loop)
	var total: int = config.get_total_frames()
	var cols: int = maxi(config.hframes, 1)
	for i: int in total:
		var col: int = i % cols
		var row: int = int(i / cols)
		var atlas: AtlasTexture = build_atlas_frame(sheet, Vector2i(col, row), config.cell_size)
		frames.add_frame(anim, atlas)
	_sprite_frames_cache[cache_key] = frames
	return frames


static func apply_static_region(sprite: Sprite2D, config: SkillVfxSheetConfig) -> bool:
	if sprite == null or config == null or not config.is_valid():
		return false
	var sheet: Texture2D = load_sheet_texture(config.texture_path)
	if sheet == null:
		return false
	sprite.texture = build_atlas_frame(sheet, config.frame_coords, config.cell_size)
	sprite.region_enabled = false
	sprite.centered = true
	apply_pixel_art_filter(sprite)
	apply_world_scale(sprite, config.world_scale)
	if config.tint != Color.WHITE:
		sprite.modulate = config.tint
	return true


static func setup_animated_sprite(animated: AnimatedSprite2D, config: SkillVfxSheetConfig) -> bool:
	if animated == null or config == null or not config.is_valid():
		return false
	var frames: SpriteFrames = build_sprite_frames(config)
	if frames == null:
		return false
	var anim: StringName = config.animation_name
	if anim.is_empty() or not frames.has_animation(anim):
		var names: PackedStringArray = frames.get_animation_names()
		if names.is_empty():
			return false
		anim = StringName(names[0])
	animated.sprite_frames = frames
	animated.animation = anim
	animated.centered = true
	apply_pixel_art_filter(animated)
	apply_world_scale(animated, config.world_scale)
	if config.tint != Color.WHITE:
		animated.modulate = config.tint
	animated.play(anim)
	return true


static func _cache_key(config: SkillVfxSheetConfig) -> String:
	return "%s|%s|%d|%d|%d|%s|%s" % [
		config.texture_path,
		config.animation_name,
		config.hframes,
		config.vframes,
		config.get_total_frames(),
		str(config.fps),
		str(config.loop),
	]
