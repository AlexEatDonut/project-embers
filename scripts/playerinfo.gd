extends Node

#max health is 1000 cause it's 100 with one decimal
@export var max_health = 1000: 
	set = set_max_health

@export var max_armor = 50:
	set = set_max_armor

@export var godmode : bool = false
@export var intangible : bool = false
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

var armor = max_armor  :
	get: 
		return armor
	set(value): 
		if armor > value:
			emit_signal("health_decreased")
		elif armor < value: 
			emit_signal("health_increased")
		armor = value
		emit_signal("armor_changed", armor)
		if armor <= 0:
			emit_signal("no_armor")

func set_max_health(value):
	max_health = value
	self.health = min (health, max_health)
	emit_signal("max_health_changed", max_health)

func set_max_armor(value):
	max_armor = value
	self.armor = min(armor, max_armor)
	emit_signal("max_armor_changed", max_armor)

func decrease_health(healthTaken, ratio):
	#var predamage_health = health
	if godmode == true or intangible == true:
		ratio = 0

	var healthDamage = healthTaken * ratio
	self.health -= healthDamage
	emit_signal("health_decreased")
	
func increase_health(healthGiven, ratio):
	var prehealing_health = health
	if healthGiven > 0 : 
		#ratio is a percentage from 0 to 1
		var healthBonus = max_health * ratio
		var theorectical_newhealth = health + healthBonus
		health = clamp(theorectical_newhealth, prehealing_health, max_health)
		emit_signal("health_increased")
	else: 
		print("Error ! healthGiven was 0 or lower. Not multiplying to avoid calculus issues.")

signal no_health
signal health_changed(value)
signal max_health_changed(value)

signal no_armor
signal armor_changed(value)
signal max_armor_changed(value)

signal health_decreased
signal health_increased

signal request_dodge_slide_end()
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
	is_behind_cover = true
	match snap_into_cover:
		true:
			emit_signal("request_player_cover_teleported", teleport_location)
		false:
			pass

func _ready():
	self.health = max_health
