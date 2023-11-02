extends Node

var TEMP_DIR := (OS.get_user_data_dir() + "\\Python").replace("/","\\")
#var PYTHON = OS.get_user_data_dir().split("\\AppData\\Roaming",true,2)[0] + "\\AppData\\Local\\Programs\\Python\\Python312\\python.exe"
var PYTHON := ""

var username: String 
var password: String 
var domain: String

const const_withhold_queue = ["*.out", "*.tmp"]
var withhold_queue := ["*.out", "*.tmp"]

func _ready():
	
	print("DirAccess.dir_exists_absolute user://Python call: ", DirAccess.dir_exists_absolute("user://Python"))
	if not DirAccess.dir_exists_absolute("user://Python"):
		var d := DirAccess.open("user://")
		d.make_dir_recursive("user://Python")
		print("Creating user://Python directory")
	
	print("Is standalone: ", OS.has_feature("standalone"))
	if not FileAccess.file_exists(TEMP_DIR+"\\courses.py") or not FileAccess.file_exists(TEMP_DIR+"\\submission.py"):
		var dir: DirAccess 
		var err1 := -2
		var err2 := -2
		if true:#OS.has_feature("standalone"):
			var folder : String = OS.get_executable_path().replace("/","\\").rsplit("\\",true,1)[0]
			print("Python files not found. Checking in exe directory at: ", folder,"?")
			dir = DirAccess.open(folder)
			err1=dir.copy("courses.py", "user://Python/courses.py")
			err2=dir.copy("submission.py", "user://Python/submission.py")
#		else:
#			dir = DirAccess.open("res://Python")
#			err1=dir.copy("res://Python/courses.py", TEMP_DIR+"\\courses.py")
#			err2=dir.copy("res://Python/submission.py", TEMP_DIR+"\\submission.py")
		print("Replacing. Errnos: "+str(err1)+" "+str(err2))
	
	
	
	var poutput = []
	OS.execute("powershell.exe", ["-Command", "Get-Command -ShowCommandInfo python"], poutput)
	PYTHON = str(poutput).trim_prefix("""["\\r\\n\\r\\nName          : python.exe\\r\\nModuleName    : \\r\\nModule        : @{Name=}\\r\\nCommandType   : Application\\r\\nDefinition    : """).trim_suffix("""\\r\\nParameterSets : {}\\r\\n\\r\\n\\r\\n\\r\\n"]""")
	print("Python location: ", PYTHON)

func get_list_of_classes():
	print("Obtaining classes...")
	
	var output := []
	
	print("Executing: " + PYTHON + "\n" + TEMP_DIR+"\\courses.py" + "\n" + username +" "+ password + "\n", output, true, false)
	OS.execute(PYTHON, [TEMP_DIR+"\\courses.py", username, password], output, true, false)
	print("Execution output: ",output)
	
	var output_array = str(output).replace("\""+username+" "+password,"").replace("\\n", "").replace("\\r", "").replace("\\\'", "\"").split("|")
	var simplified_course_list = output_array[0].replace("[","{").replace("]", "}")
	var course_list = simplified_course_list.trim_suffix("}") + "]"
	course_list = course_list.trim_prefix("{\"{")
	course_list = "[" + course_list
	
	var simplified_ass_list = output_array[1]
	var ass_list = simplified_ass_list.trim_suffix("\"]")
	
	var arr_course_list = JSON.parse_string(course_list)
	var arr_ass_list = JSON.parse_string(ass_list)
	
	return [arr_course_list, arr_ass_list]

func upload_to_gradescope(course: String, assignment: String, filename: String):
	var output := []
	var input_array := [TEMP_DIR+"\\submission.py", username, password, course, assignment, TEMP_DIR.replace(" ","@|@")+"\\"+filename]
	
	OS.execute(PYTHON, input_array, output, true, false)
	print(output)
	
	return output
