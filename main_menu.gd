extends Control

@onready var main_box = $CenterContainer/MainBox
@onready var controls_box = $CenterContainer/ControlsBox
@onready var play_button = $CenterContainer/MainBox/PlayButton
@onready var back_button = $CenterContainer/ControlsBox/BackButton

func _ready():
	# so keyboard navigation works right away
	play_button.grab_focus()

func _on_play_button_pressed():
	# for now this goes straight to the fight
	get_tree().change_scene_to_file("res://main.tscn")

func _on_controls_button_pressed():
	main_box.visible = false
	controls_box.visible = true
	back_button.grab_focus()

func _on_back_button_pressed():
	controls_box.visible = false
	main_box.visible = true
	play_button.grab_focus()

func _on_quit_button_pressed():
	get_tree().quit()
