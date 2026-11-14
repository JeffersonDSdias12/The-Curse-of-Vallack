extends Lib
# =====================================================================
#  obj_clima — TEMPESTADE da Fase 1
#  * duas camadas de chuva, rajadas de vento, relâmpagos com clarão duplo,
#    raio com galhos e TROVÃO com atraso; som de chuva em loop
#  Desenha no Draw End (por cima do mundo).
# =====================================================================

var chao_y := -1.0
var vento := -2.2
var vento_base := -2.2
var rajada := 0.0
var prox_rajada := 0.0
var n_gotas := 300
# gotas em arrays compactos (centenas por passo: dicionários pesam no celular)
var gx := PackedFloat32Array()
var gy := PackedFloat32Array()
var gvel := PackedFloat32Array()
var gcomp := PackedFloat32Array()
var ga := PackedFloat32Array()
var gperto := PackedByteArray()
var respingos: Array = []
var relampago := 0.0
var relampago_max := 1.0
var prox_relampago := 0.0
var raio: Array = []
var galhos: Array = []
var trovoes: Array = []
var t := 0.0


func ev_create() -> void:
	chao_y = chao_da_sala()
	prox_rajada = randi_range(240, 600)
	n_gotas = [100, 220, 320][clampi(G.cfg_qualidade, 0, 2)]     # v1.19: era 140/300/480 (a câmera ficou mais perto)
	prox_relampago = randi_range(160, 360)
	for arr in [gx, gy, gvel, gcomp, ga, gperto]:
		arr.resize(n_gotas)
	for i in n_gotas:
		nova_gota(i, true)


func nova_gota(i: int, qualquer_altura: bool) -> void:
	var vx := G.view_x
	var vy := G.view_y
	var vw := G.view_w
	var vh := G.view_h
	var perto := randf() < 0.3
	gx[i] = vx - 80 + randf() * (vw + 200)
	gy[i] = vy + randf() * vh if qualquer_altura else vy - randf() * 90
	gvel[i] = randf_range(14, 18) if perto else randf_range(10, 13)
	gcomp[i] = randf_range(18, 28) if perto else randf_range(9, 15)
	ga[i] = randf_range(0.45, 0.75) if perto else randf_range(0.22, 0.42)
	gperto[i] = 1 if perto else 0


func raio_criar(vx: float, vy: float, vw: float) -> void:
	raio = []
	galhos = []
	var rx := vx + randf_range(vw * 0.1, vw * 0.9)
	var ry := vy - 10
	var fim := vy + randf_range(140, 240)
	while ry < fim:
		raio.append([rx, ry])
		if randf() < 0.3:
			var g := [[rx, ry]]
			var gx := rx
			var gy := ry
			var gd: float = choose([-1.0, 1.0])
			for i in randi_range(2, 4):
				gx += gd * randf_range(8, 18)
				gy += randf_range(8, 16)
				g.append([gx, gy])
			galhos.append(g)
		rx += randf_range(-18, 18)
		ry += randf_range(10, 22)
	raio.append([rx, fim])


func ev_step() -> void:
	var dt := G.dt
	t += dt
	var vx := G.view_x
	var vy := G.view_y
	var vw := G.view_w
	var vh := G.view_h
	if chao_y < 0:
		chao_y = chao_da_sala()
	var chao := chao_y if chao_y >= 0 else vy + vh + 30
	ambiente("amb_chuva", 0.275)  # metade do volume anterior (0.55): estava alto demais
	# ----- vento e rajadas -----
	prox_rajada -= dt
	if prox_rajada <= 0:
		rajada = 1
		prox_rajada = randi_range(360, 800)
	rajada = maxf(0, rajada - 0.006 * dt)
	vento = vento_base - 2.6 * sin(rajada * PI) - 0.4 * sin(t / 90.0)
	# ----- chuva -----
	var v_longe := vento * dt
	var v_perto := vento * 1.3 * dt
	var qual := G.cfg_qualidade > 0
	for i in n_gotas:
		var perto := gperto[i] == 1
		var yy := gy[i] + gvel[i] * dt
		var xx := gx[i] + (v_perto if perto else v_longe)
		gy[i] = yy
		gx[i] = xx
		if yy >= chao + (10.0 if perto else 0.0) + randf() * 10:
			if chao_y >= 0 and qual and randf() < 0.45 and xx > vx and xx < vx + vw:
				respingos.append({"x": xx, "y": chao_y + randf_range(-2, 7), "t": 0.0, "g": perto})
			nova_gota(i, false)
		elif xx < vx - 140 or xx > vx + vw + 200 or yy > vy + vh + 40:
			nova_gota(i, false)
	for r in range(respingos.size() - 1, -1, -1):
		respingos[r].t += dt
		if respingos[r].t > 12:
			respingos.remove_at(r)
	# ----- relâmpagos e trovões com atraso -----
	if relampago > 0:
		relampago -= dt
	prox_relampago -= dt
	if prox_relampago <= 0:
		var perto := randf() < 0.4
		relampago = 34.0 if perto else 24.0
		relampago_max = relampago
		prox_relampago = randi_range(300, 720)
		G.camera_impact = maxf(G.camera_impact, 6.0 if perto else 3.0)
		raio_criar(vx, vy, vw)
		trovoes.append([randi_range(8, 20) if perto else randi_range(40, 95), 1.0 if perto else 0.6])
	for k in range(trovoes.size() - 1, -1, -1):
		trovoes[k][0] -= G.dt_real
		if trovoes[k][0] <= 0:
			som("sfx_trovao_" + str(randi_range(1, 3)), trovoes[k][1], 0.08)
			if trovoes[k][1] >= 1:
				G.terremoto = maxf(G.terremoto, 8)
			trovoes.remove_at(k)


