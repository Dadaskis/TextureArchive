from subprocess import Popen, PIPE
from codecs import decode
import os

def get_current_branch_name():
	git_branch_name = Popen(
		[
			'git', 'rev-parse', '--abbrev-ref', 'HEAD'
		], 
		stdout=PIPE
	)
	branch_name_list = git_branch_name.stdout.readlines()
	branch_name = str(branch_name_list[0]).replace("b'", "")
	branch_name = branch_name.replace("\\n'", "")
	return branch_name

def has_changes_to_pull():
	try:
		git_branch_name = get_current_branch_name()
		git_rev_list = Popen(
			[
				"git", "rev-list", git_branch_name + "..origin/" + git_branch_name, "--count"
			], 
			stdout=PIPE
		)
		list_of_count = git_rev_list.stdout.readlines()
		commit_count_str = str(list_of_count[0])
		commit_count_str = commit_count_str.replace("b'", "")
		commit_count_str = commit_count_str.replace("\\n'", "")
		commit_count = int(commit_count_str)

		if commit_count > 0:
			return True
		return False
	except:
		return False

Popen(
	[
		'git', 'log', '--max-count', '1'
	]
).wait()

def commit_part_msg(msg, part):
	message = msg
	if part > 0:
		message += " [PART " + str(part) + "]"
	Popen(['git', 'commit', '-m', message]).wait()

def commit(msg):
	# git status --porcelain | cut -c 1-3 --complement
	git_status = Popen(
		[
			'git', 'status', '--porcelain', '-u'
		], 
		stdout=PIPE
	)

	git_commits_cmd = Popen(
		[
			'git', 'log', '--oneline'
		], 
		stdout=PIPE
	)
	git_commits_b = git_commits_cmd.stdout.readlines()
	git_commit_counter = 0
	for git_commit_b in git_commits_b:
		git_commit = str(git_commit_b)
		if (msg in git_commit) and (not "PART" in git_commit):
			git_commit_counter += 1

	if git_commit_counter > 0:
		git_commit_counter += 1
		msg = msg + " [" + str(git_commit_counter) + "]"

	files_omitted_b = git_status.stdout.readlines()
	files_omitted = []
	
	for file_path_b in files_omitted_b:
		file_path = str(file_path_b)
		file_path = file_path.replace("\\n'", "")
		file_path = file_path.replace("b'", "")
		file_path = file_path.replace("\"", "")
		file_path = file_path.strip()
		remove_word = file_path.split(" ")[0]
		file_path = file_path.replace(remove_word, "")
		file_path = file_path.strip()
		files_omitted.append(file_path)

	for file_path in files_omitted:
		if ".import/" in file_path:
			continue
		if "game_export/game_files" in file_path:
			continue
		path = "./" + file_path
		if not os.path.exists(path):
			continue
		size = os.path.getsize(path)
		size = (size / 1000) / 1000
		if size > 100.0:
			print("100 megabyte limit! Reverting the commit.")
			print(path)
			return
		if size > 20.0:
			print("Warning! High file size: " + path + " | " + str(size) + "MB")

	commit_size = 0
	commit_part = 0
	for file_path in files_omitted:
		if ".import/" in file_path:
			continue
		if "game_export/game_files" in file_path:
			continue
		path = "./" + file_path
		if not os.path.exists(path):
			continue
		size = os.path.getsize(path)
		size = (size / 1000) / 1000
		commit_size += size
		Popen(['git', 'add', path]).wait()
		if commit_size >= 10.0:
			commit_part_msg(msg, commit_part)
			commit_part += 1
			commit_size = 0
	Popen(['git', 'add', '*']).wait()
	Popen(['git', 'add', '-u']).wait()
	commit_part_msg(msg, commit_part)

	Popen(
		[
			'git', 'log', '--max-count', '1'
		]
	).wait()

	print()
	print()
	print()

