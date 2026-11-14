extends Lib
# =====================================================================
#  obj_perfil — PERFIL, CONQUISTAS E RECOMPENSAS (v1.17)
#  * o NOME de quem joga: aparece só nas conquistas (o herói continua sendo
#    Twilight Vetrus). Na primeira partida (modo "primeiro") ele é pedido
#    antes do mapa; depois muda em PERFIL > ALTERAR NOME.
#  * abas: CONQUISTAS (as 21, com a data), LÂMINAS (estilos de efeito da
#    espada ganhos nas conquistas) e PERFIL (nome, título e números)
#  * teclado na tela (toque / controle / mouse) e o teclado de verdade
#  Criado pelo obj_menu. O mesmo da versão PC.
# =====================================================================

const TECLAS := ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J",
	"K", "L", "M", "N", "O", "P", "Q", "R", "S", "T",
	"U", "V", "W", "X", "Y", "Z", "Ç", "Ã", "É", "Í",
	"0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
	"ESPAÇO", "APAGAR", "PRONTO"]
const VALIDAS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ÇÃÉÍÁÓÚÂÊÔÕ"

var modo := "perfil"       # "perfil" (do menu) ou "primeiro" (antes do mapa)
var estado := "abas"       # abas | nome
var aba := 0               # 0 CONQUISTAS, 1 LÂMINAS, 2 PERFIL
var sel := 0
var rolagem := 0.0
var rolagem_alvo := 0.0
var t := 0.0
var entrada := 0.0
var iniciado := false
var nome_edit := ""
var tecla_sel := 0
var mensagem := ""
var mensagem_t := 0.0
var arrastando := false
var arraste_y0 := 0.0
var arraste_rol0 := 0.0
var lista: Array = []
var estilos: Array = []


func ev_create() -> void:
	V117.transicao_revelar(24)     # v1.19: o perfil surge atrás da cortina em brasa
	if G.perfil.is_empty():
		V117.perfil_carregar()
	lista = V117.conquistas_lista()
	estilos = V117.espada_estilos()


func tecla_pos(k: int) -> Rect2:
	var gw := G.gui_w
	var kw := 64.0
	var x0 := gw / 2.0 - 5 * (kw + 8) + 4
	if k < 40:
		return Rect2(x0 + (k % 10) * (kw + 8), 330 + (k / 10) * 64, kw, 54)
	var largs := [250.0, 190.0, 210.0]
	var xs := [gw / 2.0 - 340, gw / 2.0 - 70, gw / 2.0 + 140]
	return Rect2(xs[k - 40], 330 + 4 * 64, largs[k - 40], 54)


func card_pos(k: int) -> Rect2:
	var gw := G.gui_w
	var cw := minf(600, (gw - 100) / 2.0)
	return Rect2(gw / 2.0 - cw - 10 + (k % 2) * (cw + 20), 196 + (k / 2) * 82 - rolagem, cw, 72)


func lamina_pos(k: int) -> Rect2:
	var gw := G.gui_w
	var cw := minf(360, (gw - 120) / 3.0)
	return Rect2(gw / 2.0 - 1.5 * cw - 20 + (k % 3) * (cw + 20), 200 + (k / 3) * 220, cw, 200)


func abrir_nome() -> void:
	estado = "nome"
	nome_edit = G.perfil.nome
	tecla_sel = 0


func tecla_apertar(k: int) -> void:
	var tk: String = TECLAS[k]
	if tk == "APAGAR":
		nome_edit = nome_edit.substr(0, maxi(0, nome_edit.length() - 1))
		som("tit_mover", 0.6, 0.03)
		return
	if tk == "PRONTO":
		nome_salvar()
		return
	if nome_edit.length() >= V117.PERFIL_NOME_MAX:
		som("tit_negado", 0.6, 0)
		return
	nome_edit += " " if tk == "ESPAÇO" else tk
	som("tit_alterar", 0.6, 0.04)


func nome_salvar() -> void:
	var nm := nome_edit.strip_edges().to_upper()
	if nm == "":
		nm = "JOGADOR"
	G.perfil.nome = nm
	V117.perfil_salvar()
	som("tit_selecao", 0.8, 0.02)
	if modo == "primeiro":
		instance_create_depth(0, 0, -10400, "obj_mapa")
		instance_destroy()
		return
	estado = "abas"
	mensagem = "NOME SALVO: " + nm
	mensagem_t = 120


