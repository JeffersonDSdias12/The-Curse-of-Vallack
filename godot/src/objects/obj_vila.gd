extends Lib
# =====================================================================
#  obj_vila — o CENÁRIO da Fase 1 (a vila em chamas), desenhado por código
#  A arte vem de ferramentas/gerar_cenario.ps1 (atlas + JSON com as
#  âncoras dos efeitos), a mesma da versão PC. Duas instâncias, criadas
#  pelo sala_preparar():
#   camada "longe" (prof. 405): céu, lua, nuvens, montanhas, floresta e a
#      vila ao longe, com profundidade (parallax)
#   camada "perto" (prof. 396): casas, igreja, torre, ponte, barracas...
#      com o fogo, a fumaça e as janelas presos a cada peça; o muro da
#      frente e o chão
#  O clima de guerra (obj_guerra, 397) fica entre as duas. O som do fogo
#  aumenta perto das casas em chamas, do fogo no chão, das vigas e tochas.
# =====================================================================

var camada := "perto"           # o sala_preparar troca para "longe" na instância do fundo
var t := 0.0
var ok := false
var pecas: Dictionary = {}
var layout: Array = []
var emissao: Array = []
var frente: Array = []
var vaos: Array = []            # v1.20: vãos das pontes que desabam (sem muro/cerca e sem a ponte de enfeite)

const VILA_FX_MARGEM := 140.0   # px além da câmera em que as casas ainda soltam fumaça/brasas
const VILA_FX_TETO := 260       # partículas de ambiente no máximo (v1.19: era 380; busca dos 60 FPS)


func ev_create() -> void:
	ok = cenario_carregar()
	if not ok:
		return
	pecas = cen["pecas"]
	layout = cen["layout"]
	vaos = terreno_dados(G.room).get("pontes_queda", [])
	emissao.resize(layout.size())
	emissao.fill(0.0)
	# faixa da frente: muro de pedra, cerca e sebes alternados pela fase toda
	var x := -40.0
	var k := 0
	while x < G.room_width + 100:
		var hh := (k * 7919 + 13) % 10
		var nome := "muro" if hh < 4 else ("cerca" if hh < 7 else "sebe")
		frente.append([nome, x])
		x += float(pecas[nome]["w"]) - (12.0 if nome == "sebe" else 0.0) + (28.0 if hh == 9 else 0.0)
		k += 1


