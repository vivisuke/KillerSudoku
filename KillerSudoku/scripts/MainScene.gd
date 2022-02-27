extends Node2D

enum {
	HORZ = 1,
	VERT,
	BOX,
	CELL,
}
enum {
	CAGE_SUM = 0,			# ケージ内数字合計
	CAGE_IX_LIST,			# ケージ内セル位置配列
}
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
const CELL_WIDTH4 = CELL_WIDTH/4
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
const BIT_MEMO = 1<<10
const TILE_NONE = -1
const TILE_CURSOR = 0
const TILE_LTBLUE = 1				# 強調カーソル（薄青）
const TILE_LTORANGE = 2				# 強調カーソル（薄橙）
const TILE_PINK = 3					# 強調カーソル（薄ピンク）
const COLOR_INCORRECT = Color.red
const COLOR_DUP = Color.red
const COLOR_CLUE = Color.black
#const COLOR_INPUT = Color("#2980b9")	# VELIZE HOLE
const COLOR_INPUT = Color.black
const LVL_BEGINNER = 0
const LVL_EASY = 1
const LVL_NORMAL = 2
const AUTO_MEMO_N_COINS = 3				# 自動メモ消費コイン数
const MIN_1CELL_CAGE = 14

const CAGE_TABLE = [
	[	0b000000000, 0b000000000, 0b000000011, 0b000000101, 0b000001111,	# for 1, 2, ... 5
		0b000011011, 0b000111111, 0b001110111, 0b011111111, 0b111101111, 	# for 6, 7, ... 10
		0b111111110, 0b111011100, 0b111111000, 0b110110000, 0b111100000,	# for 11, 12, ... 15
		0b101000000, 0b110000000, ],										# for 16, 17
	[	0b000000000, 0b000000000, 0b000000000, 0b000000000, 0b000000000,	# for 1, 2, ... 5
		0b000000111, 0b000001011, 0b000011111, 0b000111111, 0b001111111,	# for 6, 7, ... 10
		0b011111111, 0b111111111, 0b111111111, 0b111111111, 0b111111111,	# for 11, 12, ... 15
		0b111111111, 0b111111111, 0b111111111, 0b111111110, 0b111111100,	# for 16, 17, ... 20
		0b111111000, 0b111110000, 0b110100000, 0b111000000, ],				# for 21, 22, ... 24
	[	0b000000000, 0b000000000, 0b000000000, 0b000000000, 0b000000000,	# for 1, 2, ... 5
		0b000000000, 0b000000000, 0b000000000, 0b000000000, 0b000001111,	# for 6, 7, ... 10
		0b000010111, 0b000111111, 0b001111111, 0b011111111, 0b111111111,	# for 11, 12, ... 15
		0b111111111, 0b111111111, 0b111111111, 0b111111111, 0b111111111,	# for 16, 17, ... 20
		0b111111111, 0b111111111, 0b111111111, 0b111111111, 0b111111111,	# for 21, 22, ... 25
		0b111111110, 0b111111100, 0b111111000, 0b111010000, 0b111100000, ],	# for 26, 27, ... 30
]

# 要素：[sum, ix1, ix2, ...]
const QUEST1 = [ # by wikipeida
	[3, 0, 1], [15, 2, 3, 4], [22, 5, 13, 14, 22], [4, 6, 15], [16, 7, 16], [15, 8, 17, 26, 35],
	[25, 9, 10, 18, 19], [17, 11, 12],
	[9, 20, 21, 30], [8, 23, 32, 41], [20, 24, 25, 33],
	[6, 27, 36], [14, 28, 29], [17, 31, 40, 49], [17, 34, 42, 43],
	[13, 37, 38, 46], [20, 39, 48, 57], [12, 44, 53],
	[27, 45, 54, 63, 72], [6, 47, 55, 56], [20, 50, 59, 60], [6, 51, 52],
	[10, 58, 66, 67, 75], [14, 61, 62, 70, 71],
	[8, 64, 73], [16, 65, 74], [15, 68, 69],
	[13, 76, 77, 78], [17, 79, 80],
]

var symmetric = true		# 対称形問題
var qCreating = false		# 問題生成中
var solvedStat = false		# クリア済み状態
var paused = false			# ポーズ状態
var sound = true			# 効果音
var menuPopuped = false
var hint_showed = false
var memo_mode = false		# メモ（候補数字）エディットモード
var in_button_pressed = false	# ボタン押下処理中
var hint_next_pos			# 次ボタン位置
var hint_next_pos0			# 次ボタン初期位置
var hint_next_vy			# 次ボタン速度
var saved_cell_data = []

#var hint_next_scale = 1.0	# ヒント次ボタン表示スケール
#var hint_num				# ヒントで確定する数字、[1, 9]
var hint_numstr				# ヒントで確定する数字、[1, 9]
var hint_ix = 0				# 0, 1, 2, ...
var hint_texts = []			# ヒントテキスト配列
#var restarted = false
#var elapsedTime = 0.0   	# 経過時間（単位：秒）
var saved_time
var nEmpty = 0				# 空欄数
var nDuplicated = 0			# 重複数字数
#var optGrade = -1			# 問題グレード、0: 入門、1:初級、2:ノーマル（初中級）
var diffculty = 0			# 難易度、フルハウス: 1, 隠れたシングル: 2, 裸のシングル: 10pnt？
var num_buttons = []		# 各数字ボタンリスト [0] -> 削除ボタン、[1] -> Button1, ...
var num_used = []			# 各数字使用数（手がかり数字＋入力数字）
var cur_num = -1			# 選択されている数字ボタン、-1 for 選択無し
var cur_cell_ix = -1		# 選択されているセルインデックス、-1 for 選択無し
var input_num = 0			# 入力された数字
var nRemoved
var nAnswer = 0				# 解答数

