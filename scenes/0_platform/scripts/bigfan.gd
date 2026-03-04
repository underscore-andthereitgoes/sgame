extends HoldableRigidBody3D

@export var fan_blade: MeshInstance3D
@export var wind_area: Area3D
@export var force: float

func _process(delta: float) -> void:
	fan_blade.rotation.x += delta * 0.2 * TAU

func _physics_process(delta: float) -> void:
	for b in wind_area.get_overlapping_bodies():
		if b == self: continue
		if b is RigidBody3D:
			var diff := b.global_position - global_position
			b.apply_central_impulse(((force / b.mass) / (maxf(0.0, diff.length()) + 1.0)) * delta * diff.normalized())
		elif b is CharacterBody3D:
			var diff := b.global_position - global_position
			b.velocity += force / (maxf(0.0, diff.length() + 1.0)) * delta * diff.normalized()
