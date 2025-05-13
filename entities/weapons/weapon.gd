extends Node3D

@export var WEAPON_INFO : WeaponResource

var readyForFire := true
var deltaTime:float
var wp_state := WP_IDLE 
var is_hugging_wall : bool = false
var damageHitscan

@onready var wall_raycast: RayCast3D = $WallRaycast

#preloading the raycasts to call upon it later
@onready var hitscan = preload("res://entities/systems/raycast3d_hitscan.tscn")
@onready var hitscan_projectile = preload("res://entities/systems/projectile_raycast.tscn")

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
@onready var fire_rate_timer = $FireRateTimer
@onready var fire_ready_timer: Timer = $FireReady
@onready var reload_timer: Timer = $Reload_timer
@onready var gunShot_sfx

@export var max_ammo_count : float:
	set = set_max_ammo_count

var ammo_count = max_ammo_count  :
	get: 
		return ammo_count
	set(value): 
		if ammo_count > value:
			#emit_signal("health_decreased")
			pass
		elif ammo_count < value: 
			#emit_signal("health_increased")
			pass
		ammo_count = value
		emit_signal("ammo_changed", ammo_count)
		if ammo_count <= 0:
			emit_signal("no_ammo")
			reload_wp_state()
		print(ammo_count)

func set_max_ammo_count(value):
	max_ammo_count = value
	self.ammo_count = min(ammo_count, max_ammo_count)
	#if value > 0 :
		#max_ammo_count = value
	#elif value <= 0 :
		#state = RELOADING
		#emit_signal("start_reloading")

func decrease_ammo_count(fireCost):
	ammo_count = clamp(ammo_count - fireCost, 0, max_ammo_count)
	


func _ready() -> void:
	load_weapon()

func _process(delta: float) -> void:
	if wall_raycast.is_colliding():
		is_hugging_wall = true
	else:
		is_hugging_wall = false
	
	

func load_weapon() -> void:
	weapon_mesh.mesh = WEAPON_INFO.mesh
	weapon_mesh.position = WEAPON_INFO.position
	weapon_mesh.rotation_degrees = WEAPON_INFO.rotation
	set_max_ammo_count(WEAPON_INFO.mag_size)
	reload_timer.wait_time = WEAPON_INFO.reload_speed
	emit_signal("request_hud_update")

func _physics_process(delta: float) -> void:
	deltaTime = delta

func playGunShot():
	gunShot_sfx = preload("res://sounds/weapons/weapon01_test_snd.tscn").instantiate()
	get_tree().current_scene.add_child(gunShot_sfx)

func wp_fire():
	if wp_state != WP_RELOADING:
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
		stop_wp_firing()
	if event.is_action_pressed("reload"):
		stop_wp_firing()
		reload_wp_state()

func _weapon_fire(delta):
	while wp_state == WP_SHOOTING :
		if fire_rate_timer.time_left == 0 :
			playGunShot()
			if is_hugging_wall == true:
				damageHitscan = hitscan.instantiate()
				damageHitscan.bullet_speed = 1
			else:
				damageHitscan = hitscan_projectile.instantiate()
				damageHitscan.bullet_speed = 50
			damageHitscan.player_affiliation = true
			damageHitscan.lingering = false
			damageHitscan.base_damage = WEAPON_INFO.base_damage
			damageHitscan.transform.origin = $hitscanOrigin.transform.origin
			emit_signal("shot_fired")
			add_child(damageHitscan)
			fire_rate_timer.start(WEAPON_INFO.fire_rate)
			decrease_ammo_count(WEAPON_INFO.fire_cost)
			readyForFire = false
		await get_tree().create_timer(delta).timeout

func stop_wp_firing():
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

func _on_fire_rate_timer_timeout() -> void:
		readyForFire = true
		fire_rate_timer.stop()

func reload_wp_state():
	fire_ready_timer.stop()
	wp_state = WP_RELOADING
	reload_timer.start()
	emit_signal("start_reloading")

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


func _on_reload_timer_timeout() -> void:
	ammo_count = max_ammo_count
	emit_signal("request_hud_update")
	wp_state = WP_READY
	fire_ready_timer.start()

func _on_spawn_timer_timeout() -> void:
	emit_signal("request_hud_update")

signal start_reloading()
signal shot_fired()

signal ammo_changed()
signal no_ammo()
signal request_hud_update()
