extends RefCounted
class_name  AbstractPersonState

#var color: Color = Color.WHITE

func enter(owner : Person):
	print("Person %s entered state : %s" % [owner, self.name ])
	var mat : Material = owner.get_child(0).material_override
	#HumanDummyMesh3D
	if not mat:
		mat = StandardMaterial3D.new()
	mat.albedo_color = self.color
	owner.get_child(0).material_override = mat

func process (owner : Person, delta: float):
	pass
