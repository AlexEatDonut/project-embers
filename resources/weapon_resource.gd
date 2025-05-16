class_name WeaponResource
extends Resource

enum WeaponType{
	HG,
	SMG,
	AR,
	SG,
	LMG,
	HE,
	MELEE,
	MISC
}

enum FireMode{
	AUTOMATIC,
	SEMIAUTO,
	BURSTFIRE,
	PUMPACTION,
	BOLTACTION
}

@export_category("Weapon data")
@export var name : StringName
@export var description : StringName
@export var weapon_type : WeaponType
@export var price : float

@export_category("Weapon data")
@export var firing_sounds : PackedScene
@export var reload_sound : PackedScene
@export var dry_fire_sound : PackedScene = preload("res://sounds/weapons/weapon_dry_fire.tscn")

@export_category("Weapon stats")
@export var base_damage : float
@export var fire_cost : float

@export var spread : float
@export var first_shot_accuracy : float
@export var fall_off_range : float
@export var spread_recovery : float

@export var fire_rate : float = 0.2 #seconds
@export var burst_delay : float = 0.2 #seconds, only applies if the firemode is BURST FIRE. Is the delay between bursts.
@export var burst_count : float = 3 #amount of shots fired per bursts
@export var max_mag : float

@export var bullet_count : float = 1 #amount of bullets fired. IE : multiple for shotguns
@export var reload_speed : float
@export var weight : float
@export var run_gun : float
@export var dual_wield : bool
@export var firing_mode : FireMode

@export_category("Weapon Positionning")
@export var position : Vector3
@export var rotation : Vector3
@export var scale : Vector3

@export_category("Visual settings")
@export var mesh : Mesh
@export var sway : float = 0.15