# DRAW END: tempestade por cima do mundo
func ev_draw_end() -> void:
	var vx := G.view_x
	var vy := G.view_y
	var vw := G.view_w
	var vh := G.view_h
	var flash := 0.0
	if relampago > 0:
		var p := 1 - relampago / relampago_max
		if p < 0.12:
			flash = 1
		elif p < 0.22:
			flash = 0.25
		elif p < 0.34:
			flash = 0.85
		else:
			flash = maxf(0, 1 - (p - 0.34) / 0.66) * 0.6
	draw_set_alpha(0.26 * (1 - flash * 0.8))
	draw_set_color(Color8(14, 18, 40))
	draw_rectangle(vx - 4, vy - 4, vx + vw + 4, vy + vh + 4, false)
	if chao_y >= 0:
		retangulo_gradiente(vx - 4, chao_y - 110, vx + vw + 4, chao_y + 12, Color8(120, 130, 160), 0, Color8(120, 130, 160), 0.24)
	# as gotas de cada camada vão numa chamada só
	var pen: Pen = G.pen
	var pts_l := PackedVector2Array()
	var cs_l := PackedColorArray()
	var pts_p := PackedVector2Array()
	var cs_p := PackedColorArray()
	var c_longe := Color8(165, 185, 225)
	var c_perto := Color8(205, 220, 250)
	for i in n_gotas:
		var x0 := gx[i]
		var y0 := gy[i]
		var comp := gcomp[i]
		if gperto[i] == 1:
			pts_p.append(Vector2(x0, y0))
			pts_p.append(Vector2(x0 - vento * 1.3 / gvel[i] * comp, y0 - comp))
			cs_p.append(pen.cor(c_perto, minf(1, ga[i] * (1 + flash * 0.5))))
		else:
			pts_l.append(Vector2(x0, y0))
			pts_l.append(Vector2(x0 - vento / gvel[i] * comp, y0 - comp))
			cs_l.append(pen.cor(c_longe, ga[i] * (1 + flash * 0.6)))
	pen.multilinha(pts_l, cs_l, 1.0)
	pen.multilinha(pts_p, cs_p, 1.4)
	var pts_r := PackedVector2Array()
	var cs_r := PackedColorArray()
	var c_resp := Color8(205, 220, 245)
	for s in respingos:
		var q: float = s.t / 12.0
		var k := 1.5 if s.g else 1.0
		var cr := pen.cor(c_resp, 0.65 * (1 - q))
		var d := (3 + 3 * q) * k
		pts_r.append(Vector2(s.x, s.y))
		pts_r.append(Vector2(s.x - d, s.y - d))
		pts_r.append(Vector2(s.x, s.y))
		pts_r.append(Vector2(s.x + d, s.y - d))
		cs_r.append(cr)
		cs_r.append(cr)
	pen.multilinha(pts_r, cs_r, 1.0)
	draw_set_color(c_resp)
	for s in respingos:
		if s.g:
			draw_set_alpha(0.65 * (1 - s.t / 12.0))
			var q2: float = s.t / 12.0
			draw_ellipse(s.x - 4 * q2 - 1, s.y - 1, s.x + 4 * q2 + 1, s.y + 1, true)
	if flash > 0:
		gpu_set_blendmode(bm_add)
		draw_set_alpha(flash * 0.5)
		draw_set_color(Color8(190, 205, 255))
		draw_rectangle(vx - 4, vy - 4, vx + vw + 4, vy + vh + 4, false)
		if flash > 0.5 and raio.size() > 1:
			draw_set_alpha(0.35 * flash)
			draw_set_color(Color8(140, 160, 255))
			for k2 in raio.size() - 1:
				draw_line_width(raio[k2][0], raio[k2][1], raio[k2 + 1][0], raio[k2 + 1][1], 7)
			draw_set_alpha(flash)
			draw_set_color(Color8(240, 245, 255))
			for k3 in raio.size() - 1:
				draw_line_width(raio[k3][0], raio[k3][1], raio[k3 + 1][0], raio[k3 + 1][1], 2.2)
			draw_set_alpha(flash * 0.8)
			for gl in galhos:
				for m in gl.size() - 1:
					draw_line_width(gl[m][0], gl[m][1], gl[m + 1][0], gl[m + 1][1], 1.2)
		gpu_set_blendmode(bm_normal)
	desenho_resetar()