func ev_step() -> void:
	t += G.dt
	if not ok or camada != "perto":
		return
	var pl = instance_find("obj_player", 0)
	var px: float = pl.x if pl != null else -10000.0
	var dist_fogo := 100000.0
	var q := maxf(0.5, G.cfg_qualidade)
	# v1.18: TRAVADAS — a fumaça e as brasas das casas chegavam a ~1000 partículas
	# vivas (casas a até 700 px do herói emitiam mesmo fora da tela). Agora só
	# emitem as casas perto da câmera, e o lote de ambiente tem um teto.
	var emite_x1 := G.view_x - VILA_FX_MARGEM
	var emite_x2 := G.view_x + G.view_w + VILA_FX_MARGEM
	var lote = G.fx_lotes.get(395)
	var cheio: bool = lote != null and not lote._destruido and lote.parts.size() >= VILA_FX_TETO
	for i in layout.size():
		var l: Array = layout[i]
		var p: Dictionary = pecas[l[0]]
		var lx: float = l[1]
		var s: float = float(l[6]) if l.size() > 6 else 1.0     # v1.17: escala da peça
		var d := absf(lx + float(p["w"]) * s / 2.0 - px)
		if int(l[3]) == 1:
			dist_fogo = minf(dist_fogo, d + 100)
		if d > 700:
			continue
		var cx := lx + float(p["w"]) * s / 2.0
		if cheio or cx < emite_x1 or cx > emite_x2:
			continue
		var plano := int(l[5]) if l.size() > 5 else 0
		if plano >= 2:
			continue          # fileira mais distante: só o fogo desenhado (economia)
		emissao[i] -= G.dt
		if emissao[i] > 0:
			continue
		emissao[i] = randi_range(10, 18) / q * (2.0 if plano == 1 else 1.0)
		var y0: float = float(l[2]) - float(p["h"]) * s
		var esp := int(l[4]) == 1
		# fumaça saindo das chaminés de verdade de cada casa
		var ch: Array = p["chamines"]
		if ch.size() > 0 and randf() < 0.7:
			var c: Array = ch[randi_range(0, ch.size() - 1)]
			fx_em("fumaca", cenario_ax(p, lx, esp, c[0], s), y0 + float(c[1]) * s, (1.1 if int(l[3]) > 0 else 0.6) * s, 1, 395)
		# v1.19: casa em chamas: as brasas sobem de um dos focos de verdade e os
		# rombos soltam fumaça; ruína: brasas e fumaça dos escombros
		var fg: Array = p["fogos"]
		var fcs: Array = p.get("focos", [])
		if int(l[3]) == 1 and not fcs.is_empty():
			var fo: Array = fcs[randi_range(0, fcs.size() - 1)]
			var u := randf()
			var bx := cenario_ax(p, lx, esp, lerpf(float(fo[0]), float(fo[2]), u), s)
			var by: float = y0 + (float(fo[1]) if int(fo[5]) == 2 else lerpf(float(fo[1]), float(fo[3]), u)) * s - float(fo[4]) * s * 0.5
			if randf() < 0.7:
				fx_em("brasas", bx, by, 0.8 * s, 1, 395)
			if int(fo[5]) == 1 and randf() < 0.5:
				fx_em("fumaca", bx, by - 10 * s, s, 1, 395)
		elif int(l[3]) > 0 and fg.size() > 0:
			var f: Array = fg[0]
			var fx := cenario_ax(p, lx, esp, f[0], s)
			var fl: float = float(f[2]) * s
			if randf() < 0.7:
				fx_em("brasas", fx + randf_range(-fl * 0.4, fl * 0.4), y0 + float(f[1]) * s, 0.8 * s, 1, 395)
			if int(l[3]) == 2 and randf() < 0.6:
				fx_em("fumaca", fx + randf_range(-fl * 0.3, fl * 0.3), y0 + (float(f[1]) + 4) * s, s, 1, 395)
	# som do fogo: mais alto perto das casas queimando e do fogo no chão
	for f in todos("obj_fogo_chao"):
		dist_fogo = minf(dist_fogo, absf(f.x - px))
	for v in todos("obj_viga_fogo"):
		if v.estado == "queimando":
			dist_fogo = minf(dist_fogo, absf(v.x - px))
	for tc in todos("obj_tocha"):
		if tc.acesa:
			dist_fogo = minf(dist_fogo, absf(tc.x - px) + 140)
	ambiente("amb_fogo", clampf(1 - (dist_fogo - 60) / 460.0, 0, 1) * 0.7)


func ev_draw() -> void:
	if not ok:
		return
	var pen: Pen = G.pen
	var vx := G.view_x
	var vy := G.view_y
	var vw := G.view_w
	var vh := G.view_h
	var dy := vy - (G.room_height - vh)     # 0 com a câmera no chão (o horizonte não muda com o zoom)
	var filtro := pen.filtro
	pen.filtro = false            # pixel art nítida
	if camada == "longe":
		_desenhar_longe(pen, vx, vy, vw, vh, dy)
	else:
		_desenhar_perto(pen, vx, vw)
	pen.filtro = filtro


