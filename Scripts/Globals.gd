extends Node

var TEMP_DIR := (OS.get_user_data_dir() + "\\Python").replace("/","\\")
#var PYTHON = OS.get_user_data_dir().split("\\AppData\\Roaming",true,2)[0] + "\\AppData\\Local\\Programs\\Python\\Python312\\python.exe"
var PYTHON := ""

var username: String 
var password: String 
var domain: String

func _ready():
	
	if not FileAccess.file_exists(TEMP_DIR+"\\courses.py") or not FileAccess.file_exists(TEMP_DIR+"\\submission.py"):
		var dir := DirAccess.open("res://Python")
		var err1=dir.copy("res://Python/courses.py", TEMP_DIR+"\\courses.py")
		var err2=dir.copy("res://Python/submission.py", TEMP_DIR+"\\submission.py")
		print("Python files not found. Replacing. Errs: "+str(err1)+" "+str(err2))
	
	var poutput = []
	OS.execute("powershell.exe", ["-Command", "Get-Command -ShowCommandInfo python"], poutput)
	PYTHON = str(poutput).trim_prefix("""["\\r\\n\\r\\nName          : python.exe\\r\\nModuleName    : \\r\\nModule        : @{Name=}\\r\\nCommandType   : Application\\r\\nDefinition    : """).trim_suffix("""\\r\\nParameterSets : {}\\r\\n\\r\\n\\r\\n\\r\\n"]""")
	
	if not DirAccess.dir_exists_absolute("user://Python"):
		var d := DirAccess.open("user://")
		d.make_dir_recursive("user://Python")

func get_list_of_classes():
	var output := []
	
	OS.execute(PYTHON, [TEMP_DIR+"\\courses.py", username, password], output, true, false)
	
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
