extends Node3D
## V4 arena decoration: procedurally scatters cheap primitive props around
## the arena — grass tufts, extra rocks, simple trees, wall pillars, check
## pattern overlay via large flat quads. All decorative, no colliders, so
## horde flow is unaffected. Budget-conscious (static, merged into one
## parent node).

const GRASS_COUNT := 90
const TREE_COUNT := 14
const EXTRA_ROCKS := 18
const WALL_PILLARS := 20

const GRASS_COLOR := Color(0.42, 0.62, 0.3)
const GRASS_COLOR2 := Color(0.5, 0.68, 0.34)
const TRUNK_COLOR := Color(0.38, 0.27, 0.17)
const LEAF_COLOR := Color(0.3, 0.55, 0.28)
const STONE_COLOR := Color(0.55, 0.52, 0.48)

@onready var arena: Node3D = get_parent()

func _ready() -> void:
	_build_grass()
	_build_trees()
	_build_rocks()
	_build_wall_pillars()

func _random_ring_pos(min_r: float, max_r: float) -> Vector3:
	var angle := randf() * TAU
	var r := randf_range(min_r, max_r)
	return Vector3(cos(angle) * r, 0, sin(angle) * r)

func _build_grass() -> void:
	var parent := Node3D.new()
	parent.name = "Grass"
	add_child(parent)
	var blade := PrismMesh.new()
	blade.size = Vector3(0.16, 0.45, 0.16)
	for i in range(GRASS_COUNT):
		var tuft := Node3D.new()
		tuft.position = _random_ring_pos(6.0, 56.0)
		parent.add_child(tuft)
		var mat := _baked_mat(GRASS_COLOR if i % 2 == 0 else GRASS_COLOR2)
		for b in range(3):
			var mi := MeshInstance3D.new()
			mi.mesh = blade
			mi.material_override = mat
			mi.position = Vector3(randf_range(-0.3, 0.3), 0.2, randf_range(-0.3, 0.3))
			mi.rotation.z = randf_range(-0.3, 0.3)
			tuft.add_child(mi)

func _build_trees() -> void:
	var parent := Node3D.new()
	parent.name = "Trees"
	add_child(parent)
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.18
	trunk.bottom_radius = 0.26
	trunk.height = 2.2
	var crown := SphereMesh.new()
	crown.radius = 1.3
	crown.height = 2.2
	for i in range(TREE_COUNT):
		var tree := Node3D.new()
		# Keep trees near the edges so combat space stays open
		tree.position = _random_ring_pos(38.0, 56.0)
		parent.add_child(tree)
		var trunk_mi := MeshInstance3D.new()
		trunk_mi.mesh = trunk
		trunk_mi.material_override = _baked_mat(TRUNK_COLOR)
		trunk_mi.position = Vector3(0, 1.1, 0)
		tree.add_child(trunk_mi)
		var crown_mi := MeshInstance3D.new()
		crown_mi.mesh = crown
		crown_mi.material_override = _baked_mat(LEAF_COLOR if i % 2 == 0 else LEAF_COLOR.lightened(0.08))
		crown_mi.position = Vector3(0, 2.9, 0)
		crown_mi.scale = Vector3.ONE * randf_range(0.85, 1.25)
		tree.add_child(crown_mi)

func _build_rocks() -> void:
	var parent := Node3D.new()
	parent.name = "Rocks"
	add_child(parent)
	var rock := BoxMesh.new()
	rock.size = Vector3(1.4, 0.9, 1.2)
	for i in range(EXTRA_ROCKS):
		var rock_mi := MeshInstance3D.new()
		rock_mi.mesh = rock
		rock_mi.material_override = _baked_mat(STONE_COLOR.darkened(randf_range(0.0, 0.25)))
		rock_mi.position = _random_ring_pos(14.0, 57.0) + Vector3(0, 0.35, 0)
		rock_mi.rotation.y = randf() * TAU
		rock_mi.rotation.z = randf_range(-0.12, 0.12)
		rock_mi.scale = Vector3.ONE * randf_range(0.6, 1.4)
		parent.add_child(rock_mi)

func _build_wall_pillars() -> void:
	var parent := Node3D.new()
	parent.name = "WallPillars"
	add_child(parent)
	var pillar := BoxMesh.new()
	pillar.size = Vector3(1.6, 4.2, 1.6)
	var cap := BoxMesh.new()
	cap.size = Vector3(2.0, 0.4, 2.0)
	for i in range(WALL_PILLARS):
		var t := float(i) / WALL_PILLARS
		# Along each wall: 4 pillars + corners share
		var pos: Vector3
		var per_side := WALL_PILLARS / 4
		var side := i / per_side
		var k := float(i % per_side) / (per_side - 1)
		var spread := lerpf(-57.0, 57.0, k)
		match side:
			0: pos = Vector3(spread, 2.1, -59.5)
			1: pos = Vector3(spread, 2.1, 59.5)
			2: pos = Vector3(-59.5, 2.1, spread)
			_: pos = Vector3(59.5, 2.1, spread)
		var p := MeshInstance3D.new()
		p.mesh = pillar
		p.material_override = _baked_mat(STONE_COLOR.darkened(0.1))
		p.position = pos
		parent.add_child(p)
		var c := MeshInstance3D.new()
		c.mesh = cap
		c.material_override = _baked_mat(STONE_COLOR.lightened(0.1))
		c.position = pos + Vector3(0, 2.1, 0)
		parent.add_child(c)

## Bake a shared material (cached by color so props share instances).
func _baked_mat(color: Color) -> StandardMaterial3D:
	var key := color.to_html()
	if not _mat_cache.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 0.9
		_mat_cache[key] = m
	return _mat_cache[key]

var _mat_cache: Dictionary = {}