func ev_step() -> void:
	var dt := G.dt_real
	t += dt
	entrada = minf(1, entrada + dt / 18.0)
	if mensagem_t > 0:
		mensagem_t -= dt
	if not iniciado:
		iniciado = true
		if modo == "primeiro":
			abrir_nome()
	var gw := G.gui_w
	var gh := G.gui_h
	var mp := G.mouse_gui()
	var clique := G.mouse_apertado
	var ok := G.nav_ok
	var voltar := G.nav_voltar
	# ===================== NOME =====================
	if estado == "nome":
		var digitou := false
		if G.texto_tick != "":
			for ch in G.texto_tick.to_upper():
				if VALIDAS.contains(ch) and nome_edit.length() < V117.PERFIL_NOME_MAX:
					nome_edit += ch
				digitou = true
		if G.keyboard_check_pressed(KEY_BACKSPACE):
			nome_edit = nome_edit.substr(0, maxi(0, nome_edit.length() - 1))
			digitou = true
		if G.keyboard_check_pressed(KEY_ENTER) or G.keyboard_check_pressed(KEY_KP_ENTER):
			nome_salvar()
			return
		if voltar:
			som("tit_voltar", 0.8, 0.02)
			if modo == "primeiro":
				var m = instance_find("obj_menu", 0)
				if m != null:
					m.mudar_estado("menu", 0, false)
				V117.transicao_revelar(24)
				instance_destroy()
				return
			estado = "abas"
			return
		var antes := tecla_sel
		if G.nav_esq:
			tecla_sel = maxi(40, tecla_sel - 1) if tecla_sel >= 40 else (tecla_sel / 10) * 10 + ((tecla_sel % 10) + 9) % 10
		if G.nav_dir:
			tecla_sel = mini(42, tecla_sel + 1) if tecla_sel >= 40 else (tecla_sel / 10) * 10 + ((tecla_sel % 10) + 1) % 10
		if G.nav_cima:
			tecla_sel = 30 + (tecla_sel - 40) * 4 if tecla_sel >= 40 else maxi(0, tecla_sel - 10)
		if G.nav_baixo:
			if tecla_sel >= 30 and tecla_sel < 40:
				tecla_sel = 40 + mini(2, (tecla_sel - 30) / 4)
			elif tecla_sel < 40:
				tecla_sel += 10
		if tecla_sel != antes:
			som("tit_mover", 0.5, 0.03)
		if ok and not digitou and not G.keyboard_check_pressed(KEY_SPACE):
			tecla_apertar(tecla_sel)
		if clique:
			for k in TECLAS.size():
				if tecla_pos(k).has_point(mp):
					tecla_sel = k
					tecla_apertar(k)
					break
		return
	# ===================== ABAS =====================
	if voltar and entrada >= 1:
		som("tit_voltar", 0.8, 0.02)
		V117.perfil_salvar()
		var m2 = instance_find("obj_menu", 0)
		if m2 != null:
			m2.mudar_estado("menu", 2, false)
		V117.transicao_revelar(24)     # v1.19: o menu volta atrás da cortina
		instance_destroy()
		return
	var aba_antes := aba
	if G.nav_esq:
		aba = (aba + 2) % 3
	elif G.nav_dir:
		aba = (aba + 1) % 3
	for a in 3:
		var tx := gw / 2.0 + (a - 1) * 250
		if clique and Rect2(tx - 115, 128, 230, 42).has_point(mp):
			aba = a
	if aba != aba_antes:
		sel = 0
		rolagem_alvo = 0
		som("tit_mover", 0.6, 0.03)
	match aba:
		0:
			var nl := lista.size()
			if G.nav_cima:
				sel = maxi(0, sel - 1)
			if G.nav_baixo:
				sel = mini(nl - 1, sel + 1)
			if G.roda != 0:
				rolagem_alvo += G.roda * 120
			if clique and mp.y > 186 and mp.y < gh - 60:
				arrastando = true
				arraste_y0 = mp.y
				arraste_rol0 = rolagem
			if arrastando:
				if G.mouse_segurado:
					rolagem_alvo = arraste_rol0 - (mp.y - arraste_y0)
					rolagem = rolagem_alvo
				else:
					arrastando = false
			var linhas := ceili(nl / 2.0)
			var max_rol := maxf(0, linhas * 82 - (gh - 60 - 196))
			if G.nav_cima or G.nav_baixo:
				var cy := 196 + (sel / 2) * 82
				rolagem_alvo = clampf(cy - (gh / 2.0 - 40), 0, max_rol)
			rolagem_alvo = clampf(rolagem_alvo, 0, max_rol)
			if not arrastando:
				rolagem = lerpf(rolagem, rolagem_alvo, 1 - pow(0.8, dt))
		1:
			var ne := estilos.size()
			if G.nav_cima:
				sel = (sel + ne - 1) % ne
			if G.nav_baixo:
				sel = (sel + 1) % ne
			if G.nav_cima or G.nav_baixo:
				som("tit_mover", 0.5, 0.03)
			var escolher := ok
			for k in ne:
				if clique and lamina_pos(k).has_point(mp):
					sel = k
					escolher = true
			if escolher:
				var es: Dictionary = estilos[sel]
				if V117.espada_estilo_liberado(es.id):
					G.perfil.espada_fx = es.id
					V117.perfil_salvar()
					som("tit_selecao", 0.8, 0.02)
					mensagem = "LÂMINA EQUIPADA: " + str(es.nome)
					mensagem_t = 110
				else:
					som("tit_negado", 0.7, 0)
					mensagem = "Ganhe esta lâmina numa conquista"
					mensagem_t = 110
		2:
			if G.nav_cima or G.nav_baixo:
				sel = 1 - sel
				som("tit_mover", 0.6, 0.03)
			var bn := Rect2(gw / 2.0 - 160, 214, 320, 48)
			var bt := Rect2(gw / 2.0 - 260, 300, 520, 48)
			if clique and bn.has_point(mp):
				sel = 0
				ok = true
			var mudar_titulo := false
			if clique and bt.has_point(mp):
				sel = 1
				mudar_titulo = true
			if ok and sel == 0:
				som("tit_selecao", 0.8, 0.02)
				abrir_nome()
			if ok and sel == 1:
				mudar_titulo = true
			if mudar_titulo:
				var tl := V117.titulos_liberados()
				if tl.is_empty():
					som("tit_negado", 0.7, 0)
					mensagem = "Ganhe títulos nas conquistas"
					mensagem_t = 110
				else:
					var idx := tl.find(G.perfil.titulo)
					G.perfil.titulo = tl[(idx + 1) % tl.size()]
					V117.perfil_salvar()
					som("tit_alterar", 0.7, 0.03)


