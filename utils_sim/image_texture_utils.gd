extends RefCounted
class_name ImageTextureUtils

static func array_to_image(arr: PackedFloat32Array , image :Image, w:int , h: int)-> void:
	var i := 0
	for gy in range(h):
		for gx in range(w):
			image.set_pixel(gx, gy, Color(arr[i], 0, 0, 1))
			i+=1
			
			
static func arrays2_to_image(arr: PackedFloat32Array ,arr2: PackedFloat32Array , image :Image, w:int , h: int)-> void:
	var i := 0
	for gy in range(h):
		for gx in range(w):
			image.set_pixel(gx, gy, Color(arr[i], arr2[i], 0, 1))
			i+=1

static func new_surface_and_mass_images_and_tex(w : int , h : int ) -> Array:
	var surface_image := Image.create(w, h, false, Image.FORMAT_RF)
	var surface_tex := ImageTexture.create_from_image(surface_image)
	var mass_image := Image.create(w, h, false, Image.FORMAT_RF)
	var mass_tex := ImageTexture.create_from_image(mass_image)
	return [surface_image,surface_tex, mass_image, mass_tex ]
	
	

static func update_surface_and_mass_textures(surface:  PackedFloat32Array, surface_image :Image, surface_tex :ImageTexture,mass:PackedFloat32Array,  mass_image : Image ,mass_tex : ImageTexture, w : int , h : int ) -> void:
	
	var i := 0
	for gy in range(w):
		for gx in range(h):	
			surface_image.set_pixel(gx, gy, Color(surface[i], 0, 0, 1))
			mass_image.set_pixel(gx, gy, Color(mass[i], 0, 0, 1))
			i += 1

	surface_tex.update(surface_image)
	mass_tex.update(mass_image)
