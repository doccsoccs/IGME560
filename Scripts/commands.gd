extends Node

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_window().grab_focus()

func _input(event):
	if event.is_action_pressed("Quit"): # EXITS THE GAME
		get_tree().quit()
