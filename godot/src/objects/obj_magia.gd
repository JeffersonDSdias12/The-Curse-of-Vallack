extends Lib
# =====================================================================
#  obj_magia — projéteis de magia dos inimigos novos (v1.8)
#  "orbe" (estátua): persegue Twilight; a defesa segura, aparar devolve
#  "teia" (aranha): voa em arco e PRENDE; no chão vira armadilha
#  "onda" (porco): corte roxo rente ao chão; não dá para defender
# =====================================================================

var tipo := "orbe"
var vx := 0.0
var vy := 0.0
var dano := 5.0
var dono = null
var alcance := 900.0
var dist := 0.0
var t := 0.0
var ang := 180.0
var escala := 0.8
var refletida := false
var estado := "voando"
var fim_t := 0.0
var vida_chao := 0.0
var atingiu := false


func ev_create() -> void:
	image_speed = 0


func estourar() -> void:
	if estado == "fim":
		return
	estado = "fim"
	fim_t = 0
	vx = 0
	vy = 0
	if tipo == "orbe":
		som_em("fogo_explosao", x, y, 0.45)
	elif tipo == "onda":
		fx_em("poeira", x, y, 0.5)


func ev_step() -> void:
	var dt := G.dt
	t += dt
	if estado == "fim":
		fim_t += dt
		if fim_t >= 16:
			instance_destroy()
		return
	var p = instance_find("obj_player", 0)
	var vivo: bool = p != null and not p.morto
	var intang := false
	if vivo:
		intang = p.jogador_intangivel()
	# ===== TEIA GRUDADA NO CHÃO: armadilha pegajosa =====
	if estado == "chao":
		vida_chao -= dt
		if vida_chao <= 0:
			instance_destroy()
			return
		if vivo and not intang and p.enredado <= 0 and p.teia_imune <= 0 \
				and rectangle_in_rectangle(x - 22, y - 8, x + 22, y + 2, p.bbox_left, p.bbox_top, p.bbox_right, p.bbox_bottom) > 0:
			jogador_enredar(45)
			vida_chao = minf(vida_chao, 20)
		return
	# ===== MOVIMENTO =====
	match tipo:
		"orbe":
			if not refletida and t < 40 and vivo:
				var alvo_ang := point_direction(x, y, p.x, p.y - 34)
				var sp := point_distance(0, 0, vx, vy)
				var a := point_direction(0, 0, vx, vy)
				a += clampf(angle_difference(alvo_ang, a), -1.3 * dt, 1.3 * dt)
				vx = lengthdir_x(sp, a)
				vy = lengthdir_y(sp, a)
		"teia":
			vy += 0.12 * dt
	x += vx * dt
	y += vy * dt
	dist += point_distance(0, 0, vx, vy) * dt
	if vx != 0 or vy != 0:
		ang = point_direction(0, 0, vx, vy)
	# ===== REBATIDA POR TWILIGHT: fere e prende os inimigos =====
	if refletida:
		var e = collision_rectangle(x - 8, y - 8, x + 8, y + 8, "obj_inimigo_base")
		if e != null and not e.morrendo and e.ativo:
			var gw := {"chave": "teia" if tipo == "teia" else "orbe", "especial": false, "pesado": true, "porcento": 0, "dano": 0, "combo": 0}
			var pc := 0.15 if tipo == "teia" else 0.5
			var dn: float = maxf(1, round(e.vida_max * 0.03)) if e.eh_boss else maxf(1, round(e.vida_max * pc))
			var at := 150.0 if tipo == "teia" else 90.0
			e.levar_dano(dn, x - vx, false, 5, null, gw)
			if not e.morrendo:
				e.inimigo_atordoar(at, true)
			if G.existe(e) and ("rachada_t" in e):
				e.rachada_t = 180
			fx_em("faiscas_golpe", x, y, 1, signf(vx))
			som_em("hit_2", x, y, 0.9)
			estourar()
			return
	elif vivo and not intang and not atingiu:
		var toca := false
		if tipo == "onda":
			toca = rectangle_in_rectangle(x - 16, y - 30, x + 16, y, p.bbox_left, p.bbox_top, p.bbox_right, p.bbox_bottom) > 0
		else:
			toca = point_in_rectangle(x, y, p.bbox_left - 5, p.bbox_top - 5, p.bbox_right + 5, p.bbox_bottom + 5)
		if toca:
			var frente: bool = x == p.x or signf(x - p.x) == p.facing
			# APARAR: volta contra quem lançou (a onda roxa não dá para aparar)
			if tipo != "onda" and p.janela_aparar > 0 and frente:
				jogador_aparou(null)
				refletida = true
				var sp2 := maxf(6, point_distance(0, 0, vx, vy) * 1.4)
				var ang2 := ang + 180
				if G.existe(dono):
					ang2 = point_direction(x, y, dono.x, dono.y - 40)
				vx = lengthdir_x(sp2, ang2)
				vy = lengthdir_y(sp2, ang2)
				if tipo == "teia":
					vy -= 1.2
				dist = 0
				alcance = 900
				return
			# DEFESA MÁGICA: segura o orbe e a teia
			if tipo != "onda" and p.bloqueando and frente:
				jogador_bloqueou(x)
				estourar()
				return
			var bloq := tipo != "onda"
			var vida_antes: float = p.vida
			var armadura: bool = p.armadura
			p.levar_dano(dano, x, bloq, 6.0 if tipo == "onda" else 3.0, null)
			if tipo == "teia" and p.vida < vida_antes and not armadura and not p.morto:
				var q := 90.0
				if G.existe(dono) and ("teia_quadros" in dono):
					q = dono.teia_quadros
				jogador_enredar(q)
			if tipo == "onda":
				atingiu = true
			else:
				estourar()
				return
	# ===== CENÁRIO E ALCANCE =====
	if tipo == "onda":
		var sv := 1.0 if vx >= 0 else -1.0
		if position_meeting(x + sv * 16, y - 14, "obj_chao") or not position_meeting(x, y + 4, "obj_chao") or dist >= alcance:
			estourar()
	elif position_meeting(x, y, "obj_chao"):
		if tipo == "teia" and not refletida:
			estado = "chao"
			vida_chao = 240
			vx = 0
			vy = 0
			var gy := y
			while gy > y - 40 and position_meeting(x, gy - 1, "obj_chao"):
				gy -= 1
			y = gy
			som_em("teia_prende", x, y, 0.4)
		else:
			estourar()
	elif dist >= alcance or y > G.room_height + 50:
		estourar()


