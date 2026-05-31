## Construye SpriteFrames desde hojas Tiny RPG (celdas cuadradas, p. ej. 100×100).
class_name TinyRpgSpriteFrames
extends RefCounted


static func build(def: Dictionary) -> SpriteFrames:
	var frames: SpriteFrames = SpriteFrames.new()
	var frame_px: int = maxi(int(def.get("frame_px", 100)), 1)
	var base_path: String = String(def.get("sheet_base", ""))
	var anims: Array = def.get("animations", [])
	for entry: Variant in anims:
		if entry is Dictionary:
			_add_sheet_animation(frames, entry, base_path, frame_px)
	return frames


static func _add_sheet_animation(
	frames: SpriteFrames,
	entry: Dictionary,
	base_path: String,
	frame_px: int
) -> void:
	var anim_name: String = String(entry.get("name", ""))
	if anim_name.is_empty():
		return
	var file_name: String = String(entry.get("file", ""))
	if file_name.is_empty():
		return
	var sheet_path: String = base_path.path_join(file_name) if not base_path.is_empty() else file_name
	if not ResourceLoader.exists(sheet_path):
		return
	var sheet: Texture2D = load(sheet_path) as Texture2D
	if sheet == null:
		return
	var hframes: int = int(entry.get("hframes", 0))
	var vframes: int = int(entry.get("vframes", 0))
	if hframes <= 0:
		hframes = maxi(int(sheet.get_width() / float(frame_px)), 1)
	if vframes <= 0:
		vframes = maxi(int(sheet.get_height() / float(frame_px)), 1)
	var fps: float = float(entry.get("fps", 8.0))
	var loop: bool = bool(entry.get("loop", true))
	var anim_id: StringName = StringName(anim_name)
	frames.add_animation(anim_id)
	frames.set_animation_speed(anim_id, fps)
	frames.set_animation_loop(anim_id, loop)
	var fw: float = float(frame_px)
	var fh: float = float(frame_px)
	for row: int in vframes:
		for col: int in hframes:
			var atlas: AtlasTexture = AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(float(col) * fw, float(row) * fh, fw, fh)
			frames.add_frame(anim_id, atlas)
