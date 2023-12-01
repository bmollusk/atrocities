extends Control

var tabind = {"Malice": 2, "Tutorial": 1, "Home": 0}


func _on_home_link(str):
	if str == "Waiting Room":
		_on_button_4_pressed()
	if str == "Atrocities of Scale!!!":
		_on_texture_button_pressed()
	if str in tabind:
		$MarginContainer/VBoxContainer/TabContainer.current_tab = tabind[str]


func _on_button_pressed():
	_on_home_link("Home")


func _on_button_2_pressed():
	_on_home_link("Tutorial")


func _on_button_3_pressed():
	_on_home_link("Malice")


func _on_button_4_pressed():
	get_tree().change_scene_to_packed(Globals.mult_menu)


func _on_texture_button_pressed():
	_on_home_link("Home")
