extends Control

func _ready() -> void:
	var img := DisplayServer.screen_get_image()
	var i: TextureRect = $img
	i.texture = ImageTexture.create_from_image(img)

func _process(delta: float) -> void:
	var i: TextureRect = $img
	var t := get_screen_transform().affine_inverse().translated(-get_window().position)
	i.global_position = t * Vector2(0, 0)
	i.size = (t * Vector2(get_window().size)) - (t * Vector2(0, 0))
