## Player.gd — Mage y Swordman: habilidades, meta-progresión y cartas equipadas.
class_name Player
extends CharacterBody2D

const _ShapeFactory = preload("res://scripts/util/shape_texture_factory.gd")
const _SpriteLoader = preload("res://scripts/visual/sprite_asset_loader.gd")
const _AnimLoader = preload("res://scripts/visual/sprite_animation_loader.gd")
const _PlayerVisuals = preload("res://data/player_visual_catalog.gd")
const _SkillDefs = preload("res://data/skill_definitions.gd")
const _SkillScaling = preload("res://data/skill_scaling.gd")
const _MageScale = preload("res://data/mage_skill_scaling.gd")
const _SwordmanScaling = preload("res://data/swordman_scaling.gd")
const _FrostDiveTravelScene: PackedScene = preload("res://scenes/skills/FrostDiveTravel.tscn")
const _FusionMeteorRain = preload("res://scenes/skills/fusion/FusionMeteorRain.gd")
const _FusionLandProtector = preload("res://scenes/skills/fusion/FusionLandProtector.gd")
const _FusionHeavensDrive = preload("res://scenes/skills/fusion/FusionHeavensDrive.gd")
const _FusionStormGust = preload("res://scenes/skills/fusion/FusionStormGust.gd")
const _FusionGrandCross = preload("res://scenes/skills/fusion/FusionGrandCross.gd")
const _FusionShieldBoomerang = preload("res://scenes/skills/fusion/FusionShieldBoomerang.gd")
const _MageCombatScript = preload("res://scripts/combat/mage_combat_controller.gd")
const _SwordCombatScript = preload("res://scripts/combat/swordman_combat_controller.gd")
const _HpBarScript = preload("res://scenes/player/PlayerHpBar.gd")
const _DamageNumber = preload("res://scenes/ui/DamageNumber.gd")
const _CollisionLayers = preload("res://scripts/combat/collision_layers.gd")
const _BodySeparation = preload("res://scripts/combat/body_separation.gd")
const _TileDepthSort = preload("res://scripts/visual/tile_depth_sort.gd")
const _EndureAuraScene: PackedScene = preload("res://scenes/vfx/SwordmanEndureAura.tscn")
const _BerserkAuraScene: PackedScene = preload("res://scenes/vfx/SwordmanBerserkAura.tscn")
const _VfxSpawn = preload("res://scripts/vfx/vfx_spawn_helper.gd")
const _SkinCatalog = preload("res://data/player_skin_catalog.gd")

signal health_changed(current_hp: int, max_hp: int)
signal shield_changed(current_shield: int, max_shield: int)
signal player_died
signal support_buffs_changed(remaining_seconds: float, active: bool)

@export_group("Visual")
@export var sprite_height: float = 52.0
@export var procedural_fallback_color: Color = Color(0.35, 0.55, 1.0, 1.0)
@export_group("Indicador de apuntado")
## Radio del anillo en tiles de mapa (Prontera: 16px × escala 2 ≈ 32px por tile).
@export var aim_indicator_radius_tiles: float = 2.0
@export var aim_indicator_tile_px: float = 32.0
@export var aim_indicator_wedge_degrees: float = 32.0

@export_group("Estadísticas")
@export var max_hp: int = 100
@export var move_speed: float = 225.0
@export var cooldown_reduction: float = 0.0
@export var skill_range: float = 400.0

@export_group("Fire Bolt (Mage)")
@export var fire_bolt_damage: int = 25
@export var fire_bolt_interval: float = 0.9
@export var fire_bolt_burst_delay: float = 0.07
@export var fire_bolt_scene: PackedScene

@export_group("Cold Bolt (Mage)")
@export var cold_bolt_damage: int = 18
@export var cold_bolt_interval: float = 2.5
@export var cold_bolt_scene: PackedScene

@export_group("Thunderstorm (Mage)")
@export var thunderstorm_interval: float = 4.0
@export var thunderstorm_scene: PackedScene

@export_group("Lightning / Fire Wall (Mage)")
@export var lightning_bolt_scene: PackedScene = preload("res://scenes/skills/LightningBolt.tscn")
@export var firewall_scene: PackedScene = preload("res://scenes/skills/FireWall.tscn")

@export_group("Sight (Mage)")
@export var sight_tick_damage: int = 6

@export_group("Swordman")
@export var bash_base_damage: int = 22
@export var bash_scene: PackedScene
@export var magnum_base_damage: int = 28
@export var magnum_scene: PackedScene
@export var spear_stab_base_damage: int = 32
@export var spear_stab_scene: PackedScene
@export var bowling_bash_base_damage: int = 38
@export var bowling_bash_scene: PackedScene

@export_group("Loot")
@export var loot_magnet_radius: float = 96.0

@export_group("Combate / hitbox")
## i-frames tras recibir daño (contacto o proyectil).
@export var invulnerability_seconds: float = 0.05
## Cápsula de daño y empuje físico (pies/cadera; cabeza queda fuera con depth sort).
@export var hurt_capsule_radius: float = 9.0
@export var hurt_capsule_height: float = 12.0
@export var hurt_shape_offset_y: float = 11.0

var class_id: String = "mage"
var current_hp: int = 100
var fire_bolt_level: int = 1
var cold_bolt_level: int = 1
var thunderstorm_level: int = 1
var sight_level: int = 1
var bash_level: int = 1
var _increase_hp_recovery_applied: int = 0
var cold_bolt_unlocked: bool = false
var thunderstorm_unlocked: bool = false
var sight_unlocked: bool = false

var attack_multiplier: float = 1.0
var defense_multiplier: float = 1.0
var _land_protector_timer: float = 0.0
var _two_hand_quicken_timer: float = 0.0
var _reflect_shield_timer: float = 0.0
var _shield_boomerang_debuff_timer: float = 0.0
var crit_chance: float = 0.0
var _meta_regen_hp: int = 0
var _meta_regen_accum: float = 0.0
var _base_loot_magnet_radius: float = 96.0
var fire_damage_bonus: float = 0.0
var _fire_buff_timer: float = 0.0
var _endure_active: bool = false
var _endure_timer: float = 0.0

## Bufos del drop de cruz verde (Blessing + Increase AGI), comparten temporizador de 20 s.
const SUPPORT_BUFF_DURATION_SEC: float = 20.0
const SUPPORT_BLESSING_DAMAGE_MULT: float = 2.0
const SUPPORT_AGI_SPEED_MULT: float = 1.5
var _support_buff_timer: float = 0.0
var _support_blessing_mult: float = 1.0
var _support_agi_mult: float = 1.0

var _is_dead: bool = false
var _hurt_sfx_cooldown: float = 0.0
var _uses_animation: bool = false
var _action_anim_lock: bool = false
var _last_input_dir: Vector2 = Vector2.ZERO
## Último clip de caminata y espejo; al parar se usa la pareja idle_* correspondiente.
var _last_walk_anim: StringName = ANIM_WALK_DOWN
var _last_locomotion_flip_h: bool = false
var _base_modulate: Color = Color.WHITE
var _aim_direction: Vector2 = Vector2.RIGHT
var _burst_in_progress: bool = false
var _cold_burst_in_progress: bool = false
var _contact_hit_times: Dictionary = {}
var _hurt_radius: float = 9.0
var _hurt_offset: Vector2 = Vector2.ZERO
var _invuln_flicker_active: bool = false
var _contact_hurt_shown_physics_frame: int = -1
var _last_aim_draw_dir: Vector2 = Vector2.RIGHT
var _energy_coat_shield: int = 0
var _energy_coat_shield_max: int = 0
var _energy_coat_regen_elapsed: float = 0.0

const ENERGY_COAT_REGEN_DELAY: float = 8.0
const INVULN_FLICKER_ALPHA_LOW: float = 0.3
const INVULN_FLICKER_HZ: float = 14.0
## Auditoría escena original Player.tscn: CircleShape2D radius=14 → diámetro 28 px centrado en el torso.
const LEGACY_SCENE_HITBOX_RADIUS_PX: float = 14.0

const ANIM_WALK_RIGHT: StringName = &"walk_right"
const ANIM_WALK_UP: StringName = &"walk_up"
const ANIM_WALK_DOWN: StringName = &"walk_down"
const ANIM_WALK_DIAG_UP_RIGHT: StringName = &"walk_diag_up_right"
const ANIM_WALK_DIAG_DOWN_RIGHT: StringName = &"walk_diag_down_right"

const ANIM_IDLE_RIGHT: StringName = &"idle_right"
const ANIM_IDLE_UP: StringName = &"idle_up"
const ANIM_IDLE_DOWN: StringName = &"idle_down"
const ANIM_IDLE_DIAG_UP_RIGHT: StringName = &"idle_diag_up_right"
const ANIM_IDLE_DIAG_DOWN_RIGHT: StringName = &"idle_diag_down_right"

const DIR_INPUT_EPSILON_SQ: float = 0.0001
const MOVEMENT_SECTOR_STEP: float = PI / 4.0
const MOVEMENT_SECTOR_OFFSET: float = PI / 8.0

@onready var visual_root: Node2D = $VisualRoot
@onready var animated_visual: AnimatedSprite2D = $VisualRoot/AnimatedSprite2D
@onready var static_visual: Sprite2D = $VisualRoot/Sprite2D
@onready var sight_orb: Node = $Sight
@onready var loot_collector: Area2D = $LootCollector
@onready var fire_bolt_timer: Timer = $SkillTimers/FireBoltTimer
@onready var cold_bolt_timer: Timer = $SkillTimers/ColdBoltTimer
@onready var thunderstorm_timer: Timer = $SkillTimers/ThunderstormTimer
@onready var bash_timer: Timer = $SkillTimers/BashTimer
@onready var magnum_timer: Timer = $SkillTimers/MagnumTimer
@onready var regen_timer: Timer = $SkillTimers/RegenTimer
@onready var floating_hp_bar: ProgressBar = $FloatingHPBar
@onready var hit_sound_player: HitSoundPlayer = $HitSoundPlayer
@onready var active_skills: ActiveSkillController = $ActiveSkills
@onready var invulnerability_timer: Timer = $InvulnerabilityTimer
@onready var body_collision_shape: CollisionShape2D = $CollisionShape2D

