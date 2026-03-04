extends LevelScene

@export var statslabel: StatsLabel
@export var world_environment: WorldEnvironment

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
	var tw := create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(world_environment.environment, ^"tonemap_exposure", 1.0, 2.0).from(0.0)

func player_setup(player: PlayerCharacterBody3D) -> void:
	player.global_position = Vector3.ZERO
	player.rotation.y = 0.0
	player.camera_rotation_x = 0.0
	player.velocity = Vector3.ZERO
	player.last_velocity = Vector3.ZERO
	statslabel.player = player
