@tool
extends Node
class_name TerrainBaker

@export var function: TerrainSmartFunction
@export var size_x: int = 64
@export var size_y: int = 16
@export var size_z: int = 64
@export var bake : bool :
	set (value):
		bake_to_cache(folder, "TerrainBaker" + get_resource_name(function))
@export var folder : String = "res://baked_terrains/"
	
static func get_resource_name(resource: Resource)->String:
	return resource.resource_path.get_file().trim_suffix('.tres')

func bake_to_cache(folder:String, file:String):
	print("baking to cashe: " , folder , file)
	if function == null:
		push_error("No function assigned!")
		return
	
	var cache := TerrainCache.new()
	cache.size_x = size_x
	cache.size_y = size_y
	cache.size_z = size_z
	
	cache.elevations.resize(size_x * size_z)
	
	for z in range(size_z):
		for x in range(size_x):
			var elev = function.get_elevation_at(x, z)
			cache.elevations[z * size_x + x] = elev

	ensure_save(cache,folder,file)
	
	
	


static func format_folder(base_in: String, default_prefix:String = "res://") -> String:
	var base := base_in.strip_edges()
	# Normalize Windows-style separators
	base = base.replace("\\", "/")
	# Remove any leading slashes from the path portion only
	base = base.lstrip("/").rstrip("/")	
	if  not base.begins_with("res://") and not base.begins_with("user://"):
		base = default_prefix + base 
	base += "/"
	return base
	
static func format_ressource_path(folder:String, file:String) ->String:
	file = file.replace("\\", "/")
	file = file.lstrip("/").rstrip("/")	
	file = file + ".tres"
	return folder + file 
	
static func ensure_save(resource: Resource, folder:String, file:String):
	folder = format_folder(folder)
	DirAccess.make_dir_recursive_absolute(folder)
	var path := format_ressource_path(folder,file)
	ResourceSaver.save(resource, path)
	
	
	

	
