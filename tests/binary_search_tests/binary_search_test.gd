extends Node

func _ready() -> void:
	print("Running binary_search_floor tests...")
	_test_basic()
	_test_edge_cases()
	
	
func _test_basic() -> void:
	var arr := PackedFloat32Array([0.0, 2.0, 5.0, 9.0])
	
	assert(BinarySearch.search_floor(arr, -1.0) == -1)  # below range
	assert(BinarySearch.search_floor(arr, 0.0) == 0)    # exact match
	assert(BinarySearch.search_floor(arr, 1.0) == 0)    # between 0 and 2
	assert(BinarySearch.search_floor(arr, 2.0) == 1)    # exact
	assert(BinarySearch.search_floor(arr, 4.99) == 1)   # just below 5
	assert(BinarySearch.search_floor(arr, 5.0) == 2)    # exact
	assert(BinarySearch.search_floor(arr, 7.5) == 2)    # between 5 and 9
	assert(BinarySearch.search_floor(arr, 9.0) == 3)    # exact
	assert(BinarySearch.search_floor(arr, 10.0) == 3)   # above range
	
	print("✅ _test_basic passed")

func _test_edge_cases() -> void:
	# Empty array
	assert(BinarySearch.search_floor(PackedFloat32Array(), 3.0) == -1)
	
	# Single element array
	var single := PackedFloat32Array([5.0])
	assert(BinarySearch.search_floor(single, 0.0) == -1)
	assert(BinarySearch.search_floor(single, 5.0) == 0)
	assert(BinarySearch.search_floor(single, 10.0) == 0)
	
	print("✅ _test_edge_cases passed")