var _mage_combat: Node = null
var _sword_combat: Node = null
var _endure_aura: Node2D = null
var _berserk_aura: Node2D = null
var _scene_sprite_frames: SpriteFrames = null
var _base_max_hp: int = 100
var _base_move_speed: float = 225.0
var _firewall_timer: Timer = null


func _ready() -> void:
	class_id = Game.selected_class_id
	add_to_group("Jugador")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_setup_body_collision_layers()
	_setup_player_hurtbox()
	_setup_invulnerability_timer()
	_update_tile_depth_sort()
	_configure_class_base_stats()
	_base_max_hp = max_hp
	_base_move_speed = move_speed
	_base_loot_magnet_radius = loot_magnet_radius
	Global.apply_run_bonuses_to_player(self)
	current_hp = max_hp
	if animated_visual and animated_visual.sprite_frames:
		_scene_sprite_frames = animated_visual.sprite_frames
	_apply_player_visual()
	if animated_visual and not animated_visual.animation_finished.is_connected(_on_sprite_animation_finished):
		animated_visual.animation_finished.connect(_on_sprite_animation_finished)
	_setup_combat_controllers()
	_setup_class_skills()
	_setup_floating_hp_bar()
	sync_from_skill_tree()
	if active_skills:
		active_skills.bind_player(self)
	if not health_changed.is_connected(_on_health_changed_berserk_vfx):
		health_changed.connect(_on_health_changed_berserk_vfx)
	health_changed.emit(current_hp, max_hp)
	shield_changed.emit(_energy_coat_shield, _energy_coat_shield_max)
	_update_berserk_aura()


func _configure_class_base_stats() -> void:
	if class_id == Game.CLASS_SWORDMAN:
		max_hp = 140
		move_speed = 205.0
		procedural_fallback_color = Color(0.85, 0.35, 0.3, 1.0)
	else:
		class_id = Game.CLASS_MAGE


func _setup_combat_controllers() -> void:
	if _mage_combat == null:
		_mage_combat = _MageCombatScript.new()
		_mage_combat.name = "MageCombat"
		add_child(_mage_combat)
	if _sword_combat == null:
		_sword_combat = _SwordCombatScript.new()
		_sword_combat.name = "SwordCombat"
		add_child(_sword_combat)
	if _mage_combat.has_method("setup"):
		_mage_combat.setup(self)
	if _sword_combat.has_method("setup"):
		_sword_combat.setup(self)
	_setup_swordman_vfx()


func _setup_swordman_vfx() -> void:
	if not is_swordman() or visual_root == null:
		return
	if _endure_aura == null and _EndureAuraScene != null:
		_endure_aura = _EndureAuraScene.instantiate() as Node2D
		if _endure_aura:
			visual_root.add_child(_endure_aura)
			_endure_aura.position = Vector2.ZERO
			_endure_aura.visible = false
	if _berserk_aura == null and _BerserkAuraScene != null:
		_berserk_aura = _BerserkAuraScene.instantiate() as Node2D
		if _berserk_aura:
			visual_root.add_child(_berserk_aura)
			_berserk_aura.position = Vector2.ZERO
			_berserk_aura.visible = false


func _update_endure_aura() -> void:
	if _endure_aura == null:
		return
	_endure_aura.visible = _endure_active and is_swordman() and not _is_dead


func _update_berserk_aura() -> void:
	if _berserk_aura == null:
		return
	var show_berserk: bool = false
	if is_swordman() and not _is_dead and Global.get_skill_level("auto_berserk") > 0:
		var ratio: float = get_missing_hp_ratio()
		show_berserk = ratio >= _SwordmanScaling.get_auto_berserk_visual_hp_threshold()
	if _berserk_aura.has_method("set_active"):
		_berserk_aura.set_active(show_berserk)
	else:
		_berserk_aura.visible = show_berserk


func _on_health_changed_berserk_vfx(_current: int, _max: int) -> void:
	_update_berserk_aura()


func _setup_class_skills() -> void:
	_stop_combat_skill_timers()
	if _mage_combat != null and _mage_combat.has_method("refresh_all"):
		_mage_combat.refresh_all()
	if _sword_combat != null and _sword_combat.has_method("refresh_all"):
		_sword_combat.refresh_all()


func _stop_combat_skill_timers() -> void:
	if fire_bolt_timer:
		fire_bolt_timer.stop()
	if cold_bolt_timer:
		cold_bolt_timer.stop()
	if thunderstorm_timer:
		thunderstorm_timer.stop()
	if bash_timer:
		bash_timer.stop()
	if magnum_timer:
		magnum_timer.stop()
	if _firewall_timer:
		_firewall_timer.stop()


func _ensure_firewall_timer() -> Timer:
	if _firewall_timer == null:
		_firewall_timer = Timer.new()
		_firewall_timer.name = "FirewallTimer"
		var host: Node = get_node_or_null("SkillTimers")
		if host:
			host.add_child(_firewall_timer)
		else:
			add_child(_firewall_timer)
	return _firewall_timer


func _setup_floating_hp_bar() -> void:
	if floating_hp_bar == null:
		return
	floating_hp_bar.set_script(_HpBarScript)
	if floating_hp_bar.has_method("bind_player"):
		floating_hp_bar.bind_player(self)


func apply_meta_bonuses(bonuses: Dictionary) -> void:
	var hp_mult: float = float(bonuses.get("max_hp_mult", 1.0))
	var atk_mult: float = float(bonuses.get("attack_mult", 1.0))
	var move_mult: float = float(bonuses.get("move_speed_mult", 1.0))
	var card_stats: Dictionary = bonuses.get("card_stats", {})
	max_hp = int(round(float(max_hp) * hp_mult))
	max_hp += int(card_stats.get("max_hp_flat", 0))
	max_hp = int(round(float(max_hp) * (1.0 + float(card_stats.get("max_hp_pct", 0.0)))))
	attack_multiplier = atk_mult * (1.0 + float(card_stats.get("attack_pct", 0.0)))
	defense_multiplier = 1.0 + float(bonuses.get("defense_pct", 0.0)) + float(card_stats.get("defense_pct", 0.0))
	move_speed *= move_mult * (1.0 + float(card_stats.get("move_speed_pct", 0.0)))
	cooldown_reduction = clampf(cooldown_reduction + float(card_stats.get("cooldown_pct", 0.0)), -0.5, 0.9)
	crit_chance = clampf(float(bonuses.get("crit_chance", 0.0)), 0.0, 0.95)
	_meta_regen_hp = maxi(int(bonuses.get("regen_hp_per_tick", 0)), 0)
	_meta_regen_accum = 0.0
	var pickup_mult: float = float(bonuses.get("pickup_range_mult", 1.0))
	loot_magnet_radius = _base_loot_magnet_radius * pickup_mult
	current_hp = max_hp


func is_mage() -> bool:
	return class_id == Game.CLASS_MAGE or class_id in [Game.JOB_WIZARD, Game.JOB_SAGE]


func is_swordman() -> bool:
	return class_id == Game.CLASS_SWORDMAN or class_id in [Game.JOB_KNIGHT, Game.JOB_CRUSADER]


func is_alive() -> bool:
	return not _is_dead


## Bonificación de poder al entrar a Orc Village con clase evolucionada (Job Change).
func apply_map3_evolved_power_boost() -> void:
	if Global.current_class.is_empty() or Global.current_class == Global.base_class_id:
		return
	max_hp = int(round(float(max_hp) * MapConfig.MAP3_EVOLVED_HP_MULT))
	current_hp = max_hp
	attack_multiplier *= MapConfig.MAP3_EVOLVED_ATTACK_MULT
	health_changed.emit(current_hp, max_hp)


func sync_from_skill_tree() -> void:
	class_id = Global.current_class if not Global.current_class.is_empty() else Game.selected_class_id
	fire_bolt_level = maxi(Global.get_skill_level("fire_bolt"), 1)
	cold_bolt_unlocked = Global.get_skill_level("cold_bolt") > 0
	cold_bolt_level = maxi(Global.get_skill_level("cold_bolt"), 1) if cold_bolt_unlocked else 1
	thunderstorm_unlocked = Global.get_skill_level("thunderstorm") > 0
	thunderstorm_level = maxi(Global.get_skill_level("thunderstorm"), 1) if thunderstorm_unlocked else 1
	sight_unlocked = Global.get_skill_level("sight") > 0
	sight_level = maxi(Global.get_skill_level("sight"), 1) if sight_unlocked else 1
	bash_level = maxi(Global.get_skill_level("bash"), 1)
	sync_increase_hp_recovery_levels()
	apply_run_stat_bonuses()
	_setup_class_skills()
	_update_berserk_aura()


func apply_run_stat_bonuses() -> void:
	move_speed = _base_move_speed * Global.get_move_speed_multiplier()
	_refresh_energy_coat_from_run_stats()


func apply_max_hp_percent_bonus(percent: float) -> void:
	var bonus_hp: int = int(round(float(_base_max_hp) * percent))
	if bonus_hp <= 0:
		return
	max_hp += bonus_hp
	current_hp = mini(current_hp + bonus_hp, max_hp)
	_refresh_energy_coat_from_run_stats()
	health_changed.emit(current_hp, max_hp)


func get_main_scene() -> Node:
	return get_tree().current_scene


func _spawn_in_main(node: Node, world_pos: Vector2) -> void:
	_VfxSpawn.add_child_at_world(get_main_scene(), node, world_pos)


func get_missing_hp_ratio() -> float:
	return _SwordmanScaling.get_missing_hp_ratio(current_hp, max_hp)


func get_auto_berserk_damage_multiplier() -> float:
	if not is_swordman():
		return 1.0
	return _SwordmanScaling.get_auto_berserk_damage_multiplier(
		Global.get_skill_level("auto_berserk"),
		get_missing_hp_ratio()
	)


## Alias de combate: daño melee actual con Berserk, maestría y buffs.
func get_current_damage(base: int, mult: float = 1.0) -> int:
	return get_scaled_melee_damage(base, mult)


