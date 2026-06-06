## Rayo dinámico Line2D — zig-zag, flash rápido, sin bloques cuadrados.
extends Node2D
class_name LightningBoltBeam

@export var core_width: float = 2.8
@export var glow_width: float = 7.5
@export var segment_count: int = 9
@export var jitter: float = 20.0
@export var branch_count: int = 2
@export var beam_extra_length: float = 28.0

var _glow_line: Line2D
var _core_line: Line2D
var _hot_line: Line2D
var _branches: Array[Line2D] = []
var _from: Vector2 = Vector2.ZERO
var _to: Vector2 = Vector2.ZERO
var _elapsed: float = 0.0
var _noise_seed: int = 0
var _lines_ready: bool = false


func _ready() -> void:
	_ensure_lines()
	_noise_seed = randi()
	set_process(true)


func _ensure_lines() -> void:
	if _lines_ready:
		return
	_glow_line = _make_line(glow_width, 0.35)
	_core_line = _make_line(core_width, 0.85)
	_hot_line = _make_line(core_width * 0.45, 1.0)
	add_child(_glow_line)
	add_child(_core_line)
	add_child(_hot_line)
	_branches.clear()
	for _i: int in branch_count:
		var branch: Line2D = _make_line(core_width * 0.55, 0.65)
		_branches.append(branch)
		add_child(branch)
	_lines_ready = true


func _make_line(stroke: float, alpha_scale: float) -> Line2D:
	var line: Line2D = Line2D.new()
	line.visible = false
	line.width = stroke
	line.default_color = Color(CombatVfxPalette.PLAYER_LIGHTNING_CORE.r, CombatVfxPalette.PLAYER_LIGHTNING_CORE.g, CombatVfxPalette.PLAYER_LIGHTNING_CORE.b, alpha_scale)
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.antialiased = true
	CombatVfxPalette.apply_soft_blend(line)
	return line


func update_beam(from_world: Vector2, to_world: Vector2, flicker_time: float) -> void:
	_ensure_lines()
	_from = from_world
	_to = to_world
	_elapsed = flicker_time
	_rebuild_geometry()
	_glow_line.visible = true
	_core_line.visible = true
	_hot_line.visible = true
	for branch_line: Line2D in _branches:
		branch_line.visible = true


func _rebuild_geometry() -> void:
	var dir: Vector2 = (_to - _from)
	if dir.length_squared() < 0.01:
		dir = Vector2.RIGHT
	var extended_from: Vector2 = _from - dir.normalized() * beam_extra_length * 0.35
	var extended_to: Vector2 = _to + dir.normalized() * beam_extra_length
	var noise_seed: int = _noise_seed + int(_elapsed * 60.0)
	var points: PackedVector2Array = LightningPathBuilder.build_zigzag(
		extended_from, extended_to, segment_count, jitter, noise_seed
	)
	var local_pts: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in points:
		local_pts.append(to_local(p))
	_glow_line.points = local_pts
	_core_line.points = local_pts
	_hot_line.points = local_pts
	_update_branches(local_pts, noise_seed)
	_apply_flicker()


func _update_branches(local_points: PackedVector2Array, branch_noise_seed: int) -> void:
	if local_points.size() < 4:
		return
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = branch_noise_seed + 991
	var max_i: int = maxi(local_points.size() - 2, 2)
	for i: int in _branches.size():
		var line: Line2D = _branches[i]
		var anchor_i: int = rng.randi_range(2, max_i)
		var anchor: Vector2 = local_points[anchor_i]
		var tangent: Vector2 = local_points[mini(anchor_i + 1, local_points.size() - 1)] - anchor
		if tangent.length_squared() < 0.01:
			tangent = Vector2.RIGHT
		var branch_dir: Vector2 = tangent.rotated(rng.randf_range(-1.1, 1.1)).normalized()
		var branch_pts: PackedVector2Array = LightningPathBuilder.build_branch(
			to_global(anchor),
			branch_dir,
			rng.randf_range(14.0, 34.0),
			branch_noise_seed + i * 17
		)
		var local_branch: PackedVector2Array = PackedVector2Array()
		for p: Vector2 in branch_pts:
			local_branch.append(to_local(p))
		line.points = local_branch


func _apply_flicker() -> void:
	var flicker: float = 0.4 + 0.6 * absf(sin(_elapsed * 52.0))
	var col: Color = CombatVfxPalette.player_lightning_modulate(_elapsed)
	col.a = flicker
	_glow_line.default_color = Color(col.r, col.g, col.b, flicker * 0.35)
	_core_line.default_color = Color(col.r, col.g, col.b, flicker * 0.82)
	_hot_line.default_color = Color(col.r, col.g, col.b, flicker * 0.92)
	for branch: Line2D in _branches:
		branch.default_color = Color(col.r, col.g, col.b, flicker * 0.55)


func _process(_delta: float) -> void:
	if _from != _to:
		_rebuild_geometry()
