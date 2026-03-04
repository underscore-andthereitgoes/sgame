extends LevelScene

var player: PlayerCharacterBody3D
@export var elevator_doors_body: StaticBody3D
@export var elevator_door1: MeshInstance3D
@export var elevator_door2: MeshInstance3D
@export var world_environment: WorldEnvironment

var elevator_exit_dir: int = -1
var remy_next: bool = false

func pre_level_change() -> void:
	pass

func sterilize_this_level() -> PackedByteArray:
	return PackedByteArray([1 if remy_next else 0])

func data_setup(data: PackedByteArray) -> void:
	remy_next = (data[0] > 0)
	elevator_exit_dir = data[1]

func pre_setup() -> void:
	pass

func close_elevator_doors() -> void:
	elevator_doors_body.collision_layer = 1
	elevator_door1.position.z = 0.0
	elevator_door2.position.z = 0.0

func open_elevator_doors() -> void:
	elevator_doors_body.collision_layer = 0
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(elevator_door1, ^"position:z", -0.5, 2.0).from(0.0)
	tw.parallel().tween_property(elevator_door2, ^"position:z", 0.5, 2.0).from(0.0)

func post_setup() -> void:
	var timer := Timer.new()
	add_child(timer)
	timer.one_shot = true
	timer.start(player.camera_shake_time + 2.0)
	timer.timeout.connect(open_elevator_doors)

func player_setup(p: PlayerCharacterBody3D) -> void:
	player = p
	var xz: Vector2 = Vector2(fposmod(player.global_position.x + 2.5, 5.0) - 2.5, fposmod(player.global_position.z + 2.5, 5.0) - 2.5)
	xz = xz.rotated(0.5 * PI * -elevator_exit_dir)
	player.rotation.y += 0.5 * PI * elevator_exit_dir
	player.velocity = player.velocity.rotated(Vector3.UP, 0.5 * PI * elevator_exit_dir)
	player.last_velocity = player.last_velocity.rotated(Vector3.UP, 0.5 * PI * elevator_exit_dir)
	player.global_position = Vector3(xz.x, player.global_position.y, xz.y)
	player.freeze = false

func _physics_process(delta: float) -> void:
	if player.global_position.y < -150.0 and not player.freeze:
		player.freeze = true
		var tw := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
		tw.tween_property(world_environment, ^"environment:tonemap_exposure", 0.0, 1.0).from(1.0)
		if player.global_position.x > 57.0:
			tw.chain().tween_callback(func():
				trigger_next_level.emit(-1)
			)
		else:
			tw.chain().tween_callback(func():
				world_environment.environment.tonemap_exposure = 0.0
				close_elevator_doors()
				player.rotation.y = PI * -0.5
				player.camera_rotation_x = 0.0
				player.velocity = Vector3.ZERO
				player.last_velocity = Vector3.ZERO
				player.global_position = Vector3(0.5, 0.0, 0.0)
				player.freeze = false
			).set_delay(0.5)
			tw.chain().tween_property(world_environment, ^"environment:tonemap_exposure", 1.0, 1.0).from(0.0)
			tw.chain().tween_callback(open_elevator_doors).set_delay(1.0)
