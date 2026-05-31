## Carga animaciones walk desde SpriteFrames, carpeta de frames o spritesheet.
class_name SpriteAnimationLoader
extends RefCounted

const _TinyRpgFrames = preload("res://scripts/visual/tiny_rpg_sprite_frames.gd")

const MONSTER_BASE: String = "res://assets/sprites/monsters/"


static func try_setup_animated(
	animated: AnimatedSprite2D,
	static_sprite: Sprite2D,
	def: Dictionary
) -> bool:
	if animated == null:
		return false
	var monster_id: String = String(def.get("id", ""))
	# 1) Recurso SpriteFrames (.tres) creado en el editor
	var frames_path: String = String(def.get("sprite_frames_path", ""))
	if frames_path != "" and ResourceLoader.exists(frames_path):
		return _play_sprite_frames(animated, static_sprite, load(frames_path) as SpriteFrames, def)
	# 2) Carpeta con PNG numerados: monsters/poring/00.png, 01.png...
	var folder: String = String(def.get("walk_frames_folder", ""))
	if folder.is_empty() and not monster_id.is_empty():
		folder = MONSTER_BASE + monster_id + "/"
	if folder != "":
		var textures: Array[Texture2D] = _load_textures_from_folder(folder)
		if textures.size() >= 2:
			var built: SpriteFrames = _build_walk_frames(textures, def)
			return _play_sprite_frames(animated, static_sprite, built, def)
	# 3) Spritesheet en una sola imagen
	var sheet_path: String = String(def.get("sprite_sheet_path", ""))
	if sheet_path != "" and ResourceLoader.exists(sheet_path):
		var sheet: Texture2D = load(sheet_path) as Texture2D
		if sheet != null:
			var hframes: int = int(def.get("sheet_hframes", 4))
			var vframes: int = int(def.get("sheet_vframes", 1))
			var built_sheet: SpriteFrames = _build_from_sheet(sheet, hframes, vframes, def)
			return _play_sprite_frames(animated, static_sprite, built_sheet, def)
	return false


## Hojas Tiny RPG (varias animaciones: idle, walk, attack, hurt, death).
static func try_setup_tiny_rpg(
	animated: AnimatedSprite2D,
	static_sprite: Sprite2D,
	def: Dictionary
) -> bool:
	if animated == null:
		return false
	var anims: Array = def.get("animations", [])
	if anims.is_empty():
		return false
	var built: SpriteFrames = _TinyRpgFrames.build(def)
	if built.get_animation_names().is_empty():
		return false
	return _play_sprite_frames(animated, static_sprite, built, def)


static func _play_sprite_frames(
	animated: AnimatedSprite2D,
	static_sprite: Sprite2D,
	frames: SpriteFrames,
	def: Dictionary
) -> bool:
	if frames == null:
		return false
	var anim_name: String = String(def.get("anim_default", "walk"))
	if not frames.has_animation(anim_name):
		anim_name = frames.get_animation_names()[0] if frames.get_animation_names().size() > 0 else ""
	if anim_name.is_empty():
		return false
	animated.sprite_frames = frames
	animated.visible = true
	animated.play(anim_name)
	if static_sprite:
		static_sprite.visible = false
	_apply_display_scale(animated, static_sprite, def)
	return true


static func _apply_display_scale(
	animated: AnimatedSprite2D,
	static_sprite: Sprite2D,
	def: Dictionary
) -> void:
	var target_h: float = float(def.get("sprite_height", 30.0))
	var tex: Texture2D = animated.sprite_frames.get_frame_texture(animated.animation, 0)
	if tex == null:
		return
	var scale_factor: float = target_h / maxf(float(tex.get_height()), 1.0)
	animated.scale = Vector2(scale_factor, scale_factor)
	animated.centered = true
	var tint: Color = def.get("tint", Color.WHITE)
	animated.modulate = tint
	if static_sprite:
		static_sprite.scale = Vector2(scale_factor, scale_factor)


static func _build_walk_frames(textures: Array[Texture2D], def: Dictionary) -> SpriteFrames:
	var frames: SpriteFrames = SpriteFrames.new()
	frames.add_animation(&"walk")
	var fps: float = float(def.get("anim_fps", 8.0))
	frames.set_animation_speed(&"walk", fps)
	frames.set_animation_loop(&"walk", true)
	for tex: Texture2D in textures:
		if tex:
			frames.add_frame(&"walk", tex)
	return frames


static func _build_from_sheet(
	sheet: Texture2D,
	hframes: int,
	vframes: int,
	def: Dictionary
) -> SpriteFrames:
	var frames: SpriteFrames = SpriteFrames.new()
	frames.add_animation(&"walk")
	var fps: float = float(def.get("anim_fps", 8.0))
	frames.set_animation_speed(&"walk", fps)
	frames.set_animation_loop(&"walk", true)
	var frame_w: float = float(sheet.get_width()) / float(maxi(hframes, 1))
	var frame_h: float = float(sheet.get_height()) / float(maxi(vframes, 1))
	for row: int in vframes:
		for col: int in hframes:
			var atlas: AtlasTexture = AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(col * frame_w, row * frame_h, frame_w, frame_h)
			frames.add_frame(&"walk", atlas)
	return frames


static func _load_textures_from_folder(folder_path: String) -> Array[Texture2D]:
	var result: Array[Texture2D] = []
	if not DirAccess.dir_exists_absolute(folder_path):
		return result
	var dir: DirAccess = DirAccess.open(folder_path)
	if dir == null:
		return result
	var names: PackedStringArray = dir.get_files()
	names.sort()
	for file_name: String in names:
		if file_name.begins_with("."):
			continue
		if not (file_name.ends_with(".png") or file_name.ends_with(".webp")):
			continue
		var full_path: String = folder_path.path_join(file_name)
		if ResourceLoader.exists(full_path):
			var tex: Texture2D = load(full_path) as Texture2D
			if tex:
				result.append(tex)
	return result
