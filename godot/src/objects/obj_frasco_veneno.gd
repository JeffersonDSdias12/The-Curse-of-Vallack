extends Lib
# =====================================================================
#  obj_frasco_veneno — frasco do Esqueleto Alquimista (v1.12)
#  Voa em arco. O veneno atravessa a defesa: só a esquiva escapa. No
#  chão, vira uma poça de veneno.
# =====================================================================

var vx := 0.0
var vy := 0.0
var g := 0.25
var dano := 6.0
var ang := 0.0
var t := 0.0


func estourar() -> void:
	var cy := chao_abaixo(x, y - 24, 220)
	instance_create_depth(x, cy, 140, "obj_poca_veneno")
	som_em("veneno_poca", x, y, 0.8)
	for i in 6:
		var f = instance_create_depth(x + randf_range(-8, 8), y - 6, -100, "obj_fagulha")
		f.cor = choose([Color8(120, 230, 80), Color8(70, 170, 50)])
	instance_destroy()


func ev_step() -> void:
	var dt := G.dt
	t += dt
	vy += g * dt
	x += vx * dt
	y += vy * dt
	ang += 12 * dt
	var p = instance_find("obj_player", 0)
	if p != null and not p.morto and point_in_rectangle(x, y, p.bbox_left - 4, p.bbox_top - 4, p.bbox_right + 4, p.bbox_bottom + 4):
		if not p.jogador_intangivel():
			p.levar_dano(dano, x, false, 2, null)
			estourar()
			return
	# (o frasco não tem máscara: o toque no chão é medido no ponto do frasco)
	if position_meeting(x, y, "obj_chao") or y > G.room_height:
		estourar()
		return
	if t > 300:
		instance_destroy()


func ev_draw() -> void:
	gpu_set_blendmode(bm_add)
	draw_set_alpha(0.35)
	draw_set_color(Color8(120, 255, 90))
	draw_circle(x, y, 9, false)
	gpu_set_blendmode(bm_normal)
	draw_set_alpha(1)
	draw_set_color(Color8(70, 160, 60))
	draw_circle(x, y, 5, false)
	draw_set_color(Color8(170, 255, 140))
	draw_circle(x - 1.5, y - 1.5, 1.6, false)
	draw_set_color(Color8(120, 90, 60))
	draw_line_width(x, y, x + lengthdir_x(8, ang), y + lengthdir_y(8, ang), 2.5)
	draw_set_color(c_white)
