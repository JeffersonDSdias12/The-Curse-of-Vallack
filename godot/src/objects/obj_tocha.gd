extends Lib
# =====================================================================
#  obj_tocha — tocha de parede (v1.11)
#  Começa apagada (só uma brasa) e ACENDE quando Twilight chega perto.
# =====================================================================

var acesa := false
var luz := 0.0
var brasa_t := 0.0
var semente := 0.0


func ev_create() -> void:
	image_speed = 0
	depth = 240
	semente = randf() * 100


func ev_step() -> void:
	var dt := G.dt
	if not acesa:
		if cenario_dist_jogador(x, y) < 300:
			acesa = true
			som_em("tocha_acender", x, y, 0.8)
			fx_em("brasas", x, y - 4, 0.7, 1, depth - 1)
			fx_em("faiscas_golpe", x, y - 2, 0.45, choose([-1.0, 1.0]), depth - 1)
		return
	luz = minf(1, luz + 0.05 * dt)
	brasa_t -= dt
	if brasa_t <= 0:
		brasa_t = randi_range(16, 34) / maxf(0.5, G.cfg_qualidade)
		if cenario_na_tela(x, x, 0):
			fx_em("brasas", x, y - 8, 0.22, 1, depth - 1)


func ev_draw() -> void:
	if not cenario_na_tela(x - 90, x + 90):
		return
	var t := current_time() / 16.0
	if luz > 0:
		var pisca := 0.85 + 0.15 * sin(t / 3.1 + semente) * sin(t / 7.7 + semente * 3)
		cenario_luz(x, y - 10, 92 * (0.6 + 0.4 * luz), luz * pisca, cor_chama_maldita())
	draw_sprite(sprite_index, 0, x, y)
	if luz > 0:
		desenhar_chamas(x, y + 1, 10, 18 * (0.4 + 0.6 * luz), t + semente * 10, luz, semente)
	else:
		gpu_set_blendmode(bm_add)
		draw_set_alpha(0.4 + 0.2 * sin(t / 9.0 + semente))
		draw_set_color(Color8(170, 60, 255))
		draw_circle(x, y, 2, false)
		gpu_set_blendmode(bm_normal)
		draw_set_alpha(1)
