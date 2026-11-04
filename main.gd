extends Node2D

const WIN_SCORE = 5

var score1 = 0
var score2 = 0
var round_active = true

func _ready():
	# run after the players have moved this frame
	process_physics_priority = 1
	update_score("")

func _physics_process(delta):
	if round_active == false:
		return

	var p1_was_hit = false
	var p2_was_hit = false

	if $Player1.is_diving and $Player1.foot_rect().intersects($Player2.body_rect()):
		p2_was_hit = true
	if $Player2.is_diving and $Player2.foot_rect().intersects($Player1.body_rect()):
		p1_was_hit = true

	if p1_was_hit or p2_was_hit:
		end_round(p1_was_hit, p2_was_hit)

func end_round(p1_was_hit, p2_was_hit):
	round_active = false
	$Player1.frozen = true
	$Player2.frozen = true

	var message = ""
	if p1_was_hit and p2_was_hit:
		message = "Trade! No points"
	elif p1_was_hit:
		score2 += 1
		message = "Player 2 scores"
	else:
		score1 += 1
		message = "Player 1 scores"

	var game_over = false
	if score1 >= WIN_SCORE:
		message = "PLAYER 1 WINS!"
		game_over = true
	elif score2 >= WIN_SCORE:
		message = "PLAYER 2 WINS!"
		game_over = true

	update_score(message)

	if game_over:
		await get_tree().create_timer(3.0).timeout
		score1 = 0
		score2 = 0
	else:
		await get_tree().create_timer(1.0).timeout

	start_new_round()

func start_new_round():
	$Player1.reset()
	$Player2.reset()
	round_active = true
	update_score("")

func update_score(message):
	$ScoreLabel.text = str(score1) + " - " + str(score2) + "\n" + message
