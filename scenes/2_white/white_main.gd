extends LevelScene

@export var remy: HoldableRigidBody3D
var remy_meshes: Array[VisualInstance3D] = []
var copied_remy_meshes: Array[VisualInstance3D] = []
@export var world_environment: WorldEnvironment
@export var pillar_z: float
@export var abs_pillar_x: float

@export_group("portal")
@export var portalcsg: CSGCombiner3D
@export var portalmesh: MeshInstance3D
@export var portal_inside: Area3D
@export var portal_outside: Area3D
@export var portalsubviewport: SubViewport
@export var portal_camera: Camera3D
@export var portal_marker_1: Marker3D
@export var portal_marker_2: Marker3D
@export var show_after_travel: Node3D
@export var upper_portal_outer: CSGCylinder3D
var portal_visible: bool = false

var player: PlayerCharacterBody3D

func pre_level_change() -> void:
	pass

func sterilize_this_level() -> PackedByteArray:
	return PackedByteArray([1 if remy and (remy.global_position.y > 3500.0 and remy.global_position.y < 4000.0) else 0])

func data_setup(data: PackedByteArray) -> void:
	if data[0] == 1:
		pass
	else:
		remy.queue_free()
		remy = null

func pre_setup() -> void:
	show_after_travel.hide()
	portalsubviewport.handle_input_locally = false
	portalsubviewport.gui_disable_input = true
	upper_portal_outer.radius *= 10.0
	var vp := get_viewport()
	portalsubviewport.msaa_3d = vp.msaa_3d
	portalsubviewport.screen_space_aa = vp.screen_space_aa
	portalsubviewport.use_taa = false
	portalsubviewport.use_debanding = vp.use_debanding
	portalsubviewport.use_occlusion_culling = vp.use_occlusion_culling
	portalsubviewport.mesh_lod_threshold = vp.mesh_lod_threshold
	portalsubviewport.scaling_3d_mode = vp.scaling_3d_mode
	portalsubviewport.scaling_3d_scale = vp.scaling_3d_scale
	portalsubviewport.texture_mipmap_bias = vp.texture_mipmap_bias
	portalsubviewport.anisotropic_filtering_level = vp.anisotropic_filtering_level
	portalsubviewport.fsr_sharpness = vp.fsr_sharpness
	portalsubviewport.audio_listener_enable_3d = vp.audio_listener_enable_3d
	portalsubviewport.sdf_oversize = vp.sdf_oversize
	portalsubviewport.sdf_scale = vp.sdf_scale
	portalsubviewport.positional_shadow_atlas_size = vp.positional_shadow_atlas_size
	portalsubviewport.positional_shadow_atlas_16_bits = vp.positional_shadow_atlas_16_bits
	portalsubviewport.positional_shadow_atlas_quad_0 = vp.positional_shadow_atlas_quad_0
	portalsubviewport.positional_shadow_atlas_quad_1 = vp.positional_shadow_atlas_quad_1
	portalsubviewport.positional_shadow_atlas_quad_2 = vp.positional_shadow_atlas_quad_2
	portalsubviewport.positional_shadow_atlas_quad_3 = vp.positional_shadow_atlas_quad_3
	portalsubviewport.oversampling = vp.oversampling
	portalsubviewport.oversampling_override = vp.oversampling_override
	portalsubviewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	portalsubviewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func post_setup() -> void:
	update_portal_visibility()
	if remy:
		for c in remy.get_children():
			if c is VisualInstance3D:
				remy_meshes.append(c)
				var copy: VisualInstance3D = c.duplicate()
				copy.hide()
				remy.get_parent().add_child(copy)
				copied_remy_meshes.append(copy)

func player_setup(setup_player: PlayerCharacterBody3D) -> void:
	player = setup_player
	player.global_position = Vector3(0.0, 500.0, 0.0)
	player.velocity = Vector3(0.0, -200.0, 0.0)
	player.camera_rotation_x = 0.0
	player.rotation.y = 0.0
	player_z_lessthan_pillar_z = player.global_position.z < pillar_z

func update_portal_visibility() -> void:
	portal_visible = portalcsg.visible
	portalcsg.collision_layer = 1 if portal_visible else 0
	portalsubviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if portal_visible else SubViewport.UPDATE_DISABLED

var player_z_lessthan_pillar_z: bool = false

var portal_sent: Array[Node3D] = []
var player_sent: bool = false

var next_level_timer: Timer = null

func _physics_process(delta: float) -> void:
	
	if is_instance_valid(player) and player is PlayerCharacterBody3D:
		var now_player_z_lessthan_pillar_z := player.global_position.z < pillar_z
		if now_player_z_lessthan_pillar_z != player_z_lessthan_pillar_z:
			player_z_lessthan_pillar_z = now_player_z_lessthan_pillar_z
			if absf(player.global_position.x) > abs_pillar_x:
				portalcsg.visible = not portalcsg.visible
				update_portal_visibility()
	
	if portal_visible:
		var outside := portal_outside.get_overlapping_bodies()
		var inside := portal_inside.get_overlapping_bodies()
		for collider in inside:
			if not is_instance_valid(collider) or collider.is_queued_for_deletion(): continue
			if collider not in portal_sent:
				if collider == player:
					collider.global_position = portal_marker_2.global_position + (collider.global_position - portal_marker_1.global_position)
					world_environment.environment = portal_camera.environment
					portal_sent.append(collider)
					player_sent = true
					show_after_travel.show()
					upper_portal_outer.radius /= 10.0
					if player.holding is HoldableRigidBody3D:
						player.holding.global_position += portal_marker_2.global_position - portal_marker_1.global_position
						portal_sent.append(player.holding)
					if remy and remy not in portal_sent:
						if remy in inside:
							remy.global_position += portal_marker_2.global_position - portal_marker_1.global_position
							portal_sent.append(remy)
						else:
							remy.queue_free()
							remy = null
							remy_meshes = []
							for c in copied_remy_meshes:
								c.queue_free()
							copied_remy_meshes = []
				elif collider is HoldableRigidBody3D and collider != player.holding:
					if collider not in outside:
						collider.global_position += portal_marker_2.global_position - portal_marker_1.global_position
						portal_sent.append(collider)
	
	if next_level_timer == null and player.global_position.y > 3500.0 and player.global_position.y < 4000.0:
		next_level_timer = Timer.new()
		add_child(next_level_timer)
		next_level_timer.start(15.0)
		next_level_timer.timeout.connect(func():
			trigger_next_level.emit(-1)
		)

func _process(delta: float) -> void:
	
	if portal_visible:
		if remy:
			var remy_sent: bool = remy in portal_sent
			if player_sent and remy_sent:
				for m in copied_remy_meshes:
					m.visible = false
			else:
				for i in range(remy_meshes.size()):
					copied_remy_meshes[i].visible = true
					copied_remy_meshes[i].global_transform = remy_meshes[i].global_transform.translated(portal_marker_2.global_position - portal_marker_1.global_position)
		if is_instance_valid(player) and player is PlayerCharacterBody3D:
			portalsubviewport.size = get_window().size
			var current_camera := player.camera
			portal_camera.global_transform = current_camera.global_transform.translated(portal_marker_2.global_position - portal_marker_1.global_position)
			portal_camera.fov = current_camera.fov
