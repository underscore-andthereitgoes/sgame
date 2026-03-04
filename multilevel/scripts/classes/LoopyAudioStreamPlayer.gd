class_name LoopyAudioStreamPlayer
extends AudioStreamPlayer

var loop_start: float = 0.0
var loop_end: float = INF
var loop_enabled: bool = false

func _process(delta: float) -> void:
	if playing and loop_enabled:
		var t := get_playback_position() + AudioServer.get_time_since_last_mix()
		if t >= loop_end:
			t = t - (loop_end - loop_start) + AudioServer.get_time_to_next_mix()
			seek(t)
