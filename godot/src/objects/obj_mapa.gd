extends Lib
# =====================================================================
#  obj_mapa — O MAPA DE VALLACK (v1.17): escolha da fase e da dificuldade
#  Um caminho em chamas liga as 18 fases. Só a primeira está aberta; as
#  outras têm cadeado e "EM DESENVOLVIMENTO". Na última, o covil do chefão,
#  o dragão voa ao lado. Cada fase tem nome, descrição e a foto do cenário
#  (mapa_fases.jpg: 6 x 3 fotos de 320 x 180, ferramentas/gerar_mapa.ps1).
#  Deslize com o dedo (ou arraste o mouse); toque numa fase para escolher e
#  toque de novo (ou em JOGAR) para jogar. ◄ ► / ▲ ▼ no controle e teclado.
#  Criado pelo obj_menu (NOVO JOGO). O mesmo da versão PC.
# =====================================================================

const FOTO_W := 236.0
const FOTO_H := 133.0
const GAP := 330.0

var fases: Array = []
var n := 0
var sel := 0
var dif := 1
var t := 0.0
var entrada := 0.0
var saindo := -1.0
var arrastando := false
var arraste_x0 := 0.0
var arraste_cam0 := 0.0
var arraste_dist := 0.0
var arraste_vel := 0.0
var mouse_ant_x := 0.0
var toque_no := -1
var aviso_txt := ""
var aviso_t := 0.0
var brasas: Array = []
var caminho: Array = []
var mundo_w := 0.0
var cam_x := 0.0
var cam_alvo := 0.0


func ev_create() -> void:
	V117.transicao_revelar(28)     # v1.19: o mapa surge atrás da cortina em brasa
	fases = V117.fases_mapa()
	n = fases.size()
	dif = G.dificuldade
	if G.img_mapa == null:
		G.img_mapa = imagem_carregar("mapa_fases.jpg")
	mundo_w = no_x(n - 1) + 520
	# o caminho em chamas: curva suave (Catmull-Rom) por baixo das fotos
	var pts: Array = []
	for k in range(-1, n + 1):
		pts.append(Vector2(no_x(k), no_y(clampi(k, 0, n - 1)) + 96))
	for s in range(1, pts.size() - 2):
		var p0: Vector2 = pts[s - 1]
		var p1: Vector2 = pts[s]
		var p2: Vector2 = pts[s + 1]
		var p3: Vector2 = pts[s + 2]
		for k2 in 20:
			var u := k2 / 20.0
			var u2 := u * u
			var u3 := u2 * u
			var p := 0.5 * ((2 * p1) + (-p0 + p2) * u + (2 * p0 - 5 * p1 + 4 * p2 - p3) * u2 + (-p0 + 3 * p1 - 3 * p2 + p3) * u3)
			caminho.append([p.x, p.y, randf() * 100])


func no_x(k: int) -> float:
	return 300 + k * GAP


func no_y(k: int) -> float:
	return 268 + sin(k * 0.95 + 0.6) * 62


func aviso_mapa(txt_aviso: String) -> void:
	aviso_txt = txt_aviso
	aviso_t = 150


func jogar() -> void:
	if not V117.fase_mapa_livre(sel):
		aviso_mapa(str(fases[sel].nome) + " ESTÁ EM DESENVOLVIMENTO")
		som("tit_negado", 0.8, 0)
		return
	G.dificuldade = dif
	som("tit_selecao", 0.9, 0)
	saindo = 0


