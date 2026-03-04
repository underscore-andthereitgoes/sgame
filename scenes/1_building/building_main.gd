extends LevelScene

@export var remy: HoldableRigidBody3D
@export var persisted_props: Node3D

@export_group("light")
@export var lights_container: Node3D
@export var lightbulb_template: Node3D
@export var giant_lightbulb: HoldableRigidBody3D

@export_group("button")
@export var green_button: Button3DContainer
@export var green_button_extra_collider: CollisionShape3D

@export_group("room")
@export var room_body: RigidBody3D
@export var room_extra_walls: StaticBody3D

@export_group("meshes")
@export var windows_disable_mesh1: MeshInstance3D
@export var windows_disable_mesh2: MeshInstance3D
@export var windows_mesh: MeshInstance3D

@export_group("fragmenting")
@export var fragment_material: ShaderMaterial
var fragment_targets: Array[MeshInstance3D]

func _find_fragment_targets(parent: Node3D):
	for c in parent.get_children():
		if c is Node3D:
			if c is MeshInstance3D:
				fragment_targets.append(c)
			_find_fragment_targets(c)

func pre_level_change() -> void:
	lights_container.queue_free()
	await get_tree().process_frame
	if is_instance_valid(giant_lightbulb): giant_lightbulb.queue_free()
	if is_instance_valid(green_button): green_button.queue_free()
	if is_instance_valid(green_button_extra_collider): green_button_extra_collider.queue_free()

func sterilize_this_level() -> PackedByteArray:
	if is_instance_valid(remy) and remy is HoldableRigidBody3D and remy.global_position.distance_squared_to(room_body.global_position) <= 400.0:
		return PackedByteArray([1])
	else:
		return PackedByteArray([0])

func data_setup(data: PackedByteArray) -> void:
	
	var interval: int = 0
	
	var d: Dictionary[StringName,Dictionary] = bytes_to_var(data)
	await get_tree().process_frame
	
	var children := persisted_props.get_children()
	for child in children:
		if child is RigidBody3D:
			if StringName(child.name) in d.keys():
				var child_data: Dictionary = d[StringName(child.name)]
				child.global_position = child_data["p"]
				child.global_rotation = child_data["r"]
				child.linear_velocity = child_data["L"]
				child.angular_velocity = child_data["A"]
			else:
				child.queue_free()
			interval += 1
			if interval > 2:
				interval = 0
				await get_tree().process_frame

func pre_setup() -> void:
	MusicManager.playing_music(&"platform.building", 1.0)
	green_button.hide()
	green_button.process_mode = Node.PROCESS_MODE_DISABLED
	green_button_extra_collider.disabled = true
	room_extra_walls.process_mode = Node.PROCESS_MODE_DISABLED
	var xz := Vector2.from_angle(randf() * TAU) * 100.0
	giant_lightbulb.position = Vector3(xz.x, 1.0, xz.y)
	giant_lightbulb.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
	await get_tree().process_frame
	for i in range(50):
		for j in range(20):
			var lb := lightbulb_template.duplicate()
			lights_container.add_child(lb)
			var o := true
			while o or lb.global_position.distance_to(room_body.global_position) <= 30.0:
				lb.position = Vector3(randfn(0.0, 200.0), 0.1, randfn(0.0, 200.0))
				o = false
			lb.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
		await get_tree().process_frame
	lightbulb_template.queue_free()
	await get_tree().process_frame
	_find_fragment_targets(self)
	await get_tree().process_frame

func post_setup() -> void:
	pass

var fragmenting: bool = false
func begin_fragmentation() -> void:
	if fragmenting: return
	fragmenting = true
	for target in fragment_targets:
		if is_instance_valid(target) and target is MeshInstance3D:
			target.material_overlay = fragment_material
	fragment_material.set_shader_parameter(&"factor", 0.0)
	var tw := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tw.tween_method(func(factor: float):
		fragment_material.set_shader_parameter(&"factor", factor)
	, 0.0, 1.0, 30.0)
	tw.tween_callback(func(): trigger_next_level.emit(-1))

var p: PlayerCharacterBody3D
func player_setup(player: PlayerCharacterBody3D) -> void:
	p = player

func _process(delta: float) -> void:
	
	if is_instance_valid(giant_lightbulb):
		
		var d := p.global_position.distance_to(giant_lightbulb.global_position)
		if d > 40.0:
			MusicManager.set_mix_music(&"platform.building", &"building.green", 0.0, 0.0, 0.0, 999999999.0)
		else:
			var f: float = clampf((d - 5.0) / 35.0, 0.0, 1.0)
			MusicManager.set_music_volume(&"platform.building", f)
			MusicManager.set_music_volume(&"building.green", 1.0 - f)
	
	if not fragmenting:
		if not green_button.visible and (giant_lightbulb.collision_layer & 0b0010) == 0:
			green_button.show()
			green_button.process_mode = Node.PROCESS_MODE_INHERIT
			green_button_extra_collider.disabled = false
			green_button.pressed.connect(func():
				room_extra_walls.process_mode = Node.PROCESS_MODE_INHERIT
				room_body.gravity_scale = 0.0
				room_body.freeze = false
				room_body.constant_force = Vector3(0.0, 2000.0, 0.0)
				room_body.linear_damp = 10.0
				windows_disable_mesh1.hide()
				windows_disable_mesh2.hide()
				windows_mesh.show()
			, CONNECT_ONE_SHOT)

func _physics_process(delta: float) -> void:
	if not room_body.freeze:
		room_extra_walls.constant_linear_velocity = room_body.linear_velocity
		room_extra_walls.constant_angular_velocity = room_body.angular_velocity
		if room_body.position.y > 40.0 and not fragmenting:
			begin_fragmentation()
