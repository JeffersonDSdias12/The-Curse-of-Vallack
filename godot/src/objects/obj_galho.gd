extends Lib
# =====================================================================
#  obj_galho — GALHO VARREDOR da Árvore Amaldiçoada (v1.12, fases 2 e 3)
#  aviso (1 s: o chão da arena brilha) -> varre a arena rente ao chão ->
#  recolhe. Não dá para defender: PULE ou ROLE.
# =====================================================================

var dono = null
var dir := -1.0
var x_base := 0.0
var x_fim := 0.0
var ponta := 0.0
var estado := "aviso"
var t := 0.0
var vel := 13.0
var dano := 14.0
var atingiu := false
var y_chao := 0.0
var alt := 34.0
var semente := 0.0


func ev_create() -> void:
	x_base = x
	x_fim = x - 600
	ponta = x
	y_chao = y
	semente = randf() * 100
	som_em("galho_aviso", x, y, 1)


func ev_step() -> void:
	var dt := G.dt
	t += dt
	match estado:
		"aviso":
			if t >= 60:
				estado = "varre"
				t = 0
				som_em("fogo_whoosh", x, y, 0.9)
				G.camera_impact = maxf(G.camera_impact, 6)
		"varre":
			ponta += dir * vel * dt
			var p = instance_find("obj_player", 0)
			if not atingiu and p != null and not p.morto:
				var x1 := minf(ponta, ponta - dir * 40)
				var x2 := maxf(ponta, ponta - dir * 40)
				if rectangle_in_rectangle(x1, y_chao - alt, x2, y_chao, p.bbox_left, p.bbox_top, p.bbox_right, p.bbox_bottom) > 0:
					if not p.jogador_intangivel():
						atingiu = true
						p.levar_dano(dano, ponta - dir * 30, false, 6, null)
			if (dir < 0 and ponta <= x_fim) or (dir > 0 and ponta >= x_fim):
				estado = "recolhe"
				t = 0
		"recolhe":
			ponta -= dir * vel * 1.6 * dt
			if (dir < 0 and ponta >= x_base) or (dir > 0 and ponta <= x_base):
				instance_destroy()


func ev_draw() -> void:
	if estado == "aviso":
		var k := t / 60.0
		gpu_set_blendmode(bm_add)
		draw_set_alpha(0.15 + 0.35 * k * (0.6 + 0.4 * sin(t / 3.0)))
		draw_set_color(Color8(190, 80, 255))
		draw_rectangle(minf(x_base, x_fim), y_chao - 6, maxf(x_base, x_fim), y_chao + 2, false)
		gpu_set_blendmode(bm_normal)
		draw_set_alpha(1)
		gpu_set_texfilter(true)
		var pa := 0.6 + 0.4 * sin(t / 4.0)
		txt_sombra(lerpf(x_base, x_fim, 0.25), y_chao - 46, "!", FONTE.GRANDE, Color8(255, 120, 230), pa, fa_center, fa_bottom, 0.9)
		txt_sombra(lerpf(x_base, x_fim, 0.5), y_chao - 46, "!", FONTE.GRANDE, Color8(255, 120, 230), pa, fa_center, fa_bottom, 0.9)
		txt_sombra(lerpf(x_base, x_fim, 0.75), y_chao - 46, "!", FONTE.GRANDE, Color8(255, 120, 230), pa, fa_center, fa_bottom, 0.9)
		gpu_set_texfilter(false)
		desenho_resetar()
		return
	var x1 := x_base
	var x2 := ponta
	var n := maxi(2, int(ceil(absf(x2 - x1) / 24.0)))
	for i in n:
		var a := float(i) / n
		var b := float(i + 1) / n
		var xa := lerpf(x1, x2, a)
		var xb := lerpf(x1, x2, b)
		var wa := lerpf(16, 6, a)
		var wb := lerpf(16, 6, b)
		var ya := y_chao - alt * 0.45 + sin(a * 9 + semente) * 3
		var yb := y_chao - alt * 0.45 + sin(b * 9 + semente) * 3
		draw_set_color(Color8(72, 46, 32))
		draw_triangle(xa, ya - wa, xa, ya + wa, xb, yb + wb, false)
		draw_triangle(xa, ya - wa, xb, yb - wb, xb, yb + wb, false)
		draw_set_color(Color8(116, 76, 50))
		draw_line(xa, ya - wa * 0.5, xb, yb - wb * 0.5)
		if i % 2 == 0:
			draw_set_color(Color8(50, 30, 20))
			draw_triangle(xa, ya - wa, xa + 4, ya - wa, xa + 2, ya - wa - 8, false)
	gpu_set_blendmode(bm_add)
	draw_set_alpha(0.5)
	draw_set_color(Color8(180, 70, 255))
	draw_circle(x2, y_chao - alt * 0.45, 14, false)
	gpu_set_blendmode(bm_normal)
	draw_set_alpha(1)
	draw_set_color(c_white)
