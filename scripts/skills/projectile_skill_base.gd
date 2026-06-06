## Utilidades compartidas para proyectiles con spritesheets 32×32 → mundo 16×16.
## Equivalente ligero a un ProjectileBase visual (los bolts siguen siendo Area2D propios).
class_name ProjectileSkillBase
extends RefCounted

const CELL_PX: Vector2i = Vector2i(32, 32)
const PIXEL_ART_WORLD_SCALE: Vector2 = Vector2(1.0, 1.0)

const _Builder = preload("res://scripts/visual/skill_vfx_spritesheet_builder.gd")
const _Registry = preload("res://data/skill_vfx_registry.gd")
const _Config = preload("res://scripts/visual/skill_vfx_sheet_config.gd")
const _ShapeFactory = preload("res://scripts/util/shape_texture_factory.gd")

const META_USES_SHEET: StringName = &"uses_skill_sheet"
const META_HOLD_SPIN_RAD: StringName = &"sheet_hold_spin_rad"
const META_HOLD_SPIN_ACTIVE: StringName = &"sheet_hold_spin_active"
const META_HOLD_SPIN_BOUND: StringName = &"sheet_hold_spin_bound"
const VISUAL_NODE_NAME: StringName = &"SkillSheetVisual"
const BULLET_DOT_TEXTURE_PX: int = 8
const BULLET_DOT_SCALE: float = 0.44


## Inspector Godot 4:
## Sprite2D / AnimatedSprite2D → CanvasItem → Texture Filter = "Nearest"
static func configure_pixel_art_sprite(item: CanvasItem) -> void:
	_Builder.apply_pixel_art_filter(item)


static func apply_world_scale(node: Node2D, scale_factor: Vector2 = PIXEL_ART_WORLD_SCALE) -> void:
	_Builder.apply_world_scale(node, scale_factor)


## Constructor principal para proyectiles instanciados desde escena.
static func setup_from_registry(
	projectile: Node2D,
	fallback_sprite: Sprite2D,
	skill_id: String,
	role_key: String = "projectile"
) -> AnimatedSprite2D:
	var config: SkillVfxSheetConfig = _Registry.get_config(skill_id, role_key)
	if config == null or not config.is_valid():
		return null
	return _apply_config_to_projectile(projectile, fallback_sprite, config)


## Constructor manual con parámetros explícitos (texture_path + coords).
static func setup_from_texture(
	projectile: Node2D,
	fallback_sprite: Sprite2D,
	texture_path: String,
	frame_coords: Vector2i = Vector2i.ZERO,
	animated: bool = true,
	hframes: int = 6,
	vframes: int = 2,
	fps: float = 12.0
) -> AnimatedSprite2D:
	var config: SkillVfxSheetConfig
	if animated:
		config = _Config.animated_loop("", texture_path, _Config.VisualRole.PROJECTILE, hframes, vframes, fps)
	else:
		config = _Config.static_cell("", texture_path, frame_coords.x, frame_coords.y)
	return _apply_config_to_projectile(projectile, fallback_sprite, config)


static func setup_static_region(
	sprite: Sprite2D,
	texture_path: String,
	frame_coords: Vector2i
) -> bool:
	var config: SkillVfxSheetConfig = _Config.static_cell("", texture_path, frame_coords.x, frame_coords.y)
	if not config.is_valid():
		return false
	configure_pixel_art_sprite(sprite)
	var ok: bool = _Builder.apply_static_region(sprite, config)
	if ok:
		apply_world_scale(sprite, config.world_scale)
	return ok


static func uses_skill_sheet(projectile: Node) -> bool:
	return projectile != null and projectile.has_meta(META_USES_SHEET) and bool(projectile.get_meta(META_USES_SHEET))


static func get_sheet_visual(projectile: Node2D) -> AnimatedSprite2D:
	if projectile == null:
		return null
	var node: Node = projectile.get_node_or_null(String(VISUAL_NODE_NAME))
	return node as AnimatedSprite2D


