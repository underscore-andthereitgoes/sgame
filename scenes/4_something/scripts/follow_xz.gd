extends MeshInstance3D

func _process(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	global_position.x = camera.global_position.x
	global_position.z = camera.global_position.z
