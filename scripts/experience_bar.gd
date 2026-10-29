extends Control
## 화면 아래쪽 경험치 바. 다음 레벨까지 모은 비율만큼 채우고, 가운데에 레벨과 숫자를 쓴다.

const BACK_COLOR := Color("1a1a1a")
const FILL_COLOR := Color("ffd166")
const BORDER_COLOR := Color("f1faee")
const TEXT_COLOR := Color("f1faee")
const TEXT_OUTLINE_COLOR := Color("1a1a1a")
const FONT_SIZE := 14

var level := 1
var experience := 0
var needed := 1


func set_progress(new_level: int, new_experience: int, new_needed: int) -> void:
	level = new_level
	experience = new_experience
	needed = new_needed
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, BACK_COLOR)
	var fill := rect
	fill.size.x *= float(experience) / needed
	draw_rect(fill, FILL_COLOR)
	draw_rect(rect, BORDER_COLOR, false, 2.0)

	var font := get_theme_default_font()
	var text := "레벨 %d   경험치 %d / %d" % [level, experience, needed]
	var baseline := (size.y + font.get_ascent(FONT_SIZE) - font.get_descent(FONT_SIZE)) / 2.0
	# 노란 막대 위에서도 읽히도록 글자에 어두운 테두리를 두른다
	draw_string_outline(font, Vector2(0, baseline), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, FONT_SIZE, 3, TEXT_OUTLINE_COLOR)
	draw_string(font, Vector2(0, baseline), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, FONT_SIZE, TEXT_COLOR)