var cage_labels = []		# ケージ合計数字用ラベル配列
var clue_labels = []		# 手がかり数字用ラベル配列
var input_labels = []		# 入力数字用ラベル配列
#var ans_bit = []			# 解答の各セル数値（0 | BIT_1 | BIT_2 | ... | BIT_9）
var ans_num = []			# 解答の各セル数値、1～N_HORZ
var cell_bit = []			# 各セル数値（0 | BIT_1 | BIT_2 | ... | BIT_9）
var quest_cages = []		# クエストケージリスト配列、要素：[sum, ix1, ix2, ...]
var cage_list = []			# ケージリスト配列、要素：IX_CAGE_XXX
var cage_ix = []			# 各セルのケージリスト配列インデックス
var candidates_bit = []		# 入力可能ビット論理和
var line_used = []			# 各行の使用済みビット
var column_used = []		# 各カラムの使用済みビット
var box_used = []			# 各3x3ブロックの使用済みビット
var memo_labels = []		# メモ（候補数字）用ラベル配列（２次元）
var memo_text = []			# ポーズ復活時用ラベルテキスト配列（２次元）
var shock_wave_timer = -1
var undo_ix = 0
var undo_stack = []			# 要素：[ix old new]、old, new は 0～9 の数値、0 for 空欄

var rng = RandomNumberGenerator.new()

var CageLabel = load("res://CageLabel.tscn")
var ClueLabel = load("res://ClueLabel.tscn")
var InputLabel = load("res://InputLabel.tscn")
var MemoLabel = load("res://MemoLabel.tscn")
var FallingChar = load("res://FallingChar.tscn")
var FallingMemo = load("res://FallingMemo.tscn")
var FallingCoin = load("res://FallingCoin.tscn")

onready var g = get_node("/root/Global")

func _ready():
	if false:
		randomize()
		rng.randomize()
	else:
		var sd = 1
		seed(sd)
		rng.set_seed(sd)
	cell_bit.resize(N_CELLS)
	ans_num.resize(N_CELLS)
	candidates_bit.resize(N_CELLS)
	cage_ix.resize(N_CELLS)
	column_used.resize(N_HORZ)
	box_used.resize(N_HORZ)
	memo_text.resize(N_CELLS)
	column_used.resize(N_HORZ)
	num_used.resize(N_HORZ + 1)		# +1 for 0
	#
	num_buttons.push_back($DeleteButton)
	for i in range(N_HORZ):
		num_buttons.push_back(get_node("Button%d" % (i+1)))
	#
	init_labels()
	#gen_ans()
	#show_clues()	# 手がかり数字表示
	#gen_cage()
	#set_quest(QUEST1)
	gen_quest()
	pass
func gen_quest():
	# undone: 問題集以外の場合対応
	#if g.todaysQuest:		# 今日の問題の場合
	#	g.qLevel += 1
	#	if g.qLevel > 2: g.qLevel = 0
	#elif g.qNumber == 0:		# 問題自動生成の場合
	#	g.qRandom = true		# 
	#	gen_qName()
	#else:					# 問題集の場合
	#	g.qNumber += 1
	#	g.qName = "%06d" % g.qNumber
	if g.qNumber != 0:	# 問題集の場合
		$NextButton.disabled = g.qNumber > g.nSolved[g.qLevel]
	elif !g.todaysQuest:		# ランダム生成の場合
		if g.qName == "":
			gen_qName()
			$TitleBar/Label.text = titleText()
	var stxt = g.qName+String(g.qLevel)
	if g.qNumber != 0: stxt += "Q"
	seed(stxt.hash())
	rng.set_seed(stxt.hash())
	while true:
		gen_ans()
		gen_cages()
		if g.qLevel == LVL_BEGINNER:
			if count_n_cell_cage(1) < MIN_1CELL_CAGE:
				##continue			# 再生成
				pass
		#	#split_2cell_cage()		# 1セルケージ数が４未満なら２セルケージを分割
		#el
		if g.qLevel == LVL_NORMAL:
			merge_2cell_cage()
			#if count_n_cell_cage(3) <= 3:
			#merge_2cell_cage()
		#print_cages()
		#gen_cages_3x2()		# 3x2 単位で分割
		#break
		#ans_bit = cell_bit.duplicate()
		break
		#if is_proper_quest():
		#	break
	#print_ans()
	fill_1cell_cages()
	update_cages_sum_labels()
	solvedStat = false
	g.elapsedTime = 0.0
	#ans_bit = cell_bit.duplicate()
	#print_ans()
	print_ans_num()
	#print_cages()
func is_proper_quest() -> bool:
	nAnswer = 0
	for ix in range(N_CELLS): cell_bit[ix] = 0
	for ix in range(N_HORZ):
		line_used[ix] = 0
		column_used[ix] = 0
		box_used[ix] = 0
	#ipq_sub(0, 0, 0, 0)
	return nAnswer == 1
