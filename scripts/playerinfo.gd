extends Node

#im unsure if/how im going to implement weapon types and different ammo capacity
#lightround would be for low damage pistols and smgs
#mid round would be for more medium damage guns
#heavyrounds would be for revolvers, high damage handgun (handcannons, if you will) and even shotguns. 

@export var max_health = 100: 
	set = set_max_health

@export var godmode : bool = false
var playerIsDead : bool = false

var cover_tracker = 0 :
	set = set_cover_tracker
var snap_into_cover : bool = true
var currently_sliding : bool = false

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

func set_cover_tracker(is_increase):
	#true = augmenter ; false = réduire
	if is_increase == true :
		cover_tracker += 1
		print("cover tracker increased")
	elif is_increase == false :
		cover_tracker -= 1
		print("cover tracker decreased")
	else :
		print("error, parsed not-a-boolean in place of the boolean ")

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

signal request_player_teleport(node_destination)
signal request_player_cover()

func cover_handler(teleport_location:Marker3D, area_trigger:Area3D):
	match [area_trigger.name,snap_into_cover]:
		["CoverArea", true]:
			#hitting large hitbox with snapping on.
			#We do the thing : we snap the player into place and put him into the cover state. 
			#We stop the shooting, we stop the sliding and give the player back controls after a cooldown
			emit_signal("request_player_teleport", teleport_location)
			emit_signal("request_player_cover")
		["CoverArea", false]:
			pass
			#hitting large hitbox with snapping off.
			#We don't snap the player into the cover, but we change a variable to be able to 
			#turn the sliding into just a button to get into cover
		["SnapArea", true]:
			pass
			#hitting small hitbox with snapping on.
			#if it's on, it doesn't matter, it's going to be like the false one anyway. 
			#If your snapping is on, you might be already in the bigger hitbox at this point
			#do nothing
		["SnapArea", false]:
			pass
			#hitting small hitbox with snapping off.
			#We do the thing : we snap the player into place and put him into the cover state. 
			#We stop the shooting, we stop the sliding and give the player back controls after a cooldown

func place_player_into_cover():
	pass

func _ready():
	self.health = max_health
	print(player_character)
