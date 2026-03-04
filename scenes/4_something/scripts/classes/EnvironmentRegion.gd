class_name EnvironmentRegion
extends VisibleOnScreenNotifier3D

@export var target_world_environment: WorldEnvironment

@export var environment: Environment
@export var camera_attributes: CameraAttributes
@export_flags_3d_render var extra_camera_cull: int = 0

var subviewport: SubViewport
var subviewport_camera: Camera3D
var mesh_instances: Array[MeshInstance3D]
var meshes: Array[BoxMesh] = []
const mesh_count: int = 5
const mesh_step: float = 0.05
var shader: Shader = preload("res://multilevel/shaders/envregion.gdshader")
var shmat: ShaderMaterial
var vptex: ViewportTexture

func is_camera_inside(camera: Camera3D) -> bool:
	var camera_pos := to_local(camera.global_position)
	return aabb.has_point(camera_pos)

var on_screen := false

func _ready() -> void:
	
	screen_entered.connect(func(): on_screen = true)
	screen_exited.connect(func(): on_screen = false)
	
	subviewport = SubViewport.new()
	add_child(subviewport)
	subviewport_camera = Camera3D.new()
	subviewport_camera.cull_mask = 1 | extra_camera_cull
	subviewport.add_child(subviewport_camera)
	subviewport_camera.environment = environment
	subviewport_camera.environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	subviewport_camera.attributes = camera_attributes
	subviewport.gui_disable_input = true
	subviewport.handle_input_locally = false
	subviewport.render_target_update_mode = SubViewport.UPDATE_WHEN_PARENT_VISIBLE
	
	var vp := get_viewport()
	subviewport.msaa_3d = Viewport.MSAA_DISABLED
	subviewport.screen_space_aa = mini(vp.screen_space_aa, vp.SCREEN_SPACE_AA_FXAA) as Viewport.ScreenSpaceAA
	subviewport.use_taa = false
	subviewport.use_debanding = vp.use_debanding
	subviewport.use_occlusion_culling = vp.use_occlusion_culling
	subviewport.mesh_lod_threshold = vp.mesh_lod_threshold
	subviewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	subviewport.scaling_3d_scale = 1.0
	subviewport.texture_mipmap_bias = vp.texture_mipmap_bias
	subviewport.anisotropic_filtering_level = vp.anisotropic_filtering_level
	subviewport.fsr_sharpness = vp.fsr_sharpness
	subviewport.audio_listener_enable_3d = vp.audio_listener_enable_3d
	subviewport.sdf_oversize = vp.sdf_oversize
	subviewport.sdf_scale = vp.sdf_scale
	subviewport.positional_shadow_atlas_size = vp.positional_shadow_atlas_size
	subviewport.positional_shadow_atlas_16_bits = vp.positional_shadow_atlas_16_bits
	subviewport.positional_shadow_atlas_quad_0 = vp.positional_shadow_atlas_quad_0
	subviewport.positional_shadow_atlas_quad_1 = vp.positional_shadow_atlas_quad_1
	subviewport.positional_shadow_atlas_quad_2 = vp.positional_shadow_atlas_quad_2
	subviewport.positional_shadow_atlas_quad_3 = vp.positional_shadow_atlas_quad_3
	subviewport.oversampling = vp.oversampling
	subviewport.oversampling_override = vp.oversampling_override
	
	vptex = subviewport.get_texture()
	
	shmat = ShaderMaterial.new()
	shmat.shader = shader
	shmat.set_shader_parameter(&"vptex", vptex)
	
	for i in range(mesh_count):
		
		var mesh := BoxMesh.new()
		mesh.size = aabb.grow(-mesh_step * i).size
		mesh.material = shmat
		meshes.append(mesh)
		
		var mesh_instance := MeshInstance3D.new()
		add_child(mesh_instance)
		mesh_instance.position = aabb.get_center()
		mesh_instance.mesh = mesh
		mesh_instance.layers = 0b10
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh_instances.append(mesh_instance)

var camera_was_inside: bool = true

func _process(delta: float) -> void:
	
	subviewport.size = get_window().size / 2
	var camera := get_viewport().get_camera_3d()
	
	environment.tonemap_exposure = target_world_environment.environment.tonemap_exposure
	
	var camera_is_inside := is_camera_inside(camera)
	if camera_is_inside != camera_was_inside:
		camera_was_inside = camera_is_inside
		if camera_is_inside:
			target_world_environment.environment = environment
			target_world_environment.camera_attributes = camera_attributes
		else:
			vptex = subviewport.get_texture()
	
	if camera_is_inside:
		subviewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		hide()
		camera.cull_mask |= extra_camera_cull
	else:
		var update := false
		if on_screen or not visible:
			var aabbc := AABB(to_local(camera.global_position), Vector3.ZERO).grow(8.0)
			if aabb.intersects(aabbc):
				update = true
		if update:
			subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			camera.cull_mask &= ~extra_camera_cull
			shmat.set_shader_parameter(&"vptex", vptex)
		else:
			subviewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		show()
	
	subviewport_camera.global_position = camera.global_position
	subviewport_camera.global_basis = camera.global_basis
	subviewport_camera.near = 0.001
	subviewport_camera.far = camera.far
	subviewport_camera.fov = camera.fov
