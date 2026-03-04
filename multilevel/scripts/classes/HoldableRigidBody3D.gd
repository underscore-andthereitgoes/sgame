class_name HoldableRigidBody3D
extends RigidBody3D

func _ready() -> void:
	collision_layer &= ~0b0001
	collision_layer |= 0b1110
	collision_mask |= 0b0111
