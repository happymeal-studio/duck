extends Node2D
## 한 판의 진행 상황을 기록한다.

const GAME_DURATION := 180.0  # 3분
const ExperienceBar := preload("res://scripts/experience_bar.gd")
const LevelUpMenu := preload("res://scripts/level_up_menu.gd")
const OrbitBlades := preload("res://scripts/orbit_blades.gd")
const AreaBlast := preload("res://scripts/area_blast.gd")
const SoundEffects := preload("res://scripts/sound_effects.gd")
const BLAST_RADIUS_STEP := 20.0
# 레벨업 때 고를 수 있는 강화. 효과는 _apply_upgrade에서 적용한다.
const UPGRADE_OPTIONS := [
	{"id": "attack_speed", "name": "공격 속도", "description": "발사 간격 15% 감소"},
	{"id": "move_speed", "name": "이동 속도", "description": "이동 속도 10% 증가"},
	{"id": "projectile_count", "name": "투사체 수", "description": "한 번에 1발 더 발사"},
	{"id": "max_health", "name": "최대 체력", "description": "최대 체력 +20, 즉시 회복"},
	{"id": "orbit_blade", "name": "회전 칼날", "description": "주위를 도는 칼날 1개 추가"},
	{"id": "area_blast", "name": "범위 폭발", "description": "2.5초마다 주변 폭발\n(다시 고르면 범위 증가)"},
]
const MIN_FIRE_INTERVAL := 0.25
const BEST_RECORD_PATH := "user://best_record.cfg"  # 게임을 껐다 켜도 남도록 사용자 데이터 폴더에 저장한다

var kill_count := 0
var time_left := GAME_DURATION
var _pending_level_ups := 0
var _level_up_menu: Control
var _pause_button: Button
var _pause_overlay: Control

@onready var _kill_label: Label = $HUD/KillCount
@onready var _health_bar: Control = $HUD/HealthBar
@onready var _time_label: Label = $HUD/TimeLeft
@onready var _result: Control = $HUD/Result


func _ready() -> void:
	# 창 제목도 한글 게임 이름으로 보이게 한다 (프로젝트 이름 vampsulike는 그대로 둔다)
	DisplayServer.window_set_title("딥다운")
	_fit_window_to_screen()
	_add_sound_effects()
	_add_gem_container()
	_add_experience_bar()
	_add_level_up_menu()
	_add_pause_ui()
	$Enemies.boss_spawned.connect(_on_boss_spawned)
	$Enemies.enemy_killed.connect(_on_enemy_killed)
	_update_kill_label()
	$Player.health_changed.connect(_on_health_changed)
	_on_health_changed($Player.health)
	_update_time_label()
	# 게임이 멈춘 뒤에도 결과 화면은 클릭을 받아야 한다
	_result.process_mode = Node.PROCESS_MODE_ALWAYS
	$HUD/Result/Dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 커진 공주가 결과 글자 뒤로 비치지 않도록 배경을 더 어둡게 덮는다
	$HUD/Result/Dim.color.a = 0.85
	_result.gui_input.connect(_on_result_input)


func _process(delta: float) -> void:
	time_left = maxf(time_left - delta, 0.0)
	_update_time_label()
	if time_left <= 0.0:
		win()


func win() -> void:
	show_result("승리!", "3분을 버텼어요")


func lose() -> void:
	show_result("패배", "체력이 모두 떨어졌어요")


func show_result(title: String, subtitle: String) -> void:
	if get_tree().paused:
		return  # 같은 순간에 승리와 패배가 겹쳐도 먼저 난 결과만 보여 준다
	$HUD/Result/Title.text = title
	$HUD/Result/Subtitle.text = subtitle
	_pause_button.hide()
	var survived := floori(GAME_DURATION - time_left)
	var level: int = $Player.level
	var best := load_best_record()
	var best_kills: int = best.kills
	var best_level: int = best.level
	save_best_record(maxi(kill_count, best_kills), maxi(level, best_level))
	$HUD/Result/Stats.text = "생존 시간 %s\n처치 %d%s · 레벨 %d%s\n이전 최고  처치 %d · 레벨 %d\n\n클릭하면 다시 시작" % [
		format_time(survived),
		kill_count, "  (새 기록!)" if kill_count > best_kills else "",
		level, "  (새 기록!)" if level > best_level else "",
		best_kills, best_level]
	_result.show()
	# 게임 화면 전체를 멈춘다. 결과 화면은 그려진 채로 남는다.
	get_tree().paused = true


