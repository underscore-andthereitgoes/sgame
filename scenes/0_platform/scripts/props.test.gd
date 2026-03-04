extends Node3D

func _ready() -> void:
	return
	var remy_template: HoldableRigidBody3D = null
	for c in get_children():
		if c.name == "remy": remy_template = c
		else: c.queue_free()
	for i in range(500):
		var r2 := remy_template.duplicate()
		r2.position = Vector3(randf_range(-2.0, 2.0), randf_range(5.0, 15.0), randf_range(-12.0, -8.0))
		r2.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
		add_child(r2)
	remy_template.queue_free()


func _process(delta: float) -> void:
	pass
	#if get_tree().get_frame() > 400:
	#	cc *= 1.5 ** delta
	#	for i in range(int(cc * delta + accum)):
	#		var c := crate.duplicate()
	#		add_child(c)
	#		c.position = Vector3(randf_range(-2.0, 2.0), randf_range(100.0, 120.0), randf_range(-2.0, 2.0))
	#		c.rotation = Vector3(randf_range(-TAU, TAU), randf_range(-TAU, TAU), randf_range(-TAU, TAU))
	#		c.process_mode = Node.PROCESS_MODE_INHERIT
	#		c.show()
	#	accum += fmod(cc * delta + accum, 1.0)
