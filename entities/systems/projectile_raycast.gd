extends RayCast3D

@export var bullet_speed : float = 50
@export var base_damage = 5
@export var player_affiliation : bool
@export var lingering : bool

@onready var gpu_trail_3d: GPUTrail3D = $GPUTrail3D
@onready var checker_timer: Timer = $CheckerTimer

@onready var remote_transform := RemoteTransform3D.new()
@onready var mesh = $MeshInstance3D
@onready var bullet_decal = preload("res://entities/decals/bullet_decal.tscn")

var target

#code imported from raycast hitbox
#signal collide_world()
signal collide_body(collider)

func _ready() -> void:
	self.top_level = true
	position += (global_basis * Vector3.FORWARD) * -0.7

func _physics_process(delta: float) -> void:
	position += global_basis * Vector3.FORWARD * bullet_speed * delta
	target_position = Vector3.FORWARD * bullet_speed * delta
	force_raycast_update()
	target = get_collider()
	if is_colliding():
		if not target.is_in_group("Client"):
			var bullet_hole = bullet_decal.instantiate()
			var pt = get_collision_point()
			var nrml = get_collision_normal()
			global_position = get_collision_point()
			create_bullethole(bullet_hole, target)
			BulletDecalPool.spawn_bullet_decal(pt, nrml, target )
			set_physics_process(false)
			emit_signal("collide_body", target)
			if lingering == true :
				target.add_child(remote_transform)
				remote_transform.global_transform = global_transform
				remote_transform.remote_path = remote_transform.get_path_to(self)
				remote_transform.tree_exited.connect(_cleanup)
			else :
				_cleanup()

func create_bullethole(bh, target):
	var root = get_tree().current_scene
	root.add_child(bh)
	bh.global_transform.origin = get_collision_point()
	#if get_collision_normal() == Vector3(1,0,0):
		#bh.look_at(get_collision_point() + get_collision_normal(), Vector3.RIGHT)
	#elif get_collision_normal() == Vector3(-1,0,0):
		#bh.look_at(get_collision_point() + get_collision_normal(), Vector3.RIGHT)
	#else:
		#bh.look_at(get_collision_point() + get_collision_normal())

func _cleanup() -> void:
	queue_free()


func _on_collide_body(collider: Variant) -> void:
	#this is a hacky way to get around the hitbox system i have put in place. 
	#I should call upon signals or some other ways later 
	var target = collider.get_parent_node_3d() 
	if target.is_in_group("NPC") && player_affiliation == true :
		#bullet deals damage to enemies
		target._decrease_health(base_damage)
	if target.is_in_group("Client") && player_affiliation == false :
		#bullet deals damage to player and NPC
		pass


func _on_checker_timer_timeout() -> void:
	gpu_trail_3d.emitting = true
