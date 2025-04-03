extends Node

@export var strength = 1

@export var max_health = 200: 
	set = set_max_health
@export var close_to_player : bool =  false 
@export var closest_to_player : bool =  false :
	set = set_closest_to_player
@export var highlighted : bool =  false : 
	set = set_highlight
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

func set_closest_to_player(boolean):
		if boolean == true:
			emit_signal("is_closest_to_player")
			closest_to_player = true
		else :
			emit_signal("not_closest_to_player")
			closest_to_player = false

func set_highlight(boolean):
	if boolean == true:
		emit_signal("highlight_on")
		highlighted = true
	else :
		emit_signal("highlight_off")
		highlighted = false

signal no_health
signal health_changed(value)
signal max_health_changed(value)

signal is_closest_to_player
signal not_closest_to_player

signal highlight_on
signal highlight_off

signal lockon_on
signal lockon_off

func _ready():
	self.health = max_health
