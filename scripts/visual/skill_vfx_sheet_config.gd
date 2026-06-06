## Configuración tipada de una hoja VFX 32×32 para una habilidad.
class_name SkillVfxSheetConfig
extends RefCounted

enum VisualMode {
	## Un solo frame recortado con region_rect (Sprite2D).
	STATIC_REGION,
	## Animación continua generada desde la grilla hframes × vframes.
	ANIMATED_SHEET,
	## Reproduce una vez y libera el nodo al terminar.
	ONE_SHOT,
}

## Rol visual dentro de la habilidad (proyectil, impacto, aura, etc.).
enum VisualRole {
	PROJECTILE,
	IMPACT,
	SLASH,
	AURA,
}

var skill_id: String = ""
var role: VisualRole = VisualRole.PROJECTILE
var mode: VisualMode = VisualMode.ANIMATED_SHEET
var texture_path: String = ""
var cell_size: Vector2i = Vector2i(32, 32)
var hframes: int = 6
var vframes: int = 2
## Limita frames activos si la animación no usa toda la grilla (p. ej. 9 de 12).
var frame_count: int = 0
## Solo para STATIC_REGION: columna/fila dentro de la grilla.
var frame_coords: Vector2i = Vector2i.ZERO
var animation_name: StringName = &"default"
var fps: float = 12.0
var loop: bool = true
## Escala mundo: 1.0 = tamaño nativo de celda (32 px).
var world_scale: Vector2 = Vector2(1.0, 1.0)
## Tint extra encima del arte (Color.WHITE = sin tint).
var tint: Color = Color.WHITE
## Mezcla modulate de clase (Mage/Swordman) encima del sprite.
var apply_class_palette: bool = true
## Giro continuo (rad/s) del frame de hold al terminar la animación (0 = sin giro).
var hold_spin_rad_per_sec: float = 0.0
## Frame final en hold (1-indexed); usado al congelar en impacto.
var hold_frame_1based: int = 0


func is_valid() -> bool:
	return not texture_path.is_empty() and ResourceLoader.exists(texture_path)


func get_frame_rect(col: int = -1, row: int = -1) -> Rect2:
	var use_col: int = col if col >= 0 else frame_coords.x
	var use_row: int = row if row >= 0 else frame_coords.y
	return Rect2(
		float(use_col * cell_size.x),
		float(use_row * cell_size.y),
		float(cell_size.x),
		float(cell_size.y)
	)


func get_total_frames() -> int:
	var grid_total: int = maxi(hframes, 1) * maxi(vframes, 1)
	if frame_count > 0:
		return mini(frame_count, grid_total)
	return grid_total


static func animated_loop(
	p_skill_id: String,
	p_texture_path: String,
	p_role: VisualRole = VisualRole.PROJECTILE,
	p_hframes: int = 6,
	p_vframes: int = 2,
	p_fps: float = 12.0,
	p_frame_count: int = 0
) -> SkillVfxSheetConfig:
	var cfg := SkillVfxSheetConfig.new()
	cfg.skill_id = p_skill_id
	cfg.role = p_role
	cfg.mode = VisualMode.ANIMATED_SHEET
	cfg.texture_path = p_texture_path
	cfg.hframes = p_hframes
	cfg.vframes = p_vframes
	cfg.fps = p_fps
	cfg.frame_count = p_frame_count
	cfg.loop = true
	return cfg


static func one_shot_burst(
	p_skill_id: String,
	p_texture_path: String,
	p_role: VisualRole = VisualRole.IMPACT,
	p_hframes: int = 6,
	p_vframes: int = 2,
	p_fps: float = 18.0,
	p_frame_count: int = 0
) -> SkillVfxSheetConfig:
	var cfg := animated_loop(p_skill_id, p_texture_path, p_role, p_hframes, p_vframes, p_fps, p_frame_count)
	cfg.mode = VisualMode.ONE_SHOT
	cfg.loop = false
	return cfg


## Reproduce frames 1..N (1-indexed) una vez y se queda en el frame N (sin loop ni fade posterior).
static func animated_play_then_hold(
	p_skill_id: String,
	p_texture_path: String,
	p_role: VisualRole = VisualRole.PROJECTILE,
	p_hframes: int = 6,
	p_vframes: int = 2,
	p_fps: float = 12.0,
	p_last_frame_1based: int = 6,
	p_hold_spin_rad_per_sec: float = 0.0
) -> SkillVfxSheetConfig:
	var cfg := animated_loop(
		p_skill_id, p_texture_path, p_role, p_hframes, p_vframes, p_fps, p_last_frame_1based
	)
	cfg.loop = false
	cfg.hold_frame_1based = p_last_frame_1based
	cfg.hold_spin_rad_per_sec = p_hold_spin_rad_per_sec
	return cfg


static func static_cell(
	p_skill_id: String,
	p_texture_path: String,
	p_col: int,
	p_row: int,
	p_role: VisualRole = VisualRole.PROJECTILE
) -> SkillVfxSheetConfig:
	var cfg := SkillVfxSheetConfig.new()
	cfg.skill_id = p_skill_id
	cfg.role = p_role
	cfg.mode = VisualMode.STATIC_REGION
	cfg.texture_path = p_texture_path
	cfg.frame_coords = Vector2i(p_col, p_row)
	cfg.loop = false
	return cfg
