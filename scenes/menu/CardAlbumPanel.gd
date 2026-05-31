## Álbum de coleccionista: cuadrícula + detalle (efectos a la izquierda, arte a la derecha).
extends Control

const _CardStats = preload("res://data/card_stats.gd")
const _Catalog = preload("res://data/card_catalog.gd")
const _Visuals = preload("res://data/card_visual_catalog.gd")
const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")
const _EntryScene: PackedScene = preload("res://scenes/ui/components/CardGridEntry.tscn")

@onready var card_grid: GridContainer = $Margin/VBox/Body/GridScroll/CardGrid
@onready var inspect_panel: PanelContainer = $Margin/VBox/Body/InspectPanel
@onready var inspect_art: TextureRect = $Margin/VBox/Body/InspectPanel/InspectMargin/InspectHBox/ArtColumn/InspectArt
@onready var inspect_name: Label = $Margin/VBox/Body/InspectPanel/InspectMargin/InspectHBox/DetailsColumn/InspectName
@onready var inspect_subtitle: Label = $Margin/VBox/Body/InspectPanel/InspectMargin/InspectHBox/DetailsColumn/InspectSubtitle
@onready var inspect_effect: Label = $Margin/VBox/Body/InspectPanel/InspectMargin/InspectHBox/DetailsColumn/InspectEffect
@onready var inspect_lore: Label = $Margin/VBox/Body/InspectPanel/InspectMargin/InspectHBox/DetailsColumn/InspectLore
@onready var equip_hint: Label = $Margin/VBox/Body/InspectPanel/InspectMargin/InspectHBox/DetailsColumn/EquipHint
@onready var equip_hint_top: Label = $Margin/VBox/EquipHintTop
@onready var equip_button: Button = $Margin/VBox/Body/InspectPanel/InspectMargin/InspectHBox/DetailsColumn/EquipButton
@onready var slots_label: Label = $Margin/VBox/SlotsLabel
@onready var album_label: Label = $Margin/VBox/AlbumLabel
@onready var slot_buttons: Array[Button] = [
	$Margin/VBox/SlotsRow/Slot0,
	$Margin/VBox/SlotsRow/Slot1,
	$Margin/VBox/SlotsRow/Slot2,
	$Margin/VBox/SlotsRow/Slot3,
	$Margin/VBox/SlotsRow/Slot4,
]

var _inspected_card_id: String = ""
var _active_slot: int = -1
var _awaiting_slot_replace: bool = false


func _ready() -> void:
	visible = false
	_Theme.apply_panel(inspect_panel)
	_Theme.style_title(slots_label, 15)
	_Theme.style_title(album_label, 15)
	_Theme.style_title(inspect_name, 18)
	_Theme.style_subtitle(inspect_subtitle, 11)
	_Theme.style_accent(inspect_effect, 13)
	_Theme.style_body(inspect_lore, 12)
	_Theme.style_subtitle(equip_hint, 11)
	_Theme.style_subtitle(equip_hint_top, 11)
	_Theme.apply_button(equip_button, 40.0)
	for btn: Button in slot_buttons:
		_Theme.apply_button(btn, 40.0)
		btn.toggled.connect(_on_slot_toggled.bind(btn))
	equip_button.pressed.connect(_on_equip_pressed)
	Global.equipped_cards_changed.connect(_refresh)
	Global.card_collected.connect(func(_id, _d): _refresh())


func show_panel() -> void:
	visible = true
	_refresh()


func hide_panel() -> void:
	visible = false
	_inspected_card_id = ""
	_active_slot = -1
	_awaiting_slot_replace = false
	inspect_panel.visible = false


func _on_slot_toggled(toggled_on: bool, button: Button) -> void:
	var slot_index: int = slot_buttons.find(button)
	if slot_index < 0:
		return
	if not toggled_on:
		if _active_slot == slot_index:
			_active_slot = -1
		_update_equip_hint()
		return
	Audio.play_ui_click()
	for i: int in slot_buttons.size():
		if i != slot_index:
			slot_buttons[i].set_pressed_no_signal(false)
	_active_slot = slot_index
	if not _inspected_card_id.is_empty():
		_equip_to_slot(slot_index)
		_refresh()
		return
	var current: String = _slot_card_id(slot_index)
	if current != "":
		Global.clear_equipped_slot(slot_index)
		_active_slot = -1
		button.set_pressed_no_signal(false)
	_refresh()


func _equip_to_slot(slot_index: int) -> void:
	if _inspected_card_id.is_empty():
		return
	if Global.is_card_equipped(_inspected_card_id) and Global.get_equipped_slot_for(_inspected_card_id) == slot_index:
		return
	Global.set_equipped_card(slot_index, _inspected_card_id)
	_awaiting_slot_replace = false
	_active_slot = -1
	for btn: Button in slot_buttons:
		btn.set_pressed_no_signal(false)


