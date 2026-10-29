extends Control
## 화면 위에 그리는 체력바. 남은 비율만큼 채우고, 가운데에 숫자를 쓴다.

const BACK_COLOR := Color("1a1a1a")
const FILL_COLOR := Color("e5383b")
const BORDER_COLOR := Color("f1faee")
const TEXT_COLOR := Color("f1faee")
const FONT_SIZE := 14

var max_value := 100.0
var value := 100.0:
	set(new_value):
		value = clampf(new_value, 0.0, max_value)
		queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, BACK_COLOR)
	var fill := rect
	fill.size.x *= value / max_value
	draw_rect(fill, FILL_COLOR)
	draw_rect(rect, BORDER_COLOR, false, 2.0)

	var font := get_theme_default_font()
	var text := "체력 %d / %d" % [ceili(value), int(max_value)]
	var baseline := (size.y + font.get_ascent(FONT_SIZE) - font.get_descent(FONT_SIZE)) / 2.0
	draw_string(font, Vector2(0, baseline), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, FONT_SIZE, TEXT_COLOR)
