extends Node3D


var rof := 360.0
var time := 0.0
@onready var muzzle_flash_particles := $GPUParticles3D
@onready var shot_audio := $AudioStreamPlayer3D


func _physics_process(delta: float) -> void:
	time += delta

func use():
	if 60 / rof <= time:
		time = 0.0
		muzzle_flash_particles.emitting = true
		shot_audio.play()
