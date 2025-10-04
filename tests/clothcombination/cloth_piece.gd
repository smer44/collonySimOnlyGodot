extends Node3D
class_name ClothPiece



var part_map: Dictionary = {}
var parts :Array[MeshInstance3D] = []


func _ready() -> void:
	init_parts()
	if not parts:
		print("ClothPiece %s has no parts" % self.name)
	for p in parts:
		part_map[p.name] = p

func init_parts():
	for child in get_children():
		if child is ClothPart:
			parts.append(child)
			part_map[child.name] = child
		
	

	
