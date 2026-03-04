class_name Button3DContainer
extends Node3D

var button_pressed: bool = false
signal pressed()
signal released()

var top: RigidBody3D
var unpressed_position := Vector3.ZERO
@export var min_button_y: float = 0.0
@export var press_threshold: float = 0.0
@export var max_button_y: float = 0.0
@export var force: float = 20.0

func _ready() -> void:
	for c in get_children():
		if c is RigidBody3D:
			top = c
			unpressed_position = c.position
			c.gravity_scale = 0.0
			c.lock_rotation = true
			break
	for c in get_children():
		if c is StaticBody3D:
			top.add_collision_exception_with(c)

func _physics_process(delta: float) -> void:
	
	if top.position.y < min_button_y:
		top.position.y = min_button_y
		top.linear_velocity.y = maxf(top.linear_velocity.y, 0.0)
	if top.position.y > max_button_y:
		top.position.y = max_button_y
		top.linear_velocity.y = minf(top.linear_velocity.y, 0.0)
	top.position.x = unpressed_position.x
	top.position.z = unpressed_position.z
	top.constant_force = Vector3(0.0, (unpressed_position.y - top.position.y) * force, 0.0)
	if not top.rotation.is_zero_approx(): top.rotation = Vector3.ZERO
	
	var currently_pressed = top.position.y < press_threshold
	if currently_pressed != button_pressed:
		button_pressed = currently_pressed
		if currently_pressed: emit_signal(&"pressed")
		else: emit_signal(&"released")
