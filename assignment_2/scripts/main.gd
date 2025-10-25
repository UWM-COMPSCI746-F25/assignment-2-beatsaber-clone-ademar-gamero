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
