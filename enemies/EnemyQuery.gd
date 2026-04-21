class_name EnemyQuery extends RefCounted

static func nearest(tree: SceneTree, pos: Vector2, max_dist: float = INF) -> Node2D:
	var best: Node2D = null
	var best_d: float = max_dist
	for e in tree.get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var d: float = e.global_position.distance_to(pos)
		if d < best_d:
			best_d = d
			best = e
	return best


static func nearest_n(tree: SceneTree, pos: Vector2, n: int, max_dist: float = INF, exclude: Array = []) -> Array:
	var candidates: Array = []
	for e in tree.get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or e in exclude:
			continue
		var d: float = e.global_position.distance_to(pos)
		if d <= max_dist:
			candidates.append([d, e])
	candidates.sort_custom(func(a, b): return a[0] < b[0])
	var result: Array = []
	for i in min(n, candidates.size()):
		result.append(candidates[i][1])
	return result


static func random_within(tree: SceneTree, pos: Vector2, max_dist: float) -> Node2D:
	var candidates: Array = []
	for e in tree.get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		if e.global_position.distance_to(pos) <= max_dist:
			candidates.append(e)
	if candidates.is_empty():
		return null
	return candidates[randi() % candidates.size()]
