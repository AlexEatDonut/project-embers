extends Node3D

@export var parent = CharacterBody3D
@export var WEAPON_INFO : WeaponResource



@onready var wall_raycast: RayCast3D = $WallRaycast

#preloading the raycasts to call upon them later
@onready var hitscan = preload("res://entities/systems/raycast3d_hitscan.tscn")
@onready var hitscan_projectile = preload("res://entities/systems/projectile_raycast.tscn")

@onready var weapon_mesh : MeshInstance3D = %WeaponMesh
@onready var fire_rate_timer = $FireRateTimer
@onready var firing_stance_timer: Timer = $FiringStance
@onready var reload_timer: Timer = $Reload_timer
@onready var gunShot_sfx
@onready var reload_sfx

var wp_current : WeaponResource

var readyForFire := true
var deltaTime:float
var wp_state := WP_IDLE 
var is_hugging_wall : bool = false
var damageHitscan
var first_shot : bool = false #for debug, false on default
var successive_shots : float = 0

enum{
	WP_IDLE,
	WP_SHOOTING,
	WP_FIRESTANCE,
	WP_READY,
	WP_RELOADING
}
#these are the states for the player.
#this is here to switch it, despite the state variable being in it's own script.
#TODO : Make it functions instead of switching it directly with its enums
#region Playerinfo States
#enum {
	#NORMAL,
	#SHOOTING,
	#RELOADING,
	#COVER,
	#COVERSHOOTING,
	#COVERRELOAD,
	#SLIDING,
	#STUNNED,
	#DYING
#}
#endregion

func _ready() -> void:
	#load_weapon()
	wp_current = parent.wp_current
	weapon_mesh.mesh = wp_current.mesh

func _process(delta: float) -> void:
	if wall_raycast.is_colliding():
		is_hugging_wall = true
	else:
		is_hugging_wall = false
	
	if parent.wp_current_ammo > 0:
		parent.wp_dry_fire = false
	elif parent.wp_current_ammo <= 0:
		parent.wp_dry_fire = true
	
	if parent.wp_is_reloading == false and parent.wp_current_ammo != wp_current.max_mag :
		parent.wp_can_reload = true
	else:
		parent.wp_can_reload = false

func _physics_process(delta: float) -> void:
	deltaTime = delta

func playGunShot():
	gunShot_sfx = preload("res://sounds/weapons/weapon01_test_snd.tscn").instantiate()
	get_tree().current_scene.add_child(gunShot_sfx)

func playDryFire():
	gunShot_sfx = preload("res://sounds/weapons/weapon_dry_fire.tscn").instantiate()
	get_tree().current_scene.add_child(gunShot_sfx)

func playReloadSfx():
	reload_sfx = preload("res://sounds/weapons/weapon_reload_pistol_01.tscn").instantiate()
	get_tree().current_scene.add_child(reload_sfx)

func wp_fire():
	if wp_state != WP_RELOADING:
		if parent.wp_can_fire == true:
			wp_state = WP_SHOOTING
			_weapon_fire(deltaTime)
			firing_stance_timer.stop()

func wp_reload_handler(isManual : bool):
	stop_wp_firing()
	if parent.wp_can_reload == true and parent.wp_is_reloading == false or isManual == false :
		parent.wp_can_fire = false
		#Playerinfo.state = RELOADING
		wp_state = WP_RELOADING
		firing_stance_timer.stop()
		fire_rate_timer.stop()
		parent.wp_is_reloading = true
		wp_reload()
	else:
		return


func wp_reload():
	playReloadSfx()
	firing_stance_timer.stop()
	reload_timer.start(wp_current.reload_speed)

func _input(event : InputEvent):
	if event.is_action_pressed("shoot"):
		#match Playerinfo.state:
			#SLIDING:
				#pass
			#COVER :
				#Playerinfo.state = COVERSHOOTING
				#wp_fire()
			#_:
				#Playerinfo.state = SHOOTING
				wp_fire()
	if event.is_action_released("shoot") :
		stop_wp_firing()
	if event.is_action_pressed("reload"):
		wp_reload_handler(true)

func _weapon_fire(delta):
	while wp_state == WP_SHOOTING :
		if fire_rate_timer.time_left == 0 and parent.wp_can_fire == true and parent.wp_dry_fire == false:
			playGunShot()
			spawn_raycast()
			fire_rate_timer.start(wp_current.fire_rate)
			readyForFire = false
			parent.wp_current_ammo -= wp_current.fire_cost
			parent.hud_update()
			parent.wp_can_fire = false
		elif fire_rate_timer.time_left == 0 and parent.wp_can_fire == true and parent.wp_dry_fire == true:
			playDryFire()
			fire_rate_timer.start(wp_current.fire_rate)
			readyForFire = false
			parent.wp_can_fire = false
		await get_tree().create_timer(delta).timeout


func spawn_raycast():
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
	add_child(damageHitscan)
	
	#how add spread ? who knows ? not me yet
	#var rng = RandomNumberGenerator.new()
	#var spread_y : float = rng.randf_range(wp_current.spread * -1, wp_current.spread)
	#var spread_x : float = rng.randf_range(wp_current.spread * -1, wp_current.spread)
	#damageHitscan.transform.rotation += Vector3(spread_x, spread_y, 0)

func stop_wp_firing():
	#match Playerinfo.state:
		#SLIDING:
			#_on_firing_stance_timeout()
		#COVER :
			#Playerinfo.state = COVER
		#COVERSHOOTING :
			#Playerinfo.state = COVER
		#_:
			#pass
	wp_state = WP_READY
	firing_stance_timer.start()

func _on_fire_rate_timer_timeout() -> void:
		readyForFire = true
		parent.wp_can_fire = true
		fire_rate_timer.stop()

func _on_firing_stance_timeout() -> void:
	wp_state = WP_IDLE
	#match Playerinfo.state:
		#SHOOTING:
			#Playerinfo.state = NORMAL
		#COVER:
			#Playerinfo.state = COVER
		#COVERSHOOTING:
			#Playerinfo.state = COVER
		#SLIDING:
			#pass
		#_:
			#Playerinfo.state = NORMAL
	if parent.wp_dry_fire == true and fire_rate_timer.time_left == 0 and parent.wp_can_fire == true:
		wp_reload_handler(false)


func _on_reload_timer_timeout() -> void:
	parent.wp_current_ammo = wp_current.max_mag
	parent.hud_update()
	parent.wp_can_fire = true
	parent.wp_is_reloading = false
	wp_state = WP_READY
	firing_stance_timer.start()

signal start_reloading()
signal shot_fired()

signal ammo_changed()
signal no_ammo()