while True:
	print("GIC - Giantic Commit | Git Utility")
	print("1. Commit           |     Stage all changes and commit them.")
	print("2. Push             |     Send changes to server.")
	print("3. Pull             |     Get changes from server.")
	print("4. List of branches |     Lists all local and remote branches")
	print("5. Switch branch    |     Switch to existing branch")
	print("6. Create branch    |     Create a new branch based of current one")
	print("7. Reset HARD       |     Brutally discard all local changes")
	print("8. Fetch            |     Update information about remotes")
	print("9. Purge            |     Shallow git commit history to save disc space")
	print("") 
	print("Current branch name: " + get_current_branch_name())
	print("")
	needs_pull = has_changes_to_pull()
	needs_pull_str = "NO NEED"
	if needs_pull:
		needs_pull_str = "YES, YOU NEED TO PULL"
	print("Has changes to pull? " + needs_pull_str)
	print("")
	print("")
	print("")
	
	option = 0
	input_option = input("Your option: ")
	try:
		option = int(input_option)
	except:
		if len(input_option) > 3:
			msg = str(input_option)
			commit(msg)
			continue

	print("Processing your option...")
	print()
	print()
	print()

	if option == 1:
		msg = str(input("Commit message: "))
		commit(msg)
		continue

	if option == 2:
		git_branch_name = get_current_branch_name()

		while True:
			git_rev_list = Popen(
				[
					'git', 'rev-list', '--reverse', '--date-order', 'origin/' + git_branch_name + '..' + git_branch_name
				], 
				stdout=PIPE
			)

			list_of_commit_hashes = git_rev_list.stdout.readlines()

			if len(list_of_commit_hashes) == 0:
				print("Pushed everything!")
				print()
				print()
				print()
				break

			str_commit_hash = str(list_of_commit_hashes[0])
			str_commit_hash = str_commit_hash.replace("b'", "")
			str_commit_hash = str_commit_hash.replace("\\n'", "")
			process = Popen(["git", "push", "origin", str_commit_hash + ":" + git_branch_name])
			process.wait()
		continue

	if option == 3:
		Popen(["git", "pull"]).wait()
		print("[git pull] is done!")
		print()
		print()
		print()
		continue

	if option == 4:
		Popen(["git", "branch", "--all"]).wait()
		print("")
		print("")
		print("")
		continue

	if option == 5:
		Popen(["git", "branch", "--all"]).wait()
		print("Switching the branch. Please, enter the full name of branch you want to switch to.")
		print("Enter \"NULL\" to discontinue.")
		branch_name = input("Branch name: ")
		if branch_name == "NULL":
			continue
		Popen(["git", "switch", branch_name]).wait()
		print("")
		print("")
		print("")
		continue

	if option == 6:
		Popen(["git", "branch", "--all"]).wait()
		print("Creating a new branch based of current branch.")
		current_branch_name = get_current_branch_name()
		print("Current branch name: " + current_branch_name)
		print("Enter \"NULL\" to discontinue.")
		branch_name = input("Branch name: ")
		if branch_name == "NULL":
			print("Discontinuing the operation.")
			print("")
			print("")
			print("")
			continue
		Popen(["git", "branch", branch_name, current_branch_name]).wait()
		Popen(["git", "checkout", branch_name]).wait()
		print("")
		print("")
		print("")
		continue

	if option == 7:
		print("Reset of all local changes. To accept the operation, write \"RESET\"")
		accept_word = input("Accept word: ")
		if accept_word == "RESET":
			Popen(["git", "reset", "--hard"]).wait()
		else:
			print("Discontinuing the operation.")
		print("")
		print("")
		print("")
		continue

	if option == 8:
		process = Popen(["git", "fetch"])
		process.wait()
		print("")
		print("")
		print("")
		continue

	if option == 9:
		print("Purge in progress...")
		process = Popen(["git", "fetch", "--depth", "5"])
		process.wait()
		process = Popen(["git", "reflog", "expire", "--expire=all", "--all"])
		process.wait()
		process = Popen(["git", "gc", "--prune=now"])
		process.wait()
		print("")
		print("")
		print("")
		continue

	print("Wrong option?")
