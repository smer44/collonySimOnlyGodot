extends RefCounted
class_name TerrainSimUtils


static func update_image_from_array(array : PackedFloat32Array, image:Image,  w:int, h:int) -> void:
	var i := 0
	for gy in range(w):
		for gx in range(h):
			image.set_pixel(gx, gy, Color(array[i], 0, 0, 1))
			i += 1


static func new_images_and_tex(w : int , h : int ) -> Array:
	var surface_image := Image.create(w, h, false, Image.FORMAT_RF)
	var surface_tex := ImageTexture.create_from_image(surface_image)
	return [surface_image,surface_tex]
