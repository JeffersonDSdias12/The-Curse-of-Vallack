class_name Lib
extends LibBase
# =====================================================================
#  Funções globais (scripts do GameMaker), parte 2:
#  scr_tutorial, scr_efeitos, scr_progresso, scr_v112, scr_cenario,
#  scr_combate, scr_inimigos_novos e a parte global de scr_dano
# =====================================================================

const BAU_PARTICULAS := 36
const ARMADILHA_FERE_INIMIGOS := false
const FURIA_MODO_QUADROS := 720.0
const CRITICO_PONTA := 0.68
const CRITICO_MULT := 1.5
const RECUAR_DURACAO := 18.0
const RECUAR_INVENC := 10.0
const RECUAR_VEL := 7.4
const AEREO_MAX := 3
const ESPINHOS_ESCALA := 1.6
const ROLAR_DURACAO := 26.0
const ROLAR_INVENC_INI := 2.0
const ROLAR_INVENC_FIM := 19.0
const ROLAR_VEL := 6.6
const ROLAR_BUFFER := 14.0
const APARAR_JANELA := 10.0
const APARAR_RECARGA := 26.0
const ORBS_BESTA := 12
const ORBS_ARQUEIRO := 8
const ORBS_ESCUDO := 20
const ORBS_MINI_BOSS := 150
const ORBS_BOSS := 400
const ORBS_ESQUELETO := 10
const ORBS_ARANHA := 14
const ORBS_ESTATUA := 18
const ORBS_PORCO := 45
const ORBS_SEGREDO := 60
const ORBS_FINALIZADOR := 1.5
const BOSS_ONDA_BESTAS := 10
const BOSS_ONDA_ARQUEIROS := 5
const BOSS_ONDA_ESQUELETOS := [2, 3, 3, 4]
const BOSS_ONDA_ARANHAS := [1, 1, 2, 2]
const NIVEL_MAX := 5
const EVAPORAR_INI := 70.0
const EVAPORAR_FIM := 180.0
const FALAS_LIGADAS := false


# =====================================================================
# scr_tutorial: o tutorial em PERGAMINHO da tela de carregamento
# =====================================================================
static func tutorial_carregamento() -> Dictionary:
	if G.usando_toque and not usando_controle():
		# toque: analógico + 4 botões (direção + botão muda o golpe, como no Castlevania)
		return {"titulo": "COMO JOGAR", "sub": "Fogo roxo, espinhos, veneno e abismos ferem   ·   a fumaça dos inimigos derrotados, não", "linhas": [
			{"ic": [ACAO.ESQUERDA, ACAO.DIREITA, ACAO.PULAR], "n": "ANALÓGICO E PULO", "t": "Twilight sempre corre. ▼ agacha; ▼ + PULO desce de passarelas. Cair num abismo é morte certa."},
			{"ic": [ACAO.ESQUIVA], "n": "ESQUIVA E DEFESA", "t": "Com ◄ ►: rola (nada acerta). Sem seta: defende; na hora do golpe, apara."},
			{"ic": [ACAO.ATACAR, ACAO.ATAQUE_FORTE], "n": "ATAQUE  ·  PESADO", "t": "No ritmo viram combos. ▼ + ATAQUE: rasteira. ▲ + PESADO: lançador."},
			{"ic": [ACAO.ATACAR], "n": "SUB-ARMAS", "t": "▲ + ATAQUE: lâmina bumerangue. ▼ + PESADO: chama de Sylla."},
			{"ic": [ACAO.INTERAGIR], "n": "AÇÃO", "t": "Aparece sozinho perto de baú (ABRIR), cristal (SALVAR) e inimigo marcado."},
			{"ic": [ACAO.ESPECIAL_3, ACAO.FURIA], "n": "MAGIA E FÚRIA", "t": "MAGIA surge com a espada evoluída (▲ / ▼ trocam). Fúria cheia: Modo Fúria."},
		]}
	return {"titulo": "COMO JOGAR", "sub": "Fogo roxo, espinhos, veneno e abismos ferem   ·   a fumaça dos inimigos derrotados, não", "linhas": [
		{"ic": [ACAO.ESQUERDA, ACAO.DIREITA, ACAO.PULAR], "n": "CORRER E PULAR", "t": "Twilight sempre corre. No ar, ainda dá para atacar."},
		{"ic": [ACAO.ESQUIVA], "n": "ESQUIVA E BACKDASH", "t": "Com direção, rola: no meio da rolagem nada acerta. Parado, salta para trás."},
		{"ic": [ACAO.ATACAR, ACAO.ATAQUE_FORTE, ACAO.ATAQUE_SALTO], "n": "ATAQUE  ·  PESADO  ·  RASTEIRA", "t": "No ritmo, viram combos. Acertar com a ponta da espada causa crítico."},
		{"ic": [ACAO.PULAR, ACAO.ATAQUE_FORTE], "n": "LANÇADOR E COMBO AÉREO", "t": "Quase juntos: o inimigo voa, Twilight sobe junto e continua no ar."},
		{"ic": [ACAO.DEFENDER], "n": "DEFESA E CONTRA-ATAQUE", "t": "Segure para defender. Na hora exata do golpe: apara e contra-ataca."},
		{"ic": [ACAO.INTERAGIR], "n": "INTERAGIR E SUB-ARMAS", "t": "Baús, cristal e execução (contorno vermelho). Longe deles: sub-arma."},
		{"ic": [ACAO.ESPECIAL_3, ACAO.FURIA], "n": "MAGIA E FÚRIA", "t": "Especiais gastam a barra azul. Fúria cheia: Modo Fúria. " + botao_menu_armas() + ": armas."},
	]}


# Rótulo do botão da tela de armas
static func botao_menu_armas() -> String:
	if G.usando_pad and G.pad_slot >= 0:
		return "OPTIONS" if pad_estilo() == "ps" else "START"
	if G.usando_toque:
		return "ARMAS"
	return "TAB"


# Rolo de madeira/pergaminho enrolado (em cima e embaixo)
func pergaminho_rolo(cx: float, py: float, w: float, alfa: float) -> void:
	var x1 := cx - w / 2.0
	var x2 := cx + w / 2.0
	var c_esc := Color8(118, 82, 42)
	var c_luz := Color8(232, 204, 150)
	retangulo_gradiente(x1, py - 13, x2, py, c_esc, alfa, c_luz, alfa)
	retangulo_gradiente(x1, py, x2, py + 13, c_luz, alfa, c_esc, alfa)
	draw_set_alpha(alfa)
	draw_set_color(Color8(80, 52, 24))
	draw_rectangle(x1, py - 13, x2, py + 13, true)
	for l in [-1, 1]:
		var px := x1 - 9 if l < 0 else x2 + 9
		draw_set_color(Color8(70, 38, 18))
		draw_ellipse(px - 11, py - 16, px + 11, py + 16, false)
		draw_set_color(Color8(150, 98, 46))
		draw_ellipse(px - 7, py - 11, px + 5, py + 7, false)
		draw_set_color(Color8(205, 160, 80))
		draw_circle(px - 2, py - 4, 3, false)


# abre: 0..1 (desenrola) · rodape: texto do botão de continuar
func pergaminho_desenhar(cx: float, cy: float, w: float, h: float, abre: float, pag: Dictionary, alfa: float, rodape: String, indice := "", rodape_alfa := 1.0) -> void:
	var ab := clampf(abre, 0, 1)
	var ease := 1.0 - pow(1.0 - ab, 3)
	var hh := maxf(10.0, h * ease)
	var x1 := cx - w / 2.0
	var x2 := cx + w / 2.0
	var y1 := cy - hh / 2.0
	var y2 := cy + hh / 2.0
	var papel := Color8(238, 222, 182)
	var papel2 := Color8(203, 172, 118)
	var queim := Color8(92, 56, 26)
	draw_set_alpha(0.5 * alfa)
	draw_set_color(c_black)
	draw_rectangle(x1 + 12, y1 + 16, x2 + 12, y2 + 16, false)
	retangulo_gradiente_h(x1, y1, cx, y2, papel2, alfa, papel, alfa)
	retangulo_gradiente_h(cx, y1, x2, y2, papel, alfa, papel2, alfa)
	retangulo_gradiente(x1, y1, x2, y1 + 46, queim, 0.32 * alfa, queim, 0)
	retangulo_gradiente(x1, y2 - 46, x2, y2, queim, 0, queim, 0.32 * alfa)
	# manchas
	draw_set_color(Color8(150, 110, 60))
	for m in 7:
		var mx := x1 + w * (0.12 + 0.76 * frac(sin(m * 12.9898) * 43758.5453))
		var my := y1 + hh * (0.15 + 0.7 * frac(sin(m * 78.233) * 12345.678))
		var mr := 14 + 26 * frac(sin(m * 3.17) * 999.1)
		draw_set_alpha(0.07 * alfa)
		draw_ellipse(mx - mr, my - mr * 0.6, mx + mr, my + mr * 0.6, false)
	# bordas laterais rasgadas e queimadas
	draw_set_color(queim)
	var passo := 9.0
	var yy := y1
	while yy < y2:
		var k := yy - y1
		var r1 := 3 + 6 * absf(sin(k * 0.37 + 1.3))
		var r2 := 3 + 6 * absf(sin(k * 0.23 + 4.1))
		var yb := minf(y2, yy + passo)
		draw_set_alpha(0.6 * alfa)
		draw_triangle(x1, yy, x1 + r1, (yy + yb) / 2.0, x1, yb, false)
		draw_triangle(x2, yy, x2 - r2, (yy + yb) / 2.0, x2, yb, false)
		yy += passo
	draw_set_alpha(0.75 * alfa)
	draw_rectangle(x1, y1, x2, y2, true)
	pergaminho_rolo(cx, y1, w + 30, alfa)
	pergaminho_rolo(cx, y2, w + 30, alfa)
	if ease < 0.9:
		desenho_resetar()
		return
	var ca := alfa * clampf((ease - 0.9) / 0.1, 0, 1)
	var vermelho := Color8(128, 18, 16)
	var tinta := Color8(54, 32, 16)
	var tinta2 := Color8(96, 64, 34)
	var ty := y1 + 46
	txt(cx, ty, pag.titulo, FONTE.MEDIA, vermelho, ca, fa_center, fa_middle, minf(1.15, (w - 120) / maxf(1, txt_largura(pag.titulo, FONTE.MEDIA))))
	txt(cx, ty + 30, pag.sub, FONTE.MINI, tinta2, ca, fa_center, fa_middle, minf(1, (w - 120) / maxf(1, txt_largura(pag.sub, FONTE.MINI))))
	draw_set_alpha(ca)
	draw_set_color(tinta2)
	draw_line_width(cx - 200, ty + 50, cx - 14, ty + 50, 2)
	draw_line_width(cx + 14, ty + 50, cx + 200, ty + 50, 2)
	draw_set_color(vermelho)
	draw_triangle(cx - 9, ty + 50, cx, ty + 43, cx + 9, ty + 50, false)
	draw_triangle(cx - 9, ty + 50, cx, ty + 57, cx + 9, ty + 50, false)
	# linhas
	var xi := x1 + 56
	var xt := x1 + 56 + 150
	var lt := x2 - 56 - xt
	var py := ty + 76
	for ln in pag.linhas:
		var ic = ln.get("ic")
		var sq = ln.get("seq")
		var nm = ln.get("n")
		if ic == null and sq == null:
			draw_set_alpha(ca * 0.5)
			draw_set_color(vermelho)
			draw_circle(xi + 4, py + 9, 3, false)
			txt_bloco(xi + 16, py, ln.t, FONTE.MINI, tinta, ca, x2 - 56 - xi - 16, fa_left, fa_top)
			py += txt_bloco_altura(ln.t, FONTE.MINI, x2 - 56 - xi - 16) + 18
			continue
		var cx_ic := xi
		var lista: Array = ic if sq == null else sq
		for k2 in lista.size():
			if k2 > 0:
				draw_set_alpha(ca)
				draw_set_color(tinta2)
				if sq != null:
					draw_triangle(cx_ic + 1, py + 11, cx_ic + 7, py + 16, cx_ic + 1, py + 21, false)
				else:
					txt(cx_ic + 4, py + 16, "/", FONTE.MINI, tinta2, ca, fa_center, fa_middle)
				cx_ic += 10
			cx_ic += desenhar_icone_acao(cx_ic, py + 16, lista[k2], 28, ca) + 2
		if nm != null:
			txt(xt, py, nm, FONTE.PEQUENA, vermelho, ca, fa_left, fa_top, minf(1, lt / maxf(1, txt_largura(nm, FONTE.PEQUENA))))
		txt_bloco(xt, py + 24, ln.t, FONTE.MINI, tinta, ca, lt, fa_left, fa_top)
		py += maxf(38, 24 + txt_bloco_altura(ln.t, FONTE.MINI, lt)) + 18
	# selo de cera
	var sx := x2 - 64
	var sy := y2 - 52
	draw_set_alpha(ca * 0.9)
	draw_set_color(Color8(110, 10, 12))
	draw_circle(sx, sy, 25, false)
	draw_set_color(Color8(160, 24, 22))
	draw_circle(sx - 1, sy - 1, 20, false)
	draw_set_color(Color8(95, 6, 8))
	draw_circle(sx, sy, 17, true)
	txt(sx, sy, "V", FONTE.MEDIA, Color8(230, 120, 100), ca * 0.9, fa_center, fa_middle, 0.9)
	if indice != "":
		txt(cx, y2 - 70, indice, FONTE.MINI, tinta2, ca, fa_center, fa_middle)
	# continuar: [X] / [ENTER] / [TOQUE]
	if rodape != "" and rodape_alfa > 0:
		var ra := ca * rodape_alfa
		var ry := y2 - 40
		if G.usando_toque and not usando_controle():
			var tr := "TOQUE PARA " + rodape
			txt(cx, ry, tr, FONTE.PEQUENA, vermelho, ra, fa_center, fa_middle)
		else:
			var wt := txt_largura(rodape, FONTE.PEQUENA)
			var w_ic := 28 + 18 + desenhar_tecla_largura("ENTER", 28)
			var rx := cx - (w_ic + 12 + wt) / 2.0
			rx += desenhar_icone_pad(rx, ry, gp_face1, 28, ra)
			txt(rx + 9, ry, "/", FONTE.PEQUENA, tinta2, ra, fa_center, fa_middle)
			rx += 18
			rx += desenhar_tecla(rx, ry, "ENTER", 28, ra)
			txt(rx + 12, ry, rodape, FONTE.PEQUENA, vermelho, ra, fa_left, fa_middle)
	desenho_resetar()


# ----- Ícones de teclas, botões e toque. _x = borda esquerda, _y = centro -----
func desenhar_icone_acao(px: float, py: float, acao: int, a := 30.0, alfa := 1.0) -> float:
	if G.usando_pad and G.pad_slot >= 0:
		return desenhar_icone_pad(px, py, G.botoes[acao], a, alfa)
	if G.usando_toque:
		return desenhar_icone_toque(px, py, acao, a, alfa)
	return desenhar_tecla(px, py, nome_tecla(G.teclas[acao]), a, alfa)


static func icone_acao_largura(acao: int, a := 30.0) -> float:
	if G.usando_pad and G.pad_slot >= 0:
		return icone_pad_largura(G.botoes[acao], a)
	if G.usando_toque:
		return icone_toque_largura(acao, a)
	return desenhar_tecla_largura(nome_tecla(G.teclas[acao]), a)


static func icone_toque_largura(acao: int, a := 30.0) -> float:
	var e := minf(1.0, (a * 0.55) / 15.0)
	return maxf(a, txt_largura(toque_curto(acao), FONTE.MINI, e) + 12)


# Botão de toque (mesmo visual dos botões da tela)
func desenhar_icone_toque(px: float, py: float, acao: int, a := 30.0, alfa := 1.0) -> float:
	var w := icone_toque_largura(acao, a)
	var r := a / 2.0
	var cor := toque_cor(acao)
	draw_set_alpha(alfa * 0.5)
	draw_set_color(c_black)
	draw_roundrect_ext(px + 1, py - r + 2, px + w + 1, py + r + 2, r, r, false)
	draw_set_alpha(alfa)
	draw_set_color(Color8(24, 20, 22))
	draw_roundrect_ext(px, py - r, px + w, py + r, r, r, false)
	draw_set_color(cor)
	draw_roundrect_ext(px, py - r, px + w, py + r, r, r, true)
	var e := minf(1.0, (a * 0.55) / 15.0)
	txt(px + w / 2.0, py, toque_curto(acao), FONTE.MINI, cor.lerp(c_white, 0.4), alfa, fa_center, fa_middle, e)
	desenho_resetar()
	return w


static func icone_pad_largura(b: int, a := 30.0) -> float:
	if b < 0:
		return maxf(a * 1.3, txt_largura("ANALÓGICO", FONTE.MINI, minf(1, (a * 0.6) / 15.0)) + 16)
	if b in [gp_face1, gp_face2, gp_face3, gp_face4, gp_padu, gp_padd, gp_padl, gp_padr, gp_stickl, gp_stickr]:
		return a
	var ps := pad_estilo() == "ps"
	var nome := str(b)
	match b:
		gp_shoulderl:
			nome = "L1" if ps else "LB"
		gp_shoulderr:
			nome = "R1" if ps else "RB"
		gp_shoulderlb:
			nome = "L2" if ps else "LT"
		gp_shoulderrb:
			nome = "R2" if ps else "RT"
		gp_select:
			nome = "SELECT" if ps else "BACK"
		gp_start:
			nome = "OPTIONS" if ps else "START"
	var e := minf(1, (a * 0.6) / 15.0)
	return maxf(a * 1.3, txt_largura(nome, FONTE.MINI, e) + 16)


