extends Lib
# obj_caverna — entrada de caverna entre as rochas, ao fundo (v1.11).
# Lá de dentro vem um brilho roxo e escapam fiapos da fumaça da maldição.

var tom := Color(1, 1, 1)
var fumaca_t := 0.0
var semente := 0.0


func ev_create() -> void:
	image_speed = 0
	depth = 250
	tom = cenario_tom_fundo()
	semente = randf() * 100


func ev_step() -> void:
	var dt := G.dt
	if cenario_dist_jogador(x, y - 60) > 700:
		return
	fumaca_t -= dt
	if fumaca_t <= 0:
		fumaca_t = randi_range(14, 30) / maxf(0.5, G.cfg_qualidade)
		fx_em("fumaca_maldita", x + randf_range(-26, 26), y - randf_range(14, 70), 0.45, 1, depth - 1)


func ev_draw() -> void:
	if not cenario_na_tela(x - 88, x + 88):
		return
	draw_sprite_ext(sprite_index, 0, x, y, image_xscale, image_yscale, 0, tom, 1)
	var p := 0.7 + 0.3 * sin(current_time() / 420.0 + semente)
	gpu_set_blendmode(bm_add)
	draw_set_color(Color8(150, 40, 220))
	draw_set_alpha(0.14 * p)
	draw_ellipse(x - 38, y - 60, x + 38, y - 4, false)
	draw_set_alpha(0.1 * p)
	draw_ellipse(x - 22, y - 36, x + 22, y - 8, false)
	draw_set_color(Color8(220, 40, 90))
	draw_set_alpha(0.06 * p)
	draw_ellipse(x - 60, y - 100, x + 60, y + 10, false)
	gpu_set_blendmode(bm_normal)
	draw_set_alpha(1)
