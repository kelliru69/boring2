## Main.gd — Mapa, spawner, modificadores y jefe según selección.
extends Node2D

const _EnemyCatalog = preload("res://data/enemy_catalog.gd")
const _MapConfig = preload("res://data/map_config.gd")
const _WaveCatalog = preload("res://data/wave_event_catalog.gd")
const _WaveController = preload("res://scripts/world/wave_event_controller.gd")
const _GridSelectorScene: PackedScene = preload("res://scenes/world/GridSelector.tscn")
const _HealBuffDropScene: PackedScene = preload("res://scenes/pickups/HealBuffDrop.tscn")
const _Scoreboard = preload("res://scripts/persistence/local_scoreboard.gd")
const _CombatEnvironment = preload("res://scripts/vfx/combat_environment_factory.gd")

const BOSS_SPAWN_TIME: float = 540.0
const BOSS_LOOT_PHASE_SECONDS: float = 30.0
const BOSS_WARNING_LEAD_SECONDS: float = 3.0

## Drop de cruz verde: ~1 aparición cada 5 minutos (300 s) de media.
const HEAL_BUFF_TARGET_INTERVAL_SEC: float = 300.0
const HEAL_BUFF_CHECK_INTERVAL_SEC: float = 10.0
## Probabilidad por tick: p = Δt / T. Con Δt=10 y T=300 → p ≈ 3.33%.
## E[ticks hasta éxito] = 1/p = T/Δt = 30 ticks → E[tiempo] = 30 × 10 s = 300 s.
const HEAL_BUFF_SPAWN_PROBABILITY: float = HEAL_BUFF_CHECK_INTERVAL_SEC / HEAL_BUFF_TARGET_INTERVAL_SEC
const HEAL_BUFF_SPAWN_MIN_RADIUS: float = 100.0
const HEAL_BUFF_SPAWN_MAX_RADIUS: float = 360.0

@export var enemy_scene: PackedScene
@export var creamy_boss_scene: PackedScene
@export var moonlight_flower_boss_scene: PackedScene
@export var orc_hero_boss_scene: PackedScene
@export var base_spawn_interval: float = 1.65
@export var min_spawn_interval: float = 0.45
@export var base_max_enemies: int = 53 # +25% (antes 42)
@export var max_enemies_cap: int = 119 # +25% (antes 95)
@export var spawn_radius: float = 500.0
@export var difficulty_step_seconds: float = 30.0
@export var spawn_interval_decay_per_step: float = 0.12
@export var max_enemies_bonus_per_step: int = 9 # +25% (antes 7)
## Zoom de cámara en partida (1.0 = sin acercar).
@export var camera_game_zoom: float = 1.0

@onready var player: Player = $Player
@onready var spawn_timer: Timer = $SpawnTimer
@onready var camera: Camera2D = $Camera2D
@onready var run_result_ui: CanvasLayer = $RunResultUI
@onready var game_hud: CanvasLayer = $GameHUD
@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var job_change_menu: CanvasLayer = $JobChangeMenu

var field_background: Node2D = null
var _map_def: Dictionary = {}
var _current_max_enemies: int = 42
var _cached_enemy_count: int = 0
var _enemy_count_refresh_frame: int = -1
var _boss_spawned: bool = false
var _run_finished: bool = false
var _loot_phase_active: bool = false
var _loot_phase_timer: float = 0.0
var _boss_warning_triggered: bool = false
var _wave_controller: WaveEventController = null
var _grid_selector: GridSelector = null
var _grid_selector_ready: bool = false
var _heal_buff_check_timer: Timer = null


