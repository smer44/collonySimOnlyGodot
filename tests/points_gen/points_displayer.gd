extends Control


#var display_scale:float= min(size.x, size.y)
@export var display_scale:float= 40.0
@export var point_radius: float = 4.0
@export var point_color: Color = Color.RED
@export var rect_color: Color = Color.BLUE
@export var triangle_color: Color = Color.GREEN

var pts: Array[Vector2] 
var bbox : Rect2
var super_triangle : Array[Vector2] 
var triangulation : Array
var pan_offset: Vector2 = Vector2.ZERO
var _is_panning: bool = false



func _ready() -> void:
	pts = Random2dCalc.sample_naive(20,0.1,3)
	print("Points gen test: pts :" , pts)
	print("Points gen test: display_scale:" , display_scale)
	bbox = TriangulateCalc.bouding_box_2d(pts)
	print("Points gen test: Bbox :" , pts)
	super_triangle= TriangulateCalc.super_triangle_for_bounding_box(bbox)
	print("Points gen test: super_triangle :" , super_triangle)
	
	triangulation = TriangulateCalc.triangulate(pts)
	

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		#update_scale()
		pass

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if  event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			display_scale *= 1.1
			queue_redraw()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			display_scale *= 0.9
			queue_redraw()
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			_is_panning = event.pressed
	elif event is InputEventMouseMotion:
		if _is_panning: 
			pan_offset += event.relative
			queue_redraw()
			
	
	
func scale_point_from_center(p: Vector2) -> Vector2:
	var center = size * 0.5
	return center + pan_offset +p * display_scale
	
func scale_point_by_bounds(p: Vector2) -> Vector2:
	return pan_offset + p * display_scale

func draw_points(pts: Array[Vector2] ):
	for p in pts:
		var scaled_p = scale_point_from_center(p)
		draw_circle(scaled_p, point_radius, point_color)			

func draw_my_rect(r : Rect2):
	var scaled_rect = Rect2(scale_point_from_center(r.position), r.size * display_scale)
	draw_rect(scaled_rect, rect_color, false, 2.0, false)

func draw_scaled_triangle(tri: Array[Vector2]):
	var scaled_triangle: PackedVector2Array = []
	for tp in tri:
		scaled_triangle.append(scale_point_from_center(tp))	
	scaled_triangle.append(scaled_triangle[0])	
	draw_polyline(scaled_triangle, triangle_color)

func _draw():
	draw_points(pts)
	draw_my_rect(bbox)
	for tri in triangulation:
		draw_scaled_triangle(tri)

	
