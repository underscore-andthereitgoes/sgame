class_name GreenroomsChunkGenerator
extends Node3D

var player_stuck: bool = false

var can_generate_exit: bool = false
var exit: Vector2i = Vector2i.ZERO
var exit_wall_chunk: Vector2i
# [X-, Z-, X+, Z+]
var exit_direction: int = -1

var wall_chance_min: float = 0.0
var wall_chance_max: float = 0.8
const no_exit_distance_squared: int = floori(pow(200.0 / 5.0, 2.0))
const stuck_ending_distance_squared: float = pow(250.0, 2.0)
@onready var wall_noise := Perlin.new(randi(), 0.02, 1.0)

@export var template_empty: Node3D
@export var template_wallx: Node3D
@export var template_wallz: Node3D
@export var template_wallxz: Node3D

@export_group("exit")
@export var exit_node: Area3D
@export var exit_corridorbody: StaticBody3D
@export var exit_corridorcollider: CollisionShape3D
@export var elevator_doors_body: StaticBody3D
@export var elevator_doors_trigger: Area3D
@export var elevator_door1: MeshInstance3D
@export var elevator_door2: MeshInstance3D

const chunk_size: float = 5.0

const generate_within_distance_squared: int = int(pow(5, 2.0))
const ungenerate_out_of_distance_squared: int = int(pow(6, 2.0))

var generate_nearby_array: Array[Vector2i] = []
func _create_gennear_array():
	var r: int = ceili(sqrt(generate_within_distance_squared))
	for x in range(-r, r+1):
		for z in range(-r, r+1):
			var v := Vector2i(x, z)
			if v.length_squared() <= generate_within_distance_squared:
				generate_nearby_array.append(v)
	generate_nearby_array.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return Vector2(a).angle() < Vector2(b).angle())
	generate_nearby_array.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.length_squared() < b.length_squared())

var generated_chunks: Dictionary[Vector2i,Node3D] = {}

var walls: Dictionary[Vector2i,int] = {}

func place_exit() -> void:
	exit_node.show()
	exit_node.process_mode = Node.PROCESS_MODE_INHERIT
	exit_node.position = Vector3(exit.x * chunk_size, 0.0, exit.y * chunk_size)
	exit_node.rotation = Vector3(0.0, PI * 0.5 * -exit_direction, 0.0)

var exit_state: int = 0

func update_exit(player: PlayerCharacterBody3D) -> void:
	
	if exit_state == 0:
		
		if exit_node.visible:
			
			var exit_wall_chunk_node: Node3D = generated_chunks.get(exit_wall_chunk, null)
			if exit_wall_chunk_node:
			
				var target_staticbody: StaticBody3D = exit_wall_chunk_node.get_node(NodePath("wallbody" + ("z" if (exit_direction & 1) == 1 else "x")))
				
				if player in exit_node.get_overlapping_bodies():
					
					if player in elevator_doors_trigger.get_overlapping_bodies():
						exit_state = 1
						elevator_doors_body.collision_layer = 1
						
						var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
						tw.tween_property(elevator_door1, ^"position:z", 0.0, 2.0)
						tw.parallel().tween_property(elevator_door2, ^"position:z", 0.0, 2.0)
						tw.chain().tween_callback(func():
							exit_state = 2
							print("doors closed")
							for c in generated_chunks.keys():
								generated_chunks[c].queue_free()
							generated_chunks.clear()
						)
					
					else:
						elevator_doors_body.collision_layer = 0
					
					target_staticbody.process_mode = Node.PROCESS_MODE_DISABLED
					target_staticbody.hide()
					exit_corridorbody.process_mode = Node.PROCESS_MODE_INHERIT
					exit_corridorbody.show()
					exit_corridorcollider.disabled = false
					return
				
				target_staticbody.process_mode = Node.PROCESS_MODE_INHERIT
				target_staticbody.show()
		exit_corridorbody.process_mode = Node.PROCESS_MODE_DISABLED
		exit_corridorbody.hide()
		exit_corridorcollider.disabled = true
		elevator_doors_body.collision_layer = 0