func get_scaled_melee_damage(base: int, mult: float = 1.0) -> int:
	var dmg: float = float(get_scaled_skill_damage(base)) * mult * (1.0 + fire_damage_bonus)
	if is_swordman():
		dmg *= Global.get_sword_mastery_run_multiplier()
		dmg *= get_auto_berserk_damage_multiplier()
	return maxi(int(round(dmg)), 1)


func try_fatal_blow_heal(bash_damage: int) -> void:
	if not is_swordman() or bash_damage <= 0:
		return
	var chance: float = Global.get_fatal_blow_proc_chance()
	if chance <= 0.0 or randf() >= chance:
		return
	heal(maxi(int(round(float(bash_damage) * 0.01)), 1))


func apply_magnum_fire_buff() -> void:
	fire_damage_bonus = _SwordmanScaling.get_magnum_fire_buff(1)
	_fire_buff_timer = _SwordmanScaling.get_magnum_fire_buff_duration()


func heal_missing_percent(ratio: float) -> void:
	if _is_dead or ratio <= 0.0:
		return
	var missing: int = maxi(max_hp - current_hp, 0)
	heal(int(round(float(missing) * ratio)))


func sync_increase_hp_recovery_levels() -> void:
	if not is_swordman():
		return
	var target: int = Global.get_skill_level("increase_hp_recovery")
	while _increase_hp_recovery_applied < target:
		apply_max_hp_percent_bonus(_SwordmanScaling.get_max_hp_bonus_per_level())
		_increase_hp_recovery_applied += 1


func is_stagger_immune() -> bool:
	return _endure_active


func get_scaled_skill_damage(base: int) -> int:
	var dmg: int = _get_scaled_damage(base)
	if crit_chance > 0.0 and randf() < crit_chance:
		dmg = int(round(float(dmg) * MetaShop.CRIT_DAMAGE_MULT))
	return dmg


func get_auto_skill_interval(base_interval: float) -> float:
	var mult: float = Global.get_attack_speed_multiplier()
	if _two_hand_quicken_timer > 0.0:
		mult *= 2.0
	return maxf(base_interval / mult, 0.12)


func get_effective_skill_cooldown(skill_id: String) -> float:
	var base: float = Global.get_skill_cooldown(skill_id)
	if skill_id == "frost_dive":
		base = _MageScale.get_frost_dive_cooldown()
	elif skill_id == "thunderstorm":
		var ts_lv: int = maxi(Global.get_skill_level("thunderstorm"), 1)
		base = _MageScale.get_thunderstorm_cooldown(ts_lv)
	elif skill_id == "endure":
		base = _SwordmanScaling.get_endure_cooldown()
	elif skill_id == "bowling_bash":
		base = _SwordmanScaling.get_bowling_bash_cooldown()
	elif skill_id == "lord_of_vermilion":
		base = 14.0
	elif skill_id == "storm_gust":
		base = 12.0
	elif skill_id == "vanguard_force":
		base = 9.0
	elif skill_id == "meteor_storm":
		base = 11.0
	elif skill_id == "jupitel_thunder":
		base = 10.0
	elif skill_id == "diamond_dust":
		base = 11.0
	elif skill_id == "spiral_pierce":
		base = 8.0
	elif skill_id == "knights_rush":
		base = 10.0
	elif skill_id == "sacred_hammer":
		base = 9.5
	elif skill_id == "land_protector":
		base = 28.0
	elif skill_id == "heavens_drive":
		base = 13.0
	elif skill_id == "grand_cross":
		base = 14.0
	elif skill_id == "shield_boomerang":
		base = 11.0
	elif skill_id == "reflect_shield":
		base = 18.0
	elif skill_id == "two_hand_quicken":
		base = 16.0
	return maxf(base * Global.get_active_cooldown_multiplier(), 0.25)


func cast_skill_by_id(skill_id: String) -> bool:
	if _is_dead:
		return false
	if Global.is_skill_disabled_for_combat(skill_id):
		return false
	match skill_id:
		"frost_dive":
			return _cast_frost_dive()
		"thunderstorm":
			return _cast_thunderstorm_manual()
		"lord_of_vermilion":
			return _cast_lord_of_vermilion()
		"storm_gust":
			return _cast_storm_gust()
		"vanguard_force":
			return _cast_vanguard_force()
		"meteor_storm":
			return _cast_meteor_storm()
		"jupitel_thunder":
			return _cast_jupitel_thunder()
		"land_protector":
			return _cast_land_protector()
		"heavens_drive":
			return _cast_heavens_drive()
		"diamond_dust":
			return _cast_diamond_dust()
		"spiral_pierce":
			return _cast_spiral_pierce()
		"knights_rush":
			return _cast_knights_rush()
		"two_hand_quicken":
			return _cast_two_hand_quicken()
		"grand_cross":
			return _cast_grand_cross()
		"shield_boomerang":
			return _cast_shield_boomerang()
		"reflect_shield":
			return _cast_reflect_shield()
		"sacred_hammer":
			return _cast_sacred_hammer()
		"endure":
			return _cast_endure()
		"bowling_bash":
			return _cast_bowling_bash()
		_:
			return false


func _cast_endure() -> bool:
	if not is_swordman() or Global.get_skill_level("endure") <= 0:
		return false
	_play_action_anim(&"attack")
	_endure_active = true
	_endure_timer = _SwordmanScaling.get_endure_duration()
	_update_endure_aura()
	return true


func _cast_bowling_bash() -> bool:
	if not is_swordman() or bowling_bash_scene == null or Global.get_skill_level("bowling_bash") <= 0:
		return false
	var lv: int = Global.get_skill_level("bowling_bash")
	var forward: Vector2 = _get_mouse_aim_direction()
	if forward.length_squared() < 0.01:
		forward = _last_input_dir
	if forward.length_squared() < 0.01:
		forward = Vector2.RIGHT
	forward = forward.normalized()
	_play_action_anim(&"attack")
	var dmg: int = get_scaled_melee_damage(
		bowling_bash_base_damage,
		_SwordmanScaling.get_bowling_bash_damage_mult(lv)
	)
	var bash: Node = bowling_bash_scene.instantiate()
	if bash == null or not bash.has_method("setup_from_player"):
		return false
	_spawn_in_main(bash, global_position)
	bash.setup_from_player(
		global_position,
		forward,
		dmg,
		_SwordmanScaling.get_bowling_bash_width(lv),
		_SwordmanScaling.get_bowling_bash_length(lv),
		_SwordmanScaling.get_bowling_bash_knockback(lv)
	)
	return true


func _cast_thunderstorm_manual() -> bool:
	if not is_mage() or thunderstorm_scene == null or Global.get_skill_level("thunderstorm") <= 0:
		return false
	var lv: int = Global.get_skill_level("thunderstorm")
	var target_pos: Vector2 = get_global_mouse_position()
	_cast_thunderstorm_at_delayed(target_pos, lv)
	return true


func _cast_thunderstorm_at_delayed(
	world_pos: Vector2,
	lv: int,
	damage_mult: float = 1.0,
	radius_mult: float = 1.0
) -> void:
	var delay: float = _MageScale.get_thunderstorm_cast_delay(lv)
	await get_tree().create_timer(delay).timeout
	if _is_dead or not is_instance_valid(self):
		return
	_spawn_thunderstorm_at(world_pos, get_main_scene(), lv, damage_mult, radius_mult)


func _ensure_timer_connected(timer: Timer, callback: Callable) -> void:
	if timer == null:
		return
	if not timer.timeout.is_connected(callback):
		timer.timeout.connect(callback)


func _connect_timer(timer: Timer, callback: Callable, interval: float) -> void:
	if timer == null:
		return
	_ensure_timer_connected(timer, callback)
	timer.wait_time = _apply_cooldown(interval)
	timer.start()


func _apply_cooldown(base_interval: float) -> float:
	var reduction: float = clampf(cooldown_reduction, 0.0, 0.9)
	return maxf(base_interval * (1.0 - reduction), 0.15)


func _process(delta: float) -> void:
	if _is_dead:
		return
	_aim_direction = _get_mouse_aim_direction()
	if _fire_buff_timer > 0.0:
		_fire_buff_timer = maxf(_fire_buff_timer - delta, 0.0)
		if _fire_buff_timer <= 0.0:
			fire_damage_bonus = 0.0
	if _support_buff_timer > 0.0:
		_support_buff_timer = maxf(_support_buff_timer - delta, 0.0)
		if _support_buff_timer <= 0.0:
			_clear_support_buffs()
	if _endure_active:
		_endure_timer = maxf(_endure_timer - delta, 0.0)
		if _endure_timer <= 0.0:
			_endure_active = false
	_update_endure_aura()
	if _aim_direction.distance_squared_to(_last_aim_draw_dir) > 0.02:
		_last_aim_draw_dir = _aim_direction
		if GraphicsSettings.show_aim_direction_ring or _should_show_frost_dive_aim_preview():
			queue_redraw()
	if _meta_regen_hp > 0:
		_meta_regen_accum += delta
		if _meta_regen_accum >= MetaShop.REGEN_INTERVAL_SEC:
			_meta_regen_accum = 0.0
			heal(_meta_regen_hp)
	_update_energy_coat_regen(delta)


func _update_energy_coat_regen(delta: float) -> void:
	if _energy_coat_shield_max <= 0:
		return
	if _energy_coat_shield >= _energy_coat_shield_max:
		return
	_energy_coat_regen_elapsed += delta
	if _energy_coat_regen_elapsed < ENERGY_COAT_REGEN_DELAY:
		return
	_energy_coat_shield = _energy_coat_shield_max
	_energy_coat_regen_elapsed = 0.0
	shield_changed.emit(_energy_coat_shield, _energy_coat_shield_max)


func _refresh_energy_coat_from_run_stats() -> void:
	var ratio: float = 0.0
	if is_mage():
		ratio = Global.get_energy_coat_ratio()
	elif is_swordman():
		ratio = Global.get_shield_up_ratio()
	var new_max: int = int(round(float(max_hp) * ratio))
	new_max = maxi(new_max, 0)
	var old_max: int = _energy_coat_shield_max
	_energy_coat_shield_max = new_max
	if _energy_coat_shield_max <= 0:
		_energy_coat_shield = 0
		_energy_coat_regen_elapsed = 0.0
		shield_changed.emit(_energy_coat_shield, _energy_coat_shield_max)
		return
	if old_max <= 0:
		_energy_coat_shield = _energy_coat_shield_max
	else:
		_energy_coat_shield = mini(_energy_coat_shield, _energy_coat_shield_max)
	shield_changed.emit(_energy_coat_shield, _energy_coat_shield_max)


