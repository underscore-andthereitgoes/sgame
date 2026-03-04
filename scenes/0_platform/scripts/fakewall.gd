extends Node3D

var activate_distance_squared: float = 8.0 **2
var activated: bool = false

var tween: Tween = null

@export var screen_mesh_inst: MeshInstance3D
@export var plane_xy_rect: Rect2

func _ready() -> void:
	screen_mesh_inst.hide()

func local_xy_to_screen_xy(local_xy: Vector2) -> Vector2:
	return get_viewport().get_camera_3d().unproject_position(to_global(Vector3(local_xy.x, local_xy.y, 0.0)))

func is_local_xy_behind(local_xy: Vector2) -> bool:
	return get_viewport().get_camera_3d().is_position_behind(to_global(Vector3(local_xy.x, local_xy.y, 0.0)))

func _process(delta: float) -> void:
	
	var d := get_viewport().get_camera_3d().global_position.distance_squared_to(global_position)
	
	if d < activate_distance_squared:
	
		if not activated:
			
			var img := get_viewport().get_texture().get_image()
			img.srgb_to_linear()
			var tex := ImageTexture.create_from_image(img)
			var shmat: ShaderMaterial = screen_mesh_inst.mesh.material
			shmat.set_shader_parameter(&"vptex", tex)
			shmat.set_shader_parameter(&"viewmat", get_viewport().get_camera_3d().get_camera_transform().inverse())
			shmat.set_shader_parameter(&"projectionmat", get_viewport().get_camera_3d().get_camera_projection())
			screen_mesh_inst.show()
			screen_mesh_inst.transparency = 0.0
			if tween:
				tween.pause()
				tween.stop()
				tween = null
			
			activated = true
			
	else:
		
		if activated:
			activated = false
			tween = create_tween()
			tween.tween_property(screen_mesh_inst, ^"transparency", 1.0, 1.0)
			tween.tween_callback(func(): screen_mesh_inst.hide())
