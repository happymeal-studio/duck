extends Node2D
## 플레이어. 공주 스프라이트 시트로 서 있기·걷기 애니메이션을 보여 주고, WASD 또는 방향키로 8방향 이동한다.

const RADIUS := 31.0  # 적과 부딪히는 판정 크기. 줄인 그림의 몸통 폭에 맞췄다.
# hero/manifest.json 의 값과 같아야 한다: 칸 256x256, 0번 줄 idle 4컷 4fps, 1번 줄 walk 4컷 8fps
const SHEET := preload("res://hero/sprite-sheet-alpha.png")
const CELL_SIZE := Vector2(256, 256)
const ANIMATIONS := {
	"idle": {"row": 0, "frames": 4, "fps": 4.0},
	"walk": {"row": 1, "frames": 4, "fps": 8.0},
}
const SPRITE_SCALE := 0.6  # 키 약 200px 그림을 약 125px로 줄인다
const BASE_SPEED := 200.0
const BASE_MAX_HEALTH := 100.0
const CONTACT_DAMAGE := 25.0  # 한 번 맞을 때 닿아 있는 적 한 마리당 피해
const INVULNERABLE_TIME := 0.8  # 맞은 뒤 다시 맞지 않는 시간
const BLINK_INTERVAL := 0.1
const PICKUP_RADIUS := 60.0  # 보석을 줍는 거리
const MAGNET_RADIUS := 140.0  # 이 안의 보석은 플레이어 쪽으로 끌려온다
const MAGNET_SPEED := 450.0

signal health_changed(health: float)
signal experience_changed(level: int, experience: int, needed: int)
signal leveled_up(level: int)

var speed := BASE_SPEED
var max_health := BASE_MAX_HEALTH
var health := max_health
var level := 1
var experience := 0
var _invulnerable_time_left := 0.0
var _sprite: AnimatedSprite2D


func _ready() -> void:
	# 적이 쫓아갈 대상을 찾을 수 있도록 그룹에 넣는다
	add_to_group("player")
	_sprite = build_sprite()
	add_child(_sprite)
	# 회전 칼날 같은 무기가 그림 위로 지나가도록 맨 아래에 그린다
	move_child(_sprite, 0)


func build_sprite() -> AnimatedSprite2D:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for animation_name in ANIMATIONS:
		var info: Dictionary = ANIMATIONS[animation_name]
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, info.fps)
		frames.set_animation_loop(animation_name, true)
		for i in info.frames:
			var cell := AtlasTexture.new()
			cell.atlas = SHEET
			cell.region = Rect2(Vector2(i, info.row) * CELL_SIZE, CELL_SIZE)
			frames.add_frame(animation_name, cell)
	var sprite := AnimatedSprite2D.new()
	sprite.name = "Sprite"
	sprite.sprite_frames = frames
	sprite.scale = Vector2.ONE * SPRITE_SCALE
	sprite.play("idle")
	return sprite


func _process(delta: float) -> void:
	var direction := get_move_direction()
	position += direction * speed * delta
	update_animation(direction)
	update_invulnerability(delta)
	take_contact_damage()
	collect_gems(delta)


func update_animation(direction: Vector2) -> void:
	_sprite.play("idle" if direction == Vector2.ZERO else "walk")
	# 그림은 오른쪽을 보고 있으니 왼쪽으로 갈 때만 뒤집는다. 위아래로만 갈 때는 보던 쪽을 유지한다.
	if direction.x < 0.0:
		_sprite.flip_h = true
	elif direction.x > 0.0:
		_sprite.flip_h = false


func update_invulnerability(delta: float) -> void:
	if _invulnerable_time_left <= 0.0:
		return
	_invulnerable_time_left = maxf(_invulnerable_time_left - delta, 0.0)
	# 무적인 동안 0.1초마다 깜빡이고, 끝나면 다시 보이게 한다
	var blink_on := fmod(_invulnerable_time_left, BLINK_INTERVAL * 2.0) < BLINK_INTERVAL
	# 그림만 깜빡이고 칼날 같은 다른 자식은 그대로 보인다
	_sprite.modulate.a = 0.25 if blink_on and _invulnerable_time_left > 0.0 else 1.0


func is_invulnerable() -> bool:
	return _invulnerable_time_left > 0.0


func take_contact_damage() -> void:
	if is_invulnerable() or health <= 0.0:
		return
	var touching := touching_enemy_weight()
	if touching == 0.0:
		return
	health = maxf(health - touching * CONTACT_DAMAGE, 0.0)
	_invulnerable_time_left = INVULNERABLE_TIME
	get_tree().call_group("sfx", "play", "hit")
	health_changed.emit(health)


func collect_gems(delta: float) -> void:
	var container := get_tree().get_first_node_in_group("gems")
	if container == null:
		return
	for gem in container.get_children():
		if gem.is_queued_for_deletion():
			continue
		var distance := global_position.distance_to(gem.global_position)
		if distance <= PICKUP_RADIUS:
			gain_experience(gem.experience)
			get_tree().call_group("sfx", "play", "gem")
			gem.queue_free()
		elif distance <= MAGNET_RADIUS:
			gem.global_position = gem.global_position.move_toward(global_position, MAGNET_SPEED * delta)


func increase_max_health(amount: float) -> void:
	# 늘어난 만큼 바로 회복도 시켜 준다
	max_health += amount
	health += amount
	health_changed.emit(health)


func experience_to_next_level() -> int:
	# 레벨 1→2는 3개, 이후 레벨마다 3개씩 더 필요하다
	return 3 + 3 * (level - 1)


func gain_experience(amount: int) -> void:
	experience += amount
	while experience >= experience_to_next_level():
		experience -= experience_to_next_level()
		level += 1
		get_tree().call_group("sfx", "play", "level_up")
		leveled_up.emit(level)
	experience_changed.emit(level, experience, experience_to_next_level())


func touching_enemy_weight() -> float:
	# 보스처럼 더 아프게 하는 적은 일반 적 여러 마리만큼 센다
	var weight := 0.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var reach: float = RADIUS + enemy.hit_radius()
		if global_position.distance_squared_to(enemy.global_position) <= reach * reach:
			weight += enemy.contact_weight
	return weight


func get_move_direction() -> Vector2:
	var direction := Vector2.ZERO
	if is_any_key_pressed([KEY_A, KEY_LEFT]):
		direction.x -= 1.0
	if is_any_key_pressed([KEY_D, KEY_RIGHT]):
		direction.x += 1.0
	if is_any_key_pressed([KEY_W, KEY_UP]):
		direction.y -= 1.0
	if is_any_key_pressed([KEY_S, KEY_DOWN]):
		direction.y += 1.0
	# 대각선도 같은 속도가 되도록 길이를 1로 맞춘다
	return direction.normalized()


func is_any_key_pressed(keys: Array) -> bool:
	# 물리 키 기준이라 한글 입력 상태에서도 WASD가 동작한다
	for key in keys:
		if Input.is_physical_key_pressed(key):
			return true
	return false

