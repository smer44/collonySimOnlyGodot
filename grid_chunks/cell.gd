class_name Cell
extends RefCounted

enum CellFillingType { Air, Water, Sand, Soil, Stone }

var items: Array = [] # 1D array of item objects (your game-defined type)
var color: Color = Color(0, 0, 0)
var obstacle: bool = false
