extends Node
## Generic object pooling for high-frequency nodes (enemies, projectiles, pickups, VFX).
## Pools are created per scene path. Acquire/release never instantiates/destroys
## in steady state — nodes are recycled.

var _pools: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

## Create (or get) a pool for a scene with an initial prewarm size.
func create_pool(scene_path: String, prewarm: int = 0) -> void:
	if _pools.has(scene_path):
		return
	var pool := {
		"scene": load(scene_path),
		"free": [],
		"active_count": 0,
		"total_created": 0,
	}
	_pools[scene_path] = pool
	for i in range(prewarm):
		var node := _instantiate(pool)
		node.visible = false
		pool["free"].append(node)

func _instantiate(pool: Dictionary) -> Node:
	var node: Node = pool["scene"].instantiate()
	pool["total_created"] += 1
	return node

## Acquire an instance. Caller must add it to the tree.
func acquire(scene_path: String) -> Node:
	if not _pools.has(scene_path):
		create_pool(scene_path)
	var pool: Dictionary = _pools[scene_path]
	var node: Node
	if pool["free"].is_empty():
		node = _instantiate(pool)
	else:
		node = pool["free"].pop_back()
	pool["active_count"] += 1
	return node

## Release an instance back to its pool. Removes from parent.
func release(node: Node) -> void:
	if node == null or not is_instance_valid(node):
		return
	var scene_path: String = node.get_meta("pool_scene", "")
	if scene_path == "" or not _pools.has(scene_path):
		node.queue_free()
		return
	var pool: Dictionary = _pools[scene_path]
	node.get_parent().remove_child(node)
	node.visible = false
	pool["free"].append(node)
	pool["active_count"] -= 1

## Mark a node as poolable under a scene path (call right after acquire).
func tag(node: Node, scene_path: String) -> void:
	node.set_meta("pool_scene", scene_path)

func get_pool_stats(scene_path: String) -> Dictionary:
	if not _pools.has(scene_path):
		return {}
	var pool: Dictionary = _pools[scene_path]
	return {
		"free": pool["free"].size(),
		"active": pool["active_count"],
		"created": pool["total_created"],
	}

func get_all_stats() -> Dictionary:
	var out := {}
	for key in _pools:
		out[key] = get_pool_stats(key)
	return out

func clear_all() -> void:
	for key in _pools:
		var pool: Dictionary = _pools[key]
		for node in pool["free"]:
			if is_instance_valid(node):
				node.queue_free()
	_pools.clear()
