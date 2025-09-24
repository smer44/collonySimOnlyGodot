extends RefCounted
class_name Queue

var array : Array
var _head : int 
var _tail : int 
var _count : int 


func _init(n: int):
	array = []
	array.resize(n)
	self._head = 0 
	self._tail = 0
	self._count = 0

func size():
	return _count
	
func capacity() -> int:
	return self.array.size()
		
func is_full()-> int:
	return _count == self.array.size()

func put(value ) -> bool:
	if is_full():
		return false 
	array[_tail] = value
	_tail = _tail+1
	if _tail == array.size():
		_tail = 0
	_count +=1
	return true 

func is_empty():
	return 	self._count == 0

func peek():
	if self._count == 0:
		return null 
	return array[_head]
	
func pop():
	if self._count == 0:
		return null 
	var value = array[_head] 
	array[_head] = null
	_head += 1
	if _head == array.size():
		_head = 0
	_count -= 1 
	return value	
	 

# Iterator support
func _iter_init(iter):
	if is_empty():
		return false
	iter[0] = 0
	return true


func _iter_next(iter):
	var iter_next = iter[0]+1
	iter[0] = iter_next
	return iter_next < _count

func _iter_get(n):	
	return array[(_head + n) % array.size()]
	
	
