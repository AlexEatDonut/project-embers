extends AudioStreamPlayer

var rng = RandomNumberGenerator.new()

func _ready() -> void:
	var pitchRandomizer = rng.randf_range(0.9, 1.1)
	pitch_scale=pitchRandomizer

func _on_finished():
	queue_free()
