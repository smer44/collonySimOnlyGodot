extends PointDisplayer
class_name QuadTreeTest


var quadtree = QuadTree.new(Rect2(0,0,1,1),4)
var selected= null
var cursor = null
var colors = [Color.GREEN, Color.YELLOW, Color.ORANGE, Color.RED, Color.PURPLE, Color.DARK_BLUE]



func _ready() -> void:
	self.set_anchors_preset(Control.PRESET_FULL_RECT)
	pts = Random2dCalc.sample_naive(100,0.01,3)
	#print(pts)
	quadtree.insert_all(pts)
	print(quadtree.size_deep())

	#PP.pp_quad_tree(quadtree)
	

func _process(delta: float) -> void:
	cursor  = get_viewport().get_mouse_position()
	cursor = screen_to_point_coord(cursor)
	
	selected = quadtree.nearest(cursor)

	#print(cursor , ' : ' ,selected)
	queue_redraw()
	
func draw_quad_tree(q: QuadTree):
	for tup in q.points_with_depth():
		var p:Vector2 = tup[0]
		var depth : int = tup[1]
		var color = colors[depth % colors.size()]
		#print("displaying:" , p, "depth :" , depth)
		draw_point(p,2,  color)		
		

func _draw():
	draw_quad_tree(quadtree)
	if selected:
		draw_point(selected,3,  Color.AQUA)
		if selected and cursor:
			draw_my_line(cursor,selected,Color.AQUA,2)
			
			
