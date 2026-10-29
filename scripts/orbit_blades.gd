extends Node2D
## 회전 칼날. 플레이어 주위를 돌며 닿은 적을 쓰러뜨린다. 플레이어의 자식으로 둔다.

const ORBIT_RADIUS := 72.0
const ORBIT_SPEED := 4.5  # 초당 회전 각도(라디안)
const BLADE_LENGTH := 14.0
const BLADE_WIDTH := 5.0
const HIT_RADIUS := 10.0
const BODY_COLOR := Color("d8e2dc")
const OUTLINE_COLOR := Color("2b2d42")

var blade_count := 1
var _angle := 0.0


func _process(delta: float) -> void:
	_angle = wrapf(_angle + ORBIT_SPEED * delta, 0.0, TAU)
	hit_enemies()
	queue_redraw()


func blade_offsets() -> Array[Vector2]:
	# 칼날이 여러 개면 원 위에 같은 간격으로 늘어놓는다
	var offsets: Array[Vector2] = []
	for i in blade_count:
		offsets.append(Vector2.RIGHT.rotated(_angle + TAU * i / blade_count) * ORBIT_RADIUS)
	return offsets


func hit_enemies() -> void:
	for offset in blade_offsets():
		var blade_position := global_position + offset
		for enemy in get_tree().get_nodes_in_group("enemies"):
			var reach: float = HIT_RADIUS + enemy.hit_radius()
			if blade_position.distance_squared_to(enemy.global_position) <= reach * reach:
				enemy.hit()


func _draw() -> void:
	for offset in blade_offsets():
		# 칼끝이 도는 방향을 향하도록 원의 접선 방향으로 눕힌다
		var forward := offset.normalized().orthogonal() * -1.0
		var side := offset.normalized()
		var outline := PackedVector2Array([
			offset + forward * (BLADE_LENGTH + 2.0), offset + side * (BLADE_WIDTH + 2.0),
			offset - forward * (BLADE_LENGTH + 2.0), offset - side * (BLADE_WIDTH + 2.0),
		])
		var body := PackedVector2Array([
			offset + forward * BLADE_LENGTH, offset + side * BLADE_WIDTH,
			offset - forward * BLADE_LENGTH, offset - side * BLADE_WIDTH,
		])
		draw_colored_polygon(outline, OUTLINE_COLOR)
		draw_colored_polygon(body, BODY_COLOR)
