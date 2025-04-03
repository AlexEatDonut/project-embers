#extends StateMachine
extends CharacterBody3D

@onready var stats = $EnemyStats
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var highlight_indicator: Node3D = $Body/HighlightIndicator
@onready var lock_on_indicator: Node3D = $Body/LockOnIndicator

@onready var projectile = preload("res://entities/systems/projectile_raycast.tscn")
@onready var enemy_detector = preload("res://entities/systems/enemy_detector.tscn")
@onready var enemy_stats: Node = $EnemyStats

@onready var character_mesh: MeshInstance3D = $Body/MeshInstance3D
@onready var body: Node3D = $Body

@onready var ray_to_player: RayCast3D = $RayToPlayer
@onready var line_of_sight_ray: RayCast3D = $Body/LineOfSight/LineOfSightRay
@onready var bullet_spawn_location: Marker3D = $Body/BulletSpawnLocation

@onready var shoot_timer = $ShootTimer
@onready var reaction_time: Timer = $ReactionTime

@export var outline_material : Material

@export var alert_rotation_speed : Vector3 = Vector3(0, 50, 0)

var target
var lookat_target

const TURN_SPEED = 3

enum {
	IDLE,
	ALERT,
	STAREDOWN,
	ATTACKING,
	DYING
}

var state = IDLE

func _ready():
	pass

func _process(delta):
	match state:
		IDLE:
			pass
		ALERT:
			print("enemy alerted")
			looking_around(delta)
		STAREDOWN:
			look_at_player(target)
			
		ATTACKING:
			look_at_player(target)
			
		DYING:
			pass

func look_at_player(target):
	body.look_at(target.global_transform.origin, Vector3.UP)
	#ray_to_player.target_position = Playerinfo.playerLocation

func looking_around(delta):
	rotation_degrees += alert_rotation_speed  * delta

#region ADDITIONAL STAREDOWN CODE

#endregion


#region HEALTH RELATED CODE
func _decrease_health(value):
	stats.health -= value
	print("enemy lost health")
	#the game attempts to start a grace period but fails due to the raycast still being in his hitbox, 
	#preventing any changes to the monitoring to happen
		#TODO : Find a way to accomplish this idea
		#hitbox.start_graceperiod(1)
		#print("processed starting graceperiod of 1 sec")


func _on_enemy_stats_no_health() -> void:
	#create_death_effect() 
	#aka create effects on death lmao
	state = DYING
	animation_player.play("death")
#endregion



func _on_enemy_stats_health_changed(value: Variant) -> void:
	# check if health got bigger or lower, then do things accordingly with other signals
	pass
func _on_animation_finished(anim_name: StringName) -> void:
		if anim_name == "death" :
			queue_free()


#region #RANGE CHECKS
func _on_awareness_range_body_entered(body: Node3D) -> void:
		if body.is_in_group("Client"):
			target = body
			state = STAREDOWN
			shoot_timer.start()
func _on_awareness_range_body_exited(body: Node3D) -> void:
	state = IDLE
	shoot_timer.stop()


func _on_sight_range_body_entered(body: Node3D) -> void:
	if body.is_in_group("Client"):
		target = body
		state = ALERT
		shoot_timer.start()

func _on_sight_range_body_exited(body: Node3D) -> void:
	state = IDLE
	shoot_timer.stop()
#endregion

func _on_enemy_stats_highlight_on() -> void:
	highlight_indicator.visible = true
	character_mesh.material_overlay = outline_material


func _on_enemy_stats_highlight_off() -> void:
	highlight_indicator.visible = false
	character_mesh.material_overlay = null

func _on_shoot_timer_timeout() -> void:
	if line_of_sight_ray.is_colliding():
		var target = line_of_sight_ray.get_collider()
		if target.is_in_group("Client"):
			var bullet = projectile.instantiate()
			bullet.bullet_speed = 45
			bullet.player_affiliation = false
			bullet_spawn_location.add_child(bullet)
