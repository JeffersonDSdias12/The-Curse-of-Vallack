extends Node2D
# =====================================================================
#  Controles de TOQUE (Android): ANALÓGICO + 4 BOTÕES
#  * analógico à esquerda (nasce onde o polegar toca):
#    ◄ ► correm, ▼ agacha, ▲ / ▼ mudam o golpe dos botões
#  * 4 botões à direita: ATAQUE, PESADO, PULO e ESQUIVA/DEFESA
#      ▼ + ATAQUE = rasteira      ▲ + ATAQUE = sub-arma (lâmina)
#      ▼ + PESADO = chama de Sylla ▲ + PESADO = lançador
#      ESQUIVA com ◄ ► rola, com ▼ salta para trás; sem direção DEFENDE
#      (segurar defende, apertar na hora do golpe apara)
#  * aparecem só quando servem: MAGIA (▲ / ▼ trocam a magia), FÚRIA (barra
#    cheia) e AÇÃO perto de baú / cristal / inimigo para executar
#  * PAUSA e ARMAS no alto, à direita
#  * botão VOLTAR nos menus (PULAR nos diálogos e cenas)
#  Os botões ficam escondidos quando um controle é usado e voltam ao tocar.
# =====================================================================

const ACAO := GMObj.ACAO

var eixo := Vector2.ZERO
var pausa_apertada := false
var armas_apertada := false

var _cont: Array = []           # dedos segurando cada ação
var _ap: Array = []             # ação apertada neste passo
var _ap_ev: Array = []          # ação apertada desde o último passo
var _pausa_ev := false
var _armas_ev := false
var _dedos := {}                # índice do toque -> ação EFETIVA (-1 analógico, -2 pausa, -3 armas, -4 voltar)
var _dedo_botao := {}           # índice do toque -> botão (ação base) que o dedo segura
var _ana_idx := -1              # dedo no analógico
var _ana_ponta := Vector2.ZERO
var _ana_centro := Vector2.ZERO  # onde o polegar tocou (o analógico nasce ali)
var _modo := ""
var _flash := {}                # brilho ao apertar
var _contexto := ""             # "ABRIR", "SALVAR", "EXECUTAR" ou "" (botão AÇÃO)

# v1.21 — HUD PERSONALIZADA: modo (2, 4 ou 8 dedos), tamanho livre e cada botão
# pode ser arrastado para onde o jogador quiser (OPÇÕES > HUD DE TOQUE)
const MODO_NOMES := ["2 DEDOS", "4 DEDOS", "8 DEDOS"]
const BR := 0                   # âncora: canto inferior direito
const BL := 1                   # âncora: canto inferior esquerdo
var arrastando := false         # o editor está movendo um botão (o menu ignora o clique)
var _edit_idx := -1
var _edit_chave := ""
var _edit_ini := Vector2.ZERO
var _edit_delta0 := Vector2.ZERO
var _edit_base := Vector2.ZERO  # centro do botão sem o ajuste do jogador
var _edit_raio := 40.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	for i in ACAO.TOTAL:
		_cont.append(0)
		_ap.append(false)
		_ap_ev.append(false)
	# anel suave (contorno dos botões) desenhado como textura: círculos e arcos
	# do CanvasItem viram polígonos, que custam um buffer novo a cada quadro
	var ct := CanvasTexture.new()
	ct.diffuse_texture = Pen.textura_radial(256, [0.0, 0.902, 0.912, 0.992, 1.0], [0.0, 0.0, 1.0, 1.0, 0.0])
	ct.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_anel_tex = ct


var _anel_tex: CanvasTexture


func _disco(p: Vector2, r: float, cor: Color) -> void:
	draw_texture_rect(G.pen.disco, Rect2(p.x - r, p.y - r, r * 2.0, r * 2.0), false, cor)


func _anel(p: Vector2, r: float, cor: Color) -> void:
	draw_texture_rect(_anel_tex, Rect2(p.x - r, p.y - r, r * 2.0, r * 2.0), false, cor)


