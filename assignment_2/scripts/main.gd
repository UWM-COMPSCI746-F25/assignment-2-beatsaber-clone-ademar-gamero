extends Node3D

var xr_interface: XRInterface
var xr_origin: XROrigin3D

func _ready():
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR initialized successfully")
		# Turn off v-sync!
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		# Change our main viewport to output to the HMD
		get_viewport().use_xr = true
	else:
		print("OpenXR not initialized, please check if your headset is connected")
	
	# Get the XROrigin3D node
	xr_origin = $XROrigin3D 
	if not xr_origin:
		push_error("XROrigin3D not found!")

func _on_right_hand_pose_centered():
	if not xr_origin:
		return
		
	# Find the nearest cube
	var cubes = get_tree().get_nodes_in_group("cubes")
	if cubes.is_empty():
		print("No cubes to recenter to")
		return
	
	var nearest_cube = null
	var nearest_distance = INF
	
	for cube in cubes:
		var distance = xr_origin.global_position.distance_to(cube.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_cube = cube
	
	if nearest_cube:
		# Calculate direction to cube
		var to_cube = nearest_cube.global_position - xr_origin.global_position
		to_cube.y = 0  # Keep on horizontal plane
		var angle_to_cube = atan2(to_cube.x, to_cube.z)
		
		# Rotate XR Origin to face the cube
		xr_origin.rotation.y = angle_to_cube
		
		print("Recentered to face cube at: ", nearest_cube.global_position)
