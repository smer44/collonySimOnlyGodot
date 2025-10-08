extends Node

@export var moving: Node
@export var time_factor := 1.0
@export var points: Array
@export var loop:=true
var tick_count: int = 0
var acc : PackedFloat32Array

func _ready():
	acc = InterpolateCalc.accumulate_distance(points,loop)

func _physics_process(delta: float) -> void:
	var time:= delta * tick_count *time_factor
	var pos = InterpolateCalc.position_at_time(points,acc,time,loop)
	moving.global_position = pos 
	tick_count+=1
	
