extends PlayerState


#region Godot Stairs Class
class StepResult:
	var diff_position: Vector3 = Vector3.ZERO
	var normal: Vector3 = Vector3.ZERO
	var is_step_up: bool = false
#endregion

func enter(previous_state_path: String, data := {}) -> void:
	player.animation_player.play("dev_move")

func physics_update(delta: float) -> void:
	var is_step: bool = false
	var input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	player.direction = Vector3(input.x, 0, input.y).normalized()
	if input != Vector2(0,0):
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

	if player.is_on_floor() and player.is_slide_on_cooldown == false:
		player.slide_elligibility = true
	else:
		player.slide_elligibility = false
	
	var step_result : StepResult = StepResult.new()
	
	is_step = step_check(delta, player.is_jumping, step_result)
	
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

	if Input.is_action_just_pressed("dodge_slide") and player.slide_elligibility == true:
		finished.emit(SLIDING)


#region Step Check Function Code
func step_check(delta: float, is_jumping_: bool, step_result: StepResult):
	var is_step: bool = false
	
	player.step_height_main = player.STEP_HEIGHT_DEFAULT
	player.step_incremental_check_height = player.STEP_HEIGHT_DEFAULT / player.STEP_CHECK_COUNT
	if player.is_in_air and player.is_enabled_stair_stepping_in_air:
		player.step_height_main = player.STEP_HEIGHT_IN_AIR_DEFAULT
		player.step_incremental_check_height = player.STEP_HEIGHT_IN_AIR_DEFAULT / player.STEP_CHECK_COUNT
		
	if player.gravity_direction.y >= 0:
		for i in range(player.STEP_CHECK_COUNT):
			var test_motion_result: PhysicsTestMotionResult3D = PhysicsTestMotionResult3D.new()
			
			var step_height: Vector3 = player.step_height_main - i * player.step_incremental_check_height
			var transform3d: Transform3D = player.global_transform
			var motion: Vector3 = step_height
			var test_motion_params: PhysicsTestMotionParameters3D = PhysicsTestMotionParameters3D.new()
			test_motion_params.from = transform3d
			test_motion_params.motion = motion
			
			var is_player_collided: bool = PhysicsServer3D.body_test_motion(player.get_rid(), test_motion_params, test_motion_result)
			if is_player_collided and test_motion_result.get_collision_normal().y < 0:
				continue

			transform3d.origin += step_height
			motion = player.main_velocity * delta
			test_motion_params.from = transform3d
			test_motion_params.motion = motion
			
			is_player_collided = PhysicsServer3D.body_test_motion(player.get_rid(), test_motion_params, test_motion_result)
			
			if not is_player_collided:
				transform3d.origin += motion
				motion = -step_height
				test_motion_params.from = transform3d
				test_motion_params.motion = motion
				
				is_player_collided = PhysicsServer3D.body_test_motion(player.get_rid(), test_motion_params, test_motion_result)
				
				if is_player_collided:
					if test_motion_result.get_collision_normal().angle_to(Vector3.UP) <= deg_to_rad(player.STEP_MAX_SLOPE_DEGREE):
						is_step = true
						step_result.is_step_up = true
						step_result.diff_position = -test_motion_result.get_remainder()
						step_result.normal = test_motion_result.get_collision_normal()
						break
			else:
				var wall_collision_normal: Vector3 = test_motion_result.get_collision_normal()
				transform3d.origin += wall_collision_normal * player.WALL_MARGIN
				motion = (player.main_velocity * delta).slide(wall_collision_normal)
				test_motion_params.from = transform3d
				test_motion_params.motion = motion
				
				is_player_collided = PhysicsServer3D.body_test_motion(player.get_rid(), test_motion_params, test_motion_result)
				
				if not is_player_collided:
					transform3d.origin += motion
					motion = -step_height
					test_motion_params.from = transform3d
					test_motion_params.motion = motion
					
					is_player_collided = PhysicsServer3D.body_test_motion(player.get_rid(), test_motion_params, test_motion_result)
					
					if is_player_collided:
						if test_motion_result.get_collision_normal().angle_to(Vector3.UP) <= deg_to_rad(player.STEP_MAX_SLOPE_DEGREE):
							is_step = true
							step_result.is_step_up = true
							step_result.diff_position = -test_motion_result.get_remainder()
							step_result.normal = test_motion_result.get_collision_normal()
							break

	if not is_jumping_ and not is_step and player.is_on_floor():
		step_result.is_step_up = false
		var test_motion_result: PhysicsTestMotionResult3D = PhysicsTestMotionResult3D.new()
		var transform3d: Transform3D = player.global_transform
		var motion: Vector3 = player.main_velocity * delta
		var test_motion_params: PhysicsTestMotionParameters3D = PhysicsTestMotionParameters3D.new()
		test_motion_params.from = transform3d
		test_motion_params.motion = motion
		test_motion_params.recovery_as_collision = true

		var is_player_collided: bool = PhysicsServer3D.body_test_motion(player.get_rid(), test_motion_params, test_motion_result)
			
		if not is_player_collided:
			transform3d.origin += motion
			motion = -player.step_height_main
			test_motion_params.from = transform3d
			test_motion_params.motion = motion
			
			is_player_collided = PhysicsServer3D.body_test_motion(player.get_rid(), test_motion_params, test_motion_result)
			
			if is_player_collided and test_motion_result.get_travel().y < -player.STEP_DOWN_MARGIN:
				if test_motion_result.get_collision_normal().angle_to(Vector3.UP) <= deg_to_rad(player.STEP_MAX_SLOPE_DEGREE):
					is_step = true
					step_result.diff_position = test_motion_result.get_travel()
					step_result.normal = test_motion_result.get_collision_normal()
		elif is_zero_approx(test_motion_result.get_collision_normal().y):
			var wall_collision_normal: Vector3 = test_motion_result.get_collision_normal()
			transform3d.origin += wall_collision_normal * player.WALL_MARGIN
			motion = (player.main_velocity * delta).slide(wall_collision_normal)
			test_motion_params.from = transform3d
			test_motion_params.motion = motion
			
			is_player_collided = PhysicsServer3D.body_test_motion(player.get_rid(), test_motion_params, test_motion_result)
			
			if not is_player_collided:
				transform3d.origin += motion
				motion = -player.step_height_main
				test_motion_params.from = transform3d
				test_motion_params.motion = motion
				
				is_player_collided = PhysicsServer3D.body_test_motion(player.get_rid(), test_motion_params, test_motion_result)
				
				if is_player_collided and test_motion_result.get_travel().y < -player.STEP_DOWN_MARGIN:
					if test_motion_result.get_collision_normal().angle_to(Vector3.UP) <= deg_to_rad(player.STEP_MAX_SLOPE_DEGREE):
						is_step = true	
						step_result.diff_position = test_motion_result.get_travel()
						step_result.normal = test_motion_result.get_collision_normal()

	return is_step
#endregion