# céu, lua, nuvens, montanhas, floresta e a vila ao longe
func _desenhar_longe(pen: Pen, vx: float, vy: float, vw: float, vh: float, dy: float) -> void:
	var c1 := Color8(24, 18, 36)
	var c2 := Color8(76, 52, 76)
	var c3 := Color8(146, 102, 106)
	pen.retangulo_cores(vx - 2, vy - 2, vx + vw + 2, vy + vh * 0.42, c1, c1, c2, c2, 1.0)
	pen.retangulo_cores(vx - 2, vy + vh * 0.42, vx + vw + 2, vy + vh + 2, c2, c2, c3, c3, 1.0)
	# lua cheia com o halo
	var lx := vx + vw * 0.76
	var ly := vy + vh * 0.15
	pen.blend_add = true
	for k in range(1, 5):
		pen.circulo(lx, ly, 11 + k * 9, Color8(200, 170, 170), 0.05, false)
	pen.blend_add = false
	pen.circulo(lx, ly, 11, Color8(234, 224, 204), 1.0, false)
	pen.circulo(lx - 3, ly - 2, 2.5, Color8(204, 192, 176), 1.0, false)
	pen.circulo(lx + 4, ly + 3, 2, Color8(204, 192, 176), 1.0, false)
	pen.circulo(lx + 1, ly - 5, 1.5, Color8(204, 192, 176), 1.0, false)
	# camadas com profundidade
	cenario_faixa(pecas["nuvens"], vx, vw, 0.06, vy + vh * 0.28, t * 0.12)
	cenario_faixa(pecas["montanhas"], vx, vw, 0.1, 606 + dy * 0.8)
	cenario_faixa(pecas["floresta"], vx, vw, 0.3, 652 + dy * 0.65)
	cenario_faixa(pecas["vila_longe"], vx, vw, 0.55, 672 + dy * 0.45)
	if not G.cenario_economico:
		_incendios_longe(pen, vx, vw, 672 + dy * 0.45)


# v1.14: o reino ardendo ao longe: o brilho dos incêndios nos escombros da faixa
# distante e colunas de fumaça subindo (sem fumaça na qualidade baixa)
func _incendios_longe(pen: Pen, vx: float, vw: float, yb: float) -> void:
	var p: Dictionary = pecas["vila_longe"]
	var fg: Array = p["fogos"]
	if fg.is_empty():
		return
	var w: float = p["w"]
	var y0: float = yb - float(p["h"])
	var ox := vx * (1 - 0.55)
	var x := ox + floorf((vx - ox) / w) * w - w
	var q := G.cfg_qualidade
	while x < vx + vw + 60:
		for j in fg.size():
			var f: Array = fg[j]
			var fx: float = x + float(f[0])
			if fx < vx - 60 or fx > vx + vw + 60:
				continue
			var fy: float = y0 + float(f[1])
			var fw: float = f[2]
			var sem := float(j) * 3.7
			var fl := 0.7 + 0.3 * sin(t * 0.09 + sem) * sin(t * 0.031 + sem * 2.0)
			pen.blend_add = true
			pen.elipse(fx - fw * 0.9, fy - 7, fx + fw * 0.9, fy + 5, Color8(255, 96, 36), 0.16 * fl, false)
			pen.elipse(fx - fw * 0.4, fy - 3, fx + fw * 0.4, fy + 2, Color8(255, 170, 80), 0.18 * fl, false)
			pen.blend_add = false
			# coluna de fumaça (uma a cada duas fogueiras; mais alta na qualidade alta)
			if q > 0 and j % 2 == 0:
				var n := 6 if q == 1 else 10
				var alt := 150.0 if q == 1 else 210.0
				for k in n:
					var fase := fposmod(t * 0.22 + k * alt / n + sem * 40.0, alt)
					var a := 0.3 * (1.0 - fase / alt) * minf(1.0, fase / 18.0)
					var cor := Color8(132, 66, 44) if fase < 26 else Color8(64, 54, 62)     # a base iluminada pelo fogo
					pen.circulo(fx + fase * 0.16 + sin(t * 0.02 + k + sem) * 3.0, fy - 6 - fase, 5.0 + fase * 0.12, cor, a, false)
		x += w


