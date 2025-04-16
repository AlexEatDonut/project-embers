extends Node

#im unsure if/how im going to implement weapon types and different ammo capacity
#lightround would be for low damage pistols and smgs
#mid round would be for more medium damage guns
#heavyrounds would be for revolvers, high damage handgun (handcannons, if you will) and even shotguns. 

@export var max_health = 100: 
	set = set_max_health

@export var godmode : bool = false
var playerIsDead : bool = false

var snap_into_cover : bool = true
var is_behind_cover : bool = false :
	set = set_behind_cover

var playerLocation

var locked_on : bool = false
var locked_on_location

enum {
	NORMAL,
	SHOOTING,
	RELOADING,
	COVER,
	COVERSHOOTING,
	COVERRELOAD,
	SLIDING,
	STUNNED,
	DYING
}

var state = NORMAL

@onready var player_character = get_tree().get_root().find_children("Player")

var prevent_movement_input : bool = false
var movement_prevented: bool = false

var health = max_health  :
	get: 
		return health
	set(value): 
		if health > value:
			#emit_signal("health_decreased")
			pass
		elif health < value: 
			#emit_signal("health_increased")
			pass
		health = value
		emit_signal("health_changed", health)
		if health <= 0:
			emit_signal("no_health")

func set_max_health(value):
	max_health = value
	self.health = min (health, max_health)
	emit_signal("max_health_changed", max_health)

func decrease_health(healthTaken, ratio):
	#var predamage_health = Playerinfo.health
	var healthDamage = healthTaken * ratio
	Playerinfo.health -= healthDamage
	emit_signal("health_decreased")
	
func increase_health(healthGiven, ratio):
	var prehealing_health = Playerinfo.health
	if healthGiven > 0 : 
		#ratio is a percentage from 0 to 1
		var healthBonus = max_health * ratio
		var theorectical_newhealth = Playerinfo.health + healthBonus
		Playerinfo.health = clamp(theorectical_newhealth, prehealing_health, Playerinfo.max_health)
		emit_signal("health_increased")
	else: 
		print("Error ! healthGiven was 0 or lower. Not multiplying to avoid calculus issues.")

signal no_health
signal health_changed(value)
signal health_decreased
signal health_increased
signal max_health_changed(value)

signal request_dodge_slide_end()
signal request_player_cover_walk_in()
signal request_player_cover_teleported(node_destination)
signal request_player_cover_snapped(node_destination)
signal request_player_out_of_cover()

func set_behind_cover(newBool):
	match newBool :
		true:
			state = COVER
		false:
			emit_signal("request_player_out_of_cover")

func cover_snapper(teleport_location:Marker3D):
	match snap_into_cover:
		true:
			#hitting large hitbox with snapping on.
			#We do the thing : we snap the player into place and put him into the cover state. 
			#We stop the shooting, we stop the sliding and give the player back controls after a cooldown
			emit_signal("request_dodge_slide_end")
			emit_signal("request_player_cover_snapped", teleport_location)
		false:
			pass
			#hitting large hitbox with snapping off.
			#We don't snap the player into the cover, but we change a variable to be able to 
			#turn the sliding into just a button to get into cover


func cover_handler(teleport_location:Marker3D):
	print(snap_into_cover)
	is_behind_cover = true
	match snap_into_cover:
		true:
			emit_signal("request_player_cover_teleported", teleport_location)
		false:
			pass
			#emit_signal("request_player_cover_walk_in")
	
	#emit_signal("request_player_cover_teleported")

func _ready():
	self.health = max_health
	print(player_character)
