extends LevelScene

@export var persistentpropsarea: Area3D
@export var extrawallsbody: StaticBody3D
@export var extrawallsarea: Area3D
@export var worldcsg: CSGCombiner3D
@export var props: Node3D
@export var sunlight: DirectionalLight3D
@export var any_items_area: Area3D

var player: PlayerCharacterBody3D

var preserve_props: Array[RigidBody3D] = []

var lc_start: int = 0

var item_check_wait: float = 10.0

func pre_level_change() -> void:
	
	lc_start = Time.get_ticks_msec()
	
	var interval: int = 0
	
	preserve_props = []
	
	extrawallsbody.show()
	extrawallsbody.collision_layer = 32
	
	for p in props.get_children():
		if not p.is_in_group(&"persistent_props"):
			p.queue_free()
			interval += 1
			if interval > 2:
				interval = 0
				await get_tree().process_frame
	
	await get_tree().process_frame
	worldcsg.queue_free()
	await get_tree().process_frame
	
	extrawallsbody.collision_layer = 32 | 1
	for prop in persistentpropsarea.get_overlapping_bodies():
		if prop is RigidBody3D:
			if prop.is_in_group(&"persistent_props"):
				preserve_props.append(prop)
	
	while Time.get_ticks_msec() < lc_start + 1000:
		await get_tree().process_frame

func sterilize_this_level() -> PackedByteArray:
	var d: Dictionary[StringName,Dictionary] = {}
	for prop in preserve_props:
		d[StringName(prop.name)] = {
			"L": prop.linear_velocity,
			"A": prop.angular_velocity,
			"p": prop.global_position,
			"r": prop.global_rotation
		}
	await get_tree().process_frame
	return var_to_bytes(d)

func data_setup(data: PackedByteArray) -> void:
	return

var music_cross: float = 0.0
func pre_setup() -> void:
	MusicManager.set_music(&"platform.day", 1.0, 0.0)
	MusicManager.set_mix_music(&"platform.day", &"platform.night", 0.0, 0.0, 0.0, 999999999.0)
	MusicManager.set_mix_music(&"platform.day", &"platform.building", 0.0, 0.0, 0.0, 999999999.0)

func post_setup() -> void:
	return

func player_setup(player: PlayerCharacterBody3D) -> void:
	self.player = player

func _process(delta: float) -> void:
	
	if (not sunlight.visible) and music_cross <= 0.00001:
		MusicManager.set_mix_music(&"platform.day", &"platform.night", music_cross, 0.0, 0.0, 999999999.0)
		MusicManager.set_mix_music(&"platform.day", &"platform.building", music_cross, 0.0, 0.0, 999999999.0)
	music_cross = move_toward(music_cross, 0.0 if sunlight.visible else 1.0, delta / (4*60.0/130.0))
	MusicManager.playing_music(&"platform.day", 1.0 - music_cross)
	var m := player in persistentpropsarea.get_overlapping_bodies()
	MusicManager.set_music_volume(&"platform.night", 0.0 if m else music_cross)
	MusicManager.set_music_volume(&"platform.building", music_cross if m else 0.0)
	
	if not sunlight.visible:
		if player in persistentpropsarea.get_overlapping_bodies() and player not in extrawallsarea.get_overlapping_bodies():
			trigger_next_level.emit(-1)
	else:
		if item_check_wait <= 0.0:
			var found_item: bool = false
			for a in any_items_area.get_overlapping_bodies():
				if a is HoldableRigidBody3D and a.mass > 0.05:
					found_item = true
					break
			if not found_item:
				hide()
				trigger_next_level.emit(1)
		else:
			item_check_wait -= delta