# a vila de verdade, com os efeitos presos a cada peça
func _desenhar_perto(pen: Pen, vx: float, vw: float) -> void:
	# terra escura atrás das casas (liga a vila ao longe ao chão)
	pen.retangulo(vx - 2, 641, vx + vw + 2, 700, Color8(24, 26, 26), 1.0, false)
	var tt := current_time() / 16.0
	for i in layout.size():
		var l: Array = layout[i]
		var p: Dictionary = pecas[l[0]]
		var x: float = l[1]
		var b: float = l[2]
		var q := int(l[3])
		var esp := int(l[4]) == 1
		var plano := int(l[5]) if l.size() > 5 else 0     # fileiras de trás: mais escuras (3 = a mais ao fundo)
		var atras := plano > 0
		var s: float = float(l[6]) if l.size() > 6 else 1.0     # v1.17: escala (casas 2x, o resto 1,5x)
		var w: float = float(p["w"]) * s
		if x > vx + vw + 30 or x + w < vx - 30:
			continue
		if plano >= 2 and G.cenario_economico:
			continue          # nível MÍNIMO: sem as fileiras do fundo
		if l[0] == "ponte" and not vaos.is_empty():
			continue          # v1.20: a ponte de pedra agora é de verdade e desaba (obj_terreno)
		var y0: float = b - float(p["h"]) * s
		var sem := i * 7.3
		var pisca := 0.75 + 0.25 * sin(tt / 4.0 + sem) * sin(tt / 9.3 + sem * 2)
		# o rio passa por baixo da ponte
		if l[0] == "ponte":
			var ry := b - 18
			pen.retangulo(x - 30, ry, x + w + 30, b + 8, Color8(28, 38, 58), 1.0, false)
			pen.blend_add = true
			for k in 9:
				var wx := x - 20 + fposmod(k * 0.37 + tt * 0.004 * (1 + k % 3), 1.0) * (w + 40)
				var wy := ry + 4 + (k % 4) * 4
				pen.linha(wx, wy, wx + 8 + (k % 3) * 4, wy, Color8(90, 110, 150), 0.25)
			pen.blend_add = false
		# incêndio: a luz roxa da maldição sobe do telhado (v1.19: presa ao telhado,
		# não mais um oval em volta da casa inteira)
		if q == 1:
			pen.blend_add = true
			pen.elipse(x - w * 0.1, y0 - 34 * s, x + w * 1.1, y0 + float(p["h"]) * s * 0.55, Color8(140, 40, 255), 0.12 * pisca, false)
			pen.blend_add = false
		var tom := Color.WHITE
		if plano == 3:
			tom = Color8(62, 54, 76)
		elif plano == 2:
			tom = Color8(84, 74, 96)
		elif atras:
			tom = Color8(128, 116, 132)
		cenario_peca(p, x, b, esp, tom, s)
		# v1.14: ruína fumegante: brasas brilhando no meio dos escombros
		if q == 2:
			var fgr: Array = p["fogos"]
			if fgr.size() > 0:
				var gx := cenario_ax(p, x, esp, fgr[0][0], s)
				var gy: float = y0 + float(fgr[0][1]) * s
				var gw: float = float(fgr[0][2]) * s
				pen.blend_add = true
				pen.elipse(gx - gw * 0.6, gy - 6 * s, gx + gw * 0.6, gy + 8 * s, Color8(255, 90, 30), (0.1 if atras else 0.14) * pisca, false)
				pen.blend_add = false
		pen.blend_add = true
		# janelas acesas tremeluzindo (roxo-alaranjado nas casas em chamas)
		var jan: Array = p["janelas"]
		for j in jan.size():
			var jw: Array = jan[j]
			var jx: float = x + (float(p["w"]) - float(jw[0]) - float(jw[2])) * s if esp else x + float(jw[0]) * s
			var fl := 0.7 + 0.3 * sin(tt / (3 + j) + sem + j * 2)
			var cj := Color8(220, 110, 255) if q == 1 else Color8(255, 170, 70)
			pen.retangulo(jx - 2 * s, y0 + (float(jw[1]) - 2) * s, jx + (float(jw[2]) + 1) * s, y0 + (float(jw[1]) + float(jw[3]) + 1) * s, cj, (0.45 if q == 1 else 0.22) * fl, false)
		# lampiões, lanternas e vitrais: halo de luz
		var lz: Array = p["luzes"]
		for j in lz.size():
			var lzx := cenario_ax(p, x, esp, lz[j][0], s)
			var lzy: float = y0 + float(lz[j][1]) * s
			var r: float = float(lz[j][2]) * s
			var fl2 := 0.8 + 0.2 * sin(tt / 5.0 + j + sem)
			var cl := Color8(200, 120, 255) if l[0] == "igreja" else Color8(255, 170, 80)
			pen.circulo(lzx, lzy, r, cl, 0.07 * fl2, false)
			pen.circulo(lzx, lzy, r * 0.5, cl, 0.12 * fl2, false)
		pen.blend_add = false
		# chamas da maldição presas à construção (v1.19): saem dos rombos e das
		# janelas quebradas, correm pelo cume e por uma das águas, ardem nos escombros
		# v1.19 (60 FPS no celular): o fogo das fileiras do fundo depende da qualidade
		# (fileira 3 só na ALTA, fileira 2 da MÉDIA para cima); a arte queimada e o
		# brilho roxo continuam contando o incêndio
		if q == 1 and plano <= G.cfg_qualidade + 1:
			var forca: float = [0.9, 0.65, 0.5, 0.4][plano]
			# só a fileira da frente leva a camada do meio; as do fundo, o mínimo
			var lod := 2 if plano >= 2 else (1 if plano == 1 or G.cfg_qualidade == 0 else 0)
			var fc: Array = p.get("focos", [])
			if not fc.is_empty():
				for j in fc.size():
					var f: Array = fc[j]
					var tipo := int(f[5])
					if plano >= 2 and tipo == 2:
						continue          # fileiras do fundo: o incêndio se lê pelos rombos e telhados (economia)
					chamas_linha(cenario_ax(p, x, esp, f[0], s), y0 + float(f[1]) * s, cenario_ax(p, x, esp, f[2], s), y0 + float(f[3]) * s,
						float(f[4]) * s * (0.8 if tipo == 1 else 1.0), tt + sem * 10 + j * 17, forca, sem + j * 3.1, 0, tipo, s, lod)
			else:
				var fg: Array = p["fogos"]
				for j in fg.size():
					var fx := cenario_ax(p, x, esp, fg[j][0], s)
					var fw: float = float(fg[j][2]) * s
					desenhar_chamas(fx, y0 + float(fg[j][1]) * s, fw, (22 + float(fg[j][2]) * 0.25) * s, tt + sem * 10, forca, sem)
	# muro, cerca e sebes da frente
	for f in frente:
		var fp: Dictionary = pecas[f[0]]
		var fx2: float = f[1]
		if fx2 > vx + vw or fx2 + float(fp["w"]) < vx:
			continue
		var no_vao := false
		for v in vaos:
			if fx2 + float(fp["w"]) > v[0] and fx2 < v[1]:
				no_vao = true
		if no_vao:
			continue          # v1.20: nada de muro flutuando sobre a ravina
		cenario_peca(fp, fx2, 680, false)     # v1.13: borda de trás da rua (o pé pisa dentro do calçamento)
	# v1.20: terra escura abaixo da rua (aparece quando a câmera desce nas pontes)
	pen.retangulo(vx - 2, 750, vx + vw + 2, G.room_height + 260, Color8(18, 14, 16), 1.0, false)
	# chão calçado (repete pela fase toda)
	var chp: Dictionary = pecas["chao"]
	var cw: float = chp["w"]
	var cx := floorf(vx / cw) * cw
	while cx < vx + vw:
		cenario_peca(chp, cx, 675 + float(chp["h"]), false)
		cx += cw