static func desenhar_tecla_largura(texto: String, a: float) -> float:
	var e := minf(1, (a * 0.62) / 15.0)
	return maxf(a, txt_largura(texto, FONTE.MINI, e) + 16)


func desenhar_tecla(px: float, py: float, texto: String, a := 30.0, alfa := 1.0) -> float:
	var e := minf(1, (a * 0.62) / 15.0)
	var w := desenhar_tecla_largura(texto, a)
	var y1 := py - a / 2.0
	var y2 := py + a / 2.0
	draw_set_alpha(alfa * 0.55)
	draw_set_color(c_black)
	draw_roundrect_ext(px + 1, y1 + 3, px + w + 1, y2 + 3, 8, 8, false)
	draw_set_alpha(alfa)
	draw_set_color(Color8(58, 46, 36))
	draw_roundrect_ext(px, y1, px + w, y2, 8, 8, false)
	draw_set_color(Color8(236, 228, 210))
	draw_roundrect_ext(px + 2, y1 + 2, px + w - 2, y2 - 4, 6, 6, false)
	txt(px + w / 2.0, py - 1, texto, FONTE.MINI, Color8(40, 28, 18), alfa, fa_center, fa_middle, e)
	return w


func desenhar_icone_pad(px: float, py: float, b: int, a := 30.0, alfa := 1.0) -> float:
	var ps := pad_estilo() == "ps"
	var r := a / 2.0
	var cx := px + r
	var fundo := Color8(30, 28, 32)
	var borda := Color8(150, 145, 140)
	if b in [gp_face1, gp_face2, gp_face3, gp_face4]:
		draw_set_alpha(alfa * 0.5)
		draw_set_color(c_black)
		draw_circle(cx + 1, py + 2, r, false)
		draw_set_alpha(alfa)
		draw_set_color(fundo)
		draw_circle(cx, py, r, false)
		draw_set_color(borda)
		draw_circle(cx, py, r, true)
		var s := r * 0.46
		if ps:
			match b:
				gp_face1:
					draw_set_color(Color8(130, 180, 255))
					draw_line_width(cx - s, py - s, cx + s, py + s, 3)
					draw_line_width(cx - s, py + s, cx + s, py - s, 3)
				gp_face2:
					draw_set_color(Color8(255, 100, 100))
					for i in 3:
						draw_circle(cx, py, s + 1 - i, true)
				gp_face3:
					draw_set_color(Color8(245, 145, 215))
					for i in 3:
						draw_rectangle(cx - s + i, py - s + i, cx + s - i, py + s - i, true)
				gp_face4:
					draw_set_color(Color8(95, 230, 175))
					var ty1 := py - s * 1.05
					var ty2 := py + s * 0.8
					draw_line_width(cx, ty1, cx - s * 1.1, ty2, 3)
					draw_line_width(cx - s * 1.1, ty2, cx + s * 1.1, ty2, 3)
					draw_line_width(cx + s * 1.1, ty2, cx, ty1, 3)
		else:
			var letra := "A"
			var cor := Color8(110, 210, 90)
			if b == gp_face2:
				letra = "B"
				cor = Color8(240, 80, 70)
			if b == gp_face3:
				letra = "X"
				cor = Color8(80, 150, 255)
			if b == gp_face4:
				letra = "Y"
				cor = Color8(245, 200, 60)
			txt(cx, py, letra, FONTE.PEQUENA, cor, alfa, fa_center, fa_middle, minf(1, a / 30.0))
		desenho_resetar()
		return a
	var dirc := -1
	if b == gp_padu:
		dirc = 0
	if b == gp_padr:
		dirc = 1
	if b == gp_padd:
		dirc = 2
	if b == gp_padl:
		dirc = 3
	if dirc >= 0:
		var t := a * 0.34
		draw_set_alpha(alfa)
		draw_set_color(borda)
		draw_rectangle(cx - t / 2 - 1, py - r - 1, cx + t / 2 + 1, py + r + 1, false)
		draw_rectangle(cx - r - 1, py - t / 2 - 1, cx + r + 1, py + t / 2 + 1, false)
		draw_set_color(fundo)
		draw_rectangle(cx - t / 2, py - r, cx + t / 2, py + r, false)
		draw_rectangle(cx - r, py - t / 2, cx + r, py + t / 2, false)
		draw_set_color(Color8(255, 210, 90))
		match dirc:
			0:
				draw_rectangle(cx - t / 2 + 1, py - r + 1, cx + t / 2 - 1, py - t / 2, false)
			1:
				draw_rectangle(cx + t / 2, py - t / 2 + 1, cx + r - 1, py + t / 2 - 1, false)
			2:
				draw_rectangle(cx - t / 2 + 1, py + t / 2, cx + t / 2 - 1, py + r - 1, false)
			3:
				draw_rectangle(cx - r + 1, py - t / 2 + 1, cx - t / 2, py + t / 2 - 1, false)
		desenho_resetar()
		return a
	var nome := ""
	match b:
		gp_shoulderl:
			nome = "L1" if ps else "LB"
		gp_shoulderr:
			nome = "R1" if ps else "RB"
		gp_shoulderlb:
			nome = "L2" if ps else "LT"
		gp_shoulderrb:
			nome = "R2" if ps else "RT"
		gp_stickl:
			nome = "L3"
		gp_stickr:
			nome = "R3"
		gp_select:
			nome = "SELECT" if ps else "BACK"
		gp_start:
			nome = "OPTIONS" if ps else "START"
		_:
			nome = "ANALÓGICO" if b < 0 else str(b)
	var e := minf(1, (a * 0.6) / 15.0)
	var w := maxf(a * 1.3, txt_largura(nome, FONTE.MINI, e) + 16)
	var redondo := b == gp_stickl or b == gp_stickr
	if redondo:
		w = a
	draw_set_alpha(alfa * 0.5)
	draw_set_color(c_black)
	draw_roundrect_ext(px + 1, py - r + 2, px + w + 1, py + r + 2, r, r, false)
	draw_set_alpha(alfa)
	draw_set_color(fundo)
	draw_roundrect_ext(px, py - r, px + w, py + r, r if redondo else 9.0, r if redondo else 9.0, false)
	draw_set_color(borda)
	draw_roundrect_ext(px, py - r, px + w, py + r, r if redondo else 9.0, r if redondo else 9.0, true)
	txt(px + w / 2.0, py, nome, FONTE.MINI, c_white, alfa, fa_center, fa_middle, e)
	desenho_resetar()
	return w


# =====================================================================
# scr_efeitos: portal, cristal, barreira, ícones e a espada da tela de armas
# =====================================================================
func desenhar_portal(px: float, py: float, abre: float, t: float) -> void:
	if abre <= 0:
		return
	var rx := 34 * abre
	var ry := 9 * abre
	gpu_set_blendmode(bm_add)
	draw_set_alpha(0.32 * abre)
	draw_set_color(Color8(170, 40, 200))
	draw_ellipse(px - rx * 1.6, py - ry * 1.6, px + rx * 1.6, py + ry * 1.6, false)
	retangulo_gradiente(px - rx * 0.8, py - 80 * abre, px + rx * 0.8, py, Color8(200, 60, 255), 0, Color8(200, 60, 255), 0.32 * abre)
	gpu_set_blendmode(bm_normal)
	draw_set_alpha(0.92 * abre)
	draw_set_color(Color8(18, 4, 24))
	draw_ellipse(px - rx, py - ry, px + rx, py + ry, false)
	draw_set_alpha(abre)
	draw_set_color(Color8(230, 90, 255))
	draw_ellipse(px - rx, py - ry, px + rx, py + ry, true)
	draw_ellipse(px - rx - 1, py - ry - 1, px + rx + 1, py + ry + 1, true)
	for k in 8:
		var a := t * 4 + k * 45
		draw_circle(px + lengthdir_x(rx * 1.25, a), py + lengthdir_y(ry * 1.25, a), 1.6, false)
	gpu_set_blendmode(bm_add)
	draw_set_color(Color8(240, 140, 255))
	for k2 in 7:
		var f := frac(t / 40.0 + k2 / 7.0)
		draw_set_alpha((1 - f) * abre)
		draw_circle(px + sin(k2 * 2.1 + t / 9.0) * rx * 0.7, py - f * 64, 1.5, false)
	gpu_set_blendmode(bm_normal)
	draw_set_alpha(1)


# Cristal mágico flutuante (checkpoint e cristal dourado)
func desenhar_cristal(px: float, py: float, tam: float, cor1: Color, cor2: Color, brilho: float, t: float) -> void:
	var gira := 0.55 + 0.45 * absf(dcos(t * 1.6))
	var w := tam * gira
	var h := tam * 1.9
	gpu_set_blendmode(bm_add)
	draw_set_alpha(0.22 * brilho)
	draw_set_color(cor2)
	draw_circle(px, py, tam * 2.3, false)
	draw_set_alpha(0.3 * brilho)
	draw_circle(px, py, tam * 1.3, false)
	gpu_set_blendmode(bm_normal)
	draw_set_alpha(1)
	draw_set_color(merge_color(cor1, c_black, 0.35))
	draw_triangle(px - w, py, px, py - h, px, py + h * 0.75, false)
	draw_set_color(cor1)
	draw_triangle(px + w, py, px, py - h, px, py + h * 0.75, false)
	draw_set_color(merge_color(cor1, c_white, 0.45))
	draw_triangle(px - w * 0.35, py - h * 0.1, px, py - h * 0.85, px + w * 0.15, py - h * 0.1, false)
	draw_set_color(merge_color(cor2, c_white, 0.5))
	draw_line(px - w, py, px, py - h)
	draw_line(px, py - h, px + w, py)
	draw_line(px + w, py, px, py + h * 0.75)
	draw_line(px, py + h * 0.75, px - w, py)
	gpu_set_blendmode(bm_add)
	draw_set_alpha((0.5 + 0.5 * sin(t * 0.15)) * brilho)
	draw_set_color(c_white)
	draw_circle(px, py - h * 0.15, 2.2, false)
	gpu_set_blendmode(bm_normal)
	draw_set_alpha(1)


# Barreira mágica vertical
func desenhar_barreira(px: float, y_topo: float, y_base: float, alfa: float, t: float) -> void:
	if alfa <= 0:
		return
	gpu_set_blendmode(bm_add)
	retangulo_gradiente_h(px - 26, y_topo, px, y_base, Color8(200, 20, 30), 0, Color8(200, 20, 30), 0.35 * alfa)
	retangulo_gradiente_h(px, y_topo, px + 26, y_base, Color8(200, 20, 30), 0.35 * alfa, Color8(200, 20, 30), 0)
	draw_set_color(Color8(255, 90, 70))
	for i in 14:
		var f := frac(t / 90.0 + i / 14.0)
		var yy := y_base - f * (y_base - y_topo)
		draw_set_alpha((1 - absf(f - 0.5) * 2) * alfa)
		var ox := sin(t / 12.0 + i * 1.7) * 6
		draw_line_width(px + ox - 4, yy, px + ox + 4, yy - 6, 2)
	draw_set_alpha(0.6 * alfa)
	draw_line_width(px, y_topo, px, y_base, 2)
	gpu_set_blendmode(bm_normal)
	draw_set_alpha(1)


# Ícone pulsando sobre um inimigo pronto para o FINALIZADOR
func desenhar_icone_finalizador(px: float, py: float) -> void:
	var p := 0.5 + 0.5 * sin(current_time() / 90.0)
	gpu_set_blendmode(bm_add)
	draw_set_alpha(0.35 + 0.25 * p)
	draw_set_color(Color8(255, 60, 40))
	draw_circle(px, py, 10 + 2 * p, false)
	gpu_set_blendmode(bm_normal)
	draw_set_alpha(1)
	var tf := gpu_get_texfilter()
	gpu_set_texfilter(true)
	var a := 13.0
	var acao := ACAO.ATAQUE_SALTO
	var w := icone_acao_largura(acao, a)
	desenhar_icone_acao(px - w / 2.0, py, acao, a, 1)
	gpu_set_texfilter(tf)
	desenho_resetar()


# A Lâmina de Sylla grande (tela de armas): runas acendem a cada nível
func desenhar_espada_grande(cx: float, y1: float, y2: float, nivel: int, alfa: float, brilho: float, t: float) -> void:
	var h := y2 - y1
	var lam_fim := y1 + h * 0.70
	var bw := 15.0
	gpu_set_blendmode(bm_add)
	draw_set_alpha(alfa * (0.10 + 0.04 * nivel + 0.5 * brilho))
	draw_set_color(Color8(220, 30, 20))
	draw_ellipse(cx - 70, y1 - 10, cx + 70, lam_fim + 20, false)
	gpu_set_blendmode(bm_normal)
	draw_set_alpha(alfa)
	var c1 := Color8(205, 210, 220)
	var c2 := Color8(120, 125, 140)
	draw_primitive_begin(pr_trianglelist)
	draw_vertex_color(cx, y1, c_white, alfa)
	draw_vertex_color(cx - bw, y1 + 40, c1, alfa)
	draw_vertex_color(cx + bw, y1 + 40, c2, alfa)
	draw_vertex_color(cx - bw, y1 + 40, c1, alfa)
	draw_vertex_color(cx + bw, y1 + 40, c2, alfa)
	draw_vertex_color(cx - bw, lam_fim, c1, alfa)
	draw_vertex_color(cx + bw, y1 + 40, c2, alfa)
	draw_vertex_color(cx - bw, lam_fim, c1, alfa)
	draw_vertex_color(cx + bw, lam_fim, c2, alfa)
	draw_primitive_end()
	draw_set_color(Color8(90, 92, 105))
	draw_rectangle(cx - 2, y1 + 30, cx + 2, lam_fim - 6, false)
	for i in 5:
		var ry := lam_fim - 26 - i * ((lam_fim - y1 - 70) / 5.0)
		var acesa := i < nivel
		if acesa:
			gpu_set_blendmode(bm_add)
			draw_set_alpha(alfa * (0.5 + 0.3 * sin(t / 9.0 + i) + brilho))
			draw_set_color(Color8(255, 50, 30))
			draw_circle(cx, ry, 8, false)
			gpu_set_blendmode(bm_normal)
		draw_set_alpha(alfa)
		draw_set_color(Color8(255, 120, 90) if acesa else Color8(70, 70, 80))
		draw_line_width(cx - 5, ry - 5, cx + 5, ry + 5, 2)
		draw_line_width(cx + 5, ry - 5, cx - 5, ry + 5, 2)
		draw_line_width(cx, ry - 7, cx, ry + 7, 2)
	var ouro := Color8(200, 150, 60)
	draw_set_color(ouro)
	draw_triangle(cx - 54, lam_fim - 4, cx, lam_fim - 12, cx, lam_fim + 12, false)
	draw_triangle(cx + 54, lam_fim - 4, cx, lam_fim - 12, cx, lam_fim + 12, false)
	draw_set_color(Color8(120, 80, 30))
	draw_rectangle(cx - 16, lam_fim - 6, cx + 16, lam_fim + 8, false)
	draw_set_color(Color8(200, 20, 20))
	draw_circle(cx, lam_fim + 1, 6, false)
	var cabo_fim := y2 - 18
	draw_set_color(Color8(50, 26, 18))
	draw_rectangle(cx - 7, lam_fim + 8, cx + 7, cabo_fim, false)
	draw_set_color(Color8(90, 50, 30))
	var yy := lam_fim + 12
	while yy < cabo_fim:
		draw_line_width(cx - 7, yy, cx + 7, yy + 4, 2)
		yy += 8
	draw_set_color(ouro)
	draw_circle(cx, y2 - 10, 11, false)
	draw_set_color(Color8(200, 20, 20))
	draw_circle(cx, y2 - 10, 5, false)
	draw_set_alpha(1)


# Pote de orbs (HUD e tela de armas)
func desenhar_pote_orbs(px: float, py: float, esc: float, alfa: float, fx: float) -> void:
	var p := 1 + 0.15 * clampf(fx / 20.0, 0, 1)
	var r := 14 * esc * p
	draw_set_alpha(alfa)
	draw_set_color(Color8(40, 26, 20))
	draw_circle(px, py + 2, r + 2, false)
	draw_set_color(Color8(120, 86, 46))
	draw_circle(px, py + 2, r, false)
	draw_set_color(Color8(60, 36, 22))
	draw_rectangle(px - r * 0.55, py - r - 4 * esc, px + r * 0.55, py - r + 4 * esc, false)
	gpu_set_blendmode(bm_add)
	draw_set_alpha(alfa * (0.55 + 0.35 * clampf(fx / 20.0, 0, 1)))
	draw_set_color(Color8(255, 40, 30))
	draw_circle(px, py + 3, r * 0.65, false)
	draw_set_color(Color8(255, 200, 170))
	draw_circle(px - r * 0.2, py, r * 0.22, false)
	gpu_set_blendmode(bm_normal)
	draw_set_alpha(1)


# Cadeado pequeno (ação ainda bloqueada)
func desenhar_cadeado(px: float, py: float, alfa := 1.0) -> void:
	draw_set_alpha(alfa)
	draw_set_color(Color8(30, 24, 20))
	draw_roundrect_ext(px - 7, py - 3, px + 7, py + 8, 3, 3, false)
	draw_set_color(Color8(200, 170, 90))
	draw_roundrect_ext(px - 6, py - 2, px + 6, py + 7, 3, 3, false)
	draw_circle(px, py - 4, 5, true)
	draw_circle(px, py - 4, 4, true)
	draw_set_color(Color8(60, 40, 20))
	draw_rectangle(px - 1, py + 1, px + 1, py + 4, false)
	draw_set_alpha(1)


# =====================================================================
# scr_progresso: orbs, evolução da espada e estatísticas
# =====================================================================
static func espada_custo(nivel: int) -> int:
	return [0, 0, 120, 280, 420, 520][clampi(nivel, 0, ESPADA_NIVEL_MAX)]

