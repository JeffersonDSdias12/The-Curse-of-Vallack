extends Lib
# =====================================================================
#  obj_chama_sylla — CHAMA DE SYLLA (sub-arma, v1.12, 2 essências)
#  Uma chama sagrada dourada no chão à frente de Twilight: queima os
#  inimigos que passam por ela durante 4 s (não fere o jogador).
# =====================================================================

var dir := 1.0
var vida := 240.0
var t := 0.0
var tick := 0.0
var dano := 6.0
var semente := 0.0
var atingidos: Array = []


func ev_create() -> void:
	semente = randf() * 100


func ev_step() -> void:
	var dt := G.dt
	t += dt
	tick -= dt
	var x1 := minf(x, x + dir * 90) - 16
	var x2 := maxf(x, x + dir * 90) + 16
	if tick <= 0:
		tick = 24
		var g := {"chave": "chama", "especial": false, "pesado": false, "porcento": 0, "dano": dano, "combo": 0, "no_ar": false}
		for alvo in collision_rectangle_list(x1, y - 46, x2, y, "obj_inimigo_base"):
			if alvo.morrendo or not alvo.ativo:
				continue
			var d := maxf(1, round(dano * espada_dano_mult()))
			alvo.levar_dano(d, x, true, 0.5, null, g)
			if not alvo.morrendo and not alvo.eh_boss:
				alvo.inimigo_atordoar(12)
	if t >= vida:
		instance_destroy()


func ev_draw() -> void:
	var f := clampf(minf(t / 10.0, (vida - t) / 30.0), 0, 1)
	gpu_set_blendmode(bm_add)
	draw_set_alpha(0.2 * f)
	draw_set_color(Color8(255, 200, 90))
	draw_ellipse(minf(x, x + dir * 90) - 24, y - 8, maxf(x, x + dir * 90) + 24, y + 4, false)
	gpu_set_blendmode(bm_normal)
	draw_set_alpha(1)
	for i in 4:
		desenhar_chamas(x + dir * i * 30, y, 26, 30 + 6 * sin(t / 9.0 + i), current_time() / 16.0 + i * 13, f, semente + i, 1)
