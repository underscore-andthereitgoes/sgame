extends HoldableRigidBody3D

@export var hole: CSGShape3D
@export var middle_mesh: MeshInstance3D

func _physics_process(delta: float) -> void:
	var dsquared := (Vector3.UP * global_basis).abs().distance_squared_to(Vector3.UP)
	dsquared = maxf(0.0, dsquared - 0.0003)
	middle_mesh.position = to_local(global_position + Vector3(0.0, -0.175, 0.0))
	if freeze and linear_damp > 0.1:
		middle_mesh.show()
		freeze = false
		collision_layer = 0b1100
		collision_mask = 0b0111
		hole.hide()
	elif sleeping and not freeze:
		if position.y <= 0.1025 and dsquared <= 0.0:
			freeze = true
			rotation.x = 0.0
			position.y = 0.1
			rotation.z = 0.0
			collision_layer = 0b1000
			collision_mask = 0b0000
			middle_mesh.hide()
			hole.position.x = position.x
			hole.position.z = position.z
			hole.rotation.y = rotation.y
			hole.show()
