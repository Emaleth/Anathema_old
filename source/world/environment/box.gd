extends Node3D

var life = 100


func damage(_amount : float):
	life -= _amount
	$Cube/StaticBody3D/CollisionShape3D.disabled = true
	hide()
	get_tree().create_timer(2.0).timeout.connect(func(): $Cube/StaticBody3D/CollisionShape3D.disabled = false; show())
