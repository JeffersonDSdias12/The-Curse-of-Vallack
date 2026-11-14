extends Lib
# =====================================================================
#  obj_viga_fogo — viga em chamas que cai do telhado de uma casa
#  aviso (poeira, brasas e sombra) -> queda -> queimando -> cinzas
# =====================================================================

var estado := "esperando"
var t := 0.0
var y_chao := 0.0
var y_viga := 0.0
var vy := 0.0
var ang := 0.0
var atingidos: Array = []
var queima := 0.0
var semente := 0.0
var dist_ativar := 150.0


func ev_create() -> void:
	y_chao = y
	y_viga = y - 320
	ang = randf_range(-10, 10)
	semente = randf() * 100


func ev_step() -> void:
	var dt := G.dt
	t += dt
	var p = instance_find("obj_player", 0)
	match estado:
		"esperando":
			if p != null and not p.morto and absf(p.x - x) < dist_ativar and absf(p.y - y) < 120:
				estado = "aviso"
				t = 0
				y_viga = G.view_y - 30
				som_em("viga_aviso", x, y, 1)
				som_em("fogo_whoosh", x, y, 0.7)
		"aviso":
			if randf() < 0.5 * dt:
				fx_em("brasas", x + randf_range(-30, 30), y_viga + 30, 0.6)
			if randf() < 0.3 * dt:
				fx_em("poeira", x + randf_range(-30, 30), y_viga + 40, 0.3)
			if t >= 48:
				estado = "caindo"
				t = 0
				vy = 2
		"caindo":
			vy = minf(vy + 0.55 * dt, 16)
			y_viga += vy * dt
			ang = lerpf(ang, 0, 0.05)
			if y_viga >= y_chao - 7:
				y_viga = y_chao - 7
				estado = "queimando"
				t = 0
				atingidos = []
				armadilha_area(x - 40, y_chao - 60, x + 40, y_chao, 20, 45, atingidos, 6)
				som_em("dest_viga", x, y, 1)
				som_em("fogo_explosao", x, y, 0.5)
				G.camera_impact = maxf(G.camera_impact, 10)
				fx_em("poeira", x, y_chao, 1.3)
				fx_em("faiscas_tela", x, y_chao, 0.5)
				fx_em("lascas", x, y_chao - 6, 0.8)
		"queimando":
			queima += dt
			if floor((queima - dt) / 45.0) != floor(queima / 45.0):
				atingidos = []
			if queima < 260:
				armadilha_area(x - 34, y_chao - 16, x + 34, y_chao, 6, 10, atingidos, 2)
			if randf() < 0.12 * dt:
				fx_em("fumaca", x + randf_range(-30, 30), y_chao - 10, 0.8)
			if queima >= 360:
				estado = "cinzas"
				t = 0


func ev_draw() -> void:
	var tt := current_time() / 16.0
	if estado == "esperando":
		return
	if estado == "aviso" or estado == "caindo":
		var k := t / 48.0 if estado == "aviso" else 1.0
		draw_set_alpha(0.25 + 0.3 * k)
		draw_set_color(c_black)
		draw_ellipse(x - 40 * k, y_chao - 3, x + 40 * k, y_chao + 3, false)
		draw_set_alpha(1)
		if estado == "aviso":
			var pa := 0.6 + 0.4 * sin(tt * 0.5)
			gpu_set_blendmode(bm_add)
			draw_set_alpha(0.18 + 0.2 * k)
			draw_set_color(Color8(170, 60, 255))
			draw_rectangle(x - 42, y_chao - 150, x + 42, y_chao, false)
			draw_set_alpha(0.5 + 0.3 * pa)
			draw_ellipse(x - 46, y_chao - 5, x + 46, y_chao + 4, false)
			gpu_set_blendmode(bm_normal)
			draw_set_alpha(1)
			gpu_set_texfilter(true)
			txt_sombra(x, y_chao - 96, "!", FONTE.GRANDE, Color8(255, 210, 80), pa, fa_center, fa_middle, 1.25 + 0.15 * k)
			gpu_set_texfilter(false)
	var fogo := 1.0
	if estado == "cinzas":
		fogo = maxf(0, 1 - t / 120.0)
	elif estado == "queimando":
		fogo = clampf(1.2 - queima / 360.0, 0.15, 1)
	var cor := merge_color(c_white, Color8(70, 60, 60), clampf(t / 60.0, 0, 1)) if estado == "cinzas" else c_white
	if estado != "aviso":
		draw_sprite_ext(Spr.spr_viga, 0, x, y_viga, 1, 1, ang, cor, maxf(0, 1 - t / 200.0) if estado == "cinzas" else 1.0)
		desenhar_chamas(x, y_viga - 2, 70, 22.0 if estado == "caindo" else 30.0, tt, fogo, semente)
	if estado == "cinzas" and t >= 200:
		instance_destroy()
