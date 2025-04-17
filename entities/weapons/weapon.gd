extends Node3D

@export var WEAPON_INFO : WeaponResource

var readyForFire := true
var deltaTime:float
var wp_state := WP_IDLE 

#preloading the raycast to call upon it later
#@onready var hitscan = preload("res://tscns/generic_hit-hurt_box/raycast3d_hitscan.tscn")
@onready var hitscan = preload("res://entities/systems/projectile_raycast.tscn")

enum{
	WP_IDLE,
	WP_SHOOTING,
	WP_READY,
	WP_RELOADING
}

#region Playerinfo States
enum {
	NORMAL,
	SHOOTING,
	RELOADING,
	COVER,
	COVERSHOOTING,
	COVERRELOAD,
	SLIDING,
	STUNNED,
	DYING
}
#endregion

@onready var weapon_mesh : MeshInstance3D = %WeaponMesh
@onready var timer = $Timer
@onready var fire_ready_timer: Timer = $FireReady
@onready var gunShot_sfx

func _ready() -> void:
	load_weapon()

func load_weapon() -> void:
	weapon_mesh.mesh = WEAPON_INFO.mesh
	weapon_mesh.position = WEAPON_INFO.position
	weapon_mesh.rotation_degrees = WEAPON_INFO.rotation

func _physics_process(delta: float) -> void:
	deltaTime = delta

func playGunShot():
	gunShot_sfx = preload("res://sounds/weapons/weapon01_test_snd.tscn").instantiate()
	get_tree().current_scene.add_child(gunShot_sfx)

func wp_fire():
	wp_state = WP_SHOOTING
	_weapon_fire(deltaTime)
	fire_ready_timer.stop()

func _input(event : InputEvent):
	if event.is_action_pressed("shoot"):
		match Playerinfo.state:
			SLIDING:
				pass
			COVER :
				Playerinfo.state = COVERSHOOTING
				wp_fire()
			_:
				Playerinfo.state = SHOOTING
				wp_fire()
	if event.is_action_released("shoot") :
		match Playerinfo.state:
			SLIDING:
				_on_fire_ready_timeout()
			COVER :
				Playerinfo.state = COVER
			COVERSHOOTING :
				Playerinfo.state = COVER
			_:
				pass

		wp_state = WP_READY
		fire_ready_timer.start()
	

func _weapon_fire(delta):
	while wp_state == WP_SHOOTING :
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

func _on_fire_ready_timeout() -> void:
	wp_state = WP_IDLE
	match Playerinfo.state:
		SHOOTING:
			Playerinfo.state = NORMAL
		COVER:
			Playerinfo.state = COVER
		COVERSHOOTING:
			Playerinfo.state = COVER
		SLIDING:
			pass
		_:
			Playerinfo.state = NORMAL
