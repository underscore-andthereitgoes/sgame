extends Node3D

@export var flashlight: SpotLight3D
var player: PlayerCharacterBody3D

const flashlight_height: float = 0.8

func instant() -> void:
	global_position = player.global_position
	flashlight.position = Vector3(0.0, flashlight_height, 0.0)
	flashlight.global_basis = player.camera.global_basis

func _physics_process(delta: float) -> void:
	global_position = player.global_position
	flashlight.position = Vector3(0.0, flashlight_height, 0.0)
	flashlight.global_basis = flashlight.global_basis.slerp(player.camera.global_basis, 1.0 - (0.01 ** delta))
