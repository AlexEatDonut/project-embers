extends AudioStreamPlayer

@export var  pitch_custom_lowest : float = 1
@export var pitch_custom_highest : float = 1
@export var volume_custom : float = 0

var rng = RandomNumberGenerator.new()

func _ready() -> void:
	if pitch_custom_lowest != pitch_custom_highest :
		pitch_scale = rng.randf_range(pitch_custom_lowest, pitch_custom_highest)
	
func _on_finished() -> void:
	self.stop()
