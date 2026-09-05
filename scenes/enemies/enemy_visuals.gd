extends Node3D
## V2 enemy visual builder: assembles a distinct primitive model per
## archetype on top of the shared Enemy scene. The generic body mesh is
## hidden; archetype-specific parts are created once per spawn and cleared
## on recycle. Idle/locomotion micro-animation per type.

## Built lazily per archetype id: id -> Array[Node] (parts parented under
## Visual root). Parts are pooled with the enemy itself.
static func build(visual_root: Node3D, archetype_id: String) -> void:
	if visual_root.has_meta("built_for") and visual_root.get_meta("built_for") == archetype_id:
		return
	_clear_parts(visual_root)
	visual_root.set_meta("built_for", archetype_id)
	match archetype_id:
		"basic_drone": _build_drone(visual_root)
		"fast_wisp": _build_wisp(visual_root)
		"tank_golem": _build_golem(visual_root)
		"shooter_turret": _build_turret(visual_root)
		"swarm_bat": _build_bat(visual_root)
		_: _build_drone(visual_root)

static func clear(visual_root: Node3D) -> void:
	visual_root.remove_meta("built_for")
	_clear_parts(visual_root)

static func _clear_parts(visual_root: Node3D) -> void:
	for child in visual_root.get_children():
		child.queue_free()

