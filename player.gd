extends CharacterBody2D

@export var player_id = 1
@export var facing = 1   # 1 = facing right, -1 = facing left

const GRAVITY = 900.0
const JUMP_X = 250.0
const JUMP_Y = -450.0
const BACK_HOP_X = 200.0
const BACK_HOP_Y = -250.0
const DIVE_X = 300.0
const DIVE_Y = 500.0

# hit rectangles (body size must match the collision shape)
const BODY_SIZE = Vector2(40, 80)
const FOOT_SIZE = Vector2(40, 40)
const FOOT_OFFSET = Vector2(30, 30)

var is_diving = false
var frozen = false
var start_position = Vector2.ZERO
var foot_visual = null

func _ready():
	start_position = global_position

	# red rectangle that shows the foot hit area while diving
	foot_visual = ColorRect.new()
	foot_visual.color = Color(1, 0, 0, 0.7)
	foot_visual.size = FOOT_SIZE
	foot_visual.position = Vector2(FOOT_OFFSET.x * facing, FOOT_OFFSET.y) - FOOT_SIZE / 2
	foot_visual.visible = false
	add_child(foot_visual)

func body_rect():
	return Rect2(global_position - BODY_SIZE / 2, BODY_SIZE)

func foot_rect():
	var center = global_position + Vector2(FOOT_OFFSET.x * facing, FOOT_OFFSET.y)
	return Rect2(center - FOOT_SIZE / 2, FOOT_SIZE)

func _physics_process(delta):
	# nobody moves between the kill and the next round
	if frozen:
		return

	var dive_pressed = Input.is_action_just_pressed("p" + str(player_id) + "_dive")
	var kick_pressed = Input.is_action_just_pressed("p" + str(player_id) + "_kick")

	if is_on_floor():
		is_diving = false
		velocity.x = 0

		if dive_pressed:
			# jump forward
			velocity.x = JUMP_X * facing
			velocity.y = JUMP_Y
		elif kick_pressed:
			# hop backward
			velocity.x = -BACK_HOP_X * facing
			velocity.y = BACK_HOP_Y
	else:
		if kick_pressed and is_diving == false:
			# kick in the air: dive down and forward
			is_diving = true
			velocity.x = DIVE_X * facing
			velocity.y = DIVE_Y
		elif is_diving == false:
			velocity.y += GRAVITY * delta

	move_and_slide()

	foot_visual.visible = is_diving

func reset():
	global_position = start_position
	velocity = Vector2.ZERO
	is_diving = false
	frozen = false
	foot_visual.visible = false
