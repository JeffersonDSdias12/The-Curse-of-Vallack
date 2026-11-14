extends Lib
# =====================================================================
#  obj_fogo_chao — fogo no chão (destroços da vila queimando)
#  Sempre queima baixo; de tempos em tempos as chamas sobem (mais dano).
#  image_xscale da instância na sala = largura em blocos de 32 px.
# =====================================================================

var larg := 32.0
var t := 0.0
var forte := 0.0
var atingidos: Array = []
var semente := 0.0


func ev_create() -> void:
	larg = 32 * maxf(1, image_xscale)
	image_xscale = 1
	t = fmod(x, 131)
	forte = 0
	semente = randf() * 100
	visible = true


func ev_step() -> void:
	var dt := G.dt
	t += dt
	# a cada 3 s as chamas sobem por 1 s
	var ciclo := fmod(t, 180)
	var alvo := 1.0 if ciclo > 130 else 0.35
	if ciclo > 118 and ciclo < 130 and randf() < 0.5 * dt:
		fx_em("brasas", x + randf_range(-larg / 2, larg / 2), y - 4, 0.7)
	forte = lerpf(forte, alvo, 0.15)
	if ciclo < dt:
		atingidos = []
		som_em("fogo_whoosh", x, y, 0.55)
	if forte > 0.6:
		armadilha_area(x - larg / 2, y - 40 * forte, x + larg / 2, y, 12, 20, atingidos, 3)
	elif floor((t - dt) / 50.0) != floor(t / 50.0):
		var baixo := []
		armadilha_area(x - larg / 2 + 4, y - 12, x + larg / 2 - 4, y, 4, 0, baixo, 1)
	if randf() < 0.06 * dt:
		fx_em("fumaca", x + randf_range(-larg / 2, larg / 2), y - 16, 0.6)
	if randf() < 0.08 * dt:
		fx_em("brasas", x + randf_range(-larg / 2, larg / 2), y - 6, 0.4)


func ev_draw() -> void:
	draw_set_color(Color8(30, 18, 14))
	draw_set_alpha(0.85)
	draw_ellipse(x - larg / 2 - 4, y - 4, x + larg / 2 + 4, y + 3, false)
	draw_set_alpha(1)
	desenhar_chamas(x, y, larg, 48, current_time() / 16.0, forte, semente)
	if G.debug_hitbox:
		draw_set_color(c_orange)
		draw_rectangle(x - larg / 2, y - 40 * forte, x + larg / 2, y, true)
