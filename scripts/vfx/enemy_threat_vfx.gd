## VFX de amenaza enemiga — círculos rojos sutiles en el suelo (estilo original).
extends RefCounted
class_name EnemyThreatVfx

const _TileDepthSort = preload("res://scripts/visual/tile_depth_sort.gd")


static func draw_ground_telegraph(
	canvas: CanvasItem,
	center: Vector2,
	radius: float,
	elapsed: float,
	duration: float = -1.0
) -> void:
	if canvas == null:
		return
	var t: float = elapsed
	if duration > 0.0:
		t = elapsed / maxf(duration, 0.01)
	var fill_a: float = 0.11 + t * 0.16 + sin(elapsed * 10.0) * 0.04
	var ring_a: float = 0.34 + sin(elapsed * 12.0) * 0.1
	var fill: Color = Color(1.0, 0.15, 0.1, fill_a)
	var ring: Color = Color(1.0, 0.2, 0.12, ring_a)
	canvas.draw_circle(center, radius, fill)
	canvas.draw_arc(center, radius, 0.0, TAU, 48, ring, 2.5, true)


static func setup_enemy_projectile_sprite(sprite: CanvasItem, _pulse: float = 0.0) -> void:
	if sprite == null:
		return
	if sprite is CanvasItem:
		(sprite as CanvasItem).material = null
		(sprite as CanvasItem).modulate = Color(1.0, 0.2, 0.12, 1.0)


static func attach_enemy_projectile_trail(_projectile: Node2D) -> void:
	pass


static func apply_ground_layer_z(node: CanvasItem, world_y: float) -> void:
	if node == null:
		return
	node.z_as_relative = false
	node.z_index = _TileDepthSort.compute_ground_telegraph_z_index(world_y)


## Telémetro lineal (rayos de jefe).
static func draw_line_telegraph(
	canvas: CanvasItem,
	from_pos: Vector2,
	to_pos: Vector2,
	elapsed: float,
	duration: float,
	base_width: float = 24.0
) -> void:
	if canvas == null:
		return
	var tele_t: float = clampf(1.0 - elapsed / maxf(duration, 0.01), 0.0, 1.0)
	var pulse: float = 0.35 + sin(elapsed * 14.0) * 0.15 + tele_t * 0.2
	var fill: Color = Color(1.0, 0.15, 0.1, 0.1 + tele_t * 0.1)
	var core: Color = Color(1.0, 0.2, 0.12, pulse)
	canvas.draw_line(from_pos, to_pos, fill, base_width * 0.55)
	canvas.draw_line(from_pos, to_pos, core, base_width * 0.22)
	canvas.draw_circle(to_pos, base_width * 0.18, core)


## Zona de daño enemiga (espíritus orbitales, AoE persistente).
static func draw_threat_zone(
	canvas: CanvasItem,
	center: Vector2,
	radius: float,
	elapsed: float,
	_pulse_hz: float = 10.0
) -> void:
	if canvas == null:
		return
	draw_ground_telegraph(canvas, center, radius, elapsed, -1.0)


## Flash del golpe activo (tras el telémetro).
static func draw_line_strike_flash(
	canvas: CanvasItem,
	from_pos: Vector2,
	to_pos: Vector2,
	alpha: float,
	base_width: float = 24.0
) -> void:
	if canvas == null or alpha <= 0.01:
		return
	var core: Color = Color(1.0, 0.22, 0.14, alpha * 0.85)
	var hot: Color = Color(1.0, 0.45, 0.25, alpha * 0.55)
	canvas.draw_line(from_pos, to_pos, core, base_width * 0.38)
	canvas.draw_line(from_pos, to_pos, hot, base_width * 0.2)


const GROUND_TELEGRAPH_META: StringName = &"enemy_ground_telegraph"


static func ensure_ground_telegraph(owner: Node) -> EnemyGroundTelegraph:
	if owner == null:
		return null
	if owner.has_meta(GROUND_TELEGRAPH_META):
		var existing: EnemyGroundTelegraph = owner.get_meta(GROUND_TELEGRAPH_META) as EnemyGroundTelegraph
		if existing and is_instance_valid(existing):
			return existing
	var node: EnemyGroundTelegraph = EnemyGroundTelegraph.new()
	var parent: Node = owner.get_tree().current_scene
	if parent == null:
		parent = owner
	parent.add_child(node)
	owner.set_meta(GROUND_TELEGRAPH_META, node)
	return node


static func release_ground_telegraph(owner: Node) -> void:
	if owner == null:
		return
	if owner.has_meta(GROUND_TELEGRAPH_META):
		var node: EnemyGroundTelegraph = owner.get_meta(GROUND_TELEGRAPH_META) as EnemyGroundTelegraph
		if node and is_instance_valid(node):
			node.queue_free()
		owner.remove_meta(GROUND_TELEGRAPH_META)
