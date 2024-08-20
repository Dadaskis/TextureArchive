extends Node

onready var logs = $logs
onready var path_text = $path_text
onready var file_dialog = $file_dialog

var library_path
var template_text
var quixel_mats

func get_local_path():
	var path = "./"
	if not OS.has_feature("standalone"):
		path = "../"
	else:
		path = OS.get_executable_path().get_base_dir() + "/"
	return path

func get_folder_path():
	var path = get_local_path()
	path += "PBR/"
	return path

func get_quixel_surface_path():
	return library_path + "/Custom/surface/"

func folder_exists():
	var dir = Directory.new()
	return dir.dir_exists(get_folder_path())

func print_log(text: = ""):
	logs.text += "\n" + text
	logs.scroll_to_line(logs.get_line_count() - 1)

func load_template():
	var file = File.new()
	file.open("res://template.json", File.READ)
	template_text = file.get_as_text()
	file.close()

func _ready():
	print_log("Program Start")
	load_values()
	load_template()
	if library_path != "":
		print_log("Path loaded: " + library_path)
	
	print_log("PBR folder path: " + get_folder_path())
	if not folder_exists():
		print_log("Error: PBR folder does not exist")
		$button.visible = false
		return
	
	print_log()
	
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

func load_values():
	var save_path = get_local_path() + "save.json"
	
	var file = File.new()
	if not file.file_exists(save_path):
		return
	
	file.open(save_path, File.READ)
	var json_text = str(file.get_as_text())
	var values = parse_json(json_text)
	file.close()
	
	set_library_path(values.get("library_path", ""))

func save_values():
	var save_path = get_local_path() + "save.json"
	var file = File.new()
	file.open(save_path, File.WRITE)
	var values = {}
	values["library_path"] = library_path
	file.store_string(to_json(values))
	file.close()

func set_library_path(value):
	library_path = value
	path_text.text = "Path to Quixel Library: " + value
	save_values()

func file_dialog_dir_selected(dir):
	set_library_path(dir)

func path_select():
	file_dialog.popup()

func process_material(dir_path, category):
	var files = Utilities.list_all_files(dir_path)
	print_log("Processing: " + dir_path)
	for file in files:
		print_log(file)

func import_pressed():
	print_log("Importing start")
	
	var categories = Utilities.list_directories(get_folder_path())
	
	quixel_mats = Utilities.list_directories(get_quixel_surface_path())
	print_log("Already imported:")
	for mat in quixel_mats:
		print_log(mat)
	
	for category in categories:
		var materials = Utilities.list_directories(
			get_folder_path() + category
		)
		
		for material in materials:
			if material in quixel_mats:
				continue
			process_material(
				get_folder_path() + category + "/" + material, category
			)
	
	print_log("Importing end")
