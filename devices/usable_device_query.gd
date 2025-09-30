extends RefCounted
class_name UsableDeviceQuery


const satisfy_needs = {"Drink": UsableDevice.UsageType.Drink , 
						"Fun" : UsableDevice.UsageType.GainFun}

static func _get_current_scene_root() -> Node:
	# Works from static context: grab the SceneTree via Engine
	return Engine.get_main_loop().current_scene


static func find_first_direct_child(usage_type: UsableDevice.UsageType) -> UsableDevice:
	var root := _get_current_scene_root()
	for child in root.get_children():
		if child is UsableDevice and child.usageType == usage_type:
			return child
	return null
	
static func find_first_device_to_satisfy(need : Need) -> UsableDevice:
	var usage_type : UsableDevice.UsageType = satisfy_needs[need.name]
	return find_first_direct_child(usage_type)


static func find_direct_children(usage_type: UsableDevice.UsageType) -> Array[UsableDevice]:
	var result: Array[UsableDevice] = []
	var root := _get_current_scene_root()
	for child in root.get_children():
		if child is UsableDevice and child.usageType == usage_type:
			result.append(child)
	return result