func _draw() -> void:
	if _is_dead:
		return
	_draw_aim_ring_indicator()
	_draw_frost_dive_indicator()


func get_hp_bar_anchor_offset() -> Vector2:
	return Vector2(0.0, get_visual_half_extent())


func get_visual_half_extent() -> float:
	if _uses_animation and animated_visual != null and animated_visual.visible:
		if animated_visual.sprite_frames != null:
			var anim: StringName = animated_visual.animation
			if anim.is_empty():
				var names: PackedStringArray = animated_visual.sprite_frames.get_animation_names()
				if not names.is_empty():
					anim = StringName(names[0])
			if not anim.is_empty():
				var tex: Texture2D = animated_visual.sprite_frames.get_frame_texture(anim, 0)
				if tex != null:
					return animated_visual.scale.y * float(tex.get_height()) * 0.5
	if static_visual != null and static_visual.visible:
		return static_visual.scale.y * 16.0
	return get_contact_radius()


func get_aim_indicator_radius() -> float:
	return maxf(aim_indicator_radius_tiles * aim_indicator_tile_px, 8.0)


func _should_show_frost_dive_aim_preview() -> bool:
	if not is_mage() or Global.get_skill_level("frost_dive") <= 0:
		return false
	var slot_id: String = _get_slot_for_skill("frost_dive")
	if slot_id.is_empty():
		return false
	if active_skills and active_skills.has_method("get_slot_cooldown_ratio"):
		if float(active_skills.get_slot_cooldown_ratio(slot_id)) > 0.01:
			return false
	return true


func _draw_aim_ring_indicator() -> void:
	if not GraphicsSettings.show_aim_direction_ring:
		return
	var radius: float = get_aim_indicator_radius()
	var angle: float = _aim_direction.angle()
	var half_wedge: float = deg_to_rad(aim_indicator_wedge_degrees * 0.5)
	var track_color: Color
	var wedge_color: Color
	var tip_color: Color
	if is_mage():
		track_color = Color(0.45, 0.72, 1.0, 0.22)
		wedge_color = Color(0.55, 0.88, 1.0, 0.82)
		tip_color = Color(0.75, 0.95, 1.0, 0.95)
	else:
		track_color = Color(1.0, 0.82, 0.35, 0.2)
		wedge_color = Color(1.0, 0.72, 0.28, 0.85)
		tip_color = Color(1.0, 0.92, 0.55, 0.95)

	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 72, track_color, 1.25, true)
	var start_a: float = angle - half_wedge
	var end_a: float = angle + half_wedge
	draw_arc(Vector2.ZERO, radius, start_a, end_a, 14, wedge_color, 3.5, true)

	var tip: Vector2 = Vector2.from_angle(angle) * (radius + 3.0)
	var back: Vector2 = Vector2.from_angle(angle) * (radius - 5.0)
	var side: Vector2 = Vector2.from_angle(angle + PI * 0.5) * 5.0
	draw_colored_polygon([tip, back + side, back - side], tip_color)


func _get_slot_for_skill(skill_id: String) -> String:
	if skill_id.is_empty():
		return ""
	for slot_id: String in SkillTreeCatalog.ALL_SLOT_IDS:
		if Global.get_slot_skill(slot_id) == skill_id:
			return slot_id
	return ""


func _draw_frost_dive_indicator() -> void:
	if not is_mage():
		return
	var lv: int = Global.get_skill_level("frost_dive")
	if lv <= 0:
		return
	var slot_id: String = _get_slot_for_skill("frost_dive")
	if slot_id.is_empty():
		return
	if active_skills and active_skills.has_method("get_slot_cooldown_ratio"):
		if float(active_skills.get_slot_cooldown_ratio(slot_id)) > 0.01:
			return

	var radius: float = _MageScale.get_frost_dive_radius(lv)
	var max_range: float = 220.0 + maxf(_MageScale.get_frost_dive_line_length(lv), 0.0)
	var mouse_world: Vector2 = get_global_mouse_position()
	var offset: Vector2 = mouse_world - global_position
	if offset.length() > max_range:
		offset = offset.normalized() * max_range
	var target_world: Vector2 = global_position + offset
	var target_local: Vector2 = to_local(target_world)

	var color_line: Color = Color(0.35, 0.9, 1.0, 0.75)
	var color_ring: Color = Color(0.55, 0.95, 1.0, 0.55)
	var color_fill: Color = Color(0.35, 0.9, 1.0, 0.12)
	draw_line(Vector2.ZERO, target_local, color_line, 4.0)
	draw_circle(target_local, radius, color_fill)
	draw_arc(target_local, radius, 0.0, TAU, 48, color_ring, 2.0, true)


## Movimiento en físicas (no en _process) para sincronizar con Camera2D en modo Physics.
## Pixel art — en Ajustes del proyecto recomendado:
##   Rendering → Textures → Default Texture Filter = Nearest (sin filtro bilinear).
##   Rendering → 2D → Snap 2D Transforms to Pixel = Activado.
##   (Opcional) Activar también Snap 2D Vertices to Pixel en el mismo apartado.
## En nodos UI/Control con texto pixelado: activar "Snap Controls to Pixels" en el inspector.
func _physics_process(delta: float) -> void:
	_hurt_sfx_cooldown = maxf(_hurt_sfx_cooldown - delta, 0.0)
	_tick_fusion_buffs(delta)
	_update_invulnerability_flicker()
	if _is_dead:
		return
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir.length_squared() > 0.0001:
		_last_input_dir = input_dir
	velocity = input_dir * move_speed * _support_agi_mult
	move_and_slide()
	_resolve_enemy_overlap()
	_update_tile_depth_sort()
	_collect_overlapping_cards()
	if Arena.is_ready():
		_constrain_to_playable()
	if input_dir.length_squared() > DIR_INPUT_EPSILON_SQ:
		_last_input_dir = input_dir.normalized()
	update_movement_animation(velocity)


func _unhandled_input(event: InputEvent) -> void:
	if active_skills and active_skills.try_handle_input(event):
		var vp: Viewport = get_viewport()
		if vp:
			vp.set_input_as_handled()


func get_contact_radius() -> float:
	return _hurt_radius


func get_hurt_world_position() -> Vector2:
	return global_position + _hurt_offset


func get_depth_sort_y() -> float:
	return get_hurt_world_position().y


func get_depth_tile_size_px() -> float:
	return aim_indicator_tile_px


func get_depth_tile_row() -> int:
	return _TileDepthSort.get_tile_row(get_depth_sort_y(), get_depth_tile_size_px())


func _update_tile_depth_sort() -> void:
	z_as_relative = false
	z_index = _TileDepthSort.compute_player_z_index(get_depth_tile_row())


func _resolve_enemy_overlap() -> void:
	var anchor: Vector2 = get_hurt_world_position()
	var my_radius: float = get_contact_radius()
	for node: Node in get_tree().get_nodes_in_group("Enemigos"):
		if not (node is Node2D):
			continue
		var enemy: Node2D = node as Node2D
		if enemy.has_method("is_linear_wave_mob") and bool(enemy.call("is_linear_wave_mob")):
			continue
		if enemy.has_method("should_skip_overlap_separation") and bool(enemy.call("should_skip_overlap_separation")):
			continue
		if not enemy.has_method("get_body_radius"):
			continue
		var enemy_radius: float = float(enemy.call("get_body_radius"))
		var resolved: Vector2 = _BodySeparation.resolve_position(
			enemy.global_position,
			anchor,
			enemy_radius,
			my_radius,
		)
		if resolved.distance_squared_to(enemy.global_position) > 0.25:
			enemy.global_position = resolved


func is_damage_invulnerable() -> bool:
	return invulnerability_timer != null and not invulnerability_timer.is_stopped()


func _setup_body_collision_layers() -> void:
	collision_layer = _CollisionLayers.LAYER_PLAYER
	collision_mask = _CollisionLayers.MASK_PLAYER_BODY
	if loot_collector:
		loot_collector.collision_layer = _CollisionLayers.LAYER_PLAYER
		loot_collector.collision_mask = _CollisionLayers.LAYER_LOOT


func _setup_invulnerability_timer() -> void:
	if invulnerability_timer == null:
		return
	invulnerability_timer.wait_time = invulnerability_seconds
	if not invulnerability_timer.timeout.is_connected(_on_invulnerability_timer_timeout):
		invulnerability_timer.timeout.connect(_on_invulnerability_timer_timeout)


func _setup_player_hurtbox() -> void:
	_hurt_offset = Vector2(0.0, hurt_shape_offset_y)
	_hurt_radius = hurt_capsule_radius
	if body_collision_shape == null:
		return
	var previous: Shape2D = body_collision_shape.shape
	var previous_label: String = "sin forma"
	if previous is CircleShape2D:
		var circle: CircleShape2D = previous as CircleShape2D
		previous_label = (
			"CircleShape2D radius=%.1f (diametro %.1f px, centrado en origen del Player)"
			% [circle.radius, circle.radius * 2.0]
		)
	var capsule: CapsuleShape2D = CapsuleShape2D.new()
	capsule.radius = hurt_capsule_radius
	capsule.height = hurt_capsule_height
	body_collision_shape.shape = capsule
	body_collision_shape.position = _hurt_offset
	var footprint_h: float = hurt_capsule_height + hurt_capsule_radius * 2.0
	print(
		"[Player hitbox] Anterior (escena): %s. Nuevo: CapsuleShape2D radius=%.1f height=%.1f offset=%s → ~%.0fx%.0f px en pies/cadera."
		% [previous_label, capsule.radius, capsule.height, _hurt_offset, footprint_h, capsule.radius * 2.0]
	)


func _begin_damage_invulnerability() -> void:
	if invulnerability_timer == null:
		return
	invulnerability_timer.wait_time = invulnerability_seconds
	invulnerability_timer.start()
	_invuln_flicker_active = true


