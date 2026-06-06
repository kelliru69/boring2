## Límite de proyectiles del jugador — evita acumulación en combate intenso.
extends RefCounted
class_name PlayerProjectileRegistry

const GROUP: StringName = &"player_projectiles"
const MAX_ACTIVE: int = 24

static var _spawn_order: Array[int] = []


static func track(projectile: Node) -> void:
	if projectile == null:
		return
	if not projectile.is_in_group(GROUP):
		projectile.add_to_group(GROUP)
	var id: int = projectile.get_instance_id()
	if not _spawn_order.has(id):
		_spawn_order.append(id)
	if not projectile.tree_exiting.is_connected(_on_tree_exiting):
		projectile.tree_exiting.connect(_on_tree_exiting.bind(id))
	_evict_if_over_limit()


static func _on_tree_exiting(id: int) -> void:
	_spawn_order.erase(id)


static func _evict_if_over_limit() -> void:
	while _spawn_order.size() > MAX_ACTIVE:
		var oldest_id: int = _spawn_order[0]
		_spawn_order.remove_at(0)
		var node: Node = instance_from_id(oldest_id)
		if node == null or not is_instance_valid(node):
			continue
		if node.has_method("force_despawn"):
			node.force_despawn()
		elif node.has_method("queue_free"):
			node.queue_free()


static func active_count() -> int:
	return _spawn_order.size()
