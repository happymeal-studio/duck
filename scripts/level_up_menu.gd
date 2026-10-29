extends Control
## 레벨업 강화 선택 창. 선택지 3개를 버튼으로 보여 주고, 클릭한 것을 알려 준다.
## 게임이 멈춘 동안에도 클릭을 받아야 하므로 항상 동작하게 둔다.

signal chosen(option: Dictionary)

const BUTTON_SIZE := Vector2(240, 120)

var _buttons: HBoxContainer


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var title := Label.new()
	title.text = "레벨 업! 강화를 하나 고르세요"
	title.add_theme_font_size_override("font_size", 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.anchor_left = 0.0
	title.anchor_right = 1.0
	title.anchor_top = 0.5
	title.anchor_bottom = 0.5
	title.offset_top = -140.0
	title.offset_bottom = -90.0
	add_child(title)

	_buttons = HBoxContainer.new()
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.add_theme_constant_override("separation", 24)
	_buttons.anchor_right = 1.0
	_buttons.anchor_top = 0.5
	_buttons.anchor_bottom = 0.5
	_buttons.offset_top = -60.0
	_buttons.offset_bottom = -60.0 + BUTTON_SIZE.y
	add_child(_buttons)


func open(options: Array) -> void:
	for old in _buttons.get_children():
		old.queue_free()
	for option in options:
		var button := Button.new()
		button.text = "%s\n\n%s" % [option.name, option.description]
		button.custom_minimum_size = BUTTON_SIZE
		button.add_theme_font_size_override("font_size", 20)
		button.add_theme_stylebox_override("normal", _button_style(Color("2b2d42"), Color("8d99ae")))
		button.add_theme_stylebox_override("hover", _button_style(Color("3d405b"), Color("ffd166")))
		button.add_theme_stylebox_override("pressed", _button_style(Color("4a4e69"), Color("ffd166")))
		button.pressed.connect(_on_pressed.bind(option))
		_buttons.add_child(button)
	show()


func _button_style(background: Color, border: Color) -> StyleBoxFlat:
	# 기본 버튼은 반투명이라 뒤의 게임 화면이 비친다. 불투명한 카드처럼 보이게 한다.
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	return style


func _on_pressed(option: Dictionary) -> void:
	hide()
	chosen.emit(option)