# arco parcial feito de segmentos de linha (primitivas agrupadas)
func _arco(p: Vector2, r: float, a0: float, a1: float, cor: Color, w: float) -> void:
	var n := maxi(2, int(ceil(absf(a1 - a0) / TAU * 40.0)))
	var ant := p + Vector2(cos(a0), sin(a0)) * r
	for i in range(1, n + 1):
		var ang := a0 + (a1 - a0) * i / n
		var q := p + Vector2(cos(ang), sin(ang)) * r
		draw_line(ant, q, cor, w)
		ant = q


func _escala() -> float:
	return clampf(G.cfg_hud_tam, 0.6, 1.6)


func _modo_hud() -> int:
	return clampi(G.cfg_hud_modo, 0, 2)


# ajuste que o jogador deu a um botão (arrastando no editor)
func _ajuste(chave: String) -> Vector2:
	return G.cfg_hud_pos.get(str(_modo_hud()) + "_" + chave, Vector2.ZERO)


func _no_ecra(p: Vector2, r: float) -> Vector2:
	return Vector2(clampf(p.x, r, maxf(r, G.gui_w - r)), clampf(p.y, r, maxf(r, G.gui_h - r)))


func mostrar_toque() -> bool:
	if G.usando_pad and G.pad_slot >= 0:
		return false
	return G.usando_toque or OS.has_feature("mobile")


# "jogo" (botões de ação), "menu" (botão VOLTAR) ou "" (nada)
func calcular_modo() -> String:
	if not mostrar_toque():
		return ""
	if G.lib == null:
		return ""
	var lib = G.lib
	if lib.instance_exists("obj_loading") or lib.instance_exists("obj_resultado") or lib.instance_exists("obj_final") or lib.instance_exists("obj_game_over"):
		return ""
	if lib.instance_exists("obj_pausa") or lib.instance_exists("obj_save_menu") or lib.instance_exists("obj_menu_armas"):
		return "menu"
	var d = lib.instance_find("obj_dialogo", 0)
	if d != null:
		return "" if d.pendente else "menu"
	var c = lib.instance_find("obj_cutscene", 0)
	if c != null:
		return "menu" if c.fase == "mostrando" else ""
	var m = lib.instance_find("obj_menu", 0)
	if m != null:
		if m.estado == "hud":
			return "editor"          # v1.21: editor da HUD (arrastar os botões)
		return "menu" if m.estado in ["dificuldade", "carregar", "slot_novo", "opcoes", "teclado", "controle"] else ""
	var p = lib.instance_find("obj_player", 0)
	if p != null and not p.morto:
		return "jogo"
	return ""


# botões de ação: [ação base, centro, raio, grande], em volta do ATAQUE (canto
# inferior direito). Só 4 fixos; MAGIA, FÚRIA e AÇÃO aparecem quando servem
# (menos botões poluindo a tela). A ação de verdade depende do analógico: _efetiva.
func layout(tudo := false) -> Array:
	var s := _escala()
	var r := []
	for e in _layout_base(tudo):
		var anc := Vector2(G.gui_w, G.gui_h) if e[1] == BR else Vector2(0, G.gui_h)
		var raio: float = e[3] * s
		r.append([e[0], _no_ecra(anc + e[2] * s + _ajuste(str(e[0])), raio), raio, e[4]])
	return r


