## Subpanel de remapeo de teclas (habilidades + consumibles 1–9).
class_name ControlsRemapPanel
extends VBoxContainer

const _Remap = preload("res://scripts/input/skill_input_remap.gd")
const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")

var _waiting_action: String = ""
var _rows: Dictionary = {}


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	_build_rows()


func _build_rows() -> void:
	for child: Node in get_children():
		child.queue_free()
	_rows.clear()
	var title := Label.new()
	title.text = "Controles — clic en Reasignar y pulsa la nueva tecla"
	_Theme.style_subtitle(title, 12)
	add_child(title)
	for action: String in _Remap.get_rebindable_actions():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var label := Label.new()
		label.text = _action_label(action)
		label.custom_minimum_size.x = 140.0
		_Theme.style_body(label, 13)
		var value := Label.new()
		value.text = _current_binding_text(action)
		value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_Theme.style_accent(value, 12)
		var btn := Button.new()
		btn.text = "Reasignar"
		_Theme.apply_button(btn, 32.0)
		btn.pressed.connect(_start_rebind.bind(action, value))
		row.add_child(label)
		row.add_child(value)
		row.add_child(btn)
		add_child(row)
		_rows[action] = value


func _action_label(action: String) -> String:
	if action.begins_with("consumable_"):
		return "Consumible %s" % action.trim_prefix("consumable_")
	return _Remap.get_action_display_name(action)


func _current_binding_text(action: String) -> String:
	if not InputMap.has_action(action):
		return "(sin asignar)"
	var events: Array[InputEvent] = InputMap.action_get_events(action)
	if events.is_empty():
		return "(sin asignar)"
	var ev: InputEvent = events[0]
	if ev is InputEventKey:
		return (ev as InputEventKey).as_text_physical_keycode()
	if ev is InputEventMouseButton:
		var mb: InputEventMouseButton = ev as InputEventMouseButton
		return "Mouse %d" % mb.button_index
	return ev.as_text()


func _start_rebind(action: String, value_label: Label) -> void:
	_waiting_action = action
	value_label.text = "Pulsa una tecla…"
	set_process_unhandled_input(true)


func _unhandled_input(event: InputEvent) -> void:
	if _waiting_action.is_empty():
		return
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		_Remap.rebind_action(_waiting_action, event.duplicate())
		_waiting_action = ""
		set_process_unhandled_input(false)
		_refresh_values()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_Remap.rebind_action(_waiting_action, event.duplicate())
		_waiting_action = ""
		set_process_unhandled_input(false)
		_refresh_values()
		get_viewport().set_input_as_handled()


func _refresh_values() -> void:
	for action: String in _rows:
		var lbl: Label = _rows[action] as Label
		if lbl:
			lbl.text = _current_binding_text(action)
