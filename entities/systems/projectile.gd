extends RigidBody3D

enum {
	ENEMY,
	PLAYER
}

@onready var hurtbox = $hurtbox

@export var hurt_player : bool

#var shoot = false
var damage
@export var SPEED = 10

func _ready():
	damage = hurtbox.damage
	self.top_level=true
	
func _physics_process(delta: float) -> void:
	position += global_basis * Vector3.FORWARD * SPEED * delta


func _on_timer_timeout() -> void:
	queue_free()


func _on_hurtbox_body_entered(body: Node3D) -> void:
	var target = body.get_parent_node_3d() 
	match hurt_player:
		false:
			if target.is_in_group("Player"):
				#target.player_take_damage(hurtbox.damage)
				#queue_free()
				print("hit a player")
			queue_free()
		true:
			#if target.is_in_group("Enemy"):
				#target._decrease_health(hurtbox.damage)
				#queue_free()
			queue_free()
	queue_free()
