extends Node2D

# === CONFIGURAÇÕES ===
const SCREEN_W := 720.0
const SCREEN_H := 1280.0
const PLAYER_SPEED := 380.0
const ATTACK_COOLDOWN := 0.35
const JOYSTICK_RADIUS := 90.0
const JOYSTICK_DEADZONE := 0.18

# === ESTADO ===
var player_pos := Vector2(360, 980)
var player_vel := Vector2.ZERO
var hp := 100
var crystals := 0
var attack_cd := 0.0
var enemies: Array[Dictionary] = []
var projectiles: Array[Dictionary] = []

# Joystick
var joystick_center := Vector2(140, 1120)
var joystick_touch_id := -1
var joystick_vector := Vector2.ZERO

# Botão de ataque
var attack_btn_center := Vector2(580, 1120)
var attack_btn_radius := 70.0

var font: Font

func _ready() -> void:
	font = ThemeDB.fallback_font
	_spawn_enemies()
	queue_redraw()

func _spawn_enemies() -> void:
	enemies.clear()
	for i in 4:
		enemies.append({
			"pos": Vector2(randf_range(100, 620), randf_range(220, 700)),
			"hp": 30,
			"speed": randf_range(40, 90)
		})

func _process(delta: float) -> void:
	attack_cd = maxf(0.0, attack_cd - delta)

	# Movimento
	var move_dir := joystick_vector
	if move_dir.length() < JOYSTICK_DEADZONE:
		move_dir = Vector2.ZERO
	else:
		move_dir = move_dir.normalized()

	# Teclado (para testes no editor)
	move_dir.x += Input.get_axis("move_left", "move_right")
	move_dir.y += Input.get_axis("move_up", "move_down")
	if move_dir.length() > 1.0:
		move_dir = move_dir.normalized()

	player_vel = move_dir * PLAYER_SPEED
	player_pos += player_vel * delta
	player_pos.x = clampf(player_pos.x, 50, SCREEN_W - 50)
	player_pos.y = clampf(player_pos.y, 180, SCREEN_H - 220)

	# Atualiza inimigos
	for e in enemies:
		var dir = (player_pos - e.pos).normalized()
		e.pos += dir * e.speed * delta

	# Atualiza projéteis
	for p in projectiles:
		p.pos += p.vel * delta
	projectiles = projectiles.filter(func(p): return p.pos.y > 40 and p.pos.y < SCREEN_H)

	# Colisão projétil x inimigo
	for i in range(enemies.size() - 1, -1, -1):
		var e = enemies[i]
		for j in range(projectiles.size() - 1, -1, -1):
			if e.pos.distance_to(projectiles[j].pos) < 40:
				e.hp -= 15
				projectiles.remove_at(j)
				if e.hp <= 0:
					crystals += 1
					enemies.remove_at(i)
				break

	if enemies.is_empty():
		_spawn_enemies()

	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)
	elif event is InputEventMouseButton and event.pressed:
		# Clique no botão de ataque (desktop)
		if event.position.distance_to(attack_btn_center) < attack_btn_radius:
			_try_attack()

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		# Joystick
		if event.position.distance_to(joystick_center) < JOYSTICK_RADIUS * 1.6:
			joystick_touch_id = event.index
			_update_joystick(event.position)
		# Ataque
		elif event.position.distance_to(attack_btn_center) < attack_btn_radius * 1.3:
			_try_attack()
	else:
		if event.index == joystick_touch_id:
			joystick_touch_id = -1
			joystick_vector = Vector2.ZERO

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == joystick_touch_id:
		_update_joystick(event.position)

func _update_joystick(pos: Vector2) -> void:
	var offset = pos - joystick_center
	if offset.length() > JOYSTICK_RADIUS:
		offset = offset.normalized() * JOYSTICK_RADIUS
	joystick_vector = offset / JOYSTICK_RADIUS

func _try_attack() -> void:
	if attack_cd > 0.0:
		return
	attack_cd = ATTACK_COOLDOWN
	var dir = Vector2(0, -1)
	if player_vel.length() > 10:
		dir = player_vel.normalized()
	projectiles.append({
		"pos": player_pos + dir * 40,
		"vel": dir * 780
	})

func _draw() -> void:
	# Fundo
	draw_rect(Rect2(0, 0, SCREEN_W, SCREEN_H), Color("0a0718"))
	draw_circle(Vector2(360, 500), 320, Color(0.12, 0.08, 0.28, 0.6))

	# Título
	draw_string(font, Vector2(36, 64), "ARCANA REALMS", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("e8d9ff"))
	draw_string(font, Vector2(36, 100), "PROTOTYPE 02  •  MOBILE", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("9c8bbd"))

	# HUD
	draw_string(font, Vector2(36, 150), "HP  %d" % hp, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("ff8ea1"))
	draw_string(font, Vector2(500, 150), "CRISTAIS  %02d" % crystals, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("75e6ff"))

	# Inimigos
	for e in enemies:
		draw_circle(e.pos, 32, Color("5c2d91"))
		draw_circle(e.pos, 18, Color("d85cff"))
		draw_circle(e.pos + Vector2(-7, -6), 5, Color.WHITE)

	# Projéteis
	for p in projectiles:
		draw_circle(p.pos, 11, Color("a8f3ff"))
		draw_circle(p.pos, 5, Color.WHITE)

	# Jogador
	draw_circle(player_pos, 40, Color("3a2a8a"))
	draw_circle(player_pos, 28, Color("62d9ff"))
	draw_circle(player_pos + Vector2(-8, -9), 6, Color.WHITE)

	# Joystick base
	draw_circle(joystick_center, JOYSTICK_RADIUS, Color(0.15, 0.1, 0.3, 0.7))
	draw_circle(joystick_center, JOYSTICK_RADIUS - 8, Color(0.1, 0.07, 0.22, 0.8))
	var knob_pos = joystick_center + joystick_vector * JOYSTICK_RADIUS * 0.7
	draw_circle(knob_pos, 36, Color(0.55, 0.4, 0.95, 0.9))

	# Botão de ataque
	var attack_color = Color("75e6ff") if attack_cd <= 0.0 else Color(0.4, 0.4, 0.5)
	draw_circle(attack_btn_center, attack_btn_radius, Color(0.15, 0.1, 0.3, 0.75))
	draw_circle(attack_btn_center, attack_btn_radius - 10, attack_color)
	draw_string(font, attack_btn_center + Vector2(-28, 8), "ATK", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("0a0718"))
