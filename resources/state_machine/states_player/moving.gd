extends PlayerState

func enter(previous_state_path: String, data := {}) -> void:
	player.animation_player.play("dev_move")

func physics_update(delta: float) -> void:
	
	player.body.look_at(player.ScreenPointToRay(), Vector3.UP)
	
	var is_step: bool = false
	var input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	player.direction = Vector3(input.x, 0, input.y).normalized()
	if input != Vector2(0,0):
		player.slide_direction_3D.position = Vector3((input.x*5), 0, (input.y*5))
		player.last_known_direction = player.direction
	elif input == Vector2(0,0):
		finished.emit(IDLE)

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
	
	player.main_velocity = player.main_velocity.lerp(player.direction * player.speed, player.acceleration * delta)
	player.movement = player.main_velocity + player.gravity_direction
	
	
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
	
	if Input.is_action_just_pressed("dodge_slide") and player.is_slide_on_cooldown == false:
		finished.emit(SLIDING)
