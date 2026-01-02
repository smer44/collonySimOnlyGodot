@tool
extends Sprite2D

# Option A: provide a Shader resource (.gdshader imported as Shader)
@export var shader_resource: Shader

# Option B: paste shader code directly
@export_multiline var shader_code: String = ""

@export var apply_on_ready: bool = true
@export var force_draw_after_apply: bool = true
@export var time_speed_value: float = 1.0


func _ready() -> void:
	if apply_on_ready:
		apply_shader()

func apply_shader() -> void:
	var code := _get_code()
	if code.is_empty():
		push_error("No shader provided. Set 'shader_resource' or 'shader_code'.")
		return

	# Basic preflight checks (these catch common mistakes, not GPU compile errors).
	for msg in _basic_sanity_check(code):
		# Using push_error so you also see it in the editor debugger/errors.
		push_error(msg)

	# Build shader + material and assign to Sprite2D.
	var sh := Shader.new()
	sh.code = code

	var mat := ShaderMaterial.new()
	mat.shader = sh
	material = mat
	
	mat.set_shader_parameter("time_speed", time_speed_value)
	
	#print("ShaderMaterial assigned to Sprite2D. If compilation fails, Godot will print shader errors to Output/Debugger.")

	# Trigger compilation/logging sooner by forcing at least one draw and yielding frames.
	if force_draw_after_apply:
		RenderingServer.force_draw()

	# Give the renderer a couple frames to compile; errors (if any) will appear in Output.
	await get_tree().process_frame
	await get_tree().process_frame
	
	


func _get_code() -> String:
	if shader_resource != null:
		return shader_resource.code
	return shader_code

func _basic_sanity_check(code: String) -> Array[String]:
	var issues: Array[String] = []

	if not code.contains("shader_type"):
		issues.append("Missing 'shader_type ...;' declaration.")
		
	elif not code.contains("shader_type canvas_item"):
		issues.append("Expected 'shader_type canvas_item;' for Sprite2D/CanvasItem shaders.")
	
	if code.contains("float TAU"):
		issues.append("TAU redefinition may be an error.")
		

	# Not strictly required for all shaders, but common expectations:
	if not code.contains("void fragment"):
		issues.append("No 'void fragment()' found. Sprite2D shaders typically define fragment().")

	# Common typo: TEXTURE/UV usage without canvas_item
	if code.contains("TEXTURE") and not code.contains("canvas_item"):
		issues.append("Uses TEXTURE but shader_type is not canvas_item (Sprite2D expects canvas_item).")

	# Warn on very large dynamic loops (common compile/perf issue)
	if code.contains("while"):
		issues.append("Contains 'while' loop: many platforms/drivers reject or poorly handle while loops in shaders.")

	return issues
