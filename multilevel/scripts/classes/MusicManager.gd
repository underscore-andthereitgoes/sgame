class_name MusicManager
extends Node

static var preloaded_music: Array[StringName] = []
static var play_from: Dictionary[StringName,float] = {}
static var music_players: Dictionary[StringName,AudioStreamPlayer] = {}

static func preload_music(music_id: StringName) -> void:
	preloaded_music.append(music_id)

## Stops all playing music except for one, sets the volume, and seeks to a specified position.
static func set_music(music_id: StringName, volume: float = 1.0, from_position: float = 0.0) -> void:
	var asm := music_players[music_id]
	for p: AudioStreamPlayer in music_players.values():
		if p.playing: p.stop()
	asm.volume_linear = 0.0#volume
	asm.play(from_position)

## Ensures music is playing (if it isn't, plays it from 0.0) at a specified volume (less than 0 to keep current volume).
static func playing_music(music_id: StringName, volume: float = -1.0) -> void:
	var asm := music_players[music_id]
	if not asm.playing:
		asm.play()
	if volume >= 0.0:
		asm.volume_linear = 0.0#volume

## Plays another music track at the same time as a current one, with a different volume, with advanced looping.
static func set_mix_music(base_music_id: StringName, music_id: StringName, volume: float, loop_offset_1: float, loop_offset_2: float, loop_length: float) -> void:
	var basm: AudioStreamPlayer = music_players.get(base_music_id)
	var ppos := 0.0
	if basm != null:
		ppos = basm.get_playback_position() + AudioServer.get_time_since_last_mix()
	var asm := music_players[music_id]
	if basm.playing:
		asm.volume_linear = 0.0#volume
		asm.play(loop_offset_2 + fposmod(ppos - loop_offset_1, loop_length) + AudioServer.get_time_to_next_mix())
	else:
		asm.stop()

## Changes the volume of a music track, without playing or pausing.
static func set_music_volume(music_id: StringName, volume: float) -> void:
	var asm := music_players[music_id]
	asm.volume_linear = 0.0#volume
