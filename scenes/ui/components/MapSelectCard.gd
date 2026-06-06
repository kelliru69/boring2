## Tarjeta de mapa con miniaturas de mobs, jefe y candado.
class_name MapSelectCard
extends PanelContainer

signal map_selected(map_id: String)

const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")
const _EnemyCatalog = preload("res://data/enemy_catalog.gd")
const _MonsterManifest = preload("res://data/monster_visual_manifest.gd")

var _map_id: String = ""
var _unlocked: bool = true
var _selected: bool = false

@onready var _preview_tex: TextureRect = $Margin/VBox/Preview/BgTexture
@onready var _preview_tint: ColorRect = $Margin/VBox/Preview/BgTint
@onready var _title: Label = $Margin/VBox/TitleLabel
@onready var _difficulty: Label = $Margin/VBox/DifficultyLabel
@onready var _desc: Label = $Margin/VBox/DescLabel
@onready var _mobs_row: HBoxContainer = $Margin/VBox/MobsRow
@onready var _boss_slot: TextureRect = $Margin/VBox/BossRow/BossSprite
@onready var _boss_mystery: Label = $Margin/VBox/BossRow/BossMystery
@onready var _lock_overlay: ColorRect = $LockOverlay
@onready var _lock_label: Label = $LockOverlay/LockLabel


func _ready() -> void:
	add_theme_stylebox_override(&"panel", _Theme.make_card_style())
	_Theme.style_title(_title, 18)
	_Theme.style_accent(_difficulty, 13)
	_Theme.style_subtitle(_desc, 11)
	_Theme.style_title(_boss_mystery, 32)
	_lock_label.text = "🔒 Completa Prontera"
	_lock_overlay.visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_hover_enter)
	mouse_exited.connect(_on_hover_exit)
	_Theme.pass_clicks_to_root(self)


func setup(entry: Dictionary, unlocked: bool, boss_discovered: bool) -> void:
	_map_id = String(entry.get("id", ""))
	_unlocked = unlocked
	_title.text = String(entry.get("title", _map_id))
	_difficulty.text = "Dificultad: %s" % String(entry.get("difficulty_label", ""))
	_desc.text = String(entry.get("description", ""))
	var tex_path: String = String(entry.get("preview_texture", ""))
	if tex_path != "" and ResourceLoader.exists(tex_path):
		_preview_tex.texture = load(tex_path) as Texture2D
	else:
		_preview_tex.texture = null
	if _preview_tint:
		_preview_tint.color = entry.get("preview_tint", Color(0.1, 0.15, 0.2, 0.85)) as Color
	var mob_ids: Array = entry.get("mob_type_ids", []) as Array
	if _unlocked:
		_populate_mobs(mob_ids)
		_setup_boss(String(entry.get("boss_type_id", "")), boss_discovered)
	else:
		_populate_mobs_hidden(mob_ids.size())
		_setup_boss_hidden()
	_apply_lock_state()
	_Theme.pass_clicks_to_root(self)


func set_selected(selected: bool) -> void:
	_selected = selected and _unlocked
	add_theme_stylebox_override(&"panel", _Theme.make_card_style(false, _selected))


func _populate_mobs(type_ids: Array) -> void:
	_clear_mobs_row()
	for type_id: Variant in type_ids:
		if type_id is not String:
			continue
		var tex: Texture2D = _resolve_monster_texture(type_id as String)
		if tex == null:
			_mobs_row.add_child(_make_mystery_slot(40.0))
			continue
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(44, 44)
		icon.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = tex
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_mobs_row.add_child(icon)


func _populate_mobs_hidden(mob_count: int) -> void:
	_clear_mobs_row()
	for _i: int in mob_count:
		_mobs_row.add_child(_make_mystery_slot(40.0))


func _clear_mobs_row() -> void:
	for child: Node in _mobs_row.get_children():
		child.queue_free()


func _make_mystery_slot(slot_size: float) -> Label:
	var lbl := Label.new()
	lbl.custom_minimum_size = Vector2(slot_size, slot_size)
	lbl.text = "?"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_Theme.style_title(lbl, 22)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl


static func _resolve_monster_texture(type_id: String) -> Texture2D:
	var def: Dictionary = _EnemyCatalog.get_definition(type_id)
	var sp: String = String(def.get("sprite_path", ""))
	if sp != "" and ResourceLoader.exists(sp):
		return load(sp) as Texture2D
	var frame_path: String = _MonsterManifest.get_static_sprite_path(type_id)
	if frame_path != "" and ResourceLoader.exists(frame_path):
		return load(frame_path) as Texture2D
	return null


func _setup_boss(boss_type_id: String, discovered: bool) -> void:
	if discovered and boss_type_id != "":
		var tex: Texture2D = _resolve_monster_texture(boss_type_id)
		_boss_slot.visible = tex != null
		_boss_mystery.visible = tex == null
		_boss_slot.texture = tex
	else:
		_setup_boss_hidden()


func _setup_boss_hidden() -> void:
	_boss_slot.visible = false
	_boss_mystery.visible = true
	_boss_slot.texture = null


func _apply_lock_state() -> void:
	_lock_overlay.visible = not _unlocked
	# Modulate del panel entero atenúa pero dejaba ver sprites; el contenido ya usa "?".
	modulate = Color.WHITE if _unlocked else Color(0.55, 0.55, 0.6, 1.0)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _unlocked else Control.CURSOR_FORBIDDEN
	if not _unlocked:
		_selected = false
		add_theme_stylebox_override(&"panel", _Theme.make_card_style(false, false))


func _on_gui_input(event: InputEvent) -> void:
	if not _unlocked:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Audio.play_ui_click()
		map_selected.emit(_map_id)


func _on_hover_enter() -> void:
	if _unlocked and not _selected:
		add_theme_stylebox_override(&"panel", _Theme.make_card_style(true, false))


func _on_hover_exit() -> void:
	add_theme_stylebox_override(&"panel", _Theme.make_card_style(false, _selected))
