extends TileMapLayer

const TILE_ID = 1
const TILE_ATLAS_COORDS = Vector2i(0, 0)
const TILE_SIZE = 64

const MAP_WIDTH = 1100 
const MAP_HEIGHT = 120

func _ready():
	generate_grid()

func generate_grid():
	for x in range(-1, MAP_WIDTH):
		for y in range(-1, MAP_HEIGHT):
			set_cell(Vector2i(x, y), TILE_ID, TILE_ATLAS_COORDS)  
