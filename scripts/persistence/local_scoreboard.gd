## Top 10 local: persiste en user://scoreboard.json (tiempo de supervivencia + mapa).
class_name LocalScoreboard
extends RefCounted

const SAVE_PATH: String = "user://scoreboard.json"
const MAX_ENTRIES: int = 10

const _MapConfig = preload("res://data/map_config.gd")


static func record_run(
	survival_seconds: float,
	map_id: String,
	map_display_name: String,
	victory: bool,
	run_zeny: int,
	class_id: String,
	player_name: String = "Aventurero"
) -> void:
	var entries: Array = _load_entries()
	var entry: Dictionary = {
		"player_name": player_name,
		"survival_seconds": maxf(survival_seconds, 0.0),
		"map_id": map_id,
		"map_name": map_display_name,
		"victory": victory,
		"zeny": run_zeny,
		"class_id": class_id,
		"recorded_at_unix": Time.get_unix_time_from_system(),
	}
	entries.append(entry)
	entries.sort_custom(_compare_entries)
	while entries.size() > MAX_ENTRIES:
		entries.pop_back()
	_save_entries(entries)


static func get_top_entries() -> Array[Dictionary]:
	var raw: Array = _load_entries()
	raw.sort_custom(_compare_entries)
	var out: Array[Dictionary] = []
	var limit: int = mini(raw.size(), MAX_ENTRIES)
	for i: int in limit:
		if raw[i] is Dictionary:
			out.append(raw[i] as Dictionary)
	return out


static func format_time(seconds: float) -> String:
	var total: int = maxi(int(seconds), 0)
	return "%02d:%02d" % [int(total / 60.0), total % 60]


static func format_hp_number(value: int) -> String:
	var negative: bool = value < 0
	var digits: String = str(absi(value))
	var parts: PackedStringArray = []
	while digits.length() > 3:
		parts.insert(0, digits.substr(digits.length() - 3, 3))
		digits = digits.substr(0, digits.length() - 3)
	if not digits.is_empty():
		parts.insert(0, digits)
	var body: String = ",".join(parts)
	return ("-" if negative else "") + body


static func _compare_entries(a: Variant, b: Variant) -> bool:
	return _sort_key(a as Dictionary) > _sort_key(b as Dictionary)


static func _sort_key(entry: Dictionary) -> int:
	var seconds: int = int(entry.get("survival_seconds", 0.0))
	var map_tier: int = 1 if String(entry.get("map_id", "")) == _MapConfig.MAP_PAYON else 0
	var victory_bonus: int = 60 if bool(entry.get("victory", false)) else 0
	return map_tier * 1_000_000 + seconds * 10 + victory_bonus


static func _load_entries() -> Array:
	if not FileAccess.file_exists(SAVE_PATH):
		return []
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Array:
		return parsed.duplicate()
	return []


static func _save_entries(entries: Array) -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("LocalScoreboard: no se pudo escribir %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(entries, "\t"))