func ev_step() -> void:
	var dt := G.dt_real
	t += dt
	entrada = minf(1, entrada + dt / 24.0)
	if aviso_t > 0:
		aviso_t -= dt
	var gw := G.gui_w
	var gh := G.gui_h
	# brasas subindo do caminho (só perto da tela)
	var max_b := 20 if G.cfg_qualidade == 0 else (40 if G.cfg_qualidade == 1 else 70)
	if brasas.size() < max_b and randf() < 0.6 * dt:
		var cp: Array = caminho[randi() % caminho.size()]
		if cp[0] > cam_x - 40 and cp[0] < cam_x + gw + 40:
			brasas.append({"x": cp[0] + randf_range(-10, 10), "y": cp[1], "vx": randf_range(-0.4, 0.4), "vy": randf_range(-1.6, -0.5), "v": randf_range(50, 110), "r": randf_range(1, 2.4)})
	for b in range(brasas.size() - 1, -1, -1):
		var br: Dictionary = brasas[b]
		br.x += (br.vx + sin((t + b * 13) / 20.0) * 0.3) * dt
		br.y += br.vy * dt
		br.v -= dt
		if br.v <= 0:
			brasas.remove_at(b)
	# saindo: escurece e começa a fase (o menu cuida do slot e da cutscene)
	if saindo >= 0:
		saindo += dt
		if saindo >= 30:
			var m = instance_find("obj_menu", 0)
			instance_destroy()
			if m != null:
				m.comecar_pelo_mapa()
		return
	var mp := G.mouse_gui()
	var apertou := G.mouse_apertado
	var segura := G.mouse_segurado
	var ok := G.nav_ok
	var voltar := G.nav_voltar
	var sel_antes := sel
	var dif_antes := dif
	if G.nav_esq:
		sel = maxi(0, sel - 1)
	if G.nav_dir:
		sel = mini(n - 1, sel + 1)
	if G.nav_cima:
		dif = (dif + DIF.TOTAL - 1) % DIF.TOTAL
	if G.nav_baixo:
		dif = (dif + 1) % DIF.TOTAL
	if G.roda != 0:
		cam_alvo += G.roda * GAP * 0.8
	var py := gh - 196
	var bj := Rect2(gw - 300, py + 118, 250, 54)
	var bd1 := Rect2(gw - 470, py + 40, 50, 50)
	var bd2 := Rect2(gw - 100, py + 40, 50, 50)
	var bv := Rect2(24, 22, 146, 44)
	var no_painel := mp.y >= py
	if apertou and not no_painel and not bv.has_point(mp):
		arrastando = true
		arraste_x0 = mp.x
		arraste_cam0 = cam_x
		arraste_dist = 0
		arraste_vel = 0
		mouse_ant_x = mp.x
		toque_no = -1
		for k in n:
			var nx := no_x(k) - cam_x
			var ny := no_y(k)
			if absf(mp.x - nx) < FOTO_W / 2 + 10 and mp.y > ny - FOTO_H / 2 - 30 and mp.y < ny + 120:
				toque_no = k
	if arrastando:
		if segura:
			cam_x = arraste_cam0 - (mp.x - arraste_x0)
			arraste_dist = maxf(arraste_dist, absf(mp.x - arraste_x0))
			arraste_vel = lerpf(arraste_vel, -(mp.x - mouse_ant_x), 0.5)
			cam_alvo = cam_x
		else:
			arrastando = false
			if arraste_dist < 12 and toque_no != -1:
				# toque: escolhe a fase; tocar de novo na fase aberta já escolhida = jogar
				if toque_no == sel and V117.fase_mapa_livre(sel):
					jogar()
				else:
					sel = toque_no
			else:
				cam_alvo = cam_x + arraste_vel * 14
		mouse_ant_x = mp.x
	if apertou and no_painel:
		if bj.has_point(mp):
			ok = true
		if bd1.has_point(mp):
			dif = (dif + DIF.TOTAL - 1) % DIF.TOTAL
		if bd2.has_point(mp):
			dif = (dif + 1) % DIF.TOTAL
	if apertou and bv.has_point(mp):
		voltar = true
	if sel != sel_antes:
		som("tit_mover", 0.6, 0.03)
		cam_alvo = no_x(sel) - gw / 2.0
	if dif != dif_antes:
		som("tit_alterar", 0.7, 0.03)
	if voltar and entrada >= 1:
		som("tit_voltar", 0.8, 0.02)
		var mm = instance_find("obj_menu", 0)
		if mm != null:
			mm.mudar_estado("menu", 0, false)
		V117.transicao_revelar(24)     # v1.19: o menu volta atrás da cortina
		instance_destroy()
		return
	if ok and entrada >= 1 and not arrastando:
		jogar()
	var max_cam := maxf(0, mundo_w - gw)
	cam_alvo = clampf(cam_alvo, 0, max_cam)
	if not arrastando:
		cam_x = lerpf(cam_x, cam_alvo, 1 - pow(0.86, dt))
	cam_x = clampf(cam_x, -60, max_cam + 60)


