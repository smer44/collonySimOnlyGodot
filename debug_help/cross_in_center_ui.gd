extends Control

@export var thickness: float = 2.0

func _ready():
	# Make sure our Control covers the whole screen
	anchor_left = 0
	anchor_top = 0
	anchor_right = 1
	anchor_bottom = 1
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Create horizontal line
	var h_line = ColorRect.new()
	h_line.color = Color.WHITE
	h_line.anchor_left = 0
	h_line.anchor_right = 1
	h_line.anchor_top = 0.5
	h_line.anchor_bottom = 0.5
	h_line.custom_minimum_size = Vector2(0, thickness)
	add_child(h_line)
	
	# Create vertical line
	var v_line = ColorRect.new()
	v_line.color = Color.WHITE
	v_line.anchor_left = 0.5
	v_line.anchor_right = 0.5
	v_line.anchor_top = 0
	v_line.anchor_bottom = 1
	v_line.custom_minimum_size = Vector2(thickness, 0)
	add_child(v_line)
