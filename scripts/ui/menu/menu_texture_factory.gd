## Texturas placeholder para menús cuando aún no hay PNG finales.
class_name MenuTextureFactory
extends RefCounted

static func solid_color_texture(color: Color, size: Vector2i = Vector2i(256, 256)) -> Texture2D:
	var img: Image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)


static func load_or_placeholder(path: String, fallback_color: Color, size: Vector2i = Vector2i(256, 256)) -> Texture2D:
	if path != "" and ResourceLoader.exists(path):
		var tex: Texture2D = load(path) as Texture2D
		if tex != null:
			return tex
	return solid_color_texture(fallback_color, size)


static func build_menu_sprite_frames_from_skin(skin_id: String) -> SpriteFrames:
	var skin_def: Dictionary = PlayerSkinCatalog.get_skin(skin_id)
	# En menú siempre generamos desde las hojas idle/walk (blue_cat tiene use_scene_default en juego).
	var menu_def: Dictionary = skin_def.duplicate()
	menu_def["use_scene_default"] = false
	var frames: SpriteFrames = PlayerDirectionalSpriteFrames.build_from_skin_def(menu_def)
	if frames != null:
		return frames
	return _fallback_sprite_frames()


static func _fallback_sprite_frames() -> SpriteFrames:
	var frames: SpriteFrames = SpriteFrames.new()
	var tex: Texture2D = solid_color_texture(Color(0.35, 0.75, 1.0, 1.0), Vector2i(64, 64))
	if not frames.has_animation(&"idle"):
		frames.add_animation(&"idle")
	frames.set_animation_loop(&"idle", true)
	frames.set_animation_speed(&"idle", 4.0)
	frames.add_frame(&"idle", tex, 0.0)
	return frames
