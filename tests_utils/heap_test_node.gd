extends Node


func _ready():

	var h = MinHeap.new()
	
	h.push(10, "ten")
	h.push(4, "four")
	h.push(7, "seven")
	assert(h.pop() == [4, "four"])
	
	#print(h.pop())  # -> {"key": 4, "value": "four"}
	
	
	h.push(3, "three")
	h.push(15, "fifteen")
	#print(h.pop())  # -> {"key": 3, "value": "three"}
	assert(h.pop() == [3, "three"])
	
	h.push(1, "one")
	h.push(8, "eight")
	#print(h.pop())  # -> {"key": 1, "value": "one"}
	#print(h.pop())  # -> {"key": 7, "value": "seven"}
	assert(h.pop() == [1, "one"])
	assert(h.pop() == [7, "seven"])
	
	
	h.push(2, "two")
	#print(h.pop())  # -> {"key": 2, "value": "two"}
	#print(h.pop())  # -> {"key": 8, "value": "eight"}
	#print(h.pop())  # -> {"key": 10, "value": "ten"}
	#print(h.pop())  # -> {"key": 15, "value": "fifteen"}
	
	assert(h.pop() == [2, "two"])
	assert(h.pop() == [8, "eight"])
	assert(h.pop() == [10, "ten"])
	assert(h.pop() == [15, "fifteen"])	
	print_rich("[color=green]Min Heap test done[/color]")
	
