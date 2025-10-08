extends CharacterBody3D

@export var grid_map: Node3D
var state
var path: Array = []
var current_index = 0
var move_speed = 5.0
var fall_speed = .5

var idle_state
var moving_state
var falling_state

func _ready(): 
	idle_state = preload("res://Units/States/IdleState.gd").new() 
	moving_state = preload("res://Units/States/MovingState.gd").new() 
	falling_state = preload("res://Units/States/FallingState.gd").new() 
	state = idle_state 
	
	# --- Aqui é o teste --- 
	path = [Vector3(0,0,0), Vector3(1,0,0), Vector3(2,0,0)] 
	current_index = 0 
	enter_state(moving_state)

func _physics_process(delta):
	print("Unit is at :" , global_position)
	if state:
		state.update(self, delta)
		

func enter_state(new_state):
	state = new_state

func can_move_to(cell_pos: Vector3) -> bool:
	if not grid_map.is_cell_valid(cell_pos):
		return false
	if grid_map.is_cell_blocked(cell_pos, self):
		return false
	return true

func get_cell_below() -> Vector3:
	var pos = global_transform.origin
	var below_pos = pos - Vector3(0, 1, 0)
	if grid_map.is_cell_valid(below_pos):
		return grid_map.get_cell_position(below_pos)
	return Vector3(pos.x, -1000, pos.z)
