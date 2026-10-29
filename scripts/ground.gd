extends Node2D
## 끝없는 평원 배경. 화면에 보이는 영역만 타일로 다시 그려서 어디로 가도 끊기지 않는다.

const TILE_SIZE := 64.0
const COLOR_A := Color("1d3a22")
const COLOR_B := Color("21402a")
const GRASS_COLOR := Color("2d5a35")


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var view_rect := get_viewport().get_canvas_transform().affine_inverse() * get_viewport_rect()
	var first := (view_rect.position / TILE_SIZE).floor()
	var last := (view_rect.end / TILE_SIZE).ceil()
	for x in range(int(first.x), int(last.x)):
		for y in range(int(first.y), int(last.y)):
			var origin := Vector2(x, y) * TILE_SIZE
			var color := COLOR_A if posmod(x + y, 2) == 0 else COLOR_B
			draw_rect(Rect2(origin, Vector2(TILE_SIZE, TILE_SIZE)), color)
			draw_grass(origin, hash(Vector2i(x, y)))


func draw_grass(origin: Vector2, tile_hash: int) -> void:
	# 타일 좌표로 정한 값이라 같은 자리에는 항상 같은 풀이 난다
	if tile_hash % 3 != 0:
		return
	var base := origin + Vector2(8 + (tile_hash >> 4) % 48, 16 + (tile_hash >> 10) % 40)
	draw_line(base, base + Vector2(-3, -7), GRASS_COLOR, 2.0)
	draw_line(base, base + Vector2(0, -9), GRASS_COLOR, 2.0)
	draw_line(base, base + Vector2(3, -7), GRASS_COLOR, 2.0)