func _on_invulnerability_timer_timeout() -> void:
	_invuln_flicker_active = false
	var target: CanvasItem = _get_visual_target()
	if target != null:
		target.modulate = _base_modulate


func _update_invulnerability_flicker() -> void:
	if not _invuln_flicker_active or not is_damage_invulnerable():
		return
	var target: CanvasItem = _get_visual_target()
	if target == null:
		return
	var phase: float = sin(Time.get_ticks_msec() * 0.001 * TAU * INVULN_FLICKER_HZ)
	var alpha: float = lerpf(INVULN_FLICKER_ALPHA_LOW, 1.0, 0.5 + 0.5 * phase)
	var base: Color = _base_modulate
	target.modulate = Color(base.r, base.g, base.b, alpha)


func _collect_overlapping_cards() -> void:
	if loot_collector == null:
		return
	for area: Area2D in loot_collector.get_overlapping_areas():
		if area is CardPickup:
			(area as CardPickup).try_collect_by(self)


func _constrain_to_playable() -> void:
	global_position = Arena.clamp_to_playable(global_position, get_contact_radius())


func _get_mouse_aim_direction() -> Vector2:
	var dir: Vector2 = get_global_mouse_position() - global_position
	if dir.length_squared() < 0.001:
		return _aim_direction if _aim_direction.length_squared() > 0.001 else Vector2.RIGHT
	return dir.normalized()


func _get_scaled_damage(base: int) -> int:
	var with_player_mods: float = float(base) * attack_multiplier * _support_blessing_mult
	with_player_mods *= Global.get_mystical_amplification_multiplier()
	return int(round(with_player_mods))


# --- Mage (legacy timers desactivados; lógica en MageCombatController) ---
func _start_fire_bolt_burst() -> void:
	_burst_in_progress = true
	var direction: Vector2 = _get_mouse_aim_direction()
	for i: int in clampi(fire_bolt_level, 1, SkillTreeCatalog.MAX_SKILL_LEVEL):
		if _is_dead:
			break
		_spawn_fire_bolt(direction)
		if i < fire_bolt_level - 1:
			await get_tree().create_timer(fire_bolt_burst_delay).timeout
	_burst_in_progress = false


func _spawn_fire_bolt(direction: Vector2) -> void:
	var bolt: Node = fire_bolt_scene.instantiate()
	if bolt == null or not bolt.has_method("setup_direction"):
		return
	var parent: Node = get_tree().current_scene
	_VfxSpawn.add_child_at_world(parent, bolt as Node2D, global_position)
	var dmg: int = _get_scaled_damage(fire_bolt_damage)
	dmg = int(round(float(dmg) * (1.0 + fire_damage_bonus)))
	bolt.setup_direction(direction, dmg)
	Audio.play_sfx("fire_bolt", randf_range(0.92, 1.05))


func _on_cold_bolt_timer_timeout() -> void:
	if _is_dead or not is_mage() or not cold_bolt_unlocked or cold_bolt_scene == null or _cold_burst_in_progress:
		return
	_cold_burst_in_progress = true
	await _fire_cold_bolt_burst()
	_cold_burst_in_progress = false


func _fire_cold_bolt_burst() -> void:
	for i: int in _SkillScaling.get_cold_bolt_burst_count(cold_bolt_level):
		if _is_dead:
			return
		var target: Node2D = _find_highest_max_hp_enemy_in_range()
		if target == null:
			return
		var bolt: Node = cold_bolt_scene.instantiate()
		if bolt == null:
			return
		_VfxSpawn.add_child_at_world(get_tree().current_scene, bolt as Node2D, global_position)
		bolt.setup_target(target, _get_scaled_damage(cold_bolt_damage))
		if i < _SkillScaling.get_cold_bolt_burst_count(cold_bolt_level) - 1:
			await get_tree().create_timer(0.12).timeout


func _on_thunderstorm_timer_timeout() -> void:
	if _is_dead or not is_mage() or not thunderstorm_unlocked or thunderstorm_scene == null:
		return
	var enemies: Array[Node] = get_tree().get_nodes_in_group(_SkillDefs.GROUP_ENEMIES)
	if enemies.is_empty():
		return
	var pick: Node2D = enemies[randi() % enemies.size()] as Node2D
	if pick:
		_spawn_thunderstorm_at(pick.global_position, get_tree().current_scene)


func _cast_frost_dive() -> bool:
	if not is_mage() or Global.get_skill_level("frost_dive") <= 0:
		return false
	var lv: int = Global.get_skill_level("frost_dive")
	var mouse: Vector2 = get_global_mouse_position()
	var radius: float = _MageScale.get_frost_dive_radius(lv)
	var dmg: int = int(round(float(_get_scaled_damage(cold_bolt_damage)) * _MageScale.get_frost_dive_damage_mult(lv)))
	var stun: float = _MageScale.get_frost_dive_stun_duration(lv)
	_play_action_anim(&"attack")
	# Rango: base + bonus de line_len (en nv.3+ se extiende).
	var max_range: float = 220.0 + maxf(_MageScale.get_frost_dive_line_length(lv), 0.0)
	var offset: Vector2 = mouse - global_position
	if offset.length() > max_range:
		offset = offset.normalized() * max_range
	var target: Vector2 = global_position + offset

	var travel: Node2D = _FrostDiveTravelScene.instantiate() as Node2D
	if travel == null:
		return false
	_spawn_in_main(travel, global_position)
	if travel.has_method("setup"):
		travel.setup(global_position, target, dmg, radius, stun)
	return true


func _damage_enemies_in_circle(center: Vector2, radius: float, damage: int, stun_sec: float) -> void:
	for node: Node in get_tree().get_nodes_in_group(_SkillDefs.GROUP_ENEMIES):
		if not node is Node2D:
			continue
		var enemy: Node2D = node as Node2D
		if center.distance_to(enemy.global_position) > radius:
			continue
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage)
		if enemy.has_method("apply_freeze"):
			enemy.apply_freeze(stun_sec, 0.0)


func _spawn_thunderstorm_at(world_pos: Vector2, parent: Node, lv: int = 1, damage_mult: float = 1.0, radius_mult: float = 1.0) -> void:
	var storm: Node = thunderstorm_scene.instantiate()
	if storm == null:
		return
	_VfxSpawn.add_child_at_world(parent, storm as Node2D, world_pos)
	if storm.has_method("setup_level"):
		var base_dmg: int = int(round(float(get_scaled_skill_damage(12)) * _MageScale.get_thunderstorm_damage_mult(lv) * damage_mult))
		storm.setup_level(lv, base_dmg)
		if storm.has_method("set_radius_override"):
			storm.set_radius_override(_MageScale.get_thunderstorm_radius(lv) * radius_mult)


func _cast_lord_of_vermilion() -> bool:
	if not is_mage() or Global.get_skill_level("lord_of_vermilion") <= 0 or thunderstorm_scene == null:
		return false
	var target_pos: Vector2 = get_global_mouse_position()
	_cast_thunderstorm_at_delayed(target_pos, 5, 2.8, 2.2)
	return true


func _cast_storm_gust() -> bool:
	if not is_mage() or Global.get_skill_level("storm_gust") <= 0:
		return false
	var lv: int = 5
	var target: Vector2 = _clamp_skill_target(get_global_mouse_position())
	var radius: float = _MageScale.get_frost_dive_radius(lv) * 2.8
	var dmg: int = int(round(float(get_scaled_skill_damage(cold_bolt_damage)) * _MageScale.get_frost_dive_damage_mult(lv) * 2.6))
	_play_action_anim(&"attack")
	var gust: Node2D = _FusionStormGust.new() as Node2D
	if gust == null:
		return false
	_spawn_in_main(gust, global_position)
	if gust.has_method("setup"):
		gust.setup(global_position, target, dmg, radius, 0.0)
	return true


func _cast_vanguard_force() -> bool:
	if not is_swordman() or Global.get_skill_level("vanguard_force") <= 0 or bowling_bash_scene == null:
		return false
	var forward: Vector2 = _get_mouse_aim_direction().normalized()
	if forward.length_squared() < 0.01:
		forward = Vector2.RIGHT
	_play_action_anim(&"attack")
	var dmg: int = int(round(float(bowling_bash_base_damage) * 2.6 * attack_multiplier))
	var bash: Node = bowling_bash_scene.instantiate()
	if bash == null or not bash.has_method("setup_from_player"):
		return false
	_spawn_in_main(bash, global_position)
	bash.setup_from_player(
		global_position,
		forward,
		dmg,
		_SwordmanScaling.get_bowling_bash_width(5) * 1.8,
		_SwordmanScaling.get_bowling_bash_length(5) * 1.5,
		_SwordmanScaling.get_bowling_bash_knockback(5) * 1.4
	)
	if randf() < 0.45:
		_grant_vanguard_shield()
	return true


func _grant_vanguard_shield() -> void:
	var bonus: int = maxi(int(round(float(max_hp) * 0.12)), 20)
	_energy_coat_shield = mini(_energy_coat_shield + bonus, maxi(_energy_coat_shield_max, bonus))


func _cast_meteor_storm() -> bool:
	if not is_mage() or Global.get_skill_level("meteor_storm") <= 0:
		return false
	_play_action_anim(&"attack")
	var center: Vector2 = _clamp_skill_target(get_global_mouse_position())
	var tick_dmg: int = int(round(float(get_scaled_skill_damage(22)) * 1.35))
	var rad: float = _MageScale.get_firewall_radius(5) * 2.0
	var rain: Node2D = _FusionMeteorRain.new() as Node2D
	if rain == null:
		return false
	_spawn_in_main(rain, center)
	if rain.has_method("setup"):
		rain.setup(center, rad, tick_dmg, 5.5, 0.16)
	return true


func _cast_jupitel_thunder() -> bool:
	if not is_mage() or Global.get_skill_level("jupitel_thunder") <= 0 or lightning_bolt_scene == null:
		return false
	_play_action_anim(&"attack")
	var dmg: int = int(round(float(get_scaled_skill_damage(fire_bolt_damage)) * 2.35))
	var travel: float = _MageScale.get_lightning_travel_distance(5) * 1.65
	var knockback: float = 520.0
	var base_dir: Vector2 = _get_mouse_aim_direction().normalized()
	if base_dir.length_squared() < 0.01:
		base_dir = Vector2.RIGHT
	for i: int in 5:
		var dir: Vector2 = base_dir.rotated(lerpf(-0.55, 0.55, float(i) / 4.0))
		_spawn_jupitel_bolt(dir, dmg, travel, knockback)
	return true


