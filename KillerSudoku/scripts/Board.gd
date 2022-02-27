extends ColorRect

const N_VERT = 9
const N_HORZ = 9
const N_CELLS = N_HORZ * N_VERT
const CELL_WIDTH = 54
const CELL_WIDTH3 = CELL_WIDTH/3
const CELL_WIDTH4 = CELL_WIDTH/4

const BOARD_WIDTH = CELL_WIDTH * N_HORZ
const BOX_WIDTH = CELL_WIDTH * N_HORZ / 3
const BOX_HEIGHT = CELL_WIDTH * N_VERT / 3

const COL = Color("#e0e0e0")
const MEMO_COL = Color("#ffff00")		# 黄色

var memo_labels = []		# メモ（候補数字）用ラベル配列（２次元）
var cur_num = -1

onready var g = get_node("/root/Global")

func _ready():
	pass # Replace with function body.

func _draw():
	draw_rect(Rect2(0, 0, BOX_WIDTH, BOX_HEIGHT), COL)
	draw_rect(Rect2(BOX_WIDTH*2, 0, BOX_WIDTH, BOX_HEIGHT), COL)
	draw_rect(Rect2(BOX_WIDTH, BOX_HEIGHT, BOX_WIDTH, BOX_HEIGHT), COL)
	draw_rect(Rect2(0, BOX_HEIGHT*2, BOX_WIDTH, BOX_HEIGHT), COL)
	draw_rect(Rect2(BOARD_WIDTH*2, BOX_HEIGHT*2, BOX_WIDTH, BOX_HEIGHT), COL)
	# 候補数字背景強調
	return
	if cur_num > 0 && memo_labels != []:
		for ix in range(N_CELLS):
			if memo_labels[ix][cur_num-1].text != "":
				var x = ix % N_HORZ
				var y = ix / N_HORZ
				var h = (cur_num - 1) % 3
				var v = (cur_num - 1) / 3
				var pos = g.memo_label_pos(x*CELL_WIDTH, y*CELL_WIDTH, h, v) - Vector2(1, 4)
				draw_rect(Rect2(pos, Vector2(CELL_WIDTH4, CELL_WIDTH3)), MEMO_COL)
