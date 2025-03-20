extends Decal

func _ready() -> void:
		self.top_level = true
		#print("spawned a bullet decal")

func cleanup() -> void:
	queue_free()
