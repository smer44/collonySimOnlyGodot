extends Node
class_name ClothCombination


@export var all_pieces: Array[ClothPiece] = []
@export var pieces: Array[ClothPiece] = []

var combo := {}
func _ready() -> void:
	make_all_invisible(all_pieces)
	combo = build(pieces)
	make_combo_visible(combo)
	#print('ClothCombination: combo:' , combo)
	print(PP.pp_dict_of_lists(combo))

	


static func make_all_invisible(pieces: Array[ClothPiece]):
	for p in pieces:
		for m in p.parts:
			m.visible = false
			
			
static func make_combo_visible( combo : Dictionary):	
	for key  in combo:
		var row:Array = combo[key]
		for part in row:
			#var piece :ClothPiece= combo[key]
			#var part: MeshInstance3D = piece.part_map[key]
			part.visible = true 


static func build(pieces: Array[ClothPiece]) -> Dictionary:

	var combo := {}
	
	# List all items in combo first:
	
	for p in pieces:
		for key in p.part_map:
			
			if key in combo:
				var lst : Array = combo[key]
				var part :ClothPart=  p.part_map[key]
				var last_part :ClothPart= lst[lst.size()-1]
				if part.covers(last_part):
					print(part.pp()," covers:" , last_part.pp())
					lst = [part]
					combo[key] = lst
				else:
					if last_part.covers(part):
						print(part.pp()," is already covered by :",  last_part.pp())
					else:
						print(part.pp()," coexists with :" , last_part.pp())
						if part.max_priority < last_part.max_priority:
							lst.pop_back()
							lst.append(part)
							lst.append(last_part)
						else:
							lst.append(part)
				
			else:
										
				var part :ClothPart=  p.part_map[key]
				print('is new: ', part.pp())		
				var lst := [part]
				combo[key] = lst
			
			
				#if there was old piece:
				
			

	return combo

				 
