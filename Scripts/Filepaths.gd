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

var t
var time := 0.0
var cached_periods := -1
func _physics_process(delta):
	
	if t != null and not t.is_alive():
		match t.wait_to_finish():
			2:
				t = null
	
	time += delta
	var periods := int(time/0.5)%3
	if cached_periods != periods and t != null:
		cached_periods = periods+1
		$CenterContainer/VBoxContainer/Container/LoadingLabel.text = \
			"Loading "+".".repeat(cached_periods)

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
	$CenterContainer/VBoxContainer/Container/LoadingLabel.visible = true
	
	t = Thread.new()
	t.start(_submit.bind(Globals, $CenterContainer/VBoxContainer/Container/ErrorLabel))

func _submit(globals, error_label):
	
	error_label.visible = true
	error_label.text = ""
	
	error_label.set("theme_override_colors/default_color", Color.RED)
	
	var output := []
	OS.execute("scp", ["-r",globals.username+globals.domain+":/home/"+globals.username+"/"+filepath, globals.TEMP_DIR], output, true, true)
	if output != [""]:
		if output[0].begins_with("scp: "):
			error_label.text = "File " + output[0].split(" ")[1] + " does not exist in " + globals.domain
		else:
			error_label.text = "Uncaught error (report): " + str(output)
		return
	
	var filepath_arr := filepath.split("/")
	var filepath_ending_name: String = filepath_arr[filepath_arr.size()-1]
	var del_queue := [filepath_ending_name]
	
	var files := []
	if filepath_ending_name.ends_with(".zip"):
		
		OS.execute("powershell.exe", ["-Command", "tar -tf "+globals.TEMP_DIR.replace(" ", "` ")+"\\"+filepath_ending_name], files, true)
		
		files = str(files).trim_prefix("[\"").trim_suffix("\"]").split("\\r\\n")
		
		print("zip file tree: ",files)
		
		var output2 = []
		OS.execute("powershell.exe", ["-Command", "tar -xvf "+globals.TEMP_DIR.replace(" ", "` ")+"\\"+filepath_ending_name+" -C "+\
		globals.TEMP_DIR.replace(" ", "` ")], output2, true)
		print("Unzip ret: ", output2)
	
		filepath_ending_name = files[0].trim_suffix("/")
		del_queue = [filepath_ending_name, filepath_ending_name+".zip"]
	
	if DirAccess.dir_exists_absolute(globals.TEMP_DIR+"\\"+filepath_ending_name) and globals.withhold_queue.size() > 0:
		print("Witholding detected... Processing...")
		for withhold_token in globals.withhold_queue:
			OS.execute("powershell.exe", ["-Command", "rm -Recurse -Force "+globals.TEMP_DIR.replace(" ", "` ") + "\\" + filepath_ending_name + "\\" + withhold_token])
	
	output = globals.upload_to_gradescope(tooltips[selected_course], selected_assignment, filepath_ending_name)
	if output != [""]:
		if output[0].begins_with("submitted! visit"):
			error_label.set("theme_override_colors/default_color", Color.GREEN)
			error_label.text = output[0].trim_suffix("\\r\\n")
		else:
			error_label.text = "Uncaught error (report, nonblocking): " + str(output)
	
	var outputrm = []
	for f_name in del_queue:
		OS.execute("powershell.exe", ["-Command", "rm -Recurse -Force "+globals.TEMP_DIR.replace(" ", "` ") + "\\" + f_name], outputrm)
	print("rm output: ", outputrm)
	
	return 2


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
