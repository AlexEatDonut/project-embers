extends RayCast3D

@export var bullet_speed : float = 0
@export var base_damage = 50
@export var player_affiliation : bool
@export var lingering : bool

@onready var bullet_decal = preload("res://entities/decals/bullet_decal.tscn")

var hasTriggered:bool = false

func _ready() -> void:
	target_position.z = bullet_speed * -1
	self.top_level = true
	if is_colliding():
		hasTriggered = true
	await get_tree().create_timer(0.1).timeout
	hasTriggered = true
	await get_tree().create_timer(3).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	if hasTriggered != true:
		force_raycast_update()
		if is_colliding():
			var bullet_hole = bullet_decal.instantiate()
			var target = get_collider()
			var pt = get_collision_point()
			var nrml = get_collision_normal()
			create_bullethole(bullet_hole, target)
			BulletDecalPool.spawn_bullet_decal(pt, nrml, target )
			hasTriggered = true
	else :
		set_physics_process(false)

func create_bullethole(bh, target):
	var root = get_tree().current_scene
	root.add_child(bh)
	bh.global_transform.origin = get_collision_point()

func _on_collide_body(collider: Variant) -> void:
	var target = collider.get_parent_node_3d() 
	if target.is_in_group("NPC"):
		target._decrease_health(base_damage)
