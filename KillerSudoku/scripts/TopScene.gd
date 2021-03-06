extends Node2D

const N_BUTTONS = 6

var buttons = []
onready var g = get_node("/root/Global")

func _ready():
	g.todaysQuest = false
	g.load_environment()
	if !g.env.has(g.KEY_LOGIN_DATE) || g.env[g.KEY_LOGIN_DATE] != g.today_string():
		g.env[g.KEY_LOGIN_DATE] = g.today_string()
		g.env[g.KEY_N_COINS] += g.DAYLY_N_COINS
		g.save_environment()
	$CoinButton/NCoinLabel.text = String(g.env[g.KEY_N_COINS])
	g.load_stats()
	#
	for i in range(N_BUTTONS):
		buttons.push_back(get_node("Button%d" % i))
	for i in range(N_BUTTONS):
		var n = g.stats[i]["NSolved"] if g.stats[i].has("NSolved") else 0
		buttons[i].get_node("NSolvedLabel").text = "クリア回数: %d" % n
		var txt = "平均タイム: "
		if n == 0:
			txt += "N/A"
		else:
			var avg : int = int(g.stats[i]["TotalSec"] / n)
			txt += g.sec_to_MSStr(avg)
		buttons[i].get_node("AveTimeLabel").text = txt
		txt = "最短タイム: "
		if g.stats[i].has("BestTime"):
			txt += g.sec_to_MSStr(g.stats[i]["BestTime"])
		else:
			txt += "N/A"
		buttons[i].get_node("BestTimeLabel").text = txt
	pass # Replace with function body.

func to_MainScene(qLevel):
	print($LineEdit.text)
	g.qLevel = qLevel
	g.qName = $LineEdit.text
	g.qRandom = $LineEdit.text == ""
	g.qNumber = 0
	g.todaysQuest = false
	get_tree().change_scene("res://MainScene.tscn")
func _on_Button0_pressed():
	to_MainScene(0)
func _on_Button1_pressed():
	to_MainScene(1)
func _on_Button2_pressed():
	to_MainScene(2)

func to_LevelScene(qLevel):
	#print($LineEdit.text)
	g.qLevel = qLevel
	g.qName = ""
	g.qRandom = false	#$LineEdit.text == ""
	g.todaysQuest = false
	get_tree().change_scene("res://LevelScene.tscn")
func _on_Button3_pressed():
	to_LevelScene(0)
func _on_Button4_pressed():
	to_LevelScene(1)
func _on_Button5_pressed():
	to_LevelScene(2)
func _on_Button6_pressed():
	get_tree().change_scene("res://TodaysQuest.tscn")