func print_cages():
	for i in range(cage_list.size()):
		print(cage_list[i])
func merge_2cell_cage():	# 2セルケージ２つをマージし4セルに
	#print_cages()
	while true:
		var ix = rng.randi_range(0, N_CELLS-1)
		var cix = cage_ix[ix]
		if cage_list[cix][CAGE_IX_LIST].size() != 2: continue
		var lst2 = []
		var x = ix % N_HORZ
		var y = ix / N_HORZ
		if y != 0:
			var i2 = xyToIX(x, y-1)
			if cage_ix[i2] != cix && cage_list[cage_ix[i2]][CAGE_IX_LIST].size() == 2:
				lst2.push_back(i2)
		if x != 0:
			var i2 = xyToIX(x-1, y)
			if cage_ix[i2] != cix && cage_list[cage_ix[i2]][CAGE_IX_LIST].size() == 2:
				lst2.push_back(i2)
		if x != N_HORZ-1:
			var i2 = xyToIX(x+1, y)
			if cage_ix[i2] != cix && cage_list[cage_ix[i2]][CAGE_IX_LIST].size() == 2:
				lst2.push_back(i2)
		if y != N_VERT-1:
			var i2 = xyToIX(x, y+1)
			if cage_ix[i2] != cix && cage_list[cage_ix[i2]][CAGE_IX_LIST].size() == 2:
				lst2.push_back(i2)
		if lst2.empty(): continue
		var ix2 = lst2[0] if lst2.size() == 1 else lst2[rng.randi_range(0, lst2.size() - 1)]
		var cix2 = cage_ix[ix2]
		#print("cix = ", cage_list[cix])
		#print("cix2 = ", cage_list[cix2])
		for i in range(cage_list[cix2][CAGE_IX_LIST].size()):
			cage_ix[cage_list[cix2][CAGE_IX_LIST][i]] = cix
		cage_list[cix][CAGE_IX_LIST] += cage_list[cix2][CAGE_IX_LIST]
		cage_list[cix][CAGE_SUM] += cage_list[cix2][CAGE_SUM]
		cage_list[cix2] = [0, []]
		#print_cages()
		return
func sel_from_lst(ix, lst):		# lst からひとつを選ぶ
	if g.qLevel != LVL_NORMAL:
		return lst[rng.randi_range(0, lst.size() - 1)]
	var n = get_cell_numer(ix)
	if n <= 3:		# 3以下の場合は、最大のものを選ぶ
		var mx = 0
		var mxi = 0
		for i in range(lst.size()):
			var n2 = get_cell_numer(lst[i])
			if n2 > mx:
				mx = n2
				mxi = i
		return lst[mxi]
	else:		# 4以上の場合は、最小のものを選ぶ
		var mn = N_HORZ + 1
		var mni = 0
		for i in range(lst.size()):
			var n2 = get_cell_numer(lst[i])
			if n2 < mn:
				mn = n2
				mni = i
		return lst[mni]
