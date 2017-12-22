# class Blackbord

base_memory = {}
tree_memory = {}

func get_tree_memory(tree_scope):
	if !tree_memory[tree_scope]:
		tree_memory[tree_scope] = {
			'action_memory': {},
			'open_actions': []
		}
	return tree_memory[tree_scope]

func get_action_memory(tree_memory, action_scope):
	var memory = tree_memory['action_memory']
	if !memory[action_scope]:
		memory[action_scope] = {}
	return memory[action_scope]

func get_memory(tree_scope = null, action_scope = null):
	var memory = base_memory
	if tree_scope:
		memory = get_tree_memory(tree_scope)
		if action_scope:
			memory = get_action_memory(memory, action_scope)
	return memory

func set(key, value, tree_scope = null, action_scope = null):
	var memory = get_memory(tree_scope, action_scope)
	memory[key] = value

func get(key, tree_scope = null, action_scope = null):
	var memory = get_memory(tree_scope, action_scope)
	if memory: return memory[key]