static func espada_nome() -> String:
	return "LÂMINA DE SYLLA"

static func espada_niveis() -> Array:
	return [
		{"nivel": 1, "itens": [{"tipo": "combo", "n": 1}, {"tipo": "especial", "acao": ACAO.ESPECIAL_3}], "texto": "O começo da jornada."},
		{"nivel": 2, "itens": [{"tipo": "especial", "acao": ACAO.ESPECIAL}], "texto": "+8% de dano."},
		{"nivel": 3, "itens": [{"tipo": "combo", "n": 2}], "texto": "+16% de dano."},
		{"nivel": 4, "itens": [{"tipo": "especial", "acao": ACAO.ESPECIAL_2}], "texto": "+24% de dano."},
		{"nivel": 5, "itens": [{"tipo": "combo", "n": 3}], "texto": "+32% de dano · fúria mais rápida"},
	]

static func espada_dano_mult() -> float:
	return 1 + 0.08 * (G.espada_nivel - 1)

static func furia_ganho_mult() -> float:
	return 1.35 if G.espada_nivel >= 5 else 1.0

static func combo_nivel_req(n: int) -> int:
	return 5 if n >= 3 else (3 if n == 2 else 1)

static func combo_liberado(n: int) -> bool:
	return G.espada_nivel >= combo_nivel_req(n)

static func especial_nivel_req(acao: int) -> int:
	if acao == ACAO.ESPECIAL:
		return 2
	if acao == ACAO.ESPECIAL_2:
		return 4
	return 1

static func especial_liberado(acao: int) -> bool:
	return G.espada_nivel >= especial_nivel_req(acao)

static func especial_nome(acao: int) -> String:
	if acao == ACAO.ESPECIAL:
		return "ONDA CARMESIM"
	if acao == ACAO.ESPECIAL_2:
		return "QUEDA CARMESIM"
	return "TREMOR DE VALLACK"

static func especial_custo(acao: int) -> float:
	if acao == ACAO.ESPECIAL:
		return 0.4
	if acao == ACAO.ESPECIAL_2:
		return 0.7
	return 0.6


# Solta orbs num ponto: viram bolinhas que voam sozinhas até o jogador
func orbs_soltar(px: float, py: float, total: float) -> void:
	var t := int(round(total))
	if t <= 0:
		return
	var grandes := t / 25
	var resto := t - grandes * 25
	var pequenos := resto / 5
	var uns := resto - pequenos * 5
	var lista := []
	for i in grandes:
		lista.append(25)
	for i in pequenos:
		lista.append(5)
	for i in uns:
		lista.append(1)
	for i in lista.size():
		var o = instance_create_depth(px + randf_range(-8, 8), py + randf_range(-8, 8), -120, "obj_orb")
		o.valor = lista[i]
		o.vx = randf_range(-2.6, 2.6)
		o.vy = randf_range(-4.2, -1.5)
		o.espera = 18 + i * 2


static func orbs_ganhar(n: float) -> void:
	G.orbs += n
	G.orbs_coletados += n
	G.orbs_fx = 20
	V117.perfil_somar("orbs", n)     # v1.17: conquista ALMAS SEM FIM


static func orbs_do_inimigo(inst) -> int:
	match inst.obj:
		"obj_besta_elite":
			return ORBS_BESTA * 3
		"obj_esqueleto_elite":
			return ORBS_ESQUELETO * 3
		"obj_alquimista":
			return ORBS_ARQUEIRO
		"obj_inimigo_01":
			return ORBS_BESTA
		"obj_inimigo_02":
			return ORBS_ARQUEIRO
		"obj_inimigo_03":
			return ORBS_ESCUDO
		"obj_mini_boss":
			return ORBS_MINI_BOSS
		"obj_boss_01":
			return ORBS_BOSS
		"obj_esqueleto":
			return ORBS_ESQUELETO
		"obj_aranha":
			return ORBS_ARANHA
		"obj_porco":
			return ORBS_PORCO
		"obj_estatua":
			return ORBS_ESTATUA
	return 5


# =====================================================================
# scr_v112: textos que sobem, diálogos, essência, sangue e fúria
# =====================================================================
func popup_criar(px: float, py: float, texto: String, cor: Color, escala := 1.0):
	var p = instance_create_depth(px, py, -160, "obj_popup")
	p.texto = texto
	p.cor = cor
	p.escala = escala
	return p


static func dialogo_falas(qual: String) -> Array:
	match qual:
		"morador":
			return [
				{"q": "morador", "t": "Senhor! Graças aos céus... Os servos de Vallack invadiram a vila!"},
				{"q": "twilight", "t": "Leve todos para a ponte do norte. Ninguém fica nas ruas: eu cuido deles."},
				{"q": "morador", "t": "E o fogo? Chove a noite inteira e as casas não param de queimar!"},
				{"q": "twilight", "t": "Não é fogo comum. Essas chamas roxas vêm do poder de Vallack. A chuva não as apaga."},
				{"q": "morador", "t": "Os anciãos dizem que só a água mágica do templo de Sylla apaga a chama maldita..."},
				{"q": "twilight", "t": "Então vou buscá-la, depois de abrir caminho até o castelo. Agora vá!"},
			]
		"carrasco_inicio":
			return [
				{"q": "carrasco", "t": "Mais um herói vindo morrer na estrada de Vallack."},
				{"q": "twilight", "t": "Saia da frente, Carrasco. Esta vila não pertence ao seu mestre."},
				{"q": "carrasco", "t": "Tudo pertence a Vallack. Até a sua cabeça... quando eu a cortar!"},
			]
		"carrasco_fase2":
			return [{"q": "carrasco", "t": "Você luta bem... Chega de brincadeira!"}]
		"carrasco_fim":
			return [
				{"q": "carrasco", "t": "Isso... não acaba aqui... A Árvore guarda a estrada..."},
				{"q": "twilight", "t": "Então ela é a próxima."},
			]
		"arvore_inicio":
			return [
				{"q": "arvore", "t": "Pequeno guerreiro... Minhas raízes beberam o sangue de mil invasores."},
				{"q": "twilight", "t": "Foi você quem espalhou a chama maldita pela vila?"},
				{"q": "arvore", "t": "A chama é de Vallack. Eu apenas a guardo. Nenhuma chuva vai apagá-la!"},
				{"q": "twilight", "t": "Então vou arrancá-la pela raiz."},
			]
		"arvore_fase2":
			return [{"q": "arvore", "t": "Sinta a floresta inteira se erguer contra você!"}]
		"arvore_fase3":
			return [{"q": "arvore", "t": "Vallack... me dê força... QUEIME!"}]
		"arvore_fim":
			return [
				{"q": "arvore", "t": "A chama... não morre comigo... só a água do templo..."},
				{"q": "twilight", "t": "Então é para o templo que eu vou."},
			]
	return []


static func dialogo_nome(q: String) -> String:
	match q:
		"twilight":
			return NOME_GUERREIRO.to_upper()
		"morador":
			return "MORADOR DA VILA"
		"carrasco":
			return "O CARRASCO DE VALLACK"
		"arvore":
			return "ÁRVORE AMALDIÇOADA"
	return ""


static func dialogo_cor(q: String) -> Color:
	match q:
		"twilight":
			return Color8(255, 210, 90)
		"morador":
			return Color8(200, 190, 170)
		"carrasco":
			return Color8(230, 90, 80)
		"arvore":
			return Color8(190, 110, 255)
	return c_white


static func dialogo_retrato(q: String) -> Array:
	match q:
		"twilight":
			return [Spr.spr_player_idle, 0, c_white]
		"morador":
			return [Spr.spr_morador_parado, 0, c_white]
		"carrasco":
			return [Spr.spr_inimigo01_parado, 0, Color8(175, 125, 140)]
		"arvore":
			return [Spr.spr_boss_01_parado, 0, c_white]
	return [null, 0, c_white]


# Abre um diálogo. ao_fim (opcional): função chamada quando ele fecha.
func dialogo_iniciar(qual: String, ao_fim = null):
	if instance_exists("obj_dialogo"):
		return null
	var falas := dialogo_falas(qual)
	if falas.is_empty():
		return null
	var d = instance_create_depth(0, 0, -10400, "obj_dialogo")
	d.falas = falas
	d.ao_fim = ao_fim
	return d


static func essencia_ganhar(n: int) -> void:
	G.essencia = clampi(G.essencia + n, 0, ESSENCIA_MAX)
	G.essencia_coletada += n
	G.essencia_fx = 20


func essencia_soltar(px: float, py: float, n: int) -> void:
	for i in n:
		var e = instance_create_depth(px + randf_range(-6, 6), py + randf_range(-6, 6), -121, "obj_essencia")
		e.vx = randf_range(-2.2, 2.2)
		e.vy = randf_range(-4.4, -2)


static func essencia_do_inimigo(inst) -> int:
	if inst.invocado or inst.eh_boss:
		return 0
	if inst.elite:
		return 3
	match inst.obj:
		"obj_porco":
			return 2
		"obj_inimigo_03":
			return 1 if randf() < 0.6 else 0
		"obj_estatua":
			return 1 if randf() < 0.6 else 0
		"obj_mini_boss":
			return 4
	return 1 if randf() < 0.35 else 0


static func subarma_custo(agachado: bool) -> int:
	return 2 if agachado else 1

static func subarma_nome(agachado: bool) -> String:
	return "CHAMA DE SYLLA" if agachado else "LÂMINA BUMERANGUE"


func furia_modo_ativo() -> bool:
	var p = instance_find("obj_player", 0)
	return p != null and p.furia_modo


# Sangue de um inimigo derrotado voando para a lâmina (enche a FÚRIA)
func sangue_soltar(px: float, py: float, n: int) -> void:
	if furia_modo_ativo():
		return
	var q := maxi(2, int(round(n * 0.5))) if G.cfg_qualidade == 0 else n
	var valor := n * 1.15 / q
	for i in q:
		var s = instance_create_depth(px + randf_range(-10, 10), py + randf_range(-16, 8), -122, "obj_sangue")
		s.valor = valor
		s.vx = randf_range(-1.6, 1.6)
		s.vy = randf_range(-3, -1)


static func sangue_do_inimigo(inst) -> int:
	if inst.invocado:
		return 2
	if inst.elite:
		return 14
	match inst.obj:
		"obj_porco":
			return 12
		"obj_mini_boss":
			return 30
		"obj_boss_01":
			return 0
		"obj_inimigo_03":
			return 8
		"obj_estatua":
			return 8
	return 6


# Cristal de essência (no mundo e no HUD)
func essencia_desenhar(px: float, py: float, k := 1.0, alfa := 1.0) -> void:
	var b := 0.7 + 0.3 * sin(current_time() / 120.0)
	gpu_set_blendmode(bm_add)
	draw_set_alpha(0.35 * b * alfa)
	draw_set_color(Color8(80, 160, 255))
	draw_circle(px, py, 9 * k, false)
	gpu_set_blendmode(bm_normal)
	draw_set_alpha(alfa)
	draw_set_color(Color8(60, 130, 255))
	draw_triangle(px, py - 7 * k, px + 5 * k, py, px - 5 * k, py, false)
	draw_triangle(px - 5 * k, py, px + 5 * k, py, px, py + 7 * k, false)
	draw_set_color(Color8(210, 235, 255))
	draw_triangle(px, py - 7 * k, px + 2 * k, py - 1 * k, px - 2 * k, py - 1 * k, false)
	draw_set_color(c_white)
	draw_set_alpha(1)


# =====================================================================
# scr_cenario: cenário destrutível, baús, armadilhas, arenas e chamas
# =====================================================================
# efeitos de ambiente bem longe da câmera somem antes de alguém chegar lá:
# não são criados (no celular, cada instância a menos conta)
const FX_AMBIENTE := ["fumaca", "brasas", "fumaca_maldita", "poeira"]
const FX_MARGEM := 360.0


# efeitos só de partículas (sem clarão próprio): todos os da mesma profundidade
# ficam numa instância só, na ordem em que nasceram (o desenho é o mesmo)
const FX_LOTE := ["fumaca", "brasas", "fumaca_maldita", "sangue", "lascas", "entulho", "escudo_quebrado", "chamas_corpo"]


func fx_em(tipo: String, px: float, py: float, tam := 1.0, d := 1.0, prof := -110):
	if tipo in FX_AMBIENTE and (px < G.view_x - FX_MARGEM or px > G.view_x + G.view_w + FX_MARGEM \
			or py < G.view_y - FX_MARGEM or py > G.view_y + G.view_h + FX_MARGEM):
		return null
	if tipo in FX_LOTE:
		var lote = G.fx_lotes.get(prof)
		if lote == null or lote._destruido:
			lote = instance_create_depth(0, 0, prof, "obj_fx")
			lote.lote = true
			lote.gen = true
			G.fx_lotes[prof] = lote
		lote.lote_adicionar(tipo, px, py, tam, d)
		return lote
	var f = instance_create_depth(px, py, prof, "obj_fx")
	f.tipo = tipo
	f.tam = tam
	f.dir = d
	f.fx_iniciar()
	return f


# =====================================================================
# v1.18: ORÇAMENTO DOS EFEITOS DE COMBATE (o mesmo da versão PC, scr_cenario)
# Cada acerto criava faíscas + corte + explosão de fogo (+ corte em X, rajada,
# sangue) e um clarão; acertando vários inimigos tudo se empilhava no mesmo
# ponto, sujava a tela e derrubava o FPS do celular.
#  * decorativos iguais quase no mesmo lugar e na mesma hora viram um só;
#  * quanto maior a "carga" (efeitos recentes), menos partículas; com a tela
#    cheia os decorativos são descartados;
#  * no máximo um clarão a cada FX_FLASH_MS.
# Os que AVISAM algo (aparar, escudo, ondas/rachaduras, destrutíveis,
# ambiente) não passam por aqui. No celular os limites são mais baixos.
# =====================================================================
const FX_LIMITE := 9.0         # PC: 14
const FX_MEIA_VIDA := 350.0    # ms para a carga cair pela metade
const FX_PERTO := 28.0
const FX_PERTO_MS := 90
const FX_FLASH_MS := 70
const FX_BASE := 0.65          # PC: 0.8
const FX_DECORATIVOS := ["faiscas_golpe", "sangue", "corte", "corte_lua", "corte_x", "explosao_fogo",
	"rajada", "chamas_estouro", "chamas_morte", "fumaca_maldita_estouro", "poeira"]


# multiplicador de partículas do efeito; 0 = não criar
func fx_orcamento(tipo: String, px: float, py: float) -> float:
	if not tipo in FX_DECORATIVOS:
		return 1.0
	var agora := Time.get_ticks_msec()
	G.fx_carga *= pow(0.5, (agora - G.fx_carga_t) / FX_MEIA_VIDA)
	G.fx_carga_t = agora
	var r: Array = G.fx_recentes
	for i in range(r.size() - 1, -1, -1):
		var e: Array = r[i]
		if agora - e[3] > FX_PERTO_MS:
			r.remove_at(i)
			continue
		if e[0] == tipo and absf(e[1] - px) < FX_PERTO and absf(e[2] - py) < FX_PERTO:
			return 0.0
	r.append([tipo, px, py, agora])
	G.fx_carga += 1.0
	var excesso := G.fx_carga / FX_LIMITE
	if excesso >= 2.5:
		return 0.0
	return FX_BASE * clampf(1.6 - 0.6 * excesso, 0.3, 1.0)


func fx_flash_livre() -> bool:
	var agora := Time.get_ticks_msec()
	if agora - G.fx_flash_t < FX_FLASH_MS:
		return false
	G.fx_flash_t = agora
	return true


# TERRENO (estilo Castlevania): ABISMOS onde quem cai morre e PLATAFORMAS
# para pular por cima. A mesma tabela existe na versão PC (GameMaker).
#   chao: topo do chão da fase · abismos: [[x1, x2]] · plataformas: [[x1, x2, y_topo]]
# Vãos de até ~120 px (o pulo alcança ~200). Plataformas sobre chão ficam
# 88 px acima dele (o pulo cheio sobe ~98): por baixo sobram 72 px e o
# herói (66 px) passa sem enroscar.
const PLATAFORMA_ALT := 16.0
const DEGRAU_MAX := 9          # degraus até esta altura são subidos andando (escadarias)
const PECA_ESC := 0.7          # escala de desenho das peças do Alex (atlas pecas_fase1)


