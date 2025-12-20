extends Node


static func uvs_down(subdiv: int) -> Array[Vector2i]:
	"""
	# Downward triangle (apex at top):
	# u = 0..subdiv
	# v = 0..u
	"""
	assert(subdiv >= 0)
	var out: Array[Vector2i] = []
	for u in range(subdiv + 1):
		for v in range(u + 1):
			out.append(Vector2i(u, v))
	return out


static func uvs_up(subdiv: int) -> Array[Vector2i]:
	"""
	# Upward triangle (base at top, apex at bottom):
	# u = 0..subdiv
	# row_len(u) = (subdiv - u + 1)
	# v = 0..row_len-1
	
	"""
	assert(subdiv >= 0)
	var out: Array[Vector2i] = []
	for u in range(subdiv + 1):
		var row_len := subdiv - u + 1
		for v in range(row_len):
			out.append(Vector2i(u, v))
	return out
	
func _ready() -> void:
	var subdiv :=3
	
	for plane_nr in range(5):
		var pts := uvs_down(subdiv)
		for p in pts:
			var ij :=IcoSphereUtils.plane_04(plane_nr,p.x,p.y)
			print(plane_nr , p , " : ", ij  )
	for plane_nr in range(5, 10):
		var pts := uvs_down(subdiv)
		for p in pts:
			var ij :=IcoSphereUtils.plane_510(plane_nr,p.x,p.y,subdiv)
			#print(plane_nr , p , " : ", ij  )
		
	for plane_nr in range(10, 15):
		var pts := uvs_up(subdiv)
		for p in pts:
			var ij :=IcoSphereUtils.plane_1014(plane_nr,p.x,p.y,subdiv)
			#print(plane_nr , p , " : ", ij  )
			
	for plane_nr in range(15,20):
		var pts := uvs_up(subdiv)
		for p in pts :
			var ij :=IcoSphereUtils.plane_1520(plane_nr,p.x,p.y,subdiv)
			#print(plane_nr , p , " : ", ij  )
			
	



	
		
