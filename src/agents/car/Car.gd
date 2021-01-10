extends KinematicBody2D

export var max_speed: = 350
export var steer_force: = 0.1
export var look_ahead: = 100
export var num_rays: = 16

var actual_speed: int

# context array
var ray_directions = []
var interest = []
var danger = []

var chosen_dir = Vector2.ZERO
var velocity = Vector2.ZERO
var acceleration = Vector2.ZERO

var speed_offset: int

func _ready():
	interest.resize(num_rays)
	danger.resize(num_rays)
	ray_directions.resize(num_rays)
	for i in num_rays:
		var angle = i * 2 * PI / num_rays
		ray_directions[i] = Vector2.RIGHT.rotated(angle)
	
	randomize()
	speed_offset = randi()%100+1 

func _process(_delta):
	look_at(global_position + velocity)

func _physics_process(delta):
	set_interest()
	set_danger()
	choose_direction()
	var desired_velocity = chosen_dir.rotated(rotation) * (max_speed - speed_offset)
	velocity = velocity.linear_interpolate(desired_velocity, steer_force)
	rotation = velocity.angle()
	var _c = move_and_collide(velocity * delta)


func set_interest():
	# Set interest in each slot based on world direction
	
	if owner and owner.has_method("get_path_direction"):
		var path_direction = owner.get_path_direction(position)
		for i in num_rays:
			var d = ray_directions[i].rotated(rotation).dot(path_direction)
			interest[i] = max(0, d)
	# If no world path, use default interest
	else:
		set_default_interest()


func set_default_interest():
	# Default to moving forward
	for i in num_rays:
		var d = ray_directions[i].rotated(rotation).dot(transform.x)
		interest[i] = max(0, d)


func set_danger():
	# Cast rays to find danger directions

	var space_state = get_world_2d().direct_space_state
	for i in num_rays:
		var result = space_state.intersect_ray(
			position,
			position + ray_directions[i].rotated(rotation) * look_ahead,
			[self]
		)
		danger[i] = 1.0 if result else 0.0


func choose_direction():
	# Eliminate interest in slots with danger

	for i in num_rays:
		if danger[i] > 0.0:
			interest[i] = 0.0
	# Choose direction based on remaining interest

	chosen_dir = Vector2.ZERO
	for i in num_rays:
		chosen_dir += ray_directions[i] * interest[i]
	chosen_dir = chosen_dir.normalized()
