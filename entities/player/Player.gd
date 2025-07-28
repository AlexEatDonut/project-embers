class_name Player
extends CharacterBody3D

@onready var body = $Body
@onready var head = $Body/Head
@onready var head_position: Vector3 = head.position
@onready var base_camera: Camera3D = $CameraPivot/CameraMarker3D/BaseCamera
@onready var enemy_detector: Area3D = $EnemyDetector
@onready var weapon: Node3D = $Body/Weapon


@onready var slide_direction_3D: Marker3D = $SlideDirection

@onready var sliding_timer: Timer = $SlidingTimer
@onready var slide_cooldown: Timer = $SlideCooldown

@onready var cover_cooldown: Timer = $CoverCooldown

#@onready var weapon: Node3D = $Body/Weapon

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animation_tree: AnimationTree = $AnimationTree

@export var mouse_sensitivity: float = 0.1

#region Hud Variables
@onready var hud_label_health: Label = $"UI_elements/HUD/PlayerInfoPanel/Health&Armor/Health"
@onready var hud_label_armor: Label = $"UI_elements/HUD/PlayerInfoPanel/Health&Armor/Armor"
@onready var hud_label_ammo: Label = $UI_elements/HUD/WeaponInfoPanel/Ammo_frame/Ammocount

@onready var hud_label_reloadtimer: Label = $UI_elements/HUD/WeaponInfoPanel/Ammo_frame/ReloadTimer
@onready var hud_label_state: Label = $UI_elements/HUD/dev_info_box/State
#endregion

#region Cover Raycasts
@onready var n_high: RayCast3D = $CoverRaycasts/NHigh
@onready var s_high: RayCast3D = $CoverRaycasts/SHigh
@onready var e_high: RayCast3D = $CoverRaycasts/EHigh
@onready var w_high: RayCast3D = $CoverRaycasts/WHigh
var cover_surrounding : bool = true
var cover_directions : Array = [false, false, false, false]

#endregion

#region GODETTE_TEST_ANIMS
@onready var godette_model_anims = $Body/godetteModel/AnimationPlayer
#endregion

#region Weapons Variables
var wp_current : WeaponResource = WEAPON_01_TEST
var wp_can_fire : bool = true
var wp_dry_fire : bool = false
var wp_can_reload : bool = false
var wp_is_reloading : bool = false
var wp_current_ammo : int = wp_current.max_mag 

const WEAPON_01_TEST = preload("res://resources/weapons/weapon01_test.tres")
#endregion

@onready var movement_state_machine = $StateMachine

#region Movement Related Variables
@export var ACCELERATION_DEFAULT: float = 10.0
@export var ACCELERATION_AIR: float = 1.0

@export var SPEED_DEFAULT: float = 7.0
@export var SPEED_SHOOTING_DEFAULT: float = snapped(SPEED_DEFAULT * 0.55, 1)
@export var SPEED_SLIDING_DEFAULT: float = snapped(SPEED_DEFAULT * 6, 1) 
@export var SPEED_COVER_DEFAULT: float = snapped(SPEED_DEFAULT * 0.3, 1)
@export var SPEED_COVERSHOOTING_DEFAULT: float = snapped(SPEED_DEFAULT * 0.1, 1)

@export var SPEED_ON_STAIRS: float = 5.0
@export var LOOKING_SPEED: float = 10.0

@export var gravity: float = 9.8
@export var jump: float = 5.0

var acceleration: float = ACCELERATION_DEFAULT
var speed: float = SPEED_DEFAULT
var speed_shooting: float = SPEED_SHOOTING_DEFAULT
var speed_cover: float = SPEED_COVER_DEFAULT
var speed_covershooting: float = SPEED_COVERSHOOTING_DEFAULT
var direction: Vector3 = Vector3.ZERO
var previous_look_direction = Vector3()
var main_velocity: Vector3 = Vector3.ZERO
var gravity_direction: Vector3 = Vector3.ZERO
var movement: Vector3 = Vector3.ZERO
var is_jumping: bool = false
var is_in_air: bool = false
#endregion

#region Stairs Related Variables
const STAIRS_FEELING_COEFFICIENT: float = 2.5
const WALL_MARGIN: float = 0.001
const STEP_DOWN_MARGIN: float = 0.01
const STEP_HEIGHT_DEFAULT: Vector3 = Vector3(0, 0.6, 0)
const STEP_HEIGHT_IN_AIR_DEFAULT: Vector3 = Vector3(0, 0.6, 0)
const STEP_MAX_SLOPE_DEGREE: float = 40.0
const STEP_CHECK_COUNT: int = 2
const SPEED_CLAMP_AFTER_JUMP_COEFFICIENT = 0.4
const SPEED_CLAMP_SLOPE_STEP_UP_COEFFICIENT = 0.4

