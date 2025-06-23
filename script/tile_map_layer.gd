extends TileMapLayer

const TILE_ID = 2
const TILE_ATLAS_COORDS = Vector2i(0, 0)

# Veľmi veľká plocha
const MAP_WIDTH = 1100
const MAP_HEIGHT = 120

func _ready():
	generate_grid()

func generate_grid():
	# Optimalizované generovanie gridu
	var tile_pos := Vector2i.ZERO
	for x in range(-1, MAP_WIDTH):
		for y in range(-1, MAP_HEIGHT):
			tile_pos.x = x
			tile_pos.y = y
			set_cell(tile_pos, TILE_ID, TILE_ATLAS_COORDS)