# [ação base, âncora, deslocamento, raio, grande]. "tudo" = todos os botões do modo,
# mesmo os que só aparecem quando servem (para o editor da HUD).
#  2 DEDOS (polegares): 4 botões; o resto sai de direção + botão ou aparece quando serve
#  4 DEDOS (garra): + DEFESA e AÇÃO/SUB-ARMA no alto à esquerda, MAGIA no alto à direita
#  8 DEDOS: cada golpe tem o seu botão (rasteira e as três magias também)
func _layout_base(tudo: bool) -> Array:
	var modo := _modo_hud()
	var p = G.lib.instance_find("obj_player", 0) if G.lib != null else null
	var furia: bool = tudo or (p != null and (p.furia >= 100 or p.furia_modo))
	var l := [
		[ACAO.ATACAR, BR, Vector2(-118, -122), 60.0, true],
		[ACAO.PULAR, BR, Vector2(-266, -80), 44.0, false],
		[ACAO.ESQUIVA, BR, Vector2(-252, -218), 40.0, false],
		[ACAO.ATAQUE_FORTE, BR, Vector2(-108, -280), 40.0, false],
	]
	if modo == 0:
		if tudo or magia_base() >= 0:
			l.append([ACAO.ESPECIAL, BR, Vector2(-376, -200), 36.0, false])
		if furia:
			l.append([ACAO.FURIA, BR, Vector2(-300, -336), 38.0, false])
		if tudo or _contexto != "":
			l.append([ACAO.INTERAGIR, BR, Vector2(-404, -72), 50.0, true])
		return l
	# 4 e 8 dedos: os indicadores alcançam o alto da tela
	l.append([ACAO.DEFENDER, BL, Vector2(110, -340), 40.0, false])
	l.append([ACAO.INTERAGIR, BL, Vector2(250, -366), 40.0, false])
	# (no 8 DEDOS este botão é só a ONDA: as outras magias têm os seus)
	if tudo or (LibBase.especial_liberado_s(ACAO.ESPECIAL) if modo == 2 else magia_base() >= 0):
		l.append([ACAO.ESPECIAL, BR, Vector2(-250, -366), 38.0, false])
	if furia:
		l.append([ACAO.FURIA, BR, Vector2(-390, -210), 38.0, false])
	if modo == 2:
		l.append([ACAO.ATAQUE_SALTO, BR, Vector2(-400, -84), 38.0, false])
		if tudo or LibBase.especial_liberado_s(ACAO.ESPECIAL_2):
			l.append([ACAO.ESPECIAL_2, BR, Vector2(-362, -366), 36.0, false])
		if tudo or LibBase.especial_liberado_s(ACAO.ESPECIAL_3):
			l.append([ACAO.ESPECIAL_3, BR, Vector2(-470, -340), 36.0, false])
	return l

# o que o botão AÇÃO faz agora (ele só aparece nesses casos)
func _calcular_contexto(p) -> String:
	if p == null or p.morto:
		return ""
	if p.alvo_interacao != null and G.existe(p.alvo_interacao):
		return "ABRIR" if p.alvo_interacao.obj == "obj_bau" else "SALVAR"
	if p.alvo_finalizavel() != null:
		return "EXECUTAR"
	return ""


# Twilight está colado num baú fechado (o AÇÃO vira ABRIR)
func perto_do_bau(_p = null) -> bool:
	return _contexto == "ABRIR"


# magia do botão MAGIA sem seta: ONDA, senão TREMOR, senão QUEDA (-1: nenhuma liberada)
func magia_base() -> int:
	for esp in [ACAO.ESPECIAL, ACAO.ESPECIAL_3, ACAO.ESPECIAL_2]:
		if LibBase.especial_liberado_s(esp):
			return esp
	return -1


func _seta_cima() -> bool:
	return _ana_idx >= 0 and eixo.y < -0.5 and absf(eixo.y) > absf(eixo.x)


func _seta_baixo() -> bool:
	return _ana_idx >= 0 and eixo.y > 0.5 and absf(eixo.y) > absf(eixo.x)


func _seta_lado() -> bool:
	return _ana_idx >= 0 and absf(eixo.x) > 0.35


# a ação que o botão faz com a direção do analógico (Castlevania: direção + botão)
func _efetiva(a: int) -> int:
	# v1.21: no modo 8 DEDOS cada magia tem o seu botão (a direção não troca a magia)
	if _modo_hud() == 2 and a == ACAO.ESPECIAL:
		return a
	match a:
		ACAO.ATACAR:
			if _seta_cima():
				return ACAO.INTERAGIR          # sub-arma (lâmina bumerangue)
			if _seta_baixo():
				return ACAO.ATAQUE_SALTO       # rasteira / rasteira sangrenta
		ACAO.ATAQUE_FORTE:
			if _seta_baixo():
				return ACAO.INTERAGIR          # agachado: chama de Sylla
		ACAO.ESQUIVA:
			if not _seta_lado() and not _seta_baixo():
				return ACAO.DEFENDER           # sem direção: defende / apara
		ACAO.ESPECIAL:
			var m := magia_base()
			if _seta_cima() and LibBase.especial_liberado_s(ACAO.ESPECIAL_2):
				return ACAO.ESPECIAL_2
			if _seta_baixo() and LibBase.especial_liberado_s(ACAO.ESPECIAL_3):
				return ACAO.ESPECIAL_3
			return m if m >= 0 else a
	return a