func gen_cages():
	for i in range(N_CELLS): cage_labels[i].text = ""
	cage_list = []
	# 4隅を風車風に２セルケージに分ける
	if rng.randf_range(0.0, 1.0) < 0.5:
		cage_list.push_back([0, [0, 1]])
		var ix0 = N_HORZ-1
		cage_list.push_back([0, [ix0, ix0+N_HORZ]])
		ix0 = N_HORZ * (N_VERT - 1)
		cage_list.push_back([0, [ix0, ix0-N_HORZ]])
		ix0 = N_CELLS - 1
		cage_list.push_back([0, [ix0, ix0-1]])
	else:
		cage_list.push_back([0, [0, N_HORZ]])
		var ix0 = N_HORZ-1
		cage_list.push_back([0, [ix0, ix0-1]])
		ix0 = N_HORZ * (N_VERT - 1)
		cage_list.push_back([0, [ix0, ix0+1]])
		ix0 = N_CELLS - 1
		cage_list.push_back([0, [ix0, ix0-N_HORZ]])
	for i in range(cage_ix.size()): cage_ix[i] = -1
	for ix in range(cage_list.size()):
		var lst = cage_list[ix][1]
		for k in range(lst.size()): cage_ix[lst[k]] = ix
	# undone: 入門問題の場合は１セルケージを8つ、初級の場合は２つ生成
	if g.qLevel < LVL_NORMAL:
		var cnt = 4 if g.qLevel == LVL_BEGINNER else 2
		while cnt > 0:
			var ix = rng.randi_range(0, N_CELLS-1)
			if cage_ix[ix] >= 0: continue
			cage_ix[ix] = cage_list.size()
			cage_list.push_back([0, [ix]])
			cnt -= 1
	#
	var ar = []
	for ix in range(N_CELLS): ar.push_back(ix)
	ar.shuffle()
	for i in range(ar.size()):
		var ix = ar[i]
		if cage_ix[ix] < 0:	# 未分割の場合
			if false:
			#if g.qLevel == LVL_BEGINNER && i >= ar.size() - N_HORZ*2.2:
			#if g.qLevel == LVL_BEGINNER && rng.randf_range(0.0, 1.0) < 0.1:
				cage_ix[ix] = cage_list.size()
				cage_list.push_back([0, [ix]])
			else:
				var x = ix % N_HORZ
				var y = ix / N_HORZ
				var lst0 = []	# 空欄リスト
				var lst1 = []	# １セルケージリスト
				var lst2 = []	# ２セルケージリスト
				if y != 0:
					var i2 = xyToIX(x, y-1)
					if cage_ix[i2] < 0: lst0.push_back(i2)	# 空欄の場合
					elif cage_list[cage_ix[i2]][CAGE_IX_LIST].size() == 1: lst1.push_back(i2)
					elif cage_list[cage_ix[i2]][CAGE_IX_LIST].size() == 2: lst2.push_back(i2)
				if x != 0:
					var i2 = xyToIX(x-1, y)
					if cage_ix[i2] < 0: lst0.push_back(i2)	# 空欄の場合
					elif cage_list[cage_ix[i2]][CAGE_IX_LIST].size() == 1: lst1.push_back(i2)
					elif cage_list[cage_ix[i2]][CAGE_IX_LIST].size() == 2: lst2.push_back(i2)
				if x != N_HORZ-1:
					var i2 = xyToIX(x+1, y)
					if cage_ix[i2] < 0: lst0.push_back(i2)	# 空欄の場合
					elif cage_list[cage_ix[i2]][CAGE_IX_LIST].size() == 1: lst1.push_back(i2)
					elif cage_list[cage_ix[i2]][CAGE_IX_LIST].size() == 2: lst2.push_back(i2)
				if y != N_VERT-1:
					var i2 = xyToIX(x, y+1)
					if cage_ix[i2] < 0: lst0.push_back(i2)	# 空欄の場合
					elif cage_list[cage_ix[i2]][CAGE_IX_LIST].size() == 1: lst1.push_back(i2)
					elif cage_list[cage_ix[i2]][CAGE_IX_LIST].size() == 2: lst2.push_back(i2)
				#if ix == 13 || ix == 14:
				#	print("ix = ", ix)
				if !lst0.empty():	# ４近傍に未分割セルがある場合
					#var ix2 = lst0[0] if lst0.size() == 1 else lst0[rng.randi_range(0, lst0.size() - 1)]
					var ix2 = lst0[0] if lst0.size() == 1 else sel_from_lst(ix, lst0)
					#cage_list.back()[1].push_back(i2)
					cage_ix[ix] = cage_list.size()
					cage_ix[ix2] = cage_list.size()
					cage_list.push_back([0, [ix, ix2]])
				#if !lst1.empty():	# ４近傍に1セルケージがある場合
				#	# 1セルのケージに ix をマージ
				#	var i2 = lst1[0] if lst1.size() == 1 else lst1[rng.randi_range(0, lst1.size() - 1)]
				#	var lstx = cage_ix[i2]
				#	cage_list[lstx][CAGE_IX_LIST].push_back(ix)
				#	cage_ix[ix] = lstx
				elif !lst2.empty() && g.qLevel != LVL_BEGINNER:	# ４近傍に２セルのケージがある場合
					# ２セルのケージに ix をマージ
					var i2 = lst2[0] if lst2.size() == 1 else lst2[rng.randi_range(0, lst2.size() - 1)]
					var lstx = cage_ix[i2]
					cage_list[lstx][1].push_back(ix)
					cage_ix[ix] = lstx
				else:
					cage_ix[ix] = cage_list.size()
					cage_list.push_back([0, [ix]])
	for ix in range(cage_list.size()):		# 各ケージの合計を計算
		var item = cage_list[ix]
		var sum = 0
		var lst = item[CAGE_IX_LIST]
		for k in range(lst.size()):
			sum += bit_to_num(cell_bit[lst[k]])
		item[CAGE_SUM] = sum
		#print(cage_list[ix])
		#if sum != 0:
		#	cage_labels[lst.min()].text = String(sum)
		#for k in range(lst.size()): cage_ix[lst[k]] = ix
	quest_cages = cage_list
	$Board/CageGrid.cage_ix = cage_ix
	$Board/CageGrid.update()
	pass
func count_n_cell_cage(n):
	var cnt = 0
	for i in range(cage_list.size()):
		if cage_list[i][CAGE_IX_LIST].size() == n: cnt += 1
	return cnt
func find_2cell_cage():		# 2セルケージを探す
	while true:
		var ix = rng.randi_range(0, cage_list.size() - 1)
		if cage_list[ix][CAGE_IX_LIST].size() == 2:
			return ix
func split_2cell_cage():		# 1セルケージ数が４未満なら２セルケージを分割
	if count_n_cell_cage(1) >= 4: return
	var cix = find_2cell_cage()		# 2セルケージを探す
	var cage = cage_list[cix]
	var ix2 = cage[CAGE_IX_LIST][1]		# ２番めの要素
	cage_ix[ix2] = cage_list.size()
	var t = [bit_to_num(cell_bit[ix2]), [ix2]]
	cage_list.push_back(t)
	var ix1 = cage[CAGE_IX_LIST][0]		# 1番めの要素
	cage = [bit_to_num(cell_bit[ix1]), [ix1]]
	#update_cages_sum_labels()
	cage_labels[ix1].text = String(get_cell_numer(ix1))
	cage_labels[ix2].text = String(get_cell_numer(ix2))
func fill_1cell_cages():
	for ci in range(cage_list.size()):
		var cage = cage_list[ci]
		if cage[CAGE_IX_LIST].size() == 1:
			var ix = cage[CAGE_IX_LIST][0]
			cell_bit[ix] = num_to_bit(cage[CAGE_SUM])
			input_labels[ix].text = String(cage[CAGE_SUM])
