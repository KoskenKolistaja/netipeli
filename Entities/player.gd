extends CharacterBody2D

var player_id = 1

const SPEED = 300.0
const JUMP_VELOCITY = -500.0
const WALL_JUMP_VELOCITY = Vector2(350.0, -450.0) # Horizontal push-off and vertical lift
const WALL_SLIDE_GRAVITY = 60.0                   # Reduced gravity when sliding down a wall

func _enter_tree():
	set_multiplayer_authority(int(name))
	player_id = int(name)

func _ready():
	global_position = Vector2(32,544)

func _physics_process(delta):
	if not is_multiplayer_authority():
		return
	
	
	
	if global_position.y > 700:
		global_position = Vector2(32,544)

	# 1. Determine wall slide and wall direction context
	var is_against_wall = is_on_wall_only()
	var direction = Input.get_axis("ui_left", "ui_right")
	
	# Check if player is holding movement *toward* the wall they are touching
	var pushing_against_wall = false
	if is_against_wall and direction != 0:
		# get_wall_normal() points away from the wall. 
		# If pushing into the wall, input direction matches the inverse of the normal.
		var wall_normal = get_wall_normal()
		if (wall_normal.x > 0 and direction < 0) or (wall_normal.x < 0 and direction > 0):
			pushing_against_wall = true

	# 2. Apply Gravity & Wall Sliding
	if not is_on_floor():
		if is_against_wall and pushing_against_wall and velocity.y >= 0:
			# Slide slowly down the wall
			velocity.y += WALL_SLIDE_GRAVITY * delta
		else:
			# Normal gravity
			velocity.y += get_gravity().y * delta

	# 3. Handle Jump & Wall Jump
	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		elif is_against_wall:
			# Wall jump: Kick away from the wall using its normal direction
			var wall_normal = get_wall_normal()
			velocity.x = wall_normal.x * WALL_JUMP_VELOCITY.x
			velocity.y = WALL_JUMP_VELOCITY.y

	# 4. Handle Movement & Deceleration (Slowed down if walking against a wall)
	if direction != 0:
		var current_speed = SPEED
		if is_against_wall and pushing_against_wall:
			current_speed *= 0.4 # Reduce speed down to 40% when grinding/walking into a wall
		velocity.x = direction * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
