class_name PlayerState extends State

const IDLE = "Idle"
const MOVING = "Moving"
const SLIDING = "Sliding"
const FALLING = "Falling"
#TODO add the missing states

var player: Player

func _ready() -> void:
	await owner.ready
	player = owner as Player
	assert(player != null, "The PlayerState state type must be used only in the player scene. It needs the owner to be a Player node.")