var step_height_main: Vector3
var step_incremental_check_height: Vector3
var is_enabled_stair_stepping_in_air: bool = true
#endregion

#region Remnant Code from Godot Stairs
var head_offset: Vector3 = Vector3.ZERO
var camera_target_position : Vector3 = Vector3.ZERO
var camera_lerp_coefficient: float = 1.0
var time_in_air: float = 0.0
var update_camera = false
var camera_gt_previous : Transform3D
var camera_gt_current : Transform3D
#endregion

#region Godot Stairs Class
class StepResult:
	var diff_position: Vector3 = Vector3.ZERO
	var normal: Vector3 = Vector3.ZERO
	var is_step_up: bool = false
#endregion

#region Sliding Variables
#SLIDE SPEED VARIABLES
var SLIDE_DECELARATION_DEFAULT : float = 1
var SLIDE_DECELARATION : float = SLIDE_DECELARATION_DEFAULT
var SLIDE_ACCELARATION : float = SPEED_SLIDING_DEFAULT
var slide_velocity: Vector3 = Vector3.ZERO
var default_slide_velocity : Vector3 = Vector3.ZERO
#SLIDE RULE VARIABLES
#is a mix of factors, tells if you are allowed to slide from a mix of reasons
#var slide_elligibility :bool = false 
# slide eligibility was removed due to the new stat system already allowing to filter out is not on floor through lack of code
# and the only var left to care about was is_slide_on_cooldown
#var is_slide_allowed : bool = true
#var is_slide_button_on : bool = false
#var is_player_sliding : bool = false
var is_slide_on_cooldown : bool = false
var last_known_direction = Vector3(1, 0, 1).normalized()
#endregion

#region Variables used by state machine
###Used by COVER state  
##Variable to see how many cover areas you are touching. Used to keep the player in COVER state to avoid cases where the player exits one cover area that was overlapping with another.
var cover_collisions:float = 0
##allows the player to see what cover to prefer when inputting "get into cover" when already in a cover area. 
var last_cover_touched : Area3D
#endregion
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
#these are the states for the weapon.
#this is here to switch it, despite the state variable being in it's own script.
#TODO : Make it functions instead of switching it directly with its enums
#enum wp_states{
	#WP_IDLE,
	#WP_SHOOTING,
	#WP_FIRESTANCE,
	#WP_READY,
	#WP_RELOADING
#}

func _ready():
	default_slide_velocity = main_velocity
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	#Playerinfo.connect("request_player_cover_walk_in", function here)
	Playerinfo.connect("request_player_cover_teleported", attempt_player_cover_teleported)
	Playerinfo.connect("request_player_cover_snapped", attempt_player_cover_snapped)

	Playerinfo.connect("request_player_out_of_cover", attempt_player_escape_cover)
	Playerinfo.connect("health_decreased", hud_update)
	#weapon.connect("shot_fired", hud_update)
	#weapon.connect("start_reloading", reloading_weapon)
	#weapon.connect("request_hud_update", hud_update)
	slide_direction_3D.position = Vector3(5,0,5) 
	
	
	hud_update()
	
func _process(delta: float) -> void:
	#reminder : this is the "every frame, do thing" functions
	#if wp_current_ammo == 0 :
		#wp_dry_fire = true
	#else:
		#wp_dry_fire = false

#	Is time_in_air ever something that is used ? Why would i use that, even for fall damage ?
	if is_on_floor():
		time_in_air = 0.0
	else:
		time_in_air += delta

	enemy_detector.global_position = ScreenPointToRay()
	Playerinfo.playerLocation = global_position
	
	hud_label_reloadtimer.text = str(snapped($Body/Weapon/Reload_timer.time_left, 0.01))
	hud_label_state.text = str($StateMachine.state)

func attempt_player_cover_teleported(destination):
	move_player(destination.global_position, 0.1)
	prevent_all_movement()
	await get_tree().create_timer(0.1).timeout
	Playerinfo.is_behind_cover = true
	cover_cooldown.start()

func attempt_player_cover_snapped(destination):
	Playerinfo.is_behind_cover = true
	move_player(destination.global_position, 0.15)

func move_player(destination, duration):
	var tween := create_tween()
	tween.tween_property(self, ^"position" ,destination ,duration) # take two seconds to move

func attempt_player_escape_cover():
	pass

func hud_update():
	hud_label_health.text = str(Playerinfo.health / 10)
	hud_label_ammo.text = str(wp_current_ammo)
func hud_update_hp():
	hud_label_health.text = str(Playerinfo.health / 10)
