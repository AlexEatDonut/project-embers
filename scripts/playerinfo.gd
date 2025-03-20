extends Node

#im unsure if/how im going to implement weapon types and different ammo capacity
#lightround would be for low damage pistols and smgs
#mid round would be for more medium damage guns
#heavyrounds would be for revolvers, high damage handgun (handcannons, if you will) and even shotguns. 
@export var ammoTypesMax := {
	"lightRound" : 80, 
	"midRound" : 60,
	"heavyRound" : 30
}

@export var max_health = 100: 
	set = set_max_health

@export var godmode : bool = false

var playerIsDead : bool = false

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

func _ready():
	self.health = max_health
