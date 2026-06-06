## Control hermético de pausa durante overlays de menú/kit (ref-count).
class_name RunPauseGuard
extends RefCounted

static var _lock_count: int = 0


static func lock_pause(tree: SceneTree) -> void:
	if tree == null:
		return
	_lock_count += 1
	tree.paused = true


static func unlock_pause(tree: SceneTree) -> void:
	if tree == null:
		return
	_lock_count = maxi(_lock_count - 1, 0)
	if _lock_count <= 0:
		tree.paused = false


static func force_unlock(tree: SceneTree) -> void:
	if tree == null:
		return
	_lock_count = 0
	tree.paused = false


static func is_locked() -> bool:
	return _lock_count > 0


static func ensure_paused(tree: SceneTree) -> void:
	if tree == null:
		return
	tree.paused = true