func update_cages_sum_labels():
	for ix in range(cage_list.size()):
		var item = cage_list[ix]
		var sum = item[CAGE_SUM]
		var lst = item[CAGE_IX_LIST]
		if sum != 0:
			cage_labels[lst.min()].text = String(sum)
func gen_qName():
	g.qRandom = true
	g.qName = ""
	rng.randomize()
	for i in range(15):
		var r = rng.randi_range(0, 10+26-1)
		if r < 10: g.qName += String(r+1)
		else: g.qName += "%c" % (r - 10 + 0x61)		# 0x61 is 'a'
func classText() -> String:
	if g.qLevel == LVL_BEGINNER: return "【入門】"
	elif g.qLevel == 1: return "【初級】"
	elif g.qLevel == 2: return "【初中級】"
	return ""
func titleText() -> String:
	var tt = classText()
	#elif g.qLevel == LVL_NOT_SYMMETRIC: tt = "【非対称】"
	return tt + "“" + g.qName + "”"
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
			label.text = ""
			$Board.add_child(label)
			# 手がかり数字用ラベル
			label = ClueLabel.instance()
			clue_labels.push_back(label)
			label.rect_position = Vector2(px, py + 2)
			label.text = ""		#String((x+y)%9 + 1)
			$Board.add_child(label)
			# 入力数字用ラベル
			label = InputLabel.instance()
			input_labels.push_back(label)
			label.rect_position = Vector2(px, py + 2)
			label.text = ""
			$Board.add_child(label)
			# 候補数字用ラベル
			var lst = []
			for v in range(3):
				for h in range(3):
					label = MemoLabel.instance()
					lst.push_back(label)
					label.rect_position = Vector2(px + CELL_WIDTH4*(h+1)-3, py + CELL_WIDTH4*(v+1)-3)
					label.text = ""		#String(v*3+h+1)
					$Board.add_child(label)
			memo_labels.push_back(lst)
func init_cell_bit():		# clue_labels, input_labels から 各セルの cell_bit 更新
	for ix in range(N_CELLS):
		var n = get_cell_numer(ix)
		if n == 0:
			cell_bit[ix] = 0
		else:
			cell_bit[ix] = num_to_bit(n)
func init_candidates():		# cell_bit から各セルの候補数字計算
	for i in range(N_CELLS):
		candidates_bit[i] = ALL_BITS if cell_bit[i] == 0 else 0
	for y in range(N_VERT):
		for x in range(N_HORZ):
			var b = cell_bit[xyToIX(x, y)]
			if b != 0:
				for t in range(N_HORZ):
					candidates_bit[xyToIX(t, y)] &= ~b
					candidates_bit[xyToIX(x, t)] &= ~b
				var x0 = x - x % 3		# 3x3ブロック左上位置
				var y0 = y - y % 3
				for v in range(3):
					for h in range(3):
						candidates_bit[xyToIX(x0 + h, y0 + v)] &= ~b
	pass
func set_quest(cages):
	quest_cages = cages
	for y in range(N_VERT):
		for x in range(N_HORZ):
			$Board/CageTileMap.set_cell(x, y, -1)
	#var col = 0
	for cix in range(cages.size()):
		var item = cages[cix]			# [sum, col, ix1, ix2, ... ]
		cage_labels[item[1]].text = String(item[0])
		var x1 = item[1] % N_HORZ
		var y1 = item[1] / N_HORZ
		#while( $Board/CageTileMap.get_cell(x1, y1-1) == col || $Board/CageTileMap.get_cell(x1-1, y1) == col ||
		#		$Board/CageTileMap.get_cell(x1, y1+1) == col || $Board/CageTileMap.get_cell(x1+1, y1) == col ):
		#	col = (col + 1) % N_COLOR
		#var col = item[1]
		for k in range(1, item.size()):
			cage_ix[item[k]] = cix
			#var x = item[k] % N_HORZ
			#var y = item[k] / N_HORZ
			#$Board/CageTileMap.set_cell(x, y, col)
	$Board/CageGrid.cage_ix = cage_ix
	$Board/CageGrid.update()
	#update()
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
func show_clues():
	for i in range(N_CELLS):
		clue_labels[i].text = bit_to_numstr(cell_bit[i])