func _on_result_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		restart()


func restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_enemy_killed() -> void:
	kill_count += 1
	_update_kill_label()


func _update_kill_label() -> void:
	_kill_label.text = "처치 %d" % kill_count


func _on_health_changed(health: float) -> void:
	_health_bar.max_value = $Player.max_health
	_health_bar.value = health
	if health <= 0.0:
		lose()


func _update_time_label() -> void:
	# 0.1초가 남아도 0:00이 아니라 0:01로 보이도록 올림한다
	_time_label.text = format_time(ceili(time_left))


func format_time(seconds: int) -> String:
	return "%d:%02d" % [floori(seconds / 60.0), seconds % 60]


func _add_gem_container() -> void:
	# 보석은 플레이어와 적보다 아래에 그려지도록 Player 바로 앞에 끼워 넣는다
	var gems := Node2D.new()
	gems.name = "Gems"
	gems.add_to_group("gems")
	add_child(gems)
	move_child(gems, $Player.get_index())


func _add_experience_bar() -> void:
	# 화면 아래쪽 가로 전체에 깐다. 결과 화면보다 아래에 그려지도록 Result 앞에 둔다.
	var bar := ExperienceBar.new()
	bar.name = "ExperienceBar"
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_left = 16.0
	bar.offset_right = -16.0
	bar.offset_top = -36.0
	bar.offset_bottom = -16.0
	$HUD.add_child(bar)
	$HUD.move_child(bar, _result.get_index())
	var player := $Player
	bar.set_progress(player.level, player.experience, player.experience_to_next_level())
	player.experience_changed.connect(bar.set_progress)


func _add_level_up_menu() -> void:
	_level_up_menu = LevelUpMenu.new()
	_level_up_menu.name = "LevelUpMenu"
	$HUD.add_child(_level_up_menu)
	$HUD.move_child(_level_up_menu, _result.get_index())
	_level_up_menu.chosen.connect(_on_upgrade_chosen)
	$Player.leveled_up.connect(_on_leveled_up)


func _on_leveled_up(_level: int) -> void:
	# 보석 하나로 두 레벨이 오를 수도 있으니 몇 번 골라야 하는지 세어 둔다
	_pending_level_ups += 1
	if not _level_up_menu.visible:
		_open_level_up_menu()


func _open_level_up_menu() -> void:
	var options := UPGRADE_OPTIONS.duplicate()
	options.shuffle()
	_level_up_menu.open(options.slice(0, 3))
	_pause_button.disabled = true  # 강화를 고르는 동안에는 일시정지를 누를 수 없다
	get_tree().paused = true


func _on_upgrade_chosen(option: Dictionary) -> void:
	_apply_upgrade(option.id)
	_pending_level_ups -= 1
	if _pending_level_ups > 0:
		_open_level_up_menu()
	else:
		_pause_button.disabled = false
		get_tree().paused = false


func _apply_upgrade(id: String) -> void:
	var player := $Player
	var gun := $Player/AutoGun
	match id:
		"attack_speed":
			gun.fire_interval = maxf(gun.fire_interval * 0.85, MIN_FIRE_INTERVAL)
		"move_speed":
			player.speed *= 1.1
		"projectile_count":
			gun.projectile_count += 1
		"max_health":
			player.increase_max_health(20.0)
		"orbit_blade":
			var blades := player.get_node_or_null("OrbitBlades")
			if blades == null:
				blades = OrbitBlades.new()
				blades.name = "OrbitBlades"
				player.add_child(blades)
			else:
				blades.blade_count += 1
		"area_blast":
			var blast := player.get_node_or_null("AreaBlast")
			if blast == null:
				blast = AreaBlast.new()
				blast.name = "AreaBlast"
				blast.show_behind_parent = true  # 폭발 고리가 플레이어를 가리지 않게 한다
				player.add_child(blast)
			else:
				blast.radius += BLAST_RADIUS_STEP


func _add_sound_effects() -> void:
	var sfx := SoundEffects.new()
	sfx.name = "SoundEffects"
	add_child(sfx)