func _cast_diamond_dust() -> bool:
	if not is_mage() or Global.get_skill_level("diamond_dust") <= 0:
		return false
	var mouse: Vector2 = _clamp_skill_target(get_global_mouse_position())
	var radius: float = _MageScale.get_frost_dive_radius(5) * 1.9
	var dmg: int = int(round(float(get_scaled_skill_damage(cold_bolt_damage)) * 2.4))
	var stun: float = _MageScale.get_frost_dive_stun_duration(5) * 1.2
	_play_action_anim(&"attack")
	var travel: Node2D = _FrostDiveTravelScene.instantiate() as Node2D
	if travel == null:
		return false
	_spawn_in_main(travel, global_position)
	if travel.has_method("setup"):
		travel.setup(global_position, mouse, dmg, radius, stun)
	return true


func _cast_spiral_pierce() -> bool:
	if not is_swordman() or Global.get_skill_level("spiral_pierce") <= 0 or spear_stab_scene == null:
		return false
	var forward: Vector2 = _get_mouse_aim_direction().normalized()
	if forward.length_squared() < 0.01:
		forward = Vector2.RIGHT
	_play_action_anim(&"attack")
	var dmg: int = int(round(float(spear_stab_base_damage) * 2.8 * attack_multiplier))
	var slash: Node = spear_stab_scene.instantiate()
	if slash == null or not slash.has_method("setup_from_player"):
		return false
	_spawn_in_main(slash, global_position)
	slash.setup_from_player(
		global_position,
		forward,
		dmg,
		_SwordmanScaling.get_spear_stab_width(5) * 2.0,
		_SwordmanScaling.get_spear_stab_length(5) * 1.85,
		_SwordmanScaling.get_spear_stab_knockback(5) * 1.6
	)
	return true


func _cast_knights_rush() -> bool:
	if not is_swordman() or Global.get_skill_level("knights_rush") <= 0:
		return false
	var forward: Vector2 = _get_mouse_aim_direction().normalized()
	if forward.length_squared() < 0.01:
		forward = Vector2.RIGHT
	_play_action_anim(&"attack")
	heal_missing_percent(0.18)
	_endure_active = true
	_endure_timer = _SwordmanScaling.get_endure_duration() * 1.1
	_update_endure_aura()
	velocity = forward * move_speed * 2.4
	move_and_slide()
	if magnum_scene != null:
		var burst: Node = magnum_scene.instantiate()
		if burst != null and burst.has_method("setup_at_center"):
			_spawn_in_main(burst, global_position)
			var dmg: int = int(round(float(magnum_base_damage) * 1.6 * attack_multiplier))
			burst.setup_at_center(global_position, _SwordmanScaling.get_magnum_radius(5) * 1.1, dmg)
	return true


func _cast_land_protector() -> bool:
	if not is_mage() or Global.get_skill_level("land_protector") <= 0:
		return false
	_play_action_anim(&"attack")
	var zone: Node2D = _FusionLandProtector.new() as Node2D
	if zone == null:
		return false
	_spawn_in_main(zone, global_position)
	if zone.has_method("setup"):
		zone.setup(self, 140.0, 7.0)
	return true


func _cast_heavens_drive() -> bool:
	if not is_mage() or Global.get_skill_level("heavens_drive") <= 0:
		return false
	var forward: Vector2 = _get_mouse_aim_direction().normalized()
	if forward.length_squared() < 0.01:
		forward = Vector2.RIGHT
	var target: Vector2 = global_position + forward * 520.0
	if Arena.is_ready():
		target = Arena.clamp_to_playable(target, 20.0)
	var dmg: int = int(round(float(get_scaled_skill_damage(cold_bolt_damage)) * 2.8))
	var radius: float = _MageScale.get_frost_dive_radius(5) * 1.35
	_play_action_anim(&"attack")
	var drive: Node2D = _FusionHeavensDrive.new() as Node2D
	if drive == null:
		return false
	drive.line_hit_radius = 58.0
	drive.travel_speed = 920.0
	_spawn_in_main(drive, global_position)
	if drive.has_method("setup"):
		drive.setup(global_position, target, dmg, radius, 0.0)
	return true


func _cast_two_hand_quicken() -> bool:
	if not is_swordman() or Global.get_skill_level("two_hand_quicken") <= 0:
		return false
	_play_action_anim(&"attack")
	_two_hand_quicken_timer = maxf(_two_hand_quicken_timer, 8.0)
	if _sword_combat != null and _sword_combat.has_method("refresh_all"):
		_sword_combat.refresh_all()
	if _mage_combat != null and _mage_combat.has_method("refresh_all"):
		_mage_combat.refresh_all()
	return true


func _cast_grand_cross() -> bool:
	if not is_swordman() or Global.get_skill_level("grand_cross") <= 0:
		return false
	_play_action_anim(&"attack")
	var tick_dmg: int = int(round(float(magnum_base_damage) * 1.55 * attack_multiplier))
	var cross: Node2D = _FusionGrandCross.new() as Node2D
	if cross == null:
		return false
	_spawn_in_main(cross, global_position)
	if cross.has_method("setup"):
		cross.setup(self, tick_dmg, 3.6)
	return true


func _cast_shield_boomerang() -> bool:
	if not is_swordman() or Global.get_skill_level("shield_boomerang") <= 0:
		return false
	var forward: Vector2 = _get_mouse_aim_direction().normalized()
	if forward.length_squared() < 0.01:
		forward = Vector2.RIGHT
	_play_action_anim(&"attack")
	var dmg: int = int(round(float(bowling_bash_base_damage) * 2.1 * attack_multiplier))
	var boom: Area2D = _FusionShieldBoomerang.new() as Area2D
	if boom == null:
		return false
	_spawn_in_main(boom, global_position)
	if boom.has_method("setup"):
		boom.setup(self, forward, dmg)
	_shield_boomerang_debuff_timer = get_effective_skill_cooldown("shield_boomerang")
	return true


func _cast_reflect_shield() -> bool:
	if not is_swordman() or Global.get_skill_level("reflect_shield") <= 0:
		return false
	_play_action_anim(&"attack")
	_reflect_shield_timer = maxf(_reflect_shield_timer, 6.0)
	return true


func _cast_sacred_hammer() -> bool:
	if not is_swordman() or Global.get_skill_level("sacred_hammer") <= 0 or magnum_scene == null:
		return false
	_play_action_anim(&"attack")
	heal_percent_of_max(0.12)
	var burst: Node = magnum_scene.instantiate()
	if burst == null or not burst.has_method("setup_at_center"):
		return false
	_spawn_in_main(burst, global_position)
	var dmg: int = int(round(float(magnum_base_damage) * 2.2 * attack_multiplier))
	burst.setup_at_center(global_position, _SwordmanScaling.get_magnum_radius(5) * 1.45, dmg)
	if burst.has_method("set_knockback_force"):
		burst.knockback_force = _SwordmanScaling.get_magnum_knockback(5) * 1.3
	return true


func _clamp_skill_target(world_pos: Vector2) -> Vector2:
	var offset: Vector2 = world_pos - global_position
	var max_range: float = 320.0
	if offset.length() > max_range:
		offset = offset.normalized() * max_range
	var target: Vector2 = global_position + offset
	if Arena.is_ready():
		target = Arena.clamp_to_playable(target, 20.0)
	return target


func _spawn_firewall_barrier(
	pos: Vector2,
	tile_count: int,
	tile_px: float,
	dmg: int,
	kb: float,
	life: float,
	push_direction: Vector2 = Vector2.LEFT
) -> void:
	var wall: Node = firewall_scene.instantiate()
	if wall == null:
		return
	_spawn_in_main(wall, pos)
	if wall.has_method("setup_barrier"):
		wall.setup_barrier(pos, tile_count, tile_px, dmg, kb, life, push_direction)


func _spawn_skill_fire_bolt(direction: Vector2, dmg: int, trail_preset: StringName = &"fire") -> void:
	if fire_bolt_scene == null:
		return
	var bolt: Node = fire_bolt_scene.instantiate()
	if bolt == null:
		return
	if bolt.has_method("set_trail_preset"):
		bolt.set_trail_preset(trail_preset)
	_spawn_in_main(bolt, global_position)
	if bolt.has_method("setup_direction"):
		bolt.setup_direction(direction, dmg)


func _spawn_lightning_bolt(direction: Vector2, dmg: int, travel: float, knockback: float = 0.0) -> void:
	var bolt: Node = lightning_bolt_scene.instantiate()
	if bolt == null:
		return
	_spawn_in_main(bolt, global_position)
	if bolt.get("knockback_on_hit") != null:
		bolt.knockback_on_hit = knockback
	if bolt.has_method("setup_boomerang"):
		bolt.setup_boomerang(direction, dmg, travel)


func _spawn_jupitel_bolt(direction: Vector2, dmg: int, travel: float, knockback: float) -> void:
	_spawn_lightning_bolt(direction, dmg, travel, knockback)


func activate_land_protector(duration: float) -> void:
	_land_protector_timer = maxf(_land_protector_timer, maxf(duration, 0.1))


func try_fusion_autocast_duplicate_bolt(
	direction: Vector2,
	damage: int,
	trail_preset: StringName = &"fire",
	bolt_kind: String = "fire"
) -> void:
	if Global.get_skill_level("autocast") <= 0 or not is_mage():
		return
	if randf() >= 0.5:
		return
	var rnd_dir: Vector2 = Vector2.from_angle(randf() * TAU)
	match bolt_kind:
		"lightning":
			_spawn_lightning_bolt(rnd_dir, damage, _MageScale.get_lightning_travel_distance(5), 0.0)
		"cold":
			var target: Node2D = _find_nearest_enemy_in_range()
			if target != null and cold_bolt_scene != null:
				var bolt: Node = cold_bolt_scene.instantiate()
				if bolt != null:
					_spawn_in_main(bolt, global_position)
					if bolt.has_method("setup_target"):
						bolt.setup_target(target, damage)
			else:
				_spawn_skill_fire_bolt(rnd_dir, damage, trail_preset)
		_:
			_spawn_skill_fire_bolt(rnd_dir, damage, trail_preset)


