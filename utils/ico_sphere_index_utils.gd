extends RefCounted
class_name IcoSphereIndexUtils


static func plane_04(plane_rn: int, u: int, v: int)-> Vector2i:
	var max_j := u * 5
	var j := plane_rn*u+v
	j = j if j < max_j else 0
	return Vector2i(u,j)
	
static func plane_510(plane_rn: int, u: int, v: int, subdiv : int)-> Vector2i:
	var max_nr := subdiv * 5
	return Vector2i(subdiv+u,(max_nr +(plane_rn-5)*subdiv+v - u) % max_nr )
	
static func plane_1014(plane_rn: int, u: int, v: int, subdiv : int)-> Vector2i:
	var max_nr := subdiv * 5
	return Vector2i(subdiv+u,((plane_rn-10)*subdiv+v) % max_nr )
	

static func plane_1520(plane_rn: int, u: int, v: int, subdiv : int)-> Vector2i:
	var max_j := (subdiv - u) * 5
	var j := (plane_rn -15 )*subdiv + v 
	j = j if j < max_j else 0
	return Vector2i(2 * subdiv + u, j)
