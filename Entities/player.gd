extends CharacterBody2D

## Identifier for multiplayer authority assignment.
var player_id: int = 1

const SPEED = 350.0
const JUMP_VELOCITY = -700.0
const WALL_JUMP_VELOCITY = Vector2(450.0, -500.0)
const WALL_SLIDE_GRAVITY = 100.0
const JUMP_CUT_RATIO = 0.5
const COYOTE_TIME = 0.12 ## Time in seconds the player can jump after leaving a ledge

const ACCELERATION = 6800.0
const FRICTION = 6000.0
const AIR_ACCELERATION = 6000.0
const AIR_FRICTION = 6000.0

var coyote_timer: float = 0.0
var current_anim: String = ""
var current_flip: bool = false

var inactive = true

func _enter_tree() -> void:
	set_multiplayer_authority(int(name))
	global_position = Vector2(32, 544)
	player_id = int(name)

func _ready() -> void:
	global_position = Vector2(32, 544)
	%AnimatedSprite2D.speed_scale = 4.0
	await get_tree().create_timer(1.0).timeout
	global_position = Vector2(32, 544)
	inactive = false

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority() or inactive:
		return

	if global_position.y > 700:
		global_position = Vector2(32, 544)

	var is_against_wall = is_on_wall_only()
	var direction = Input.get_axis("ui_left", "ui_right")

	# Update coyote timer
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer = max(0.0, coyote_timer - delta)

	var pushing_against_wall = false
	if is_against_wall and direction != 0:
		var wall_normal = get_wall_normal()
		pushing_against_wall = (wall_normal.x > 0 and direction < 0) or (wall_normal.x < 0 and direction > 0)

	# Gravity & Wall Sliding
	if not is_on_floor():
		if is_against_wall and pushing_against_wall and velocity.y >= 0:
			velocity.y += WALL_SLIDE_GRAVITY * delta
		else:
			velocity.y += get_gravity().y * 2.0 * delta

	# Jump & Wall Jump
	if Input.is_action_just_pressed("ui_up"):
		if coyote_timer > 0.0:
			velocity.y = JUMP_VELOCITY
			coyote_timer = 0.0
		elif is_against_wall:
			var wall_normal = get_wall_normal()
			velocity.x = wall_normal.x * WALL_JUMP_VELOCITY.x
			velocity.y = WALL_JUMP_VELOCITY.y

	# Partial Jump (Variable Jump Height)
	if Input.is_action_just_released("ui_up") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT_RATIO

	# Inertia & Movement
	var target_speed = direction * SPEED
	if is_against_wall and pushing_against_wall:
		target_speed *= 0.4

	var accel = ACCELERATION if is_on_floor() else AIR_ACCELERATION
	var decel = FRICTION if is_on_floor() else AIR_FRICTION

	if direction != 0:
		velocity.x = move_toward(velocity.x, target_speed, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, decel * delta)

	move_and_slide()
	_update_and_sync_animations()

func _update_and_sync_animations() -> void:
	var new_flip = current_flip
	if velocity.x > 10.0:
		new_flip = false
	elif velocity.x < -10.0:
		new_flip = true

	var new_anim = "idle"
	if not is_on_floor():
		if velocity.y < 0:
			new_anim = "jump"
		else:
			new_anim = "fall" if %AnimatedSprite2D.animation == "fall" and %AnimatedSprite2D.is_playing() else "fall_loop"
	else:
		new_anim = "run" if abs(velocity.x) > 20.0 else "idle"

	if new_anim != current_anim or new_flip != current_flip:
		current_anim = new_anim
		current_flip = new_flip
		_apply_visuals(current_anim, current_flip)
		sync_visuals.rpc(current_anim, current_flip)

## Updates sprite properties locally for remote peers.
@rpc("authority", "call_remote", "reliable")
func sync_visuals(anim_name: String, flip: bool) -> void:
	_apply_visuals(anim_name, flip)

func _apply_visuals(anim_name: String, flip: bool) -> void:
	%AnimatedSprite2D.flip_h = flip
	if %AnimatedSprite2D.animation != anim_name:
		%AnimatedSprite2D.play(anim_name)
