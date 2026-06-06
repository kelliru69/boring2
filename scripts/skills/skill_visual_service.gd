## Fachada de alto nivel: enlaza habilidades Mage/Swordman con hojas VFX del registro.
class_name SkillVisualService
extends RefCounted

const _ProjectileBase = preload("res://scripts/skills/projectile_skill_base.gd")
const _Builder = preload("res://scripts/visual/skill_vfx_spritesheet_builder.gd")
const _Registry = preload("res://data/skill_vfx_registry.gd")
const _Config = preload("res://scripts/visual/skill_vfx_sheet_config.gd")
const _MageVfx = preload("res://scripts/vfx/mage_skill_vfx.gd")
const _SwordVfx = preload("res://scripts/vfx/swordman_skill_vfx.gd")
const _Palette = preload("res://scripts/vfx/combat_vfx_palette.gd")

const VISUAL_NODE_NAME: StringName = &"SkillSheetVisual"

## Desactiva trails/partículas/impactos procedurales que tapan las hojas de sprite.
const USE_LEGACY_PARTICLE_VFX: bool = false
const USE_SIGHT_WISP_PARTICLES: bool = false
const USE_BULLET_DOT: bool = true


# --- Proyectiles Mage ---------------------------------------------------------

static func use_legacy_particle_vfx() -> bool:
	return USE_LEGACY_PARTICLE_VFX


static func apply_mage_projectile(
	projectile: Node2D,
	fallback_sprite: Sprite2D,
	skill_id: String,
	element: StringName = &""
) -> AnimatedSprite2D:
	var animated: AnimatedSprite2D = _ProjectileBase.setup_from_registry(
		projectile, fallback_sprite, skill_id, "projectile"
	)
	var uses_sheet: bool = _ProjectileBase.uses_skill_sheet(projectile)
	var dot_color: Color = _element_bullet_color(element)
	if uses_sheet and animated != null:
		animated.modulate = Color.WHITE
		if fallback_sprite and USE_BULLET_DOT:
			_ProjectileBase.setup_bullet_dot(fallback_sprite, dot_color)
	elif fallback_sprite:
		if USE_BULLET_DOT:
			_ProjectileBase.setup_bullet_dot(fallback_sprite, dot_color)
		else:
			fallback_sprite.visible = true
			_MageVfx.setup_player_projectile(fallback_sprite, element)
	return animated


static func spawn_mage_impact(parent: Node, world_pos: Vector2, skill_id: String, role_key: String = "impact", radius_px: float = -1.0) -> AnimatedSprite2D:
	var animated: AnimatedSprite2D = _spawn_world_effect(parent, world_pos, skill_id, role_key)
	if animated != null and radius_px > 0.0:
		_scale_sheet_to_radius(animated, radius_px)
	return animated


static func spawn_mage_strike(parent: Node, world_pos: Vector2, skill_id: String, radius_px: float = -1.0) -> AnimatedSprite2D:
	var animated: AnimatedSprite2D = _spawn_world_effect(parent, world_pos, skill_id, "strike")
	if animated != null and radius_px > 0.0:
		_scale_sheet_to_radius(animated, radius_px)
	return animated


## Efecto de área persistente (Fire Wall, Thunderstorm) escalado al radio de juego.
static func apply_mage_area_aura(
	host: Node2D,
	fallback_sprite: Sprite2D,
	skill_id: String,
	role_key: String = "aura",
	radius_px: float = -1.0
) -> AnimatedSprite2D:
	var animated: AnimatedSprite2D = _ProjectileBase.setup_from_registry(
		host, fallback_sprite, skill_id, role_key
	)
	if _ProjectileBase.uses_skill_sheet(host) and animated != null:
		animated.modulate = Color.WHITE
		if radius_px > 0.0:
			_scale_sheet_to_radius(animated, radius_px)
		if fallback_sprite:
			fallback_sprite.visible = false
	elif fallback_sprite:
		fallback_sprite.visible = true
	return animated


static func has_config(skill_id: String, role_key: String = "projectile") -> bool:
	return _Registry.has_config(skill_id, role_key)


# --- Efectos Swordman ---------------------------------------------------------

