extends Node2D
## 경험치 보석. 적이 쓰러진 자리에 떨어지는 노란 보석이다.

const SIZE := 7.0
const BODY_COLOR := Color("ffd166")
const OUTLINE_COLOR := Color("4a3a0a")

var experience := 1


func _draw() -> void:
	draw_colored_polygon(diamond(SIZE + 2.0), OUTLINE_COLOR)
	draw_colored_polygon(diamond(SIZE), BODY_COLOR)


func diamond(half: float) -> PackedVector2Array:
	# 세로로 조금 긴 마름모라 적(정마름모)보다 작고 보석처럼 보인다
	return PackedVector2Array([
		Vector2(0, -half * 1.3), Vector2(half, 0), Vector2(0, half * 1.3), Vector2(-half, 0),
	])
