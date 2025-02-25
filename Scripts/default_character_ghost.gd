extends Sprite2D

@onready var animation_player = $AnimationPlayer

enum anim_state {
	forward,
	backward
}
var current_anim_state: anim_state
var prev_anim_state: anim_state

# Called when the node enters the scene tree for the first time.
func _ready():
	current_anim_state = anim_state.forward
	prev_anim_state = current_anim_state
	animation_player.play("walk")

func _process(_delta):
	if current_anim_state != prev_anim_state:
		switch_animations(current_anim_state)
		prev_anim_state = current_anim_state

func switch_animations(state: anim_state):
	match state:
		anim_state.forward:
			animation_player.play("walk")
			return
		anim_state.backward:
			animation_player.play("walk_back")
			return

func left():
	flip_h = false
	current_anim_state = anim_state.backward

func right():
	flip_h = true
	current_anim_state = anim_state.forward

func up():
	flip_h = true
	current_anim_state = anim_state.backward

func down():
	flip_h = false
	current_anim_state = anim_state.forward
