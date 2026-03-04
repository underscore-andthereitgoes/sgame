extends HoldableRigidBody3D

func _physics_process(delta: float) -> void:
	constant_torque = Quaternion(Vector3.UP * global_basis, Vector3.UP).get_euler() * 0.1
