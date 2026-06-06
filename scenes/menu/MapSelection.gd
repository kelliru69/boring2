## Selector de mapa / etapa antes de iniciar la run.
extends Control

const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")
const _MapCatalog = preload("res://data/menu_map_catalog.gd")
const _MapConfig = preload("res://data/map_config.gd")
const _CardScene: PackedScene = preload("res://scenes/ui/components/MapSelectCard.tscn")
const BACKGROUND_PATH: String = "res://art/background.png"
const _MenuEsc = preload("res://scripts/ui/menu_esc_handler.gd")

@onready var background: TextureRect = $Background
@onready var title_label: Label = $RootMargin/RootVBox/Header/TitleLabel
@onready var cards_row: HBoxContainer = $RootMargin/RootVBox/CardsRow
@onready var back_button: Button = $RootMargin/RootVBox/Footer/BackButton
@onready var start_button: Button = $RootMargin/RootVBox/Footer/StartButton

var _selected_map_id: String = _MapConfig.MAP_PRONTERA
var _map_cards: Dictionary = {}


func _ready() -> void:
	if ResourceLoader.exists(BACKGROUND_PATH):
		background.texture = load(BACKGROUND_PATH) as Texture2D
	_Theme.style_title(title_label, 26)
	title_label.text = "Selecciona el mapa"
	_Theme.apply_button(back_button, 44.0)
	_Theme.apply_cta_button(start_button, 52.0)
	start_button.text = "¡COMENZAR PARTIDA!"
	back_button.pressed.connect(_on_back_pressed)
	start_button.pressed.connect(_on_start_pressed)
	Global.profile_loaded.connect(_refresh_cards)
	_build_cards()
	_select_map(_selected_map_id)


func _build_cards() -> void:
	for child: Node in cards_row.get_children():
		child.queue_free()
	_map_cards.clear()
	for entry: Dictionary in _MapCatalog.get_all_entries():
		var map_id: String = String(entry.get("id", ""))
		var card: MapSelectCard = _CardScene.instantiate() as MapSelectCard
		cards_row.add_child(card)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var unlocked: bool = Global.is_map_unlocked(map_id)
		var boss_known: bool = Global.is_boss_discovered_for_map(map_id)
		card.setup(entry, unlocked, boss_known)
		_map_cards[map_id] = card
		if card.has_signal("map_selected"):
			card.map_selected.connect(_select_map)


func _refresh_cards() -> void:
	for map_id: String in _map_cards:
		var card: MapSelectCard = _map_cards[map_id] as MapSelectCard
		if card == null:
			continue
		var entry: Dictionary = _MapCatalog.get_entry(map_id)
		if entry.is_empty():
			continue
		card.setup(entry, Global.is_map_unlocked(map_id), Global.is_boss_discovered_for_map(map_id))
	_select_map(_selected_map_id)


func _select_map(map_id: String) -> void:
	if not Global.is_map_unlocked(map_id):
		return
	_selected_map_id = map_id
	Game.selected_map_id = map_id
	for id: String in _map_cards:
		var card: MapSelectCard = _map_cards[id] as MapSelectCard
		if card:
			card.set_selected(id == map_id)
	start_button.disabled = false


func _unhandled_input(event: InputEvent) -> void:
	if _MenuEsc.is_back_pressed(event):
		_on_back_pressed()
		_MenuEsc.mark_input_handled(self)


func _on_back_pressed() -> void:
	Audio.play_ui_click()
	Game.go_to_preparation()


func _on_start_pressed() -> void:
	if not Global.is_map_unlocked(_selected_map_id):
		return
	Audio.play_ui_click()
	Game.selected_map_id = _selected_map_id
	Game.start_new_run()


func _exit_tree() -> void:
	if Global.profile_loaded.is_connected(_refresh_cards):
		Global.profile_loaded.disconnect(_refresh_cards)
