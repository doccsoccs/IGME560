extends Sprite2D

func _process(_delta):
	if Input.is_action_just_pressed("Select"):
		frame = 1
	elif Input.is_action_just_released("Select"):
		await get_tree().create_timer(0.25).timeout
		frame = 0

func set_invisible_after_time(time: float = 0.25):
	await get_tree().create_timer(time).timeout
	visible = false
