## Red de seguridad VFX — solo corta spawns en picos extremos (no regula calidad base).
extends RefCounted
class_name CombatVfxBudget

const BURST_WINDOW_MS: int = 100
const MAX_BURSTS_PER_WINDOW: int = 16

const FLASH_WINDOW_MS: int = 1000
const MAX_FLASHES_PER_SEC: int = 22
const FLASH_DEDUP_RADIUS_SQ: float = 28.0 * 28.0
const FLASH_DEDUP_MS: int = 40

const ZAP_WINDOW_MS: int = 80
const MAX_ZAPS_PER_WINDOW: int = 6

const VFX_PARTICLES_GROUP: StringName = &"vfx_particles"
const MAX_ACTIVE_PARTICLE_NODES: int = 64

static var _burst_window_start_ms: int = 0
static var _burst_count: int = 0

static var _flash_window_start_ms: int = 0
static var _flash_count: int = 0
static var _recent_flashes: Array[Dictionary] = []

static var _zap_window_start_ms: int = 0
static var _zap_count: int = 0


static func allow_trail() -> bool:
	return _active_particle_count() < MAX_ACTIVE_PARTICLE_NODES


static func allow_burst() -> bool:
	if _active_particle_count() >= MAX_ACTIVE_PARTICLE_NODES:
		return false
	var now_ms: int = Time.get_ticks_msec()
	if now_ms - _burst_window_start_ms > BURST_WINDOW_MS:
		_burst_window_start_ms = now_ms
		_burst_count = 0
	if _burst_count >= MAX_BURSTS_PER_WINDOW:
		return false
	_burst_count += 1
	return true


static func allow_impact_flash(world_pos: Vector2) -> bool:
	var now_ms: int = Time.get_ticks_msec()
	if now_ms - _flash_window_start_ms > FLASH_WINDOW_MS:
		_flash_window_start_ms = now_ms
		_flash_count = 0
	if _flash_count >= MAX_FLASHES_PER_SEC:
		return false
	_prune_recent_flashes(now_ms)
	for entry: Dictionary in _recent_flashes:
		var pos: Vector2 = entry.get("pos", Vector2.ZERO)
		if pos.distance_squared_to(world_pos) <= FLASH_DEDUP_RADIUS_SQ:
			return false
	_recent_flashes.append({"pos": world_pos, "t": now_ms})
	_flash_count += 1
	return true


static func allow_lightning_zap() -> bool:
	var now_ms: int = Time.get_ticks_msec()
	if now_ms - _zap_window_start_ms > ZAP_WINDOW_MS:
		_zap_window_start_ms = now_ms
		_zap_count = 0
	if _zap_count >= MAX_ZAPS_PER_WINDOW:
		return false
	_zap_count += 1
	return true


static func _prune_recent_flashes(now_ms: int) -> void:
	var kept: Array[Dictionary] = []
	for entry: Dictionary in _recent_flashes:
		if now_ms - int(entry.get("t", 0)) <= FLASH_DEDUP_MS:
			kept.append(entry)
	_recent_flashes = kept


static func _active_particle_count() -> int:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return 0
	return tree.get_node_count_in_group(VFX_PARTICLES_GROUP)