func _pos_pausa() -> Vector2:
	return Vector2(G.gui_w - 48, 44)


func _pos_armas() -> Vector2:
	return Vector2(G.gui_w - 124, 44)


func _rect_voltar() -> Rect2:
	return Rect2(14, 14, 168, 58)


# o toque em p cai no botão VOLTAR (o clique emulado não deve contar nos menus)
func toca_voltar(p: Vector2) -> bool:
	return calcular_modo() == "menu" and _rect_voltar().grow(10).has_point(p)


# analógico parado (canto inferior esquerdo)
func _centro_repouso() -> Vector2:
	var s := _escala()
	return _no_ecra(Vector2(36 + 118 * s, G.gui_h - 36 - 118 * s) + _ajuste("ana"), _raio_ana())


func _raio_ana() -> float:
	return 84.0 * _escala()


func segurado(a: int) -> bool:
	if _modo != "jogo":
		return false
	if _cont[a] > 0 or _ap[a]:
		return true
	if _ana_idx >= 0:
		if a == ACAO.ESQUERDA and eixo.x < -0.35:
			return true
		if a == ACAO.DIREITA and eixo.x > 0.35:
			return true
		if a == ACAO.AGACHAR and eixo.y > 0.65 and eixo.y > absf(eixo.x):
			return true
	return false


# chamado pelo G no começo de cada passo do jogo
func comecar_tick() -> void:
	pausa_apertada = _pausa_ev
	armas_apertada = _armas_ev
	_pausa_ev = false
	_armas_ev = false
	for i in ACAO.TOTAL:
		_ap[i] = _ap_ev[i]
		_ap_ev[i] = false


func fim_tick() -> void:
	pass


func limpar_apertos() -> void:
	for i in ACAO.TOTAL:
		_ap[i] = false
		_ap_ev[i] = false
	pausa_apertada = false
	armas_apertada = false
	_pausa_ev = false
	_armas_ev = false


func _soltar_tudo() -> void:
	_dedos.clear()
	_dedo_botao.clear()
	for i in ACAO.TOTAL:
		_cont[i] = 0
	_ana_idx = -1
	eixo = Vector2.ZERO


func _process(_delta: float) -> void:
	var novo := calcular_modo()
	if novo != _modo:
		_soltar_tudo()
		_modo = novo
	_contexto = _calcular_contexto(G.lib.instance_find("obj_player", 0)) if (_modo == "jogo" and G.lib != null) else ""
	for k in _flash.keys():
		_flash[k] -= _delta
		if _flash[k] <= 0:
			_flash.erase(k)


func _input(ev: InputEvent) -> void:
	if ev is InputEventScreenTouch:
		G.usando_toque = true
		if ev.pressed:
			_toque_inicio(ev.index, ev.position)
		else:
			_toque_fim(ev.index)
	elif ev is InputEventScreenDrag:
		_toque_move(ev.index, ev.position)


func _botao_em(p: Vector2) -> int:
	var melhor := -1
	var dm := INF
	for b in layout():
		var d: float = p.distance_to(b[1])
		if d < b[2] * 1.18 and d < dm:
			dm = d
			melhor = b[0]
	return melhor