## Congela la hoja en un frame (1 = primer celda de la grilla).
static func hold_sheet_frame(projectile: Node2D, frame_1based: int) -> void:
	var animated: AnimatedSprite2D = get_sheet_visual(projectile)
	if animated == null or animated.sprite_frames == null:
		return
	var anim: StringName = animated.animation
	if anim.is_empty() or not animated.sprite_frames.has_animation(anim):
		return
	var max_index: int = animated.sprite_frames.get_frame_count(anim) - 1
	var index: int = clampi(frame_1based - 1, 0, maxi(max_index, 0))
	animated.stop()
	animated.frame = index
	animated.frame_progress = 0.0
	if float(projectile.get_meta(META_HOLD_SPIN_RAD, 0.0)) > 0.0:
		projectile.set_meta(META_HOLD_SPIN_ACTIVE, true)


## Activa giro local del sprite al quedar en el frame de hold (centrado en el nodo).
static func setup_hold_spin(projectile: Node2D, animated: AnimatedSprite2D, spin_rad_per_sec: float) -> void:
	if projectile == null or animated == null or spin_rad_per_sec <= 0.0:
		return
	projectile.set_meta(META_HOLD_SPIN_RAD, spin_rad_per_sec)
	projectile.set_meta(META_HOLD_SPIN_ACTIVE, false)
	animated.centered = true
	if bool(projectile.get_meta(META_HOLD_SPIN_BOUND, false)):
		return
	projectile.set_meta(META_HOLD_SPIN_BOUND, true)
	animated.animation_finished.connect(
		_on_hold_spin_animation_finished.bind(projectile),
		CONNECT_ONE_SHOT
	)


static func tick_hold_spin(projectile: Node2D, delta: float) -> void:
	if projectile == null or delta <= 0.0:
		return
	var spin_rad: float = float(projectile.get_meta(META_HOLD_SPIN_RAD, 0.0))
	if spin_rad <= 0.0:
		return
	var animated: AnimatedSprite2D = get_sheet_visual(projectile)
	if animated == null:
		return
	if not bool(projectile.get_meta(META_HOLD_SPIN_ACTIVE, false)):
		if animated.is_playing():
			return
		projectile.set_meta(META_HOLD_SPIN_ACTIVE, true)
	animated.rotation += spin_rad * delta


static func _on_hold_spin_animation_finished(projectile: Node2D) -> void:
	if projectile != null and is_instance_valid(projectile):
		projectile.set_meta(META_HOLD_SPIN_ACTIVE, true)


## Circulito de color detrás del sprite — no tapa la hoja animada.
static func setup_bullet_dot(sprite: Sprite2D, fill_color: Color) -> void:
	if sprite == null:
		return
	sprite.texture = _ShapeFactory.create(_ShapeFactory.Shape.CIRCLE, BULLET_DOT_TEXTURE_PX, fill_color)
	sprite.centered = true
	sprite.scale = Vector2(BULLET_DOT_SCALE, BULLET_DOT_SCALE)
	sprite.z_index = -1
	sprite.z_as_relative = true
	sprite.visible = true
	sprite.modulate = Color(fill_color.r, fill_color.g, fill_color.b, 0.88)
	configure_pixel_art_sprite(sprite)


static func _apply_config_to_projectile(
	projectile: Node2D,
	fallback_sprite: Sprite2D,
	config: SkillVfxSheetConfig
) -> AnimatedSprite2D:
	if projectile == null or config == null or not config.is_valid():
		return null
	var existing: AnimatedSprite2D = get_sheet_visual(projectile)
	if existing != null:
		existing.queue_free()
	if fallback_sprite:
		fallback_sprite.visible = false
	var animated := AnimatedSprite2D.new()
	animated.name = String(VISUAL_NODE_NAME)
	projectile.add_child(animated)
	match config.mode:
		_Config.VisualMode.STATIC_REGION:
			if fallback_sprite:
				_Builder.apply_static_region(fallback_sprite, config)
				fallback_sprite.visible = true
				configure_pixel_art_sprite(fallback_sprite)
				apply_world_scale(fallback_sprite, config.world_scale)
				animated.queue_free()
				projectile.set_meta(META_USES_SHEET, true)
				return null
		_:
			if not _Builder.setup_animated_sprite(animated, config):
				animated.queue_free()
				if fallback_sprite:
					fallback_sprite.visible = true
				return null
			animated.z_index = 1
			animated.z_as_relative = true
			animated.modulate = Color.WHITE
			if config.hold_spin_rad_per_sec > 0.0:
				setup_hold_spin(projectile, animated, config.hold_spin_rad_per_sec)
	projectile.set_meta(META_USES_SHEET, true)
	return animated