func _on_equip_pressed() -> void:
	if _inspected_card_id.is_empty():
		return
	if Global.is_card_equipped(_inspected_card_id):
		return
	Audio.play_ui_click()
	if _active_slot >= 0:
		_equip_to_slot(_active_slot)
		_refresh()
		return
	var empty_slot: int = _first_empty_slot()
	if empty_slot >= 0:
		_equip_to_slot(empty_slot)
		_refresh()
		return
	_awaiting_slot_replace = true
	_update_equip_hint()
	_refresh()


func _on_card_clicked(card_id: String) -> void:
	if not Global.unlocked_cards.has(card_id):
		return
	Audio.play_ui_click()
	_inspected_card_id = card_id
	_awaiting_slot_replace = false
	_show_inspection(card_id)
	_highlight_grid_selection(card_id)


func _show_inspection(card_id: String) -> void:
	var def: Dictionary = _Catalog.get_definition(card_id)
	var saved: Dictionary = Global.unlocked_cards.get(card_id, {})
	inspect_panel.visible = true
	inspect_name.text = String(saved.get("name", def.get("name", card_id)))
	inspect_subtitle.text = String(def.get("subtitle", ""))
	inspect_effect.text = _CardStats.get_effect_description(card_id)
	inspect_lore.text = String(def.get("lore", ""))
	var tex: Texture2D = _Visuals.load_texture(card_id)
	inspect_art.texture = tex
	inspect_art.modulate = Color.WHITE if tex else Color(0.35, 0.55, 0.85, 0.35)
	if Global.is_card_equipped(card_id):
		equip_button.text = "Equipada (ranura %d)" % (Global.get_equipped_slot_for(card_id) + 1)
		equip_button.disabled = true
	else:
		equip_button.text = "Equipar carta"
		equip_button.disabled = false
	_update_equip_hint()


func _refresh() -> void:
	_update_slot_buttons()
	_rebuild_grid()
	if _inspected_card_id != "" and Global.unlocked_cards.has(_inspected_card_id):
		_show_inspection(_inspected_card_id)
		_highlight_grid_selection(_inspected_card_id)
	elif inspect_panel.visible:
		inspect_panel.visible = false


func _update_slot_buttons() -> void:
	for i: int in slot_buttons.size():
		var id: String = _slot_card_id(i)
		var prefix: String = "▸ " if i == _active_slot else ""
		if id == "":
			slot_buttons[i].text = "%sRanura %d" % [prefix, i + 1]
		else:
			var card_name: String = String(Global.unlocked_cards.get(id, {}).get("name", id))
			slot_buttons[i].text = "%s%d · %s" % [prefix, i + 1, card_name]
		slot_buttons[i].set_pressed_no_signal(i == _active_slot)


func _rebuild_grid() -> void:
	for child: Node in card_grid.get_children():
		child.queue_free()
	for card_id: String in _Catalog.ALL_CARD_IDS:
		var discovered: bool = Global.unlocked_cards.has(card_id)
		var def: Dictionary = _Catalog.get_definition(card_id)
		var entry: PanelContainer = _EntryScene.instantiate() as PanelContainer
		card_grid.add_child(entry)
		entry.setup(card_id, String(def.get("name", card_id)), discovered)
		entry.card_clicked.connect(_on_card_clicked)


func _highlight_grid_selection(card_id: String) -> void:
	for child: Node in card_grid.get_children():
		if child.has_method("set_selected") and child.has_method("get_card_id"):
			child.set_selected(child.get_card_id() == card_id)


func _first_empty_slot() -> int:
	for i: int in slot_buttons.size():
		if _slot_card_id(i).is_empty():
			return i
	return -1


func _slot_card_id(slot_index: int) -> String:
	if slot_index < 0 or slot_index >= Global.equipped_cards.size():
		return ""
	return String(Global.equipped_cards[slot_index])


func _update_equip_hint() -> void:
	if _inspected_card_id.is_empty():
		equip_hint.text = "Pulsa una carta desbloqueada para ver sus efectos."
		return
	if Global.is_card_equipped(_inspected_card_id):
		equip_hint.text = "Esta carta ya está equipada."
		return
	if _awaiting_slot_replace:
		equip_hint.text = "Todas las ranuras están llenas. Pulsa una ranura para reemplazar su carta."
	elif _active_slot >= 0:
		equip_hint.text = "Ranura %d seleccionada. Pulsa Equipar o la misma ranura para confirmar." % (_active_slot + 1)
	else:
		equip_hint.text = "Pulsa Equipar (ranura libre) o selecciona una ranura arriba."