func _ready() -> void:
	_CombatEnvironment.apply_to(world_environment, Game.selected_map_id)
	if Game.preserve_session_on_next_load:
		Game.preserve_session_on_next_load = false
	else:
		Global.reset_session()
		if game_hud and game_hud.has_method("reset_for_new_run"):
			game_hud.reset_for_new_run()
	Global.reset_map_tombola_tools()
	_map_def = _MapConfig.get_definition(Game.selected_map_id)
	var spawn_mult: float = float(_map_def.get("spawn_interval_multiplier", 1.0))
	base_spawn_interval = maxf(base_spawn_interval * spawn_mult, min_spawn_interval)
	_current_max_enemies = base_max_enemies + int(_map_def.get("max_enemies_bonus", 0))
	_spawn_map_background()
	if camera:
		# Suavizado desactivado: con pixel art produce desfase/jitter frente al movimiento en físicas.
		camera.position_smoothing_enabled = false
		camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
		camera.zoom = Vector2.ONE * maxf(camera_game_zoom, 0.25)
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
		if Game.selected_map_id == _MapConfig.MAP_ORC_VILLAGE and player.has_method("apply_map3_evolved_power_boost"):
			player.apply_map3_evolved_power_boost()
		_try_center_player_on_arena()
	_update_spawn_difficulty()
	_setup_wave_events()
	_setup_ro_aiming_visuals()
	_setup_heal_buff_spawner()
	if not GraphicsSettings.settings_changed.is_connected(_on_graphics_settings_changed):
		GraphicsSettings.settings_changed.connect(_on_graphics_settings_changed)
	if job_change_menu and job_change_menu.has_signal("job_selected") and not job_change_menu.job_selected.is_connected(_on_job_change_completed):
		job_change_menu.job_selected.connect(_on_job_change_completed)
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


func _process(delta: float) -> void:
	if _loot_phase_active:
		_loot_phase_timer = maxf(_loot_phase_timer - delta, 0.0)
		if game_hud and game_hud.has_method("set_map_exit_countdown"):
			game_hud.set_map_exit_countdown(_loot_phase_timer)
		if _loot_phase_timer <= 0.0:
			_end_loot_phase()
		return
	if _run_finished:
		return
	_update_spawn_difficulty()
	if not _boss_spawned:
		if not _boss_warning_triggered \
				and Global.session_elapsed_time >= BOSS_SPAWN_TIME - BOSS_WARNING_LEAD_SECONDS:
			_boss_warning_triggered = true
			if game_hud and game_hud.has_method("show_boss_warning"):
				game_hud.show_boss_warning(BOSS_WARNING_LEAD_SECONDS)
			Arena.announce_wave("¡Cuidado! El jefe está por aparecer")
		if Global.session_elapsed_time >= BOSS_SPAWN_TIME:
			_spawn_boss()


func _physics_process(_delta: float) -> void:
	_sync_camera_to_player()


func _sync_camera_to_player() -> void:
	if camera == null or player == null or not is_instance_valid(player):
		return
	# Alineación a píxeles enteros reduce vibración/borrosidad en sprites pixel art.
	camera.global_position = player.global_position.round()


func show_wall_wave_warning(wave_type: String, duration: float) -> void:
	if game_hud and game_hud.has_method("show_wall_wave_warning"):
		game_hud.show_wall_wave_warning(wave_type, duration)


func hide_wall_wave_warning() -> void:
	if game_hud and game_hud.has_method("hide_wall_wave_warning"):
		game_hud.hide_wall_wave_warning()


func _update_spawn_difficulty() -> void:
	if _run_finished:
		return
	var steps: int = int(Global.session_elapsed_time / difficulty_step_seconds)
	var interval: float = base_spawn_interval * pow(1.0 - spawn_interval_decay_per_step, float(steps))
	spawn_timer.wait_time = maxf(interval, min_spawn_interval)
	_current_max_enemies = mini(base_max_enemies + steps * max_enemies_bonus_per_step, max_enemies_cap)


func _setup_ro_aiming_visuals() -> void:
	RoCursor.apply_game_cursor()
	if _grid_selector == null:
		var node: Node = _GridSelectorScene.instantiate()
		_grid_selector = node as GridSelector
		if _grid_selector == null:
			push_warning("Main: no se pudo instanciar GridSelector.")
			return
	call_deferred("_bind_grid_selector_to_map")


func _bind_grid_selector_to_map() -> void:
	_grid_selector_ready = false
	if _grid_selector == null:
		return
	if field_background == null:
		_apply_grid_selector_visibility()
		return
	if not field_background.has_method("get_snapping_tile_layer"):
		_apply_grid_selector_visibility()
		return
	var layer: TileMapLayer = field_background.get_snapping_tile_layer()
	if layer == null:
		push_warning("Main: no se encontró GroundLayer para el selector de celda.")
		_apply_grid_selector_visibility()
		return
	if layer.tile_set == null:
		push_warning("Main: GroundLayer sin TileSet — selector de celda desactivado.")
		_apply_grid_selector_visibility()
		return
	if _grid_selector.get_parent() != self:
		if _grid_selector.is_inside_tree():
			_grid_selector.reparent(self)
		else:
			add_child(_grid_selector)
	# Dibujo en espacio global: encima del mapa, debajo del jugador (z=0).
	_grid_selector.set_as_top_level(true)
	_grid_selector.z_as_relative = false
	var tile_px: int = 32
	if field_background.has_method("get_snapping_tile_size_px"):
		tile_px = int(field_background.get_snapping_tile_size_px())
	_grid_selector.setup(layer, tile_px)
	_grid_selector_ready = true
	_apply_grid_selector_visibility()


