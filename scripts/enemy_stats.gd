extends Node

@export var strength = 1

@export var max_health = 200: 
	set = set_max_health
@export var closest_to_player : bool =  false 
@export var highlighted : bool =  false 
@export var locked_on : bool =  false 

var health = max_health  :
	get: 
		return health
	set(value): 
		health = value
		emit_signal("health_changed", health)
		if health <= 0:
			emit_signal("no_health")

func set_max_health(value):
	max_health = value
	self.health = min (health, max_health)
	emit_signal("max_health_changed", max_health)

signal no_health
signal health_changed(value)
signal max_health_changed(value)

func _ready():
	self.health = max_health
