extends Control

var t

func _ready():
	if not FileAccess.file_exists("user://save.save"):
		t = Thread.new()
		$CenterContainer/VBoxContainer/VBoxContainer/DownloadLabel.visible = true
		$CenterContainer/VBoxContainer/VBoxContainer/HBoxContainer/Button.disabled = true
		t.start(_download)
		
		print("Running bat file:")
		var poutput := []
		OS.execute("powershell.exe", ["-Command", Globals.get_exe_path()+"\\makepy.bat"], poutput)
		print(poutput)

var time := 0.0
var cached_periods := -1
func _physics_process(delta):
	
	if t != null and not t.is_alive():
		match t.wait_to_finish():
			2:
				$CenterContainer/VBoxContainer/VBoxContainer/HBoxContainer/Button.disabled = false
				$CenterContainer/VBoxContainer/VBoxContainer/DownloadLabel.visible = false
				$CenterContainer/VBoxContainer/VBoxContainer/LogLabel.visible = false
				t = null
			3:
				if not Globals.get_list_of_classes()[0] is Array or Globals.get_list_of_classes()[0].size() == 0:
					$CenterContainer/VBoxContainer/VBoxContainer/LogLabel.visible = false
					$CenterContainer/VBoxContainer/VBoxContainer/LogErrorLabel.visible = true
					$CenterContainer/VBoxContainer/VBoxContainer/HBoxContainer/Button.disabled = true
					t = null
				else:
					get_tree().change_scene_to_file("res://Scenes/Filepaths.tscn")
	
	time += delta
	var periods := int(time/0.5)%3
	if cached_periods != periods:
		cached_periods = periods+1
		$CenterContainer/VBoxContainer/VBoxContainer/DownloadLabel.text = \
			"Currently Downloading Dependencies "+".".repeat(cached_periods)
		$CenterContainer/VBoxContainer/VBoxContainer/LogLabel.text = \
			"Logging in "+".".repeat(cached_periods)

func _on_button_pressed():
	Globals.domain = $CenterContainer/VBoxContainer/VBoxContainer/HBoxContainer/HBoxContainer/Domain/TextEdit.text
	if not Globals.domain.begins_with("@"):
		Globals.domain = "@"+Globals.domain
	Globals.username = $CenterContainer/VBoxContainer/VBoxContainer/HBoxContainer/HBoxContainer/Username/TextEdit.text
	Globals.password = $CenterContainer/VBoxContainer/VBoxContainer/HBoxContainer/HBoxContainer/Password/TextEdit.text
	
	t = Thread.new()
	$CenterContainer/VBoxContainer/VBoxContainer/LogLabel.visible = true
	$CenterContainer/VBoxContainer/VBoxContainer/HBoxContainer/Button.disabled = true
	t.start(_update_lists.bind(Globals))
	
	
	

func _download():
	OS.execute("powershell.exe", ["-Command","pip install selenium"])
	OS.execute("powershell.exe", ["-Command","pip install requests"])
	OS.execute("powershell.exe", ["-Command","pip install lxml"])
	var f := FileAccess.open("user://save.save",FileAccess.WRITE_READ)
	return 2

func _update_lists(global):
	global.update_list_of_classes()
	return 3
