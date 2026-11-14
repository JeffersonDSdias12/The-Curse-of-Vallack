extends Lib
# =====================================================================
#  obj_nevoa_veneno — névoa venenosa (v1.12)
#  Andando, Twilight é empurrado de volta e se fere; ROLANDO ele atravessa.
#  Na sala: Escala X = largura (1 = 68 px).
# =====================================================================

var larg := 34.0
var alt := 150.0
var t := 0.0
var dano := 3.0
var aviso_t := 0.0


func ev_create() -> void:
	larg = 34 * maxf(1, absf(image_xscale))
	image_speed = 0
	depth = 90


func ev_step() -> void:
	var dt := G.dt
	t += dt
	if aviso_t > 0:
		aviso_t -= dt
	var p = instance_find("obj_player", 0)
	if p == null or p.morto:
		return
	if absf(p.x - x) < larg + 6 and p.y > y - alt and p.y <= y + 4:
		if p.rolando:
			return
		var lado := -1.0 if p.x < x else 1.0
		p.x = x + lado * (larg + 7)
		if p.tempo_invencivel <= 0:
			p.levar_dano(dano, x, false, 0, null)
			som_em("veneno_dano", x, y, 0.8)
		p.velh = 0
		p.empurrao = lado * 3.5
		aviso_t = 120


func ev_draw() -> void:
	if not cenario_na_tela(x - larg * 2, x + larg * 2):
		return
	for i in 14:
		var fy := y - (i / 13.0) * alt
		var ox := sin(t / 30.0 + i * 1.3) * larg * 0.35
		var r := larg * (0.7 + 0.25 * sin(t / 40.0 + i))
		draw_set_alpha(0.16)
		draw_set_color(Color8(60, 130, 45))
		draw_circle(x + ox, fy, r, false)
	gpu_set_blendmode(bm_add)
	draw_set_alpha(0.12)
	draw_set_color(Color8(120, 255, 90))
	draw_ellipse(x - larg * 1.2, y - alt, x + larg * 1.2, y + 4, false)
	for k in 6:
		var f := frac(t / 120.0 + k / 6.0)
		draw_set_alpha(0.5 * (1 - f))
		draw_circle(x + sin(k * 2.3 + t / 50.0) * larg * 0.6, y - f * alt, 1.5 + 2.5 * (1 - f), true)
	gpu_set_blendmode(bm_normal)
	draw_set_alpha(1)
	desenho_resetar()
