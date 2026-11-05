extends Node2D

const WIN_SCORE = 5
const ROUND_TIME = 20.0

# the red line shows up when this many seconds are left
const LINE_TIME = 5.0

# middle of the arena (players move between x = 60 and x = 1220)
const CENTER_X = 640.0

var score1 = 0
var score2 = 0
var round_number = 1
var round_active = false
var shake = 0.0
var time_left = ROUND_TIME

# goes up every time a round intro starts (or a round ends), so an
# old intro can tell that something newer has taken over
var intro_token = 0

@onready var camera = $Camera2D
@onready var center_line = %CenterLine
@onready var p1_name = %P1Name
@onready var p1_pips = %P1Pips
@onready var p2_name = %P2Name
@onready var p2_pips = %P2Pips
@onready var timer_label = %TimerLabel
@onready var banner_label = %BannerLabel
@onready var p1_popup = %P1ScorePopup
@onready var p2_popup = %P2ScorePopup
@onready var win_screen = %WinScreen
@onready var winner_label = %WinnerLabel
@onready var rematch_button = %RematchButton

func _ready():
	# run after the players have moved this frame
	process_physics_priority = 1
	start_new_round()

func _process(delta):
	# shake fades out on its own
	shake = move_toward(shake, 0.0, 60.0 * delta)
	camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake

func _input(event):
	# pick characters: 1/2/3 for player 1, 7/8/9 for player 2
	# (only while a round is being fought, not during the intro)
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

	# count the round clock down
	time_left -= delta
	update_timer_label()

	# the red line appears for the last seconds
	if time_left <= LINE_TIME:
		center_line.visible = true

	# "lost" means this player got hit and lost the round
	var p1_lost = false
	var p2_lost = false

	if $Player1.is_diving and $Player1.foot_rect().intersects($Player2.body_rect()):
		p2_lost = true
	if $Player2.is_diving and $Player2.foot_rect().intersects($Player1.body_rect()):
		p1_lost = true

	if p1_lost or p2_lost:
		end_round(p1_lost, p2_lost, false)
	elif time_left <= 0:
		end_by_decision()

func end_by_decision():
	# time is up and nobody got hit: the player closest to the center wins
	var dist1 = abs($Player1.global_position.x - CENTER_X)
	var dist2 = abs($Player2.global_position.x - CENTER_X)

	if abs(dist1 - dist2) < 1.0:
		# same distance (within a pixel): draw, both lose the round
		end_round(true, true, true)
	elif dist1 < dist2:
		# player 1 is closer, so player 2 loses
		end_round(false, true, true)
	else:
		end_round(true, false, true)

func end_round(p1_lost, p2_lost, timed_out):
	round_active = false
	$Player1.frozen = true
	$Player2.frozen = true

	# stops a round intro that is still running from hiding the banner
	intro_token += 1

	if p1_lost and p2_lost:
		# both lost: nobody scores
		if timed_out:
			show_banner("DRAW!", Color(1, 0.85, 0.3))
		else:
			show_banner("TRADE!", Color(1, 0.85, 0.3))
	elif p1_lost:
		score2 += 1
		show_score_popup(p2_popup, $Player2.body_color)
		if timed_out:
			show_banner("TIME UP!", Color(1, 0.85, 0.3))
	else:
		score1 += 1
		show_score_popup(p1_popup, $Player1.body_color)
		if timed_out:
			show_banner("TIME UP!", Color(1, 0.85, 0.3))

	var winner_text = ""
	var game_over = false
	if score1 >= WIN_SCORE:
		winner_text = "PLAYER 1 WINS!"
		game_over = true
	elif score2 >= WIN_SCORE:
		winner_text = "PLAYER 2 WINS!"
		game_over = true

	update_score()

	# a time up has no hit, so it gets no shake or flash
	if timed_out == false:
		play_hit_effects(p1_lost, p2_lost, game_over)

	# the last "true" makes this timer ignore the slow-mo
	await get_tree().create_timer(1.0, true, false, true).timeout

	if game_over:
		# stay frozen and let the player choose
		winner_label.text = winner_text
		win_screen.visible = true
		rematch_button.grab_focus()
	else:
		# every finished round counts, even trades and draws
		round_number += 1
		start_new_round()

func play_hit_effects(p1_was_hit, p2_was_hit, big):
	# screen shake, bigger on the final kill
	shake = 24.0 if big else 14.0
	Sfx.play("hit")

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
	intro_token += 1
	var my_token = intro_token

	Engine.time_scale = 1.0
	$Player1.sprite.modulate = Color.WHITE
	$Player2.sprite.modulate = Color.WHITE
	$Player1.reset()
	$Player2.reset()

	# nobody can move and the clock waits until "FIGHT!"
	$Player1.frozen = true
	$Player2.frozen = true
	round_active = false
	time_left = ROUND_TIME
	update_timer_label()
	update_score()

	# the score popups and the red line from the last round go away
	p1_popup.visible = false
	p2_popup.visible = false
	center_line.visible = false

	show_banner("ROUND " + str(round_number), Color(1, 0.85, 0.3))
	await get_tree().create_timer(1.0, true, false, true).timeout
	if my_token != intro_token:
		return

	show_banner("FIGHT!", Color(1, 0.3, 0.3))
	$Player1.frozen = false
	$Player2.frozen = false
	round_active = true
	await get_tree().create_timer(0.7, true, false, true).timeout
	if my_token != intro_token:
		return

	banner_label.visible = false

func show_banner(text, color):
	banner_label.text = text
	banner_label.add_theme_color_override("font_color", color)
	banner_label.visible = true

	# the text pops in big and shrinks to normal size
	banner_label.pivot_offset = banner_label.size / 2
	banner_label.scale = Vector2(1.6, 1.6)
	var tween = create_tween()
	tween.tween_property(banner_label, "scale", Vector2(1, 1), 0.25)

func show_score_popup(popup, color):
	# stays on screen until the next round starts
	popup.add_theme_color_override("font_color", color)
	popup.visible = true

func update_timer_label():
	# show whole seconds, never below 0
	var seconds = int(ceil(max(time_left, 0.0)))
	timer_label.text = str(seconds)

	# turn red for the last 5 seconds
	if seconds <= 5:
		timer_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	else:
		timer_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))

func update_score():
	p1_name.text = $Player1.char_name
	p2_name.text = $Player2.char_name
	p1_pips.text = make_pips(score1)
	p2_pips.text = make_pips(score2)

	# name color matches the character's color
	p1_name.add_theme_color_override("font_color", $Player1.body_color)
	p2_name.add_theme_color_override("font_color", $Player2.body_color)

func make_pips(score):
	# filled circles for points won, empty ones for points left
	return "●".repeat(score) + "○".repeat(WIN_SCORE - score)

func _on_rematch_button_pressed():
	score1 = 0
	score2 = 0
	round_number = 1
	win_screen.visible = false
	start_new_round()

func _on_menu_button_pressed():
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://main_menu.tscn")