# v1.13 — FASE EM ANDARES (a mesma tabela da versão PC, scr_cenario):
#   escadas: [[x_chao, x_alto, y_alto]] degraus de madeira (8 px) que sobem andando
#   blocos:  [[x1, x2, y_topo]] torre de vigia de madeira (sólida) do topo até o chão
#   pontes:  [[x1, x2, y]] passarela de madeira de MÃO ÚNICA (obj_plataforma)
#   ilhas:   [[x_centro, y_topo, "peça"]] ilha de terra flutuante (mão única)
#   plataformas: [[x1, x2, y, alto?]] laje sólida (alto = 1: andaime alto de madeira)
#   ruinas:  [["peça", x, espelho]] ruínas e pilares na frente das casas
#   mover:   [[objeto, x1, x2, x_novo, y_novo]] tira um inimigo da rua e põe no alto
#   caixotes: [[x, y]] caixotes com orbs nos caminhos de cima
#   arvores: [[x, espelho]] árvores assombradas (animadas) na estrada
#   remover: objetos de decoração que saem da fase (os pedaços de castelo)
static func terreno_dados(sala: String) -> Dictionary:
	var vazio := {"escadas": [], "blocos": [], "pontes": [], "ilhas": [], "ruinas": [], "mover": [], "caixotes": [], "arvores": [], "remover": [],
		"escalar": [], "pontes_corda": [], "suspensas": [], "chave": {}, "portao": [], "pontes_queda": [], "frageis": []}
	if sala == "Room1":
		return {"chao": 693.0, "madeira": true,
			# v1.20: mais buracos e maiores. Os dois com piso frágil (1020 e 4010) só se
			# atravessam pisando nas lajes; os das pontes ficam em "pontes_queda"
			"abismos": [[1020.0, 1225.0], [4010.0, 4200.0]],
			# v1.20 — PONTES QUE DESABAM [x1, x2, "madeira" | "pedra"]: abrem o próprio abismo
			# (bem mais fundo: a câmera desce) e caem trecho a trecho atrás de quem corre
			"pontes_queda": [[1335.0, 1545.0, "madeira"], [1785.0, 2122.0, "pedra"]],
			# v1.20 — PISO FRÁGIL [x1, x2, y]: laje que treme quando pisada e cai se o
			# herói demorar em cima; volta depois de um tempo
			"frageis": [[1062.0, 1104.0, 693.0], [1142.0, 1184.0, 693.0], [4050.0, 4092.0, 693.0], [4124.0, 4166.0, 693.0]],
			# (o forte de madeira 2120..2330 em y 360 é o chão da arena da chave)
			"plataformas": [[1546.0, 1632.0, 605.0], [1700.0, 1776.0, 585.0], [950.0, 1250.0, 470.0, 1], [2120.0, 2330.0, 360.0]],
			"escadas": [[318.0, 406.0, 605.0], [3442.0, 3530.0, 605.0]],
			"blocos": [[3530.0, 3594.0, 605.0]],
			"pontes": [[402.0, 700.0, 605.0], [3594.0, 3700.0, 605.0]],
			"ilhas": [[775.0, 548.0, "chao15"], [890.0, 500.0, "chao17"], [1862.0, 540.0, "chao15"],
				[3762.0, 585.0, "chao15"], [3862.0, 556.0, "chao17"]],
			# v1.14 — ESCALAR: [x, y do alto, y de baixo, "escada" | "corda" | "corrente",
			# saída no alto (-1 esquerda, 1 direita, 0 reto para cima)]
			"escalar": [[1236.0, 470.0, 640.0, "corda", 0],                # corda pendurada no andaime (pula e agarra)
				[2142.0, 590.0, 693.0, "escada", 1],               # sobe para as plataformas penduradas do forte
				[2346.0, 360.0, 548.0, "corda", -1]],              # a corda até o alto do forte (a arena da chave)
			"pontes_corda": [],                                    # v1.20: a ponte de corda virou a ponte de madeira que desaba
			# plataformas penduradas: [x1, x2, y, y das cordas no alto, poste da forca (-1 = presa no forte)]
			"suspensas": [[2142.0, 2212.0, 590.0, 376.0, -1.0], [2246.0, 2304.0, 540.0, 376.0, -1.0]],
			# a CHAVE DO PORTÃO: baú selado no alto do forte; ao chegar, os guardiões surgem
			"chave": {"bau": [2226.0, 360.0], "arena": [2128.0, 2322.0, 360.0],
				"guardioes": [["obj_esqueleto", 2164.0], ["obj_inimigo_01", 2296.0], ["obj_aranha", 2250.0]]},
			"portao": [2470.0],                                    # portão trancado no meio da fase
			"ruinas": [],
			# v1.13: sem os pedaços de castelo espalhados pela vila
			"remover": ["obj_muralha_fundo", "obj_ruina_fundo", "obj_coluna", "obj_coluna_quebrada", "obj_balaustrada", "obj_portao", "obj_tocha", "obj_caverna"],     # v1.19: sem o buraco de caverna
			# v1.14: inimigos espalhados pela fase (antes vinham em bandos de 3 a 5;
			# ninguém fica dentro das arenas do mini-chefe 2510..3150 e do chefe)
			"mover": [["obj_inimigo_02", 3400.0, 3620.0, 3562.0, 584.0],
				["obj_inimigo_01", 930.0, 940.0, 1600.0, 600.0], ["obj_inimigo_01", 970.0, 980.0, 2200.0, 672.0],
				["obj_inimigo_01", 1985.0, 1995.0, 2300.0, 672.0],      # v1.20: saem de cima da ponte de pedra
				["obj_besta_elite", 2060.0, 2080.0, 2380.0, 672.0], ["obj_inimigo_03", 2150.0, 2170.0, 3740.0, 672.0],
				["obj_estatua", 2250.0, 2275.0, 1738.0, 580.0], ["obj_porco", 3180.0, 3192.0, 3250.0, 672.0],
				["obj_esqueleto_elite", 3400.0, 3410.0, 3380.0, 672.0], ["obj_esqueleto", 3280.0, 3292.0, 3930.0, 672.0],
				["obj_aranha", 3445.0, 3460.0, 4270.0, 672.0]],
			"caixotes": [[1090.0, 470.0], [1124.0, 470.0], [1180.0, 470.0]],
			"arvores": []}            # v1.13: sem árvores assombradas (pareciam outros chefes)
	if sala == "Room2":
		var d := {"chao": 682.0, "madeira": false,
			"abismos": [[1760.0, 1880.0], [3380.0, 3480.0], [3600.0, 3722.0]],
			"plataformas": [[1792.0, 1848.0, 616.0], [2650.0, 2750.0, 594.0], [2790.0, 2880.0, 550.0], [3636.0, 3690.0, 620.0]],
			"escalar": [[2786.0, 550.0, 682.0, "corrente", 1], [2646.0, 594.0, 682.0, "corrente", 1]]}     # correntes do salão
		d.merge(vazio)
		return d
	var r := {"chao": 0.0, "madeira": false, "abismos": [], "plataformas": []}
	r.merge(vazio)
	return r


# v1.14: a CHAVE DO PORTÃO desenhada por código (argola, haste e dentes, dourada);
# giro (-1..1) achata na horizontal para parecer que ela gira no ar
func desenhar_chave(px: float, py: float, esc := 1.0, giro := 1.0) -> void:
	var sx := maxf(0.15, absf(giro)) * esc
	var ouro := Color8(236, 186, 70)
	draw_set_color(Color8(140, 92, 26))
	draw_ellipse(px - 6 * sx, py - 12 * esc, px + 6 * sx, py - 1 * esc, false)
	draw_set_color(ouro)
	draw_ellipse(px - 5 * sx, py - 11 * esc, px + 5 * sx, py - 2 * esc, false)
	draw_set_color(Color8(40, 24, 10))
	draw_ellipse(px - 2 * sx, py - 8 * esc, px + 2 * sx, py - 5 * esc, false)
	draw_set_color(ouro)
	draw_rectangle(px - 1.2 * sx, py - 2 * esc, px + 1.2 * sx, py + 12 * esc, false)
	draw_rectangle(px + 1.2 * sx, py + 7 * esc, px + 5 * sx, py + 9 * esc, false)
	draw_rectangle(px + 1.2 * sx, py + 10.5 * esc, px + 4 * sx, py + 12 * esc, false)
	draw_set_color(Color8(255, 240, 190))
	draw_line(px - 3 * sx, py - 10 * esc, px - 1 * sx, py - 11 * esc)
	draw_set_color(c_white)


# [x, y, w, h] de uma peça do atlas do Alex (ou [] se não houver)
static func peca(nome: String) -> Array:
	return atlas_pecas.get(nome, [])


# desenha a peça com a base em (x esquerda, base); esp espelha
static func peca_desenhar(nome: String, x: float, base: float, esp := false, tom := Color.WHITE, esc := PECA_ESC) -> void:
	var p := peca(nome)
	if p.is_empty():
		return
	var w: float = p[2] * esc
	var h: float = p[3] * esc
	if esp:
		G.pen.textura_parte(pecas_tex, p[0], p[1], p[2], p[3], x + w, base - h, -esc, esc, tom, 1)
	else:
		G.pen.textura_parte(pecas_tex, p[0], p[1], p[2], p[3], x, base - h, esc, esc, tom, 1)


# enche o retângulo com a peça repetida (alinhada ao mundo); o fundo escuro
# vira a argamassa entre as pedras
static func peca_encher(nome: String, x1: float, y1: float, x2: float, y2: float, tom := Color.WHITE) -> void:
	var p := peca(nome)
	if p.is_empty() or x2 <= x1 or y2 <= y1:
		return
	G.pen.retangulo(x1, y1, x2 - 1, y2 - 1, Color8(30, 22, 22), 1.0, false)
	var tw: float = p[2] * PECA_ESC
	var th: float = p[3] * PECA_ESC
	var xx := floorf(x1 / tw) * tw
	while xx < x2:
		var a := maxf(xx, x1)
		var b := minf(xx + tw, x2)
		if b > a:
			var yy := y1
			while yy < y2:
				var hh := minf(th, y2 - yy)
				G.pen.textura_parte(pecas_tex, p[0] + (a - xx) / PECA_ESC, p[1], (b - a) / PECA_ESC, hh / PECA_ESC, a, yy, PECA_ESC, PECA_ESC, tom, 1)
				yy += th
		xx += tw


# tábuas verticais de madeira enchendo o retângulo (escadas e torre de vigia);
# semente varia o tom das tábuas
static func madeira_tabuas(x1: float, y1: float, x2: float, y2: float, semente := 0) -> void:
	if x2 <= x1 or y2 <= y1:
		return
	G.pen.retangulo(x1, y1, x2 - 1, y2 - 1, Color8(30, 20, 12), 1.0, false)
	var xx := x1
	while xx < x2:
		var w := minf(8.0, x2 - xx)
		var s := (int(floorf(xx / 8.0)) + semente) % 3
		var c := Color8(92, 62, 38) if s == 0 else (Color8(80, 54, 32) if s == 1 else Color8(100, 68, 42))
		var c2 := c.lerp(Color.BLACK, 0.35)
		G.pen.retangulo_cores(xx, y1, xx + maxf(1.0, w - 2), y2 - 1, c, c, c2, c2, 1.0)
		xx += 8


# ---------------------------------------------------------------------
# PLATAFORMAS DE MÃO ÚNICA (obj_plataforma): o herói sobe pulando por baixo,
# pousa em cima e desce com ▼ + PULO. Não é filha do obj_chao; o topo é o y.
# ---------------------------------------------------------------------
func plataforma_sob_pes():
	if obj != "obj_player" or get("atravessar_t") > 0 or get("velv") < 0:
		return null
	for p in G.listas.get("obj_plataforma", []):
		if not p._ativo:
			continue
		if absf(y - p.y) <= 1.0 and bbox_right >= p.bbox_left and bbox_left <= p.bbox_right:
			return p
	return null


# plataforma onde o herói pousa ao cair mv px neste passo (End Step do obj_entidade)
func plataforma_pouso(mv: float):
	if obj != "obj_player" or mv <= 0 or get("atravessar_t") > 0:
		return null
	var melhor = null
	for p in G.listas.get("obj_plataforma", []):
		if not p._ativo or bbox_right < p.bbox_left or bbox_left > p.bbox_right:
			continue
		if y <= p.y + 0.5 and y + mv >= p.y and (melhor == null or p.y < melhor.y):
			melhor = p
	return melhor


func terreno_ponte(x1: float, x2: float, py: float) -> GMObj:
	var b := instance_create_depth(x1, py, 0, "obj_plataforma")
	b.image_xscale = (x2 - x1) / 20.0
	b.image_yscale = 8.0 / 35.0
	return b


# bloco sólido de x1..x2, de y1 até y2
func terreno_bloco(x1: float, x2: float, y1: float, y2: float) -> GMObj:
	var b := instance_create_depth(x1, y1, 0, "obj_chao")
	b.image_xscale = (x2 - x1) / 20.0
	b.image_yscale = (y2 - y1) / 35.0
	G.chao_sujo = true
	return b


# degraus de 8 px do chão (xa) até y_alto (xb)
func terreno_escada(xa: float, xb: float, y_alto: float, chao_y: float) -> void:
	var n := maxi(1, roundi((chao_y - y_alto) / 8.0))
	var lw := absf(xb - xa) / n
	for k in n:
		var x1 := xa + k * lw if xb > xa else xa - (k + 1) * lw
		terreno_bloco(x1, x1 + lw, chao_y - (k + 1) * 8, chao_y)


# tira a decoração de chão que ficaria dentro de um bloco ou escada
func terreno_limpar(x1: float, x2: float) -> void:
	for s in todos("obj_solido"):
		var dono = s.get("dono")
		if s.bbox_right > x1 and s.bbox_left < x2 and not (G.existe(dono) and dono.obj == "obj_caixote"):
			instance_destroy(s)
	var lote = instance_find("obj_mato_lote", 0)
	if lote != null:
		lote.remover_faixa(x1 - 4, x2 + 4)
	for tipo in ["obj_mato", "obj_pedras", "obj_tronco", "obj_barril", "obj_lampiao", "obj_placa"]:
		for o in todos(tipo):
			if o.x > x1 - 10 and o.x < x2 + 10:
				instance_destroy(o)
	G.chao_sujo = true


# Abre um abismo no chão entre x1 e x2: corta os blocos de chão (o do
# nível do chão e os de apoio embaixo) e tira a decoração que ficava ali
func terreno_abrir(x1: float, x2: float, chao_y: float) -> void:
	var cortar := []
	for c in todos("obj_chao"):
		if c.obj == "obj_chao" and c.image_xscale > 0 and c.y >= chao_y - 4 and c.x < x2 and c.x + 20 * c.image_xscale > x1:
			cortar.append(c)
	for c in cortar:
		var l: float = c.x
		var r: float = c.x + 20 * c.image_xscale
		var t: float = c.y
		var ys: float = c.image_yscale
		var dep: int = c.depth
		instance_destroy(c)
		if x1 > l:
			var e := instance_create_depth(l, t, dep, "obj_chao")
			e.image_xscale = (x1 - l) / 20.0
			e.image_yscale = ys
		if r > x2:
			var d := instance_create_depth(x2, t, dep, "obj_chao")
			d.image_xscale = (r - x2) / 20.0
			d.image_yscale = ys
	# sólidos de obstáculos que ficavam no vão (pedras, troncos...)
	for s in todos("obj_solido"):
		if s.bbox_right > x1 and s.bbox_left < x2:
			instance_destroy(s)
	# mato (no lote) e objetos de chão que ficariam flutuando sobre o abismo
	var lote = instance_find("obj_mato_lote", 0)
	if lote != null:
		lote.remover_faixa(x1 - 6, x2 + 6)
	for tipo in ["obj_mato", "obj_pedras", "obj_tronco", "obj_barril", "obj_lampiao", "obj_placa"]:
		for o in todos(tipo):
			if o.x > x1 - 14 and o.x < x2 + 14:
				instance_destroy(o)
	G.chao_sujo = true


# Bloco sólido de uma plataforma (pula-se nela; por baixo, bate a cabeça)
func terreno_plataforma(x1: float, x2: float, py: float) -> GMObj:
	var b := instance_create_depth(x1, py, 0, "obj_chao")
	b.image_xscale = (x2 - x1) / 20.0
	b.image_yscale = PLATAFORMA_ALT / 35.0
	G.chao_sujo = true
	return b


# CENÁRIO DA FASE 1 desenhado por código (carregado em LibBase.cenario_carregar)
# desenha uma peça com a base (pé) em base; esp = espelhada
func cenario_peca(p: Dictionary, x: float, base: float, esp: bool, cor := Color.WHITE, s := 1.0) -> void:
	var w: float = p["w"]
	var h: float = p["h"]
	# v1.17: escala (as casas do cenário com o dobro do tamanho, pixel art nítida)
	if esp:
		G.pen.textura_parte(cen_tex, p["x"], p["y"], w, h, x + w * s, base - h * s, -s, s, cor, 1)
	else:
		G.pen.textura_parte(cen_tex, p["x"], p["y"], w, h, x, base - h * s, s, s, cor, 1)


# x de uma âncora da peça no mundo (respeita o espelho e a escala)
static func cenario_ax(p: Dictionary, x: float, esp: bool, ax: float, s := 1.0) -> float:
	return x + (float(p["w"]) - ax) * s if esp else x + ax * s


# faixa distante que se repete e anda mais devagar que a câmera (parallax)
#  fx: 0 = presa à câmera, 1 = presa ao mundo · deriva: deslocamento extra (nuvens)
func cenario_faixa(p: Dictionary, vx: float, vw: float, fx: float, yb: float, deriva := 0.0) -> void:
	var w: float = p["w"]
	var h: float = p["h"]
	var ox := vx * (1 - fx) - deriva
	var x := ox + floorf((vx - ox) / w) * w
	while x < vx + vw:
		G.pen.textura_parte(cen_tex, p["x"], p["y"], w, h, round(x), round(yb - h), 1, 1, c_white, 1)
		x += w


# GOLPE FATAL (estilo Castlevania): o tempo congela, desacelera e o monstro
# explode em chamas. A câmera lenta tem intervalo, para não arrastar as hordas.
func golpe_fatal(px: float, py: float, d: float, tam: float) -> void:
	impacto(7)
	camera_empurrar(d, 6, -0.3)
	G.camera_impact = maxf(G.camera_impact, 9)
	G.last_hit_flash = maxf(G.last_hit_flash, 7)
	if G.fatal_t <= 0:
		camera_lenta(16, 0.35)
		G.fatal_t = 75
	fx_em("chamas_morte", px, py, tam, d, -105)
	som("fogo_explosao", 0.45, 0.1)


# BLOCO SÓLIDO de um objeto destrutível (caixote, parede, muralha mágica)
func solido_criar(x1: float, y1: float, x2: float, y2: float):
	var s = instance_create_depth(x1, y1, 0, "obj_solido")
	s.image_xscale = maxf(0.05, (x2 - x1) / 20.0)
	s.image_yscale = maxf(0.05, (y2 - y1) / 35.0)
	s.dono = self
	G.chao_sujo = true
	return s


