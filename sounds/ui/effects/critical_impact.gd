extends AudioStreamPlayer

var rng = RandomNumberGenerator.new()

func _ready() -> void:
	var pitchRandomizer = rng.randf_range(0.7, 1.3)
	pitch_scale=pitchRandomizer

func _on_finished():
	queue_free()
