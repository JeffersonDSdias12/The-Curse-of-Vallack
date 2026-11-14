extends Lib
# obj_portao — portão em arco do castelo, ao fundo (v1.11). Lá dentro, a
# luz do incêndio maldito pisca.

var tom := Color(1, 1, 1)
var semente := 0.0


func ev_create() -> void:
	image_speed = 0
	depth = 250
	tom = cenario_tom_fundo()
	semente = randf() * 100


func ev_draw() -> void:
	if not cenario_na_tela(x - 72, x + 72):
		return
	draw_sprite_ext(sprite_index, 0, x, y, image_xscale, image_yscale, 0, tom, 1)
	var p := 0.75 + 0.25 * sin(current_time() / 140.0 + semente) * sin(current_time() / 330.0 + semente * 2)
	gpu_set_blendmode(bm_add)
	draw_set_color(Color8(150, 60, 255))
	draw_set_alpha(0.1 * p)
	draw_ellipse(x - 40, y - 70, x + 40, y + 6, false)
	draw_set_alpha(0.08 * p)
	draw_ellipse(x - 26, y - 40, x + 26, y + 2, false)
	gpu_set_blendmode(bm_normal)
	draw_set_alpha(1)
