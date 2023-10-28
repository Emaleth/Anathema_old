extends Node3D


var rof := 360.0
var rof_time := 0.0
var flash_timer := 0.0
@onready var muzzle_flash := $MuzzleFlash
@onready var shot_audio := $AudioStreamPlayer3D

func _ready() -> void:
		muzzle_flash.visible = false


func _physics_process(delta: float) -> void:
	rof_time += delta
	flash_timer += delta
	if muzzle_flash.visible and flash_timer > 0.02:
		muzzle_flash.visible = false

func use():
	if 60 / rof <= rof_time:
		rof_time = 0.0
		flash_timer = 0.0
		muzzle_flash.visible = true
		shot_audio.play()
