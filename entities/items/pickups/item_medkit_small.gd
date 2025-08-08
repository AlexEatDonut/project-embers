extends Node3D



@export var healthRatio = 0.25

#@onready var triggerBox = $entityCollisionHull/CollisionShape3D
@onready var kitSprite = $healthkit_Sprite
@onready var collisionHull = $entityCollisionHull
@onready var kit_respawn_timer: Timer = $kit_respawn_timer

@onready var item_respawn_sfx: AudioStreamPlayer = $item_respawn_sfx
@onready var item_pickup_sfx: AudioStreamPlayer = $item_pickup_sfx

@onready var canInteract = true

func _ready():
	pass

func _pickup_healthReturn(healthGiven):
	Playerinfo.increase_health(healthGiven, healthRatio)

func _on_entity_collision_hull_body_entered(body: Node3D) -> void:
	if Playerinfo.health < Playerinfo.max_health :
		_pickup_healthReturn(healthRatio)
		item_pickup_sfx.play()
		canInteract = false
		_on_pickup_respawn_start()

func _on_pickup_respawn_start() -> void:
	kitSprite.visible = false
	kit_respawn_timer.start()

func _on_pickup_respawn_end() -> void:
	kitSprite.visible = true
	canInteract = true
	kit_respawn_timer.stop()
	item_respawn_sfx.play()

func _on_kit_respawn_timer_timeout() -> void:
	_on_pickup_respawn_end()
