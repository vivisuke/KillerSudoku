extends Node2D

const N_VERT = 9
const N_HORZ = 9
const N_CELLS = N_HORZ * N_VERT
const CELL_WIDTH = 54
const CELL_WIDTH3 = CELL_WIDTH/3
const BIT_1 = 1
const BIT_2 = 1<<1
const BIT_3 = 1<<2
const BIT_4 = 1<<3
const BIT_5 = 1<<4
const BIT_6 = 1<<5
const BIT_7 = 1<<6
const BIT_8 = 1<<7
const BIT_9 = 1<<8
const ALL_BITS = (1<<N_HORZ) - 1

var cage_labels = []		# ケージ合計数字用ラベル配列
var clue_labels = []		# 手がかり数字用ラベル配列
var input_labels = []		# 入力数字用ラベル配列

var CageLabel = load("res://CageLabel.tscn")
var ClueLabel = load("res://ClueLabel.tscn")

func _ready():
	init_labels()
	pass
func init_labels():
	# 手がかり数字、入力数字用 Label 生成
	for y in range(N_VERT):
		for x in range(N_HORZ):
			var px = x * CELL_WIDTH
			var py = y * CELL_WIDTH
			var label = ClueLabel.instance()
			clue_labels.push_back(label)
			label.rect_position = Vector2(px, py + 2)
			label.text = String((x+y)%9 + 1)
			$Board.add_child(label)
			label = CageLabel.instance()
			cage_labels.push_back(label)
			label.rect_position = Vector2(px, py + 2)
			label.text = "45"
			$Board.add_child(label)
