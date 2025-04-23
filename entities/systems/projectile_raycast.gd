extends RayCast3D

@export var bullet_speed : float = 50
@export var base_damage = 50
@export var player_affiliation : bool
@export var lingering : bool

@onready var gpu_trail_3d: GPUTrail3D = $GPUTrail3D
@onready var checker_timer: Timer = $CheckerTimer

@onready var remote_transform := RemoteTransform3D.new()
@onready var mesh = $MeshInstance3D
@onready var bullet_decal = preload("res://entities/decals/bullet_decal.tscn")

var target

func _ready() -> void:
	self.top_level = true

func _physics_process(delta: float) -> void:
	position += global_basis * Vector3.FORWARD * bullet_speed * delta
	target_position = Vector3.FORWARD * bullet_speed * delta
	force_raycast_update()
	target = get_collider()
	if is_colliding():
		_on_collide_body(target)
		if not target.is_in_group("Client") || not target.is_in_group("NPC"):
			var bullet_hole = bullet_decal.instantiate()
			var pt = get_collision_point()
			var nrml = get_collision_normal()
			global_position = get_collision_point()
			BulletDecalPool.spawn_bullet_decal(pt, nrml, target )
			set_physics_process(false)
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

func _cleanup() -> void:
	queue_free()

func _on_collide_body(collider: Variant) -> void:
	var collider_parent = collider.get_parent_node_3d() 
	if collider_parent.is_in_group("NPC"):
		match player_affiliation:
			true : 
				collider_parent._decrease_health(base_damage)
	elif collider.is_in_group("Client"):
		match player_affiliation:
			false:
				Playerinfo.decrease_health(base_damage,1)

func _on_checker_timer_timeout() -> void:
	gpu_trail_3d.emitting = true