func _toque_inicio(i: int, p: Vector2) -> void:
	_modo = calcular_modo()
	if _modo == "menu":
		if _rect_voltar().grow(10).has_point(p):
			_dedos[i] = -4
			G.voltar_ev = true
			_flash[-4] = 0.2
		return
	if _modo == "editor":
		if _rect_voltar().grow(10).has_point(p):
			_dedos[i] = -4
			G.voltar_ev = true
			_flash[-4] = 0.2
		else:
			_editor_inicio(i, p)
		return
	if _modo != "jogo":
		return
	if p.distance_to(_pos_pausa()) < 36:
		_dedos[i] = -2
		_pausa_ev = true
		_flash[-2] = 0.2
		return
	if p.distance_to(_pos_armas()) < 36:
		_dedos[i] = -3
		_armas_ev = true
		_flash[-3] = 0.2
		return
	var a := _botao_em(p)
	if a >= 0:
		_apertar(i, a)
		return
	# analógico: qualquer toque no lado dele (o esquerdo, a não ser que o jogador o
	# tenha levado para a direita); ele nasce onde o polegar tocou
	var lado_esq := _centro_repouso().x < G.gui_w / 2.0
	var no_lado := p.x < G.gui_w * 0.45 if lado_esq else p.x > G.gui_w * 0.55
	if no_lado and p.y > G.gui_h * 0.28 and _ana_idx < 0:
		var r := _raio_ana()
		_dedos[i] = -1
		_ana_idx = i
		_ana_centro = Vector2(maxf(p.x, r + 16), minf(p.y, G.gui_h - r - 16))
		_ana_ponta = p
		_atualizar_eixo()


# o dedo i apertou o botão de ação base a: entra a ação efetiva (com a direção)
func _apertar(i: int, a: int) -> void:
	var e := _efetiva(a)
	_dedos[i] = e
	_dedo_botao[i] = a
	_cont[e] += 1
	_ap_ev[e] = true
	_flash[a] = 0.15


func _toque_move(i: int, p: Vector2) -> void:
	if arrastando and i == _edit_idx:
		var alvo := _no_ecra(_edit_base + _edit_delta0 + (p - _edit_ini), _edit_raio)
		G.cfg_hud_pos[str(_modo_hud()) + "_" + _edit_chave] = alvo - _edit_base
		return
	if not _dedos.has(i):
		return
	var a: int = _dedos[i]
	if a == -1:
		_ana_ponta = p
		_atualizar_eixo()
	elif a >= 0:
		# o dedo deslizou para outro botão: troca (ex.: de ATAQUE para PULO)
		var b := _botao_em(p)
		if b >= 0 and b != _dedo_botao.get(i, -1):
			_cont[a] = maxi(0, _cont[a] - 1)
			_apertar(i, b)


func _toque_fim(i: int) -> void:
	if arrastando and i == _edit_idx:
		arrastando = false
		_edit_idx = -1
		LibBase.config_salvar()
		return
	if not _dedos.has(i):
		return
	var a: int = _dedos[i]
	_dedos.erase(i)
	_dedo_botao.erase(i)
	if a == -1:
		_ana_idx = -1
		eixo = Vector2.ZERO
	elif a >= 0:
		_cont[a] = maxi(0, _cont[a] - 1)


# analógico: direção contínua (comprimento até 1), com zona morta no centro
func _atualizar_eixo() -> void:
	var v := (_ana_ponta - _ana_centro) / _raio_ana()
	if v.length() < 0.18:
		eixo = Vector2.ZERO
		return
	eixo = v.limit_length(1.0)


# ---------------------------------------------------------------------
# DESENHO
# ---------------------------------------------------------------------
# ----- editor da HUD: o dedo pega o botão mais perto e arrasta -----
func _editor_inicio(i: int, p: Vector2) -> void:
	if arrastando:
		return
	var chave := ""
	var dm := INF
	var raio := 40.0
	for b in layout(true):
		var d: float = p.distance_to(b[1])
		if d < b[2] * 1.25 and d < dm:
			dm = d
			chave = str(b[0])
			raio = b[2]
	var ca := _centro_repouso()
	if chave == "" and p.distance_to(ca) < _raio_ana() * 1.15:
		chave = "ana"
		raio = _raio_ana()
	if chave == "":
		return
	arrastando = true
	_edit_idx = i
	_edit_chave = chave
	_edit_ini = p
	_edit_delta0 = _ajuste(chave)
	_edit_raio = raio
	# centro sem o ajuste: o de agora menos o ajuste (antes do limite da tela, o
	# ajuste guardado pode ser maior; recomeça do que está na tela)
	var agora := ca
	if chave != "ana":
		for b in layout(true):
			if str(b[0]) == chave:
				agora = b[1]
	_edit_base = agora - _edit_delta0
	_flash[-9] = 0.2


