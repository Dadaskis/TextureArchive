extends Node

onready var logs = $logs

func get_folder_path():
	var path = "./"
	if not OS.has_feature("standalone"):
		path = "../"
	else:
		path = OS.get_executable_path().get_base_dir() + "/"
	path += "PBR/"
	return path

func folder_exists():
	var dir = Directory.new()
	return dir.dir_exists(get_folder_path())

func print_log(text: String):
	logs.text += "\n" + text

func _ready():
	print_log("Program Start")
	
	print_log(get_folder_path())
	if not folder_exists():
		print_log("Error: PBR folder does not exist")
		$button.visible = false
		return
	
	var categories = Utilities.list_directories(get_folder_path())
	print_log("Detected Categories")
	for category in categories:
		print_log(category)
	
	var counter = 0
	for category in categories:
		var amount = len(
			Utilities.list_directories(get_folder_path() + category)
		)
		counter += amount
	print_log(str(counter) + " materials detected")
