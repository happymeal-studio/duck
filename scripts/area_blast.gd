extends Node2D
## 범위 폭발. 일정 간격으로 플레이어 주변을 터뜨려 반경 안의 적을 모두 쓰러뜨린다. 플레이어의 자식으로 둔다.

const BLAST_INTERVAL := 2.5
const BASE_RADIUS := 110.0
const EFFECT_DURATION := 0.3  # 터지는 고리가 퍼졌다 사라지는 시간
const EFFECT_COLOR := Color("ff9f1c")

var radius := BASE_RADIUS
var _time_until_blast := BLAST_INTERVAL
var _effect_time_left := 0.0


func _process(delta: float) -> void:
	_time_until_blast -= delta
	if _time_until_blast <= 0.0:
		_time_until_blast += BLAST_INTERVAL
		blast()
	if _effect_time_left > 0.0:
		_effect_time_left = maxf(_effect_time_left - delta, 0.0)
		queue_redraw()


func blast() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if global_position.distance_to(enemy.global_position) <= radius + enemy.hit_radius():
			enemy.hit()
	_effect_time_left = EFFECT_DURATION
	queue_redraw()


func _draw() -> void:
	if _effect_time_left <= 0.0:
		return
	# 고리가 반경 끝까지 퍼지면서 점점 투명해진다
	var progress := 1.0 - _effect_time_left / EFFECT_DURATION
	var fill := EFFECT_COLOR
	fill.a = 0.25 * (1.0 - progress)
	var ring := EFFECT_COLOR
	ring.a = 1.0 - progress
	draw_circle(Vector2.ZERO, radius * progress, fill)
	draw_arc(Vector2.ZERO, radius * progress, 0.0, TAU, 64, ring, 4.0)
