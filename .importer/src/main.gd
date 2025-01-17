extends Node

class MaterialData:
	var diffuse_path: String
	var displacement_path: String
	var normal_path: String
	var roughness_path: String
	var metalness_path: String
	var is_metal: = false

onready var logs = $logs
onready var path_text = $path_text
onready var file_dialog = $file_dialog
onready var model = $viewport/camera/mesh_instance
onready var viewport = $viewport

var library_path
var template_text
var template_metal_text
var quixel_mats

signal next_material()

func get_local_path():
	var path = "./"
	if not OS.has_feature("standalone"):
		path = "res://"
		path = ProjectSettings.globalize_path(path)
		path = path.replace(".importer/", "")
	else:
		path = OS.get_executable_path().get_base_dir() + "/"
	return path

func get_folder_path():
	var path = get_local_path()
	path += "PBR/"
	return path

func get_quixel_surface_path():
	return library_path + "/Custom/surface/"

func get_quixel_material_path(mat_name: String):
	var directory = Directory.new()
	var path = get_quixel_surface_path() + mat_name + "/"
	directory.make_dir_recursive(path)
	return path

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
	
	file.open("res://template_metal.json", File.READ)
	template_metal_text = file.get_as_text()
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

func detect_textures(dir_path) -> MaterialData:
	var data = MaterialData.new()
	var files = Utilities.list_all_files(dir_path)
	
	for file in files:
		# AmbientCG
		if "_Color" in file:
			data.diffuse_path = file
		if "_Displacement" in file:
			data.displacement_path = file
		if "_NormalGL" in file:
			data.normal_path = file
		if "_Roughness" in file:
			data.roughness_path = file
		if "_Metalness" in file:
			data.metalness_path = file
			data.is_metal = true
		# Polyhaven
		if "_diff" in file:
			data.diffuse_path = file
		if "_disp" in file:
			data.displacement_path = file
		if "_nor" in file:
			data.normal_path = file
		if "_rough" in file:
			data.roughness_path = file
		if "_metal" in file:
			data.metalness_path = file
			data.is_metal = true
	
	return data

func get_image_texture(path: String):
	var image = Image.new()
	image.load(path)
	var tex = ImageTexture.new()
	tex.create_from_image(image)
	return tex

func get_average_color(path: = "") -> String:
	var image = Image.new()
	image.load(path)
	image.lock()
	var color_avg = Color.black
	var sample_width = 10
	var sample_height = 10
	for x in range(sample_width):
		for y in range(sample_height):
			var color = image.get_pixel(x, y)
			color_avg.r += color.r
			color_avg.g += color.g
			color_avg.b += color.b
	color_avg.r /= sample_width * sample_height
	color_avg.g /= sample_width * sample_height
	color_avg.b /= sample_width * sample_height
	image.unlock()
#	print_log(str(color_avg))
	return color_avg.to_html(false)

func get_resolution_text(path: = "") -> String:
	var image = Image.new()
	image.load(path)
	return str(image.get_width()) + "x" + str(image.get_height())

func get_file_size(path: = "") -> String:
	var file: = File.new()
	return str(file.get_len())

func process_material(dir_path: String, category: String):
	var mat_name: = dir_path.split("/")[-2] as String
	
	var files = Utilities.list_all_files(dir_path)
	print_log("Processing: " + dir_path)
#	for file in files:
#		print_log(file)
	var mat_data = detect_textures(dir_path)
	print_log("Diffuse: " + mat_data.diffuse_path)
	print_log("Displacement: " + mat_data.displacement_path)
	print_log("Normal: " + mat_data.normal_path)
	print_log("Roughness: " + mat_data.roughness_path)
	
	var material = SpatialMaterial.new()
	material.albedo_texture = get_image_texture(mat_data.diffuse_path)
	material.roughness_texture = get_image_texture(mat_data.roughness_path)
	material.normal_enabled = true
	material.normal_texture = get_image_texture(mat_data.normal_path)
	if mat_data.is_metal:
		material.metallic_texture = get_image_texture(mat_data.metalness_path)
		material.metallic = 1.0
	model.material_override = material
	
	yield(VisualServer, "frame_post_draw")
	var tex = viewport.get_texture()
	var img = tex.get_data()
