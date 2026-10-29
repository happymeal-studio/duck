extends "res://scripts/enemy.gd"
## 보스. 일반 적보다 훨씬 크고 단단하며, 머리 위에 남은 체력을 보여 준다.
## 쓰러지면 보석을 한꺼번에 많이 떨어뜨린다.

const MAX_HEALTH := 40
const HIT_COOLDOWN := 0.1  # 칼날처럼 계속 닿는 무기에 한순간에 녹지 않도록 맞는 간격을 둔다
const BAR_WIDTH := 80.0
const BAR_HEIGHT := 8.0

var health := MAX_HEALTH
var _hit_cooldown_left := 0.0


func _init() -> void:
	speed = 150.0
	size = 40.0
	body_color = Color("9d0208")
	outline_color = Color("f48c06")
	contact_weight = 2.0
	gem_drop_count = 15


func _process(delta: float) -> void:
	super(delta)
	_hit_cooldown_left = maxf(_hit_cooldown_left - delta, 0.0)


func hit() -> void:
	if _hit_cooldown_left > 0.0:
		return
	_hit_cooldown_left = HIT_COOLDOWN
	health -= 1
	queue_redraw()
	if health <= 0:
		die()
	else:
		# 쓰러지지 않은 타격에도 맞는 소리를 낸다. 쓰러질 때는 die()가 낸다.
		get_tree().call_group("sfx", "play", "enemy_hit")


func _draw() -> void:
	super()
	# 머리 위 체력바
	var bar := Rect2(Vector2(-BAR_WIDTH / 2.0, -size - 20.0), Vector2(BAR_WIDTH, BAR_HEIGHT))
	draw_rect(bar, Color("1a1a1a"))
	var fill := bar
	fill.size.x *= float(health) / MAX_HEALTH
	draw_rect(fill, Color("f48c06"))
	draw_rect(bar, Color("f1faee"), false, 1.5)