func gen_ans():		# 解答生成
	for i in range(N_CELLS):
		clue_labels[i].text = ""
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
	#ans_bit = cell_bit.duplicate()
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
func print_ans_num():
	print("ans_num:")
	var ix = 0
	for y in range(N_VERT):
		var lst = []
		for x in range(N_HORZ):
			lst.push_back(ans_num[ix])
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
			var un = 0 if y == 0 else cage_list[cage_ix[ix-N_HORZ]][IX_CAGE_N]	# 直上ケージ数字数
			var ln = 0 if x == 0 else cage_list[cage_ix[ix-1]][IX_CAGE_N]	# 直左ケージ数字数
			var ub = 0 if y == 0 else cage_list[cage_ix[ix-N_HORZ]][IX_CAGE_BITS]	# 直上ケージ数字数
			var lb = 0 if x == 0 else cage_list[cage_ix[ix-1]][IX_CAGE_BITS]	# 直左ケージ数字数
			# done: 上・左のケージ内に num と同じ数字がある場合は、それらと異なる色にする
			if( y > 0 && (ub & bit) != 0 ||		# 上のケージ内に同じ数字がある
				x > 0 && (lb & bit) != 0 ||		# 左のケージ内に同じ数字がある
				y > 0 && un == CAGE_N_NUM_MAX && col == uc ||	# 上のケージ内数字数上限
				x > 0 && ln == CAGE_N_NUM_MAX && col == lc ):	# 左のケージ内数字数上限
					diff = true
					col = diff_color(lc, uc)
					#add_cage(ix, num, bit)
			if un == 1:	# 直上が１セルだけの場合
				col = uc
			elif y == N_VERT - 1:		# 下端の場合
				# undone: 最下行 && 左が１セル && 上と同じ色の場合は、左セルの色を変える？
				if ln == 1 && uc == lc:
					lc = diff_color($Board/CageTileMap.get_cell(x-1, y-1), $Board/CageTileMap.get_cell(x-2, y))
					$Board/CageTileMap.set_cell(x-1, y, lc)
				elif ln == 1 && !diff:	# 直左が１セルだけの場合
					col = lc
				elif x == N_HORZ - 1:	# 右端の場合
					if( ln >= CAGE_N_NUM_MAX && un >= CAGE_N_NUM_MAX ):
						col = diff_color(lc, uc)
					elif ln < un:
						col = lc
					else:
						col = uc
			elif y == 0 && ln == 1:	# １行目、左が１セルだけの場合
				if rng.randf_range(0.0, 1.0) <= 0.5:
					col = lc
				elif col == lc:
					col = (col + 1) % N_COLOR
			if col == lc && col == uc:		# 現カラーが左・上両方と同じ
				if ln + un < CAGE_N_NUM_MAX:		# マージしても上限を超えない
					if( cage_ix[ix-N_HORZ] != cage_ix[ix-1] &&		# 上と左が異なるケージ
						(ub & lb) == 0 ):			# 上と左に同じ数字が無い
							merge_cage(cage_ix[ix-1], cage_ix[ix-N_HORZ])		# 上を左にマージ
				else:
					col = (col + 1) % N_COLOR		# 上・左とは異なる色に
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
func get_cell_numer(ix) -> int:		# ix 位置に入っている数字の値を返す、0 for 空欄
	if clue_labels[ix].text != "":
		return int(clue_labels[ix].text)
	if input_labels[ix].text != "":
		return int(input_labels[ix].text)
	return 0
func update_cell_cursor(num):		# 選択数字ボタンと同じ数字セルを強調
	if num > 0 && !paused:
		var num_str = String(num)
		for y in range(N_VERT):
			for x in range(N_HORZ):
				var ix = xyToIX(x, y)
				if num != 0 && get_cell_numer(ix) == num:
					$Board/TileMap.set_cell(x, y, TILE_CURSOR)
				else:
					$Board/TileMap.set_cell(x, y, TILE_NONE)
				for v in range(3):
					for h in range(3):
						var n = v * 3 + h + 1
						var t = TILE_NONE
						if memo_labels[ix][n-1].text == num_str:
							t = TILE_CURSOR
						##$Board/MemoTileMap.set_cell(x*3+h, y*3+v, t)
	else:
		for y in range(N_VERT):
			for x in range(N_HORZ):
				$Board/TileMap.set_cell(x, y, TILE_NONE)
				##for v in range(3):
				##	for h in range(3):
				##		$Board/MemoTileMap.set_cell(x*3+h, y*3+v, TILE_NONE)
		if cur_cell_ix >= 0:
			do_emphasize(cur_cell_ix, CELL, false)
	pass
func set_num_cursor(num):	# 当該ボタンだけを選択状態に
	cur_num = num
	for i in range(num_buttons.size()):
		num_buttons[i].pressed = (i == num)
func update_all_status():
	##update_undo_redo()
	update_cell_cursor(cur_num)
	##update_NEmptyLabel()
	update_num_buttons_disabled()
	check_duplicated()
	##$HintButton.disabled = solvedStat
	##$CheckButton.disabled = solvedStat
	##if qCreating:
	##	$MessLabel.text = "問題生成中..."
	##elif solvedStat:
	##	var n = g.stats[g.qLevel]["NSolved"]
	##	var avg : int = int(g.stats[g.qLevel]["TotalSec"] / n)
	##	var txt = g.sec_to_MSStr(avg)
	##	var bst = g.sec_to_MSStr(g.stats[g.qLevel]["BestTime"])
	##	$MessLabel.text = "グッジョブ！ クリア回数: %d、平均: %s、最短: %s" % [n, txt, bst]
	##elif paused:
	##	$MessLabel.text = "ポーズ中です。解除にはポーズボタンを押してください。"
	##elif cur_num > 0:
	##	$MessLabel.text = "現数字（%d）を入れるセルをクリックしてください。" % cur_num
	##elif cur_cell_ix >= 0:
	##	$MessLabel.text = "セルに入れる数字ボタンをクリックしてください。"
	##else:
	##	$MessLabel.text = "数字ボタンまたは空セルをクリックしてください。"
	##$CheckButton.disabled = g.env[g.KEY_N_COINS] <= 0
	##$HintButton.disabled = g.env[g.KEY_N_COINS] <= 0
	##$AutoMemoButton.disabled = g.env[g.KEY_N_COINS] < AUTO_MEMO_N_COINS