func _tick_fusion_buffs(delta: float) -> void:
	_land_protector_timer = maxf(_land_protector_timer - delta, 0.0)
	_two_hand_quicken_timer = maxf(_two_hand_quicken_timer - delta, 0.0)
	_reflect_shield_timer = maxf(_reflect_shield_timer - delta, 0.0)
	_shield_boomerang_debuff_timer = maxf(_shield_boomerang_debuff_timer - delta, 0.0)


func _reflect_damage_to_nearest_enemy(incoming_damage: int) -> void:
	if incoming_damage <= 0:
		return
	var enemy: Node2D = _find_nearest_enemy_in_range()
	if enemy == null or not enemy.has_method("take_damage"):
		return
	var reflected: int = maxi(int(round(float(incoming_damage) * 5.0)), 1)
	enemy.take_damage(reflected)


func _collect_enemies_in_range(max_range: float, max_count: int) -> Array[Node2D]:
	var found: Array[Node2D] = []
	for node: Node in get_tree().get_nodes_in_group("Enemigos"):
		if not (node is Node2D):
			continue
		var enemy: Node2D = node as Node2D
		if global_position.distance_squared_to(enemy.global_position) > max_range * max_range:
			continue
		found.append(enemy)
	if found.size() <= max_count:
		return found
	found.shuffle()
	return found.slice(0, max_count)


# --- Swordman (legacy timers desactivados; lógica en SwordmanCombatController) ---


func _find_nearest_enemy_in_range() -> Node2D:
	var best: Node2D = null
	var best_dist_sq: float = INF
	var range_sq: float = skill_range * skill_range
	for node: Node in get_tree().get_nodes_in_group(_SkillDefs.GROUP_ENEMIES):
		if not node is Node2D:
			continue
		var enemy: Node2D = node as Node2D
		var dist_sq: float = global_position.distance_squared_to(enemy.global_position)
		if dist_sq > range_sq:
			continue
		if dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			best = enemy
	return best


func _find_highest_max_hp_enemy_in_range() -> Node2D:
	var best: Node2D = null
	var best_hp: int = -1
	var range_sq: float = skill_range * skill_range
	for node: Node in get_tree().get_nodes_in_group(_SkillDefs.GROUP_ENEMIES):
		if not node is Node2D:
			continue
		var enemy: Node2D = node as Node2D
		if global_position.distance_squared_to(enemy.global_position) > range_sq:
			continue
		var ehp: int = int(enemy.max_hp) if enemy.get("max_hp") != null else 0
		if ehp > best_hp:
			best_hp = ehp
			best = enemy
	return best


func _apply_player_skin_frames() -> void:
	if animated_visual == null:
		return
	var skin_id: String = Game.selected_player_skin_id
	if skin_id.is_empty() or not _SkinCatalog.is_valid(skin_id):
		skin_id = _SkinCatalog.get_default_skin_id()
	var skin_def: Dictionary = _SkinCatalog.get_skin(skin_id)
	if bool(skin_def.get("use_scene_default", false)):
		if _scene_sprite_frames:
			animated_visual.sprite_frames = _scene_sprite_frames
		return
	var built: SpriteFrames = PlayerDirectionalSpriteFrames.build_from_skin_def(skin_def)
	if built:
		animated_visual.sprite_frames = built


func _apply_player_visual() -> void:
	_apply_player_skin_frames()
	if _try_use_editor_directional_sprite():
		return
	_uses_animation = false
	if animated_visual:
		animated_visual.visible = false
	if static_visual:
		static_visual.visible = true
	var debug_color: Color = Color(0.35, 0.55, 1.0, 1.0)
	if static_visual and static_visual.has_method("apply_visual"):
		static_visual.apply_visual(_ShapeFactory.Shape.SQUARE, debug_color)
	_set_visual_modulate(debug_color)


func _try_use_editor_directional_sprite() -> bool:
	if animated_visual == null or animated_visual.sprite_frames == null:
		return false
	var frames: SpriteFrames = animated_visual.sprite_frames
	if not frames.has_animation(ANIM_WALK_RIGHT):
		return false
	_uses_animation = true
	animated_visual.visible = true
	animated_visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if static_visual:
		static_visual.visible = false
	_scale_animated_visual_to_height()
	_last_walk_anim = ANIM_WALK_DOWN
	_last_locomotion_flip_h = false
	update_movement_animation(Vector2.ZERO)
	return true


func _scale_animated_visual_to_height() -> void:
	if animated_visual == null or animated_visual.sprite_frames == null:
		return
	var anim: StringName = animated_visual.animation
	if anim.is_empty() or not animated_visual.sprite_frames.has_animation(anim):
		var names: PackedStringArray = animated_visual.sprite_frames.get_animation_names()
		if names.is_empty():
			return
		anim = StringName(names[0])
	var tex: Texture2D = animated_visual.sprite_frames.get_frame_texture(anim, 0)
	if tex == null:
		return
	var scale_factor: float = sprite_height / maxf(float(tex.get_height()), 1.0)
	animated_visual.scale = Vector2(scale_factor, scale_factor)
	animated_visual.centered = true


func _set_visual_modulate(color: Color) -> void:
	if animated_visual and animated_visual.visible:
		animated_visual.modulate = color
	if static_visual and static_visual.visible:
		static_visual.modulate = color


func _get_visual_target() -> CanvasItem:
	if _uses_animation and animated_visual:
		return animated_visual
	return static_visual


func _update_facing(input_dir: Vector2) -> void:
	if _uses_animation:
		return
	if input_dir.x == 0.0:
		return
	var flip: bool = input_dir.x < 0.0
	if static_visual:
		static_visual.flip_h = flip


## 8 direcciones: 5 walk + 5 idle, flip_h para la izquierda.
func update_movement_animation(direction: Vector2) -> void:
	if not _uses_animation or animated_visual == null or _is_dead or _action_anim_lock:
		return
	var frames: SpriteFrames = animated_visual.sprite_frames
	if frames == null:
		return

	if direction.length_squared() < DIR_INPUT_EPSILON_SQ:
		_play_directional_anim(_walk_to_idle_anim(_last_walk_anim), _last_locomotion_flip_h, frames)
		return

	var facing: Vector2 = direction.normalized()
	_last_input_dir = facing
	var locomotion: Dictionary = _locomotion_from_sector(_movement_sector_index(facing))
	_last_walk_anim = locomotion["walk"] as StringName
	_last_locomotion_flip_h = bool(locomotion["flip_h"])
	_play_directional_anim(_last_walk_anim, _last_locomotion_flip_h, frames)


func _locomotion_from_sector(sector: int) -> Dictionary:
	var walk: StringName = ANIM_WALK_RIGHT
	var flip_h: bool = false
	match sector:
		0:
			walk = ANIM_WALK_RIGHT
		1:
			walk = ANIM_WALK_DIAG_DOWN_RIGHT
		2:
			walk = ANIM_WALK_DOWN
		3:
			walk = ANIM_WALK_DIAG_DOWN_RIGHT
			flip_h = true
		4:
			walk = ANIM_WALK_RIGHT
			flip_h = true
		5:
			walk = ANIM_WALK_DIAG_UP_RIGHT
			flip_h = true
		6:
			walk = ANIM_WALK_UP
		7:
			walk = ANIM_WALK_DIAG_UP_RIGHT
		_:
			walk = ANIM_WALK_DOWN
	return {"walk": walk, "flip_h": flip_h}


func _walk_to_idle_anim(walk_anim: StringName) -> StringName:
	match walk_anim:
		ANIM_WALK_RIGHT:
			return ANIM_IDLE_RIGHT
		ANIM_WALK_UP:
			return ANIM_IDLE_UP
		ANIM_WALK_DIAG_UP_RIGHT:
			return ANIM_IDLE_DIAG_UP_RIGHT
		ANIM_WALK_DIAG_DOWN_RIGHT:
			return ANIM_IDLE_DIAG_DOWN_RIGHT
		_:
			return ANIM_IDLE_DOWN


func _play_directional_anim(anim_name: StringName, flip_h: bool, frames: SpriteFrames) -> void:
	animated_visual.flip_h = flip_h
	if not frames.has_animation(anim_name):
		return
	animated_visual.speed_scale = 1.25 if String(anim_name).begins_with("walk") else 1.0
	if animated_visual.animation != anim_name:
		animated_visual.play(anim_name)
	elif not animated_visual.is_playing():
		animated_visual.play(anim_name)


func _movement_sector_index(facing: Vector2) -> int:
	var angle: float = facing.angle()
	return int(wrapf(angle + MOVEMENT_SECTOR_OFFSET, 0.0, TAU) / MOVEMENT_SECTOR_STEP) % 8


func _update_locomotion_anim(_input_dir: Vector2) -> void:
	update_movement_animation(velocity)


func _play_action_anim(anim_name: StringName) -> void:
	if not _uses_animation or animated_visual == null or animated_visual.sprite_frames == null or _is_dead:
		return
	if anim_name == &"hurt" and is_stagger_immune():
		return
	if not animated_visual.sprite_frames.has_animation(anim_name):
		return
	_action_anim_lock = true
	animated_visual.play(anim_name)


func _on_sprite_animation_finished() -> void:
	if not _uses_animation or animated_visual == null:
		return
	var finished: StringName = animated_visual.animation
	if finished == &"hurt" or finished == &"attack":
		_action_anim_lock = false
		if not _is_dead:
			update_movement_animation(
				velocity if velocity.length_squared() > DIR_INPUT_EPSILON_SQ else Vector2.ZERO
			)


func is_loot_in_magnet_range(world_pos: Vector2) -> bool:
	return global_position.distance_to(world_pos) <= loot_magnet_radius


