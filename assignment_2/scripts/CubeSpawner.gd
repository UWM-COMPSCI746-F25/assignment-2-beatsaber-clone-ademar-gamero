extends Node3D

@export var left_cube_scene: PackedScene  # Red cube scene
@export var right_cube_scene: PackedScene  # Green cube scene
@export var spawn_distance = 12.0  # How far away cubes spawn
@export var spawn_range_x = 2.0  # Horizontal range (-x to +x)
@export var spawn_range_y_min = 0.3  # Minimum height
@export var spawn_range_y_max = 2.0  # Maximum height

# Color definitions
const COLOR_LEFT = Color(1.0, 0.0, 0.0)  # Red for left hand
const COLOR_RIGHT = Color(0.0, 1.0, 0.0)  # Green for right hand

var spawn_timer = 0.0
var next_spawn_time = 0.0
var xr_origin: XROrigin3D = null

func _ready():
	print("CubeSpawner _ready() called")
	
	# Find the XR origin to spawn relative to player position
	xr_origin = get_tree().get_first_node_in_group("xr_origin")
	
	if not xr_origin:
		print("XR Origin not found in group, searching by type...")
		for node in get_tree().root.find_children("*", "XROrigin3D"):
			xr_origin = node
			print("Found XR Origin: ", node.name)
			break
	else:
		print("Found XR Origin in group: ", xr_origin.name)
	
	if not xr_origin:
		push_error("CubeSpawner: XR Origin not found!")
	
	if not left_cube_scene:
		push_error("CubeSpawner: No left cube scene assigned in inspector!")
	else:
		print("Left cube scene is assigned: ", left_cube_scene.resource_path)
	
	if not right_cube_scene:
		push_error("CubeSpawner: No right cube scene assigned in inspector!")
	else:
		print("Right cube scene is assigned: ", right_cube_scene.resource_path)
	
	# Set initial spawn time
	next_spawn_time = 2.0
	print("Next spawn time: ", next_spawn_time)

func _process(delta):
	if not left_cube_scene or not right_cube_scene:
		return
		
	if not xr_origin:
		return
	
	spawn_timer += delta
	
	# Check if it's time to spawn a new cube
	if spawn_timer >= next_spawn_time:
		print("Spawning cube at timer: ", spawn_timer)
		spawn_cube()
		spawn_timer = 0.0
		next_spawn_time = 2.0
		print("Next spawn in: ", next_spawn_time, " seconds")

func spawn_cube():
	print("spawn_cube() called")
	
	# Randomly choose left or right cube scene
	var is_left = randf() < 0.5
	var cube_scene = left_cube_scene if is_left else right_cube_scene
	var cube_color = COLOR_LEFT if is_left else COLOR_RIGHT
	var cube_type = "LEFT (Red)" if is_left else "RIGHT (Green)"
	
	
	# Instantiate the cube
	var cube = cube_scene.instantiate()
	if not cube:
		push_error("Failed to instantiate cube!")
		return
	
	add_child(cube)
	print("Cube instantiated and added as child")
	print("Cube type: ", cube.get_class())
	print("Cube has script: ", cube.get_script() != null)
	

		# Player's position
	var player_pos = xr_origin.global_position

	# Random spawn position in a sphere around the player
	var random_angle = randf() * TAU  # Random angle (can be behind player)
	var random_distance = randf_range(15.0,20.0)  # Spawn 2-4 meters away
	var random_height_offset = randf_range(1.0, 1.5)  # Within 1 meter above/below player
	
	var random_x = player_pos.x + cos(random_angle) * random_distance
	var random_y = player_pos.y + random_height_offset
	var random_z = player_pos.z + sin(random_angle) * random_distance
	# Calculate spawn position
	var spawn_pos = Vector3(
		random_x,
		random_y,
		random_z
	)
	
	print("Spawn position: ", spawn_pos)
	
	# Set cube position
	cube.global_position = spawn_pos
	
	# Wait one frame for the cube to be fully ready
	await get_tree().process_frame
	print("set color: " ,cube.has_method("set_cube_color"))
	print("Has set_target: ", cube.has_method("set_target"))
	# Set cube's color to player position
	if cube.has_method("set_cube_color"):
		cube.set_cube_color(cube_color)
		print("Set cube color: ", cube_color)
		
	# Set cube's target to player position
	if cube.has_method("set_target"):
		var target = xr_origin.global_position
		target.y = random_y  # Keep same height
		cube.set_target(target)
		print("Set cube target: ", target)
	else:
		print("WARNING: Cube doesn't have set_target method")
		print("Available methods: ", cube.get_method_list())