func _apply_grid_selector_visibility() -> void:
	if _grid_selector == null:
		return
	_grid_selector.set_selector_active(_grid_selector_ready and GraphicsSettings.show_tile_grid_selector)


func _on_graphics_settings_changed() -> void:
	_apply_grid_selector_visibility()
	if player:
		player.queue_redraw()


func _setup_wave_events() -> void:
	_wave_controller = _WaveController.new()
	_wave_controller.name = "WaveEventController"
	add_child(_wave_controller)
	_wave_controller.setup(self, Game.selected_map_id)


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
	var type_id: String = forced_type
	if type_id.is_empty():
		type_id = _EnemyCatalog.pick_random_for_time(
			Global.session_elapsed_time, Game.selected_map_id
		)
	var scene_to_spawn: PackedScene = enemy_scene
	var def: Dictionary = _EnemyCatalog.get_definition(type_id)
	var custom_scene_path: String = String(def.get("scene_path", ""))
	if not custom_scene_path.is_empty() and ResourceLoader.exists(custom_scene_path):
		scene_to_spawn = load(custom_scene_path) as PackedScene
	if scene_to_spawn == null:
		return null
	var enemy: Enemy = scene_to_spawn.instantiate() as Enemy
	if enemy == null:
		return null
	add_child(enemy)
	enemy.apply_type(type_id)
	enemy.apply_map_modifiers(
		float(_map_def.get("hp_multiplier", 1.0)),
		float(_map_def.get("damage_multiplier", 1.0))
	)
	# Orc Village (Mapa 3): x2 HP base en orcos principales para sostener el power spike del Job Change.
	if Game.selected_map_id == _MapConfig.MAP_ORC_VILLAGE:
		if type_id in ["orc_warrior", "orc_lady", "orc_archer", "high_orc"]:
			enemy.max_hp = int(round(float(enemy.max_hp) * 2.0))
			enemy.current_hp = enemy.max_hp
	enemy.xp_reward = int(round(float(enemy.xp_reward) * float(_map_def.get("xp_multiplier", 1.0))))
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


func _setup_heal_buff_spawner() -> void:
	_heal_buff_check_timer = Timer.new()
	_heal_buff_check_timer.name = "HealBuffCheckTimer"
	_heal_buff_check_timer.wait_time = HEAL_BUFF_CHECK_INTERVAL_SEC
	_heal_buff_check_timer.autostart = true
	_heal_buff_check_timer.timeout.connect(_try_spawn_heal_buff_drop)
	add_child(_heal_buff_check_timer)


func _try_spawn_heal_buff_drop() -> void:
	if _run_finished or _loot_phase_active or player == null or not is_instance_valid(player):
		return
	if not get_tree().get_nodes_in_group(HealBuffDrop.GROUP).is_empty():
		return
	if randf() >= HEAL_BUFF_SPAWN_PROBABILITY:
		return
	var drop: HealBuffDrop = _HealBuffDropScene.instantiate() as HealBuffDrop
	if drop == null:
		return
	add_child(drop)
	drop.global_position = _pick_heal_buff_spawn_position()


func _pick_heal_buff_spawn_position() -> Vector2:
	var angle: float = randf() * TAU
	var distance: float = randf_range(HEAL_BUFF_SPAWN_MIN_RADIUS, HEAL_BUFF_SPAWN_MAX_RADIUS)
	var pos: Vector2 = player.global_position + Vector2.from_angle(angle) * distance
	if Arena.is_ready():
		pos = Arena.clamp_to_playable(pos, 20.0)
	return pos


func _clear_heal_buff_drops() -> void:
	for node: Node in get_tree().get_nodes_in_group(HealBuffDrop.GROUP):
		if is_instance_valid(node):
			node.queue_free()


func debug_spawn_boss() -> void:
	if _run_finished:
		return
	_spawn_boss()


func debug_kill_boss() -> void:
	if _run_finished or _loot_phase_active:
		return
	var boss: Node = _find_live_boss()
	if boss == null and not _boss_spawned:
		_spawn_boss()
		boss = _find_live_boss()
	if boss == null or not boss.has_method("die"):
		return
	boss.call("die")


