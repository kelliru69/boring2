## Main.gd — Mapa, spawner, modificadores y jefe según selección.
extends Node2D

const _EnemyCatalog = preload("res://data/enemy_catalog.gd")
const _MapConfig = preload("res://data/map_config.gd")
const _WaveCatalog = preload("res://data/wave_event_catalog.gd")
const _WaveController = preload("res://scripts/world/wave_event_controller.gd")

const BOSS_SPAWN_TIME: float = 540.0

@export var enemy_scene: PackedScene
@export var creamy_boss_scene: PackedScene
@export var osiris_boss_scene: PackedScene
@export var base_spawn_interval: float = 1.65
@export var min_spawn_interval: float = 0.45
@export var base_max_enemies: int = 42
@export var max_enemies_cap: int = 95
@export var spawn_radius: float = 500.0
@export var difficulty_step_seconds: float = 30.0
@export var spawn_interval_decay_per_step: float = 0.12
@export var max_enemies_bonus_per_step: int = 7

@onready var player: Player = $Player
@onready var spawn_timer: Timer = $SpawnTimer
@onready var camera: Camera2D = $Camera2D
@onready var run_result_ui: CanvasLayer = $RunResultUI

var field_background: Node2D = null
var _map_def: Dictionary = {}
var _current_max_enemies: int = 42
var _cached_enemy_count: int = 0
var _enemy_count_refresh_frame: int = -1
var _boss_spawned: bool = false
var _run_finished: bool = false
var _wave_controller: WaveEventController = null


func _ready() -> void:
	if Game.preserve_session_on_next_load:
		Game.preserve_session_on_next_load = false
	else:
		Global.reset_session()
	Global.reset_map_tombola_tools()
	_map_def = _MapConfig.get_definition(Game.selected_map_id)
	_current_max_enemies = base_max_enemies
	_spawn_map_background()
	if camera:
		camera.position_smoothing_enabled = true
	if field_background and field_background.has_method("bind_camera"):
		field_background.bind_camera(camera)
	spawn_timer.timeout.connect(_spawn_enemy)
	spawn_timer.wait_time = base_spawn_interval
	spawn_timer.start()
	if player:
		player.player_died.connect(_on_player_died)
		if Game.continued_from_map_id != "":
			player.sync_from_skill_tree()
			player.current_hp = player.max_hp
			player.health_changed.emit(player.current_hp, player.max_hp)
			Game.continued_from_map_id = ""
		_try_center_player_on_arena()
	_update_spawn_difficulty()
	_setup_wave_events()
	Audio.play_map_bgm(Game.selected_map_id)


func _spawn_map_background() -> void:
	var bg_path: String = String(_map_def.get("background_scene", _MapConfig.get_definition(_MapConfig.MAP_PRONTERA).background_scene))
	if not ResourceLoader.exists(bg_path):
		return
	var packed: PackedScene = load(bg_path) as PackedScene
	if packed == null:
		return
	field_background = packed.instantiate() as Node2D
	if field_background == null:
		return
	add_child(field_background)
	move_child(field_background, 0)
	if field_background.has_method("get_map_generator"):
		var gen: MapGenerator = field_background.get_map_generator()
		if gen and not gen.generation_finished.is_connected(_on_map_background_generated):
			gen.generation_finished.connect(_on_map_background_generated)
	elif field_background.has_method("get_playable_center"):
		call_deferred("_try_center_player_on_arena")
	if Game.selected_map_id == _MapConfig.MAP_PAYON:
		var sky: CanvasLayer = get_node_or_null("FieldSky") as CanvasLayer
		if sky:
			sky.visible = false


func _try_center_player_on_arena() -> void:
	if player and Arena.is_ready():
		player.global_position = Arena.get_center()


func _on_map_background_generated(_result: MapGenerator.MapGenerationResult) -> void:
	_try_center_player_on_arena()


func _process(_delta: float) -> void:
	if _run_finished:
		return
	if camera and player and is_instance_valid(player):
		camera.global_position = player.global_position
	_update_spawn_difficulty()
	if not _boss_spawned and Global.session_elapsed_time >= BOSS_SPAWN_TIME:
		_spawn_boss()


func _update_spawn_difficulty() -> void:
	if _run_finished:
		return
	var steps: int = int(Global.session_elapsed_time / difficulty_step_seconds)
	var interval: float = base_spawn_interval * pow(1.0 - spawn_interval_decay_per_step, float(steps))
	spawn_timer.wait_time = maxf(interval, min_spawn_interval)
	_current_max_enemies = mini(base_max_enemies + steps * max_enemies_bonus_per_step, max_enemies_cap)


func _setup_wave_events() -> void:
	_wave_controller = _WaveController.new()
	_wave_controller.name = "WaveEventController"
	add_child(_wave_controller)
	_wave_controller.setup(self)


func _spawn_enemy() -> void:
	if _run_finished:
		return
	if enemy_scene == null or player == null or not is_instance_valid(player):
		return
	var count: int = _get_enemy_count()
	if count >= _current_max_enemies:
		return
	_spawn_enemy_at(_pick_spawn_position(), "")


func _spawn_enemy_at(world_pos: Vector2, forced_type: String = "") -> Enemy:
	if enemy_scene == null:
		return null
	var enemy: Enemy = enemy_scene.instantiate() as Enemy
	if enemy == null:
		return null
	add_child(enemy)
	var type_id: String = forced_type
	if type_id.is_empty():
		type_id = _EnemyCatalog.pick_random_for_time(
			Global.session_elapsed_time, Game.selected_map_id
		)
	enemy.apply_type(type_id)
	enemy.apply_map_modifiers(
		float(_map_def.get("hp_multiplier", 1.0)),
		float(_map_def.get("damage_multiplier", 1.0))
	)
	enemy.global_position = world_pos
	return enemy


