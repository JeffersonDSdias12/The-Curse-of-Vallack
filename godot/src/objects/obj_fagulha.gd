extends Lib
# obj_fagulha — estrela de impacto (golpes, sangue, faíscas)

var tempo := 0.0
var cor := Color(1, 1, 1)


func ev_step() -> void:
	tempo += G.dt
	if tempo > 14:
		instance_destroy()


func ev_draw() -> void:
	var p := clampf(tempo / 14.0, 0, 1)
	var n := 3 if G.cfg_qualidade == 0 else (5 if G.cfg_qualidade == 1 else 8)
	gpu_set_blendmode(bm_add)
	draw_set_alpha(1 - p)
	draw_set_color(cor)
	draw_circle(x, y, 6 + 26 * p, true)
	for i in n:
		var ang := i * (360.0 / n) + 22
		draw_line_width(x + lengthdir_x(8 + 22 * p, ang), y + lengthdir_y(8 + 22 * p, ang),
			x + lengthdir_x(14 + 34 * p, ang), y + lengthdir_y(14 + 34 * p, ang), 2)
	gpu_set_blendmode(bm_normal)
	draw_set_alpha(1)
	draw_set_color(c_white)
