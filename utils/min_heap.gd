extends RefCounted
class_name MinHeap


var heap: Array = []

func _init():
	heap = []
	
func push(key: int, value) -> void:
	heap.append([key, value])
	_bubble_up(heap.size() - 1)
	
func pop():
	#assert (not heap.is_empty(), "Trying to pop from empty heap")
	if heap.is_empty():
		return null
	var root = heap[0]
	#removes and returns the last element of the array:
	var last = heap.pop_back()
	if heap.size() > 0:
		heap[0] = last
		_bubble_down(0)
	return root
	
	
	
	
	
# INNER HELPERS:
@warning_ignore("integer_division")
# Internal: restore heap upward
func _bubble_up(index: int) -> void:
	while index > 0:
		var parent :int = (index - 1) / 2
		if heap[index][0] < heap[parent][0]:
			_swap(index, parent)
			index = parent
		else:
			break

# Internal: restore heap downward
func _bubble_down(index: int) -> void:
	var size = heap.size()
	while true:
		var left = index * 2 + 1
		var right = index * 2 + 2
		var smallest = index
		
		if left < size and heap[left][0] < heap[smallest][0]:
			smallest = left
		if right < size and heap[right][0] < heap[smallest][0]:
			smallest = right
		
		if smallest != index:
			_swap(index, smallest)
			index = smallest
		else:
			break




func _swap(i: int, j: int) -> void:
	var temp = heap[i]
	heap[i] = heap[j]
	heap[j] = temp
