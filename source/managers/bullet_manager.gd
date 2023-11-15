extends Node3D

var bullet_index : Dictionary = {
	"default" : {
		"speed" : 10, # 800 is avarage
		"container" : {},
		"multimesh" : null,
		"mesh" : preload("res://assets/models/bullets/untitled.obj"),
		"material" : preload("res://assets/materials/bullet_trace.tres")
 	}
}


func _ready() -> void:
	configure_multimeshes()


func configure_multimeshes():
	for type in bullet_index:
		var multi_mesh_instance = MultiMeshInstance3D.new()
		multi_mesh_instance.multimesh = MultiMesh.new()
		multi_mesh_instance.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multi_mesh_instance.multimesh.mesh = bullet_index[type]["mesh"]
		multi_mesh_instance.material_override = bullet_index[type]["material"]
		bullet_index[type]["multimesh"] = multi_mesh_instance
		add_child(multi_mesh_instance)


func _physics_process(_delta: float) -> void:
	process_bullet_ray()
	process_bullet_multimesh()


func create_bullet(shooter : CharacterBody3D, initial_transform : Transform3D, damage : float, bullet_id : String = "default") -> void:
	var bullet_uid = hash(randi())
	bullet_index[bullet_id]["container"][bullet_uid] = {
		"time" : Time.get_unix_time_from_system(),
		"transform" : initial_transform,
		"owner" : shooter,
		"damage" : damage
	}


func process_bullet_ray() -> void:
	for type in bullet_index:
		for uid in bullet_index[type]["container"]:
			var current_transform : Transform3D = bullet_index[type]["container"][uid]["transform"]
			var next_transform = bullet_index[type]["container"][uid]["transform"].translated(
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
				var query = PhysicsRayQueryParameters3D.create(
						current_transform.origin,
						next_transform.origin,
						0xFFFFFFFF,
						[bullet_index[type]["container"][uid]["owner"].get_rid()]
						)
				var result = space_state.intersect_ray(query)
				if result:
					destroy_bullet(type, uid, result.position, result.collider)


func process_bullet_multimesh() -> void:
	for type in bullet_index:
		var index := 0
		bullet_index[type]["multimesh"].multimesh.instance_count = bullet_index[type]["container"].size()
		for i in bullet_index[type]["container"]:
			bullet_index[type]["multimesh"].multimesh.set_instance_transform(index, bullet_index[type]["container"][i]["transform"])
			index += 1


func destroy_bullet(bullet_id, bullet_uid, _impact_position, impacted_node):
	if impacted_node.has_method("damage"):
		impacted_node.damage(bullet_index[bullet_id]["container"][bullet_uid]["damage"])
	if impacted_node.owner.has_method("damage"):
		impacted_node.owner.damage(bullet_index[bullet_id]["container"][bullet_uid]["damage"])
	bullet_index[bullet_id]["container"].erase(bullet_uid)
