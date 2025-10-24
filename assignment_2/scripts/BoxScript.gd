extends Node3D
@export var speed = 2.0
@export var hit_sound: AudioStream
var target_position = Vector3.ZERO
var destroyed = false
var has_target = false
var cube_color = Color.WHITE
var rigid_body: RigidBody3D
const COLOR_LEFT = Color(1.0, 0.0, 0.0)  # Red for left hand
const COLOR_RIGHT = Color(0.0, 1.0, 0.0)  # Green for right hand

func _ready():
	# Get the RigidBody3D child
	rigid_body = get_node("RigidBody3D")  # Adjust name if different
	if rigid_body:
		rigid_body.freeze = true
		rigid_body.gravity_scale = 0.0

func set_cube_color(color: Color):
	cube_color = color

func set_target(target: Vector3):
	target_position = target
	has_target = true
	print("has_target set to TRUE - cube should now move")

func _process(delta):
	if destroyed:
		return
	
	if not has_target:
		# Only print this occasionally to avoid spam
		if Engine.get_process_frames() % 60 == 0:
			print("Cube at ", global_position, " waiting for target...")
		return
	
	# Move toward target
	var direction = (target_position - global_position).normalized()
	var movement = direction * speed * delta
	global_position += movement
	
	
	# Check if cube has passed the target (went past the user)
	var distance_to_target = global_position.distance_to(target_position)
	
	# If very close to target or has gone past it, destroy silently
	if distance_to_target < 0.5:
		print("Cube reached target, destroying")
		queue_free()  # Destroy without sound
		return
	
	# Alternative check: if cube has moved past the target position
	var to_target = target_position - global_position
	if to_target.dot(direction) < 0:  # Cube has passed the target
		print("Cube passed target, destroying")
		queue_free()  # Destroy without sound

func hit_by_sword(sword_color: Color):
	if destroyed:
		return
	
	print("Hit by sword! Cube color: ", cube_color, " Sword color: ", sword_color)
	
	# Check if colors match (with small tolerance for floating point comparison)
	if not cube_color.is_equal_approx(sword_color):
		print("Wrong color! Cube: ", cube_color, " Sword: ", sword_color)
		return  # Don't destroy if colors don't match
	
	print("Color match! Destroying cube")
	destroyed = true
	
	# Create audio player and add it to the scene root (not the cube)
	var audio_player = AudioStreamPlayer3D.new()
	audio_player.stream = load("res://sounds/121195__gusgus26__hit-plastic-box.wav")  # Change to your sound path
	audio_player.global_position = global_position  # Play sound at cube's position
	get_tree().root.add_child(audio_player)  # Add to scene root, not cube
	audio_player.play()
	
	# Auto-delete the audio player when sound finishes
	audio_player.finished.connect(audio_player.queue_free)

	
	queue_free()
