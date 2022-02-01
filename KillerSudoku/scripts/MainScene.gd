extends Node2D

enum {
	HORZ = 1,
	VERT,
	BOX,
	CELL,
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

# 要素：[sum, col, ix1, ix2, ...]
const QUEST1 = [ # by wikipeida
	[3, 0, 0, 1], [15, 1, 2, 3, 4], [22, 2, 5, 13, 14, 22], [4, 1, 6, 15], [16, 0, 7, 16], [15, 1, 8, 17, 26, 35],
	[25, 2, 9, 10, 18, 19], [17, 3, 11, 12],
	[9, 0, 20, 21, 30], [8, 1, 23, 32, 41], [20, 2, 24, 25, 33],
	[6, 0, 27, 36], [14, 3, 28, 29], [17, 3, 31, 40, 49], [17, 3, 34, 42, 43],
	[13, 1, 37, 38, 46], [20, 2, 39, 48, 57], [12, 0, 44, 53],
	[27, 2, 45, 54, 63, 72], [6, 0, 47, 55, 56], [20, 0, 50, 59, 60], [6, 2, 51, 52],
	[10, 1, 58, 66, 67, 75], [14, 1, 61, 62, 70, 71],
	[8, 1, 64, 73], [16, 3, 65, 74], [15, 3, 68, 69],
	[13, 0, 76, 77, 78], [17, 2, 79, 80],
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
var cur_num = -1			# 選択されている数字ボタン、-1 for 選択無し
var cur_cell_ix = -1		# 選択されているセルインデックス、-1 for 選択無し
var input_num = 0			# 入力された数字
var nRemoved

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
	num_buttons.push_back($DeleteButton)
	for i in range(N_HORZ):
		num_buttons.push_back(get_node("Button%d" % (i+1)))
	#
	init_labels()
	#gen_ans()
	#show_clues()	# 手がかり数字表示
	#gen_cage()
	set_quest(QUEST1)
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
func set_quest(cages):
	for y in range(N_VERT):
		for x in range(N_HORZ):
			$Board/CageTileMap.set_cell(x, y, -1)
	#var col = 0
	for cix in range(cages.size()):
		var item = cages[cix]			# [sum, col, ix1, ix2, ... ]
		cage_labels[item[2]].text = String(item[0])
		var x1 = item[2] % N_HORZ
		var y1 = item[2] / N_HORZ
		#while( $Board/CageTileMap.get_cell(x1, y1-1) == col || $Board/CageTileMap.get_cell(x1-1, y1) == col ||
		#		$Board/CageTileMap.get_cell(x1, y1+1) == col || $Board/CageTileMap.get_cell(x1+1, y1) == col ):
		#	col = (col + 1) % N_COLOR
		var col = item[1]
		for k in range(2, item.size()):
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
						##if memo_labels[ix][n-1].text == num_str:
						##	t = TILE_CURSOR
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
	##update_num_buttons_disabled()
	##check_duplicated()
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
func clear_cell_cursor():
	for y in range(N_VERT):
		for x in range(N_HORZ):
			$Board/TileMap.set_cell(x, y, TILE_NONE)
func do_emphasize(ix : int, type, fullhouse):
	pass
func add_falling_char(num_str, ix : int):
	pass
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
					##for i in range(N_HORZ):
					#	if memo_labels[ix][i].text != "":
					#		add_falling_memo(int(memo_labels[ix][i].text), ix)
					#		memo_labels[ix][i].text = ""	# メモ数字削除
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
					##input_num = int(cur_num)
					#var lst = remove_memo_num(ix, cur_num)
					#var mb = get_memo_bits(ix)
					#push_to_undo_stack([UNDO_TYPE_CELL, ix, int(input_labels[ix].text), input_num, lst, mb])
					input_labels[ix].text = num_str
				##for i in range(N_HORZ): memo_labels[ix][i].text = ""	# メモ数字削除
				pass
		update_all_status()
		pass
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


func _on_AutoMemoButton_pressed():
	pass # Replace with function body.
