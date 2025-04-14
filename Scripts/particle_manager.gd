extends Node2D

# Primary typal particles
@onready var water_particles = $WaterAttackParticles
@onready var earth_particles = $EarthAttackParticles
@onready var fire_particles = $FireAttackParticles
@onready var air_particles = $AirAttackParticles
@onready var shadow_particles = $ShadowAttackParticles
@onready var light_particles = $LightAttackParticles

# Follow-ups for multi-part particles
@onready var earth_followup_particles = $EarthAttackParticles/EarthFollowupParticles

# SFX
@onready var water_sfx = $"../AttackSFX/WaterSFX"
@onready var earth_sfx = $"../AttackSFX/EarthSFX"
@onready var fire_sfx = $"../AttackSFX/FireSFX"
@onready var air_sfx = $"../AttackSFX/AirSFX"
@onready var shadow_sfx = $"../AttackSFX/ShadowSFX"
@onready var light_sfx = $"../AttackSFX/LightSFX"


func emit_water():
	water_particles.emitting = true
	water_sfx.play()
	await get_tree().create_timer(water_particles.lifetime).timeout

func emit_earth():
	earth_particles.emitting = true
	await get_tree().create_timer(water_particles.lifetime).timeout
	earth_followup_particles.emitting = true
	earth_sfx.play()
	await get_tree().create_timer(earth_followup_particles.lifetime).timeout

func emit_fire():
	fire_particles.emitting = true
	fire_sfx.play()
	await get_tree().create_timer(fire_particles.lifetime).timeout

func emit_air():
	air_particles.emitting = true
	air_sfx.play()
	await get_tree().create_timer(air_particles.lifetime).timeout

func emit_shadow():
	shadow_particles.emitting = true
	shadow_sfx.play()
	await get_tree().create_timer(shadow_particles.lifetime).timeout

func emit_light():
	light_particles.emitting = true
	light_sfx.play()
	await get_tree().create_timer(light_particles.lifetime).timeout

# Calls a function to emit a certain particle type
# Recieves an enum's integer value that matches to the requisite type
func emit_particles(particle_type: int):
	match particle_type:
		0:
			emit_water()
			return
		1:
			emit_earth()
			return
		2:
			emit_fire()
			return
		3:
			emit_air()
			return
		4:
			emit_shadow()
			return
		5:
			emit_light()
			return
		_:
			return