func is_duplicated(ix : int):
	var n = get_cell_numer(ix)
	if n == 0: return false
	var x = ix % N_HORZ
	var y = ix / N_HORZ
	for t in range(N_HORZ):
		if t != x && get_cell_numer(xyToIX(t, y)) == n:
			return true
		if t != y && get_cell_numer(xyToIX(x, t)) == n:
			return true
	var x0 = x - x % 3		# 3x3ブロック左上位置
	var y0 = y - y % 3
	for v in range(3):
		for h in range(3):
			var ix3 = xyToIX(x0+h, y0+v)
			if ix3 != ix && get_cell_numer(ix3) == n:
				return true
	return false
func check_duplicated():
	nDuplicated = 0
	for ix in range(N_CELLS):
		if is_duplicated(ix):
			nDuplicated += 1
			clue_labels[ix].add_color_override("font_color", COLOR_DUP)
			input_labels[ix].add_color_override("font_color", COLOR_DUP)
		else:
			clue_labels[ix].add_color_override("font_color", COLOR_CLUE)
			input_labels[ix].add_color_override("font_color", COLOR_INPUT)
	pass
func update_num_buttons_disabled():		# 使い切った数字ボタンをディセーブル
	#var nUsed = []		# 各数字の使用数 [0] for EMPTY
	for i in range(N_HORZ+1): num_used[i] = 0
	for ix in range(N_CELLS):
		num_used[get_cell_numer(ix)] += 1
	for i in range(N_HORZ):
		num_buttons[i+1].disabled = num_used[i+1] >= N_HORZ
func sound_effect():
	if sound:
		if input_num > 0 && num_used[input_num] >= 9:
			$AudioNumCompleted.play()
		else:
			$AudioNumClicked.play()
func clear_cell_cursor():
	for y in range(N_VERT):
		for x in range(N_HORZ):
			$Board/TileMap.set_cell(x, y, TILE_NONE)
func do_emphasize(ix : int, type, fullhouse):
	pass
func add_falling_char(num_str, ix : int):
	pass
func add_falling_memo(num : int, ix : int):
	pass
func remove_memo_num(ix : int, num : int):		# ix に num を入れたときに、メモ数字削除
	var lst = []
	var x = ix % N_HORZ
	var y = ix / N_HORZ
	for h in range(N_HORZ):
		var ix2 = xyToIX(h, y)
		if memo_labels[ix2][num-1].text != "":
			add_falling_memo(num, ix2)
			memo_labels[ix2][num-1].text = ""
			lst.push_back(ix2)
		ix2 = xyToIX(x, h)
		if memo_labels[ix2][num-1].text != "":
			add_falling_memo(num, ix2)
			memo_labels[ix2][num-1].text = ""
			lst.push_back(ix2)
	var x0 = x - x % 3
	var y0 = y - y % 3
	for v in range(3):
		for h in range(3):
			var ix2 = xyToIX(x0 + h, y0 + v)
			if memo_labels[ix2][num-1].text != "":
				add_falling_memo(num, ix2)
				memo_labels[ix2][num-1].text = ""
				lst.push_back(ix2)
	return lst
func _input(event):
	if menuPopuped: return
	if event is InputEventMouseButton && event.is_pressed():
		if event.button_index == BUTTON_WHEEL_UP || event.button_index == BUTTON_WHEEL_DOWN:
				return
		##if paused: return
		var mp = $Board/TileMap.world_to_map($Board/TileMap.get_local_mouse_position())
		print(mp)
		if mp.x < 0 || mp.x >= N_HORZ || mp.y < 0 || mp.y >= N_VERT:
			return		# 盤面セル以外の場合
		input_num = -1
		var ix = xyToIX(mp.x, mp.y)
		if clue_labels[ix].text != "":
			# undone: 手がかり数字ボタン選択
			num_button_pressed(int(clue_labels[ix].text), true)
		else:
			if cur_num < 0:			# 数字ボタン非選択の場合
				clear_cell_cursor()
				if ix == cur_cell_ix:
					cur_cell_ix = -1
				else:
					cur_cell_ix = ix
					do_emphasize(ix, CELL, false)
				update_all_status()
				return
			if cur_num == 0:	# 削除ボタン選択中
				if input_labels[ix].text != "":
					##add_falling_char(input_labels[ix].text, ix)
					#push_to_undo_stack([UNDO_TYPE_CELL, ix, int(input_labels[ix].text), 0, [], 0])		# ix, old, new
					input_labels[ix].text = ""
				else:
					for i in range(N_HORZ):
						if memo_labels[ix][i].text != "":
					#		add_falling_memo(int(memo_labels[ix][i].text), ix)
							memo_labels[ix][i].text = ""	# メモ数字削除
					pass
			# 数字ボタン選択状態の場合 → セルにその数字を入れる or メモ数字反転
			elif !memo_mode:
				if input_labels[ix].text != "":
					add_falling_char(input_labels[ix].text, ix)
				var num_str = String(cur_num)
				if input_labels[ix].text == num_str:	# 同じ数字が入っていれば消去
					##push_to_undo_stack([UNDO_TYPE_CELL, ix, int(cur_num), 0, [], 0])		# ix, old, new
					input_labels[ix].text = ""
				else:	# 上書き
					input_num = int(cur_num)
					var lst = remove_memo_num(ix, cur_num)
					#var mb = get_memo_bits(ix)
					#push_to_undo_stack([UNDO_TYPE_CELL, ix, int(input_labels[ix].text), input_num, lst, mb])
					input_labels[ix].text = num_str
				for i in range(N_HORZ): memo_labels[ix][i].text = ""	# メモ数字削除
				pass
		update_all_status()
		sound_effect()
		pass
	if event is InputEventKey && event.is_pressed():
		print(event.as_text())
		if paused: return
		##if event.as_text() != "Alt" && hint_showed:
		##	close_hint()
		##	return
		if event.as_text() == "W" :
			shock_wave_timer = 0.0      # start shock wave
		var n = int(event.as_text())
		if n >= 1 && n <= 9:
			num_button_pressed(n, true)
	pass
