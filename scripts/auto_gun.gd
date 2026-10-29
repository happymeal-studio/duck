extends Node2D
## 자동 공격. 일정 간격으로 가장 가까운 적을 향해 투사체를 쏜다. 플레이어의 자식으로 둔다.

const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")
const BASE_FIRE_INTERVAL := 1.0
const SPREAD_ANGLE := deg_to_rad(12.0)  # 여러 발을 쏠 때 발 사이 각도

var fire_interval := BASE_FIRE_INTERVAL
var projectile_count := 1

var _time_until_fire := BASE_FIRE_INTERVAL


func _process(delta: float) -> void:
	_time_until_fire -= delta
	if _time_until_fire > 0.0:
		return
	var target := find_nearest_enemy()
	if target == null:
		return  # 적이 없으면 쏘지 않고, 적이 나타나는 즉시 쏜다
	_time_until_fire = fire_interval
	fire_at(target)
	get_tree().call_group("sfx", "play", "shoot")


func find_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var nearest_distance := INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var distance := global_position.distance_squared_to(enemy.global_position)
		if distance < nearest_distance:
			nearest = enemy
			nearest_distance = distance
	return nearest


func fire_at(target: Node2D) -> void:
	var aim := global_position.direction_to(target.global_position)
	# 여러 발이면 가운데를 겨냥 방향에 맞추고 양옆으로 부채꼴로 퍼뜨린다
	var first_angle := -SPREAD_ANGLE * (projectile_count - 1) / 2.0
	for i in projectile_count:
		spawn_projectile(aim.rotated(first_angle + SPREAD_ANGLE * i))


func spawn_projectile(direction: Vector2) -> void:
	var projectile := PROJECTILE_SCENE.instantiate()
	projectile.direction = direction
	# 투사체는 플레이어를 따라 움직이면 안 되므로 따로 모아 두는 노드에 넣는다
	var container := get_tree().get_first_node_in_group("projectiles")
	container.add_child(projectile)
	projectile.global_position = global_position