func _find_live_boss() -> Node:
	for node: Node in get_tree().get_nodes_in_group("Enemigos"):
		if not is_instance_valid(node):
			continue
		if node.has_signal("defeated"):
			return node
	return null


func _resolve_boss_scene() -> PackedScene:
	if Game.selected_map_id == _MapConfig.MAP_ORC_VILLAGE:
		return orc_hero_boss_scene
	if Game.selected_map_id == _MapConfig.MAP_PAYON:
		return moonlight_flower_boss_scene
	return creamy_boss_scene


func _spawn_boss() -> void:
	if _boss_spawned or player == null:
		return
	if game_hud and game_hud.has_method("hide_boss_warning"):
		game_hud.hide_boss_warning()
	var boss_scene: PackedScene = _resolve_boss_scene()
	if boss_scene == null:
		return
	_boss_spawned = true
	var boss: Enemy = boss_scene.instantiate() as Enemy
	if boss == null:
		return
	add_child(boss)
	boss.global_position = _pick_spawn_position()
	Global.on_boss_spawned_in_run(Game.selected_map_id)
	if boss.has_signal("defeated") and not boss.defeated.is_connected(_on_boss_defeated):
		boss.defeated.connect(_on_boss_defeated)
	if game_hud and game_hud.has_method("show_boss_health_bar"):
		game_hud.show_boss_health_bar(boss)


func _on_boss_defeated() -> void:
	if _loot_phase_active or _run_finished:
		return
	if game_hud and game_hud.has_method("hide_boss_health_bar"):
		game_hud.hide_boss_health_bar()
	_clear_all_enemies()
	spawn_timer.stop()
	if _wave_controller:
		_wave_controller.set_active(false)
	_loot_phase_active = true
	_loot_phase_timer = BOSS_LOOT_PHASE_SECONDS
	Arena.announce_wave("¡Jefe derrotado! Recolecta botín — salida en %d s" % int(BOSS_LOOT_PHASE_SECONDS))
	if game_hud and game_hud.has_method("show_map_exit_countdown"):
		game_hud.show_map_exit_countdown(_loot_phase_timer)


func _end_loot_phase() -> void:
	if not _loot_phase_active:
		return
	_loot_phase_active = false
	if game_hud and game_hud.has_method("hide_map_exit_countdown"):
		game_hud.hide_map_exit_countdown()
	if _should_show_job_change_menu():
		_show_job_change_menu()
		return
	_finish_run(true)


func _should_show_job_change_menu() -> bool:
	return Game.selected_map_id == _MapConfig.MAP_PAYON and Global.needs_campaign_job_change()


func _show_job_change_menu() -> void:
	if job_change_menu and job_change_menu.has_method("show_menu"):
		job_change_menu.show_menu()


func _on_job_change_completed(_job_id: String) -> void:
	if player and player.has_method("sync_from_skill_tree"):
		player.sync_from_skill_tree()
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
	if victory:
		Global.on_map_cleared(Game.selected_map_id)
	if _grid_selector:
		_grid_selector.set_selector_active(false)
	_loot_phase_active = false
	if game_hud and game_hud.has_method("hide_map_exit_countdown"):
		game_hud.hide_map_exit_countdown()
	_record_scoreboard_entry(victory)
	hide_wall_wave_warning()
	if game_hud and game_hud.has_method("hide_boss_health_bar"):
		game_hud.hide_boss_health_bar()
	_run_finished = true
	spawn_timer.stop()
	if _heal_buff_check_timer:
		_heal_buff_check_timer.stop()
	_clear_heal_buff_drops()
	if _wave_controller:
		_wave_controller.set_active(false)
	var pause_menu: CanvasLayer = get_node_or_null("PauseMenu") as CanvasLayer
	if pause_menu and pause_menu.has_method("close_pause_menu"):
		pause_menu.close_pause_menu()
	Audio.stop_bgm()
	Game.end_run(victory, Global.run_zeny)
	if run_result_ui and run_result_ui.has_method("show_result"):
		run_result_ui.show_result(victory, Global.run_zeny)


func _record_scoreboard_entry(victory: bool) -> void:
	_Scoreboard.record_run(
		Global.session_elapsed_time,
		Game.selected_map_id,
		String(_map_def.get("display_name", Game.selected_map_id)),
		victory,
		Global.run_zeny,
		Game.selected_class_id
	)
