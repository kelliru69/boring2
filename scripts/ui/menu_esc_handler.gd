## Detección de ESC / ui_cancel para navegación «atrás» en menús.
class_name MenuEscHandler
extends RefCounted


static func is_back_pressed(event: InputEvent) -> bool:
	if event.is_echo():
		return false
	if event.is_action_pressed("ui_cancel"):
		return true
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		return key_event.pressed and key_event.keycode == KEY_ESCAPE
	return false


static func mark_input_handled(from_node: Node) -> void:
	if from_node == null or not from_node.is_inside_tree():
		return
	var viewport: Viewport = from_node.get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()
