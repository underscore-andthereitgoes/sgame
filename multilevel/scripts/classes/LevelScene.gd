class_name LevelScene
extends Node3D

## Function called when starting to change to the next level, before [method sterilize_this_level] and [method pre_setup] (of next level). Maybe wait for process frames to avoid lagging.
func pre_level_change() -> void: await get_tree().process_frame
## Function to convert this level's data into a sterile format to pass to the next level. Called after [method pre_setup] (of next level). Maybe wait for process frames to avoid lagging.
func sterilize_this_level() -> PackedByteArray:
	await get_tree().process_frame
	return PackedByteArray()
## Function to load the current level from the previous level's sterile data. Called after [method pre_setup]. Maybe wait for process frames to avoid lagging. Doesn't run if this scene is the first scene.
func data_setup(data: PackedByteArray) -> void: await get_tree().process_frame
## Function that runs first when this level is being initialised. Called after [method pre_level_change] (on the previous level) and before everything else. Maybe wait for process frames to avoid lagging.
func pre_setup() -> void: await get_tree().process_frame
## Function that runs last when this level is being initialised. Called after everything else.
func post_setup() -> void: return
## Function to do stuff to the player when loading this level. Called after [method data_setup] and before [method post_setup].
func player_setup(player: PlayerCharacterBody3D) -> void: return

## Emit this signal when you want to change to the next scene. Pass -1 to travel to the next level, or at least 0 to travel to an ending.
signal trigger_next_level(ending: int)



# template
'''

func pre_level_change() -> void:
	pass

func sterilize_this_level() -> PackedByteArray:
	await get_tree().process_frame
	return PackedByteArray()

func data_setup(data: PackedByteArray) -> void:
	await get_tree().process_frame

func pre_setup() -> void:
	await get_tree().process_frame

func post_setup() -> void:
	pass

func player_setup(player: PlayerCharacterBody3D) -> void:
	pass

'''
