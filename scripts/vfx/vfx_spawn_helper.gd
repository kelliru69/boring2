## Utilidad de spawn — evita 1 frame en (0,0) (centro del arena tilemap).
extends RefCounted
class_name VfxSpawnHelper


static func add_child_at_world(parent: Node, node: Node, world_pos: Vector2) -> void:
	if parent == null or node == null:
		return
	var was_visible: bool = true
	if node is CanvasItem:
		was_visible = (node as CanvasItem).visible
		(node as CanvasItem).visible = false
	parent.add_child(node)
	if node is Node2D:
		(node as Node2D).global_position = world_pos
	if node is CanvasItem:
		(node as CanvasItem).visible = was_visible
	if node.has_method("on_spawned_at_world"):
		node.call_deferred("on_spawned_at_world", world_pos)


static func instantiate_at(parent: Node, scene: PackedScene, world_pos: Vector2) -> Node:
	if parent == null or scene == null:
		return null
	var node: Node = scene.instantiate()
	if node == null:
		return null
	add_child_at_world(parent, node, world_pos)
	return node
