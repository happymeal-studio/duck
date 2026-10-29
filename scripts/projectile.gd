extends Node2D
## 자동 공격 투사체. 정해진 방향으로 곧게 날아가다가 적에 맞거나 수명이 다하면 사라진다.

const RADIUS := 5.0
const COLOR := Color("f1faee")
const SPEED := 480.0
const LIFETIME := 1.5

var direction := Vector2.RIGHT
var _age := 0.0


func _process(delta: float) -> void:
	position += direction * SPEED * delta
	if hit_enemy():
		return
	_age += delta
	if _age >= LIFETIME:
		queue_free()


func hit_enemy() -> bool:
	# 원과 원이 겹치면 맞은 것으로 본다. 한 발은 적 하나만 쓰러뜨린다.
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var reach: float = RADIUS + enemy.hit_radius()
		if global_position.distance_squared_to(enemy.global_position) <= reach * reach:
			enemy.hit()
			queue_free()
			return true
	return false


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, COLOR)
