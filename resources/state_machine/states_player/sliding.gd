extends PlayerState

var slide_direction
var input


func enter(previous_state_path: String, data := {}) -> void:
	on_dodge_slide_start()
	player.debug_tick_sliding()
	input = Vector2(0,0)
	#player.animation_player.play("dev_slide")
	player.godette_model_anims.play("sit")
	slide_direction = player.slide_direction_3D.position
	player.body.look_at(player.transform.origin + slide_direction, Vector3.UP)

func on_dodge_slide_start():
	player.SLIDE_ACCELARATION = player.SPEED_SLIDING_DEFAULT
	player.slide_velocity = player.default_slide_velocity
	player.is_slide_on_cooldown = true
	## how long the slide is (0.7s)
	player.sliding_timer.start() 
	## how long before can do another slide (1s)
	player.slide_cooldown.start()
	#Playerinfo.snap_into_cover = true

func on_dodge_slide_end():

		Playerinfo.intangible = false
		if input != Vector2(0,0):
			finished.emit(IDLE)
		else:
			finished.emit(MOVING)

func physics_update(delta: float) -> void:
	Playerinfo.intangible = true
	#if player.slide_direction != Vector3(0,0,0) :
			#if !player.global_transform.origin.is_equal_approx(player.slide_direction) :
				#player.body.look_at(player.transform.origin + player.slide_direction, Vector3.UP)
	
	input = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	var is_step: bool = false

	if player.is_on_floor():
		player.is_jumping = false
		player.is_in_air = false
		player.acceleration = player.ACCELERATION_DEFAULT
		player.gravity_direction = Vector3.ZERO
	elif not player.is_on_floor():
		finished.emit(FALLING)
	
	var step_result = player.create_step_result()
	is_step = player.create_step_check(delta, player.is_jumping, step_result)
	
	if is_step:
		var is_enabled_stair_stepping: bool = true
		if step_result.is_step_up and player.is_in_air and not player.is_enabled_stair_stepping_in_air:
			is_enabled_stair_stepping = false

		if is_enabled_stair_stepping:
			player.global_transform.origin += step_result.diff_position
			player.speed = player.SPEED_ON_STAIRS

	else:
		player.head_offset = player.head_offset.lerp(Vector3.ZERO, delta * player.speed * player.STAIRS_FEELING_COEFFICIENT)
		
		if abs(player.head_offset.y) <= 0.01:
			player.speed = player.SPEED_DEFAULT
	
	player.slide_velocity = player.main_velocity.lerp(player.last_known_direction * player.SLIDE_ACCELARATION, player.acceleration * delta)
	player.SLIDE_ACCELARATION -= player.SLIDE_DECELARATION
	player.movement = player.slide_velocity + player.gravity_direction
	
	if not Playerinfo.movement_prevented:
		player.set_velocity(player.movement)
		player.set_max_slides(6)
		player.move_and_slide()
	else:
		player.movement = Vector3.ZERO
		player.set_velocity(player.movement)
		player.set_max_slides(6)
		player.move_and_slide()
	
	if is_step and step_result.is_step_up and player.is_enabled_stair_stepping_in_air:
		if player.is_in_air or player.direction.dot(step_result.normal) > 0:
			player.main_velocity *= player.SPEED_CLAMP_AFTER_JUMP_COEFFICIENT
			player.gravity_direction *= player.SPEED_CLAMP_AFTER_JUMP_COEFFICIENT

	if player.is_jumping:
		player.is_jumping = false
		player.is_in_air = true


func _on_sliding_timer_timeout() -> void:
	on_dodge_slide_end()

#this was a signal connector
func _on_cover_area_entered(area: Area3D) -> void:
	var coverEntity = area.get_parent()
	if coverEntity.is_in_group("CoverArea"):
		print(coverEntity)
		print("i should be in sliding rn")
