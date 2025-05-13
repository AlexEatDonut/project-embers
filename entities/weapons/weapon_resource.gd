class_name WeaponResource
extends Resource

@export_category("Weapon data")
@export var name : StringName
@export var description : StringName
@export var weapon_type : StringName
@export var fire_sound : PackedScene
@export var dry_fire_sound : PackedScene
@export var price : float

@export_category("Weapon stats")
@export var base_damage : float
@export var accuracy_factor : float
@export var fire_cost : float
@export var first_shot_accuracy : float
@export var fall_off_range : float
@export var fire_rate : float
@export var mag_size : float
@export var reload_speed : float
@export var weight : float
@export var run_gun : float
@export var dual_wield : bool
@export var firing_mode : StringName

@export_category("Weapon Positionning")
@export var position : Vector3
@export var rotation : Vector3
@export var scale : Vector3

@export_category("Visual settings")
@export var mesh : Mesh
