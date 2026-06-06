## Haz de hielo Line2D — Frost Diver (cristalino, no zig-zag eléctrico).
extends Node2D
class_name FrostDiverBeam

@export var glow_width: float = 9.0
@export var core_width: float = 3.2
@export var shard_width: float = 1.6
@export var segment_count: int = 7
@export var jitter: float = 11.0

var _glow: Line2D
var _core: Line2D
var _shard: Line2D
var _from: Vector2 = Vector2.ZERO
var _to: Vector2 = Vector2.ZERO
var _elapsed: float = 0.0
var _ready_lines: bool = false


func _ready() -> void:
	_ensure_lines()


func _ensure_lines() -> void:
	if _ready_lines:
		return
	_glow = _make_line(glow_width, Color(0.65, 0.9, 1.0, 0.28))
	_core = _make_line(core_width, Color(0.88, 0.98, 1.0, 0.82))
	_shard = _make_line(shard_width, Color(1.0, 1.0, 1.0, 0.95))
	add_child(_glow)
	add_child(_core)
	add_child(_shard)
	_ready_lines = true


func _make_line(stroke: float, tint: Color) -> Line2D:
	var line: Line2D = Line2D.new()
	line.visible = false
	line.width = stroke
	line.default_color = tint
	line.joint_mode = Line2D.LINE_JOINT_SHARP
	line.begin_cap_mode = Line2D.LINE_CAP_BOX
	line.end_cap_mode = Line2D.LINE_CAP_NONE
	line.antialiased = true
	CombatVfxPalette.apply_soft_blend(line)
	return line


func update_beam(from_world: Vector2, to_world: Vector2, time: float) -> void:
	_ensure_lines()
	_from = from_world
	_to = to_world
	_elapsed = time
	var noise_seed: int = int(_elapsed * 14.0)
	var points: PackedVector2Array = LightningPathBuilder.build_zigzag(
		from_world, to_world, segment_count, jitter, noise_seed
	)
	var local_pts: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in points:
		local_pts.append(to_local(p))
	_glow.points = local_pts
	_core.points = local_pts
	_shard.points = local_pts
	_glow.visible = true
	_core.visible = true
	_shard.visible = true
	var pulse: float = 0.75 + 0.25 * sin(_elapsed * 18.0)
	_glow.default_color = Color(0.55, 0.85, 1.0, 0.22 * pulse)
	_core.default_color = Color(0.82, 0.96, 1.0, 0.78 * pulse)
	_shard.default_color = Color(0.72, 0.96, 1.0, 0.72 * pulse)