static func solido_mover(s, x1: float, y1: float) -> void:
	if G.existe(s):
		if s.x != x1 or s.y != y1:
			s.x = x1
			s.y = y1
			G.chao_sujo = true


static func solido_remover(s) -> void:
	if s != null and s is GMObj and not s._destruido:
		G.destruir(s)


# ARENA: muralhas mágicas que fecham uma área (mini-boss e boss)
func arena_fechar(x1: float, x2: float, y_chao: float, dono) -> Array:
	var e = instance_create_depth(x1, y_chao, -60, "obj_parede_magica")
	var d = instance_create_depth(x2, y_chao, -60, "obj_parede_magica")
	e.dono = dono
	e.lado = -1
	d.dono = dono
	d.lado = 1
	e.parede_erguer()
	d.parede_erguer()
	G.cam_lim_esq = x1 - 30
	G.cam_lim_dir = x2 + 30
	# v1.12: luta de chefe sem inimigos comuns
	for i in todos("obj_inimigo_base"):
		if i == dono or i.eh_boss or i.morrendo or i.obj == "obj_mini_boss" or i.x <= x1 or i.x >= x2:
			continue
		fx_em("chamas_estouro", i.x, i.y - 30, 1)
		instance_destroy(i)
	som("sfx_portal", 0.9, 0)
	G.camera_impact = maxf(G.camera_impact, 8)
	return [e, d]


func arena_abrir(dono) -> void:
	for p in todos("obj_parede_magica"):
		if p.dono == dono:
			p.parede_baixar()
	G.cam_lim_esq = 0
	G.cam_lim_dir = G.room_width


func arena_limitar_x(px: float, margem := 30.0) -> float:
	var r := px
	for p in todos("obj_parede_magica"):
		if not p.ativa:
			continue
		if p.lado < 0:
			r = maxf(r, p.x + margem)
		else:
			r = minf(r, p.x - margem)
	return r


# LIMPEZA DA SALA AO VOLTAR DO CHECKPOINT: quem ficou para trás não renasce
func sala_limpar_checkpoint() -> void:
	if not G.checkpoint_ativo or G.checkpoint_room != G.room:
		return
	var cx := G.checkpoint_x
	for i in todos("obj_inimigo_base"):
		if not i.eh_boss and not i.invocado and i.obj != "obj_mini_boss" and i.x < cx - 280:
			instance_destroy(i)
	for i in todos("obj_mini_boss"):
		if i.x < cx - 280:
			instance_destroy(i)
	for i in todos("obj_viga_fogo"):
		if i.x < cx - 200:
			instance_destroy(i)


# ARMADILHAS: ferem o jogador (não dá para defender)
func armadilha_area(x1: float, y1: float, x2: float, y2: float, dano_jogador: float, dano_inimigo: float, lista: Array, forca := 4.0) -> void:
	var p = instance_find("obj_player", 0)
	if p != null and not p.morto and rectangle_in_rectangle(x1, y1, x2, y2, p.bbox_left, p.bbox_top, p.bbox_right, p.bbox_bottom) > 0:
		var antes: float = p.vida
		p.levar_dano(maxf(1, round(dano_jogador * dif_dano_inimigo())), (x1 + x2) / 2.0, false, forca, null)
		if p.vida < antes and not p.morto:
			p.velv = minf(p.velv, -3)
	if dano_inimigo <= 0 or not ARMADILHA_FERE_INIMIGOS:
		return
	for e in collision_rectangle_list(x1, y1, x2, y2, "obj_inimigo_base"):
		if e.morrendo or not e.ativo or e.eh_boss or lista.has(e):
			continue
		lista.append(e)
		e.levar_dano(dano_inimigo, (x1 + x2) / 2.0, false, 3, null)


# Chamas desenhadas por código. paleta: 0 maldita (roxa), 1 Sylla (dourada), 2 comum
static func chamas_cores(paleta: int) -> Array:
	match paleta:
		1:
			return [Color8(200, 120, 10), Color8(255, 200, 60), Color8(255, 250, 200), Color8(255, 200, 80)]
		2:
			return [Color8(200, 40, 10), Color8(255, 120, 30), Color8(255, 220, 120), Color8(255, 110, 30)]
	return [Color8(110, 20, 170), Color8(190, 70, 255), Color8(240, 200, 255), Color8(160, 60, 255)]


static func cor_chama_maldita() -> Color:
	return Color8(165, 80, 255)


# =====================================================================
# v1.19: FOGO COM LÓGICA DE INCÊNDIO (o mesmo de scr_cenario no PC).
# Antes: uma fileira de triângulos iguais sobre uma reta. Agora cada chama é
# uma LÍNGUA (base larga, cintura, ponta torta que some no ar), nascendo ao
# longo de uma LINHA da construção (beiral, água do telhado, borda quebrada,
# escombros), dos ROMBOS e das JANELAS; altura irregular, vento deitando as
# pontas para o mesmo lado e labaredas soltas que sobem e se apagam.
# =====================================================================
static func chama_hash(a: float, b: float) -> float:
	var v := sin(a * 12.9898 + b * 78.233) * 43758.5453
	return v - floorf(v)


# uma língua de fogo: a gota de 5 pontos do Pen (base fraca que funde com o que
# queima, barriga larga e forte, ponta torta que some no ar). As cores já vêm de
# pen.cor(), calculadas uma vez por foco.
func _chama_lingua(pen: Pen, bx: float, by: float, w: float, h: float, lean: float, cbase: Color, cbarriga: Color, cponta: Color) -> void:
	pen.gota(bx, by, w, h, lean, cbase, cbarriga, cponta)


# o fogo ao longo da linha (x1,y1)-(x2,y2); as chamas sempre sobem.
#  tipo: 0 telhado / borda, 1 rombo (labareda), 2 janela (vão aceso + línguas
#  saindo da verga; a linha é o retângulo do vão), 3 escombros (baixas, com falhas)
#  alt: altura já na escala do mundo · esc: escala da peça (espaço e largura das
#  línguas) · lod: 0 completo, 1 sem a camada do meio, 2 também sem labaredas soltas
func chamas_linha(x1: float, y1: float, x2: float, y2: float, alt: float, t: float, forca: float, sem: float,
		paleta := 0, tipo := 0, esc := 1.0, lod := 0) -> void:
	if forca <= 0.01:
		return
	var pen: Pen = G.pen
	var pc := chamas_cores(paleta)
	var add_antes := pen.blend_add
	pen.blend_add = true
	var pulso := 1.0
	if tipo == 2:
		# o vão da janela: o fogo lá dentro ilumina de baixo, tremendo
		var jx1 := minf(x1, x2)
		var jx2 := maxf(x1, x2)
		var jw := jx2 - jx1
		var jh := y2 - y1
		var fj := 0.6 + 0.4 * sin(t * 0.31 + sem) * sin(t * 0.13 + sem * 3)
		var cj1 := pen.cor(pc[0], 0.3 * forca * fj)
		var cj2 := pen.cor(pc[1], 0.45 * forca * fj)
		pen.poligono_convexo(PackedVector2Array([Vector2(jx1, y1), Vector2(jx2, y1), Vector2(jx2, y2), Vector2(jx1, y2)]), PackedColorArray([cj1, cj1, cj2, cj2]))
		# a chama dentro do cômodo, vista pelo vão
		if lod == 0:
			pen.gota((jx1 + jx2) / 2.0, y2, jw * 0.28, jh * (0.55 + 0.3 * fj), jh * 0.12, pen.cor(pc[1], 0.2 * forca), pen.cor(pc[2], 0.4 * forca), pen.cor(pc[2], 0.0))
		# e de vez em quando ela lambe para fora pela verga e sobe pela parede
		pulso = clampf(sin(t * 0.045 + sem * 2.3) * 1.5 + 0.35, 0, 1)
		y2 = y1
	var compr := Vector2(x1, y1).distance_to(Vector2(x2, y2))
	var passo := (6.0 if tipo == 3 else 9.0) * esc * (1 + lod * 0.5)
	var n := 3 if tipo == 1 else (1 if tipo == 2 else maxi(2, int(round(compr / passo))))
	if tipo == 1:
		# o calor saindo do rombo (brilho baixo e pequeno, sem virar disco)
		pen.elipse(x1 - 3 * esc, y1 - alt * 0.45, x2 + 3 * esc, y2 + 2 * esc, pc[3], 0.08 * forca, false)
	if tipo != 2:
		# a faixa em brasa ao longo da linha: as línguas brotam dela (não ficam soltas)
		var hb := alt * forca * (0.22 + 0.06 * sin(t * 0.17 + sem))
		var ex := 2 * esc if tipo == 1 else 0.0
		var cb := pen.cor(pc[1], 0.42 * forca)
		var ct := pen.cor(pc[0], 0.0)
		pen.poligono_convexo(PackedVector2Array([Vector2(x1 - ex, y1 + esc), Vector2(x2 + ex, y2 + esc), Vector2(x2 + ex, y2 - hb), Vector2(x1 - ex, y1 - hb)]),
			PackedColorArray([cb, cb, ct, ct]))
	var vel := 1.5 if tipo == 1 else 1.0
	# as cores das camadas, uma vez por foco
	var o0 := pen.cor(pc[0], 0.31 * forca)
	var o1 := pen.cor(pc[1], 0.62 * forca)
	var o2 := pen.cor(pc[1], 0.0)
	var m0 := pen.cor(pc[1], 0.3 * forca)
	var m1 := pen.cor(pc[2], 0.6 * forca)
	var m2 := pen.cor(pc[2], 0.0)
	for i in n:
		var h1 := chama_hash(i + 1, sem)
		var h2 := chama_hash(i + 7, sem * 1.7 + 0.3)
		var h3 := chama_hash(i + 13, sem * 0.3 + 0.7)
		if tipo == 3 and h3 < 0.22:
			continue                    # escombros: falhas entre os focos
		var u := clampf((i + 0.5 + (h1 - 0.5) * 0.7) / n, 0, 1)
		var bx := lerpf(x1, x2, u)
		var by := lerpf(y1, y2, u)
		# altura irregular ao longo da linha (sem simetria) e viva no tempo
		var env := 0.55 + 0.45 * (0.5 + 0.5 * sin(u * 5.3 + sem * 1.3) * sin(u * 2.1 + sem * 0.7 + 1.1))
		var ponta := minf(1.0, minf(u, 1 - u) * 5 + 0.35)     # nas pontas da linha o fogo é mais baixo
		if tipo == 1:
			env = 1.0 if i == 1 else 0.6
			ponta = 1.0
		elif tipo == 2:
			ponta = 1.0
		var fl := 0.7 + 0.3 * (0.6 * sin(t * 0.23 * vel + h1 * 6.28) + 0.4 * sin(t * 0.57 * vel + h2 * 6.28))
		var h := alt * forca * env * ponta * fl * pulso * (0.6 + 0.8 * h2)
		if h < 2:
			continue
		var w: float
		if tipo == 1:
			w = compr / 2.4 + 2 * esc
		elif tipo == 2:
			w = maxf(compr / 3.0, 2 * esc)
		else:
			w = passo * 0.75
		w = minf(w * (0.7 + 0.6 * h3), h * 0.42)      # chama é mais alta que larga
		var lean := h * (0.16 + 0.12 * sin(t * 0.11 * vel + h1 * 9))     # o vento deita as pontas para a direita
		pen.gota(bx, by + esc, w, h, lean, o0, o1, o2)
		if lod == 0:
			pen.gota(bx, by + esc * 0.5, w * 0.55, h * 0.72, lean * 0.7, m0, m1, m2)
		# o miolo claro: um triângulo só (barato); de longe nem aparece
		if lod < 2:
			pen.triangulo(bx - w * 0.28, by, bx + w * 0.28, by, bx + lean * 0.3, by - h * 0.36, pc[2], 0.42 * forca, false)
		# labareda que se solta da ponta, sobe e se apaga
		if lod < 2 and h1 < 0.3 and h > 10 * esc:
			var ph := fposmod(t * 0.018 * vel + h2, 1.0)
			var al := 0.6 * forca * (1 - ph)
			pen.gota(bx + lean * (1 + ph), by - h * (0.95 + ph * 0.7), w * 0.35 * (1 - ph), h * 0.3 * (1 - ph), lean * 0.2,
				pen.cor(pc[1], al * 0.5), pen.cor(pc[2], al), m2)
	pen.blend_add = add_antes


# chamas numa faixa reta (fogo no chão, vigas, tochas, braseiros): as línguas
# novas, mais o brilho no chão
func desenhar_chamas(px: float, py: float, larg: float, alt: float, t: float, forca := 1.0, semente := 0.0, paleta := 0) -> void:
	if forca <= 0.01:
		return
	var pc := chamas_cores(paleta)
	var pen: Pen = G.pen
	var add_antes := pen.blend_add
	pen.blend_add = true
	pen.elipse(px - larg * 0.7, py - 6, px + larg * 0.7, py + 4, pc[3], 0.22 * forca, false)
	pen.blend_add = add_antes
	chamas_linha(px - larg / 2.0, py, px + larg / 2.0, py, alt * 1.25, t, forca, semente, paleta, 0, clampf(larg / 40.0, 0.5, 1.4))


# ----- CENÁRIO MONTÁVEL (v1.11) -----
static func cenario_tom_fundo() -> Color:
	return Color8(150, 140, 138)


# [colunas, linhas, semente] a partir da escala que a equipe pôs na sala
func cenario_medidas() -> Array:
	return [maxi(1, int(round(absf(image_xscale)))), maxi(1, int(round(absf(image_yscale)))), absi(int(round(x * 7 + y * 3))) % 97]


static func cenario_na_tela(x1: float, x2: float, folga := 96.0) -> bool:
	return x2 >= G.view_x - folga and x1 <= G.view_x + G.view_w + folga


func cenario_dist_jogador(px: float, py: float) -> float:
	var p = instance_find("obj_player", 0)
	if p == null:
		return 100000.0
	return point_distance(px, py, p.x, p.y - 30)


# MURALHA. tipo: "solida", "fundo" ou "ruina". Origem embaixo à esquerda.
func muralha_desenhar(tipo: String, cor: Color, colunas: int, linhas: int, semente: int) -> void:
	if not cenario_na_tela(x, x + 32 * colunas):
		return
	for c in colunas:
		var px := x + 32 * c
		for r in linhas:
			var py := y - 32 * r
			if r == linhas - 1:
				if tipo == "ruina":
					if (c + semente) % 2 == 1:
						draw_sprite_ext(Spr.spr_muralha, 4, px + 32, py, -1, 1, 0, cor, 1)
					else:
						draw_sprite_ext(Spr.spr_muralha, 4, px, py, 1, 1, 0, cor, 1)
				else:
					draw_sprite_ext(Spr.spr_muralha, 2, px, py, 1, 1, 0, cor, 1)
			else:
				var f := 1 if (c * 7 + r * 13 + semente) % 5 == 0 else 0
				draw_sprite_ext(Spr.spr_muralha, f, px, py, 1, 1, 0, cor, 1)
		if tipo == "fundo" and linhas >= 3:
			draw_sprite_ext(Spr.spr_muralha, 3, px, y - 32 * linhas + 3, 1, 1, 0, cor, 1)
	# seteiras acesas pelo incêndio
	if tipo == "fundo" and colunas <= 3 and linhas >= 6:
		var sx := x + 16 * colunas - 16
		var n := 2 if linhas >= 9 else 1
		for k in n:
			var sy := y - 32 * (linhas - 3 - 3 * k)
			draw_sprite_ext(Spr.spr_muralha, 5, sx, sy, 1, 1, 0, cor, 1)
			gpu_set_blendmode(bm_add)
			draw_set_alpha(0.16 + 0.07 * sin(current_time() / 170.0 + semente + k * 2))
			draw_set_color(Color8(255, 120, 40))
			draw_ellipse(sx + 2, sy - 32, sx + 30, sy, false)
			gpu_set_blendmode(bm_normal)
			draw_set_alpha(1)


# COLUNA (origem embaixo no meio): base, fuste, capitel (ou topo quebrado)
func coluna_desenhar(quebrada: bool, cor: Color, linhas: int) -> void:
	if not cenario_na_tela(x - 16, x + 16):
		return
	for r in linhas:
		var f := 1
		if r == 0:
			f = 0
		if r == linhas - 1:
			f = 3 if quebrada else 2
		if linhas == 1:
			f = 3 if quebrada else 0
		draw_sprite_ext(Spr.spr_coluna, f, x, y - 32 * r, 1, 1, 0, cor, 1)


# Brilho de uma chama / lanterna
func cenario_luz(px: float, py: float, raio: float, forca: float, cor: Color) -> void:
	if forca <= 0.01:
		return
	gpu_set_blendmode(bm_add)
	draw_set_color(cor)
	draw_set_alpha(0.07 * forca)
	draw_ellipse(px - raio, py - raio * 0.85, px + raio, py + raio * 0.85, false)
	draw_set_alpha(0.1 * forca)
	draw_ellipse(px - raio * 0.55, py - raio * 0.45, px + raio * 0.55, py + raio * 0.45, false)
	draw_set_alpha(0.16 * forca)
	draw_ellipse(px - raio * 0.22, py - raio * 0.2, px + raio * 0.22, py + raio * 0.2, false)
	gpu_set_blendmode(bm_normal)
	draw_set_alpha(1)


# PLACAS: o aviso de cada placa é o do ponto mais perto dela na lista
static func placa_texto(px: float) -> String:
	var lista := [
		[300, "VILA DE SYLLA\nA maldição chegou com a tempestade."],
		[1456, "PERIGO!\nEspinhos e vigas em chamas adiante."],
		[2408, "PORTÃO DO BASTIÃO\nA chave ficou no forte de madeira, lá no alto."],
		[3640, "ESTRADA DE VALLACK\nA Árvore Amaldiçoada guarda o caminho."],
	]
	var melhor := ""
	var dmin := 1000000.0
	for e in lista:
		var d := absf(e[0] - px)
		if d < dmin:
			dmin = d
			melhor = e[1]
	return melhor