# volta os botões deste modo para o lugar de fábrica
func restaurar_posicoes() -> void:
	var pre := str(_modo_hud()) + "_"
	for k in G.cfg_hud_pos.keys():
		if str(k).begins_with(pre):
			G.cfg_hud_pos.erase(k)


func _desenhar_editor() -> void:
	var op := maxf(G.cfg_toque_opac, 0.2)
	var s := _escala()
	var raio := _raio_ana()
	var c := _centro_repouso()
	var pega_ana := arrastando and _edit_chave == "ana"
	if pega_ana:
		_arte("brilho", c, raio * 1.3, Color(1.0, 0.82, 0.45, 0.6))
	_arte("joy_base", c, raio * 1.1, Color(1, 1, 1, clampf(op * 1.2, 0.3, 0.95)))
	_arte("joy_pino", c, raio * 0.5, Color(1, 1, 1, clampf(op * 1.7, 0.45, 1.0)))
	_rotulo(c + Vector2(0, raio * 1.1 + 12 * s), "ANALÓGICO", int(round(12.0 * s)), 0.9)
	for b in layout(true):
		var a: int = b[0]
		var pos: Vector2 = b[1]
		var r: float = b[2]
		var pega := arrastando and _edit_chave == str(a)
		if pega:
			_arte("brilho", pos, r * 1.45, Color(1.0, 0.82, 0.45, 0.7))
		_botao(pos, r, a, b[3], pega, true, op)
		_rotulo(pos + Vector2(0, r * 1.12 + 9 * s), _nome_botao(a, a), int(round(12.0 * s)), 0.9)


func _draw() -> void:
	if _modo == "editor":
		_desenhar_voltar()
		_desenhar_editor()
	elif _modo == "menu":
		_desenhar_voltar()
	elif _modo == "jogo":
		_desenhar_jogo()


func _texto(p: Vector2, s: String, tam: int, cor: Color) -> void:
	var f: Font = G.fontes[4]
	var w := Pen._larg_linha(s, f, tam)
	var asc := f.get_ascent(tam)
	var h := f.get_height(tam)
	draw_string(f, p + Vector2(-w / 2.0 + 1, -h / 2.0 + asc + 1), s, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, Color(0, 0, 0, cor.a * 0.7))
	draw_string(f, p + Vector2(-w / 2.0, -h / 2.0 + asc), s, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, cor)


# nome embaixo do botão: letra serifada clara com contorno escuro
func _rotulo(p: Vector2, s: String, tam: int, alfa: float) -> void:
	var f: Font = G.fontes[2]
	var w := Pen._larg_linha(s, f, tam)
	var pos := p + Vector2(-w / 2.0, -f.get_height(tam) / 2.0 + f.get_ascent(tam))
	draw_string_outline(f, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, maxi(3, int(tam / 3.5)), Color(0.05, 0.03, 0.03, 0.9 * alfa))
	draw_string(f, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, Color(UI.MARFIM.r, UI.MARFIM.g, UI.MARFIM.b, alfa))


func _arte(nome: String, c: Vector2, raio: float, cor: Color) -> void:
	draw_texture_rect(UI.tex(nome), Rect2(c.x - raio, c.y - raio, raio * 2.0, raio * 2.0), false, cor)