func _on_boss_spawned() -> void:
	# 화면 가운데 위쪽에 3초 동안 알림을 띄운다
	var notice := Label.new()
	notice.text = "보스 등장!"
	notice.add_theme_font_size_override("font_size", 40)
	notice.add_theme_color_override("font_color", Color("f48c06"))
	notice.add_theme_color_override("font_outline_color", Color("1a1a1a"))
	notice.add_theme_constant_override("outline_size", 8)
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.set_anchors_preset(Control.PRESET_TOP_WIDE)
	notice.offset_top = 70.0
	notice.offset_bottom = 120.0
	$HUD.add_child(notice)
	$HUD.move_child(notice, _result.get_index())
	get_tree().create_timer(3.0, false).timeout.connect(notice.queue_free)


func _fit_window_to_screen() -> void:
	# 레티나 화면(배율 2)에서는 1280x720 창이 절반 크기로 보인다.
	# 게임 화면 기준(1280x720)은 그대로 두고, 창만 화면 배율만큼 키워 화면 가운데에 둔다.
	var window := get_window()
	if window.is_embedded() or DisplayServer.get_name() == "headless":
		return
	var screen := window.current_screen
	var screen_scale := DisplayServer.screen_get_scale(screen)
	var usable := DisplayServer.screen_get_usable_rect(screen)
	var base := Vector2(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"))
	# 화면보다 커지지 않도록 쓸 수 있는 영역의 90% 안으로 맞춘다
	var fit := minf(screen_scale, minf(usable.size.x * 0.9 / base.x, usable.size.y * 0.9 / base.y))
	var size := Vector2i(base * maxf(fit, 1.0))
	if window.size == size:
		return
	window.size = size
	window.position = usable.position + (usable.size - size) / 2


## 저장된 최고 기록. 처음이면 0으로 시작한다.
func load_best_record() -> Dictionary:
	var config := ConfigFile.new()
	config.load(BEST_RECORD_PATH)  # 파일이 없으면 실패하고 아래 기본값을 쓴다
	return {
		"kills": int(config.get_value("best", "kills", 0)),
		"level": int(config.get_value("best", "level", 0)),
	}


func save_best_record(kills: int, level: int) -> void:
	var config := ConfigFile.new()
	config.set_value("best", "kills", kills)
	config.set_value("best", "level", level)
	config.save(BEST_RECORD_PATH)


func _add_pause_ui() -> void:
	# 멈췄을 때 화면을 덮는 안내. 결과 화면·레벨업 창보다 아래에 둔다.
	_pause_overlay = Control.new()
	_pause_overlay.name = "PauseOverlay"
	_pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pause_overlay.hide()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pause_overlay.add_child(dim)
	var label := Label.new()
	label.text = "일시정지\n\n오른쪽 위 \"계속하기\"를 누르면 이어서 해요"
	label.add_theme_font_size_override("font_size", 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.add_child(label)
	$HUD.add_child(_pause_overlay)
	$HUD.move_child(_pause_overlay, _result.get_index())

	# 화면 오른쪽 위 버튼. 게임이 멈춘 동안에도 눌러야 하므로 항상 동작하게 둔다.
	_pause_button = Button.new()
	_pause_button.name = "PauseButton"
	_pause_button.text = "일시정지"
	_pause_button.process_mode = Node.PROCESS_MODE_ALWAYS
	_pause_button.focus_mode = Control.FOCUS_NONE  # 버튼이 키보드 입력을 가져가지 않게 한다
	_pause_button.add_theme_font_size_override("font_size", 20)
	_pause_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_pause_button.offset_left = -136.0
	_pause_button.offset_right = -16.0
	_pause_button.offset_top = 16.0
	_pause_button.offset_bottom = 56.0
	_pause_button.pressed.connect(toggle_pause)
	$HUD.add_child(_pause_button)
	$HUD.move_child(_pause_button, _result.get_index())


func toggle_pause() -> void:
	# 레벨업 창이나 결과 화면 때문에 멈춘 동안에는 일시정지 버튼이 끼어들지 않는다
	if _level_up_menu.visible or _result.visible:
		return
	var pausing := not _pause_overlay.visible
	_pause_overlay.visible = pausing
	_pause_button.text = "계속하기" if pausing else "일시정지"
	get_tree().paused = pausing
	$SoundEffects/Bgm.stream_paused = pausing
