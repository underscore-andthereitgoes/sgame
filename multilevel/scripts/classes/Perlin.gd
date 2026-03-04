class_name Perlin
extends Node

var s: int = 1

var scale: Vector2 = Vector2.ONE
var amplitude: float = 1.0

var phase: Vector2 = Vector2.ZERO
var rotation: float = 0.0

func _init(base_seed: int, base_scale: float = 1.0, base_amplitude: float = 1.0) -> void:
	s = base_seed
	seed(s)
	phase = Vector2(randf(), randf())
	rotation = randf() * TAU
	scale = Vector2(base_scale, base_scale)
	amplitude = base_amplitude

func random_gradient(ix: int, iy: int) -> Vector2:
	
	seed(ix)
	var a: int = randi()
	seed(iy)
	var b: int = randi()
	
	seed(s ^ (a - b))
	return Vector2.from_angle(randf() * TAU)

func dot_grid_gradient(ix: int, iy: int, xy: Vector2) -> float:
	var gradient := random_gradient(ix, iy)
	return gradient.dot(xy - Vector2(ix, iy))

func sample_base(xy: Vector2) -> float:
	
	var x0: int = floori(xy.x)
	var y0: int = floori(xy.y)
	var x1: int = x0 + 1
	var y1: int = y0 + 1
	
	var fxy := xy.posmod(1.0)
	
	var n00 := dot_grid_gradient(x0, y0, xy)
	var n10 := dot_grid_gradient(x1, y0, xy)
	var n01 := dot_grid_gradient(x0, y1, xy)
	var n11 := dot_grid_gradient(x1, y1, xy)
	
	var ix0 := lerpf(n00, n10, fxy.x)
	var ix1 := lerpf(n01, n11, fxy.x)
	
	var ixy := lerpf(ix0, ix1, fxy.y)
	
	return ixy

func sample(xy: Vector2) -> float:
	return sample_base((xy / scale) - phase) * amplitude
