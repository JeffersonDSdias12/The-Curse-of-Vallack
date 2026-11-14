extends Lib
# =====================================================================
#  obj_flecha — flecha dos arqueiros (desenhada no código; não há sprite)
#  estados: voando, refletida, ricochete, cravada, caindo
# =====================================================================

var vx := 0.0
var vy := 0.0
var dano := 5.0
var alcance := 900.0
var dist := 0.0
var estado := "voando"
var vida := 0.0
var vida_max := 1.0
var ang := 0.0
var giro := 0.0
var escala := 1.3


func ev_step() -> void:
	var dt := G.dt
	match estado:
		"voando":
			vy += 0.05 * dt
			x += vx * dt
			y += vy * dt
			dist += sqrt(vx * vx + vy * vy) * dt
			ang = point_direction(0, 0, vx, vy)
			var px := x + lengthdir_x(12 * escala, ang)
			var py := y + lengthdir_y(12 * escala, ang)
			var p = instance_find("obj_player", 0)
			var intang: bool = p != null and p.jogador_intangivel()
			if p != null and not p.morto and not intang and point_in_rectangle(px, py, p.bbox_left, p.bbox_top, p.bbox_right, p.bbox_bottom):
				if p.janela_aparar > 0 and signf(x - p.x) == p.facing:
					# APARADA: a flecha volta contra quem atirou
					jogador_aparou(null)
					estado = "refletida"
					vx = -vx * 1.2
					vy = -vy * 0.3 - 0.4
					dist = 0
					alcance = 700
					return
				if p.bloqueando and signf(x - p.x) == p.facing:
					jogador_bloqueou(x)
					estado = "ricochete"
					vx = -vx * 0.35
					vy = -3.2
					giro = 20 * signf(1.0 if vx == 0 else vx)
					vida = 50
					vida_max = 50
				else:
					p.levar_dano(dano, x, true, 2)
					instance_destroy()
					return
			elif position_meeting(px, py, "obj_chao"):
				estado = "cravada"
				vida = 120
				vida_max = 120
			elif dist >= alcance or y > G.room_height + 50:
				estado = "caindo"
				vida = 30
				vida_max = 30
		"refletida":
			vy += 0.02 * dt
			x += vx * dt
			y += vy * dt
			dist += sqrt(vx * vx + vy * vy) * dt
			ang = point_direction(0, 0, vx, vy)
			var rx := x + lengthdir_x(12 * escala, ang)
			var ry := y + lengthdir_y(12 * escala, ang)
			var e = collision_point(rx, ry, "obj_inimigo_base")
			if e != null and not e.morrendo and e.ativo:
				var gw := {"chave": "flecha", "especial": false, "pesado": true, "porcento": 0, "dano": 0, "combo": 0}
				var dn: float = maxf(1, round(e.vida_max * 0.02)) if e.eh_boss else maxf(1, round(e.vida_max * 0.6))
				e.levar_dano(dn, x - vx, false, 5, null, gw)
				if not e.morrendo:
					e.inimigo_atordoar(80, true)
				fx_em("faiscas_golpe", rx, ry, 1, signf(vx))
				som_em("hit_2", x, y, 0.9)
				instance_destroy()
				return
			if position_meeting(rx, ry, "obj_chao"):
				estado = "cravada"
				vida = 120
				vida_max = 120
			elif dist >= alcance:
				estado = "caindo"
				vida = 30
				vida_max = 30
		"ricochete":
			vy += 0.3 * dt
			x += vx * dt
			y += vy * dt
			ang += giro * dt
			if position_meeting(x, y, "obj_chao"):
				vx *= 0.5
				vy = 0
				giro *= 0.5
			vida -= dt
			if vida <= 0:
				instance_destroy()
		"cravada":
			vida -= dt
			if vida <= 0:
				instance_destroy()
		"caindo":
			vy += 0.25 * dt
			x += vx * 0.5 * dt
			y += vy * dt
			vida -= dt
			if vida <= 0:
				instance_destroy()


func ev_draw() -> void:
	var a := 1.0 if (estado == "voando" or estado == "refletida") else clampf(vida / maxf(1, vida_max) * 1.5, 0, 1)
	if estado == "refletida":
		gpu_set_blendmode(bm_add)
		draw_set_alpha(0.5)
		draw_set_color(Color8(110, 180, 255))
		draw_circle(x, y, 7, false)
		draw_line_width(x, y, x - vx * 4, y - vy * 4, 3)
		gpu_set_blendmode(bm_normal)
	var c := 12 * escala
	var tx := x - lengthdir_x(c, ang)
	var ty := y - lengthdir_y(c, ang)
	var hx := x + lengthdir_x(c, ang)
	var hy := y + lengthdir_y(c, ang)
	draw_set_alpha(a)
	if estado == "voando":
		draw_set_alpha(0.25)
		draw_set_color(Color8(255, 220, 200))
		draw_line_width(tx - lengthdir_x(10, ang), ty - lengthdir_y(10, ang), tx, ty, 1)
		draw_set_alpha(a)
	draw_set_color(Color8(215, 196, 160))
	draw_line_width(tx, ty, hx, hy, 2)
	draw_set_color(Color8(150, 150, 160))
	draw_triangle(hx + lengthdir_x(5 * escala, ang), hy + lengthdir_y(5 * escala, ang),
		hx + lengthdir_x(2.5 * escala, ang + 90), hy + lengthdir_y(2.5 * escala, ang + 90),
		hx + lengthdir_x(2.5 * escala, ang - 90), hy + lengthdir_y(2.5 * escala, ang - 90), false)
	draw_set_color(Color8(200, 40, 40))
	draw_triangle(tx, ty, tx - lengthdir_x(5 * escala, ang - 25), ty - lengthdir_y(5 * escala, ang - 25),
		tx + lengthdir_x(4 * escala, ang), ty + lengthdir_y(4 * escala, ang), false)
	draw_triangle(tx, ty, tx - lengthdir_x(5 * escala, ang + 25), ty - lengthdir_y(5 * escala, ang + 25),
		tx + lengthdir_x(4 * escala, ang), ty + lengthdir_y(4 * escala, ang), false)
	draw_set_alpha(1)
	draw_set_color(c_white)
