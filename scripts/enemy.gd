extends Node2D
## 적. 붉은 마름모로 그려서 둥근 플레이어와 한눈에 구분되게 하고, 플레이어를 향해 다가간다.

signal died

const GEM_SCENE := preload("res://scenes/gem.tscn")
const BASE_SPEED := 110.0

var speed := BASE_SPEED
var size := 14.0  # 마름모 중심에서 꼭짓점까지 거리. 맞는 판정 크기로도 쓴다.
var body_color := Color("e5383b")
var outline_color := Color("3a0b0c")
var contact_weight := 1.0  # 닿았을 때 일반 적 몇 마리만큼 아프게 하는지
var gem_drop_count := 1
var _target: Node2D


func _ready() -> void:
	add_to_group("enemies")
	_target = get_tree().get_first_node_in_group("player")


func _process(delta: float) -> void:
	if _target == null:
		return
	global_position = global_position.move_toward(_target.global_position, speed * delta)


func hit_radius() -> float:
	return size


## 무기에 맞았을 때 부른다. 일반 적은 한 번에 쓰러진다.
func hit() -> void:
	die()


func die() -> void:
	# 같은 프레임에 두 번 맞아도 한 번만 처리되도록 그룹에서 바로 빼고, 이미 빠졌으면 무시한다
	if not is_in_group("enemies"):
		return
	remove_from_group("enemies")
	died.emit()
	get_tree().call_group("sfx", "play", "enemy_hit")
	drop_gem()
	queue_free()


func drop_gem() -> void:
	var container := get_tree().get_first_node_in_group("gems")
	if container == null:
		return
	for i in gem_drop_count:
		var gem := GEM_SCENE.instantiate()
		container.add_child(gem)
		# 여러 개면 쓰러진 자리 주변에 흩뿌린다
		var scatter := Vector2.ZERO if gem_drop_count == 1 else Vector2.RIGHT.rotated(randf() * TAU) * randf_range(10.0, size * 1.5)
		gem.global_position = global_position + scatter


func _draw() -> void:
	draw_colored_polygon(diamond(size + 2.5), outline_color)
	draw_colored_polygon(diamond(size), body_color)


func diamond(half: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0, -half), Vector2(half, 0), Vector2(0, half), Vector2(-half, 0),
	])
