## Nodo GPUParticles2D editable: parámetros base en Inspector, material vía preset.
@tool
extends GPUParticles2D
class_name VfxParticles

@export var vfx_preset: StringName = &""
@export var apply_material_preset: bool = true
@export var auto_free_when_finished: bool = true

const BURST_EMISSION_CUTOFF_RATIO: float = 0.72
const FAST_FADE_SEC: float = 0.14

const _Budget = preload("res://scripts/vfx/combat_vfx_budget.gd")


func _ready() -> void:
	add_to_group(_Budget.VFX_PARTICLES_GROUP)
	_apply_preset_if_needed()
	emitting = false
	if not Engine.is_editor_hint() and one_shot and auto_free_when_finished:
		if not finished.is_connected(_on_finished):
			finished.connect(_on_finished)


func _apply_preset_if_needed() -> void:
	if not apply_material_preset or vfx_preset.is_empty():
		return
	ElementalVfxConfig.apply_preset(self, vfx_preset)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func play_burst_at(world_pos: Vector2) -> void:
	_apply_preset_if_needed()
	local_coords = true
	global_position = world_pos
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	restart()
	emitting = false
	call_deferred("_begin_burst")


func _begin_burst() -> void:
	emitting = true
	if one_shot:
		var cutoff: float = maxf(lifetime * BURST_EMISSION_CUTOFF_RATIO, 0.06)
		var timer: SceneTreeTimer = get_tree().create_timer(cutoff)
		timer.timeout.connect(_cut_burst_emission)


func _cut_burst_emission() -> void:
	emitting = false


func stop_emission_and_fade(fade_sec: float = FAST_FADE_SEC) -> void:
	emitting = false
	if fade_sec <= 0.0:
		queue_free()
		return
	var tw: Tween = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, fade_sec).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)


func configure_firewall_radius(barrier_radius: float) -> void:
	ElementalVfxConfig.apply_preset(self, ElementalVfxConfig.PRESET_FIREWALL_SMOKE, barrier_radius)


func configure_electric_outward(velocity_bias: float) -> void:
	ElementalVfxConfig.apply_preset(self, ElementalVfxConfig.PRESET_ELECTRIC_RING, velocity_bias)


func _on_finished() -> void:
	queue_free()
