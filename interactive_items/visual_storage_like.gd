extends StaticBody3D
class_name VisualStorageLike


func addItem(item: Node3D) -> bool:
	push_error("VisualStorage.addItem must be implemented by subclasses: %s" % self)
	return false
