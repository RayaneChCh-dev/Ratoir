class_name ProgressBar3D
extends Node3D
## Barre de progression 3D toujours face à la caméra et dessinée par-dessus le décor.

const WIDTH := 1.0
const HEIGHT := 0.14

var _fill: MeshInstance3D


func _ready() -> void:
	add_child(_make_quad(Color(0.1, 0.1, 0.12, 0.85), WIDTH + 0.06, HEIGHT + 0.06, 0))
	_fill = _make_quad(Color(0.35, 0.9, 0.35), WIDTH, HEIGHT, 1)
	add_child(_fill)
	set_value(0.0)
	hide()


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera:
		global_basis = camera.global_basis


func set_value(value: float) -> void:
	value = clampf(value, 0.001, 1.0)
	_fill.scale.x = value
	_fill.position.x = -WIDTH * (1.0 - value) * 0.5


func _make_quad(color: Color, width: float, height: float, priority: int) -> MeshInstance3D:
	var mesh := QuadMesh.new()
	mesh.size = Vector2(width, height)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	material.no_depth_test = true
	material.render_priority = priority
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance
