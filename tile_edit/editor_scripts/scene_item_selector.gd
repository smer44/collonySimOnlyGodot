extends Node
class_name SceneItemSelector

@export var items: Array[SceneSelectionItem]
@export var icon_size := Vector2(100, 100)
@export var hBoxContainer : HBoxContainer
@export var tileEditor : TileEditor


var selectedPackedScene: PackedScene

func _ready():
	for it in items:
		_add_item(it, hBoxContainer)
	# tell the Container/layout system to recompute sizes now
	hBoxContainer.queue_sort()
	#row.minimum_size_changed()
	#scroll.queue_sort()	
		

func _add_item(item : SceneSelectionItem, row :HBoxContainer):
	var btn := TextureButton.new()

	btn.texture_normal  = item.icon
	btn.ignore_texture_size = true
	btn.custom_minimum_size = icon_size
	btn.stretch_mode = TextureButton.STRETCH_SCALE
	# ignore_texture_size and TextureButton.STRETCH_SCALE will set 
	# size to be zero, so set custom minimum size of it to have some size.
	btn.pressed.connect(func(): _on_select(item.scene))
	row.add_child(btn)
	
func _on_select(scene: PackedScene):
	selectedPackedScene = scene 
	tileEditor.set_prefab(selectedPackedScene)
	print("selected : ", selectedPackedScene)
	

	
