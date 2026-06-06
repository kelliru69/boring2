## Overlay de kit de combate con drag & drop hacia 5 ranuras (LMB/RMB/Space/Q/E).
## NUNCA despausa el juego: solo el menú de pausa o "Continuar" liberan la pausa.
class_name CombatKitOverlay
extends CanvasLayer

signal closed

const _Kit = preload("res://scripts/combat/combat_kit_service.gd")
const _Pause = preload("res://scripts/ui/run_pause_guard.gd")
const _Theme = preload("res://scripts/ui/modern_ui_theme.gd")
const _SlotScene: PackedScene = preload("res://scenes/ui/components/CombatKitSlot.tscn")
const _ChipScene: PackedScene = preload("res://scenes/ui/components/SkillKitDragChip.tscn")

@onready var _dimmer: ColorRect = $Dimmer
@onready var _panel: PanelContainer = $Panel
@onready var _slots_row: HBoxContainer = $Panel/Margin/VBox/SlotsRow
@onready var _pool_list: VBoxContainer = $Panel/Margin/VBox/Scroll/PoolList
@onready var _hint_label: Label = $Panel/Margin/VBox/HintLabel
@onready var _close_btn: Button = $Panel/Margin/VBox/CloseBtn

var _slot_widgets: Dictionary = {}
var _is_open: bool = false


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_set_always_process_recursive(self)
	_Theme.apply_panel(_panel)
	_Theme.apply_button(_close_btn, 40.0)
	_close_btn.pressed.connect(_on_close_pressed)
	if not Global.combat_kit_changed.is_connected(_refresh):
		Global.combat_kit_changed.connect(_refresh)
	if not Global.active_slots_changed.is_connected(_refresh):
		Global.active_slots_changed.connect(_refresh)
	_build_slots()
	_hint_label.text = "Arrastra habilidades activas a las ranuras. Clic derecho en ranura = vaciar."


func _set_always_process_recursive(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_ALWAYS
	for child: Node in node.get_children():
		_set_always_process_recursive(child)


func _build_slots() -> void:
	for child: Node in _slots_row.get_children():
		child.queue_free()
	_slot_widgets.clear()
	for slot_id: String in SkillTreeCatalog.ALL_SLOT_IDS:
		var slot: CombatKitSlot = _SlotScene.instantiate() as CombatKitSlot
		_slots_row.add_child(slot)
		slot.setup(slot_id)
		slot.skill_dropped.connect(_on_slot_changed)
		_slot_widgets[slot_id] = slot


func open() -> void:
	if _is_open:
		_Pause.ensure_paused(get_tree())
		_refresh()
		return
	_is_open = true
	_Pause.lock_pause(get_tree())
	_refresh()
	visible = true


## Cierra el overlay sin tocar el estado de pausa global.
func close() -> void:
	if not _is_open:
		return
	_is_open = false
	visible = false
	closed.emit()


func _on_close_pressed() -> void:
	Audio.play_ui_click()
	close()


func _on_slot_changed(_slot_id: String, _skill_id: String) -> void:
	_refresh()


func _refresh() -> void:
	for slot_id: String in _slot_widgets:
		var widget: CombatKitSlot = _slot_widgets[slot_id] as CombatKitSlot
		if widget:
			widget.refresh(Global.get_kit_slot_assignment(slot_id))
	for child: Node in _pool_list.get_children():
		child.queue_free()
	var skills: Array[String] = _Kit.get_unlocked_manual_skills()
	for skill_id: String in skills:
		var chip: SkillKitDragChip = _ChipScene.instantiate() as SkillKitDragChip
		_pool_list.add_child(chip)
		chip.setup(skill_id)
	var equipped: int = _Kit.count_equipped_in_slots()
	_hint_label.text = "Equipadas: %d / %d — Arrastra al kit; teclas según Opciones > Controles." % [
		equipped,
		_Kit.MAX_EQUIPPED,
	]