static func _mesh(parent: Node3D, mesh: Mesh, mat: StandardMaterial3D, pos: Vector3, rot_x: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	mi.rotation.x = rot_x
	mi.set_meta("base_y", pos.y)
	parent.add_child(mi)
	return mi

static func _mat(color: Color, emission: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.7
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	return m

# --- Basic Drone: hovering round bot, antenna, two side thrusters ---
static func _build_drone(v: Node3D) -> void:
	var body_col := Color(0.62, 0.67, 0.72)
	var accent := Color(0.95, 0.45, 0.25)
	var body_mat := _mat(body_col)
	var accent_mat := _mat(accent, 0.8)
	_sphere(v, body_mat, 0.5, Vector3(0, 0.55, 0))
	_mesh(v, SphereMesh.new(), accent_mat, Vector3(0, 0.55, 0)).scale = Vector3(0.28, 0.28, 0.28)
	# antennae
	var pole := CylinderMesh.new()
	pole.top_radius = 0.02
	pole.bottom_radius = 0.02
	pole.height = 0.35
	_mesh(v, pole, accent_mat, Vector3(-0.12, 1.0, 0))
	_mesh(v, pole, accent_mat, Vector3(0.12, 1.0, 0))
	# thruster nubs
	var nub := CylinderMesh.new()
	nub.top_radius = 0.09
	nub.bottom_radius = 0.09
	nub.height = 0.16
	_mesh(v, nub, accent_mat, Vector3(-0.42, 0.4, 0), PI / 2)
	_mesh(v, nub, accent_mat, Vector3(0.42, 0.4, 0), PI / 2)
	# hover skirt
	var skirt := CylinderMesh.new()
	skirt.top_radius = 0.3
	skirt.bottom_radius = 0.42
	skirt.height = 0.2
	_mesh(v, skirt, _mat(body_col.darkened(0.25)), Vector3(0, 0.16, 0))

# --- Fast Wisp: floating flame kite with glow trail nub ---
static func _build_wisp(v: Node3D) -> void:
	var flame := Color(0.98, 0.62, 0.32)
	var core_mat := _mat(flame, 1.6)
	var outer_mat := _mat(Color(1.0, 0.5, 0.2, 0.5), 0.6)
	outer_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# teardrop body: stretched sphere
	var body := SphereMesh.new()
	body.radius = 0.3
	body.height = 0.9
	_mesh(v, body, core_mat, Vector3(0, 0.6, 0))
	var outer := SphereMesh.new()
	outer.radius = 0.42
	outer.height = 1.1
	_mesh(v, outer, outer_mat, Vector3(0, 0.6, 0))
	# tail fin
	var fin := PrismMesh.new()
	fin.size = Vector3(0.16, 0.4, 0.16)
	_mesh(v, fin, core_mat, Vector3(0, 0.14, 0), PI)

# --- Tank Golem: stacked stones, heavy shoulders, glowing core crack ---
static func _build_golem(v: Node3D) -> void:
	var stone := Color(0.55, 0.43, 0.38)
	var dark := _mat(stone.darkened(0.2))
	var mid := _mat(stone)
	var crack := _mat(Color(1.0, 0.4, 0.15), 1.4)
	var box := BoxMesh.new()
	box.size = Vector3(1.1, 0.7, 0.8)
	_mesh(v, box, mid, Vector3(0, 0.35, 0))     # base slab
	var torso := BoxMesh.new()
	torso.size = Vector3(1.3, 0.9, 0.9)
	_mesh(v, torso, mid, Vector3(0, 1.05, 0))   # torso
	var head := BoxMesh.new()
	head.size = Vector3(0.55, 0.45, 0.5)
	_mesh(v, head, dark, Vector3(0, 1.7, 0.05)) # head
	var arm := BoxMesh.new()
	arm.size = Vector3(0.45, 0.9, 0.5)
	_mesh(v, arm, dark, Vector3(-0.85, 0.9, 0))
	_mesh(v, arm, dark, Vector3(0.85, 0.9, 0))
	# glowing crack strip on chest
	var crack_box := BoxMesh.new()
	crack_box.size = Vector3(0.14, 0.6, 0.05)
	_mesh(v, crack_box, crack, Vector3(0, 1.1, 0.47))

# --- Shooter Turret: tripod + rotating barrel head ---
static func _build_turret(v: Node3D) -> void:
	var metal := _mat(Color(0.75, 0.66, 0.5))
	var dark := _mat(Color(0.35, 0.3, 0.25))
	var barrel_col := Color(1.0, 0.75, 0.4)
	var leg := CylinderMesh.new()
	leg.top_radius = 0.05
	leg.bottom_radius = 0.05
	leg.height = 0.9
	for side in [[-0.4, 0.25], [0.4, 0.25], [0.0, -0.45]]:
		var leg_mi := _mesh(v, leg, dark, Vector3(side[0], 0.45, side[1]))
		leg_mi.rotation.x = 0.35 if side[1] < 0.0 else -0.25
	var base := CylinderMesh.new()
	base.top_radius = 0.45
	base.bottom_radius = 0.3
	base.height = 0.3
	_mesh(v, base, metal, Vector3(0, 0.95, 0))
	var head := SphereMesh.new()
	head.radius = 0.35
	head.height = 0.7
	_mesh(v, head, metal, Vector3(0, 1.3, 0))
	var barrel := CylinderMesh.new()
	barrel.top_radius = 0.09
	barrel.bottom_radius = 0.09
	barrel.height = 0.8
	var barrel_mi := _mesh(v, barrel, _mat(barrel_col, 0.5), Vector3(0, 1.32, -0.45), PI / 2)
	var tip := SphereMesh.new()
	tip.radius = 0.1
	tip.height = 0.2
	_mesh(v, tip, _mat(barrel_col, 1.5), Vector3(0, 1.32, -0.85))

# --- Swarm Bat: tiny body + two flapping wing planes ---
static func _build_bat(v: Node3D) -> void:
	var fur := _mat(Color(0.45, 0.32, 0.55))
	var wing := _mat(Color(0.35, 0.24, 0.45, 0.9))
	wing.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var body := SphereMesh.new()
	body.radius = 0.2
	body.height = 0.4
	_mesh(v, body, fur, Vector3(0, 0.45, 0))
	var eye := SphereMesh.new()
	eye.radius = 0.05
	eye.height = 0.1
	var eye_mat := _mat(Color(1, 0.3, 0.2), 2.0)
	_mesh(v, eye, eye_mat, Vector3(-0.07, 0.5, -0.16))
	_mesh(v, eye, eye_mat, Vector3(0.07, 0.5, -0.16))
	var wing_mesh := BoxMesh.new()
	wing_mesh.size = Vector3(0.5, 0.03, 0.3)
	var wl := _mesh(v, wing_mesh, wing, Vector3(-0.36, 0.5, 0))
	var wr := _mesh(v, wing_mesh, wing, Vector3(0.36, 0.5, 0))
	wl.name = "WingL"
	wr.name = "WingR"

# --- Sphere helper (drone body) ---
static func _sphere(v: Node3D, mat: StandardMaterial3D, radius: float, pos: Vector3) -> void:
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	_mesh(v, s, mat, pos)

## Per-frame micro-animation called by the enemy.
static func animate(visual_root: Node3D, archetype_id: String, time: float, seed_val: float) -> void:
	match archetype_id:
		"swarm_bat":
			var wl := visual_root.get_node_or_null("WingL")
			var wr := visual_root.get_node_or_null("WingR")
			if wl != null:
				var flap := sin(time * 14.0 + seed_val) * 0.6
				wl.rotation.z = flap
				wr.rotation.z = -flap
		"fast_wisp":
			if visual_root.get_child_count() > 1:
				var outer: MeshInstance3D = visual_root.get_child(1)
				var s := 1.0 + sin(time * 9.0 + seed_val) * 0.12
				outer.scale = Vector3(s, s, s)
		"basic_drone":
			for child in visual_root.get_children():
				if child is Node3D and child.has_meta("base_y"):
					child.position.y = child.get_meta("base_y") + sin(time * 5.0 + seed_val) * 0.03
