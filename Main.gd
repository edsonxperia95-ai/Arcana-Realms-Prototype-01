extends Node2D

var player := Vector2(360, 1030)
var velocity := Vector2.ZERO
var hp := 100
var crystals := 0
var enemies := [Vector2(180, 360), Vector2(540, 470), Vector2(360, 610)]
var projectiles: Array[Dictionary] = []
var attack_cooldown := 0.0
var font: Font

func _ready() -> void:
    font = ThemeDB.fallback_font
    queue_redraw()

func _process(delta: float) -> void:
    var input_dir := Input.get_axis("move_left", "move_right")
    if Input.is_key_pressed(KEY_LEFT): input_dir -= 1.0
    if Input.is_key_pressed(KEY_RIGHT): input_dir += 1.0
    velocity.x = move_toward(velocity.x, input_dir * 420.0, 1800.0 * delta)
    player.x = clamp(player.x + velocity.x * delta, 70.0, 650.0)
    attack_cooldown -= delta
    if (Input.is_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) and attack_cooldown <= 0.0:
        fire_arcane_bolt()
        attack_cooldown = 0.28
    for p in projectiles:
        p.pos += p.vel * delta
    projectiles = projectiles.filter(func(p): return p.pos.y > 40)
    for i in range(enemies.size()):
        enemies[i].y += sin(Time.get_ticks_msec() * 0.001 + i) * 8.0 * delta
    queue_redraw()

func fire_arcane_bolt() -> void:
    projectiles.append({"pos": player + Vector2(0, -50), "vel": Vector2(0, -720)})
    for i in range(enemies.size() - 1, -1, -1):
        if player.distance_to(enemies[i]) < 520.0 and enemies[i].y < player.y:
            crystals += 1
            enemies.remove_at(i)
            break
    if enemies.is_empty():
        enemies = [Vector2(180, 360), Vector2(540, 470), Vector2(360, 610)]

func _draw() -> void:
    draw_rect(Rect2(0, 0, 720, 1280), Color("090619"))
    draw_circle(Vector2(360, 520), 330, Color("17103d"))
    draw_circle(Vector2(360, 520), 250, Color("211354"))
    for y in range(180, 900, 100):
        draw_line(Vector2(80, y), Vector2(640, y), Color(0.35, 0.25, 0.65, 0.12), 2)
    draw_string(font, Vector2(48, 70), "ARCANA REALMS", HORIZONTAL_ALIGNMENT_LEFT, -1, 38, Color("e8d9ff"))
    draw_string(font, Vector2(48, 112), "PROTOTYPE 01  •  MOBILE TEST", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("9c8bbd"))
    draw_string(font, Vector2(48, 160), "HP  %d" % hp, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("ff8ea1"))
    draw_string(font, Vector2(500, 160), "CRISTAIS  %02d" % crystals, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("75e6ff"))
    for e in enemies:
        draw_circle(e, 34, Color("6c3fa4"))
        draw_circle(e, 20, Color("d85cff"))
        draw_circle(e + Vector2(-8, -5), 5, Color.WHITE)
    draw_circle(player, 42, Color("4932a8"))
    draw_circle(player, 30, Color("62d9ff"))
    draw_circle(player + Vector2(-9, -10), 7, Color.WHITE)
    for p in projectiles:
        draw_circle(p.pos, 10, Color("a8f3ff"))
        draw_circle(p.pos, 5, Color.WHITE)
    draw_rect(Rect2(80, 1110, 560, 92), Color(0.08, 0.05, 0.18, 0.95), true)
    draw_string(font, Vector2(112, 1165), "←  →  MOVER", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("d8c9f2"))
    draw_string(font, Vector2(390, 1165), "ATAQUE  •  TOQUE", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("75e6ff"))