# botão redondo: fundo escuro, brilho na cor da ação, ícone e aro dourado
func _botao(pos: Vector2, r: float, acao: int, grande: bool, preso: bool, dispon: bool, op: float, carga := -1.0) -> void:
	var cor := LibBase.toque_cor(acao)
	var rr := r * 1.12 * (0.93 if preso else 1.0)
	var a_fundo := clampf(op * 1.3, 0.3, 0.95)
	var a_arte := clampf(op * 1.7, 0.4, 1.0) * (1.0 if dispon else 0.55)
	var kf := 0.82 if grande else 1.0     # o aro grande tem pontas: o miolo é menor
	_disco(pos + Vector2(0, 3), rr * 0.9 * kf, Color(0, 0, 0, 0.35 * a_fundo))
	_arte("base", pos, rr * kf, Color(1, 1, 1, a_fundo))
	var aceso := preso or _flash.has(acao)
	_arte("brilho", pos, rr * (0.86 if grande else 1.0), Color(cor.r, cor.g, cor.b, (0.95 if aceso else 0.5) * a_arte))
	if aceso:
		_disco(pos, rr * 0.74 * kf, Color(cor.r, cor.g, cor.b, 0.22 * a_arte))
	# magia carregando: arco em volta, por dentro do aro
	if carga >= 0.0 and carga < 1.0:
		_arco(pos, rr * 0.8, -PI / 2, -PI / 2 + TAU * carga, Color(0.5, 0.75, 1.0, 0.9 * a_arte), 3.0)
	var ic := rr * (0.46 if grande else 0.54)
	var cic := UI.MARFIM if dispon else Color(0.6, 0.57, 0.55)
	_arte(UI.icone(acao), pos, ic, Color(cic.r, cic.g, cic.b, a_arte))
	_arte("aro_grande" if grande else "aro", pos, rr, Color(1, 1, 1, a_arte))


func _desenhar_voltar() -> void:
	var r := _rect_voltar()
	var a := 0.9 if _flash.has(-4) else 0.72
	draw_rect(r.grow(2), Color(0.03, 0.02, 0.02, a))
	draw_rect(r, Color(0.09, 0.06, 0.06, a))
	draw_rect(r, Color(UI.OURO.r, UI.OURO.g, UI.OURO.b, 0.95), false, 2.0)
	# nos diálogos e cenas o botão PULA a conversa; nos menus ele VOLTA
	_rotulo(r.get_center(), "PULAR  »" if em_dialogo() else "‹  VOLTAR", 22, 1.0)


# diálogo ou cena na tela (o botão do canto vira PULAR)
func em_dialogo() -> bool:
	if G.lib == null:
		return false
	return G.lib.instance_exists("obj_dialogo") or G.lib.instance_exists("obj_cutscene")


