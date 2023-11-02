extends Control

@onready var course_dropdown = $CenterContainer/VBoxContainer/CenterLists/Courses/ItemList
@onready var assignment_dropdown = $CenterContainer/VBoxContainer/CenterLists/Assignments/ItemList

var courses := []
var assignments := {}
var tooltips := {}

var filepath := ""

var selected_course := ""
var selected_assignment := ""

func _ready():
	var list = Globals.get_list_of_classes()
	var course_list = list[0]
	var ass_list = list[1]
	if course_list is Array:
		for elem in course_list:
			courses.append(elem["short_name"])
			tooltips[elem["short_name"]] = elem["name"]
	
	
	if ass_list is Array:
		var course_idx := 0
		for course_bloc in ass_list:
			assignments[courses[course_idx]] = []
			for course in course_bloc[0]:
				assignments[courses[course_idx]].append(course["title"])
			course_idx += 1
	
	
	$CenterContainer/VBoxContainer/Filepath/FileDialog.current_dir = filepath
	$CenterContainer/VBoxContainer/UpperDisplay/LoginLabel.text = "Logged in as: " + Globals.username
	
	var i := 0
	for course_name in courses:
		course_dropdown.add_item(course_name)
		course_dropdown.set_item_tooltip(i, course_name + ": " + tooltips[course_name])
		i += 1


func _on_course_list_item_selected(index: int):
	selected_course = courses[index]
	assignment_dropdown.clear()
	for assignment_name in assignments[courses[index]]:
		assignment_dropdown.add_item(assignment_name)

func _on_assignment_list_item_selected(index: int):
	selected_assignment = assignments[selected_course][index]


func _on_check_box_toggled(button_pressed): # trus is local
	if button_pressed:
		$CenterContainer/VBoxContainer/Filepath/FileDialog.popup_centered()

func _on_file_dialog_file_selected(path):
	filepath = path
	$CenterContainer/VBoxContainer/Filepath/LineEdit.text = path
	$CenterContainer/VBoxContainer/Filepath/FileDialog.hide()

func _on_line_edit_text_changed(new_text: String):
	if new_text.begins_with("/"):
		new_text = new_text.erase(0,1)
	filepath = new_text

func _on_submit_pressed():
	print("Submission pressed")
	
	$CenterContainer/VBoxContainer/Container/ErrorLabel.text = ""
	
	$CenterContainer/VBoxContainer/Container/ErrorLabel.set("theme_override_colors/default_color", Color.RED)
	
	var output := []
	OS.execute("scp", ["-r",Globals.username+Globals.domain+":/home/"+Globals.username+"/"+filepath, Globals.TEMP_DIR], output, true, true)
	if output != [""]:
		if output[0].begins_with("scp: "):
			$CenterContainer/VBoxContainer/Container/ErrorLabel.text = "File " + output[0].split(" ")[1] + " does not exist in " + Globals.domain
		else:
			$CenterContainer/VBoxContainer/Container/ErrorLabel.text = "Uncaught error (report): " + str(output)
		return
	
	var filepath_arr := filepath.split("/")
	var filepath_ending_name: String = filepath_arr[filepath_arr.size()-1]
	var del_queue := [filepath_ending_name]
	
	var files := []
	if filepath_ending_name.ends_with(".zip"):
		
		OS.execute("powershell.exe", ["-Command", "tar -tf "+Globals.TEMP_DIR.replace(" ", "` ")+"\\"+filepath_ending_name], files, true)
		
		files = str(files).trim_prefix("[\"").trim_suffix("\"]").split("\\r\\n")
		
		print("zip file tree: ",files)
		
		var output2 = []
		OS.execute("powershell.exe", ["-Command", "tar -xvf "+Globals.TEMP_DIR.replace(" ", "` ")+"\\"+filepath_ending_name+" -C "+\
		Globals.TEMP_DIR.replace(" ", "` ")], output2, true)
		print("Unzip ret: ", output2)
	
		filepath_ending_name = files[0].trim_suffix("/")
		del_queue = [filepath_ending_name, filepath_ending_name+".zip"]
	
	if DirAccess.dir_exists_absolute(Globals.TEMP_DIR+"\\"+filepath_ending_name) and Globals.withhold_queue.size() > 0:
		print("Witholding detected... Processing...")
		for withhold_token in Globals.withhold_queue:
			OS.execute("powershell.exe", ["-Command", "rm -Recurse -Force "+Globals.TEMP_DIR.replace(" ", "` ") + "\\" + filepath_ending_name + "\\" + withhold_token])
	
	output = Globals.upload_to_gradescope(tooltips[selected_course], selected_assignment, filepath_ending_name)
	if output != [""]:
		if output[0].begins_with("submitted! visit"):
			$CenterContainer/VBoxContainer/Container/ErrorLabel.set("theme_override_colors/default_color", Color.GREEN)
			$CenterContainer/VBoxContainer/Container/ErrorLabel.text = output[0].trim_suffix("\\r\\n")
		else:
			$CenterContainer/VBoxContainer/Container/ErrorLabel.text = "Uncaught error (report): " + str(output)
			return
	
	var outputrm = []
	for f_name in del_queue:
		OS.execute("powershell.exe", ["-Command", "rm -Recurse -Force "+Globals.TEMP_DIR.replace(" ", "` ") + "\\" + f_name], outputrm)
	print("rm output: ", outputrm)


func _on_logoff_button_pressed():
	Globals.username = ""
	Globals.password = ""
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")


func _on_Exceptions_edit_text_changed(new_text: String):
	if new_text == "":
		Globals.withhold_queue = Globals.const_withhold_queue
	
	var queue: Array = new_text.split(",")
	for i in range(queue.size()):
		queue[i] = queue[i].dedent()
	Globals.withhold_queue = queue
