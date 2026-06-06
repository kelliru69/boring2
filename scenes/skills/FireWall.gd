## Fire Wall — línea vertical ígnea (eje Y del mapa) a izquierda/derecha del jugador.
class_name FireWall
extends Area2D

const _SkillDefs = preload("res://data/skill_definitions.gd")
const _AreaHitHelper = preload("res://scripts/combat/area_hit_helper.gd")
const _Vfx = preload("res://scripts/vfx/elemental_vfx_spawner.gd")
const _HitFlash = preload("res://scripts/vfx/enemy_hit_flash.gd")
const _MageVfx = preload("res://scripts/vfx/mage_skill_vfx.gd")
const _SkillVisual = preload("res://scripts/skills/skill_visual_service.gd")
const _ProjectileBase = preload("res://scripts/skills/projectile_skill_base.gd")

@export var tile_count: int = 1
@export var tile_px: float = 32.0
@export var damage: int = 16
@export var duration: float = 3.0
@export var knockback_force: float = 0.0
@export var pulse_interval: float = 0.45

var line_length_px: float = 32.0
var knockback_dir: Vector2 = Vector2.LEFT

var _elapsed: float = 0.0
var _pulse_accum: float = 0.0
var _tile_visual_hosts: Array[Node2D] = []

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Sprite2D = $Sprite2D


func setup_barrier(
	world_pos: Vector2,
	barrier_tile_count: int,
	barrier_tile_px: float,
	barrier_damage: int,
	kb: float,
	life: float,
	push_direction: Vector2 = Vector2.LEFT
) -> void:
	global_position = world_pos
	tile_count = maxi(barrier_tile_count, 1)
	tile_px = maxf(barrier_tile_px, 1.0)
	line_length_px = float(tile_count) * tile_px
	damage = barrier_damage
	knockback_force = kb
	duration = life
	knockback_dir = push_direction.normalized() if push_direction.length_squared() > 0.001 else Vector2.LEFT
	_apply_collision_shape()
	_apply_barrier_visual()
	queue_redraw()


func _line_half_height() -> float:
	return line_length_px * 0.5


func _apply_collision_shape() -> void:
	if collision_shape == null:
		return
	var rect := RectangleShape2D.new()
	rect.size = Vector2(tile_px, line_length_px)
	collision_shape.shape = rect
	collision_shape.position = Vector2.ZERO


func _apply_barrier_visual() -> void:
	_clear_tile_visuals()
	if visual:
		visual.visible = false
	var uses_any_sheet: bool = false
	var half_h: float = _line_half_height()
	for i: int in tile_count:
		var tile_host := Node2D.new()
		tile_host.name = StringName("FirewallTile_%d" % i)
		tile_host.position = Vector2(0.0, -half_h + tile_px * 0.5 + float(i) * tile_px)
		add_child(tile_host)
		_tile_visual_hosts.append(tile_host)
		var fallback := Sprite2D.new()
		fallback.visible = false
		tile_host.add_child(fallback)
		var animated: AnimatedSprite2D = _SkillVisual.apply_mage_area_aura(
			tile_host, fallback, "firewall", "aura", tile_px * 0.5
		)
		if animated != null:
			uses_any_sheet = true
	if uses_any_sheet:
		set_meta(_ProjectileBase.META_USES_SHEET, true)
	if _SkillVisual.use_legacy_particle_vfx():
		_Vfx.attach_firewall_ambient(self, line_length_px * 0.5)


func _clear_tile_visuals() -> void:
	for node: Node2D in _tile_visual_hosts:
		if is_instance_valid(node):
			node.queue_free()
	_tile_visual_hosts.clear()
	if has_meta(_ProjectileBase.META_USES_SHEET):
		remove_meta(_ProjectileBase.META_USES_SHEET)


func _process(delta: float) -> void:
	_elapsed += delta
	_pulse_accum += delta
	queue_redraw()
	if _elapsed >= duration:
		queue_free()
		return
	if _pulse_accum >= pulse_interval:
		_pulse_accum = 0.0
		_pulse_damage()


func _pulse_damage() -> void:
	var parent: Node = get_parent()
	if parent != null and _SkillVisual.has_config("firewall", "pulse"):
		_SkillVisual.spawn_mage_impact(parent, global_position, "firewall", "pulse", tile_px * 0.55)
	var world: World2D = get_world_2d()
	var top_origin: Vector2 = global_position - Vector2(0.0, _line_half_height())
	_AreaHitHelper.for_each_enemy_body_in_box(
		top_origin, Vector2.DOWN, tile_px, line_length_px, world, _on_hit
	)


func _on_hit(body: Node2D) -> void:
	if not body.is_in_group(_SkillDefs.GROUP_ENEMIES):
		return
	if body.has_method("take_damage"):
		body.take_damage(damage, _HitFlash.ELEMENT_FIRE)
	if knockback_force > 0.0 and body.has_method("apply_knockback"):
		body.apply_knockback(knockback_dir * knockback_force)


func _draw() -> void:
	if _ProjectileBase.uses_skill_sheet(self):
		return
	_MageVfx.draw_fire_barrier_line(self, tile_px, tile_count, _elapsed, duration)
