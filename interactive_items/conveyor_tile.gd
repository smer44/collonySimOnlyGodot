#TODO- check positions
extends VisualStorageLike
class_name ConveyourTile

@export var nextTile : VisualStorageLike = null # next conveyour tile where the part will give out its items if 
@export var fromPosition : Node3D # position "on" the conveyour where item will start to move
@export var toPosition : Node3D # position "on" the conveyour where item will end its movement
@export var timeThrough: float = 1.5 # time period of moving the piece all along the conveyour tile
var add_cooldown: float
@export var max_items: int = 5 # amount of items what fit  on the conveyor tile in the same time
const EPS := 0.0001


@onready  var items_and_times: Queue = Queue.new(max_items)
var stucking_end:int = 0
var _add_timer := 0.0

func _ready():
	max_items = max(1, max_items)
	timeThrough = max(1.0, timeThrough)
	
func place_on_grid(grid:DummyGrid, vec:Vector3i, turn:int):
	var cell := grid.get_cell(vec)
	var nbr_delta :Vector3i= grid.nbrs_xz[turn]
	var forward_cell := grid.get_cell(vec+nbr_delta)
	
	
	

func addItem(item: Node3D) -> bool:
	#print_rich("[color=lime]ConveyorTile : got item : %s[/color] " % item)
	if _add_timer > 0.0:
		return false 
	if items_and_times.put([item, 0.0]):
		_add_timer = add_cooldown
		return true
	return false 
	
func updateItemPos(delta : float, n: int):
	var entry = items_and_times._iter_get(n)
	if entry == null:
		return 
	var item_and_pos : Array = entry
	var item : Node3D = item_and_pos[0]
	var item_pos :float = item_and_pos[1]
	
	var item_pos_limit = timeThrough - n * timeThrough/max_items
	
	item_pos = min(item_pos + delta, item_pos_limit)
	item_and_pos[1] = item_pos
	
func tryDeliverLastItem():
	if nextTile == null or items_and_times.is_empty():
		return
	var item_and_pos : Array = items_and_times.peek()
	var item : Node3D = item_and_pos[0]
	var item_pos :float = item_and_pos[1]	
	if (item_pos +EPS >= timeThrough):
		var transferred := nextTile.addItem(item)
		if transferred:
			items_and_times.pop()

func updateItems(delta:float):
	for n in range(max_items):
		updateItemPos(delta, n)
	tryDeliverLastItem()

		
func _update_item_transforms() -> void:
	for n in range(max_items):
		var entry = items_and_times._iter_get(n)
		if entry == null:
			continue 
		var item_and_pos : Array = entry
		var item : Node3D = item_and_pos[0]
		var itemTime :float = item_and_pos[1]					

		# you do not have to clamn here since it is done in itemPosition
		var pos := itemPosition(itemTime)
		var xf := item.global_transform
		xf.origin = pos
		item.global_transform = xf			
	
	



func update_vars(delta: float):
	add_cooldown = timeThrough / max_items
	_add_timer = max(_add_timer - delta, 0.0)
	

func _physics_process(delta: float) -> void:
	update_vars(delta)
	#Clamp _add_timer at 0 after subtracting, just to avoid it going very negative.
	
	updateItems(delta)
	_update_item_transforms()
	
	

func itemPosition(item_time: float) -> Vector3:
	var t : float = clamp(item_time / timeThrough, 0.0, 1.0)
	# Sample endpoints in world space and interpolate
	var from_world: Vector3 = fromPosition.global_transform.origin
	var to_world: Vector3 = toPosition.global_transform.origin
	return from_world.lerp(to_world, t)	


	

	
	

		
	
	
