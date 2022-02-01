extends ColorRect

const N_VERT = 9
const N_HORZ = 9
const N_CELLS = N_HORZ * N_VERT
const CELL_WIDTH = 54
const WD = 8

var cage_ix = []

func _ready():
	pass # Replace with function body.

func _draw():
	if cage_ix == []: return
	var col = Color.orange
	var ix = 0
	for y in range(N_VERT):
		var py = y * CELL_WIDTH
		for x in range(N_HORZ):
			var px = x * CELL_WIDTH
			if x == 0 || cage_ix[ix-1] != cage_ix[ix]:
				draw_line(Vector2(px, py-WD/2), Vector2(px, py+CELL_WIDTH+WD/2), col, WD)
			if y == 0 || cage_ix[ix-N_HORZ] != cage_ix[ix]:
				draw_line(Vector2(px-WD/2, py), Vector2(px+CELL_WIDTH+WD/2, py), col, WD)
			ix += 1
	draw_line(Vector2(CELL_WIDTH*N_HORZ, 0), Vector2(CELL_WIDTH*N_HORZ, CELL_WIDTH*N_VERT+WD/2), col, WD)
	draw_line(Vector2(0, CELL_WIDTH*N_VERT), Vector2(CELL_WIDTH*N_HORZ+WD/2, CELL_WIDTH*N_VERT), col, WD)
	pass