#	img.save_png("C:/Users/Dadaskis/Desktop/previews/" + mat_name + ".png")
	img.save_png(get_quixel_material_path(mat_name) + mat_name + "_Preview.png")
	
	var file_template = get_quixel_material_path(mat_name) + mat_name + "_TEMPLATE.jpg"
	
	var dir = Directory.new()
	dir.copy(
		mat_data.diffuse_path, file_template.replace("TEMPLATE", "Diffuse"))
	dir.copy(
		mat_data.normal_path, file_template.replace("TEMPLATE", "Normal"))
	dir.copy(
		mat_data.roughness_path, file_template.replace("TEMPLATE", "Roughness"))
	if mat_data.is_metal:
		dir.copy(
			mat_data.metalness_path, 
				file_template.replace("TEMPLATE", "Metalness"))
	
	var template = template_text
	if mat_data.is_metal:
		template = template_metal_text
	var mat_id = mat_name.sha256_text()
	
	template = template.replace(
		"QUIXEL_CATEGORY",
		category.to_lower()
	)
	
	template = template.replace(
		"QUIXEL_MATERIAL_ID",
		mat_id
	)
	
	template = template.replace(
		"QUIXEL_MATERIAL_NAME",
		mat_name
	)
	
	template = template.replace(
		"QUIXEL_FILE_PREVIEW",
		mat_name + "_Preview.png"
	)
	
	template = template.replace(
		"QUIXEL_DIFFUSE_AVERAGE_COLOR",
		get_average_color(mat_data.diffuse_path)
	)
	
	template = template.replace(
		"QUIXEL_DIFFUSE_RESOLUTION",
		get_resolution_text(mat_data.diffuse_path)
	)
	
	template = template.replace(
		"QUIXEL_DIFFUSE_FILE",
		file_template.replace("TEMPLATE", "Diffuse")
	)
	
	template = template.replace(
		"QUIXEL_DIFFUSE_TYPE",
		"image/jpeg"
	)
	
	template = template.replace(
		"QUIXEL_DIFFUSE_SIZE",
		get_file_size(mat_data.diffuse_path)
	)
	
	template = template.replace(
		"QUIXEL_ROUGHNESS_AVERAGE_COLOR",
		get_average_color(mat_data.roughness_path)
	)
	
	template = template.replace(
		"QUIXEL_ROUGHNESS_RESOLUTION",
		get_resolution_text(mat_data.roughness_path)
	)
	
	template = template.replace(
		"QUIXEL_ROUGHNESS_FILE",
		file_template.replace("TEMPLATE", "Roughness")
	)
	
	template = template.replace(
		"QUIXEL_ROUGHNESS_TYPE",
		"image/jpeg"
	)
	
	template = template.replace(
		"QUIXEL_ROUGHNESS_SIZE",
		get_file_size(mat_data.roughness_path)
	)
	
	template = template.replace(
		"QUIXEL_NORMAL_AVERAGE_COLOR",
		get_average_color(mat_data.normal_path)
	)
	
	template = template.replace(
		"QUIXEL_NORMAL_RESOLUTION",
		get_resolution_text(mat_data.normal_path)
	)
	
	template = template.replace(
		"QUIXEL_NORMAL_FILE",
		file_template.replace("TEMPLATE", "Normal")
	)
	
	template = template.replace(
		"QUIXEL_NORMAL_TYPE",
		"image/jpeg"
	)
	
	template = template.replace(
		"QUIXEL_NORMAL_SIZE",
		get_file_size(mat_data.normal_path)
	)
	
	template = template.replace(
		"QUIXEL_DISPLACEMENT_AVERAGE_COLOR",
		get_average_color(mat_data.displacement_path)
	)
	
	template = template.replace(
		"QUIXEL_DISPLACEMENT_RESOLUTION",
		get_resolution_text(mat_data.displacement_path)
	)
	
	template = template.replace(
		"QUIXEL_DISPLACEMENT_FILE",
		file_template.replace("TEMPLATE", "Displacement")
	)
	
	template = template.replace(
		"QUIXEL_DISPLACEMENT_TYPE",
		"image/jpeg"
	)
	
	template = template.replace(
		"QUIXEL_DISPLACEMENT_SIZE",
		get_file_size(mat_data.displacement_path)
	)
	
	if mat_data.is_metal:
		template = template.replace(
			"QUIXEL_METALNESS_AVERAGE_COLOR",
			get_average_color(mat_data.metalness_path)
		)
		
		template = template.replace(
			"QUIXEL_METALNESS_RESOLUTION",
			get_resolution_text(mat_data.metalness_path)
		)
		
		template = template.replace(
			"QUIXEL_METALNESS_FILE",
			file_template.replace("TEMPLATE", "Metalness")
		)
		
		template = template.replace(
			"QUIXEL_METALNESS_TYPE",
			"image/jpeg"
		)
		
		template = template.replace(
			"QUIXEL_METALNESS_SIZE",
			get_file_size(mat_data.metalness_path)
		)
	
	var file = File.new()
	file.open(get_quixel_material_path(mat_name) + mat_id + ".json", File.WRITE)
	file.store_string(template)
	file.close()
	
	print_log("Processing done: " + dir_path)
	print_log()
	yield(VisualServer, "frame_post_draw")
	emit_signal("next_material")

func import_pressed():
	print_log()
	print_log("Importing start")
	
	var categories = Utilities.list_directories(get_folder_path())
	
	quixel_mats = Utilities.list_directories(get_quixel_surface_path())
	print_log()
	print_log("Already imported:")
	for mat in quixel_mats:
		print_log(mat)
	
	print_log()
	for category in categories:
		var materials = Utilities.list_directories(
			get_folder_path() + category
		)
		
		for material in materials:
			if material in quixel_mats:
				continue
			process_material(
				get_folder_path() + category + "/" + material + "/", category
			)
			yield(self, "next_material")
	
	print_log("Importing end")
