## Inventario de consumibles de run + asignación a teclas 1–9.
class_name ConsumableInventory
extends RefCounted

## Añade icon_path por ítem para el HUD.
const ITEM_ICONS: Dictionary = {
	"heal_potion": "res://art/ui/potion_heal.png",
	"speed_tonic": "res://art/ui/potion_speed.png",
}

const ITEM_LABELS: Dictionary = {
	"heal_potion": "Poción HP",
	"speed_tonic": "Tónico Vel.",
}


static func add_item(item_id: String, amount: int = 1) -> void:
	if item_id.is_empty() or amount <= 0:
		return
	Global.run_consumables[item_id] = int(Global.run_consumables.get(item_id, 0)) + amount
	Global.consumables_changed.emit()


static func get_count(item_id: String) -> int:
	return int(Global.run_consumables.get(item_id, 0))


static func assign_hotkey(slot_index: int, item_id: String) -> void:
	if slot_index < 1 or slot_index > 9:
		return
	var key: String = str(slot_index)
	if item_id.is_empty():
		Global.consumable_hotkeys.erase(key)
	else:
		Global.consumable_hotkeys[key] = item_id
	Global.consumables_changed.emit()


static func get_hotkey_item(slot_index: int) -> String:
	return String(Global.consumable_hotkeys.get(str(slot_index), ""))


static func try_use_hotkey(slot_index: int, player: Player) -> bool:
	if player == null or slot_index < 1 or slot_index > 9:
		return false
	var item_id: String = get_hotkey_item(slot_index)
	if item_id.is_empty() or get_count(item_id) <= 0:
		return false
	match item_id:
		"heal_potion":
			if player.has_method("heal"):
				var heal_amt: int = maxi(int(player.max_hp * 0.25), 8)
				player.heal(heal_amt)
		"speed_tonic":
			if player.has_method("apply_speed_buff"):
				player.apply_speed_buff(4.0, 0.35)
		_:
			return false
	Global.run_consumables[item_id] = get_count(item_id) - 1
	if get_count(item_id) <= 0:
		Global.run_consumables.erase(item_id)
	Global.consumables_changed.emit()
	return true


static func get_item_icon(item_id: String) -> Texture2D:
	var path: String = String(ITEM_ICONS.get(item_id, ""))
	if path != "" and ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null
