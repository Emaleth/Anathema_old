extends RigidBody3D


@export var ammo : int = 30
@export var rof := 720.0 # per minute

var ads := false
var rof_time := 0.0
var current_ammo : int = 0
var rounds_per_second : float = 0.0

@export var muzzle_marker : Marker3D
@export var ads_marker : Marker3D
@export var model : Node

@onready var red_dot := $RedDot
@onready var muzzle_flash := $muzzle_flash
@onready var shot_audio := $ShotSound
@onready var reload_audio := $ReloadSound
@onready var muzzle_pivot := $MuzzlePivot
@onready var collision_shape := $CollisionShape3D


func position_nodes():
	muzzle_flash.position = muzzle_marker.position
	shot_audio.position = muzzle_marker.position
	muzzle_pivot.position = muzzle_marker.position


func _ready() -> void:
	collision_shape.shape.size = Vector3(1, 1, 1)
	freeze = true
	collision_shape.disabled = true
	position_nodes()
	muzzle_flash.visible = false
	rounds_per_second = 60 / rof
	current_ammo = ammo
	red_dot.top_level = true
	Signals.secondary_action.connect(ads_mode)
	Signals.reload.connect(reload)
	Signals.primary_action.connect(use)
	Signals.update_camera_ray_collision_point.connect(adjust_muzzle)
	Signals.update_camera_ray_collision_point.connect(adjust_red_dot)
	get_tree().create_timer(0.1).timeout.connect(emit_initial_signals)


func _physics_process(delta: float) -> void:
	rof_time += delta


func use():
	if current_ammo > 0:
		if rounds_per_second <= rof_time:
			shot_animation()
			owner.recoil(Vector2(0.01, 0.01 * sign(randf()*2-1)))
			rof_time = 0.0
			current_ammo -= 1
			Signals.update_current_ammo.emit(current_ammo)
			BulletManager.create_bullet(owner, muzzle_pivot.global_transform, 1.0)
	else:
		reload()


func shot_animation():
	var recoil_animation_time : float = min(rounds_per_second * 0.25, 0.05)
	var recover_animation_time : float = min(rounds_per_second * 0.75, 0.15)
	muzzle_flash.show()
	shot_audio.pitch_scale = randf_range(0.9, 1.1)
	shot_audio.play()
	var tween = create_tween()
	if not ads:
		tween.tween_property( self, "position:z", randf_range(0.035, 0.045), recoil_animation_time ).set_trans(Tween.TRANS_SINE)
		tween.parallel().tween_property( self, "rotation:x", deg_to_rad( randf_range(-1.5, -0.5) ), recoil_animation_time ).set_trans(Tween.TRANS_SINE)
		tween.parallel().tween_property( self, "position:y", randf_range(0.005, 0.015), recoil_animation_time ).set_trans(Tween.TRANS_SINE)
		tween.parallel().tween_property( self, "position:x", randf_range(-0.005, 0.005), recoil_animation_time ).set_trans(Tween.TRANS_SINE)
	else:
		tween.tween_property( self, "position:z", 0.0, recoil_animation_time ).set_trans(Tween.TRANS_SINE)
		tween.parallel().tween_property( self, "rotation:x", deg_to_rad( randf_range(-0.15, 0.05) ), recoil_animation_time ).set_trans(Tween.TRANS_SINE)
		tween.parallel().tween_property( self, "position:y", randf_range(0.0005, 0.0015), recoil_animation_time ).set_trans(Tween.TRANS_SINE)
		tween.parallel().tween_property( self, "position:x", randf_range(-0.0005, 0.0005), recoil_animation_time ).set_trans(Tween.TRANS_SINE)

	tween.tween_property( self, "position:z", 0.0, recover_animation_time ).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property( self, "position:y", 0.0, recover_animation_time ).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property( self, "position:x", 0.0, recover_animation_time ).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property( self, "rotation:x", 0.0, recover_animation_time ).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_callback(muzzle_flash.hide)


func reload():
	reload_audio.play()
	current_ammo = ammo
	Signals.update_current_ammo.emit(current_ammo)


func ads_mode(value : bool):
	ads = value


func emit_initial_signals():
	Signals.update_max_ammo.emit(ammo)
	Signals.update_current_ammo.emit(current_ammo)


func adjust_muzzle(c_point : Vector3, _c_normal : Vector3):
	muzzle_pivot.look_at(c_point)


func adjust_red_dot(c_point : Vector3, c_normal : Vector3):
	red_dot.global_transform.origin = c_point
	var random_vector_up = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
	red_dot.global_transform = red_dot.global_transform.looking_at(c_point + c_normal, random_vector_up)
