extends Lib
# =====================================================================
#  obj_cenario — fundo da Fase 2 (O Salão Real em Ruínas)
#  A arte do salão (tiles "fundo") cobre só a faixa y = 464..688 da sala.
#  Este objeto preenche o resto da tela (salão distante, teto e piso).
# =====================================================================

var banda_topo := 464.0
var banda_base := 688.0
var chao_y := 682.0
var brasas: Array = []
var castelo: Array = []         # arte do salão em alta resolução (duas metades)


func ev_create() -> void:
	if ResourceLoader.exists("res://assets/data/castelo_a.png") and ResourceLoader.exists("res://assets/data/castelo_b.png"):
		castelo = [load("res://assets/data/castelo_a.png"), load("res://assets/data/castelo_b.png")]


func ev_step() -> void:
	var dt := G.dt
	var vx := G.view_x
	var vw := G.view_w
	var maximo := 0 if G.cfg_qualidade == 0 else (18 if G.cfg_qualidade == 1 else 36)
	if brasas.size() < maximo and randf() < 0.25 * dt:
		brasas.append({"x": randf_range(vx, vx + vw), "y": banda_base - randf() * 40, "vx": randf_range(-0.25, 0.25),
			"vy": randf_range(-0.7, -0.25), "vida": float(randi_range(160, 320)), "vmax": 320.0})
	for i in range(brasas.size() - 1, -1, -1):
		var b: Dictionary = brasas[i]
		b.x += (b.vx + sin(current_time() / 600.0 + i) * 0.15) * dt
		b.y += b.vy * dt
		b.vida -= dt
		if b.vida <= 0 or b.y < banda_topo - 160:
			brasas.remove_at(i)


# Desenha ATRÁS da arte do salão (profundidade 450; tiles "fundo" = 400)
func ev_draw() -> void:
	var vx := G.view_x
	var vy := G.view_y
	var vw := G.view_w
	var vh := G.view_h
	var x1 := vx - 4
	var x2 := vx + vw + 4
	var y2 := vy + vh + 4
	draw_set_alpha(1)
	draw_set_color(Color8(10, 6, 8))
	draw_rectangle(x1, vy - 4, x2, y2, false)
	# salão distante: a mesma arte ampliada e escurecida, com paralaxe
	var esc := 1.7
	var sw := Spr.spr_fundo_fase2.w * esc
	var base := banda_topo + 150
	var off := vx * 0.6
	var k0 := int(floor((x1 - off) / sw)) - 1
	var k1 := int(ceil((x2 - off) / sw)) + 1
	for k in range(k0, k1 + 1):
		if castelo.size() == 2:
			# v1.13: a arte nova do castelo também no salão distante (sem borrão)
			var hd := Spr.spr_fundo_fase2.h * esc
			var xd := off + k * sw - sw / 2.0
			var filtro_d := G.pen.filtro
			G.pen.filtro = true
			G.pen.textura(castelo[0], xd, base - hd, sw / 2.0, hd, Color8(92, 66, 70), 1.0)
			G.pen.textura(castelo[1], xd + sw / 2.0, base - hd, sw / 2.0, hd, Color8(92, 66, 70), 1.0)
			G.pen.filtro = filtro_d
		else:
			draw_sprite_ext(Spr.spr_fundo_fase2, 0, off + k * sw, base, esc, esc, 0, Color8(92, 66, 70), 1)
	# escuridão do teto
	retangulo_gradiente(x1, vy - 4, x2, banda_topo, Color8(6, 3, 5), 0.88, Color8(30, 12, 14), 0.35)
	# v1.13: o salão em alta resolução (Castelo do Alex, duas metades), no lugar
	# dos tiles antigos; repete a cada 1616 px como eles
	if castelo.size() == 2:
		var pen: Pen = G.pen
		var filtro := pen.filtro
		pen.filtro = true
		var per := 1616.0
		var alt := banda_base - banda_topo
		var k := floorf(x1 / per)
		while k * per < x2:
			pen.textura(castelo[0], k * per, banda_topo, per / 2.0, alt, Color.WHITE, 1.0)
			pen.textura(castelo[1], k * per + per / 2.0, banda_topo, per / 2.0, alt, Color.WHITE, 1.0)
			k += 1
		pen.filtro = filtro
	# piso de pedra abaixo da arte
	var cor_piso := Color8(150, 112, 118)
	var src_y := 590.0
	var src_h := 86.0
	var src_w := Spr.spr_fundo.w
	var pe := 0.65
	var tw := src_w * pe
	var j0 := int(floor(x1 / tw))
	var j1 := int(ceil(x2 / tw))
	draw_set_color(Color8(14, 10, 12))
	draw_rectangle(x1, chao_y, x2, y2, false)
	for j in range(j0, j1 + 1):
		draw_sprite_part_ext(Spr.spr_fundo, 0, 0, src_y, src_w, src_h, j * tw, chao_y, pe, pe, cor_piso, 1)
	retangulo_gradiente(x1, chao_y + 6, x2, y2, c_black, 0, c_black, 0.75)
	desenho_resetar()


# DRAW END: por cima da arte do salão, só na parte alta
func ev_draw_end() -> void:
	var vx := G.view_x
	var vw := G.view_w
	var x1 := vx - 4
	var x2 := vx + vw + 4
	retangulo_gradiente(x1, banda_topo - 2, x2, banda_topo + 34, Color8(10, 4, 6), 0.7, Color8(10, 4, 6), 0)
	gpu_set_blendmode(bm_add)
	for b in brasas:
		var a := clampf(b.vida / b.vmax, 0, 1) * 0.8
		draw_set_alpha(a)
		draw_set_color(Color8(255, 120, 40))
		draw_circle(b.x, b.y, 1.4, false)
		draw_set_alpha(a * 0.3)
		draw_circle(b.x, b.y, 3.5, false)
	gpu_set_blendmode(bm_normal)
	desenho_resetar()
