extends Node2D
## 화면 바로 바깥에 적을 만든다. 만든 적은 이 노드의 자식이 된다.
## 시간이 지날수록 더 자주, 더 빠른 적을 만들고, 1분부터는 플레이어를 둘러싸는 무리도 보낸다.

signal enemy_killed
signal boss_spawned

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const BOSS_SCENE := preload("res://scenes/boss.tscn")
const BOSS_TIME := 150.0  # 2:30. 남은 시간이 0:30일 때 등장한다.
const SPAWN_MARGIN := 40.0  # 화면 가장자리에서 얼마나 바깥에 만들지
const RAMP_DURATION := 180.0  # 이 시간에 걸쳐 시작값에서 끝값으로 바뀐다
const START_SPAWN_INTERVAL := 0.8
const END_SPAWN_INTERVAL := 0.12
const START_ENEMY_SPEED := 110.0
const END_ENEMY_SPEED := 205.0
const MAX_ALIVE := 250  # 성능을 위해 동시에 살아 있는 적 수를 제한한다
const RING_START_TIME := 60.0  # 이때부터 둘러싸는 무리가 온다
const RING_INTERVAL := 20.0
const RING_START_COUNT := 12
const RING_END_COUNT := 24
const RING_DISTANCE := 520.0  # 플레이어에서 이만큼 떨어진 원 위에 늘어선다. 화면 밖이 되도록 잡았다.

var _elapsed := 0.0
var _time_until_spawn := START_SPAWN_INTERVAL
var _next_ring_time := RING_START_TIME
var _boss_spawned := false


func _process(delta: float) -> void:
	_elapsed += delta
	_time_until_spawn -= delta
	if _time_until_spawn <= 0.0:
		_time_until_spawn += spawn_interval()
		spawn_enemy(random_point_outside_view())
	if _elapsed >= _next_ring_time:
		_next_ring_time += RING_INTERVAL
		spawn_ring()
	if not _boss_spawned and _elapsed >= BOSS_TIME:
		_boss_spawned = true
		spawn_boss()


func spawn_boss() -> void:
	# 보스는 적 수 제한과 상관없이 반드시 나온다
	var boss := BOSS_SCENE.instantiate()
	boss.position = random_point_outside_view()
	boss.died.connect(enemy_killed.emit)
	add_child(boss)
	boss_spawned.emit()


func difficulty() -> float:
	# 0(시작)에서 1(3분)까지 고르게 올라간다
	return clampf(_elapsed / RAMP_DURATION, 0.0, 1.0)


func spawn_interval() -> float:
	return lerpf(START_SPAWN_INTERVAL, END_SPAWN_INTERVAL, difficulty())


func enemy_speed() -> float:
	return lerpf(START_ENEMY_SPEED, END_ENEMY_SPEED, difficulty())


func spawn_ring() -> void:
	# 한 방향으로만 계속 도망치지 못하도록 사방에서 한꺼번에 온다
	var target := get_tree().get_first_node_in_group("player") as Node2D
	if target == null:
		return
	var count := roundi(lerpf(RING_START_COUNT, RING_END_COUNT, difficulty()))
	for i in count:
		spawn_enemy(target.global_position + Vector2.RIGHT.rotated(TAU * i / count) * RING_DISTANCE)


func spawn_enemy(at: Vector2) -> void:
	if get_tree().get_nodes_in_group("enemies").size() >= MAX_ALIVE:
		return
	var enemy := ENEMY_SCENE.instantiate()
	# 스포너는 원점에 있으므로 position이 곧 월드 좌표다
	enemy.position = at
	enemy.speed = enemy_speed()
	enemy.died.connect(enemy_killed.emit)
	add_child(enemy)


func view_rect() -> Rect2:
	return get_viewport().get_canvas_transform().affine_inverse() * get_viewport_rect()


func random_point_outside_view() -> Vector2:
	var rect := view_rect().grow(SPAWN_MARGIN)
	# 네 변 중 하나를 고르고, 그 변 위의 아무 지점에 만든다
	match randi() % 4:
		0:
			return Vector2(randf_range(rect.position.x, rect.end.x), rect.position.y)
		1:
			return Vector2(randf_range(rect.position.x, rect.end.x), rect.end.y)
		2:
			return Vector2(rect.position.x, randf_range(rect.position.y, rect.end.y))
		_:
			return Vector2(rect.end.x, randf_range(rect.position.y, rect.end.y))
