extends CharacterBody3D
class_name PlayerCharacterBody3D

var freeze: bool = false

const FLOOR_SLIDE: Array[float] = [
	0.8, # air
	0.2, # ground
]

const HITBOX_SIZE: Vector2 = Vector2(0.6, 1.3)
const CAMERA_HEIGHT: float = 1.1

const SPEED: float = 3.0
const SPEED_SPRINT: float = 6.0
const ACCELERATION: float = 8.0
const ACCELERATION_SPRINT: float = 24.0
const MAX_SPEED_MULTIPLIER: Array[float] = [
	1.0, # air
	1.0, # ground
]

const JUMP_VELOCITY: float = 4.0

var buffered_jump: bool = false

var was_on_floor: bool = true
var last_velocity: Vector3 = Vector3.ZERO

var camera: Camera3D
var camera_rotation_x: float = 0.0
const CAMERA_SENSITIVITY: float = 0.003
const ROTATE_SENSITIVITY: float = 0.02

@export_group("UI")
@export var camera_ui: Control
@export var crosshair: Control

@onready var camera_ray: RayCast3D
const CAMERA_RAY_COLLISION_MASK: int = 0b1001

var player_collider: CollisionShape3D

var holding: HoldableRigidBody3D = null
const HOLD_DISTANCE: float = 1.0
const HOLD_FORCE: float = 200.0
const HOLD_TORQUE: float = 0.5
const HOLD_GRAVITY_SCALE: float = 0.6
const HOLD_LINEAR_DAMP: float = 15.0
const HOLD_ANGULAR_DAMP: float = 5.0
const DROPPED_PROP_COLLISION_LAYER: int = 0b0010
const MAX_HOLD_DISTANCE_SQUARED: float = 5.0
var held_center_of_mass := Vector3.ZERO
var rotate_held := Vector2.ZERO

var camera_shake_time: float = 0.0
var camera_shake_intensity: float = 0.0
var camera_shake_speed: float = 0.0
var camera_shake_phase: float = 0.0

var stats: Dictionary[String,String] = {}
var stats_raw: Dictionary[String,Variant] = {
	"time": 0.0,
	"jumps": 0,
	"distance_travelled": 0.0
}

func update_stats() -> void:
	var time_seconds := str(fmod(stats_raw["time"], 60.0)).pad_decimals(1).pad_zeros(2)
	var time_minutes := str(floori(stats_raw["time"] / 60.0) % 60).pad_zeros(2)
	var time_hours := str(floori(stats_raw["time"] / 3600.0))
	
	stats = {
		"time": time_hours + ":" + time_minutes + ":" + time_seconds,
		"jumps": str(stats_raw["jumps"]),
		"distance_travelled": str(stats_raw["distance_travelled"]).pad_decimals(1) + " m",
	}


func update_camera(delta: float) -> void:
	camera.rotation = Vector3(camera_rotation_x, 0.0, 0.0)
	camera.position = Vector3(0.0, CAMERA_HEIGHT, 0.0)
	if camera_shake_time > 0.0:
		camera_shake_phase += delta / camera_shake_speed
		camera_shake_phase = fmod(camera_shake_phase, 2.0)
		camera.position.x += sin(camera_shake_phase * PI) * camera_shake_intensity
		camera.position.y += cos(camera_shake_phase * TAU) * camera_shake_intensity
		camera.rotation.z = -sin(camera_shake_phase * TAU) * camera_shake_intensity * TAU
		camera_shake_time -= delta
	else:
		camera_shake_phase = 0.0

func _ready() -> void:
	velocity = Vector3.ZERO
	rotation = Vector3(0.0, 0.0, 0.0)
	
	camera = Camera3D.new()
	camera.name = "Camera"
	add_child(camera)
	camera_ui.reparent.call_deferred(camera)
	camera_ui.set_anchors_and_offsets_preset.call_deferred(Control.PRESET_FULL_RECT)
	camera.position = Vector3(0.0, CAMERA_HEIGHT, 0.0)
	camera.cull_mask = 0b00000000001111111111
	camera.make_current()
	camera.fov = 100.0
	camera.far = 4000.0
	
	camera_ray = RayCast3D.new()
	camera_ray.name = "CameraRayCast"
	camera.add_child(camera_ray)
	camera_ray.position = Vector3.ZERO
	camera_ray.target_position = Vector3(0.0, 0.0, -camera.far)
	camera_ray.collide_with_areas = true
	camera_ray.collide_with_bodies = true
	camera_ray.collision_mask = CAMERA_RAY_COLLISION_MASK
	camera_ray.add_exception(self)
	
	player_collider = CollisionShape3D.new()
	player_collider.name = "Collider"
	var shape: CapsuleShape3D = CapsuleShape3D.new()
	shape.radius = HITBOX_SIZE.x / 2.0
	shape.height = HITBOX_SIZE.y
	player_collider.shape = shape
	add_child(player_collider)
	player_collider.position = Vector3(0.0, HITBOX_SIZE.y * 0.5, 0.0)
	
	floor_max_angle = deg_to_rad(50.0)
	axis_lock_angular_x = true
	axis_lock_angular_y = true
	axis_lock_angular_z = true
	collision_mask |= DROPPED_PROP_COLLISION_LAYER

