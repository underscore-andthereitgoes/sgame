extends LevelScene

const chunk_size: float = 5.0

var player: PlayerCharacterBody3D
@export var floorceiling: Node3D
@export var flashlightcontainer: Node3D
@export var chunks: GreenroomsChunkGenerator
@export var world_environment: WorldEnvironment
@export var elevator_light: OmniLight3D

var player_stuck_ending: bool = false

var remy_next: bool = false

var delay_level_change_tween: Tween = null

func pre_level_change() -> void:
	if player_stuck_ending:
		var tw := create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(world_environment.environment, ^"tonemap_exposure", 0.0, 10.0).from(1.0).set_delay(10.0)
		var timer := Timer.new()
		add_child(timer)
		timer.one_shot = true
		timer.start(22.0)
		await timer.timeout
		timer.queue_free()
	else:
		var timer := Timer.new()
		add_child(timer)
		timer.one_shot = true
		timer.start(2.0)
		await timer.timeout
		timer.queue_free()
		player.camera_shake_intensity = 0.002
		player.camera_shake_speed = 0.2
		player.camera_shake_time = 5.0

func sterilize_this_level() -> PackedByteArray:
	return PackedByteArray([1 if remy_next else 0, chunks.exit_direction])

func data_setup(data: PackedByteArray) -> void:
	remy_next = (data[0] > 0)

func pre_setup() -> void:
	var gen_next := true
	while gen_next:
		gen_next = chunks.slow_generate_only(Vector3.ZERO)
		await get_tree().process_frame

func post_setup() -> void:
	pass

func player_setup(p: PlayerCharacterBody3D) -> void:
	player = p
	player.global_position = Vector3.ZERO
	flashlightcontainer.player = player
	flashlightcontainer.instant()

var noexit_timer: float = 20.0

func _process(delta: float) -> void:
	var player_chunksnapped := Vector2i(floori(player.global_position.x / chunk_size + 0.5), floori(player.global_position.z / chunk_size + 0.5)) * chunk_size
	floorceiling.position = Vector3(player_chunksnapped.x, 0.0, player_chunksnapped.y)
	chunks.process_with_player_pos(delta, player.global_position)
	if not player_stuck_ending:
		noexit_timer -= delta
		if noexit_timer <= 0.0:
			chunks.can_generate_exit = true
			noexit_timer = INF
		chunks.update_exit(player)
		if chunks.player_stuck:
			player_stuck_ending = true
			trigger_next_level.emit(2)
	if chunks.exit_state == 1:
		flashlightcontainer.hide()
		elevator_light.show()
	elif chunks.exit_state == 2:
		chunks.exit_state = 3
		trigger_next_level.emit(-1)