func ev_draw_gui() -> void:
	var gw := G.gui_w
	var gh := G.gui_h
	var pen: Pen = G.pen
	var ouro := Color8(236, 186, 84)
	var tt := t
	var q := G.cfg_qualidade
	# céu de brasa e montanhas ao longe (paralaxe)
	retangulo_gradiente(0, 0, gw, gh, Color8(14, 6, 10), 1, Color8(46, 12, 8), 1)
	pen.blend_add = true
	pen.elipse(-gw * 0.2, gh * 0.42, gw * 1.2, gh * 0.95, Color8(190, 50, 20), 0.22 + 0.05 * sin(tt / 40.0), false)
	pen.blend_add = false
	for cam in 2:
		var par := 0.18 if cam == 0 else 0.4
		var base := 330.0 if cam == 0 else 400.0
		var cor := Color8(28, 10, 14) if cam == 0 else Color8(18, 6, 8)
		pen.prim_comecar(pr_trianglestrip)
		var sx := -40.0
		while sx <= gw + 40:
			var wx := sx + cam_x * par + cam * 900
			var h := 70 + sin(wx * 0.0042) * 44 + sin(wx * 0.0113 + 1.3) * 26 + absf(sin(wx * 0.021)) * 20
			pen.prim_vertice(sx, base - h, cor, 1)
			pen.prim_vertice(sx, gh, cor, 1)
			sx += 40
		pen.prim_terminar()
	# o caminho em chamas
	var vis1 := cam_x - 60
	var vis2 := cam_x + gw + 60
	var np := caminho.size()
	for k in range(1, np):
		var a: Array = caminho[k - 1]
		var b: Array = caminho[k]
		if b[0] < vis1 or a[0] > vis2:
			continue
		pen.linha(a[0] - cam_x, a[1], b[0] - cam_x, b[1], Color8(26, 8, 6), 1, 26)
	pen.blend_add = true
	for k in range(1, np):
		var a: Array = caminho[k - 1]
		var b: Array = caminho[k]
		if b[0] < vis1 or a[0] > vis2:
			continue
		var fl := 0.75 + 0.25 * sin(tt / 6.0 + a[2])
		pen.linha(a[0] - cam_x, a[1], b[0] - cam_x, b[1], Color8(255, 90, 20), 0.55 * fl, 12)
		pen.linha(a[0] - cam_x, a[1], b[0] - cam_x, b[1], Color8(255, 210, 120), 0.7 * fl, 3)
	pen.blend_add = false
	var passo := 6 if q == 0 else 4
	var k3 := 0
	while k3 < np:
		var c: Array = caminho[k3]
		if c[0] >= vis1 and c[0] <= vis2:
			desenhar_chamas(c[0] - cam_x, c[1] + 4, 9, 18 + 8 * sin(tt / 13.0 + c[2]), tt + c[2] * 10, 0.9, c[2], 2)
		k3 += passo
	# as fases
	var esc_foto := FOTO_W / 320.0
	for k in n:
		var nx := no_x(k) - cam_x
		if nx < -FOTO_W or nx > gw + FOTO_W:
			continue
		var ny := no_y(k)
		var livre := V117.fase_mapa_livre(k)
		var e := 1.1 + 0.02 * sin(tt / 12.0) if k == sel else 1.0
		var w := FOTO_W * e
		var h := FOTO_H * e
		var x1 := nx - w / 2
		var y1 := ny - h / 2
		var aa := entrada
		V117.moldura_dourada(x1, y1, x1 + w, y1 + h, aa, (0.6 + 0.4 * sin(tt / 8.0)) if k == sel else 0.0)
		if G.img_mapa != null:
			pen.filtro = true
			pen.textura_parte(G.img_mapa, (k % 6) * 320, (k / 6) * 180, 320, 180, x1, y1, esc_foto * e, esc_foto * e, Color.WHITE if livre else Color8(175, 165, 168), aa)
			pen.filtro = false
		else:
			pen.retangulo(x1, y1, x1 + w, y1 + h, Color8(30, 14, 14), aa, false)
		if not livre:
			pen.retangulo(x1, y1, x1 + w, y1 + h, Color.BLACK, 0.28 * aa, false)
			V117.cadeado_grande(nx, ny - 18, 1.2 * e, aa)
			txt_sombra(nx, ny + 36 * e, "EM DESENVOLVIMENTO", FONTE.MINI, Color8(255, 196, 150), aa, fa_center, fa_middle)
		else:
			txt_sombra(nx, y1 + h - 14, "DISPONÍVEL", FONTE.MINI, Color8(140, 255, 140), aa * (0.7 + 0.3 * sin(tt / 10.0)), fa_center, fa_middle)
		var my := ny + 96
		pen.circulo(nx, my, 19, Color8(30, 12, 8), aa, false)
		pen.circulo(nx, my, 19, ouro if livre else Color8(150, 120, 90), aa, true)
		pen.circulo(nx, my, 16, ouro if livre else Color8(150, 120, 90), aa, true)
		var rm := V117.romano(k + 1)
		txt(nx, my, rm, FONTE.MINI, ouro if livre else Color8(190, 160, 130), aa, fa_center, fa_middle, minf(1, 26 / maxf(1, txt_largura(rm, FONTE.MINI))))
		var nome: String = fases[k].nome
		txt_sombra(nx, y1 - 18, nome, FONTE.MINI, Color.WHITE if k == sel else Color8(210, 190, 180), aa, fa_center, fa_middle, minf(1, (FOTO_W + 50) / maxf(1, txt_largura(nome, FONTE.MINI))))
	# o dragão voando ao lado da última fase (o covil do chefão)
	var dxn := no_x(n - 1) - cam_x
	if dxn > -400 and dxn < gw + 400:
		var ang := tt * 0.018
		var drx := dxn + 250 + sin(ang) * 95
		var dry := no_y(n - 1) - 10 + sin(ang * 2) * 44
		var ddir := 1.0 if cos(ang) >= 0 else -1.0
		var ciclo := fmod(tt, 420.0)
		var fogo := sin(PI * (ciclo - 330) / 90.0) if ciclo > 330 else 0.0
		pen.blend_add = true
		pen.circulo(drx, dry, 120, Color8(255, 60, 20), 0.22, false)
		pen.circulo(drx, dry, 60, Color8(255, 60, 20), 0.18, false)
		pen.blend_add = false
		V117.dragao_desenhar(drx, dry, 1.7, ddir, tt, fogo)
	# brasas
	pen.blend_add = true
	for item in brasas:
		var br: Dictionary = item
		pen.circulo(br.x - cam_x, br.y, br.r, Color8(255, 150, 50), clampf(br.v / 50.0, 0, 1) * 0.9, false)
	pen.blend_add = false
	# topo: título e VOLTAR
	retangulo_gradiente(0, 0, gw, 96, Color.BLACK, 0.85, Color.BLACK, 0)
	txt_sombra(gw / 2.0, 36, "MAPA DE VALLACK", FONTE.MEDIA, ouro, entrada, fa_center, fa_middle)
	txt(gw / 2.0, 68, ("Toque numa fase  ·  deslize para ver o caminho" if G.usando_toque else "Escolha a fase e a dificuldade   ·   arraste para ver o caminho"), FONTE.MINI, Color8(210, 190, 180), entrada, fa_center, fa_middle)
	hud_faixa(24, 22, 170, 66, 0.9 * entrada)
	txt(97, 44, "VOLTAR", FONTE.MINI, Color.WHITE, entrada, fa_center, fa_middle)
	# painel de baixo: a fase escolhida, a dificuldade e JOGAR
	var py := gh - 196
	retangulo_gradiente(0, py - 30, gw, gh, Color.BLACK, 0, Color.BLACK, 0.92)
	hud_faixa(30, py, gw - 30, gh - 16, 0.95 * entrada)
	var f: Dictionary = fases[sel]
	var livre_sel := V117.fase_mapa_livre(sel)
	txt(64, py + 30, "FASE " + V117.romano(sel + 1), FONTE.MINI, ouro, entrada, fa_left, fa_middle)
	var larg_txt := gw - 64 - 520
	txt_sombra(64, py + 62, f.nome, FONTE.MEDIA, Color.WHITE, entrada, fa_left, fa_middle, minf(1, larg_txt / maxf(1, txt_largura(f.nome, FONTE.MEDIA))))
	txt_bloco(64, py + 92, f.desc, FONTE.MINI, Color8(220, 205, 195), entrada, larg_txt, fa_left, fa_top)
	if not livre_sel:
		V117.cadeado_grande(78, py + 150, 0.8, entrada)
		txt(104, py + 156, "EM DESENVOLVIMENTO", FONTE.PEQUENA, Color8(255, 170, 120), entrada, fa_left, fa_middle)
	var dcx := gw - 260.0
	txt(dcx, py + 26, "DIFICULDADE", FONTE.MINI, ouro, entrada, fa_center, fa_middle)
	txt(gw - 445, py + 65, "«", FONTE.MEDIA, Color.WHITE, entrada, fa_center, fa_middle)
	txt(gw - 75, py + 65, "»", FONTE.MEDIA, Color.WHITE, entrada, fa_center, fa_middle)
	txt_sombra(dcx, py + 65, dificuldade_nome(dif), FONTE.MEDIA, dificuldade_cor(dif), entrada, fa_center, fa_middle)
	var dd: Array = dificuldade_descricao(dif)
	txt(dcx, py + 98, dd[0], FONTE.MINI, Color8(200, 185, 175), entrada, fa_center, fa_middle, minf(1, 360 / maxf(1, txt_largura(dd[0], FONTE.MINI))))
	var bj := Rect2(gw - 300, py + 118, 250, 54)
	var pul := 0.75 + 0.25 * sin(tt / 9.0)
	pen.retangulo_arredondado(bj.position.x, bj.position.y, bj.end.x, bj.end.y, 10, 10, Color8(120, 20, 14) if livre_sel else Color8(50, 40, 40), entrada, false)
	pen.retangulo_arredondado(bj.position.x, bj.position.y, bj.end.x, bj.end.y, 10, 10, merge_color(ouro, Color.WHITE, 0.2 * pul) if livre_sel else Color8(110, 100, 96), entrada, true)
	txt_sombra(bj.get_center().x, bj.get_center().y, "JOGAR" if livre_sel else "TRANCADA", FONTE.PEQUENA, Color.WHITE if livre_sel else Color8(170, 160, 156), entrada, fa_center, fa_middle)
	if aviso_t > 0:
		txt_sombra(gw / 2.0, py - 26, aviso_txt, FONTE.PEQUENA, Color8(255, 160, 120), clampf(aviso_t / 20.0, 0, 1), fa_center, fa_middle, minf(1, (gw - 80) / maxf(1, txt_largura(aviso_txt, FONTE.PEQUENA))))
	# v1.19: a entrada é revelada pelo véu (V117.transicao_revelar no create); ao
	# jogar, a cortina em brasa fecha a tela da esquerda para a direita
	if saindo >= 0:
		var ks := clampf(saindo / 30.0, 0, 1)
		V117.transicao_cortina_desenhar(ks * ks * (3 - 2 * ks))
	desenho_resetar()
