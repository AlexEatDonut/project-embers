extends Node3D

@export var healthRatio = 1

#@onready var triggerBox = $entityCollisionHull/CollisionShape3D
@onready var kitSprite = $healthkit_Sprite
@onready var collisionHull = $entityCollisionHull

func _ready():
	pass

func _pickup_healthReturn(healthGiven):
	collisionHull.start_pickupRespawn(8)
	Playerinfo.increase_health(healthGiven, healthRatio)

func _on_entity_collision_hull_body_entered(body: Node3D) -> void:
	if Playerinfo.health < Playerinfo.max_health :
		_pickup_healthReturn(healthRatio)

func _on_entity_collision_hull_pickup_respawn_start() -> void:
	kitSprite.visible = false

func _on_entity_collision_hull_pickup_respawn_end() -> void:
	kitSprite.visible = true
