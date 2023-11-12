extends Node3D

var bullet_index : Dictionary = {
	"default" : {
		"speed" : 100,
		"container" : {},
		"multimesh" : null,
		"mesh" : null
 	}
}


func _ready() -> void:
	configure_multimeshes()


func configure_multimeshes():
	for type in bullet_index:
		var multi_mesh_instance = MultiMeshInstance3D.new()
		multi_mesh_instance.multimesh = MultiMesh.new()
		bullet_index[type]["multimesh"] = multi_mesh_instance


func _physics_process(delta: float) -> void:
	process_bullets(delta)


func create_bullet(shooter : CharacterBody3D, initial_transform : Transform3D, bullet_id : String = "default") -> void:
	var bullet_uid = hash(randi())
	bullet_index[bullet_id]["container"][bullet_uid] = {
		"time" : Time.get_unix_time_from_system(),
		"transform" : initial_transform,
		"owner" : shooter
	}
#	print(bullet_index[bullet_id]["container"].size())


func process_bullets(delta) -> void:
	for type in bullet_index:
		bullet_index[type]["multimesh"].multimesh.instance_count = bullet_index[type]["container"].size()
		for uid in bullet_index[type]["container"]:
			var current_transform : Transform3D = bullet_index[type]["container"][uid]["transform"]
#			var next_transform = Transform3D(bullet_index[type]["container"][uid]["transform"].basis, bullet_index[type]["container"][uid]["transform"].origin + (Vector3.FORWARD * bullet_index[type]["container"][uid]["transform"].basis.inverse() * (Time.get_unix_time_from_system() - bullet_index[type]["container"][uid]["time"]) * bullet_index[type]["speed"]))
			var next_transform = bullet_index[type]["container"][uid]["transform"].transposed(
					Vector3.FORWARD
					 * bullet_index[type]["container"][uid]["transform"].basis.inverse()
					 * (Time.get_unix_time_from_system() - bullet_index[type]["container"][uid]["time"])
					 * bullet_index[type]["speed"]
			)
			bullet_index[type]["container"][uid]["transform"] = next_transform
			if current_transform.origin.distance_squared_to(next_transform.origin) > pow(1000, 2):
				destroy_bullet(type, uid, null, null)
				return
			else:
				var space_state = get_world_3d().direct_space_state
				var query = PhysicsRayQueryParameters3D.create(current_transform.origin, next_transform.origin)
				var result = space_state.intersect_ray(query)
				if result:
					destroy_bullet(type, uid, result.position, result.collider)
#		for i in bullet_index[type]["container"].size():
#			bullet_index[type]["multimesh"].multimesh


func destroy_bullet(bullet_id, bullet_uid, _impact_position, impacted_node):
	bullet_index[bullet_id]["container"].erase(bullet_uid)
#	print(bullet_uid)
	print(impacted_node)
#	if impacted_node: impacted_node.queue_free()
