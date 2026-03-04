extends Node3D

@export var resetbutton: Button3DContainer

func reset_positions() -> void:
	var row: int = 0
	var col: int = 0
	for c in get_children():
		if c is HoldableRigidBody3D:
			c.position = Vector3(2.0 * sqrt(1.0/3.0) * (col - row * 0.5), 0.0, -row) * 0.6
			c.rotation = Vector3.ZERO
			c.linear_velocity = Vector3.ZERO
			c.angular_velocity = Vector3.ZERO
			c.show()
			c.reset_physics_interpolation()
			
			col += 1
			if col > row:
				col = 0
				row += 1

func _ready() -> void:
	resetbutton.connect(&"pressed", reset_positions)
	reset_positions()
