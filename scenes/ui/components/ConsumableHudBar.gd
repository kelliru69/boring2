## Barra compacta de consumibles asignados a teclas 1–9.
class_name ConsumableHudBar
extends HBoxContainer

const _Consumables = preload("res://scripts/inventory/consumable_inventory.gd")
const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")

var _slot_labels: Array[Label] = []


func _ready() -> void:
	add_theme_constant_override("separation", 4)
	if not Global.consumables_changed.is_connected(_refresh):
		Global.consumables_changed.connect(_refresh)
	_build_slots()
	_refresh()


func _build_slots() -> void:
	for child: Node in get_children():
		child.queue_free()
	_slot_labels.clear()
	for i: int in range(1, 10):
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(34, 34)
		slot.add_theme_stylebox_override(&"panel", _Theme.make_panel_style(_Theme.CARD_FILL, _Theme.PANEL_BORDER, 6, false))
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 2)
		margin.add_theme_constant_override("margin_top", 2)
		margin.add_theme_constant_override("margin_right", 2)
		margin.add_theme_constant_override("margin_bottom", 2)
		slot.add_child(margin)
		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		margin.add_child(vbox)
		var key_lbl := Label.new()
		key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_lbl.add_theme_font_size_override(&"font_size", 9)
		key_lbl.text = str(i)
		var count_lbl := Label.new()
		count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count_lbl.add_theme_font_size_override(&"font_size", 10)
		count_lbl.add_theme_color_override(&"font_color", Color(0.85, 0.92, 1.0, 1.0))
		vbox.add_child(key_lbl)
		vbox.add_child(count_lbl)
		add_child(slot)
		_slot_labels.append(count_lbl)


func _refresh() -> void:
	for i: int in range(1, 10):
		var lbl: Label = _slot_labels[i - 1]
		var item_id: String = _Consumables.get_hotkey_item(i)
		if item_id.is_empty():
			lbl.text = "—"
			lbl.modulate = Color(0.55, 0.58, 0.62, 0.7)
			continue
		var count: int = _Consumables.get_count(item_id)
		lbl.text = str(count) if count > 0 else "0"
		lbl.modulate = Color.WHITE if count > 0 else Color(0.7, 0.35, 0.35, 1.0)
