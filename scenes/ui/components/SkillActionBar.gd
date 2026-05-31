## Barra de habilidades activas en el HUD.
extends HBoxContainer

const _SlotScene: PackedScene = preload("res://scenes/ui/components/SkillBarSlot.tscn")

var _slots: Dictionary = {}
var _controller: ActiveSkillController = null


func bind_controller(controller: ActiveSkillController) -> void:
	if _controller and _controller.slot_cooldown_updated.is_connected(_on_slot_cooldown):
		_controller.slot_cooldown_updated.disconnect(_on_slot_cooldown)
	if _controller and _controller.slot_skills_changed.is_connected(_refresh_all):
		_controller.slot_skills_changed.disconnect(_refresh_all)
	_controller = controller
	if _controller == null:
		return
	if not _controller.slot_cooldown_updated.is_connected(_on_slot_cooldown):
		_controller.slot_cooldown_updated.connect(_on_slot_cooldown)
	if not _controller.slot_skills_changed.is_connected(_refresh_all):
		_controller.slot_skills_changed.connect(_refresh_all)
	_refresh_all()


func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 8)
	for slot_id: String in SkillTreeCatalog.ALL_SLOT_IDS:
		var slot: PanelContainer = _SlotScene.instantiate() as PanelContainer
		add_child(slot)
		if slot.has_method("setup"):
			slot.setup(slot_id)
		_slots[slot_id] = slot


func _refresh_all() -> void:
	for slot_id: String in _slots:
		var ratio: float = 0.0
		if _controller:
			ratio = _controller.get_slot_cooldown_ratio(slot_id)
		var slot_node: PanelContainer = _slots[slot_id] as PanelContainer
		if slot_node and slot_node.has_method("refresh_display"):
			slot_node.refresh_display(ratio)


func _on_slot_cooldown(slot_id: String, ratio: float) -> void:
	var slot_node: PanelContainer = _slots.get(slot_id) as PanelContainer
	if slot_node and slot_node.has_method("refresh_display"):
		slot_node.refresh_display(ratio)
