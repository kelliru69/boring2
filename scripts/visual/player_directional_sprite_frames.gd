## SpriteFrames 8 direcciones (idle + walk) desde hojas Eris 4 columnas × 5 filas.
extends RefCounted
class_name PlayerDirectionalSpriteFrames

const HFRAMES: int = 4
const VFRAMES: int = 5
## +25% velocidad de loop walk para coincidir con desplazamiento físico.
const ANIM_SPEED: float = 6.25

## Filas del template Eris (celda cuadrada): 0 abajo, 1 diag abajo-derecha, 2 derecha, 3 diag arriba-derecha, 4 arriba.
const ROW_DOWN: int = 0
const ROW_DIAG_DOWN_RIGHT: int = 1
const ROW_RIGHT: int = 2
const ROW_DIAG_UP_RIGHT: int = 3
const ROW_UP: int = 4


static func build_from_skin_def(skin_def: Dictionary) -> SpriteFrames:
	if bool(skin_def.get("use_scene_default", false)):
		return null
	var idle_path: String = String(skin_def.get("idle_sheet", ""))
	var walk_path: String = String(skin_def.get("walk_sheet", ""))
	var hframes: int = int(skin_def.get("hframes", HFRAMES))
	var vframes: int = int(skin_def.get("vframes", VFRAMES))
	var frame_px: int = int(skin_def.get("frame_px", 0))
	return build_from_sheets(idle_path, walk_path, frame_px, hframes, vframes)


static func build_from_sheets(
	idle_path: String,
	walk_path: String,
	frame_px: int = 0,
	hframes: int = HFRAMES,
	vframes: int = VFRAMES
) -> SpriteFrames:
	if not ResourceLoader.exists(idle_path) or not ResourceLoader.exists(walk_path):
		push_warning("PlayerDirectionalSpriteFrames: faltan hojas idle/walk.")
		return null
	var idle_tex: Texture2D = load(idle_path) as Texture2D
	var walk_tex: Texture2D = load(walk_path) as Texture2D
	if idle_tex == null or walk_tex == null:
		return null
	var px: int = frame_px
	if px <= 0:
		px = _detect_cell_size(idle_tex, hframes, vframes)
	if px <= 0:
		push_warning("PlayerDirectionalSpriteFrames: no se pudo detectar tamaño de celda.")
		return null
	var walk_px: int = frame_px
	if walk_px <= 0:
		walk_px = _detect_cell_size(walk_tex, hframes, vframes)
	if walk_px != px:
		push_warning(
			"PlayerDirectionalSpriteFrames: idle (%dpx) y walk (%dpx) difieren; usando idle."
			% [px, walk_px]
		)
	var frames: SpriteFrames = SpriteFrames.new()
	_add_row_anim(frames, &"idle_down", idle_tex, px, ROW_DOWN, hframes)
	_add_row_anim(frames, &"idle_diag_down_right", idle_tex, px, ROW_DIAG_DOWN_RIGHT, hframes)
	_add_row_anim(frames, &"idle_right", idle_tex, px, ROW_RIGHT, hframes)
	_add_row_anim(frames, &"idle_diag_up_right", idle_tex, px, ROW_DIAG_UP_RIGHT, hframes)
	_add_row_anim(frames, &"idle_up", idle_tex, px, ROW_UP, hframes)
	_add_row_anim(frames, &"walk_down", walk_tex, px, ROW_DOWN, hframes)
	_add_row_anim(frames, &"walk_diag_down_right", walk_tex, px, ROW_DIAG_DOWN_RIGHT, hframes)
	_add_row_anim(frames, &"walk_right", walk_tex, px, ROW_RIGHT, hframes)
	_add_row_anim(frames, &"walk_diag_up_right", walk_tex, px, ROW_DIAG_UP_RIGHT, hframes)
	_add_row_anim(frames, &"walk_up", walk_tex, px, ROW_UP, hframes)
	return frames


static func _detect_cell_size(sheet: Texture2D, hframes: int, vframes: int) -> int:
	if sheet == null or hframes <= 0 or vframes <= 0:
		return 0
	var fw: int = int(float(sheet.get_width()) / float(hframes))
	var fh: int = int(float(sheet.get_height()) / float(vframes))
	if fw != fh:
		push_warning(
			"PlayerDirectionalSpriteFrames: celdas no cuadradas %dx%d en %s"
			% [fw, fh, sheet.resource_path]
		)
	return mini(fw, fh)


static func _add_row_anim(
	frames: SpriteFrames,
	anim_name: StringName,
	sheet: Texture2D,
	frame_px: int,
	row: int,
	hframes: int = HFRAMES
) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, ANIM_SPEED)
	frames.set_animation_loop(anim_name, true)
	var y: float = float(row * frame_px)
	for col: int in hframes:
		var atlas: AtlasTexture = AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(float(col * frame_px), y, float(frame_px), float(frame_px))
		frames.add_frame(anim_name, atlas)


static func get_preview_texture(skin_def: Dictionary) -> Texture2D:
	var idle_path: String = String(skin_def.get("idle_sheet", ""))
	if not ResourceLoader.exists(idle_path):
		return null
	var sheet: Texture2D = load(idle_path) as Texture2D
	if sheet == null:
		return null
	var hframes: int = int(skin_def.get("hframes", HFRAMES))
	var vframes: int = int(skin_def.get("vframes", VFRAMES))
	var frame_px: int = int(skin_def.get("frame_px", 0))
	if frame_px <= 0:
		frame_px = _detect_cell_size(sheet, hframes, vframes)
	var preview_raw: Variant = skin_def.get("preview_frame", Vector2i(1, 0))
	var preview_cell: Vector2i = preview_raw as Vector2i if preview_raw is Vector2i else Vector2i(1, 0)
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(
		float(preview_cell.x * frame_px),
		float(preview_cell.y * frame_px),
		float(frame_px),
		float(frame_px)
	)
	return atlas