func _input(event: InputEvent) -> void:
	
	if event.is_action_pressed(&"mouse_lock") and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed(&"mouse_unlock"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
		if Input.is_action_pressed(&"rotate") and holding is HoldableRigidBody3D:
			rotate_held += event.screen_relative
		else:
			rotation.y -= event.screen_relative.x * CAMERA_SENSITIVITY
			camera_rotation_x = clampf(camera_rotation_x - event.screen_relative.y * CAMERA_SENSITIVITY, -0.5 * PI, 0.5 * PI)

func _physics_process(delta: float) -> void:
	
	if freeze:
		
		last_velocity = Vector3.ZERO
		was_on_floor = false
		buffered_jump = false
		
	else:
		
		stats_raw["time"] += delta
		
		var floor_material: int = 0
		
		if is_on_floor():
			
			floor_material = 1
			
			if velocity.y <= 0.0:
				velocity.y = 0.0
			
		else:
			velocity += get_gravity() * delta
			
			if position.y < -1000.0:
				position = Vector3(0.0, 1000.0, 0.0)
		
		buffered_jump = (buffered_jump and Input.is_action_pressed(&"jump")) or Input.is_action_just_pressed(&"jump")
		if is_on_floor() and buffered_jump:
			buffered_jump = false
			velocity.y = JUMP_VELOCITY
			stats_raw["jumps"] += 1
		
		var sprinting: bool = Input.is_action_pressed(&"sprint") and is_on_floor()
		
		var move_vector: Vector2 = Input.get_vector(&"left", &"right", &"forward", &"backward")
		var target_velocity: Vector3 = Vector3.ZERO
		
		if move_vector:
			var speed: float = maxf(
				(SPEED_SPRINT if sprinting else SPEED) * MAX_SPEED_MULTIPLIER[floor_material],
				(velocity * Vector3(1.0, 0.0, 1.0)).length()
			)
			target_velocity = basis * Vector3(move_vector.x, 0.0, move_vector.y).normalized() * speed
		
		var acceleration_multiplier: float = 1.0 / FLOOR_SLIDE[floor_material]
		velocity = (
			Vector3(0.0, velocity.y, 0.0) +
			(velocity * Vector3(1.0, 0.0, 1.0)).move_toward(
				target_velocity,
				(ACCELERATION_SPRINT if sprinting else ACCELERATION) * acceleration_multiplier * delta
			)
		)
		
		velocity = Vector3(0.0, velocity.y, 0.0) + velocity * Vector3(1.0, 0.0, 1.0) * FLOOR_SLIDE[floor_material] ** delta
		
		was_on_floor = is_on_floor()
		last_velocity = velocity
		
		if not is_instance_valid(holding) or holding.is_queued_for_deletion(): holding = null
		
		var holdable: HoldableRigidBody3D = null
		var was_holding := holding
		
		var hold_target := camera.to_global(Vector3.FORWARD * HOLD_DISTANCE)
		
		if camera_ray.is_colliding():
			if camera_ray.get_collision_point().distance_squared_to(hold_target) <= MAX_HOLD_DISTANCE_SQUARED:
				var collider = camera_ray.get_collider()
				if collider is HoldableRigidBody3D and not collider.is_queued_for_deletion():
					holdable = collider
		
		if Input.is_action_just_pressed(&"hold") and holdable is HoldableRigidBody3D:
			holding = holdable
			held_center_of_mass = PhysicsServer3D.body_get_direct_state(holding.get_rid()).center_of_mass_local
			holding.gravity_scale = HOLD_GRAVITY_SCALE
			holding.linear_damp = HOLD_LINEAR_DAMP
			holding.angular_damp = HOLD_ANGULAR_DAMP
			holding.collision_layer &= ~DROPPED_PROP_COLLISION_LAYER
		else:
			if Input.is_action_pressed(&"hold") and holding is HoldableRigidBody3D:
				var difference := hold_target - holding.to_global(held_center_of_mass)
				if difference.length_squared() > MAX_HOLD_DISTANCE_SQUARED:
					holding = null
				else:
					holding.constant_force = difference * HOLD_FORCE * holding.mass
					holding.constant_torque = Vector3.ZERO
					holding.angular_velocity += Quaternion(Vector3.UP * camera.global_basis.inverse(), rotate_held.x * ROTATE_SENSITIVITY).get_euler()
					holding.angular_velocity += Quaternion(Vector3.RIGHT * camera.global_basis.inverse(), rotate_held.y * ROTATE_SENSITIVITY).get_euler()
			else: holding = null
		
		if holding != null:
			crosshair.modulate = Color(0.6, 1.0, 1.0)
		elif holdable != null:
			crosshair.modulate = Color(0.6, 1.0, 0.6)
		else:
			crosshair.modulate = Color(1.0, 0.6, 1.0)
		
		if holding != was_holding and was_holding is HoldableRigidBody3D:
			was_holding.constant_force = Vector3.ZERO
			was_holding.constant_torque = Vector3.ZERO
			was_holding.gravity_scale = 1.0
			was_holding.linear_damp = 0.0
			was_holding.angular_damp = 0.0
			was_holding.collision_layer |= DROPPED_PROP_COLLISION_LAYER
		
		rotate_held = Vector2.ZERO
		
		update_stats()
		
		move_and_slide()
		
		stats_raw["distance_travelled"] += velocity.length() * delta
	
	update_camera(delta)