# Aviso em pergaminho acima da placa
func placa_desenhar_aviso(cx: float, base: float, texto: String, alfa: float) -> void:
	if alfa <= 0.01 or texto == "":
		return
	var w := txt_largura(texto, FONTE.MINI, 0.5) + 22
	var h := txt_altura(texto, FONTE.MINI, 0.5) + 12
	var sobe := (1 - alfa) * 8
	var x1 := cx - w / 2.0
	var x2 := cx + w / 2.0
	var y2 := base - sobe
	var y1 := y2 - h
	draw_set_alpha(0.35 * alfa)
	draw_set_color(c_black)
	draw_rectangle(x1 + 3, y1 + 3, x2 + 3, y2 + 3, false)
	retangulo_gradiente(x1, y1, x2, y2, Color8(236, 214, 168), alfa, Color8(196, 160, 104), alfa)
	draw_set_alpha(alfa)
	draw_set_color(Color8(92, 58, 26))
	draw_rectangle(x1, y1, x2, y2, true)
	draw_set_color(Color8(196, 160, 104))
	draw_triangle(cx - 5, y2, cx + 5, y2, cx, y2 + 6, false)
	gpu_set_texfilter(true)
	txt(cx, (y1 + y2) / 2.0, texto, FONTE.MINI, Color8(54, 30, 12), alfa, fa_center, fa_middle, 0.5)
	gpu_set_texfilter(false)
	desenho_resetar()


# =====================================================================
# scr_combate: golpes do jogador, combos e especiais
# =====================================================================
static func rolar_angulo(p: float, rolar_dir: float) -> float:
	return -rolar_dir * 360 * (1 - pow(1 - clampf(p, 0, 1), 1.6))


# A arte nova do Alex (ferramentas/importar_arte.ps1) já sai com o corpo do
# mesmo tamanho em todas as animações; fica a função para um ajuste fino.
static func sprite_fator(_s: GMSprite, _quadro := 0.0) -> float:
	return 1.0


static func combos_lista() -> Array:
	return [
		{"nome": "LÂMINA DE VALLACK", "seq": [ACAO.ATACAR, ACAO.ATACAR, ACAO.ATACAR, ACAO.ATACAR], "desc": "Rápido, duplo, triplo e o ATAQUE FRENÉTICO: uma tempestade de cortes."},
		{"nome": "QUEBRA-ESCUDO", "seq": [ACAO.ATACAR, ACAO.ATACAR, ACAO.ATAQUE_FORTE], "desc": "Dois cortes e um salto que cai com um impacto em área."},
		{"nome": "RASTEIRA SANGRENTA", "seq": [ACAO.ATACAR, ACAO.ATACAR, ACAO.ATAQUE_SALTO], "desc": "Dois cortes e uma rasteira que lança os inimigos ao ar."},
	]


# Próximo golpe da cadeia. cadeia = letras dos golpes já encadeados.
static func combo_proximo(cadeia: String, botao: String, no_ar: bool, agachado: bool) -> String:
	if no_ar:
		if botao == "Q":
			return "corte_aereo"
		if botao == "T":
			return "mergulho"
		return ""
	if agachado and botao == "Q":
		return "rasteira"
	# v1.17: a cadeia guarda as 3 últimas letras: Q, QQ, QQQ e o 4º Q = frenético
	var n := cadeia.length()
	var ultima := cadeia[n - 1] if n >= 1 else ""
	var f2 := cadeia.substr(n - 2, 2) if n >= 2 else ""
	var f3 := cadeia.substr(n - 3, 3) if n >= 3 else ""
	if f3 == "QQQ" and botao == "Q":
		return "frenetico"
	if f2 == "QQ" and f3 != "QQQ":
		if botao == "Q":
			return "corte3"
		if botao == "T" and combo_liberado(2):
			return "quebra_escudo"
		if botao == "C" and combo_liberado(3):
			return "rasteira_sangrenta"
	if ultima == "Q" and botao == "Q":
		return "corte2"
	if botao == "Q":
		return "corte1"
	if botao == "T":
		return "carrasco"
	if botao == "C":
		return "rasteira"
	return ""


static func golpe_som(chave: String) -> String:
	# v1.16: se existir um sfx_sword_slash.ogg, ele vira o som dos cortes de espada
	# (o tom varia ±0.05 a cada golpe, no som() do obj_player)
	if chave in ["corte1", "corte2", "corte_aereo", "contra"] and G.sfx.has("sfx_sword_slash"):
		return "sfx_sword_slash"
	match chave:
		"corte1", "arremesso":
			return "atk_corte_1"
		"corte2", "contra":
			return "atk_corte_2"
		"corte_aereo":
			return "atk_aereo"
		"execucao", "carrasco", "quebra_escudo", "lancador", "corte3", "frenetico":
			return "atk_pesado"
		"mergulho":
			return "atk_mergulho"
		"rasteira", "rasteira_sangrenta", "arremesso_chama":
			return "atk_rasteira"
	return ""


static func _q(q: int, d: float, extra := {}) -> Dictionary:
	var r := {"q": q, "d": d}
	r.merge(extra)
	return r


static func golpe_criar_v112(chave: String):
	match chave:
		"lancador":
			return {"nome": "LANÇADOR", "spr": Spr.spr_ataque_2, "pesado": true, "no_ar": true, "dano": 12, "forca": 0.6, "atordoa": 55, "lanca": 0, "cancel": 4,
				"arco": [-70, 115, 58, 44], "cor": Color8(255, 170, 110),
				"seq": [_q(0, 3), _q(1, 3), _q(2, 4, {"ev": "lancar", "hit": [-8, 54, -100, 2]}), _q(3, 4, {"hit": [-8, 46, -120, -24]}), _q(4, 4), _q(5, 5)]}
		"contra":
			return {"nome": "CONTRA-ATAQUE", "spr": Spr.spr_player_ataque, "pesado": true, "armadura": true, "dano": 1, "forca": 1.4, "atordoa": 90, "lanca": 0, "cancel": 99,
				"arco": [80, -50, 64, 38], "cor": Color8(150, 210, 255),
				"seq": [_q(1, 2, {"ev": "contra", "av": 3.2}), _q(2, 3, {"hit": [0, 70, -70, 0], "av": 2.4}), _q(3, 4, {"hit": [0, 86, -66, 0]}), _q(4, 4, {"hit": [0, 60, -62, 0]}), _q(5, 8)]}
		"arremesso":
			return {"nome": "LÂMINA BUMERANGUE", "spr": Spr.spr_player_ataque, "dano": 0, "forca": 0, "atordoa": 0, "lanca": 0, "cancel": 3,
				"seq": [_q(0, 3), _q(2, 3, {"ev": "bumerangue"}), _q(3, 4), _q(5, 6)]}
		"arremesso_chama":
			return {"nome": "CHAMA DE SYLLA", "spr": Spr.spr_player_atacar_agaichado, "dano": 0, "forca": 0, "atordoa": 0, "lanca": 0, "cancel": 4,
				"seq": [_q(0, 3), _q(1, 3), _q(2, 4, {"ev": "chama"}), _q(3, 4), _q(5, 7)]}
	return null


# TABELA DE GOLPES: cada quadro { q, d, hit, dm, grupo, av, esp, ev }
static func golpe_criar(chave: String):
	var g = null
	match chave:
		# v1.17: a sequência do QUADRADO usa as animações novas da equipe:
		# 1 toque = ATAQUE RÁPIDO, 2º = ATAQUE DUPLO (segunda metade), 3º = ATAQUE
		# TRIPLO (crava no chão) e o 4º solta o ATAQUE FRENÉTICO inteiro
		"corte1":
			g = {"nome": "ATAQUE RÁPIDO", "spr": Spr.spr_player_ataque_rapido, "dano": 8, "forca": 2.2, "atordoa": 30, "lanca": 0, "cancel": 3,
				"arco": [70, -40, 50, 36], "cor": Color8(255, 235, 220),
				"seq": [_q(0, 2), _q(1, 3, {"av": 0.8}), _q(2, 3, {"hit": [4, 58, -58, -34], "av": 1.0, "dm": 0.45}),
					_q(3, 4, {"hit": [4, 64, -70, -6], "grupo": 1, "dm": 0.6}), _q(4, 3, {"hit": [4, 64, -50, -24], "grupo": 2, "dm": 0.4}), _q(5, 6)]}
		"corte2":
			g = {"nome": "ATAQUE DUPLO", "spr": Spr.spr_player_ataque_duplo, "dano": 12, "forca": 2.5, "atordoa": 32, "lanca": 0, "cancel": 3,
				"arco": [80, -50, 52, 34], "cor": Color8(255, 210, 160),
				"seq": [_q(6, 3, {"hit": [4, 58, -62, -42], "av": 1.2, "dm": 0.45}), _q(7, 4, {"hit": [-24, 54, -80, -6], "grupo": 1, "dm": 0.6}),
					_q(8, 3, {"hit": [4, 56, -52, -18], "grupo": 1}), _q(9, 3), _q(10, 3, {"hit": [4, 66, -46, -26], "grupo": 2, "dm": 0.45, "av": 1.0}), _q(11, 6)]}
		"corte3":
			g = {"nome": "ATAQUE TRIPLO", "spr": Spr.spr_player_ataque_triplo, "pesado": true, "dano": 18, "forca": 5, "atordoa": 50, "lanca": 1, "cancel": 4,
				"arco": [110, -60, 58, 40], "cor": Color8(255, 150, 100),
				"seq": [_q(11, 3, {"av": 1.5}), _q(12, 4, {"hit": [-12, 62, -84, -4]}), _q(13, 6, {"hit": [4, 58, -42, 6], "grupo": 1, "dm": 0.5, "ev": "impacto_leve"}),
					_q(14, 4), _q(15, 4), _q(16, 4), _q(17, 5)]}
		"frenetico":
			g = {"nome": "ATAQUE FRENÉTICO", "spr": Spr.spr_player_ataque_frenetico, "pesado": true, "dano": 30, "forca": 6, "atordoa": 60, "lanca": 2, "cancel": 99,
				"combo": 1, "arco": [120, -60, 60, 40], "cor": Color8(255, 90, 60),
				"seq": [_q(0, 3, {"hit": [-30, 58, -64, -10], "dm": 0.12, "av": 1.2}), _q(1, 3, {"hit": [-40, 60, -80, -4], "grupo": 1, "dm": 0.12}), _q(2, 3),
					_q(3, 3, {"hit": [-30, 60, -58, -14], "grupo": 2, "dm": 0.12, "av": 0.8}), _q(4, 3), _q(5, 3, {"hit": [-40, 52, -86, -4], "grupo": 3, "dm": 0.12}),
					_q(6, 3, {"hit": [4, 56, -62, -4], "grupo": 4, "dm": 0.1}), _q(7, 3, {"hit": [4, 60, -52, -32], "grupo": 5, "dm": 0.1, "av": 1.0}),
					_q(8, 4, {"hit": [4, 74, -52, -22], "grupo": 6, "dm": 0.12, "av": 2.4}), _q(9, 3), _q(10, 3, {"hit": [-30, 60, -86, -4], "grupo": 7, "dm": 0.12}),
					_q(11, 3, {"hit": [4, 58, -82, -4], "grupo": 8, "dm": 0.1}), _q(12, 4, {"hit": [-8, 62, -98, 4], "grupo": 9, "dm": 0.3, "ev": "impacto_leve"}),
					_q(13, 6, {"hit": [-20, 66, -42, 6], "grupo": 10, "dm": 0.2}), _q(14, 4), _q(15, 4), _q(16, 4), _q(17, 6)]}
		"corte_aereo":
			g = {"nome": "CORTE AÉREO", "spr": Spr.spr_player_ataque_ar, "dano": 10, "forca": 1.2, "atordoa": 30, "lanca": 0, "cancel": 3, "no_ar": true,
				"arco": [75, -45, 50, 36], "cor": Color8(255, 235, 220),
				"seq": [_q(0, 2), _q(1, 3), _q(2, 3, {"hit": [4, 46, -62, -4]}), _q(3, 4, {"hit": [4, 60, -60, -4]}), _q(4, 4, {"hit": [4, 38, -60, -4]}), _q(5, 5)]}
		"execucao":
			g = {"nome": "EXECUÇÃO", "spr": Spr.spr_ataque_2, "pesado": true, "dano": 24, "forca": 7, "atordoa": 55, "lanca": 2, "cancel": 99,
				"combo": 1, "arco": [130, -35, 62, 40], "cor": Color8(255, 120, 90),
				"seq": [_q(1, 3), _q(2, 4, {"hit": [-4, 30, -84, -24], "dm": 0.4, "grupo": 0}), _q(3, 4), _q(4, 3), _q(5, 3), _q(6, 5, {"ev": "brilho"}),
					_q(7, 3, {"hit": [4, 50, -72, -4], "av": 3.0, "grupo": 1}), _q(8, 7, {"hit": [4, 62, -46, 0], "av": 1.8, "grupo": 1, "ev": "impacto_leve"}),
					_q(9, 6), _q(10, 5), _q(11, 5)]}
		"carrasco", "quebra_escudo":
			var forte := chave == "quebra_escudo"
			g = {"nome": "QUEBRA-ESCUDO" if forte else "SALTO DO CARRASCO", "spr": Spr.spr_ataque_2, "pesado": true,
				"dano": 28 if forte else 18, "forca": 8 if forte else 6, "atordoa": 75 if forte else 45, "lanca": 4 if forte else 3, "cancel": 99,
				"combo": 2 if forte else 0, "no_ar": true, "arco": [140, -40, 60, 44], "cor": Color8(255, 90, 60) if forte else Color8(255, 200, 150),
				"seq": [_q(0, 4), _q(1, 4), _q(2, 4, {"ev": "salto", "hit": [-6, 32, -92, -26], "dm": 0.45, "grupo": 0}), _q(3, 4), _q(4, 4), _q(5, 4),
					_q(6, 3, {"esp": "descendo"}), _q(7, 2, {"esp": "chao", "hit": [0, 46, -72, 2], "grupo": 1}),
					_q(8, 8, {"ev": "impacto_quebra" if forte else "impacto_carrasco", "hit": [-58, 86, -56, 6] if forte else [-32, 64, -50, 6], "grupo": 1}),
					_q(9, 6), _q(10, 5), _q(11, 5)]}
		"mergulho":
			g = {"nome": "MERGULHO", "spr": Spr.spr_ataque_2, "pesado": true, "dano": 16, "forca": 5, "atordoa": 40, "lanca": 2, "cancel": 99, "no_ar": true,
				"arco": [100, -60, 52, 30], "cor": Color8(255, 200, 150),
				"seq": [_q(6, 4), _q(7, 2, {"ev": "mergulho", "esp": "chao", "hit": [0, 42, -64, 2], "grupo": 0}), _q(8, 7, {"ev": "impacto_carrasco", "hit": [-28, 58, -46, 6], "grupo": 1}),
					_q(9, 6), _q(10, 5), _q(11, 4)]}
		"rasteira", "rasteira_sangrenta":
			var s := chave == "rasteira_sangrenta"
			var m := 1.6 if s else 1.0
			g = {"nome": "RASTEIRA SANGRENTA" if s else "RASTEIRA", "spr": Spr.spr_player_atacar_agaichado,
				"dano": 16 if s else 9, "forca": 3 if s else 2, "atordoa": 60 if s else 48, "lanca": 4.5 if s else 0, "cancel": 4,
				"combo": 3 if s else 0, "arco": [-70, -5, 54, 18], "cor": Color8(230, 20, 40) if s else Color8(255, 225, 200),
				"seq": [_q(0, 3, {"av": 1.5 * m}), _q(1, 3, {"av": 2.0 * m}), _q(2, 3, {"hit": [4, 47, -42, 0], "av": 1.5 * m}), _q(3, 4, {"hit": [4, 56, -42, 0], "av": 0.8 * m}),
					_q(4, 4, {"hit": [4, 45, -42, 0]}), _q(5, 7)]}
		"onda":
			g = {"nome": "ONDA CARMESIM", "spr": Spr.spr_player_especial, "especial": true, "porcento": 0.30, "acao_esp": ACAO.ESPECIAL, "armadura": true, "dano": 0, "forca": 10, "atordoa": 60, "lanca": 2, "cancel": 99,
				"seq": [_q(0, 7, {"ev": "zoom"}), _q(1, 5, {"hit": [0, 47, -82, -2]}), _q(2, 5, {"hit": [0, 74, -54, -2], "ev": "onda"}), _q(3, 5, {"hit": [0, 56, -76, -2]}), _q(4, 5, {"hit": [0, 45, -70, -2]}), _q(5, 10)]}
		"onda_agachado":
			g = {"nome": "ONDA CARMESIM", "spr": Spr.spr_player_atacar_agaichado_especial, "especial": true, "porcento": 0.30, "acao_esp": ACAO.ESPECIAL, "armadura": true, "dano": 0, "forca": 9, "atordoa": 60, "lanca": 1, "cancel": 99,
				"seq": [_q(0, 5, {"ev": "zoom"}), _q(1, 5), _q(2, 4, {"hit": [0, 58, -46, -2], "ev": "onda_baixa"}), _q(3, 5, {"hit": [0, 50, -58, -2]}), _q(4, 5, {"hit": [0, 41, -42, -2]}), _q(5, 8)]}
		"queda":
			g = {"nome": "QUEDA CARMESIM", "spr": Spr.spr_ataque_especial_2, "especial": true, "porcento": 0.40, "acao_esp": ACAO.ESPECIAL_2, "armadura": true, "no_ar": true, "dano": 0, "forca": 8, "atordoa": 70, "lanca": 4, "cancel": 99,
				"seq": [_q(0, 6, {"ev": "zoom"}), _q(1, 5, {"ev": "salto_queda"}), _q(2, 5), _q(3, 5), _q(4, 3, {"esp": "apice"}), _q(5, 2, {"ev": "mergulho_queda", "esp": "chao"}), _q(6, 9, {"ev": "impacto_queda"}), _q(7, 24, {"ev": "faiscas"})]}
		"tremor":
			g = {"nome": "TREMOR DE VALLACK", "spr": Spr.spr_ataque_03, "especial": true, "porcento": 0.35, "acao_esp": ACAO.ESPECIAL_3, "armadura": true, "dano": 0, "forca": 9, "atordoa": 80, "lanca": 5, "cancel": 99,
				"seq": [_q(0, 5, {"ev": "zoom"}), _q(1, 7, {"ev": "carga"}), _q(2, 7), _q(3, 7), _q(4, 11, {"ev": "carga_max"}), _q(5, 3), _q(6, 8, {"ev": "impacto_tremor"}), _q(7, 26)]}
		"finalizador":
			g = {"nome": "FINALIZADOR", "spr": Spr.spr_ataque_2, "pesado": true, "armadura": true, "dano": 0, "forca": 9, "atordoa": 0, "lanca": 0, "cancel": 99,
				"arco": [130, -35, 66, 40], "cor": Color8(255, 60, 40),
				"seq": [_q(0, 4, {"ev": "fin_inicio"}), _q(1, 4), _q(2, 5), _q(3, 5), _q(4, 4), _q(5, 4), _q(6, 9, {"ev": "brilho"}), _q(7, 3, {"av": 2.0}),
					_q(8, 12, {"ev": "fin_golpe"}), _q(9, 7), _q(10, 6), _q(11, 6, {"ev": "fin_fim"})]}
		"ira":
			g = {"nome": "IRA DE VALLACK", "spr": Spr.spr_player_especial, "armadura": true, "dano": 0, "forca": 12, "atordoa": 90, "lanca": 5, "cancel": 99,
				"seq": [_q(0, 30, {"ev": "ira_carga"}), _q(1, 5), _q(2, 6, {"ev": "ira_golpe"}), _q(3, 6), _q(4, 6), _q(5, 16)]}
	if g == null:
		g = golpe_criar_v112(chave)
	if g == null:
		return null
	g.chave = chave
	if not g.has("especial"):
		g.especial = false
	if not g.has("armadura"):
		g.armadura = false
	if not g.has("no_ar"):
		g.no_ar = false
	if not g.has("combo"):
		g.combo = 0
	if not g.has("arco"):
		g.arco = null
	if not g.has("cor"):
		g.cor = c_white
	if not g.has("pesado"):
		g.pesado = false
	if not g.has("porcento"):
		g.porcento = 0
	if not g.has("acao_esp"):
		g.acao_esp = -1
	var dur := 0.0
	for e in g.seq:
		dur += e.d
	g.duracao = dur
	return g


