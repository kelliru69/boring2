## Número de daño flotante estilo RO (amarillo/blanco, sube y desvanece).
class_name DamageNumber
extends Node2D

const SCENE_PATH: String = "res://scenes/ui/DamageNumber.tscn"
const MAX_ACTIVE: int = 28

static var _packed_scene: PackedScene
static var _active_count: int = 0

@onready var label: Label = $Label


static func spawn(world_pos: Vector2, amount: int, parent: Node, color: Color = Color(1.0, 0.95, 0.55)) -> void:
	if parent == null or amount <= 0 or _active_count >= MAX_ACTIVE:
		return
	if _packed_scene == null:
		if not ResourceLoader.exists(SCENE_PATH):
			return
		_packed_scene = load(SCENE_PATH) as PackedScene
		if _packed_scene == null:
			return
	var node: DamageNumber = _packed_scene.instantiate() as DamageNumber
	if node == null:
		return
	_active_count += 1
	parent.add_child(node)
	node.global_position = world_pos + Vector2(randf_range(-8.0, 8.0), -12.0)
	node.show_damage(amount, color)


func _exit_tree() -> void:
	_active_count = maxi(_active_count - 1, 0)


func show_damage(amount: int, color: Color = Color(1.0, 0.95, 0.55)) -> void:
	if label:
		label.text = str(amount)
		label.modulate = color
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 28.0, 0.55).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.55).set_delay(0.15)
	tween.chain().tween_callback(queue_free)