static func attach_swordman_slash(host: Node2D, skill_id: String, role_key: String = "slash") -> AnimatedSprite2D:
	if host == null:
		return null
	var config: SkillVfxSheetConfig = _Registry.get_config(skill_id, role_key)
	if config == null or not config.is_valid():
		return null
	var animated: AnimatedSprite2D = _ensure_visual_node(host)
	if not _Builder.setup_animated_sprite(animated, config):
		return null
	animated.z_index = _SwordVfx.Z_INDEX
	animated.z_as_relative = false
	animated.modulate = Color.WHITE
	_Palette.apply_soft_blend(animated)
	host.set_meta(_ProjectileBase.META_USES_SHEET, true)
	return animated


static func spawn_swordman_impact(parent: Node, world_pos: Vector2, skill_id: String) -> AnimatedSprite2D:
	return _spawn_world_effect(parent, world_pos, skill_id, "impact")


# --- Sight / auras ------------------------------------------------------------

static func apply_sight_aura(orb: Node2D, fallback_sprite: Sprite2D) -> AnimatedSprite2D:
	var animated: AnimatedSprite2D = _ProjectileBase.setup_from_registry(
		orb, fallback_sprite, "sight", "aura"
	)
	if _ProjectileBase.uses_skill_sheet(orb) and animated != null:
		animated.modulate = Color.WHITE
		if fallback_sprite and USE_BULLET_DOT:
			_ProjectileBase.setup_bullet_dot(fallback_sprite, _Palette.PLAYER_SIGHT_CORE)
	elif fallback_sprite and USE_BULLET_DOT:
		_ProjectileBase.setup_bullet_dot(fallback_sprite, _Palette.PLAYER_SIGHT_CORE)
	return animated


# --- API genérica -------------------------------------------------------------

static func get_config(skill_id: String, role_key: String = "projectile") -> SkillVfxSheetConfig:
	return _Registry.get_config(skill_id, role_key)


static func build_sprite_frames(skill_id: String, role_key: String = "projectile") -> SpriteFrames:
	var config: SkillVfxSheetConfig = _Registry.get_config(skill_id, role_key)
	if config == null:
		return null
	return _Builder.build_sprite_frames(config)


static func _element_bullet_color(element: StringName) -> Color:
	match element:
		&"fire":
			return _Palette.PLAYER_FIRE_CORE
		&"ice":
			return _Palette.PLAYER_ICE_CORE
		&"lightning":
			return _Palette.PLAYER_LIGHTNING_CORE
		&"soul":
			return _Palette.PLAYER_SOUL_CORE
		_:
			return Color(0.85, 0.85, 0.85, 1.0)


static func _spawn_world_effect(
	parent: Node,
	world_pos: Vector2,
	skill_id: String,
	role_key: String
) -> AnimatedSprite2D:
	if parent == null:
		return null
	var config: SkillVfxSheetConfig = _Registry.get_config(skill_id, role_key)
	if config == null or not config.is_valid():
		return null
	var host := Node2D.new()
	host.name = StringName("%s_%s_fx" % [skill_id, role_key])
	host.global_position = world_pos
	parent.add_child(host)
	var animated: AnimatedSprite2D = _ensure_visual_node(host)
	if not _Builder.setup_animated_sprite(animated, config):
		host.queue_free()
		return null
	if config.mode == _Config.VisualMode.ONE_SHOT:
		animated.animation_finished.connect(host.queue_free)
	return animated


static func _scale_sheet_to_radius(visual: Node2D, radius_px: float, cell_px: float = 32.0) -> void:
	if visual == null or radius_px <= 0.0:
		return
	var factor: float = (radius_px * 2.0) / cell_px
	visual.scale = Vector2(factor, factor)


static func _ensure_visual_node(host: Node2D) -> AnimatedSprite2D:
	var existing: Node = host.get_node_or_null(String(VISUAL_NODE_NAME))
	if existing is AnimatedSprite2D:
		return existing as AnimatedSprite2D
	var animated := AnimatedSprite2D.new()
	animated.name = String(VISUAL_NODE_NAME)
	host.add_child(animated)
	return animated
