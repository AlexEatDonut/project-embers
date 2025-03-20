extends Node3D

@export var WEAPON_INFO : WeaponResource

var readyForFire := true
var deltaTime:float
var state := IDLE 

#preloading the raycast to call upon it later
#@onready var hitscan = preload("res://tscns/generic_hit-hurt_box/raycast3d_hitscan.tscn")
@onready var hitscan = preload("res://entities/systems/projectile_raycast.tscn")

enum{
	IDLE,
	SHOOTING,
	RELOADING
}

@onready var weapon_mesh : MeshInstance3D = %WeaponMesh
@onready var timer = $Timer

func _ready() -> void:
	load_weapon()

func load_weapon() -> void:
	weapon_mesh.mesh = WEAPON_INFO.mesh
	weapon_mesh.position = WEAPON_INFO.position
	weapon_mesh.rotation_degrees = WEAPON_INFO.rotation

func _physics_process(delta: float) -> void:
	deltaTime = delta

func playGunShot():
	var gunShot = preload("res://sounds/weapons/weapon01_test_snd.tscn").instantiate()
	get_tree().current_scene.add_child(gunShot)


func _unhandled_input(event : InputEvent):
	if event.is_action_pressed("shoot"):
		state = SHOOTING
		_weapon_fire(deltaTime)
	if event.is_action_released("shoot"):
		state = IDLE

func _weapon_fire(delta):
	while state == SHOOTING :
		#print(timer.time_left)
		if timer.time_left == 0 :
		#print("shooting with my weapon :)")
			playGunShot()

			var damageHitscan = hitscan.instantiate()
			damageHitscan.player_affiliation = true
			damageHitscan.lingering = false
			damageHitscan.base_damage = WEAPON_INFO.base_damage
			damageHitscan.transform.origin = $hitscanOrigin.transform.origin
			add_child(damageHitscan)
			timer.start(WEAPON_INFO.fire_rate)
			readyForFire = false
		await get_tree().create_timer(delta).timeout


func _on_timer_timeout() -> void:
	readyForFire = true
	timer.stop()
