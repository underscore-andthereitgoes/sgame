extends LevelScene

@export var statslabel: StatsLabel

func pre_level_change() -> void:
	pass

func sterilize_this_level() -> PackedByteArray:
	pass
	return PackedByteArray()

func data_setup(data: PackedByteArray) -> void:
	pass

func pre_setup() -> void:
	pass

func post_setup() -> void:
	pass

func player_setup(player: PlayerCharacterBody3D) -> void:
	player.global_position = Vector3.ZERO
	player.rotation.y = 0.0
	player.camera_rotation_x = 0.0
	player.velocity = Vector3.ZERO
	player.last_velocity = Vector3.ZERO
	statslabel.player = player
