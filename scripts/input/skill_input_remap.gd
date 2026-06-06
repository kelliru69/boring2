## Persistencia de remapeo de InputMap para habilidades activas y consumibles.
class_name SkillInputRemap
extends RefCounted

const SETTINGS_PATH: String = "user://input_bindings.cfg"

## action_name → [ {type, ...} ] serializable
static func get_rebindable_actions() -> Array[String]:
	var actions: Array[String] = []
	for slot_id: String in SkillTreeCatalog.ALL_SLOT_IDS:
		var action: String = String(SkillDefinitions.SLOT_TO_INPUT.get(slot_id, ""))
		if not action.is_empty() and not actions.has(action):
			actions.append(action)
	for i: int in range(1, 10):
		actions.append("consumable_%d" % i)
	return actions


static func save_bindings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	for action: String in get_rebindable_actions():
		if not InputMap.has_action(action):
			continue
		var events: Array = []
		for event: InputEvent in InputMap.action_get_events(action):
			events.append(_serialize_event(event))
		cfg.set_value("bindings", action, events)
	cfg.save(SETTINGS_PATH)


static func load_bindings() -> void:
	_ensure_default_actions()
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	for action: String in get_rebindable_actions():
		if not cfg.has_section_key("bindings", action):
			continue
		var raw: Variant = cfg.get_value("bindings", action)
		if raw is Array:
			_apply_events(action, raw as Array)


static func rebind_action(action: String, event: InputEvent) -> void:
	if action.is_empty() or event == null:
		return
	_ensure_default_actions()
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event.duplicate())
	save_bindings()


static func get_action_display_name(action: String) -> String:
	if action == SkillDefinitions.INPUT_SPACE:
		return "Espacio"
	if action.begins_with("consumable_"):
		return "Tecla %s" % action.trim_prefix("consumable_")
	if action == "skill_q":
		return "Q"
	if action == "skill_e":
		return "E"
	return action


static func _ensure_default_actions() -> void:
	for slot_id: String in SkillTreeCatalog.ALL_SLOT_IDS:
		var action: String = String(SkillDefinitions.SLOT_TO_INPUT.get(slot_id, ""))
		if action.is_empty():
			continue
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	for i: int in range(1, 10):
		var action: String = "consumable_%d" % i
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		if InputMap.action_get_events(action).is_empty():
			var key_ev := InputEventKey.new()
			key_ev.keycode = KEY_0 + i if i < 10 else KEY_0
			if i == 10:
				key_ev.keycode = KEY_0
			else:
				key_ev.keycode = KEY_1 + (i - 1)
			InputMap.action_add_event(action, key_ev)


static func _serialize_event(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		var key_ev: InputEventKey = event as InputEventKey
		return {"type": "key", "keycode": key_ev.physical_keycode}
	if event is InputEventMouseButton:
		var mouse_ev: InputEventMouseButton = event as InputEventMouseButton
		return {"type": "mouse", "button": mouse_ev.button_index}
	return {}


static func _apply_events(action: String, serialized: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	for entry: Variant in serialized:
		if entry is Dictionary:
			var ev: InputEvent = _deserialize_event(entry as Dictionary)
			if ev:
				InputMap.action_add_event(action, ev)


static func _deserialize_event(data: Dictionary) -> InputEvent:
	match String(data.get("type", "")):
		"key":
			var ev := InputEventKey.new()
			ev.physical_keycode = int(data.get("keycode", 0)) as Key
			return ev
		"mouse":
			var ev := InputEventMouseButton.new()
			ev.button_index = int(data.get("button", 0))
			return ev
		_:
			return null