#func hud_update_ammo():
	#hud_label_ammo.text = str(weapon.ammo_count)

#func reset_all():
	#animation_player.play("default")
	#Playerinfo.state = NORMAL
	#is_slide_button_on = false
	#Playerinfo.prevent_movement_input = false

func detect_cover():
	cover_directions = [n_high.is_colliding(), e_high.is_colliding(), s_high.is_colliding(),w_high.is_colliding()]
	if n_high.is_colliding() || e_high.is_colliding() || s_high.is_colliding() || w_high.is_colliding():
		cover_surrounding = true
	else:
		cover_surrounding = false
	return(cover_surrounding)
	
func _input(event):
	pass

func _behind_cover():
	animation_player.play("dev_cover")
	#match Playerinfo.state:
		#COVER:
			#pass
		#COVERSHOOTING:
			#pass
	
	
func prevent_all_movement():
	Playerinfo.movement_prevented = true

func ScreenPointToRay():
	var spaceState = get_world_3d().direct_space_state
	var mousePos = get_viewport().get_mouse_position()
	var rayOrigin = base_camera.project_ray_origin(mousePos)
	var rayCollisionMasks: int = 1
	var rayEnd = rayOrigin + base_camera.project_ray_normal(mousePos) * 200
#	lookdirection_raycast_length could be reused later when i find how to take the location where the raycast is at a specific Y coord
	var rayArray = spaceState.intersect_ray(PhysicsRayQueryParameters3D.create(rayOrigin, rayEnd, rayCollisionMasks))

	if rayArray.has("position"):
		var rayHitLocation = rayArray["position"]
		rayHitLocation.y = body.global_transform.origin.y
		previous_look_direction = rayHitLocation
		return rayHitLocation
#		leftover code in case i get lookdirection_raycast_length working as desired
	#else :
		#rayEnd.y = body.global_transform.origin.y
		#return rayEnd
	return previous_look_direction

func _physics_process(delta):
	pass
	##For every state, the player moves at a different speed. 
	##Due to sliding having it's own velocity, every other state NEEDS to have 
	#"movement = main_velocity + gravity_direction"
	##This if is a workaround to avoid typing the thing many times
	##This is sure to bite me in the ass when i need to filter out more than the SLIDING state
	#match Playerinfo.state :
		#SLIDING :
			#slide_velocity = main_velocity.lerp(last_known_direction * (SLIDE_ACCELARATION - SLIDE_DECELARATION), acceleration * delta)
		#NORMAL :
			#main_velocity = main_velocity.lerp(direction * speed, acceleration * delta)
		#RELOADING : 
			#main_velocity = main_velocity.lerp(direction * speed, acceleration * delta)
		#SHOOTING : 
			#main_velocity = main_velocity.lerp(direction * speed_shooting, acceleration * delta)
		#COVER :
			#main_velocity = main_velocity.lerp(direction * speed_cover, acceleration * delta)
		#COVERSHOOTING :
			#main_velocity = main_velocity.lerp(direction * speed_covershooting, acceleration * delta)

func _on_cover_cooldown_timeout() -> void:
	Playerinfo.movement_prevented = false

func _on_slide_cooldown_timeout() -> void:
	is_slide_on_cooldown = false

func _on_hitbox_area_entered(area: Area3D) -> void:

	#print(area.get_parent())
	## We get the parent of the area3D in order to find out if it is a cover system trigger.
	## Then, we act upon this information
	## The goal is to communicate to the state machine for it to actually do what is right
	## 
	#var coverEntity = area.get_parent()
	#if coverEntity.is_in_group("CoverArea"):
		#print(coverEntity)
	var coverEntity = area.get_parent()
	if coverEntity.is_in_group("CoverArea"):
		cover_collisions += 1
		print(cover_collisions)
	
func _on_hitbox_area_exited(area: Area3D) -> void:
	var coverEntity = area.get_parent()
	if coverEntity.is_in_group("CoverArea") :
		cover_collisions -= 1
		print(cover_collisions)


#region Step Check Function Code
func create_step_result():
	var step_result : StepResult = StepResult.new()
	return step_result
	
func create_step_check(delta, is_jumping, step_result):
	var is_step = step_check(delta, is_jumping, step_result)
	return is_step