func _desenhar_jogo() -> void:
	var op := G.cfg_toque_opac
	var s := _escala()
	var p = G.lib.instance_find("obj_player", 0)
	# ----- analógico: base onde o polegar tocou e o pino seguindo o dedo -----
	var raio := _raio_ana()
	var ativo := _ana_idx >= 0
	var c := _ana_centro if ativo else _centro_repouso()
	var a_base := clampf(op * (1.5 if ativo else 1.2), 0.3, 0.95)
	_arte("joy_base", c, raio * 1.1, Color(1, 1, 1, a_base))
	var pino := c + (_ana_ponta - c).limit_length(raio) if ativo else c
	if ativo and eixo != Vector2.ZERO:
		_arte("brilho", pino, raio * 0.62, Color(1.0, 0.82, 0.45, 0.55))
	_arte("joy_pino", pino, raio * 0.5, Color(1, 1, 1, clampf(op * 1.7, 0.45, 1.0)))
	# ----- botões de ação -----
	var alfa_txt := clampf(op * 1.2, 0.35, 0.7)          # rótulos discretos
	for b in layout():
		var a: int = b[0]
		var pos: Vector2 = b[1]
		var r: float = b[2]
		var grande: bool = b[3]
		var preso := _botao_preso(a)
		var carga := -1.0
		var mostra := a
		if a == ACAO.ESPECIAL:
			# o botão MAGIA mostra a magia que sai com a direção de agora
			mostra = _efetiva(a)
			if p != null:
				carga = clampf(p.especial_carga / LibBase.ESPECIAL_SEGUNDOS / Lib.especial_custo(mostra), 0, 1)
		elif a == ACAO.ATACAR or a == ACAO.ATAQUE_FORTE or a == ACAO.ESQUIVA:
			mostra = _efetiva(a) if _ana_idx >= 0 else a
		var contexto := a == ACAO.INTERAGIR and _contexto != ""
		if contexto:
			# baú, cristal ou execução por perto: brilho dourado pulsando
			var pb := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 140.0)
			_arte("brilho", pos, r * (1.3 + 0.15 * pb), Color(1.0, 0.72, 0.3, 0.45 + 0.35 * pb))
		_botao(pos, r, mostra, grande, preso, _disponivel(mostra, p), op, carga)
		var nome := _contexto if contexto else _nome_botao(a, mostra)
		_rotulo(pos + Vector2(0, r * 1.12 + 9 * s), nome, int(round((16.0 if contexto else 12.0) * s)), 1.0 if contexto else alfa_txt)
		# FÚRIA cheia: pulsa chamando a atenção
		if a == ACAO.FURIA and p != null and not p.furia_modo:
			var pulso := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 110.0)
			_arte("brilho", pos, r * (1.25 + 0.12 * pulso), Color(1.0, 0.3, 0.15, 0.55 * pulso))
	# ----- PAUSA e ARMAS (alto, à direita) -----
	for item in [[_pos_armas(), "ic_armas", "ARMAS", -3], [_pos_pausa(), "ic_pausa", "PAUSA", -2]]:
		var pc: Vector2 = item[0]
		var rr := 26.0
		var aceso: bool = _flash.has(item[3])
		_arte("base", pc, rr, Color(1, 1, 1, clampf(op * 1.3, 0.35, 0.95)))
		if aceso:
			_disco(pc, rr * 0.8, Color(1, 0.85, 0.5, 0.3))
		_arte(item[1], pc, rr * 0.5, Color(UI.MARFIM.r, UI.MARFIM.g, UI.MARFIM.b, 1))
		_arte("aro", pc, rr, Color(1, 1, 1, 1))
		_rotulo(pc + Vector2(0, rr + 11), item[2], 12, 0.95)
	# orbs suficientes para evoluir a espada: ponto vermelho em ARMAS
	if p != null and G.espada_nivel < 5 and G.orbs >= Lib.espada_custo(G.espada_nivel + 1):
		var pa := _pos_armas() + Vector2(19, -19)
		_disco(pa, 8, Color(0.1, 0.02, 0.02, 0.9))
		_disco(pa, 6, Color(1, 0.25, 0.15, 1))

# algum dedo segura este botão (ação base)
func _botao_preso(a: int) -> bool:
	for k in _dedo_botao:
		if _dedo_botao[k] == a:
			return true
	return false


# nome curto embaixo do botão (muda com a direção: ▼ + ATAQUE = RASTEIRA...)
func _nome_botao(a: int, efetiva: int) -> String:
	match a:
		ACAO.ATACAR:
			if efetiva == ACAO.INTERAGIR:
				return "SUB-ARMA"
			return "RASTEIRA" if efetiva == ACAO.ATAQUE_SALTO else "ATAQUE"
		ACAO.ATAQUE_FORTE:
			return "CHAMA" if efetiva == ACAO.INTERAGIR else "PESADO"
		ACAO.ESQUIVA:
			if _ana_idx < 0:
				return "ESQ · DEF"
			return "DEFESA" if efetiva == ACAO.DEFENDER else "ESQUIVA"
		ACAO.ESPECIAL:
			return LibBase.toque_nome(efetiva)
		ACAO.INTERAGIR:
			return "AÇÃO" if _modo_hud() == 0 else "SUB-ARMA"
		ACAO.DEFENDER:
			return "DEFESA"
		ACAO.ATAQUE_SALTO:
			return "RASTEIRA"
	return LibBase.toque_nome(a)


func _disponivel(a: int, p) -> bool:
	if p == null:
		return true
	match a:
		ACAO.ESPECIAL, ACAO.ESPECIAL_2, ACAO.ESPECIAL_3:
			return LibBase.especial_liberado_s(a) and p.especial_carga >= Lib.especial_custo(a) * LibBase.ESPECIAL_SEGUNDOS
		ACAO.FURIA:
			return p.furia >= 100 or p.furia_modo
		ACAO.INTERAGIR:
			return _contexto != "" or G.essencia >= 1
	return true
