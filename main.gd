extends Node2D

const WIN_SCORE = 5

var score1 = 0
var score2 = 0
var round_active = true
var shake = 0.0

@onready var camera = $Camera2D
@onready var p1_name = %P1Name
@onready var p1_pips = %P1Pips
@onready var p2_name = %P2Name
@onready var p2_pips = %P2Pips
@onready var message_label = %MessageLabel
@onready var win_screen = %WinScreen
@onready var winner_label = %WinnerLabel
@onready var rematch_button = %RematchButton

func _ready():
	# run after the players have moved this frame
	process_physics_priority = 1
	update_score("")

func _process(delta):
	# shake fades out on its own
	shake = move_toward(shake, 0.0, 60.0 * delta)
	camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake

func _input(event):
	# pick characters between rounds: 1/2/3 for player 1, 7/8/9 for player 2
	if round_active == false:
		return
	if event is InputEventKey and event.pressed and event.echo == false:
		var changed = true
		if event.keycode == KEY_1:
			$Player1.set_character(0)
		elif event.keycode == KEY_2:
			$Player1.set_character(1)
		elif event.keycode == KEY_3:
			$Player1.set_character(2)
		elif event.keycode == KEY_7:
			$Player2.set_character(0)
		elif event.keycode == KEY_8:
			$Player2.set_character(1)
		elif event.keycode == KEY_9:
			$Player2.set_character(2)
		else:
			changed = false

		if changed:
			# restart the round so nobody is stuck mid-air with new stats
			start_new_round()

func _physics_process(delta):
	if round_active == false:
		return

	$Player1.face_towards($Player2.global_position.x)
	$Player2.face_towards($Player1.global_position.x)

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

	# effects run alongside the timers below
	play_hit_effects(p1_was_hit, p2_was_hit, game_over)

	# the last "true" makes this timer ignore the slow-mo
	await get_tree().create_timer(1.0, true, false, true).timeout

	if game_over:
		# stay frozen and let the player choose
		winner_label.text = message
		win_screen.visible = true
		rematch_button.grab_focus()
	else:
		start_new_round()
func play_hit_effects(p1_was_hit, p2_was_hit, big):
	# screen shake, bigger on the final kill
	shake = 24.0 if big else 14.0

	if p1_was_hit:
		hit_flash($Player1)
	if p2_was_hit:
		hit_flash($Player2)

	# hit-stop: a very short slow-motion freeze that sells the impact
	Engine.time_scale = 0.1
	await get_tree().create_timer(0.15, true, false, true).timeout
	Engine.time_scale = 1.0

	# flash is over, back to normal color
	$Player1.sprite.modulate = Color.WHITE
	$Player2.sprite.modulate = Color.WHITE

func hit_flash(player):
	player.sprite.modulate = Color(4, 4, 4)
	player.hit_burst.restart()

func start_new_round():
	Engine.time_scale = 1.0
	$Player1.sprite.modulate = Color.WHITE
	$Player2.sprite.modulate = Color.WHITE
	$Player1.reset()
	$Player2.reset()
	round_active = true
	update_score("")

func update_score(message):
	p1_name.text = $Player1.char_name
	p2_name.text = $Player2.char_name
	p1_pips.text = make_pips(score1)
	p2_pips.text = make_pips(score2)
	message_label.text = message

	# name color matches the character's color
	p1_name.add_theme_color_override("font_color", $Player1.body_color)
	p2_name.add_theme_color_override("font_color", $Player2.body_color)

func make_pips(score):
	# filled circles for points won, empty ones for points left
	return "●".repeat(score) + "○".repeat(WIN_SCORE - score)


func _on_rematch_button_pressed():
	score1 = 0
	score2 = 0
	win_screen.visible = false
	start_new_round()

func _on_menu_button_pressed():
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://main_menu.tscn")
