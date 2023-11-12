extends Node3D

var bullet_index : Dictionary = {
	"default" : {
		"speed" : 100,
		"container" : {},
 	}
}


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


func process_bullets(_delta) -> void:
	for type in bullet_index:
		for uid in bullet_index[type]["container"]:
			var current_transform : Transform3D = bullet_index[type]["container"][uid]["transform"]
			var next_transform := current_transform.translated(Vector3.ONE * bullet_index[type]["speed"] * (Time.get_unix_time_from_system() - bullet_index[type]["container"][uid]["time"]))
			if current_transform.origin.distance_squared_to(next_transform.origin) > pow(1000, 2):
				destroy_bullet(type, uid, null, null)
				return
			else:
				var space_state = get_world_3d().direct_space_state
				var query = PhysicsRayQueryParameters3D.create(current_transform.origin, next_transform.origin)
				var result = space_state.intersect_ray(query)
				if result:
					destroy_bullet(type, uid, result.position, result.collider)


func destroy_bullet(bullet_id, bullet_uid, _impact_position, impacted_node):
	bullet_index[bullet_id]["container"].erase(bullet_uid)
#	print(bullet_uid)
#	print(impacted_node)
	if impacted_node: impacted_node.queue_free()
