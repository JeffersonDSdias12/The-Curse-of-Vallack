extends Lib
# obj_poca_veneno — poça de veneno (v1.12): queima quem pisa nela por 4 s.
# Rolando, Twilight passa sem se ferir.

var vida := 240.0
var t := 0.0
var larg := 34.0
var dano := 4.0
var semente := 0.0


func ev_create() -> void:
	dano = maxf(1, round(4 * dif_dano_inimigo()))
	semente = randf() * 100


func ev_step() -> void:
	var dt := G.dt
	t += dt
	var p = instance_find("obj_player", 0)
	if p != null and not p.morto and absf(p.x - x) < larg and absf(p.y - y) < 14 and p.tempo_invencivel <= 0:
		if not p.jogador_intangivel():
			p.levar_dano(dano, x, false, 0.5, null)
			som_em("veneno_dano", x, y, 0.7)
	if t >= vida:
		instance_destroy()


func ev_draw() -> void:
	var a := clampf(minf(t / 10.0, (vida - t) / 40.0), 0, 1)
	draw_set_alpha(0.75 * a)
	draw_set_color(Color8(40, 90, 30))
	draw_ellipse(x - larg, y - 5, x + larg, y + 3, false)
	gpu_set_blendmode(bm_add)
	draw_set_alpha(0.3 * a)
	draw_set_color(Color8(110, 220, 70))
	draw_ellipse(x - larg * 0.8, y - 4, x + larg * 0.8, y + 2, false)
	for k in 4:
		var f := frac(t / 70.0 + k / 4.0 + semente)
		draw_set_alpha((1 - f) * 0.5 * a)
		draw_circle(x + sin(k * 2.7 + semente) * larg * 0.6, y - 2 - f * 26, 1.5 + 2 * (1 - f), false)
	gpu_set_blendmode(bm_normal)
	draw_set_alpha(1)
	draw_set_color(c_white)
