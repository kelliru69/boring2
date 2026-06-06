## Rayo vertical ramificado (Line2D) — parpadeo rápido de alta energía.
extends Node2D
class_name LightningZapFx

@export var bolt_height: float = 160.0
@export var segment_count: int = 9
@export var jitter: float = 26.0
@export var branch_count: int = 3
@export var line_width: float = 3.5
@export var fade_duration: float = 0.22

var _main_line: Line2D
var _branch_lines: Array[Line2D] = []
var _elapsed: float = 0.0
var _lines_ready: bool = false


func _ready() -> void:
	_ensure_lines()
	set_process(true)


func _ensure_lines() -> void:
	if _lines_ready:
		return
	_main_line = _make_line(line_width)
	add_child(_main_line)
	_branch_lines.clear()
	for _i: int in branch_count:
		var branch: Line2D = _make_line(line_width * 0.55)
		_branch_lines.append(branch)
		add_child(branch)
	_lines_ready = true


func _make_line(stroke_width: float) -> Line2D:
	var line: Line2D = Line2D.new()
	line.visible = false
	line.default_color = CombatVfxPalette.PLAYER_LIGHTNING_CORE
	line.width = stroke_width
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.antialiased = true
	CombatVfxPalette.apply_line_glow(line)
	return line


func setup_vertical_strike(ground_pos: Vector2, height: float = 160.0) -> void:
	_ensure_lines()
	bolt_height = height
	global_position = ground_pos
	var top: Vector2 = Vector2(0.0, -bolt_height)
	var points: PackedVector2Array = LightningPathBuilder.build_zigzag(
		top, Vector2.ZERO, segment_count, jitter, randi()
	)
	_main_line.points = points
	_build_branches(points)
	_main_line.visible = true
	for branch_line: Line2D in _branch_lines:
		branch_line.visible = true


func _build_branches(local_points: PackedVector2Array) -> void:
	if local_points.size() < 4:
		return
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	var max_i: int = maxi(local_points.size() - 2, 2)
	for idx: int in _branch_lines.size():
		var line: Line2D = _branch_lines[idx]
		var anchor_i: int = rng.randi_range(2, max_i)
		var anchor: Vector2 = local_points[anchor_i]
		var tangent: Vector2 = local_points[mini(anchor_i + 1, local_points.size() - 1)] - anchor
		var branch_dir: Vector2 = tangent.rotated(rng.randf_range(-1.0, 1.0)).normalized()
		var branch_world: PackedVector2Array = LightningPathBuilder.build_branch(
			to_global(anchor), branch_dir, rng.randf_range(18.0, 42.0), rng.randi()
		)
		var local_branch: PackedVector2Array = PackedVector2Array()
		for p: Vector2 in branch_world:
			local_branch.append(to_local(p))
		line.points = local_branch


func _process(delta: float) -> void:
	if not _lines_ready:
		return
	_elapsed += delta
	var flicker: float = 0.35 + 0.65 * absf(sin(_elapsed * 48.0))
	var alpha: float = (1.0 - clampf(_elapsed / fade_duration, 0.0, 1.0)) * flicker
	var col: Color = CombatVfxPalette.player_lightning_modulate(_elapsed)
	col.a = alpha
	_main_line.default_color = col
	_main_line.width = line_width * (0.5 + alpha * 0.8)
	for branch_line: Line2D in _branch_lines:
		branch_line.default_color = col.lightened(0.12)
		branch_line.width = line_width * 0.45 * (0.6 + alpha * 0.5)
	if _elapsed >= fade_duration:
		queue_free()
