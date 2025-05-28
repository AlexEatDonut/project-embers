extends Node3D

func _ready() -> void:
	pass



func _on_dev_map_pressed() -> void:
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://maps/devroom-embers.tscn")


func _on_quit_game_pressed() -> void:
		await get_tree().create_timer(0.3).timeout
		get_tree().quit()