func step_check(delta: float, is_jumping_: bool, step_result: StepResult):
	var is_step: bool = false
	
	step_height_main = STEP_HEIGHT_DEFAULT
	step_incremental_check_height = STEP_HEIGHT_DEFAULT / STEP_CHECK_COUNT
	if is_in_air and is_enabled_stair_stepping_in_air:
		step_height_main = STEP_HEIGHT_IN_AIR_DEFAULT
		step_incremental_check_height = STEP_HEIGHT_IN_AIR_DEFAULT / STEP_CHECK_COUNT
		
	if gravity_direction.y >= 0:
		for i in range(STEP_CHECK_COUNT):
			var test_motion_result: PhysicsTestMotionResult3D = PhysicsTestMotionResult3D.new()
			
			var step_height: Vector3 = step_height_main - i * step_incremental_check_height
			var transform3d: Transform3D = global_transform
			var motion: Vector3 = step_height
			var test_motion_params: PhysicsTestMotionParameters3D = PhysicsTestMotionParameters3D.new()
			test_motion_params.from = transform3d
			test_motion_params.motion = motion
			
			var is_player_collided: bool = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
			if is_player_collided and test_motion_result.get_collision_normal().y < 0:
				continue

			transform3d.origin += step_height
			motion = main_velocity * delta
			test_motion_params.from = transform3d
			test_motion_params.motion = motion
			
			is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
			
			if not is_player_collided:
				transform3d.origin += motion
				motion = -step_height
				test_motion_params.from = transform3d
				test_motion_params.motion = motion
				
				is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
				
				if is_player_collided:
					if test_motion_result.get_collision_normal().angle_to(Vector3.UP) <= deg_to_rad(STEP_MAX_SLOPE_DEGREE):
						is_step = true
						step_result.is_step_up = true
						step_result.diff_position = -test_motion_result.get_remainder()
						step_result.normal = test_motion_result.get_collision_normal()
						break
			else:
				var wall_collision_normal: Vector3 = test_motion_result.get_collision_normal()
				transform3d.origin += wall_collision_normal * WALL_MARGIN
				motion = (main_velocity * delta).slide(wall_collision_normal)
				test_motion_params.from = transform3d
				test_motion_params.motion = motion
				
				is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
				
				if not is_player_collided:
					transform3d.origin += motion
					motion = -step_height
					test_motion_params.from = transform3d
					test_motion_params.motion = motion
					
					is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
					
					if is_player_collided:
						if test_motion_result.get_collision_normal().angle_to(Vector3.UP) <= deg_to_rad(STEP_MAX_SLOPE_DEGREE):
							is_step = true
							step_result.is_step_up = true
							step_result.diff_position = -test_motion_result.get_remainder()
							step_result.normal = test_motion_result.get_collision_normal()
							break

	if not is_jumping_ and not is_step and is_on_floor():
		step_result.is_step_up = false
		var test_motion_result: PhysicsTestMotionResult3D = PhysicsTestMotionResult3D.new()
		var transform3d: Transform3D = global_transform
		var motion: Vector3 = main_velocity * delta
		var test_motion_params: PhysicsTestMotionParameters3D = PhysicsTestMotionParameters3D.new()
		test_motion_params.from = transform3d
		test_motion_params.motion = motion
		test_motion_params.recovery_as_collision = true

		var is_player_collided: bool = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
			
		if not is_player_collided:
			transform3d.origin += motion
			motion = -step_height_main
			test_motion_params.from = transform3d
			test_motion_params.motion = motion
			
			is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
			
			if is_player_collided and test_motion_result.get_travel().y < -STEP_DOWN_MARGIN:
				if test_motion_result.get_collision_normal().angle_to(Vector3.UP) <= deg_to_rad(STEP_MAX_SLOPE_DEGREE):
					is_step = true
					step_result.diff_position = test_motion_result.get_travel()
					step_result.normal = test_motion_result.get_collision_normal()
		elif is_zero_approx(test_motion_result.get_collision_normal().y):
			var wall_collision_normal: Vector3 = test_motion_result.get_collision_normal()
			transform3d.origin += wall_collision_normal * WALL_MARGIN
			motion = (main_velocity * delta).slide(wall_collision_normal)
			test_motion_params.from = transform3d
			test_motion_params.motion = motion
			
			is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
			
			if not is_player_collided:
				transform3d.origin += motion
				motion = -step_height_main
				test_motion_params.from = transform3d
				test_motion_params.motion = motion
				
				is_player_collided = PhysicsServer3D.body_test_motion(self.get_rid(), test_motion_params, test_motion_result)
				
				if is_player_collided and test_motion_result.get_travel().y < -STEP_DOWN_MARGIN:
					if test_motion_result.get_collision_normal().angle_to(Vector3.UP) <= deg_to_rad(STEP_MAX_SLOPE_DEGREE):
						is_step = true	
						step_result.diff_position = test_motion_result.get_travel()
						step_result.normal = test_motion_result.get_collision_normal()

	return is_step
#endregion
