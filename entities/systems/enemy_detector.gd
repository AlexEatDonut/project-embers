extends Area3D

@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	pass

func _on_body_entered(body: Node3D) -> void:
	var target = body
	if target.is_in_group("NPC"):
		target.enemy_stats.highlighted = true


func _on_body_exited(body: Node3D) -> void:
	var target = body
	if target.is_in_group("NPC"):
		target.enemy_stats.highlighted = false
