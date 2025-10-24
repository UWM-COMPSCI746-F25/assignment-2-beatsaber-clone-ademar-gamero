extends XRController3D

@export var raycast_length = 1.0
@export var sword_color = Color.WHITE  # Assign in inspector: Green for left, Blue for right
var collided_area = null
var last_pos = Vector3.ZERO
var velocity = Vector3.ZERO
var raycast_active = false
var occulus_button_hold = false
var occulus_button_time = 0.0
var required_hold_time = 0.5
var xr_origin: XROrigin3D = null
var target_cube: RigidBody3D = null
signal pose_centered
# Color definitions
const COLOR_LEFT = Color(1.0, 0.0, 0.0)  # Red for left hand
const COLOR_RIGHT = Color(0.0, 1.0, 0.0)  # Green for right hand
func _ready():
	last_pos = global_position
	$"LineRenderer".visible = false
	
	var node_name = name.to_lower()
	if "lefthand" in node_name:
		sword_color = COLOR_LEFT
		print("Left controller detected - Red sword")
	elif "righthand" in node_name:
		sword_color = COLOR_RIGHT
		print("Right controller detected - Green sword")

	
	
	# Find the XR origin
	xr_origin = get_tree().get_first_node_in_group("xr_origin")
	if not xr_origin:
		for node in get_tree().root.find_children("*", "XROrigin3D"):
			xr_origin = node
			break
	
	# Find the cube
	target_cube = get_tree().get_first_node_in_group("target_cube")
	if not target_cube:
		# Try finding by script or name
		for node in get_tree().root.find_children("*", "RigidBody3D"):
			if node.has_method("hit_by_sword"):
				target_cube = node
				break

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	velocity = (global_position - last_pos) / delta
	last_pos = global_position
	
	if occulus_button_hold:
		occulus_button_time += delta
		if occulus_button_time >= required_hold_time:
			emit_signal("pose_centered")
			occulus_button_hold = false
	
func _physics_process(delta):
	if not raycast_active:
		return
		
	var space_state = get_world_3d().direct_space_state
	var origin = global_position 
	var dir = global_transform.basis.z * -1
	var end = origin + (dir * raycast_length)
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	var result = space_state.intersect_ray(query)
	
	$"LineRenderer".points[0] = origin + dir * 0.1
	$"LineRenderer".points[1] = end
	
	if result:
		$"LineRenderer".points[1] = result.position
		
		# The collider is the RigidBody3D, but the script is on its parent
		var target = result.collider
		
		# Debug: print what we hit
		print("Hit object: ", target.name, " Type: ", target.get_class())
		print("Parent: ", target.get_parent().name if target.get_parent() else "No parent")
		
		# Check the collider first
		if target.has_method("hit_by_sword"):
			print("Collider has hit_by_sword method")
			target.hit_by_sword(sword_color)
		# If not, check the parent (this is where your script is!)
		elif target.get_parent() and target.get_parent().has_method("hit_by_sword"):
			print("Parent has hit_by_sword method")
			target.get_parent().hit_by_sword(sword_color)
		else:
			print("hit_by_sword method not found on collider or parent")

func _on_area_3d_area_entered(area):
	collided_area = area
	
func _on_area_3d_area_exited(area):
	collided_area = null

func _on_button_pressed(name):
	if name == "ax_button":
		# Toggle line renderer visibility and raycasting
		raycast_active = not raycast_active
		$"LineRenderer".visible = raycast_active
	elif name == "menu_button":
		occulus_button_hold = true
		occulus_button_time = 0.0

func _on_button_released(name):
	if name == "menu_button":
		occulus_button_hold = false
		occulus_button_time = 0.0