func ev_draw() -> void:
	gpu_set_texfilter(true)
	match tipo:
		"orbe":
			var cor_b := Color8(110, 190, 255) if refletida else Color8(255, 40, 60)
			if estado == "fim":
				var f := fim_t / 16.0
				gpu_set_blendmode(bm_add)
				draw_set_alpha(0.8 * (1 - f))
				draw_set_color(cor_b)
				draw_circle(x, y, 8 + 22 * f, true)
				draw_circle(x, y, 6 + 14 * f, false)
				gpu_set_blendmode(bm_normal)
				draw_set_alpha(1)
			else:
				gpu_set_blendmode(bm_add)
				draw_set_alpha(0.3 + 0.1 * sin(t * 0.5))
				draw_set_color(cor_b)
				draw_circle(x, y, 16, false)
				gpu_set_blendmode(bm_normal)
				draw_set_alpha(1)
				draw_sprite_hd(Spr.spr_estatua_orbe, 0, x, y, escala, escala, ang - 180, Color8(170, 220, 255) if refletida else c_white, 1)
		"teia":
			var cw := Color8(200, 230, 255) if refletida else Color8(235, 235, 240)
			if estado == "chao":
				var va := clampf(vida_chao / 30.0, 0, 1) * 0.85
				draw_set_alpha(va)
				draw_set_color(cw)
				draw_ellipse(x - 22, y - 5, x + 22, y + 2, true)
				draw_ellipse(x - 12, y - 3, x + 12, y + 1, true)
				for r in 6:
					var ra := r * 30.0
					draw_line(x - lengthdir_x(22, ra), y - 1.5 - lengthdir_y(3.5, ra), x + lengthdir_x(22, ra), y - 1.5 + lengthdir_y(3.5, ra))
				draw_set_alpha(1)
			else:
				var fa := 1 - fim_t / 16.0 if estado == "fim" else 1.0
				var rr := 6 + fim_t if estado == "fim" else 5.0
				draw_set_alpha(fa)
				draw_set_color(cw)
				draw_circle(x, y, rr, false)
				for k in 8:
					var ka := k * 45 + t * 6
					draw_line(x, y, x + lengthdir_x(rr + 5, ka), y + lengthdir_y(rr + 5, ka))
				draw_set_alpha(0.35 * fa)
				draw_line(x, y, x - vx * 4, y - vy * 4)
				draw_set_alpha(1)
		"onda":
			var oa := 1 - fim_t / 16.0 if estado == "fim" else 1.0
			var sd := 1.0 if vx >= 0 else -1.0
			var cx := x - sd * 8
			var cy := y - 18
			gpu_set_blendmode(bm_add)
			draw_primitive_begin(pr_trianglestrip)
			for i in 11:
				var a := -80 + i * 16.0
				var ox := lengthdir_x(1, a) * sd
				var oy := lengthdir_y(1, a)
				var l := 1 - absf(i - 5) / 5.5
				draw_vertex_color(cx + ox * 24, cy + oy * 22, Color8(230, 60, 255), 0.85 * oa * l)
				draw_vertex_color(cx + ox * 13, cy + oy * 15, Color8(255, 210, 255), 0.25 * oa)
			draw_primitive_end()
			draw_set_alpha(0.35 * oa)
			draw_set_color(Color8(200, 50, 255))
			draw_ellipse(x - 20, y - 4, x + 20, y + 3, false)
			for j in 3:
				draw_circle(x - sd * (14 + j * 12), y - 6 - fmod(t * 2 + j * 9, 22), 1.6, false)
			gpu_set_blendmode(bm_normal)
			draw_set_alpha(1)
	gpu_set_texfilter(false)
	draw_set_alpha(1)