static func combo_letra(acao: int) -> String:
	if acao == ACAO.ATACAR:
		return "Q"
	if acao == ACAO.ATAQUE_FORTE:
		return "T"
	if acao == ACAO.ATAQUE_SALTO:
		return "C"
	return ""


static func combo_acao_da_letra(l: String) -> int:
	if l == "T":
		return ACAO.ATAQUE_FORTE
	if l == "C":
		return ACAO.ATAQUE_SALTO
	return ACAO.ATACAR


# =====================================================================
# scr_inimigos_novos: nível, golpes fortes, projéteis, teia e falas
# =====================================================================
# v1.13: vida e dano a mais por nível do mapa conforme a dificuldade (no MÉDIO +15% e +10%)
static func nivel_vida(n: int) -> float:
	return 1 + dif_nivel_vida() * (n - 1)

static func nivel_dano(n: int) -> float:
	return 1 + dif_nivel_dano() * (n - 1)

static func nivel_cor(n: int) -> Color:
	match n:
		1:
			return Color8(205, 205, 205)
		2:
			return Color8(140, 225, 120)
		3:
			return Color8(255, 210, 90)
		4:
			return Color8(255, 130, 60)
	return Color8(235, 100, 255)


# Golpes que atravessam a pedra da estátua e impedem o esqueleto de se reerguer
static func golpe_e_forte(g) -> bool:
	if g == null:
		return false
	if g.get("especial", false):
		return true
	var c = g.get("chave", "")
	return c == "ira" or c == "finalizador" or c == "flecha" or c == "fogo" or c == "orbe" or c == "teia"


# Cria um projétil de magia (obj_magia)
func magia_criar(tipo: String, px: float, py: float, vx: float, vy: float, dano: float, dono):
	var m = instance_create_depth(px, py, -60, "obj_magia")
	m.tipo = tipo
	m.vx = vx
	m.vy = vy
	m.dano = dano
	m.dono = dono
	m.alcance = G.view_w * 1.2
	return m


# TEIA: Twilight fica lento, não pula e não rola
func jogador_enredar(quadros: float) -> void:
	for p in todos("obj_player"):
		p.enredar(quadros)


func falas_esqueleto() -> Array: return ["Clec, clec, clec!", "Seus ossos serão meus!", "Pelo senhor Vallack!", "Ossos e aço!", "Junte-se a nós!"]
func falas_esqueleto_ergue() -> Array: return ["Ossos não morrem!", "Eu me levanto!", "Vallack me ergue de novo!", "Ainda não acabou!"]
func falas_esqueleto_cai() -> Array: return ["Ainda... não...", "Clec...", "Eu... volto..."]
func falas_aranha() -> Array: return ["Venha para a minha teia...", "Sssss!", "Que presa saborosa!", "Oito patas, nenhuma saída!", "Fique quietinho..."]
func falas_aranha_teia() -> Array: return ["Preso!", "Enrolado como um casulo!", "Não adianta se debater!"]
func falas_porco() -> Array: return ["GRRROINC!", "Vou te esmagar!", "Carne para a maldição!", "Saia da minha frente!"]
func falas_porco_salto() -> Array: return ["Terra, trema!", "Lá vou eu!", "ESMAGAR!"]
func falas_porco_onda() -> Array: return ["Sinta a corrupção!", "Corte roxo!", "Pule, se puder!"]
func falas_porco_furia() -> Array: return ["AGORA EU FIQUEI BRAVO!", "Ossos, venham a mim!", "A maldição me fortalece!"]
func falas_estatua() -> Array: return ["Quem perturba a pedra?", "Seus passos me acordaram.", "A pedra vê tudo.", "Queime!"]
func falas_estatua_imune() -> Array: return ["Pedra não sangra.", "Inútil!", "Espere meus olhos brilharem..."]
func falas_besta() -> Array: return ["Atacaaarrr!", "Grrraaah!", "Carne fresca!", "Pela maldição!", "Daqui não passa!"]
func falas_arqueiro() -> Array: return ["Fogo!", "Na mira...", "Hehehe!", "Flechas!", "Fique longe!"]
func falas_escudo() -> Array: return ["Atrás do escudo!", "Ninguém passa!", "Formação!", "Meu escudo não cai!"]
static func cor_fala_esqueleto() -> Color: return Color8(150, 30, 25)
static func cor_fala_aranha() -> Color: return Color8(90, 60, 120)
static func cor_fala_porco() -> Color: return Color8(140, 30, 20)
static func cor_fala_estatua() -> Color: return Color8(70, 80, 40)


# =====================================================================
# scr_dano (parte global)
# =====================================================================
# O jogador segurou um golpe/projétil na defesa mágica
func jogador_bloqueou(origem_x: float) -> void:
	for p in todos("obj_player"):
		p.bloqueou(origem_x)


# APARAR: o golpe é rebatido e quem bateu fica atordoado
func jogador_aparou(atacante) -> void:
	for p in todos("obj_player"):
		p.aparou(atacante)
	if G.existe(atacante):
		var p = instance_find("obj_player", 0)
		var px: float = p.x if p != null else atacante.x
		atacante.inimigo_aparado(signf(atacante.x - px))


# Quantos inimigos ainda estão vivos (corpos não contam)
func inimigos_vivos() -> int:
	var n := 0
	for e in todos("obj_inimigo_base"):
		if not e.morrendo:
			n += 1
	return n


# FALAS DOS INIMIGOS (balão) — v1.12: desligadas (FALAS_LIGADAS = false)
func fala_dizer(inst, texto: String, cor := Color(1, 1, 1), forcar := false, dur := 110.0):
	if not FALAS_LIGADAS:
		return null
	if not G.existe(inst):
		return null
	if not forcar and G.fala_espera > 0:
		return null
	G.fala_espera = 100
	return fala_balao(inst, texto, cor, dur)


# cria o balão (obj_fala) preso ao inimigo
func fala_balao(inst, texto: String, cor: Color, dur: float):
	for f in todos("obj_fala"):
		if f.alvo == inst:
			instance_destroy(f)
	var f = instance_create_depth(inst.x, inst.y, -150, "obj_fala")
	f.alvo = inst
	f.texto = texto
	f.cor = cor
	f.vida = dur
	f.vida_max = dur
	return f


func fala_aleatoria(inst, lista: Array, cor: Color, chance := 0.35):
	if randf() > chance:
		return null
	return fala_dizer(inst, lista[randi() % lista.size()], cor)


# v1.18: os balões voltaram SÓ no começo dos ataques (pedido do jogador): o
# inimigo grita uma frase curta de vez em quando, avisando o golpe. Funciona
# mesmo com FALAS_LIGADAS = false (as outras falas continuam desligadas).
# Um balão de ataque por vez na tela inteira. O mesmo da versão PC (scr_dano).
const FALA_ATAQUE_ESPERA := 190.0   # quadros (~3,2 s) entre dois balões de ataque
const FALA_ATAQUE_DUR := 80.0


func fala_ataque(inst, lista: Array, cor: Color, chance := 0.35):
	if not G.existe(inst) or lista.is_empty():
		return null
	if G.fala_espera > 0:
		return null
	if randf() > chance:
		return null
	G.fala_espera = FALA_ATAQUE_ESPERA
	return fala_balao(inst, lista[randi() % lista.size()], cor, FALA_ATAQUE_DUR)


# =====================================================================
# HUD: barras com ponta de flecha, brasão do herói, faixa do objetivo
# (a arte vem de assets/ui; as formas são primitivas agrupadas)
# =====================================================================

# contorno de uma barra com ponta à direita (e à esquerda, se pedir)
static func hud_barra_pts(x: float, y: float, comp: float, h: float, ponta_esq := false) -> PackedVector2Array:
	var p := h * 0.5
	var x2 := x + comp
	if ponta_esq:
		var m := maxf(x + p, x2 - p)
		return PackedVector2Array([Vector2(x, y + p), Vector2(x + p, y), Vector2(m, y), Vector2(maxf(x2, x + p), y + p), Vector2(m, y + h), Vector2(x + p, y + h)])
	var q := maxf(x, x2 - p)
	return PackedVector2Array([Vector2(x, y), Vector2(q, y), Vector2(x2, y + p), Vector2(q, y + h), Vector2(x, y + h)])


# preenche a forma com degradê vertical (c1 em cima, c2 embaixo)
static func hud_forma(pts: PackedVector2Array, y: float, h: float, c1: Color, c2: Color, alfa: float) -> void:
	if alfa <= 0:
		return
	var pen: Pen = G.pen
	var cs := PackedColorArray()
	for v in pts:
		cs.append(pen.cor(c1.lerp(c2, clampf((v.y - y) / maxf(1.0, h), 0, 1)), alfa))
	pen.poligono_convexo(pts, cs)


# barra com moldura dourada; pct_atraso mostra em claro o dano recente;
# segmentos > 1 desenha os gomos da barra (como no Castlevania)
static func hud_barra(x: float, y: float, w: float, h: float, pct: float, pct_atraso: float, c1: Color, c2: Color, alfa := 1.0, ponta_esq := false, segmentos := 0) -> void:
	_hud_barra_corpo(x, y, w, h, pct, pct_atraso, c1, c2, alfa, ponta_esq)
	if segmentos > 1:
		var pen: Pen = G.pen
		for s in range(1, segmentos):
			var sx := x + w * s / segmentos
			if sx > x + w - h * 0.5:
				break
			pen.retangulo(sx, y + 1, sx + 1, y + h - 1, Color8(10, 4, 5), 0.55 * alfa, false)


static func _hud_barra_corpo(x: float, y: float, w: float, h: float, pct: float, pct_atraso: float, c1: Color, c2: Color, alfa: float, ponta_esq: bool) -> void:
	var p_esq := 3.0 if ponta_esq else 0.0
	hud_forma(hud_barra_pts(x - 3 - p_esq, y - 3, w + 7 + p_esq * 2, h + 6, ponta_esq), y - 3, h + 6, Color8(8, 5, 6), Color8(8, 5, 6), 0.9 * alfa)
	hud_forma(hud_barra_pts(x - 1.5 - p_esq * 0.5, y - 1.5, w + 3.5 + p_esq, h + 3, ponta_esq), y - 1.5, h + 3, UI.OURO_CLARO, UI.OURO_ESCURO, alfa)
	hud_forma(hud_barra_pts(x, y, w, h, ponta_esq), y, h, Color8(14, 9, 10), Color8(36, 25, 27), alfa)
	var pa := clampf(pct_atraso, 0, 1)
	var pp := clampf(pct, 0, 1)
	if pa > pp + 0.002:
		hud_forma(hud_barra_pts(x, y, w * pa, h, ponta_esq), y, h, Color8(255, 244, 222), Color8(214, 196, 170), 0.9 * alfa)
	if pp > 0.002:
		hud_forma(hud_barra_pts(x, y, w * pp, h, ponta_esq), y, h, c1, c2, alfa)
		# brilho na metade de cima
		var hb := h * 0.38
		hud_forma(hud_barra_pts(x + (h * 0.5 if ponta_esq else 0.0), y + 1, maxf(0.0, w * pp - h * (1.0 if ponta_esq else 0.5)), hb, false), y + 1, hb, Color(1, 1, 1), Color(1, 1, 1), 0.16 * alfa)


# brasão com o rosto do herói; o número na joia é o nível da espada
func hud_brasao(x: float, y: float, w: float, nivel: int, alfa := 1.0) -> void:
	var pen: Pen = G.pen
	var h := w * 1.2
	var k := w / 200.0
	pen.textura(UI.tex("brasao_fundo"), x, y, w, h, c_white, alfa)
	# retrato: cabeça e ombros do quadro 0 da spr_player_idle (arte HD)
	var e := (124.0 * k) / 54.0
	pen.sprite_parte(Spr.spr_player_idle, 0, 22, 2, 54, 54, x + 38 * k, y + 30 * k, e, e, c_white, alfa)
	pen.textura(UI.tex("brasao"), x, y, w, h, c_white, alfa)
	txt_sombra(x + 100 * k, y + 206 * k, str(nivel), FONTE.PEQUENA, UI.MARFIM, alfa, fa_center, fa_middle, 0.9)


# bússola com a agulha apontando para o objetivo (ang em radianos; 0 = leste)
func hud_bussola(cx: float, cy: float, r: float, ang: float, alfa := 1.0) -> void:
	var pen: Pen = G.pen
	pen.textura(UI.tex("bussola"), cx - r, cy - r, r * 2, r * 2, c_white, alfa)
	var d := Vector2(cos(ang), sin(ang))
	var n := Vector2(-d.y, d.x)
	var ponta := Vector2(cx, cy) + d * r * 0.72
	var cauda := Vector2(cx, cy) - d * r * 0.62
	var lado := n * r * 0.16
	var c := Vector2(cx, cy)
	pen.triangulo(ponta.x, ponta.y, c.x + lado.x, c.y + lado.y, c.x - lado.x, c.y - lado.y, UI.OURO_CLARO, alfa, false)
	pen.triangulo(cauda.x, cauda.y, c.x + lado.x, c.y + lado.y, c.x - lado.x, c.y - lado.y, Color8(150, 28, 24), alfa, false)
	pen.circulo(cx, cy, r * 0.12, UI.OURO, alfa, false)


# faixa escura com filetes dourados que somem nas pontas (objetivo, avisos)
func hud_faixa(x1: float, y1: float, x2: float, y2: float, alfa := 1.0) -> void:
	var fade := minf(70.0, (x2 - x1) * 0.25)
	var cf := Color8(10, 6, 7)
	retangulo_gradiente_h(x1, y1, x1 + fade, y2, cf, 0, cf, 0.72 * alfa)
	draw_set_alpha(0.72 * alfa)
	draw_set_color(cf)
	draw_rectangle(x1 + fade, y1, x2 - fade, y2, false)
	retangulo_gradiente_h(x2 - fade, y1, x2, y2, cf, 0.72 * alfa, cf, 0)
	for yy in [y1, y2]:
		retangulo_gradiente_h(x1, yy - 1, (x1 + x2) / 2.0, yy, UI.OURO, 0, UI.OURO, 0.85 * alfa)
		retangulo_gradiente_h((x1 + x2) / 2.0, yy - 1, x2, yy, UI.OURO, 0.85 * alfa, UI.OURO, 0)
	var cx := (x1 + x2) / 2.0
	draw_set_alpha(alfa)
	draw_set_color(UI.OURO_CLARO)
	draw_triangle(cx - 7, y2, cx, y2 - 5, cx + 7, y2, false)
	draw_triangle(cx - 7, y2, cx, y2 + 5, cx + 7, y2, false)
	draw_set_alpha(1)


# orbe vermelha pequena (contador de orbs do HUD)
func hud_orbe(cx: float, cy: float, r: float, alfa := 1.0) -> void:
	var pen: Pen = G.pen
	pen.circulo(cx, cy, r + 1.5, Color8(20, 6, 6), 0.8 * alfa, false)
	pen.circulo(cx, cy, r, Color8(170, 24, 20), alfa, false)
	pen.circulo(cx - r * 0.15, cy - r * 0.15, r * 0.7, Color8(240, 70, 50), alfa, false)
	pen.circulo(cx - r * 0.35, cy - r * 0.4, r * 0.28, Color8(255, 210, 190), 0.9 * alfa, false)