func num_button_pressed(num : int, button_pressed):
	print("num = ", num)
	if in_button_pressed: return		# ボタン押下処理中の場合
	if paused: return			# ポーズ中
	in_button_pressed = true
	if cur_cell_ix >= 0:		# セルが選択されている場合
		pass
	else:	# セルが選択されていない場合
		if button_pressed:
			set_num_cursor(num)
		else:
			cur_num = -1		# toggled
		update_cell_cursor(cur_num)
	in_button_pressed = false
	update_all_status()
	#sound_effect()
	pass
func _on_Button1_toggled(button_pressed):
	num_button_pressed(1, button_pressed)
func _on_Button2_toggled(button_pressed):
	num_button_pressed(2, button_pressed)
func _on_Button3_toggled(button_pressed):
	num_button_pressed(3, button_pressed)
func _on_Button4_toggled(button_pressed):
	num_button_pressed(4, button_pressed)
func _on_Button5_toggled(button_pressed):
	num_button_pressed(5, button_pressed)
func _on_Button6_toggled(button_pressed):
	num_button_pressed(6, button_pressed)
func _on_Button7_toggled(button_pressed):
	num_button_pressed(7, button_pressed)
func _on_Button8_toggled(button_pressed):
	num_button_pressed(8, button_pressed)
func _on_Button9_toggled(button_pressed):
	num_button_pressed(9, button_pressed)


func get_memo():
	var lst = []
	for ix in range(N_CELLS):
		var bits = 0	
		if get_cell_numer(ix) == 0:		# 数字が入っていない場合
			var mask = BIT_1
			for i in range(N_HORZ):
				if memo_labels[ix][i].text != "": bits |= mask
				mask <<= 1
		lst.push_back(bits)
	return lst
func is_same_memo(lst):	# candidates_bit[] と lst[] を比較
	for i in range(N_CELLS):
		if lst[i] != candidates_bit[i]:
			return false;
	return true
func cage_bits(item):
	#var bits = 0
	var sum = item[0]
	var nc = item.size() - 1	# セル数
	if nc == 1:
		return num_to_bit(sum)
	else:
		return CAGE_TABLE[nc-2][sum-1]
	#if nc <= 3:
	#	return CAGE_TABLE[nc-2][sum-1]
	#return bits
	#return 0x1ff
func do_auto_memo():
	init_cell_bit()
	init_candidates()		# 可能候補数字計算 → candidates_bit[]
	var lst0 = get_memo()	# 現在の候補数字状態
	if is_same_memo(lst0): return []	# 既に正しい候補数字が入っている場合
	#var lst = []
	for ix in range(N_CELLS):
		#var bits = 0		# 以前の状態
		if get_cell_numer(ix) != 0:		# 数字が入っている場合
			for i in range(N_HORZ):
				memo_labels[ix][i].text = ""
		else:							# 数字が入っていない場合
			var mask = BIT_1
			for i in range(N_HORZ):
				#if memo_labels[ix][i].text != "": bits |= mask
				if (candidates_bit[ix] & mask) != 0:
					memo_labels[ix][i].text = String(i+1)
				else:
					memo_labels[ix][i].text = ""
				mask <<= 1
		#lst.push_back(bits)
	for i in range(quest_cages.size()):
		var bits = cage_bits(quest_cages[i])
		print(quest_cages[i], ": ", bits)
		for k in range(1, quest_cages[i].size()):
			var ix = quest_cages[i][k]
			var mask = BIT_1
			for b in range(N_HORZ):
				if (bits & mask) == 0:
					memo_labels[ix][b].text = ""
				mask <<= 1
			
		pass
	return lst0		# 元の候補数字状態を返す
func _on_AutoMemoButton_pressed():
	if paused: return		# ポーズ中
	if qCreating: return	# 問題生成中
	##if g.env[g.KEY_N_COINS] < AUTO_MEMO_N_COINS: return
	var lst = do_auto_memo()
	if lst == []: return
	##for i in range(AUTO_MEMO_N_COINS):
	##	add_falling_coin()
	##g.env[g.KEY_N_COINS] -= AUTO_MEMO_N_COINS
	##$CoinButton/NCoinLabel.text = String(g.env[g.KEY_N_COINS])
	##g.save_environment()
	##push_to_undo_stack([UNDO_TYPE_AUTO_MEMO, lst])
	##update_all_status()
	##g.auto_save(true, get_cell_state())
	pass

func _on_BackButton_pressed():
	g.auto_save(false, [])
	if g.todaysQuest:
		get_tree().change_scene("res://TodaysQuest.tscn")
	elif g.qNumber == 0:
		get_tree().change_scene("res://TopScene.tscn")
	else:
		get_tree().change_scene("res://LevelScene.tscn")