func _refresh_cold_bolt_timer() -> void:
	if cold_bolt_timer == null or not is_mage():
		return
	_ensure_timer_connected(cold_bolt_timer, _on_cold_bolt_timer_timeout)
	cold_bolt_timer.stop()
	if cold_bolt_unlocked:
		var mult: float = _SkillScaling.get_cold_bolt_cooldown_multiplier(cold_bolt_level)
		cold_bolt_timer.wait_time = _apply_cooldown(cold_bolt_interval * mult)
		cold_bolt_timer.start()


func _refresh_thunderstorm_timer() -> void:
	if thunderstorm_timer == null or not is_mage():
		return
	_ensure_timer_connected(thunderstorm_timer, _on_thunderstorm_timer_timeout)
	thunderstorm_timer.stop()
	if thunderstorm_unlocked:
		thunderstorm_timer.wait_time = _apply_cooldown(thunderstorm_interval)
		thunderstorm_timer.start()


func _compute_mitigated_damage(amount: int) -> int:
	if _land_protector_timer > 0.0:
		return 0
	var mitigated: int = amount
	if _endure_active:
		mitigated = int(round(float(amount) * (1.0 - _SwordmanScaling.get_endure_defense_bonus())))
	var def_mult: float = defense_multiplier
	if _shield_boomerang_debuff_timer > 0.0:
		def_mult *= 0.5
	return int(round(float(mitigated) / maxf(def_mult, 0.1)))


func _prune_contact_hit_times() -> void:
	for source in _contact_hit_times.keys():
		if not is_instance_valid(source):
			_contact_hit_times.erase(source)


func take_contact_damage(amount: int, source: Node) -> bool:
	if _is_dead or amount <= 0 or source == null or not is_instance_valid(source):
		return false
	if is_damage_invulnerable():
		return false
	_prune_contact_hit_times()
	var now: float = Time.get_ticks_msec() / 1000.0
	if _contact_hit_times.has(source):
		if now - float(_contact_hit_times[source]) < invulnerability_seconds:
			return false
	var mitigated: int = _compute_mitigated_damage(amount)
	if _reflect_shield_timer > 0.0 and mitigated > 0:
		_reflect_damage_to_nearest_enemy(mitigated)
	mitigated = _consume_energy_coat_damage(mitigated)
	if mitigated <= 0:
		return false
	_contact_hit_times[source] = now
	if not is_stagger_immune():
		_action_anim_lock = false
		_play_action_anim(&"hurt")
	current_hp = maxi(current_hp - mitigated, 0)
	var frame: int = Engine.get_physics_frames()
	if frame != _contact_hurt_shown_physics_frame:
		_contact_hurt_shown_physics_frame = frame
		_show_hurt_damage_number(mitigated)
		if _hurt_sfx_cooldown <= 0.0:
			if hit_sound_player:
				hit_sound_player.play_hit(global_position, randf_range(0.92, 1.05))
			else:
				Audio.play_sfx("player_hurt")
			_hurt_sfx_cooldown = 0.4
		_flash_hurt()
	_begin_damage_invulnerability()
	health_changed.emit(current_hp, max_hp)
	if current_hp <= 0:
		_die()
	return true


func take_damage(amount: int) -> void:
	if _is_dead or amount <= 0 or is_damage_invulnerable():
		return
	var mitigated: int = _compute_mitigated_damage(amount)
	if _reflect_shield_timer > 0.0 and mitigated > 0:
		_reflect_damage_to_nearest_enemy(mitigated)
	mitigated = _consume_energy_coat_damage(mitigated)
	if mitigated <= 0:
		return
	if not is_stagger_immune():
		_action_anim_lock = false
		_play_action_anim(&"hurt")
	current_hp = maxi(current_hp - mitigated, 0)
	_show_hurt_damage_number(mitigated)
	if _hurt_sfx_cooldown <= 0.0:
		if hit_sound_player:
			hit_sound_player.play_hit(global_position, randf_range(0.92, 1.05))
		else:
			Audio.play_sfx("player_hurt")
		_hurt_sfx_cooldown = 0.4
	_flash_hurt()
	_begin_damage_invulnerability()
	health_changed.emit(current_hp, max_hp)
	if current_hp <= 0:
		_die()


func _show_hurt_damage_number(amount: int) -> void:
	var parent: Node = get_tree().current_scene
	if parent == null:
		return
	var hurt_color: Color = Color(1.0, 0.22, 0.22)
	_DamageNumber.spawn(global_position + Vector2(0.0, -18.0), amount, parent, hurt_color)


func _flash_hurt() -> void:
	if _uses_animation and animated_visual:
		_play_action_anim(&"hurt")
	if is_damage_invulnerable():
		return
	var target: CanvasItem = _get_visual_target()
	if target == null:
		return
	target.modulate = Color(1.4, 0.5, 0.5)
	var tween: Tween = create_tween()
	tween.tween_property(target, "modulate", _base_modulate, 0.15)


func heal(amount: int) -> void:
	if _is_dead or amount <= 0:
		return
	current_hp = mini(current_hp + amount, max_hp)
	health_changed.emit(current_hp, max_hp)


func _consume_energy_coat_damage(amount: int) -> int:
	if amount <= 0:
		return 0
	_energy_coat_regen_elapsed = 0.0
	if _energy_coat_shield_max <= 0 or _energy_coat_shield <= 0:
		return amount
	var absorbed: int = mini(amount, _energy_coat_shield)
	_energy_coat_shield -= absorbed
	shield_changed.emit(_energy_coat_shield, _energy_coat_shield_max)
	return amount - absorbed


func heal_percent_of_max(ratio: float) -> void:
	var heal_mult: float = 1.0
	if is_swordman():
		var hp_rec_lv: int = Global.get_skill_level("increase_hp_recovery")
		heal_mult += _SwordmanScaling.get_food_heal_bonus_per_level(hp_rec_lv)
	heal(int(round(float(max_hp) * clampf(ratio, 0.0, 1.0) * heal_mult)))


## Recoge la cruz verde: curación + Blessing/AGI por 20 s (el temporizador se reinicia al repetir).
func apply_heal_buff_pickup(heal_ratio: float = 0.20) -> void:
	if _is_dead:
		return
	heal_percent_of_max(heal_ratio)
	_support_blessing_mult = SUPPORT_BLESSING_DAMAGE_MULT
	_support_agi_mult = SUPPORT_AGI_SPEED_MULT
	_support_buff_timer = SUPPORT_BUFF_DURATION_SEC
	support_buffs_changed.emit(_support_buff_timer, true)
	# SFX: coloca el archivo en res://audio/sfx/buff_pickup.mp3 — se reproduce vía autoload Audio
	# (no hace falta un AudioStreamPlayer en la cruz ni en el jugador; el pool global de Audio.gd lo gestiona).
	Audio.play_sfx_varied("buff_pickup", 0.95, 1.05)


func get_support_buff_time_left() -> float:
	return _support_buff_timer


func has_active_support_buffs() -> bool:
	return _support_buff_timer > 0.0


func get_energy_coat_values() -> Dictionary:
	return {
		"current": _energy_coat_shield,
		"max": _energy_coat_shield_max,
		"label": "Shield Up" if is_swordman() else "Energy Coat",
	}


func get_spell_pierce_chance() -> float:
	return Global.get_spell_pierce_chance()


func _clear_support_buffs() -> void:
	_support_blessing_mult = 1.0
	_support_agi_mult = 1.0
	_support_buff_timer = 0.0
	support_buffs_changed.emit(0.0, false)


func increase_max_hp(amount: int) -> void:
	max_hp += amount
	current_hp = mini(current_hp + amount, max_hp)
	_refresh_energy_coat_from_run_stats()
	health_changed.emit(current_hp, max_hp)


func increase_move_speed(percent: float) -> void:
	move_speed *= 1.0 + percent


func apply_speed_buff(duration_sec: float, speed_bonus: float = 0.35) -> void:
	if _is_dead:
		return
	_support_agi_mult = maxf(_support_agi_mult, 1.0 + speed_bonus)
	_support_buff_timer = maxf(_support_buff_timer, duration_sec)
	support_buffs_changed.emit(_support_buff_timer, true)
	Audio.play_sfx_varied("buff_pickup", 0.9, 1.1)


func increase_fire_damage(amount: int) -> void:
	fire_bolt_damage += amount
	bash_base_damage += amount


func increase_skill_range(amount: float) -> void:
	skill_range += amount


func upgrade_fire_bolt_level() -> void:
	fire_bolt_level = mini(fire_bolt_level + 1, 3)


func unlock_cold_bolt() -> void:
	cold_bolt_unlocked = true
	_refresh_cold_bolt_timer()


func unlock_thunderstorm() -> void:
	thunderstorm_unlocked = true
	_refresh_thunderstorm_timer()


func unlock_sight() -> void:
	sight_unlocked = true
	if sight_orb and sight_orb.has_method("set_active"):
		sight_orb.set_active(true)


func upgrade_cold_bolt_level() -> void:
	if not cold_bolt_unlocked:
		unlock_cold_bolt()
	cold_bolt_level = mini(cold_bolt_level + 1, _SkillScaling.MAX_SKILL_LEVEL)
	_refresh_cold_bolt_timer()


func upgrade_thunderstorm_level() -> void:
	if not thunderstorm_unlocked:
		unlock_thunderstorm()
	thunderstorm_level = mini(thunderstorm_level + 1, _SkillScaling.MAX_SKILL_LEVEL)


func upgrade_sight_level() -> void:
	if not sight_unlocked:
		unlock_sight()
	sight_level = mini(sight_level + 1, _SkillScaling.MAX_SKILL_LEVEL)


func upgrade_bash_level() -> void:
	bash_level = mini(bash_level + 1, _SwordmanScaling.MAX_LEVEL)


func apply_cooldown_reduction(bonus: float) -> void:
	cooldown_reduction = clampf(cooldown_reduction + bonus, 0.0, 0.9)
	_setup_class_skills()


func _die() -> void:
	_is_dead = true
	if _uses_animation and animated_visual:
		_action_anim_lock = true
		animated_visual.play(&"death")
	for t: Timer in [fire_bolt_timer, cold_bolt_timer, thunderstorm_timer, bash_timer, magnum_timer, regen_timer]:
		if t:
			t.stop()
	if sight_orb and sight_orb.has_method("set_active"):
		sight_orb.set_active(false)
	player_died.emit()
	set_physics_process(false)
	set_process(false)
