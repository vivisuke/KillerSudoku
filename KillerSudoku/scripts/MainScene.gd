extends Node2D

enum {
	#IX_CAGE_COLOR = 0,		# ケージ背景色、0, 1, 2, 3
	IX_CAGE_TOP_LEFT = 0,	# ケージ左上位置
	IX_CAGE_N,				# ケージ内数字数
	IX_CAGE_SUM,			# ケージ内数字合計
	IX_CAGE_BITS,			# ケージ内数字ビット論理和
	#IX_CAGE_IX_LIST,		# ケージに含まれるセルIXのリスト
}

const N_COLOR = 4			# ケージ色種数
const CAGE_N_NUM_MAX = 4	# ケージ内最大数字数
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
var ans_bit = []			# 解答の各セル数値（0 | BIT_1 | BIT_2 | ... | BIT_9）
var cell_bit = []			# 各セル数値（0 | BIT_1 | BIT_2 | ... | BIT_9）
var cage_list = []			# ケージリスト配列、要素：IX_CAGE_XXX
var cage_ix = []			# 各セルのケージリスト配列インデックス
var candidates_bit = []		# 入力可能ビット論理和
var column_used = []		# 各カラムの使用済みビット
var box_used = []			# 各3x3ブロックの使用済みビット

var rng = RandomNumberGenerator.new()

var CageLabel = load("res://CageLabel.tscn")
var ClueLabel = load("res://ClueLabel.tscn")
var InputLabel = load("res://InputLabel.tscn")

func _ready():
	if false:
		randomize()
		rng.randomize()
	else:
		var sd = 1
		seed(sd)
		rng.set_seed(sd)
	cell_bit.resize(N_CELLS)
	candidates_bit.resize(N_CELLS)
	cage_ix.resize(N_CELLS)
	column_used.resize(N_HORZ)
	box_used.resize(N_HORZ)
	#
	init_labels()
	gen_ans()
	for i in range(N_CELLS):
		clue_labels[i].text = bit_to_numstr(cell_bit[i])
	gen_cage()
	pass
func xyToIX(x, y) -> int: return x + y * N_HORZ
func num_to_bit(n : int): return 1 << (n-1) if n != 0 else 0
func bit_to_num(b):
	var mask = 1
	for i in range(N_HORZ):
		if (b & mask) != 0: return i + 1
		mask <<= 1
	return 0
func bit_to_numstr(b):
	if b == 0: return ""
	return String(bit_to_num(b))
func init_labels():
	# 手がかり数字、入力数字用 Label 生成
	for y in range(N_VERT):
		for x in range(N_HORZ):
			var px = x * CELL_WIDTH
			var py = y * CELL_WIDTH
			# ケージ合計用ラベル
			var label = CageLabel.instance()
			cage_labels.push_back(label)
			label.rect_position = Vector2(px + 1, py + 1)
			label.text = "45"
			$Board.add_child(label)
			# 手がかり数字用ラベル
			label = ClueLabel.instance()
			clue_labels.push_back(label)
			label.rect_position = Vector2(px, py + 2)
			label.text = String((x+y)%9 + 1)
			$Board.add_child(label)
			# 入力数字用ラベル
			label = InputLabel.instance()
			input_labels.push_back(label)
			label.rect_position = Vector2(px, py + 2)
			label.text = ""
			$Board.add_child(label)
func gen_ans_sub(ix : int, line_used):
	#print_cells()
	#print_box_used()
	var x : int = ix % N_HORZ
	if x == 0: line_used = 0
	var x3 = x / 3
	var y3 = ix / (N_HORZ*3)
	var bix = y3 * 3 + x3
	var used = line_used | column_used[x] | box_used[bix]
	if used == ALL_BITS: return false		# 全数字が使用済み
	var lst = []
	var mask = BIT_1
	for i in range(N_HORZ):
		if (used & mask) == 0: lst.push_back(mask)		# 数字未使用の場合
		mask <<= 1
	if ix == N_CELLS - 1:
		cell_bit[ix] = lst[0]
		return true
	if lst.size() > 1: lst.shuffle()
	for i in range(lst.size()):
		cell_bit[ix] = lst[i]
		column_used[x] |= lst[i]
		box_used[bix] |= lst[i]
		if gen_ans_sub(ix+1, line_used | lst[i]): return true
		column_used[x] &= ~lst[i]
		box_used[bix] &= ~lst[i]
	cell_bit[ix] = 0
	return false;

func gen_ans():		# 解答生成
	for i in range(N_CELLS):
		clue_labels[i].text = "?"
		input_labels[i].text = ""
	for i in range(box_used.size()): box_used[i] = 0
	for i in range(cell_bit.size()): cell_bit[i] = 0
	var t = []
	for i in range(N_HORZ): t.push_back(1<<i)
	t.shuffle()
	for i in range(N_HORZ):
		cell_bit[i] = t[i]
		column_used[i] = t[i]
		box_used[i/3] |= t[i]
	#print(cell_bit)
	gen_ans_sub(N_HORZ, 0)
	print_cells()
	#update_cell_labels()
	ans_bit = cell_bit.duplicate()
	for i in range(N_CELLS): input_labels[i].text = ""		# 入力ラベル全消去
	pass
func print_cells():
	var ix = 0
	for y in range(N_VERT):
		var lst = []
		for x in range(N_HORZ):
			lst.push_back(bit_to_num(cell_bit[ix]))
			ix += 1
		print(lst)
	print("")
