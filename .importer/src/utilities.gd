# __AUTOLOAD

tool

extends Node

# path: The path to checkout
# Result: Directories in the given path in array
static func list_directories(path) -> Array:
	var dir_list = []
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while (file_name != ""):
			if dir.current_is_dir():
				dir_list.append(file_name)
			file_name = dir.get_next()
	else:
		print("list_directories: An error occurred when trying to access the path.")
		print(path)
	dir_list.erase(".")
	dir_list.erase("..")
	return dir_list

# path: The path to checkout
# Result: Files in the given path in array
static func list_files(path) -> Array:
	var file_list = []
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while (file_name != ""):
			if not dir.current_is_dir():
				file_list.append(file_name)
			file_name = dir.get_next()
	else:
		print("list_files: An error occurred when trying to access the path.")
		print(path)
	file_list.erase(".")
	file_list.erase("..")
	return file_list

static func list_all_files(path) -> Array:
	var file_list = []
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while (file_name != ""):
			if file_name == "." or file_name == "..":
				file_name = dir.get_next()
				continue
			if not dir.current_is_dir():
				file_list.append(path + file_name)
			else:
				if (file_name == ".import" or file_name == ".git"):
					continue
				var dir_path = path
				if dir_path[-1] != "/":
					dir_path += "/"
				dir_path += file_name
				dir_path += "/"
				file_list.append_array(
					list_all_files(dir_path)
				)
			file_name = dir.get_next()
	return file_list

static func list_all_directories(path) -> Array:
	var file_list = []
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while (file_name != ""):
			if file_name == "." or file_name == "..":
				file_name = dir.get_next()
				continue
			if dir.current_is_dir():
				if (file_name == ".import" or file_name == ".git"):
					continue
				var dir_path = path
				if dir_path[-1] != "/":
					dir_path += "/"
				dir_path += file_name
				dir_path += "/"
				file_list.append(path + file_name)
				file_list.append_array(
					list_all_directories(dir_path)
				)
			file_name = dir.get_next()
	return file_list

static func find_file_recursively(start_path, target_file_name):
	var found_file_path = ""
	var last_index = len(start_path) - 1
	if start_path[last_index] == "/":
		start_path = start_path.substr(0, last_index)
	var dir = Directory.new()
	if dir.open(start_path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while (file_name != ""):
			if file_name == "." or file_name == "..":
				file_name = dir.get_next()
				continue
			if not dir.current_is_dir():
				if file_name == target_file_name:
					found_file_path = start_path + "/" + file_name
					break
			else:
				var depth_path = find_file_recursively(
					start_path + "/" + file_name, target_file_name)
				if depth_path != "":
					found_file_path = depth_path
					break
			file_name = dir.get_next()
	return found_file_path

static func internal_find_by_type(
		node: Node, node_class_name: String, result: Array) -> void:
	if not is_instance_valid(node):
		return
	if node.get_class() == node_class_name:
		result.push_back(node)
	for child_index in node.get_child_count():
		var child = node.get_child(child_index)
		internal_find_by_type(child, node_class_name, result)

static func find_nodes_by_type(node: Node, type_name: String) -> Array:
	var nodes = []
	internal_find_by_type(node, type_name, nodes)
	return nodes

static func internal_find_by_script(
		node: Node, node_script_name: String, result: Array) -> void:
	if not is_instance_valid(node):
		return
	var script = node.get_script() as Script
	if script != null:
		var script_name = script.resource_path.split("/")[-1]
		if node_script_name in script_name:
			result.push_back(node)
	for child_index in node.get_child_count():
		var child = node.get_child(child_index)
		internal_find_by_script(child, node_script_name, result)

static func find_nodes_by_script(node: Node, script_name: String) -> Array:
	var nodes = []
	internal_find_by_script(node, script_name, nodes)
	return nodes

static func get_random_vector(radius: = 1.0):
	var x = rand_range(-1, 1)
	var y = rand_range(-1, 1)
	var z = rand_range(-1, 1)
	var vec = Vector3(x, y, z)
	vec *= radius
	return vec

static func optimize_physics_body(body: PhysicsBody):
	var col_shapes = []
	for child in body.get_children():
		if child is CollisionShape:
			col_shapes.append(child)
	var counter = 0
	var index = 0
	var owner_id = body.create_shape_owner(body)
	for col_shape in col_shapes:
		if not Engine.editor_hint:
			print(
				"[Utilities] Optimizing physics body: " + str(body))
			print(
				"Shape: " + str(col_shape) + " :: " + \
					str(index) + " / " + str(len(col_shapes)))
		index += 1
		body.shape_owner_add_shape(owner_id, col_shape.shape)
		body.shape_owner_set_transform(owner_id, col_shape.transform)
		col_shape.queue_free()
		counter += 1
		if counter > 15:
			counter = 0
			yield(VisualServer, "frame_post_draw")
			yield(VisualServer, "frame_post_draw")

static func toggle_physics_body(body: PhysicsBody, enabled: bool):
	var shape_owners = body.get_shape_owners()
	for shape_owner in shape_owners:
		body.shape_owner_set_disabled(shape_owner, not enabled)

static func internal_get_all_children(node: Node):
	var array = []
	for child in node.get_children():
		array.append(child)
		array.append_array(internal_get_all_children(child))
	return array

static func get_all_children(node: Node):
	return internal_get_all_children(node)

static func get_string_lines(text: String) -> PoolStringArray:
	return text.split("\n")

static func combine_string_lines(lines: Array, split_symbol = "\n") -> String:
	var text = ""
	for index in range(len(lines)):
		text += lines[index]
		if index < (len(lines) - 1):
			text += split_symbol
	return text

static func find_keyword_in_lines(lines: Array, keyword: String) -> int:
	var index = 0
	for line in lines:
		if keyword in line:
			return index
		index += 1
	return -1

static func find_line_with_keyword(text: String, keyword: String) -> String:
	var lines = get_string_lines(text)
	var index = find_keyword_in_lines(lines, keyword)
	return lines[index]

static func human_readable_array(list: Array) -> String:
	return simple_array_string(list, ", ")

static func simple_array_string(
		list: Array, space_str = " ", tab_level = 0) -> String:
	var index = 0
	var result_str = ""
	for value in list:
		index += 1
		var value_add = str(value) 
		if tab_level > 0 and (not "\t" in value_add):
			for level in range(tab_level):
				value_add = "\t" + value_add
		result_str += value_add
		if index < len(list):
			result_str += space_str
	if result_str == "":
		result_str = "None"
		for level in range(tab_level):
			result_str = "\t" + result_str
	return result_str

static func snake_to_camel_case(text: String) -> String:
	var indexes = [0]
	var index = 0
	for letter in text:
		if letter == "_":
			indexes.append(index + 1)
		index += 1
	for char_index in indexes:
		text[char_index] = char(ord(text[char_index]) - 32)
	text = text.replace("_", "")
	return text

static func check_multiple_keywords_in_string(
		keywords: Array, text: String) -> bool:
	for keyword in keywords:
		if keyword in text:
			return true
	return false