func generate_chunk(chunk: Vector2i) -> void:
	if generated_chunks.has(chunk): return
	
	var walls_index := 0
	var wall_chance := lerpf(wall_chance_min, wall_chance_max, wall_noise.sample(Vector2(chunk)) * 0.5 + 0.5)
	if randf() < wall_chance: walls_index |= 0b01
	if randf() < wall_chance: walls_index |= 0b10
	
	if chunk.length_squared() < no_exit_distance_squared and exit_state == 0 and exit_direction == -1 and can_generate_exit and randf() < 0.5:
		if randf() < 0.5:
			if (walls_index & 0b01) > 0:
				# X wall
				if randf() < 0.5:
					# inside
					exit = chunk
					exit_direction = 2
				else:
					# outside
					exit = chunk + Vector2i(1, 0)
					exit_direction = 0
				exit_wall_chunk = chunk
				place_exit()
		else:
			if (walls_index & 0b10) > 0:
				# Z wall
				if randf() < 0.5:
					# inside
					exit = chunk
					exit_direction = 3
				else:
					# outside
					exit = chunk + Vector2i(0, 1)
					exit_direction = 1
				exit_wall_chunk = chunk
				place_exit()
	
	var chunk_node: Node3D = [template_empty, template_wallx, template_wallz, template_wallxz][walls_index]
	chunk_node = chunk_node.duplicate()
	add_child(chunk_node)
	chunk_node.position = Vector3(chunk.x * chunk_size, 0.0, chunk.y * chunk_size)
	generated_chunks.set(chunk, chunk_node)
	walls.set(chunk, walls_index)

func ungenerate_far_away(player_chunk: Vector2i) -> void:
	if exit_state == 0 and exit_direction >= 0 and player_chunk.distance_squared_to(exit) > ungenerate_out_of_distance_squared:
		exit_direction = -1
		exit_node.hide()
		exit_node.process_mode = Node.PROCESS_MODE_DISABLED
	for c in generated_chunks.keys():
		if player_chunk.distance_squared_to(c) > ungenerate_out_of_distance_squared:
			generated_chunks[c].queue_free()
			generated_chunks.erase(c)
			walls.erase(c)

func generate_nearby(player_chunk: Vector2i, max_count: int) -> bool:
	var i: int = 0
	for delta_chunk in generate_nearby_array:
		var chunk := player_chunk + delta_chunk
		if not generated_chunks.has(chunk):
			generate_chunk(chunk)
			i += 1
			if i >= max_count:
				return true
	return false

func _ready() -> void:
	_create_gennear_array()
	exit_node.process_mode = Node.PROCESS_MODE_DISABLED
	exit_node.hide()

var next_escape_check: float = 0.0

func process_with_player_pos(delta: float, player_pos: Vector3) -> void:
	if exit_state == 0:
		var player_chunk := Vector2i(floori(player_pos.x / chunk_size + 0.5), floori(player_pos.z / chunk_size + 0.5))
		generate_nearby(player_chunk, 1)
		ungenerate_far_away(player_chunk)
		next_escape_check += delta
		if next_escape_check > 2.0:
			next_escape_check = fmod(next_escape_check, 2.0)
			var can_escape := try_escape(player_chunk)
			if not can_escape:
				player_stuck = true
				print("stuck")
			elif (player_pos * Vector3(1.0, 0.0, 1.0)).length_squared() >= stuck_ending_distance_squared:
				player_stuck = true
				can_generate_exit = false
				exit_direction = -1
				exit_node.hide()
				exit_node.process_mode = Node.PROCESS_MODE_DISABLED
				print("wandering")

func slow_generate_only(player_pos: Vector3) -> bool:
	var player_chunk := Vector2i(floori(player_pos.x / chunk_size + 0.5), floori(player_pos.z / chunk_size + 0.5))
	return generate_nearby(player_chunk, 1)


func try_escape(from: Vector2i) -> bool:
	return try_escape_recurse(
		from,
		[from],
		ungenerate_out_of_distance_squared,
		{from: true}
	)

func try_escape_recurse(from: Vector2i, next: Array[Vector2i], max_distance_squared: int, filled: Dictionary[Vector2i,bool]) -> bool:
	if next.size() == 0: return false
	var next_set: Dictionary[Vector2i,bool] = {}
	for n in next:
		if n.distance_squared_to(from) >= max_distance_squared: return true
		if exit_direction >= 0 and n == exit: return true
		filled.set(n, true)
		var walls_here: int = walls.get(n, 0)
		var walls_nx: int = walls.get(n + Vector2i(-1, 0), 0)
		var walls_nz: int = walls.get(n + Vector2i(0, -1), 0)
		if (walls_here & 0b01) == 0:
			var n2 := n + Vector2i(1, 0)
			if not filled.has(n2):
				next_set.set(n2, true)
		if (walls_here & 0b10) == 0:
			var n2 := n + Vector2i(0, 1)
			if not filled.has(n2):
				next_set.set(n2, true)
		if (walls_nx & 0b01) == 0:
			var n2 := n + Vector2i(-1, 0)
			if not filled.has(n2):
				next_set.set(n2, true)
		if (walls_nz & 0b10) == 0:
			var n2 := n + Vector2i(0, -1)
			if not filled.has(n2):
				next_set.set(n2, true)
	return try_escape_recurse(from, next_set.keys(), max_distance_squared, filled)