# barra de vida de chefe EMBAIXO da tela (estilo Castlevania), entre o
# joystick e os botões de toque; marcas: [[posição 0..1, cor], ...]
func hud_barra_chefe(nome: String, direita: String, cor_dir: Color, pct: float, pct_atraso: float, c1: Color, c2: Color, marcas: Array, valor: String, alfa: float) -> void:
	var gw := G.gui_w
	var bw := clampf(gw - 920, 340, 760)
	var bx := gw / 2.0 - bw / 2.0
	var by := G.gui_h - 34.0
	hud_faixa(bx - 56, by - 40, bx + bw + 56, by + 24, alfa)
	txt_sombra(bx + 6, by - 18, nome, FONTE.PEQUENA, Color8(255, 132, 104), alfa, fa_left, fa_middle, minf(0.95, (bw * 0.62) / maxf(1, txt_largura(nome, FONTE.PEQUENA))))
	txt_sombra(bx + bw - 6, by - 18, direita, FONTE.MINI, cor_dir, alfa, fa_right, fa_middle)
	hud_barra(bx, by, bw, 14, pct, pct_atraso, c1, c2, alfa, true, 20)
	for m in marcas:
		var mx: float = bx + bw * m[0]
		draw_set_alpha(alfa)
		draw_set_color(m[1])
		draw_rectangle(mx - 1, by - 4, mx + 1, by + 18, false)
	if valor != "":
		txt_sombra(bx + bw - 12, by + 7, valor, FONTE.MINI, Color8(255, 240, 228), alfa, fa_right, fa_middle, 0.8)
	draw_set_alpha(1)


# placa de ferro escuro com moldura dourada dupla e ponta gótica à direita
# (fica atrás das barras do herói)
static func hud_placa(x1: float, y1: float, x2: float, y2: float, alfa := 1.0) -> void:
	var pen: Pen = G.pen
	var h := y2 - y1
	var p := minf(26.0, h * 0.4)
	var my := y1 + h / 2.0
	hud_forma(PackedVector2Array([Vector2(x1 + 3, y1 + 5), Vector2(x2 - p + 3, y1 + 5), Vector2(x2 + 3, my + 5), Vector2(x2 - p + 3, y2 + 5), Vector2(x1 + 3, y2 + 5)]), y1, h, Color.BLACK, Color.BLACK, 0.45 * alfa)
	hud_forma(PackedVector2Array([Vector2(x1 - 2, y1 - 2), Vector2(x2 - p - 1, y1 - 2), Vector2(x2 + 2.5, my), Vector2(x2 - p - 1, y2 + 2), Vector2(x1 - 2, y2 + 2)]), y1 - 2, h + 4, UI.OURO_CLARO, UI.OURO_ESCURO, alfa)
	hud_forma(PackedVector2Array([Vector2(x1, y1), Vector2(x2 - p, y1), Vector2(x2, my), Vector2(x2 - p, y2), Vector2(x1, y2)]), y1, h, Color8(34, 24, 26), Color8(10, 7, 8), 0.94 * alfa)
	# filete interno
	pen.linha(x1 + 4, y1 + 4, x2 - p - 2, y1 + 4, UI.OURO, 0.45 * alfa)
	pen.linha(x1 + 4, y2 - 4, x2 - p - 2, y2 - 4, UI.OURO, 0.45 * alfa)
	pen.linha(x2 - p - 2, y1 + 4, x2 - 5, my, UI.OURO, 0.45 * alfa)
	pen.linha(x2 - p - 2, y2 - 4, x2 - 5, my, UI.OURO, 0.45 * alfa)
	# joia carmesim na ponta
	var jx := x2 - p * 0.55
	pen.triangulo(jx - 5, my, jx, my - 5, jx + 5, my, UI.OURO_CLARO, alfa, false)
	pen.triangulo(jx - 5, my, jx, my + 5, jx + 5, my, UI.OURO_CLARO, alfa, false)
	pen.triangulo(jx - 3, my, jx, my - 3, jx + 3, my, Color8(150, 20, 18), alfa, false)
	pen.triangulo(jx - 3, my, jx, my + 3, jx + 3, my, Color8(150, 20, 18), alfa, false)


# ícone da sub-arma: 0 = Lâmina Bumerangue, 1 = Chama de Sylla
static func hud_icone_subarma(cx: float, cy: float, r: float, tipo: int, alfa := 1.0) -> void:
	var pen: Pen = G.pen
	if tipo == 0:
		# lâmina girando (como no jogo), inclinada
		var c := cos(deg_to_rad(45))
		var s := -sin(deg_to_rad(45))
		var tx := cx + c * r
		var ty := cy + s * r
		var hx := cx - c * r * 0.55
		var hy := cy - s * r * 0.55
		var nx := -s * r * 0.2
		var ny := c * r * 0.2
		pen.blend_add = true
		pen.circulo(cx, cy, r * 0.95, Color8(255, 210, 120), 0.25 * alfa, false)
		pen.blend_add = false
		pen.triangulo(cx + nx, cy + ny, cx - nx, cy - ny, tx, ty, Color8(225, 230, 240), alfa, false)
		pen.linha(cx, cy, tx, ty, Color8(150, 160, 175), alfa)
		pen.linha(cx - nx * 1.8, cy - ny * 1.8, cx + nx * 1.8, cy + ny * 1.8, Color8(205, 165, 60), alfa, maxf(2.0, r * 0.14))
		pen.linha(cx, cy, hx, hy, Color8(205, 165, 60), alfa, maxf(2.0, r * 0.17))
		pen.circulo(hx, hy, maxf(1.5, r * 0.12), Color8(205, 165, 60), alfa, false)
	else:
		# chama amaldiçoada (gota de fogo roxa com miolo claro)
		var tre := sin(current_time() / 90.0) * r * 0.08
		pen.blend_add = true
		for i in 3:
			var esc: float = [1.0, 0.62, 0.3][i]
			var cor: Color = [Color8(165, 80, 255), Color8(220, 150, 255), Color8(255, 240, 255)][i]
			var rr := r * 0.5 * esc
			var base := cy + r * 0.45
			pen.circulo(cx, base - rr, rr, cor, alfa * (0.6 + 0.15 * i), false)
			pen.triangulo(cx - rr, base - rr, cx + rr, base - rr, cx + tre, base - rr - r * 1.2 * esc, cor, alfa * (0.6 + 0.15 * i), false)
		pen.blend_add = false


# quadro da sub-arma (como o do Castlevania): moldura dourada com cantos em
# losango, ícone no centro e o contador de essência embaixo
func hud_quadro_subarma(qx: float, qy: float, tam: float, tipo: int, pode: bool, essencia: int, essencia_fx: float, alfa := 1.0) -> void:
	var pen: Pen = G.pen
	var x2 := qx + tam
	var y2 := qy + tam
	pen.retangulo(qx + 3, qy + 5, x2 + 3, y2 + 5, Color.BLACK, 0.45 * alfa, false)
	hud_forma(PackedVector2Array([Vector2(qx - 2, qy - 2), Vector2(x2 + 2, qy - 2), Vector2(x2 + 2, y2 + 2), Vector2(qx - 2, y2 + 2)]), qy - 2, tam + 4, UI.OURO_CLARO, UI.OURO_ESCURO, alfa)
	hud_forma(PackedVector2Array([Vector2(qx + 1, qy + 1), Vector2(x2 - 1, qy + 1), Vector2(x2 - 1, y2 - 1), Vector2(qx + 1, y2 - 1)]), qy, tam, Color8(46, 16, 16), Color8(12, 6, 7), 0.96 * alfa)
	if pode:
		pen.blend_add = true
		pen.circulo(qx + tam / 2.0, qy + tam / 2.0, tam * 0.42, Color8(255, 60, 30), (0.10 + 0.05 * sin(current_time() / 200.0)) * alfa, false)
		pen.blend_add = false
	pen.retangulo(qx + 4, qy + 4, x2 - 4, y2 - 4, UI.OURO, 0.5 * alfa, true)
	for c in [Vector2(qx, qy), Vector2(x2, qy), Vector2(qx, y2), Vector2(x2, y2)]:
		pen.triangulo(c.x - 4, c.y, c.x, c.y - 4, c.x + 4, c.y, UI.OURO_CLARO, alfa, false)
		pen.triangulo(c.x - 4, c.y, c.x, c.y + 4, c.x + 4, c.y, UI.OURO_CLARO, alfa, false)
	hud_icone_subarma(qx + tam / 2.0, qy + tam / 2.0, tam * 0.36, tipo, alfa * (1.0 if pode else 0.4))
	# essência (os "corações" do Castlevania)
	var ek := 1 + 0.35 * clampf(essencia_fx / 20.0, 0, 1)
	var ex := qx + 10
	var ey := y2 + 16
	var kr := 7.0 * ek
	pen.triangulo(ex, ey - kr - 1.5, ex + kr * 0.7 + 1.5, ey, ex - kr * 0.7 - 1.5, ey, Color8(10, 18, 40), alfa, false)
	pen.triangulo(ex, ey + kr + 1.5, ex + kr * 0.7 + 1.5, ey, ex - kr * 0.7 - 1.5, ey, Color8(10, 18, 40), alfa, false)
	pen.triangulo(ex, ey - kr, ex + kr * 0.7, ey, ex - kr * 0.7, ey, Color8(140, 200, 255), alfa, false)
	pen.triangulo(ex, ey + kr, ex + kr * 0.7, ey, ex - kr * 0.7, ey, Color8(50, 110, 220), alfa, false)
	txt_sombra(ex + 12, ey, str(essencia), FONTE.PEQUENA, Color8(165, 212, 255), alfa, fa_left, fa_middle, 0.85 * ek)


# BOTÃO CONTEXTUAL (ex.: ABRIR o baú): placa ornamentada pulsando sobre o
# objeto, com a tecla/botão de INTERAGIR (no teclado/controle) e uma seta
# apontando para ele. (cx, by) = ponto logo acima do objeto, na GUI
func hud_botao_contexto(cx: float, by: float, rotulo: String, com_tecla := true, alfa := 1.0) -> void:
	var pulso := 0.5 + 0.5 * sin(current_time() / 140.0)
	var sobe := 4 * sin(current_time() / 220.0)
	var wt := txt_largura(rotulo, FONTE.PEQUENA)
	var wk := (icone_acao_largura(ACAO.INTERAGIR, 26) + 10) if com_tecla else 0.0
	var w := wt + wk + 36
	var y2 := by - 12 + sobe
	var y1 := y2 - 42
	var x1 := clampf(cx - w / 2.0, 8, G.gui_w - w - 8)
	var pen: Pen = G.pen
	pen.blend_add = true
	pen.elipse(x1 - 16, y1 - 12, x1 + w + 16, y2 + 12, Color8(255, 170, 60), (0.16 + 0.14 * pulso) * alfa, false)
	pen.blend_add = false
	desenhar_painel(x1, y1, x1 + w, y2, 0.55 + 0.45 * pulso, alfa)
	pen.triangulo(cx - 9, y2 + 3, cx + 9, y2 + 3, cx, y2 + 13, UI.OURO_CLARO, alfa, false)
	var tx := x1 + 18
	var ty := (y1 + y2) / 2.0
	if com_tecla:
		desenhar_icone_acao(tx, ty, ACAO.INTERAGIR, 26, alfa)
		tx += wk
	txt_sombra(tx, ty, rotulo, FONTE.PEQUENA, merge_color(Color8(255, 225, 150), c_white, 0.4 * pulso), alfa, fa_left, fa_middle)


# rolo de madeira em pé (laterais do pergaminho do diálogo)
func pergaminho_rolo_vertical(px: float, y1: float, y2: float, alfa: float) -> void:
	var c_esc := Color8(118, 82, 42)
	var c_luz := Color8(232, 204, 150)
	retangulo_gradiente_h(px - 12, y1, px, y2, c_esc, alfa, c_luz, alfa)
	retangulo_gradiente_h(px, y1, px + 12, y2, c_luz, alfa, c_esc, alfa)
	draw_set_alpha(alfa)
	draw_set_color(Color8(80, 52, 24))
	draw_rectangle(px - 12, y1, px + 12, y2, true)
	for py in [y1 - 7, y2 + 7]:
		draw_set_color(Color8(70, 38, 18))
		draw_ellipse(px - 15, py - 10, px + 15, py + 10, false)
		draw_set_color(Color8(150, 98, 46))
		draw_ellipse(px - 10, py - 7, px + 7, py + 4, false)
		draw_set_color(Color8(205, 160, 80))
		draw_circle(px - 4, py - 3, 3, false)


# pergaminho do diálogo: papel envelhecido entre dois rolos
func pergaminho_dialogo(x1: float, y1: float, x2: float, y2: float, alfa: float) -> void:
	var papel := Color8(238, 222, 182)
	var papel2 := Color8(206, 176, 122)
	var queim := Color8(92, 56, 26)
	var cx := (x1 + x2) / 2.0
	draw_set_alpha(0.45 * alfa)
	draw_set_color(c_black)
	draw_rectangle(x1 + 8, y1 + 12, x2 + 8, y2 + 12, false)
	retangulo_gradiente_h(x1, y1, cx, y2, papel2, alfa, papel, alfa)
	retangulo_gradiente_h(cx, y1, x2, y2, papel, alfa, papel2, alfa)
	retangulo_gradiente(x1, y1, x2, y1 + 26, queim, 0.28 * alfa, queim, 0)
	retangulo_gradiente(x1, y2 - 26, x2, y2, queim, 0, queim, 0.28 * alfa)
	draw_set_alpha(0.7 * alfa)
	draw_set_color(queim)
	draw_rectangle(x1, y1, x2, y2, true)
	pergaminho_rolo_vertical(x1 - 4, y1 - 6, y2 + 6, alfa)
	pergaminho_rolo_vertical(x2 + 4, y1 - 6, y2 + 6, alfa)
	draw_set_alpha(1)

# =====================================================================
# CRÉDITOS do fim da demo (depois do "Obrigado por jogar")
# Os nomes da equipe saíram da abertura e passam aqui, subindo pela tela.
# =====================================================================
const CREDITOS_VEL := 1.15          # pixels por passo (60/s)

static func creditos_lista() -> Array:
	var ouro := Color8(255, 210, 90)
	var branco := Color8(242, 232, 214)
	var cinza := Color8(190, 184, 178)
	return [
		{"logo": true, "h": 250.0},
		{"t": "UMA JORNADA SOBRE FORÇA, ESCOLHA E LEGADO", "f": FONTE.PEQUENA, "c": ouro, "h": 96.0},
		{"t": "DESENVOLVIDO POR", "f": FONTE.MINI, "c": cinza, "h": 34.0},
		{"t": "JEFFERSON DIAS", "f": FONTE.GRANDE, "c": branco, "h": 110.0},
		{"t": "DESENVOLVIMENTO", "f": FONTE.MINI, "c": ouro, "h": 34.0},
		{"t": "EDUARDO  ·  ISAAC  ·  ALEX  ·  ALDREON", "f": FONTE.MEDIA, "c": branco, "h": 96.0},
		{"t": "DESIGN", "f": FONTE.MINI, "c": ouro, "h": 34.0},
		{"t": "ALEX  ·  I.A. CLAUDE", "f": FONTE.MEDIA, "c": branco, "h": 96.0},
		{"t": "ROTEIRO", "f": FONTE.MINI, "c": ouro, "h": 34.0},
		{"t": "ISAAC  ·  EDUARDO  ·  I.A. CLAUDE", "f": FONTE.MEDIA, "c": branco, "h": 120.0},
		{"t": "UM PROJETO ACADÊMICO", "f": FONTE.MINI, "c": cinza, "h": 34.0},
		{"t": "FACULDADE FAPAN", "f": FONTE.MEDIA, "c": branco, "h": 130.0},
		{"t": "GAMBITECH STUDIO", "f": FONTE.GRANDE, "c": Color8(235, 120, 70), "h": 170.0},
		{"t": "A jornada continua em breve...", "f": FONTE.PEQUENA, "c": Color8(230, 120, 100), "h": 60.0},
	]


static func creditos_altura() -> float:
	var h := 0.0
	for e in creditos_lista():
		h += e.h
	return h


# tempo (passos) até a última linha chegar ao meio da tela
static func creditos_duracao() -> float:
	return (G.gui_h + creditos_altura() - G.gui_h * 0.5) / CREDITOS_VEL


func creditos_desenhar(t: float, alfa := 1.0) -> void:
	var gw := G.gui_w
	var gh := G.gui_h
	var cx := gw / 2.0
	var y := gh + 40 - t * CREDITOS_VEL
	# no fim, a última linha para no meio da tela
	y = maxf(y, gh * 0.5 - creditos_altura() + 60)
	for e in creditos_lista():
		var h: float = e.h
		var meio := y + h * 0.5
		if meio > -120 and meio < gh + 120:
			# some suavemente perto das bordas de cima e de baixo
			var borda := clampf(minf(meio, gh - meio) / 110.0, 0, 1) * alfa
			if e.has("logo"):
				if not logo_desenhar(cx, meio, h * 0.92, borda):
					txt_sombra(cx, meio, JOGO_TITULO, FONTE.GRANDE, Color8(230, 40, 40), borda, fa_center, fa_middle)
			else:
				var esc := minf(1.0, (gw * 0.9) / maxf(1, txt_largura(e.t, e.f)))
				txt_sombra(cx, meio, e.t, e.f, e.c, borda, fa_center, fa_middle, esc)
		y += h
	desenho_resetar()
