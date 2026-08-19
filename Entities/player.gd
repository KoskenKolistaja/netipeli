extends CharacterBody2D

var player_id = 1

# Higher top speed to match the 4.0x animation speed
const SPEED = 450.0
const JUMP_VELOCITY = -550.0
const WALL_JUMP_VELOCITY = Vector2(450.0, -500.0)
const WALL_SLIDE_GRAVITY = 100.0

# Momentum / Inertia Parameters
const ACCELERATION = 3800.0      # How fast you reach top speed on ground
const FRICTION = 3200.0          # How fast you slide to a stop on ground
const AIR_ACCELERATION = 2000.0   # Control strength while airborne
const AIR_FRICTION = 1000.0       # Air resistance (preserves jump momentum)

# Track visual states to detect changes
var current_anim: String = ""
var current_flip: bool = false

func _enter_tree():
	set_multiplayer_authority(int(name))
	player_id = int(name)

func _ready():
	global_position = Vector2(32, 544)
	# Set base sprite speed scale to match fast movement
	%AnimatedSprite2D.speed_scale = 4.0

func _physics_process(delta):
	if is_multiplayer_authority():
		if global_position.y > 700:
			global_position = Vector2(32, 544)

		var is_against_wall = is_on_wall_only()
		var direction = Input.get_axis("ui_left", "ui_right")

		# Check if player is pushing into a wall
		var pushing_against_wall = false
		if is_against_wall and direction != 0:
			var wall_normal = get_wall_normal()
			if (wall_normal.x > 0 and direction < 0) or (wall_normal.x < 0 and direction > 0):
				pushing_against_wall = true

		# Gravity & Wall Sliding
		if not is_on_floor():
			if is_against_wall and pushing_against_wall and velocity.y >= 0:
				velocity.y += WALL_SLIDE_GRAVITY * delta
			else:
				velocity.y += get_gravity().y * delta

		# Jump & Wall Jump
		if Input.is_action_just_pressed("ui_accept"):
			if is_on_floor():
				velocity.y = JUMP_VELOCITY
			elif is_against_wall:
				var wall_normal = get_wall_normal()
				velocity.x = wall_normal.x * WALL_JUMP_VELOCITY.x
				velocity.y = WALL_JUMP_VELOCITY.y

		# --- Inertia & Acceleration Logic ---
		var target_speed = direction * SPEED
		if is_against_wall and pushing_against_wall:
			target_speed *= 0.4 # Reduced max speed grinding against a wall

		# Select acceleration/deceleration rates based on ground vs air
		var accel = ACCELERATION if is_on_floor() else AIR_ACCELERATION
		var decel = FRICTION if is_on_floor() else AIR_FRICTION

		if direction != 0:
			# Smoothly ramp up velocity toward target speed
			velocity.x = move_toward(velocity.x, target_speed, accel * delta)
		else:
			# Smoothly bleed off velocity (sliding/coasting stop)
			velocity.x = move_toward(velocity.x, 0, decel * delta)

		move_and_slide()
		
		# Check and broadcast animation changes
		_update_and_sync_animations()

# --- Animation & Networking Sync ---

func _update_and_sync_animations() -> void:
	# Determine flip direction based on actual movement velocity
	var new_flip = current_flip
	if velocity.x > 10.0:
		new_flip = false
	elif velocity.x < -10.0:
		new_flip = true

	# Determine animation state
	var new_anim = "idle"
	if not is_on_floor():
		if velocity.y < 0:
			new_anim = "jump"
		else:
			if %AnimatedSprite2D.animation == "fall" and %AnimatedSprite2D.is_playing():
				new_anim = "fall"
			else:
				new_anim = "fall_loop"
	else:
		if abs(velocity.x) > 20.0:
			new_anim = "run"
		else:
			new_anim = "idle"

	# Only send RPC if animation state or flip direction actually changed
	if new_anim != current_anim or new_flip != current_flip:
		current_anim = new_anim
		current_flip = new_flip
		
		_apply_visuals(current_anim, current_flip)
		sync_visuals.rpc(current_anim, current_flip)

@rpc("authority", "call_remote", "reliable")
func sync_visuals(anim_name: String, flip: bool) -> void:
	_apply_visuals(anim_name, flip)

func _apply_visuals(anim_name: String, flip: bool) -> void:
	%AnimatedSprite2D.flip_h = flip
	if %AnimatedSprite2D.animation != anim_name:
		%AnimatedSprite2D.play(anim_name)