func merge_cage(cix0, cix):		# cix を cix0 にマージ
	print(cage_list[cix0])
	print(cage_list[cix])
	cage_list[cix0][IX_CAGE_SUM] += cage_list[cix][IX_CAGE_SUM]
	cage_list[cix0][IX_CAGE_N] += cage_list[cix][IX_CAGE_N]
	for i in range(cix + 1):
		if cage_ix[i] == cix: cage_ix[i] = cix0
	cage_list[cix][IX_CAGE_TOP_LEFT] = -1
func diff_color(c1, c2):	# c1, c2 と異なる色を選択
	c1 = (c1 + 1) % N_COLOR
	if c1 == c2: c1 = (c1 + 1) % N_COLOR
	return c1
func add_cage(ix, num, bit):
	cage_ix[ix] = cage_list.size()
	cage_list.push_back([ix, 1, num, bit])	# ix, セル数, 数字合計, 数字ビット論理和
func add_left_cage(ix, num, bit):
	cage_ix[ix] = cage_ix[ix-1]
	cage_list[cage_ix[ix-1]][IX_CAGE_N] += 1
	cage_list[cage_ix[ix-1]][IX_CAGE_SUM] += num
	cage_list[cage_ix[ix-1]][IX_CAGE_BITS] |= bit
func add_upper_cage(ix, num, bit):
	cage_ix[ix] = cage_ix[ix-N_HORZ]
	cage_list[cage_ix[ix-N_HORZ]][IX_CAGE_N] += 1
	cage_list[cage_ix[ix-N_HORZ]][IX_CAGE_SUM] += num
	cage_list[cage_ix[ix-N_HORZ]][IX_CAGE_BITS] |= bit
func gen_cage():
	cage_list = []
	var ix = 0
	for y in range(N_VERT):
		for x in range(N_HORZ):
			cage_labels[ix].text = ""
			var diff = false
			var num = bit_to_num(cell_bit[ix])
			var bit = num_to_bit(num)
			var col = rng.randi_range(0, 3)
			var uc = $Board/CageTileMap.get_cell(x, y-1)
			var lc = $Board/CageTileMap.get_cell(x-1, y)
			var nu = 0 if y == 0 else cage_list[cage_ix[ix-N_HORZ]][IX_CAGE_N]	# 直上ケージ数字数
			var nl = 0 if x == 0 else cage_list[cage_ix[ix-1]][IX_CAGE_N]	# 直左ケージ数字数
			# done: 上・左のケージ内に num と同じ数字がある場合は、それらと異なる色にする
			if( y > 0 && (cage_list[cage_ix[ix-N_HORZ]][IX_CAGE_BITS] & bit) != 0 ||	# 上のケージ内に同じ数字がある
				x > 0 && (cage_list[cage_ix[ix-1]][IX_CAGE_BITS] & bit) != 0 ||			# 左のケージ内に同じ数字がある
				y > 0 && nu == CAGE_N_NUM_MAX && col == uc ||	# 上のケージ内数字数上限
				x > 0 && nl == CAGE_N_NUM_MAX && col == lc ):	# 左のケージ内数字数上限
					diff = true
					col = diff_color(lc, uc)
					#add_cage(ix, num, bit)
			if nu == 1:	# 直上が１セルだけの場合
				col = uc
			elif y == N_VERT - 1:		# 下端の場合
				if nl == 1 && !diff:	# 直左が１セルだけの場合
					col = lc
				elif x == N_HORZ - 1:	# 右端の場合
					if( nl >= CAGE_N_NUM_MAX && nu >= CAGE_N_NUM_MAX ):
						col = diff_color(lc, uc)
					elif nl < nu:
						col = lc
					else:
						col = uc
			elif y == 0 && nl == 1:	# １行目、左が１セルだけの場合
				if rng.randf_range(0.0, 1.0) <= 0.5:
					col = lc
				elif col == lc:
					col = (col + 1) % N_COLOR
			if col == lc && col == uc:		# 現カラーが左・上両方と同じ
				if nl + nu < CAGE_N_NUM_MAX:		# マージしても上限を超えない
					if cage_ix[ix-N_HORZ] != cage_ix[ix-1]:		# 上と左が異なるケージ
						merge_cage(cage_ix[ix-1], cage_ix[ix-N_HORZ])		# 上を左にマージ
				else:
					col = (col + 1) % N_COLOR		# 上・左とは異なる色に
			#if lc == col:	# 左と同じ色の場合
			#	if( uc == col &&	# 上と同じ色の場合
			#		cage_ix[ix-N_HORZ] != cage_ix[ix-1] ):		# 上と左が異なるケージ
			#			if nl + nu < CAGE_N_NUM_MAX:		# マージしても上限を超えない
			#				merge_cage(cage_ix[ix-1], cage_ix[ix-N_HORZ])		# 上を左にマージ
			#	add_left_cage(ix, num, bit)
			if lc == col:	# 左と同じ色の場合
				add_left_cage(ix, num, bit)
			elif uc == col:	# 上と同じ色の場合
				add_upper_cage(ix, num, bit)
			else:		# 左・上と個なる色の場合
				add_cage(ix, num, bit)
			$Board/CageTileMap.set_cell(x, y, col)
			ix += 1
	for i in range(cage_list.size()):
		if cage_list[i][IX_CAGE_TOP_LEFT] >= 0:
			cage_labels[cage_list[i][IX_CAGE_TOP_LEFT]].text = String(cage_list[i][IX_CAGE_SUM])
	pass
