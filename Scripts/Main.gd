extends Control


func _on_button_pressed():
	Globals.domain = $CenterContainer/VBoxContainer/HBoxContainer/HBoxContainer/Domain/TextEdit.text
	if not Globals.domain.begins_with("@"):
		Globals.domain = "@"+Globals.domain
	Globals.username = $CenterContainer/VBoxContainer/HBoxContainer/HBoxContainer/Username/TextEdit.text
	Globals.password = $CenterContainer/VBoxContainer/HBoxContainer/HBoxContainer/Password/TextEdit.text
	get_tree().change_scene_to_file("res://Scenes/Filepaths.tscn")
	
