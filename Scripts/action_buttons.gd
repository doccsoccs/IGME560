extends Sprite2D

var active: bool = false

@onready var fight_button = $FightButton
@onready var wait_button = $WaitButton
@onready var toggle_button_sfx = $ToggleButtonSFX
@onready var select_button_sfx = $SelectButtonSFX

var active_button: Sprite2D

enum button_frame{
	fight_normal = 0,
	fight_pressed = 1,
	fight_hover = 2,
	wait_normal = 3,
	wait_pressed = 4,
	wait_hover = 5
}

func _ready():
	active_button = fight_button
	fight_button.frame = button_frame.fight_hover
	wait_button.frame = button_frame.wait_normal

func _process(_delta):
	if active:
		# Change button hover
		if Input.is_action_just_pressed("Down") or Input.is_action_just_pressed("Up"):
			toggle_button_sfx.play()
			if active_button == fight_button:
				active_button.frame = button_frame.fight_normal
				active_button = wait_button
				active_button.frame = button_frame.wait_hover
			elif active_button == wait_button:
				active_button.frame = button_frame.wait_normal
				active_button = fight_button
				active_button.frame = button_frame.fight_hover
		
		# Select the hovered button
		if Input.is_action_just_pressed("Select"):
			select_button_sfx.play()
			
			if active_button == fight_button: # FIGHT
				active_button.frame = button_frame.fight_pressed
				owner.attack()
			
			elif active_button == wait_button: # WAIT
				active_button.frame = button_frame.wait_pressed
				owner.end_turn()
			
			set_invisible_after_time(0.35)
		elif Input.is_action_just_released("Select"):
			await get_tree().create_timer(0.25).timeout
			if active_button == fight_button:
				active_button.frame = button_frame.fight_normal
			elif active_button == wait_button:
				active_button.frame = button_frame.wait_normal

func set_invisible_after_time(time: float = 0.15):
	active = false
	await get_tree().create_timer(time).timeout
	visible = false

func init_action_buttons():
	active = true
	visible = true
