class_name StatsLabel
extends Label3D

var player: PlayerCharacterBody3D

var format: String = ""
func _ready() -> void:
	format = text
	text = ""

func _process(delta: float) -> void:
	if player:
		text = format.format(player.stats)
	else:
		text = ""
