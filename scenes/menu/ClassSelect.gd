## Pantalla 2 — Selección de clase con scroll animado e ilustración de fondo.
extends Control

const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")
const _MenuEsc = preload("res://scripts/ui/menu_esc_handler.gd")
const _MapConfig = preload("res://data/map_config.gd")
const _ClassCatalog = preload("res://data/class_select_catalog.gd")
const _CardScene: PackedScene = preload("res://scenes/menu/components/ClassScrollCard.tscn")
const BACKGROUND_PATH: String = "res://art/background.png"

@onready var background: TextureRect = $Background
@onready var class_bg: TextureRect = $ClassBackground
@onready var class_bg_fade: ColorRect = $ClassBackgroundFade
@onready var title_label: Label = $RootMargin/RootVBox/TitleLabel
@onready var character_label: Label = $RootMargin/RootVBox/CharacterLabel
@onready var scroll: ScrollContainer = $RootMargin/RootVBox/ScrollRow/Scroll
@onready var cards_row: HBoxContainer = $RootMargin/RootVBox/ScrollRow/Scroll/CardsRow
@onready var description_panel: PanelContainer = $RootMargin/RootVBox/DescriptionPanel
@onready var class_name_label: Label = $RootMargin/RootVBox/DescriptionPanel/Margin/DescVBox/ClassNameLabel
@onready var description_label: Label = $RootMargin/RootVBox/DescriptionPanel/Margin/DescVBox/DescriptionLabel
@onready var lock_label: Label = $RootMargin/RootVBox/DescriptionPanel/Margin/DescVBox/LockLabel
@onready var back_button: Button = $RootMargin/RootVBox/Footer/BackButton
@onready var confirm_button: Button = $RootMargin/RootVBox/Footer/ConfirmButton

var _character: CharacterData = null
var _classes: Array[ClassData] = []
var _cards: Array[ClassScrollCard] = []
var _selected_index: int = 0
var _bg_tween: Tween = null


func _ready() -> void:
	if ResourceLoader.exists(BACKGROUND_PATH):
		background.texture = load(BACKGROUND_PATH) as Texture2D
	class_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_Theme.apply_panel(description_panel)
	_Theme.style_title(title_label, 28)
	title_label.text = "ELIGE TU CLASE"
	_Theme.style_accent(character_label, 14)
	_Theme.style_title(class_name_label, 24)
	_Theme.style_body(description_label, 14)
	_Theme.style_subtitle(lock_label, 12)
	lock_label.add_theme_color_override("font_color", _Theme.ZENY_GOLD)
	_Theme.apply_button(back_button, 44.0)
	_Theme.apply_cta_button(confirm_button, 48.0)
	confirm_button.text = "INICIAR — Mapa 1"
	back_button.pressed.connect(_on_back_pressed)
	confirm_button.pressed.connect(_on_confirm_pressed)
	_character = Global.selected_character
	if _character == null:
		Game.go_to_character_selection()
		return
	character_label.text = "Avatar: %s" % _character.character_name
	_classes = _ClassCatalog.get_starting_classes()
	_build_cards()
	if _classes.is_empty():
		return
	var first_playable: int = _first_selectable_index()
	_select_index(first_playable if first_playable >= 0 else 0, false)
	call_deferred("_focus_first_selectable_card")


func _build_cards() -> void:
	for child: Node in cards_row.get_children():
		child.queue_free()
	_cards.clear()
	for class_data: ClassData in _classes:
		var card: ClassScrollCard = _CardScene.instantiate() as ClassScrollCard
		cards_row.add_child(card)
		card.setup(class_data)
		card.card_focused.connect(_on_card_focused)
		_cards.append(card)


func _first_selectable_index() -> int:
	for i: int in _classes.size():
		if _classes[i].is_selectable:
			return i
	return -1


func _focus_first_selectable_card() -> void:
	var idx: int = _first_selectable_index()
	if idx < 0 or idx >= _cards.size():
		return
	_cards[idx].grab_focus()


func _on_card_focused(class_data: ClassData) -> void:
	var idx: int = _classes.find(class_data)
	if idx < 0:
		return
	_select_index(idx, true)


func _select_index(index: int, animate: bool) -> void:
	_selected_index = clampi(index, 0, maxi(_classes.size() - 1, 0))
	for i: int in _cards.size():
		_cards[i].apply_selection_visual(i == _selected_index, self if animate else null)
	var class_data: ClassData = _classes[_selected_index]
	_update_description(class_data)
	_update_background(class_data, animate)
	confirm_button.disabled = not class_data.is_selectable
	if class_data.is_selectable:
		confirm_button.text = "INICIAR — Mapa 1"
	else:
		confirm_button.text = "BLOQUEADA"


func _update_description(class_data: ClassData) -> void:
	class_name_label.text = class_data.display_name
	description_label.text = class_data.description
	if class_data.is_selectable:
		lock_label.text = ""
		lock_label.visible = false
	else:
		lock_label.text = class_data.lock_reason
		lock_label.visible = true


func _update_background(class_data: ClassData, animate: bool) -> void:
	if class_data.class_background != null:
		class_bg.texture = class_data.class_background
	if not animate:
		class_bg_fade.modulate.a = 0.0
		return
	if _bg_tween != null and _bg_tween.is_valid():
		_bg_tween.kill()
	class_bg_fade.modulate.a = 1.0
	_bg_tween = create_tween()
	_bg_tween.tween_property(class_bg_fade, "modulate:a", 0.0, 0.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_confirm_pressed() -> void:
	Audio.play_ui_click()
	if _classes.is_empty():
		return
	var class_data: ClassData = _classes[_selected_index]
	if not class_data.is_selectable:
		return
	_start_run_with_selection(class_data)


func _start_run_with_selection(class_data: ClassData) -> void:
	var skin_id: String = _character.default_skin_id
	if skin_id.is_empty():
		skin_id = Global.player_skin_id
	Global.select_character_and_class(_character, class_data, skin_id)
	Game.selected_map_id = _MapConfig.MAP_PRONTERA
	Game.intermap_preparation_mode = false
	Game.preserve_session_on_next_load = false
	Game.start_new_run()


func _on_back_pressed() -> void:
	Audio.play_ui_click()
	Game.go_to_character_selection()


func _unhandled_input(event: InputEvent) -> void:
	if _MenuEsc.is_back_pressed(event):
		_on_back_pressed()
		_MenuEsc.mark_input_handled(self)
		return
	if event.is_action_pressed("ui_left"):
		_select_index(_selected_index - 1, true)
		if _selected_index >= 0 and _selected_index < _cards.size():
			_cards[_selected_index].grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_select_index(_selected_index + 1, true)
		if _selected_index >= 0 and _selected_index < _cards.size():
			_cards[_selected_index].grab_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_on_confirm_pressed()
		get_viewport().set_input_as_handled()
