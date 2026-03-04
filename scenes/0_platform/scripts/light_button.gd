extends Button3DContainer

@export var lightbulb: LightbulbProp
@export var sunlight: DirectionalLight3D

func _ready() -> void:
	super._ready()
	pressed.connect(func():
		lightbulb.set_light_state(sunlight.visible)
		sunlight.visible = not sunlight.visible
	)
