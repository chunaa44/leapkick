extends CharacterBody2D

@export var player_id = 1
@export var facing = 1   # 1 = facing right, -1 = facing left
@export var character = 0   # 0 = Striker, 1 = Rusher, 2 = Skyfall

const GRAVITY = 1800.0

# players can't leave this x range
const LEFT_LIMIT = 60.0
const RIGHT_LIMIT = 1220.0

# the recovery animation is 4 frames at 10 fps = 0.4 seconds
const RECOVERY_ANIM_TIME = 0.4

# these are filled in by set_character()
var char_name = ""
var body_color = Color(1, 1, 1)
var jump_y = 0.0
var back_hop_x = 0.0
var back_hop_y = 0.0
var dive_x = 0.0
var dive_y = 0.0
var recovery_time = 0.0

var is_diving = false
var frozen = false
var recovery_left = 0.0
var start_position = Vector2.ZERO
var start_facing = 1
var foot_base_x = 0.0

@onready var sprite = $Sprite
@onready var body_shape = $CollisionShape2D
@onready var foot_box = $FootBox
@onready var foot_shape = $FootBox/CollisionShape2D
@onready var hit_burst = $HitBurst

func _ready():
	start_position = global_position
	start_facing = facing

	# the foot box is placed in the editor for the right-facing pose,
	# we only mirror it when facing left
	foot_base_x = foot_box.position.x
	update_foot_side()

	set_character(character)

func set_character(id):
	character = id

	if id == 0:
		# Striker: balanced, 45 degree dive
		char_name = "Striker"
		body_color = Color(0.3, 0.6, 1.0)
		jump_y = -1000.0
		back_hop_x = 250.0
		back_hop_y = -500.0
		dive_x = 600.0
		dive_y = 600.0
		recovery_time = 0.3
	elif id == 1:
		# Rusher: low jump, fast shallow dive, long recovery
		char_name = "Rusher"
		body_color = Color(1.0, 0.6, 0.2)
		jump_y = -800.0
		back_hop_x = 300.0
		back_hop_y = -450.0
		dive_x = 800.0
		dive_y = 500.0
		recovery_time = 0.4
	else:
		# Skyfall: very high jump, steep dive, short reach, short recovery
		char_name = "Skyfall"
		body_color = Color(0.4, 0.9, 0.4)
		jump_y = -1250.0
		back_hop_x = 150.0
		back_hop_y = -450.0
		dive_x = 350.0
		dive_y = 800.0
		recovery_time = 0.2

	# all characters share one sprite, so a light tint tells them apart
	# (mixed halfway with white so the art doesn't get too dark)
	var tint = body_color.lerp(Color(1, 1, 1), 0.5)
	if player_id == 2:
		# player 2 is darker so mirror matches are readable
		tint = tint.darkened(0.3)
	sprite.self_modulate = tint

	hit_burst.color = body_color

	sprite.play("idle")

func update_foot_side():
	foot_box.position.x = foot_base_x * facing

func body_rect():
	var size = body_shape.shape.size
	return Rect2(body_shape.global_position - size / 2, size)

func foot_rect():
	var size = foot_shape.shape.size
	return Rect2(foot_shape.global_position - size / 2, size)

func face_towards(other_x):
	# you can only turn around while standing on the ground and free to act
	if is_on_floor() == false or is_diving or recovery_left > 0:
		return

	if other_x > global_position.x:
		facing = 1
	elif other_x < global_position.x:
		facing = -1
	update_foot_side()

func update_animation():
	var anim = "idle"
	if is_diving:
		anim = "dive"
	elif is_on_floor() == false:
		if velocity.y < 0:
			anim = "rise"
		else:
			anim = "fall"
	elif recovery_left > 0:
		anim = "recovery"

	# only restart the animation when the state actually changes
	if sprite.animation != anim:
		sprite.play(anim)

		# stretch or squash the recovery animation to match this
		# character's recovery time
		if anim == "recovery":
			sprite.speed_scale = RECOVERY_ANIM_TIME / recovery_time
		else:
			sprite.speed_scale = 1.0

	# art is drawn facing right, so flip it when facing left
	sprite.flip_h = (facing == -1)

func _physics_process(delta):
	# nobody moves between the kill and the next round
	if frozen:
		return

	var dive_pressed = Input.is_action_just_pressed("p" + str(player_id) + "_dive")
	var kick_pressed = Input.is_action_just_pressed("p" + str(player_id) + "_kick")

	if is_on_floor():
		if is_diving:
			# just landed from a dive, stuck for a moment
			is_diving = false
			recovery_left = recovery_time

		velocity.x = 0

		if recovery_left > 0:
			recovery_left -= delta
		elif dive_pressed:
			# jump straight up
			velocity.y = jump_y
			Sfx.play("jump")
		elif kick_pressed:
			# hop backward
			velocity.x = -back_hop_x * facing
			velocity.y = back_hop_y
	else:
		if kick_pressed and is_diving == false:
			# kick in the air: dive down and forward
			is_diving = true
			velocity.x = dive_x * facing
			velocity.y = dive_y
			Sfx.play("dive")
		elif is_diving == false:
			velocity.y += GRAVITY * delta

	move_and_slide()

	global_position.x = clamp(global_position.x, LEFT_LIMIT, RIGHT_LIMIT)

	update_animation()

func reset():
	global_position = start_position
	velocity = Vector2.ZERO
	is_diving = false
	frozen = false
	recovery_left = 0.0
	facing = start_facing
	update_foot_side()
	update_animation()
