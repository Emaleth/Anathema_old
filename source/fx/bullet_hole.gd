extends Node3D


@onready var audio_player := $AudioStreamPlayer3D


func _ready() -> void:
	audio_player.play()


func _on_audio_stream_player_3d_finished() -> void:
	audio_player.queue_free()
