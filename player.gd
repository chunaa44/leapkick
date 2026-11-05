extends CharacterBody2D

@export var player_id = 1
@export var facing = 1   # 1 = facing right, -1 = facing left
@export var character = 0   # 0 = Striker, 1 = Rusher, 2 = Skyfall

const GRAVITY = 1800.0

# players can't leave this x range
const LEFT_LIMIT = 60.0
const RIGHT_LIMIT = 1220.0

# hit rectangles (body size must match the collision shape)
const BODY_SIZE = Vector2(40, 80)
const FOOT_SIZE = Vector2(40, 40)
const FOOT_OFFSET = Vector2(30, 30)

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
var foot_visual = null

func _ready():
	start_position = global_position
	start_facing = facing

	# red rectangle that shows the foot hit area while diving
	foot_visual = ColorRect.new()
	foot_visual.color = Color(1, 0, 0, 0.7)
	foot_visual.size = FOOT_SIZE
	foot_visual.visible = false
	add_child(foot_visual)
	update_foot_visual_position()

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

	# player 2 is a darker shade so mirror matches are readable
	if player_id == 1:
		$ColorRect.color = body_color
	else:
		$ColorRect.color = body_color.darkened(0.35)

func update_foot_visual_position():
	foot_visual.position = Vector2(FOOT_OFFSET.x * facing, FOOT_OFFSET.y) - FOOT_SIZE / 2

func body_rect():
	return Rect2(global_position - BODY_SIZE / 2, BODY_SIZE)

func foot_rect():
	var center = global_position + Vector2(FOOT_OFFSET.x * facing, FOOT_OFFSET.y)
	return Rect2(center - FOOT_SIZE / 2, FOOT_SIZE)

func face_towards(other_x):
	# you can only turn around while standing on the ground and free to act
	if is_on_floor() == false or is_diving or recovery_left > 0:
		return

	if other_x > global_position.x:
		facing = 1
	elif other_x < global_position.x:
		facing = -1
	update_foot_visual_position()

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
		elif is_diving == false:
			velocity.y += GRAVITY * delta

	move_and_slide()

	global_position.x = clamp(global_position.x, LEFT_LIMIT, RIGHT_LIMIT)

	foot_visual.visible = is_diving

	# gray tint while stuck in recovery
	if recovery_left > 0:
		$ColorRect.modulate = Color(0.5, 0.5, 0.5)
	else:
		$ColorRect.modulate = Color(1, 1, 1)

func reset():
	global_position = start_position
	velocity = Vector2.ZERO
	is_diving = false
	frozen = false
	recovery_left = 0.0
	facing = start_facing
	update_foot_visual_position()
	foot_visual.visible = false