func ev_draw_gui() -> void:
	var gw := G.gui_w
	var gh := G.gui_h
	var pen: Pen = G.pen
	var ouro := Color8(236, 186, 84)
	var claro := Color8(250, 240, 228)
	var cinza := Color8(190, 175, 168)
	var a := entrada
	retangulo_gradiente(0, 0, gw, gh, Color8(16, 6, 8), 1, Color8(40, 12, 10), 1)
	pen.blend_add = true
	pen.elipse(-gw * 0.1, gh * 0.55, gw * 1.1, gh * 1.4, Color8(200, 60, 20), 0.12 + 0.04 * sin(t / 30.0), false)
	pen.blend_add = false
	# cabeçalho
	var feitas := V117.conquistas_feitas()
	var total := lista.size()
	V117.conquista_emblema(86, 72, 40, a, t)
	var titulo_cab := "CONQUISTAS DE " + V117.perfil_nome_exibir()
	txt_sombra(146, 50, titulo_cab, FONTE.MEDIA, claro, a, fa_left, fa_middle, minf(1, (gw - 520) / maxf(1, txt_largura(titulo_cab, FONTE.MEDIA))))
	txt(146, 88, G.perfil.titulo if G.perfil.titulo != "" else "Sem título ainda", FONTE.PEQUENA, ouro, a, fa_left, fa_middle)
	var bx2 := gw - 40.0
	var bx1 := bx2 - 300
	txt(bx2, 52, str(feitas) + " / " + str(total), FONTE.MEDIA, ouro, a, fa_right, fa_middle)
	pen.retangulo(bx1, 80, bx2, 92, Color8(30, 14, 12), a, false)
	pen.retangulo(bx1, 80, bx1 + (bx2 - bx1) * feitas / maxf(1, total), 92, Color8(200, 60, 30), a, false)
	pen.retangulo(bx1, 80, bx2, 92, ouro, a, true)
	# abas
	var nomes_aba := ["CONQUISTAS", "LÂMINAS", "PERFIL"]
	for k in 3:
		var tx := gw / 2.0 + (k - 1) * 250
		var ativa := aba == k
		pen.retangulo_arredondado(tx - 115, 128, tx + 115, 170, 8, 8, Color8(110, 22, 16) if ativa else Color8(34, 16, 14), a, false)
		pen.retangulo_arredondado(tx - 115, 128, tx + 115, 170, 8, 8, ouro if ativa else Color8(110, 90, 80), a, true)
		txt(tx, 149, nomes_aba[k], FONTE.PEQUENA, Color.WHITE if ativa else cinza, a, fa_center, fa_middle)
	match aba:
		0:
			for k in lista.size():
				var cp := card_pos(k)
				var y1 := cp.position.y
				if y1 + cp.size.y < 170 or y1 > gh - 50:
					continue
				var fa := a * clampf((y1 - 166) / 26.0, 0, 1) * clampf((gh - 50 - (y1 + cp.size.y)) / 26.0, 0, 1)
				if fa <= 0.01:
					continue
				var c: Dictionary = lista[k]
				var tem := V117.conquista_tem(c.id)
				hud_faixa(cp.position.x, y1, cp.end.x, cp.end.y, 0.92 * fa)
				if k == sel:
					pen.retangulo(cp.position.x - 2, y1 - 2, cp.end.x + 2, cp.end.y + 2, ouro, fa, true)
				V117.conquista_emblema(cp.position.x + 38, y1 + 36, 22, fa, t + k * 7, not tem)
				var lt := cp.size.x - 180
				txt_sombra(cp.position.x + 72, y1 + 18, c.nome, FONTE.PEQUENA, claro if tem else Color8(150, 136, 130), fa, fa_left, fa_middle, minf(1, lt / maxf(1, txt_largura(c.nome, FONTE.PEQUENA))))
				txt(cp.position.x + 72, y1 + 40, c.desc, FONTE.MINI, cinza if tem else Color8(120, 110, 106), fa, fa_left, fa_middle, minf(1, (cp.size.x - 90) / maxf(1, txt_largura(c.desc, FONTE.MINI))))
				txt(cp.position.x + 72, y1 + 60, V117.recompensa_texto(c), FONTE.MINI, Color8(255, 150, 100) if tem else Color8(130, 96, 84), fa, fa_left, fa_middle)
				txt(cp.end.x - 14, y1 + 18, G.perfil.conquistas[c.id] if tem else "BLOQUEADA", FONTE.MINI, ouro if tem else Color8(120, 104, 98), fa, fa_right, fa_middle)
		1:
			for k in estilos.size():
				var lp := lamina_pos(k)
				var e: Dictionary = estilos[k]
				var lib := V117.espada_estilo_liberado(e.id)
				var equip: bool = G.perfil.espada_fx == e.id
				hud_faixa(lp.position.x, lp.position.y, lp.end.x, lp.end.y, 0.94 * a)
				if k == sel or equip:
					pen.retangulo(lp.position.x - 2, lp.position.y - 2, lp.end.x + 2, lp.end.y + 2, ouro if equip else Color8(200, 120, 80), a, true)
					if k == sel:
						pen.retangulo(lp.position.x - 4, lp.position.y - 4, lp.end.x + 4, lp.end.y + 4, ouro if equip else Color8(200, 120, 80), a, true)
				var cx := lp.get_center().x
				V117.lamina_amostra(cx, lp.position.y + 92, 46, e, t + k * 20, a * (1.0 if lib else 0.35))
				if not lib:
					V117.cadeado_grande(cx, lp.position.y + 82, 0.9, a)
				txt_sombra(cx, lp.position.y + 156, e.nome, FONTE.PEQUENA, claro if lib else Color8(140, 128, 124), a, fa_center, fa_middle, minf(1, (lp.size.x - 20) / maxf(1, txt_largura(e.nome, FONTE.PEQUENA))))
				var st := "EQUIPADA" if equip else ("ESCOLHER" if lib else "BLOQUEADA")
				if not lib:
					for c2 in lista:
						if c2.rtipo == "espada" and c2.rval == e.id:
							st = "CONQUISTA: " + str(c2.nome)
				txt(cx, lp.position.y + 182, st, FONTE.MINI, ouro if equip else (cinza if lib else Color8(150, 110, 96)), a, fa_center, fa_middle, minf(1, (lp.size.x - 16) / maxf(1, txt_largura(st, FONTE.MINI))))
		2:
			var bn := Rect2(gw / 2.0 - 160, 214, 320, 48)
			var bt := Rect2(gw / 2.0 - 260, 300, 520, 48)
			txt(gw / 2.0, 196, "Seu nome aparece só nas conquistas: o herói continua sendo Twilight Vetrus.", FONTE.MINI, cinza, a, fa_center, fa_middle)
			for b in 2:
				var bb: Rect2 = bn if b == 0 else bt
				pen.retangulo_arredondado(bb.position.x, bb.position.y, bb.end.x, bb.end.y, 8, 8, Color8(110, 22, 16) if sel == b else Color8(34, 16, 14), a, false)
				pen.retangulo_arredondado(bb.position.x, bb.position.y, bb.end.x, bb.end.y, 8, 8, ouro if sel == b else Color8(110, 90, 80), a, true)
			var t_nome := "ALTERAR NOME  ·  " + V117.perfil_nome_exibir()
			txt(gw / 2.0, 238, t_nome, FONTE.PEQUENA, Color.WHITE, a, fa_center, fa_middle, minf(1, 300 / maxf(1, txt_largura(t_nome, FONTE.PEQUENA))))
			var tit: String = G.perfil.titulo if G.perfil.titulo != "" else "(nenhum)"
			var t_tit := "TÍTULO:  «  " + tit + "  »"
			txt(gw / 2.0, 324, t_tit, FONTE.PEQUENA, ouro, a, fa_center, fa_middle, minf(1, 500 / maxf(1, txt_largura(t_tit, FONTE.PEQUENA))))
			var st2: Dictionary = G.perfil.stats
			var linhas := [["INIMIGOS DERROTADOS", "inimigos"], ["JAVALIS DE GUERRA", "javalis"], ["ORBS COLETADAS", "orbs"], ["EXECUÇÕES", "execucoes"],
				["APAROS", "aparos"], ["MAIOR COMBO", "maior_combo"], ["SEQUÊNCIAS DE GOLPES", "sequencias"], ["FASES CONCLUÍDAS", "fases"]]
			for l in linhas.size():
				var lx := gw / 2.0 + (-300.0 if l % 2 == 0 else 40.0)
				var ly := 400.0 + (l / 2) * 50
				txt(lx, ly, linhas[l][0], FONTE.MINI, cinza, a, fa_left, fa_middle)
				txt(lx + 260, ly, str(int(round(st2.get(linhas[l][1], 0.0)))), FONTE.PEQUENA, claro, a, fa_right, fa_middle)
				pen.linha(lx, ly + 18, lx + 260, ly + 18, ouro, a * 0.4)
	var dica := ("Toque nas abas e nos itens" if G.usando_toque else "ESQUERDA / DIREITA  abas    ·    CIMA / BAIXO  escolher    ·    " + nome_confirmar() + "  confirmar") + "    ·    " + nome_voltar() + "  voltar"
	txt(gw / 2.0, gh - 24, dica, FONTE.MINI, cinza, a * 0.9, fa_center, fa_middle)
	if mensagem_t > 0:
		txt_sombra(gw / 2.0, gh - 62, mensagem, FONTE.PEQUENA, ouro, clampf(mensagem_t / 20.0, 0, 1), fa_center, fa_middle)
	# ===================== NOME (por cima de tudo) =====================
	if estado == "nome":
		pen.retangulo(0, 0, gw, gh, Color.BLACK, 0.86, false)
		txt_sombra(gw / 2.0, 120, "CRIE SEU PERFIL" if modo == "primeiro" else "ALTERAR NOME", FONTE.MEDIA, ouro, 1, fa_center, fa_middle)
		txt(gw / 2.0, 160, "Seu nome aparece só nas conquistas. O herói continua sendo Twilight Vetrus.", FONTE.MINI, cinza, 1, fa_center, fa_middle)
		pen.retangulo_arredondado(gw / 2.0 - 270, 210, gw / 2.0 + 270, 280, 10, 10, Color8(24, 12, 10), 1, false)
		pen.retangulo_arredondado(gw / 2.0 - 270, 210, gw / 2.0 + 270, 280, 10, 10, ouro, 1, true)
		var cursor := "_" if int(t / 30.0) % 2 == 0 else " "
		txt_sombra(gw / 2.0, 245, nome_edit + cursor, FONTE.MEDIA, Color.WHITE, 1, fa_center, fa_middle)
		for k in TECLAS.size():
			var tp := tecla_pos(k)
			var s := k == tecla_sel
			pen.retangulo_arredondado(tp.position.x, tp.position.y, tp.end.x, tp.end.y, 8, 8, Color8(130, 26, 18) if s else Color8(38, 18, 16), 1, false)
			pen.retangulo_arredondado(tp.position.x, tp.position.y, tp.end.x, tp.end.y, 8, 8, ouro if s else Color8(110, 84, 70), 1, true)
			txt(tp.get_center().x, tp.get_center().y, TECLAS[k], FONTE.PEQUENA if k >= 40 else FONTE.MEDIA, Color.WHITE if s else claro, 1, fa_center, fa_middle)
		txt(gw / 2.0, gh - 24, "Toque nas letras" if G.usando_toque else "Digite no teclado ou clique nas letras    ·    ENTER confirma    ·    " + nome_voltar() + " volta", FONTE.MINI, cinza, 0.9, fa_center, fa_middle)
	desenho_resetar()
