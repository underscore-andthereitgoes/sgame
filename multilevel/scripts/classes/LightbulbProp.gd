class_name LightbulbProp
extends HoldableRigidBody3D

func set_light_state(on: bool) -> void:
	for c in get_children():
		if c is Light3D:
			c.visible = on