func run_wave_event(entry: Dictionary) -> void:
	if _run_finished or not Arena.is_ready():
		return
	var wave_type: String = String(entry.get("type", ""))
	var count: int = maxi(int(entry.get("count", 8)), 1)
	var speed: float = float(entry.get("speed", 90.0))
	match wave_type:
		_WaveCatalog.WALL_LEFT_RIGHT:
			_spawn_directional_wall(1.0, 0.0, count, speed)
		_WaveCatalog.WALL_RIGHT_LEFT:
			_spawn_directional_wall(-1.0, 0.0, count, speed)
		_WaveCatalog.WALL_TOP_BOTTOM:
			_spawn_directional_wall(0.0, 1.0, count, speed)
		_WaveCatalog.WALL_BOTTOM_TOP:
			_spawn_directional_wall(0.0, -1.0, count, speed)
		_WaveCatalog.HORDE_BURST:
			_spawn_horde_burst(count)
		_WaveCatalog.PINCH_HORIZONTAL:
			_spawn_pinch_horizontal(count, speed)
		_WaveCatalog.CROSS_WALLS:
			_spawn_directional_wall(1.0, 0.0, count, speed)
			_spawn_directional_wall(0.0, 1.0, maxi(int(float(count) * 0.75), 6), speed * 0.9)


func _spawn_directional_wall(dir_x: float, dir_y: float, count: int, speed: float) -> void:
	var rect: Rect2 = Arena.playable_rect
	var margin: float = 40.0
	var outside: float = 80.0
	var velocity: Vector2 = Vector2(dir_x, dir_y).normalized() * speed
	for i: int in count:
		var t: float = 0.0 if count <= 1 else float(i) / float(count - 1)
		var pos: Vector2
		if absf(dir_x) > absf(dir_y):
			var y: float = lerpf(rect.position.y + margin, rect.end.y - margin, t)
			var x: float = rect.position.x - outside if dir_x > 0.0 else rect.end.x + outside
			pos = Vector2(x, y)
		else:
			var x: float = lerpf(rect.position.x + margin, rect.end.x - margin, t)
			var y: float = rect.position.y - outside if dir_y > 0.0 else rect.end.y + outside
			pos = Vector2(x, y)
		var enemy: Enemy = _spawn_enemy_at(pos, "")
		if enemy:
			enemy.set_linear_movement(velocity, true)


func _spawn_horde_burst(count: int) -> void:
	for _i: int in count:
		_spawn_enemy_at(Arena.random_point_outside_playable(64.0), "")


func _spawn_pinch_horizontal(count: int, speed: float) -> void:
	var half: int = maxi(int(count / 2.0), 1)
	_spawn_directional_wall(1.0, 0.0, half, speed)
	_spawn_directional_wall(-1.0, 0.0, count - half, speed)


func _get_enemy_count() -> int:
	var frame: int = Engine.get_physics_frames()
	if frame != _enemy_count_refresh_frame:
		_enemy_count_refresh_frame = frame
		_cached_enemy_count = get_tree().get_nodes_in_group("Enemigos").size()
	return _cached_enemy_count


func _pick_spawn_position() -> Vector2:
	if field_background and field_background.has_method("get_map_generator"):
		var gen: MapGenerator = field_background.get_map_generator()
		if gen and gen.last_result:
			return gen.get_enemy_spawn_position(player.global_position, spawn_radius * 0.65)
	if Arena.is_ready():
		return Arena.random_point_outside_playable(80.0)
	var angle: float = randf() * TAU
	return player.global_position + Vector2.from_angle(angle) * spawn_radius


func debug_spawn_boss() -> void:
	if _run_finished:
		return
	_spawn_boss()


func _spawn_boss() -> void:
	if _boss_spawned or player == null:
		return
	var boss_key: String = String(_map_def.get("boss_scene_key", "creamy"))
	var boss_scene: PackedScene = creamy_boss_scene
	if boss_key == "osiris":
		boss_scene = osiris_boss_scene
	if boss_scene == null:
		return
	_boss_spawned = true
	var boss: Enemy = boss_scene.instantiate() as Enemy
	if boss == null:
		return
	add_child(boss)
	boss.global_position = _pick_spawn_position()
	if boss.has_signal("defeated") and not boss.defeated.is_connected(_on_boss_defeated):
		boss.defeated.connect(_on_boss_defeated)


func _on_boss_defeated() -> void:
	_clear_all_enemies()
	_finish_run(true)


func _clear_all_enemies() -> void:
	for node: Node in get_tree().get_nodes_in_group("Enemigos"):
		if is_instance_valid(node):
			node.queue_free()


func _on_player_died() -> void:
	_finish_run(false)


func _finish_run(victory: bool) -> void:
	if _run_finished:
		return
	_run_finished = true
	spawn_timer.stop()
	if _wave_controller:
		_wave_controller.set_active(false)
	var pause_menu: CanvasLayer = get_node_or_null("PauseMenu") as CanvasLayer
	if pause_menu and pause_menu.has_method("close_pause_menu"):
		pause_menu.close_pause_menu()
	Audio.stop_bgm()
	Game.end_run(victory, Global.run_zeny)
	if run_result_ui and run_result_ui.has_method("show_result"):
		run_result_ui.show_result(victory, Global.run_zeny)
