extends Node3D

var initial_scene: LevelScene
@export var player: PlayerCharacterBody3D

## Array of levels, in order.
@export var levels: Array[PackedScene]
var level_index: int = 0

## Array of ending scenes. Array index is the ending ID.
@export var endings: Array[PackedScene]
var ending_index: int = -1

## Start at a specific level instead of the first level.
@export var debug__init_level_index: int = -1

class LoopyAS extends Node:
	
	var stream: AudioStream
	var loop_start: float = 0.0
	var loop_end: float = INF
	var loop_enabled: bool = false
	
	@warning_ignore("shadowed_variable")
	func _init(stream: AudioStream) -> void:
		self.stream = stream
	
	@warning_ignore("shadowed_variable")
	func loopy(loop_start: float, loop_end: float) -> LoopyAS:
		self.loop_enabled = true
		self.loop_start = loop_start
		self.loop_end = loop_end
		return self

@onready var musics: Dictionary[StringName,LoopyAS] = {
	"platform.day": LoopyAS.new(preload("res://music/platform.day.mp3")).loopy(8*60.0/130.0, 24*60.0/130.0),
	"platform.night": LoopyAS.new(preload("res://music/platform.night.mp3")).loopy(8*60.0/130.0, 24*60.0/130.0),
	"platform.building": LoopyAS.new(preload("res://music/platform.building.mp3")).loopy(8*60.0/130.0, 24*60.0/130.0),
	"building.green": LoopyAS.new(preload("res://music/building.green.mp3")).loopy(8*60.0/130.0, 24*60.0/130.0),
}

func ready_deferred() -> void:
	await get_tree().process_frame
	await current_scene.pre_setup()
	player.process_mode = Node.PROCESS_MODE_INHERIT
	current_scene.player_setup(player)
	current_scene.post_setup()
	current_scene.process_mode = Node.PROCESS_MODE_INHERIT
	current_scene.trigger_next_level.connect.call_deferred(func(ending: int): next_level(ending), CONNECT_ONE_SHOT)

var current_scene: LevelScene

func _ready() -> void:
	
	var music_players: Dictionary[StringName,AudioStreamPlayer] = {}
	for id in musics.keys():
		var asm := LoopyAudioStreamPlayer.new()
		var las := musics[id]
		asm.stream = las.stream
		asm.autoplay = false
		asm.volume_linear = 0.0
		asm.playing = false
		asm.name = "LoopyAudioStreamPlayer~music~" + str(id).validate_node_name()
		asm.loop_enabled = las.loop_enabled
		asm.loop_start = las.loop_start
		asm.loop_end = las.loop_end
		add_child(asm)
		move_child(asm, 0)
		music_players[id] = asm
	MusicManager.music_players.merge(music_players, true)
	
	if debug__init_level_index >= 0:
		if initial_scene:
			remove_child(initial_scene)
			initial_scene.free()
		initial_scene = levels[debug__init_level_index].instantiate()
		add_child(initial_scene)
		level_index = debug__init_level_index
	else:
		if not initial_scene:
			initial_scene = levels[0].instantiate()
			add_child(initial_scene)
	current_scene = initial_scene
	initial_scene = null
	current_scene.process_mode = Node.PROCESS_MODE_DISABLED
	player.process_mode = Node.PROCESS_MODE_DISABLED
	ready_deferred.call_deferred()

func transition_level(next: LevelScene) -> void:
	
	await current_scene.pre_level_change()
	
	next.hide()
	next.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(next)
	await next.pre_setup()
	
	var data := await current_scene.sterilize_this_level()
	await next.data_setup(data)
	next.player_setup(player)
	next.post_setup()
	
	next.process_mode = Node.PROCESS_MODE_INHERIT
	
	next.show()
	current_scene.hide()
	current_scene.queue_free()
	
	current_scene = next
	current_scene.trigger_next_level.connect(func(ending: int): next_level(ending), CONNECT_ONE_SHOT)

func next_level(ending: int):
	if ending < 0:
		level_index += 1
		var level := levels[level_index % levels.size()]
		await transition_level(level.instantiate())
	else:
		ending_index = ending
		var level := endings[ending_index]
		await transition_level(level.instantiate())
