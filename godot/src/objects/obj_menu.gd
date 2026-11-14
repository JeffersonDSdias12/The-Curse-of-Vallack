extends Lib
# =====================================================================
#  obj_menu — abertura (vídeo do estúdio + aviso + título), menu inicial e opções
#  intro_video -> intro_aviso -> intro_titulo -> pressione ("pressione qualquer botão") -> menu
#  (os créditos com os nomes da equipe passam no fim da demo: Lib.creditos_*)
#  menu -> dificuldade -> (slot_novo) -> cutscene -> jogo | carregar | opcoes -> teclado / controle
#  No Android tudo funciona com toques (e com o VOLTAR do sistema).
# =====================================================================

const CFG_ULTIMO_VALOR := 10      # linhas 0..10 têm valor (« »); depois HUD DE TOQUE, TECLADO, CONTROLE, TESTE e VOLTAR

var img_aviso: Texture2D = null
var img_retrato: Texture2D = null     # v1.14: busto de Twilight (ferramentas/gerar_menu.ps1)
var img_mancha: Texture2D = null      # v1.14: pincelada de sangue atrás da logo
var estado := "menu"
var aviso_total := 360.0
var som_estado := ""
var som_sel := 0
var tempo := 0.0
var tempo_total := 0.0
var selecionado := 0
var selecionado_antes := -1
var mouse_antes := Vector2(-1, -1)
var opcoes_menu := ["NOVO JOGO", "CARREGAR JOGO", "CONQUISTAS", "OPÇÕES", "SAIR"]     # v1.17: CONQUISTAS (perfil e recompensas)
var opcoes_cfg := ["DESEMPENHO", "QUALIDADE VISUAL", "TAXA DE QUADROS", "RESOLUÇÃO", "VOLUME GERAL", "VOLUME DA MÚSICA", "VOLUME DOS EFEITOS",
	"FUNDO HD (FASE 1)", "DICAS NO CARREGAMENTO", "CÂMERA DE AÇÃO", "VIBRAÇÃO", "HUD DE TOQUE", "TECLADO", "CONTROLE", "TESTE DE DESEMPENHO", "VOLTAR"]
var hud_sel := 0     # v1.21: linha escolhida no editor da HUD (modo, tamanho, opacidade, restaurar)
# v1.17: menu mais vivo: tochas, braseiros e faíscas que seguem o dedo / o ponteiro
var fogo_part: Array = []
var fogo_ondas: Array = []
var ponteiro_x := 0.0
var ponteiro_y := 0.0
var paralaxe_x := 0.0
var paralaxe_y := 0.0
var acoes: Array = []
var acoes_tela: Array = []
var anim: Array = []
var capturando := false
var capture_wait := 0.0
var captura_solto := false
var mensagem := ""
var mensagem_tempo := 0.0
var confirmar_slot := -1
var slots: Array = []
var tem_save := false
var faiscas: Array = []
var cinzas: Array = []           # v1.14: cinzas caindo sobre a cena do menu
var relampago := 0.0
var proximo_relampago := 0.0
var gotas: Array = []
var titulo_x1 := 0.0
var titulo_x2 := 0.0
var titulo_base := 0.0
var menu_aparece := 0.0
const VIDEO_INTRO := "res://assets/video/intro_estudio.ogv"
var video_camada: CanvasLayer = null
var video_player: VideoStreamPlayer = null
var titulo_inicio := 40.0
var titulo_intervalo := 8.0
var sub_inicio := 0.0
var sub_intervalo := 4.0
var devs_inicio := 0.0
var titulo_anim_fim := 0.0
var titulo_total := 0.0


func ev_create() -> void:
	globais_iniciar()
	if not instance_exists("obj_sistema"):
		instance_create_depth(0, 0, 0, "obj_sistema")
	audio_cena_definir("titulo")
	if G.logo_img == null:
		G.logo_img = imagem_carregar("logo_vallack.png")
	img_aviso = null if G.intro_vista else imagem_carregar("intro_aviso.jpg")
	img_retrato = imagem_carregar("heroi_retrato.png")
	img_mancha = imagem_carregar("mancha_sangue.png")
	if G.intro_vista:
		estado = "menu"
	elif ResourceLoader.exists(VIDEO_INTRO):
		estado = "intro_video"
		video_comecar()
	else:
		estado = "intro_aviso" if img_aviso != null else "intro_titulo"
	if estado != "intro_video":
		musica("bgm_main_menu", 1500.0 if G.intro_vista else 3000.0)
	som_estado = estado
	if G.perfil.is_empty():
		V117.perfil_carregar()
	else:
		V117.perfil_salvar_se_mudou()
	ponteiro_x = G.gui_w / 2.0
	ponteiro_y = G.gui_h / 2.0
	acoes = acoes_nomes()
	acoes_tela = acoes_ordem_tela()
	anim.resize(24)
	anim.fill(0.0)
	proximo_relampago = randi_range(300, 600)
	sub_inicio = titulo_inicio + (JOGO_TITULO.length() - 1) * titulo_intervalo + 40
	if G.logo_img != null:
		sub_inicio = titulo_inicio + 120
	devs_inicio = sub_inicio + (JOGO_SUBTITULO.length() - 1) * sub_intervalo + 30
	titulo_anim_fim = devs_inicio + 45
	titulo_total = titulo_anim_fim + 300 + 45
	atualizar_slots()


# ----- vídeo do estúdio (GAMBITECH STUDIO) na abertura -----
# Passa inteiro, sem como pular: o menu só aparece quando ele termina.
func video_comecar() -> void:
	G.video_intro_ativo = true
	video_camada = CanvasLayer.new()
	video_camada.layer = 20
	G.add_child(video_camada)
	var fundo := ColorRect.new()
	fundo.color = Color.BLACK
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	video_camada.add_child(fundo)
	video_player = VideoStreamPlayer.new()
	video_player.stream = load(VIDEO_INTRO)
	video_player.expand = true
	video_camada.add_child(video_player)
	_video_ajustar()
	video_player.play()
	G.marca_inicio("video comecou")


# o vídeo inteiro na tela, sem cortar (barras pretas se a proporção não bater)
func _video_ajustar() -> void:
	if video_player == null:
		return
	var gw := G.gui_w
	var gh := G.gui_h
	var prop := 848.0 / 480.0
	var w := minf(gw, gh * prop)
	var h := w / prop
	video_player.position = Vector2((gw - w) / 2.0, (gh - h) / 2.0)
	video_player.size = Vector2(w, h)


func video_terminar() -> void:
	if video_camada != null:
		video_camada.queue_free()
	video_camada = null
	video_player = null
	G.video_intro_ativo = false
	G.io_clear()
	tempo = 0
	estado = "intro_aviso" if img_aviso != null else "intro_titulo"
	musica("bgm_main_menu", 3000.0)


func ev_cleanup() -> void:
	if video_camada != null:
		video_camada.queue_free()
		G.video_intro_ativo = false


func atualizar_slots() -> void:
	slots = [slot_info(1), slot_info(2), slot_info(3)]
	tem_save = slots[0].existe or slots[1].existe or slots[2].existe
	# v1.20: com progresso salvo, CONTINUAR vem primeiro (como nos jogos de console)
	opcoes_menu = ["NOVO JOGO", "CARREGAR JOGO", "CONQUISTAS", "OPÇÕES", "SAIR"]
	if tem_save:
		opcoes_menu.push_front("CONTINUAR")


func mudar_estado(novo: String, sel: int, com_som := true) -> void:
	if com_som:
		var volta := novo == "menu" or (novo == "opcoes" and (estado == "teclado" or estado == "controle")) \
			or (novo == "dificuldade" and estado == "slot_novo") or (novo == "opcoes" and estado == "hud")
		som("tit_voltar" if volta else "tit_selecao", 0.8, 0.02)
	if novo != estado:
		V117.transicao_revelar(20)     # v1.19: a tela nova surge atrás da cortina em brasa
	estado = novo
	selecionado = sel
	selecionado_antes = -1
	tempo = 0
	capturando = false
	confirmar_slot = -1
	mensagem = ""
	if novo == "menu" or novo == "carregar" or novo == "slot_novo":
		atualizar_slots()
	if novo == "menu" and tem_save:
		selecionado = sel + 1     # v1.20: CONTINUAR empurra as outras opções uma linha


func aviso_menu(t: String) -> void:
	mensagem = t
	mensagem_tempo = 150


# v1.17: o MAPA escolheu a fase e a dificuldade: acha um slot livre (ou pede
# para sobrescrever) e começa
func comecar_pelo_mapa() -> void:
	var livre := slot_vazio_primeiro()
	if livre != -1:
		iniciar_jogo(livre)
	else:
		mudar_estado("slot_novo", 0)
		aviso_menu("Os 3 slots estão ocupados. Escolha qual sobrescrever.")


# Começa a partida no slot escolhido
func iniciar_jogo(slot: int) -> void:
	partida_resetar()
	G.nome_guerreiro = NOME_GUERREIRO
	G.save_slot_atual = slot
	G.capitulo = 1
	som("tit_start", 1, 0)
	instance_create_depth(0, 0, -10500, "obj_cutscene")
	V117.transicao_revelar(30)     # v1.19: o prólogo surge atrás da cortina em brasa


func valor_opcao(i: int) -> String:
	match opcoes_cfg[i]:
		"DESEMPENHO":
			if G.cfg_desempenho == Desempenho.AUTO:
				return "AUTOMÁTICO (" + Desempenho.nome(G.nivel_desempenho) + ")"
			return Desempenho.nome(G.cfg_desempenho)
		"QUALIDADE VISUAL":
			return config_nomes_qualidade()[G.cfg_qualidade]
		"TAXA DE QUADROS":
			return config_nomes_fps()[G.cfg_fps]
		"RESOLUÇÃO":
			return "REDUZIDA (720p)" if G.cfg_resolucao == 1 else "DA TELA"
		"VOLUME GERAL":
			return str(int(round(G.cfg_volume * 100))) + "%"
		"VOLUME DA MÚSICA":
			return str(int(round(G.cfg_vol_musica * 100))) + "%"
		"VOLUME DOS EFEITOS":
			return str(int(round(G.cfg_vol_efeitos * 100))) + "%"
		"FUNDO HD (FASE 1)":
			return "LIGADO" if G.cfg_fundo_hd else "DESLIGADO"
		"DICAS NO CARREGAMENTO":
			return "LIGADO" if G.cfg_tutorial else "DESLIGADO"
		"CÂMERA DE AÇÃO":
			return ["SUAVE", "NORMAL", "INTENSA"][G.cfg_camera_acao]
		"HUD DE TOQUE":
			return G.toque.MODO_NOMES[G.cfg_hud_modo] + "  ·  " + str(int(round(G.cfg_hud_tam * 100))) + "%  ·  PERSONALIZAR"
		"VIBRAÇÃO":
			return "LIGADA" if G.cfg_vibrar else "DESLIGADA"
		"TECLADO":
			return "PERSONALIZAR"
		"CONTROLE":
			return gamepad_descricao_conectado()
		"TESTE DE DESEMPENHO":
			return "INICIAR (~2 MIN)"
	return ""


func descricao_opcao(i: int) -> String:
	match opcoes_cfg[i]:
		"DESEMPENHO":
			return "AUTOMÁTICO escolhe pelo celular e se ajusta sozinho durante o jogo (desce se travar, sobe se sobrar folga). MÍNIMO e LEVE para aparelhos simples; MÁXIMO roda a 60 FPS."
		"QUALIDADE VISUAL":
			return "Quantidade de partículas, brilhos e tremor de câmera. Mexer aqui muda o desempenho para PERSONALIZADO."
		"TAXA DE QUADROS":
			return "30 ou 60 quadros por segundo. A velocidade do jogo é a mesma nos dois."
		"RESOLUÇÃO":
			return "REDUZIDA desenha o jogo em 720p e amplia para a tela: bem mais leve em celulares com tela grande."
		"VOLUME GERAL":
			return "Volume geral do jogo."
		"VOLUME DA MÚSICA":
			return "Volume das músicas (fase e chefe)."
		"VOLUME DOS EFEITOS":
			return "Volume dos efeitos: espada, golpes, trovões, chuva e fogo."
		"FUNDO HD (FASE 1)":
			return "Fundo da fase 1 em alta definição (imagem ampliada e suavizada). Se notar qualquer falha, desligue para voltar ao fundo original."
		"DICAS NO CARREGAMENTO":
			return "Dicas de combos e ataques passando embaixo da tela de carregamento das fases (v1.17: o carregamento leva 30 s)."
		"CÂMERA DE AÇÃO":
			return "A câmera fecha no duelo, acompanha o inimigo e dá um soco de zoom a cada pancada. INTENSA é a experiência de console; SUAVE para quem prefere a tela mais parada. Não pesa no desempenho."
		"HUD DE TOQUE":
			return "Monte os botões do seu jeito: 2 DEDOS (polegares), 4 DEDOS (garra) ou 8 DEDOS (um botão por golpe), tamanho, transparência e arraste cada botão para onde quiser."
		"VIBRAÇÃO":
			return "O celular vibra ao levar dano e nos impactos fortes."
		"TECLADO":
			return "Escolha as teclas de cada ação (teclado conectado)."
		"CONTROLE":
			return "Escolha os botões do controle (Xbox, PlayStation ou genérico). SELECT abre a pausa e START a tela de armas."
		"TESTE DE DESEMPENHO":
			return "Mede este celular no menu, na vila em chamas, no combate e na árvore, em cada nível (MÁXIMO a MÍNIMO), e recomenda o melhor. Roda sozinho por ~2 min; não mexe nos seus saves."
		"VOLTAR":
			return "Salva as configurações e volta ao menu."
	return ""


func alterar_opcao(i: int, passo: int) -> void:
	match opcoes_cfg[i]:
		"DESEMPENHO":
			# AUTOMÁTICO, MÍNIMO, LEVE, EQUILIBRADO, MÁXIMO (PERSONALIZADO só mexendo nas linhas de baixo)
			var atual := G.cfg_desempenho if G.cfg_desempenho != Desempenho.PERSONALIZADO else 0
			Desempenho.escolher((atual + passo + 5) % 5)
		"QUALIDADE VISUAL":
			G.cfg_qualidade = (G.cfg_qualidade + passo + 3) % 3
			Desempenho.personalizar()
		"TAXA DE QUADROS":
			G.cfg_fps = 1 - G.cfg_fps
			Desempenho.personalizar()
		"RESOLUÇÃO":
			G.cfg_resolucao = 1 - G.cfg_resolucao
			Desempenho.personalizar()
		"VOLUME GERAL":
			G.cfg_volume = clampf(G.cfg_volume + passo * 0.1, 0, 1)
		"VOLUME DA MÚSICA":
			G.cfg_vol_musica = clampf(G.cfg_vol_musica + passo * 0.1, 0, 1)
		"VOLUME DOS EFEITOS":
			G.cfg_vol_efeitos = clampf(G.cfg_vol_efeitos + passo * 0.1, 0, 1)
			som("tit_selecao", 0.8)
		"FUNDO HD (FASE 1)":
			G.cfg_fundo_hd = 1 - G.cfg_fundo_hd
		"DICAS NO CARREGAMENTO":
			G.cfg_tutorial = 1 - G.cfg_tutorial
		"CÂMERA DE AÇÃO":
			G.cfg_camera_acao = (G.cfg_camera_acao + passo + 3) % 3
		"VIBRAÇÃO":
			G.cfg_vibrar = 1 - G.cfg_vibrar
			G.vibrar(60)
		_:
			return
	if opcoes_cfg[i] != "VOLUME DOS EFEITOS":
		som("tit_alterar", 0.7, 0.03)
	config_aplicar()
	config_salvar()

# v1.14: menu épico: logo e opções numa coluna à esquerda (a cena fica à direita)
# (lista curta logo abaixo da logo, sobre a pincelada de sangue; o busto de Twilight à direita)
func menu_x() -> float:
	return maxf(70, G.gui_w * 0.075)


func menu_y(i: int) -> float:
	return 330 + i * 42.0


# área de toque / clique de cada opção do menu inicial
func menu_caixa(i: int) -> Rect2:
	return Rect2(menu_x() - 24, menu_y(i) - 19, 354, 38)


# pincelada de sangue + logo no alto, à esquerda (menu inicial e "pressione")
func _menu_cabecalho(a: float) -> void:
	var mx := menu_x()
	var mw := minf(G.gui_w * 0.6, 760)
	var f := gpu_get_texfilter()
	gpu_set_texfilter(true)
	if img_mancha != null:
		var me := mw / float(img_mancha.get_width())
		G.pen.textura(img_mancha, mx - 56, 34, img_mancha.get_width() * me, img_mancha.get_height() * me, c_white, 0.92 * a)
	gpu_set_texfilter(f)
	var lh := minf(232.0, G.gui_h * 0.32)
	var lx := mx + mw * 0.36
	var ly := 156 + sin(tempo_total / 90.0) * 2
	if G.logo_img != null:
		gpu_set_blendmode(bm_add)
		logo_desenhar(lx, ly, lh * 1.04, a * (0.08 + 0.05 * sin(tempo_total / 120.0)))
		gpu_set_blendmode(bm_normal)
		logo_desenhar(lx, ly, lh, a)
	else:
		txt_sombra(lx, ly, JOGO_TITULO, FONTE.GRANDE, Color8(240, 200, 120), a, fa_center, fa_middle, minf(1.1, (mw * 0.8) / maxf(1, txt_largura(JOGO_TITULO, FONTE.GRANDE))))


# =====================================================================
# v1.21 — EDITOR DA HUD DE TOQUE: modo (2 / 4 / 8 dedos), tamanho, opacidade e
# restaurar. Os botões aparecem na tela (touch_controls, modo "editor") e o
# jogador arrasta cada um para onde quiser.
# =====================================================================
const HUD_LINHAS := ["MODO", "TAMANHO", "OPACIDADE", "RESTAURAR POSIÇÕES"]


func hud_linha(i: int) -> Rect2:
	var w := minf(G.gui_w - 420, 460)
	return Rect2(G.gui_w / 2.0 - w / 2.0, 20 + i * 38.0, w, 32)


func _hud_valor(i: int) -> String:
	match i:
		0:
			return G.toque.MODO_NOMES[G.cfg_hud_modo]
		1:
			return str(int(round(G.cfg_hud_tam * 100))) + "%"
		2:
			return str(int(round(G.cfg_toque_opac * 100))) + "%"
	return ""


func _hud_alterar(i: int, passo: int) -> void:
	match i:
		0:
			G.cfg_hud_modo = (G.cfg_hud_modo + passo + 3) % 3
		1:
			G.cfg_hud_tam = clampf(snappedf(G.cfg_hud_tam + passo * 0.05, 0.05), 0.6, 1.6)
		2:
			G.cfg_toque_opac = clampf(snappedf(G.cfg_toque_opac + passo * 0.1, 0.05), 0.2, 1.0)
		3:
			G.toque.restaurar_posicoes()
			aviso_menu("Botões de volta ao lugar (" + G.toque.MODO_NOMES[G.cfg_hud_modo] + ").")
	som("tit_alterar", 0.7, 0.03)
	config_aplicar()
	config_salvar()


func _hud_passo(m: Vector2, clique: bool, cima: bool, baixo: bool, esq: bool, dir: bool, ok: bool, voltar: bool) -> void:
	if voltar:
		config_salvar()
		mudar_estado("opcoes", opcoes_cfg.find("HUD DE TOQUE"))
		return
	var n := HUD_LINHAS.size()
	if cima:
		hud_sel = (hud_sel + n - 1) % n
	if baixo:
		hud_sel = (hud_sel + 1) % n
	var passo := int(dir) - int(esq)
	if ok and passo == 0 and not clique:
		passo = 1
	# toque numa linha: metade esquerda diminui, metade direita aumenta (o editor
	# de arrastar tem prioridade: tocar num botão em cima da linha não altera nada)
	if clique and tempo > 6:
		passo = 0
		if not G.toque.arrastando:
			for i in n:
				var r := hud_linha(i)
				if r.has_point(m):
					hud_sel = i
					passo = -1 if (i < 3 and m.x < r.get_center().x) else 1
	if passo != 0:
		_hud_alterar(hud_sel, passo)


func _hud_desenhar(gw: float, gh: float, cx: float, ouro: Color, cinza: Color) -> void:
	for i in HUD_LINHAS.size():
		var r := hud_linha(i)
		desenhar_painel(r.position.x, r.position.y, r.end.x, r.end.y, 1.0 if hud_sel == i else 0.0, 1)
		if i == 3:
			txt(cx, r.get_center().y, HUD_LINHAS[i], FONTE.PEQUENA, ouro if hud_sel == i else c_white, 1, fa_center, fa_middle, 0.9)
			continue
		txt(r.position.x + 18, r.get_center().y, HUD_LINHAS[i], FONTE.PEQUENA, ouro if hud_sel == i else c_white, 1, fa_left, fa_middle, 0.9)
		txt(r.end.x - 18, r.get_center().y, "«  " + _hud_valor(i) + "  »", FONTE.PEQUENA, ouro, 1, fa_right, fa_middle, 0.9)
	var dica := "ARRASTE cada botão para onde quiser   ·   toque no « » para mudar" if G.usando_toque \
		else "Com o dedo na tela, arraste cada botão para onde quiser   ·   « » altera   ·   " + nome_voltar() + " volta"
	txt_sombra(cx, 20 + 4 * 38.0 + 14, dica, FONTE.MINI, Color8(232, 220, 200), 0.95, fa_center, fa_middle, minf(1, (gw - 60) / maxf(1, txt_largura(dica, FONTE.MINI))))
	var explica: String = ["2 DEDOS: jogue com os polegares. Direção + botão muda o golpe.",
		"4 DEDOS: garra. DEFESA e SUB-ARMA no alto à esquerda, MAGIA no alto à direita.",
		"8 DEDOS: um botão para cada golpe, rasteira e as três magias."][G.cfg_hud_modo]
	txt(cx, 20 + 4 * 38.0 + 40, explica, FONTE.MINI, cinza, 0.9, fa_center, fa_middle, minf(1, (gw * 0.36) / maxf(1, txt_largura(explica, FONTE.MINI))))


func cfg_y(i: int) -> float:
	return 132 + i * 29.0      # v1.19: 16 linhas (TESTE DE DESEMPENHO) sem bater na descrição


func dif_y(i: int) -> float:
	return 196 + i * 60.0


# Remapeamento em 2 colunas: [x do centro, y, largura]
func map_pos(i: int) -> Array:
	var gw := G.gui_w
	var cw := minf((gw - 100) / 2.0, 520)
	if i == ACAO.TOTAL:
		return [gw / 2.0 - 150, 570.0, 270.0]
	if i == ACAO.TOTAL + 1:
		return [gw / 2.0 + 150, 570.0, 270.0]
	var col := 0 if i < MAP_COL1 else 1
	var lin := i if i < MAP_COL1 else i - MAP_COL1
	var cx := (gw / 2.0 - cw / 2.0 - 10) if col == 0 else (gw / 2.0 + cw / 2.0 + 10)
	return [cx, 180 + lin * 46.0, cw]


func map_navegar(i: int, dx: int, dy: int) -> int:
	var n0 := MAP_COL1
	var n1: int = ACAO.TOTAL - MAP_COL1
	var r: int = ACAO.TOTAL
	var v: int = ACAO.TOTAL + 1
	if i == r:
		if dx != 0:
			return v
		return n0 - 1 if dy < 0 else 0
	if i == v:
		if dx != 0:
			return r
		return ACAO.TOTAL - 1 if dy < 0 else n0
	var col := 0 if i < n0 else 1
	var lin := i if i < n0 else i - n0
	var n := n0 if col == 0 else n1
	if dx != 0:
		return n0 + mini(lin, n1 - 1) if col == 0 else lin
	lin += dy
	if lin < 0 or lin >= n:
		return r if col == 0 else v
	return lin if col == 0 else n0 + lin


func _rodape_toque() -> bool:
	return G.usando_toque and not usando_controle()


# =====================================================================
# STEP
# =====================================================================
func ev_step() -> void:
	var dt := G.dt_real
	tempo += dt
	tempo_total += dt
	var gw := G.gui_w
	var gh := G.gui_h
	var cx := gw / 2.0
	# ----- efeitos (brasas, relâmpagos, sangue do título) -----
	var max_f := 25 if G.cfg_qualidade == 0 else (45 if G.cfg_qualidade == 1 else 75)
	if faiscas.size() < max_f and randf() < 0.4 * dt:
		faiscas.append({"x": randf_range(10, gw - 10), "y": gh + 4, "vx": randf_range(-0.35, 0.35), "vy": randf_range(-1.3, -0.35),
			"vida": float(randi_range(60, 170)), "vmax": 170.0, "r": randf_range(1.2, 2.6)})
	for fi in range(faiscas.size() - 1, -1, -1):
		var f: Dictionary = faiscas[fi]
		f.x += (f.vx + sin(current_time() / 500.0 + fi) * 0.12) * dt
		f.y += f.vy * dt
		f.vida -= dt
		if f.vida <= 0:
			faiscas.remove_at(fi)
	# cinzas caindo devagar, levadas pelo vento
	var max_c := 0 if G.cfg_qualidade == 0 else (30 if G.cfg_qualidade == 1 else 55)
	if cinzas.size() < max_c and randf() < 0.5 * dt:
		cinzas.append({"x": randf_range(-40, gw), "y": -6.0, "vx": randf_range(0.15, 0.55), "vy": randf_range(0.35, 0.9), "r": randf_range(0.8, 2.0), "s": randf() * 6.28})
	for ci in range(cinzas.size() - 1, -1, -1):
		var c: Dictionary = cinzas[ci]
		c.x += (c.vx + sin(tempo_total / 60.0 + c.s) * 0.25) * dt
		c.y += c.vy * dt
		if c.y > gh + 6:
			cinzas.remove_at(ci)
	if relampago > 0:
		relampago -= dt
	if estado != "intro_video":
		proximo_relampago -= dt
		if proximo_relampago <= 0:
			relampago = 26
			proximo_relampago = randi_range(420, 900)
	for gi in range(gotas.size() - 1, -1, -1):
		var g: Dictionary = gotas[gi]
		g.comp = minf(g.comp_max, g.comp + 0.35 * dt)
		if g.comp >= g.comp_max:
			g.queda += 2.2 * dt
		g.vida -= dt
		if g.vida <= 0:
			gotas.remove_at(gi)
	if mensagem_tempo > 0:
		mensagem_tempo -= dt
	if estado != "intro_video" and estado != "intro_titulo":
		menu_aparece += dt
	# ----- entradas (teclado, controle e toque/mouse) -----
	var bloq := instance_exists("obj_loading") or instance_exists("obj_cutscene") or instance_exists("obj_mapa") or instance_exists("obj_perfil")     # v1.17: mapa e perfil por cima
	var m := G.mouse_gui()
	var mexeu := mouse_antes.x != -1 and m != mouse_antes
	var clique := G.mouse_apertado
	var clique_dir := G.mouse_dir_apertado
	mouse_antes = m
	var cima := G.nav_cima
	var baixo := G.nav_baixo
	var esq := G.nav_esq
	var dir := G.nav_dir
	var ok := G.nav_ok
	var voltar := G.nav_voltar
	if bloq:
		cima = false
		baixo = false
		esq = false
		dir = false
		ok = false
		voltar = false
		clique = false
		clique_dir = false
		mexeu = false
	# v1.17: o fogo do menu reage ao dedo / ponteiro (faíscas no rastro, explosão no toque)
	if estado == "menu" or estado == "pressione" or estado == "opcoes":
		V117.menu_fogo_atualizar(self, m.x, m.y, mexeu, clique, dt)
	match estado:
		"intro_video":
			_video_ajustar()
			# sem pular: termina só quando o vídeo acaba (com uma folga de
			# segurança caso o aparelho não consiga tocá-lo)
			if (tempo > 30 and not video_player.is_playing()) or tempo > 60 * 26:
				video_terminar()
		"intro_aviso":
			if tempo >= aviso_total or (tempo > 60 and (ok or clique)):
				img_aviso = null
				estado = "intro_titulo"
				tempo = 0
		"intro_titulo":
			if tempo - dt < titulo_inicio and tempo >= titulo_inicio:
				som("tit_logo", 0.9, 0)
			if tempo > titulo_inicio + 60 and tempo < titulo_total - 60 and G.cfg_qualidade > 0 \
					and randf() < 0.07 * dt and gotas.size() < 16 and titulo_x2 > titulo_x1:
				gotas.append({"x": randf_range(titulo_x1 + 10, titulo_x2 - 10), "y": titulo_base, "comp": 0.0, "comp_max": randf_range(8, 26), "queda": 0.0, "vida": 170.0})
			if tempo >= titulo_total:
				G.intro_vista = true
				gotas = []
				mudar_estado("pressione", 0, false)
		# v1.14: "PRESSIONE QUALQUER BOTÃO" (depois da abertura)
		"pressione":
			if tempo > 30 and not bloq and (ok or voltar or clique or cima or baixo or esq or dir or Input.is_anything_pressed()):
				som("tit_start", 0.8, 0)
				mudar_estado("menu", 0, false)
				selecionado = 0     # v1.20: abre em CONTINUAR quando há progresso
				menu_aparece = 0
				G.io_clear()
		"menu":
			var n := opcoes_menu.size()
			if cima:
				selecionado = (selecionado + n - 1) % n
			if baixo:
				selecionado = (selecionado + 1) % n
			var escolheu := ok
			for i in n:
				if menu_caixa(i).has_point(m):
					if mexeu:
						selecionado = i
					if clique:
						selecionado = i
						escolheu = true
			if escolheu and tempo > 25:
				match str(opcoes_menu[selecionado]):
					"CONTINUAR":
						# v1.20: direto para o save mais recente do perfil
						var sr := slot_recente()
						if sr != -1 and carregar_slot(sr):
							som("tit_start", 0.9, 0)
							var lc = instance_create_depth(0, 0, -10000, "obj_loading")
							lc.modo = "carregar"
							lc.destino = G.checkpoint_room
						else:
							aviso_menu("Nenhum jogo salvo ainda.")
							som("tit_negado", 0.7, 0)
					"NOVO JOGO":
						# v1.17: na primeira vez, o PERFIL (o nome de quem joga, só para as
						# conquistas); depois o MAPA (fase e dificuldade)
						som("tit_selecao", 0.8, 0.02)
						if str(G.perfil.get("nome", "")) == "":
							var pf = instance_create_depth(0, 0, -10400, "obj_perfil")
							pf.modo = "primeiro"
						else:
							instance_create_depth(0, 0, -10400, "obj_mapa")
					"CARREGAR JOGO":
						if tem_save:
							var primeiro := 0
							for s0 in range(2, -1, -1):
								if slots[s0].existe:
									primeiro = s0
							mudar_estado("carregar", primeiro)
						else:
							aviso_menu("Nenhum jogo salvo ainda.")
							som("tit_negado", 0.7, 0)
					"CONQUISTAS":
						som("tit_selecao", 0.8, 0.02)
						instance_create_depth(0, 0, -10400, "obj_perfil")     # v1.17: CONQUISTAS
					"OPÇÕES":
						mudar_estado("opcoes", 0)
					"SAIR":
						G.get_tree().quit()
		"dificuldade":
			if voltar:
				mudar_estado("menu", 0)
				return
			if esq or dir:
				G.cfg_tutorial = 1 - G.cfg_tutorial
				config_salvar()
				som("tit_alterar", 0.7, 0.03)
			if cima:
				selecionado = (selecionado + DIF.TOTAL - 1) % DIF.TOTAL
			if baixo:
				selecionado = (selecionado + 1) % DIF.TOTAL
			var escolha := ok
			for d in DIF.TOTAL:
				var dy2 := dif_y(d)
				if point_in_rectangle(m.x, m.y, cx - 260, dy2 - 24, cx + 260, dy2 + 24):
					if mexeu:
						selecionado = d
					if clique:
						selecionado = d
						escolha = true
			# toque na linha do tutorial: liga / desliga
			if clique and point_in_rectangle(m.x, m.y, cx - 300, 610, cx + 300, 646):
				G.cfg_tutorial = 1 - G.cfg_tutorial
				config_salvar()
				som("tit_alterar", 0.7, 0.03)
			if escolha and tempo > 10:
				G.dificuldade = selecionado
				var livre := slot_vazio_primeiro()
				if livre != -1:
					iniciar_jogo(livre)
				else:
					mudar_estado("slot_novo", 0)
					aviso_menu("Os 3 slots estão ocupados. Escolha qual sobrescrever.")
		"carregar", "slot_novo":
			if voltar:
				if estado == "carregar":
					mudar_estado("menu", 1)
				else:
					mudar_estado("menu", 0)
					instance_create_depth(0, 0, -10400, "obj_mapa")     # v1.17: volta ao mapa
				return
			if esq or cima:
				selecionado = (selecionado + 2) % 3
				confirmar_slot = -1
			if dir or baixo:
				selecionado = (selecionado + 1) % 3
				confirmar_slot = -1
			var conf := ok
			var cw := minf(300, gw * 0.23)
			for s in 3:
				var sx := gw * (s + 1) / 4.0
				if point_in_rectangle(m.x, m.y, sx - cw / 2, 250, sx + cw / 2, 470):
					if mexeu and selecionado != s:
						selecionado = s
						confirmar_slot = -1
					if clique:
						selecionado = s
						conf = true
			if conf and tempo > 10:
				if estado == "carregar":
					if slots[selecionado].existe and carregar_slot(selecionado + 1):
						var l = instance_create_depth(0, 0, -10000, "obj_loading")
						l.modo = "carregar"
						l.destino = G.checkpoint_room
					else:
						aviso_menu("Este slot está vazio.")
						som("tit_negado", 0.7, 0)
				else:
					if slots[selecionado].existe and confirmar_slot != selecionado:
						confirmar_slot = selecionado
						aviso_menu("Confirme de novo para SOBRESCREVER o slot " + str(selecionado + 1) + ".")
					else:
						iniciar_jogo(selecionado + 1)
		"opcoes":
			var n2 := opcoes_cfg.size()
			if voltar:
				config_salvar()
				mudar_estado("menu", 3)
				return
			if cima:
				selecionado = (selecionado + n2 - 1) % n2
			if baixo:
				selecionado = (selecionado + 1) % n2
			var passo := int(dir) - int(esq)
			var ativar := ok
			var pw := minf(gw - 80, 860)
			for q in n2:
				var qy := cfg_y(q)
				if point_in_rectangle(m.x, m.y, cx - pw / 2, qy - 15, cx + pw / 2, qy + 15):
					if mexeu:
						selecionado = q
					if clique:
						selecionado = q
						if q <= CFG_ULTIMO_VALOR:
							# toque na metade do « (esquerda do valor) diminui; no resto aumenta
							passo = -1 if (m.x > cx and m.x < cx + pw / 2 - 110) else 1
						else:
							ativar = true
					if clique_dir:
						selecionado = q
						if q <= CFG_ULTIMO_VALOR:
							passo = -1
			if selecionado <= CFG_ULTIMO_VALOR:
				if passo != 0:
					alterar_opcao(selecionado, passo)
				elif ativar:
					alterar_opcao(selecionado, 1)
			elif ativar and tempo > 6:
				if opcoes_cfg[selecionado] == "HUD DE TOQUE":
					hud_sel = 0
					mudar_estado("hud", 0)      # v1.21: editor da HUD
				elif opcoes_cfg[selecionado] == "TECLADO":
					mudar_estado("teclado", 0)
				elif opcoes_cfg[selecionado] == "CONTROLE":
					mudar_estado("controle", 0)
				elif opcoes_cfg[selecionado] == "TESTE DE DESEMPENHO":
					# v1.19: TESTE DE DESEMPENHO (obj_benchmark)
					config_salvar()
					som("tit_selecao", 0.8, 0.02)
					if not instance_exists("obj_benchmark"):
						instance_create_depth(0, 0, -12000, "obj_benchmark")
				else:
					config_salvar()
					mudar_estado("menu", 3)
		"hud":
			_hud_passo(m, clique, cima, baixo, esq, dir, ok, voltar)
		"teclado", "controle":
			_remapear(m, mexeu, clique, cima, baixo, esq, dir, ok, voltar, dt)
	# som de "mover" quando a seleção muda na mesma tela
	if estado == som_estado and selecionado != som_sel and not bloq:
		som("tit_mover", 0.55, 0.03)
	som_estado = estado
	som_sel = selecionado
	for a in anim.size():
		anim[a] = lerp_dt(anim[a], 1.0 if a == selecionado else 0.0, 0.2)
	if estado == "menu" and selecionado != selecionado_antes and selecionado_antes != -1 and G.cfg_qualidade > 0:
		var oy2 := menu_y(selecionado)
		for i in 10:
			faiscas.append({"x": menu_x() + randf_range(-20, 320), "y": oy2 + randf_range(-10, 10), "vx": randf_range(-0.8, 0.8), "vy": randf_range(-1.6, -0.4),
				"vida": float(randi_range(25, 50)), "vmax": 50.0, "r": randf_range(1, 2.2)})
	selecionado_antes = selecionado


func _remapear(m: Vector2, mexeu: bool, clique: bool, cima: bool, baixo: bool, esq: bool, dir: bool, ok: bool, voltar: bool, dt: float) -> void:
	var modo_pad := estado == "controle"
	var total: int = ACAO.TOTAL + 2
	if not capturando:
		if voltar:
			config_validar_controles()
			config_salvar()
			mudar_estado("opcoes", CFG_ULTIMO_VALOR + (2 if modo_pad else 1))
			return
		if cima:
			selecionado = map_navegar(selecionado, 0, -1)
		if baixo:
			selecionado = map_navegar(selecionado, 0, 1)
		if esq or dir:
			selecionado = map_navegar(selecionado, int(dir) - int(esq), 0)
		var at := ok
		for r in total:
			var mp := map_pos(r)
			if point_in_rectangle(m.x, m.y, mp[0] - mp[2] / 2, mp[1] - 21, mp[0] + mp[2] / 2, mp[1] + 21):
				if mexeu:
					selecionado = r
				if clique:
					selecionado = r
					at = true
		if at and tempo > 6:
			if selecionado < ACAO.TOTAL:
				if modo_pad and G.pad_slot < 0:
					aviso_menu("Conecte um controle para remapear os botões.")
				else:
					capturando = true
					capture_wait = 10
					captura_solto = false
					mensagem = ""
			elif selecionado == ACAO.TOTAL:
				if modo_pad:
					G.botoes = botoes_padrao()
				else:
					G.teclas = teclas_padrao()
				config_salvar()
				aviso_menu("Controles restaurados para o padrão.")
			else:
				config_validar_controles()
				config_salvar()
				mudar_estado("opcoes", CFG_ULTIMO_VALOR + (2 if modo_pad else 1))
	elif selecionado < 0 or selecionado >= ACAO.TOTAL:
		capturando = false
	else:
		var acao_sel: int = acoes_tela[selecionado]
		var cancelar := G.keyboard_check_pressed(KEY_ESCAPE) or G.voltar_apertado or (G.pad_slot >= 0 and G.pad_botao_apertado(gp_start))
		if capture_wait > 0:
			capture_wait -= dt
		elif cancelar:
			capturando = false
			aviso_menu("Remapeamento cancelado.")
			som("tit_voltar", 0.7, 0)
		elif not modo_pad:
			if G.alguma_tecla:
				var k := G.ultima_tecla
				if tecla_reservada(k):
					aviso_menu(nome_tecla(k) + " é reservada do sistema. Escolha outra tecla.")
					som("tit_negado", 0.7, 0)
				else:
					var antiga: int = G.teclas[acao_sel]
					for j in ACAO.TOTAL:
						if j != acao_sel and G.teclas[j] == k:
							G.teclas[j] = antiga
							aviso_menu("Tecla trocada com " + acoes[j] + ".")
					G.teclas[acao_sel] = k
					capturando = false
					som("tit_selecao", 0.8, 0.02)
					config_salvar()
		else:
			if G.pad_slot < 0:
				capturando = false
				aviso_menu("Controle desconectado.")
			else:
				var novo := -1
				for b in botoes_remapeaveis():
					if pad_entrada(G.pad_slot, b):
						novo = b
						break
				if not captura_solto:
					if novo == -1:
						captura_solto = true
				elif novo != -1:
					var velho: int = G.botoes[acao_sel]
					for j2 in ACAO.TOTAL:
						if j2 != acao_sel and G.botoes[j2] == novo:
							G.botoes[j2] = velho
							aviso_menu("Botão trocado com " + acoes[j2] + ".")
					G.botoes[acao_sel] = novo
					capturando = false
					som("tit_selecao", 0.8, 0.02)
					config_salvar()
					G.io_clear()


# =====================================================================
# DRAW GUI
# =====================================================================
func ev_draw_gui() -> void:
	if instance_exists("obj_mapa") or instance_exists("obj_perfil"):
		return     # v1.17: o mapa / o perfil cobrem a tela
	var gw := G.gui_w
	var gh := G.gui_h
	var cx := gw / 2.0
	var ouro := Color8(255, 210, 90)
	var ouro2 := Color8(176, 141, 70)
	var cinza := Color8(175, 172, 178)
	var q := G.cfg_qualidade
	# ----- v1.14: CENA ÉPICA (a árvore gigante, o herói em silhueta, névoa e cinzas) -----
	var fundo_a := 1.0
	if estado == "intro_video" or estado == "intro_aviso":
		fundo_a = 0
	elif estado == "intro_titulo":
		fundo_a = clampf((tempo - (titulo_total - 45)) / 45.0, 0, 1)
	draw_set_alpha(1)
	draw_set_color(c_black)
	draw_rectangle(0, 0, gw, gh, false)
	if fundo_a > 0:
		_desenhar_cena(gw, gh, fundo_a)
	match estado:
		"intro_aviso":
			var av := clampf(minf(tempo / 40.0, (aviso_total - tempo) / 30.0), 0, 1)
			imagem_desenhar_ajustada(img_aviso, 0, 0, gw, gh, av)
		"intro_video":
			pass
		"intro_titulo":
			_desenhar_titulo(gw, gh, cx, ouro, ouro2, cinza)
		"pressione":
			_desenhar_pressione(gw, gh, cx)
		_:
			_desenhar_menus(gw, gh, cx, ouro, ouro2, cinza)
	# ----- brasas (em todas as telas) -----
	gpu_set_blendmode(bm_add)
	for f in faiscas:
		var fa := clampf(f.vida / f.vmax, 0, 1)
		draw_set_alpha(fa * 0.8)
		draw_set_color(Color8(230, int(70 + 80 * fa), 30))
		draw_circle(f.x, f.y, f.r, false)
		if q == 2:
			draw_set_alpha(fa * 0.2)
			draw_circle(f.x, f.y, f.r * 3, false)
	gpu_set_blendmode(bm_normal)
	desenho_resetar()


# v1.14: CENA ÉPICA ATRÁS DO MENU — a Árvore Amaldiçoada gigante no horizonte
# em chamas, Twilight em silhueta encarando-a, névoa, cinzas caindo e faixas
# pretas de cinema (a mesma da versão PC)
func _desenhar_cena(gw: float, gh: float, fundo_a: float) -> void:
	var q := G.cfg_qualidade
	# céu: o panorama antigo, bem escuro
	var sw := Spr.spr_fundo.w
	var sh := Spr.spr_fundo.h
	var esc := maxf(gw / sw, gh / sh) * 1.12
	var px := -(sw * esc - gw) * (0.5 + 0.5 * sin(tempo_total / 1400.0)) - paralaxe_x * 16     # v1.17: segue o dedo
	var py := -(sh * esc - gh) * 0.5 + sin(tempo_total / 900.0) * 4 - paralaxe_y * 8
	gpu_set_texfilter(true)
	draw_sprite_ext(Spr.spr_fundo, 0, px, py, esc, esc, 0, Color8(92, 70, 80), fundo_a)
	retangulo_gradiente(0, 0, gw, gh * 0.55, Color8(6, 4, 10), 0.75 * fundo_a, Color8(6, 4, 10), 0)
	# o horizonte em chamas
	var pul := 0.85 + 0.15 * sin(tempo_total / 70.0) * sin(tempo_total / 23.0)
	gpu_set_blendmode(bm_add)
	draw_set_color(Color8(190, 54, 18))
	draw_set_alpha(0.22 * pul * fundo_a)
	draw_ellipse(gw * 0.25, gh * 0.62, gw * 1.15, gh * 1.12, false)
	draw_set_color(Color8(255, 120, 40))
	draw_set_alpha(0.12 * pul * fundo_a)
	draw_ellipse(gw * 0.45, gh * 0.74, gw * 0.98, gh * 1.02, false)
	gpu_set_blendmode(bm_normal)
	# v1.14: a luz rompendo as nuvens atrás de Twilight (raios girando devagar)
	var lx := gw * 0.66
	var ly := gh * 0.40
	gpu_set_blendmode(bm_add)
	# camadas: o brilho cresce suave do centro para fora (sem borda de "oval")
	var camadas := [0.80, 0.56, 0.38, 0.24, 0.13]
	for ci2 in 5:
		var cr: float = gh * camadas[ci2]
		draw_set_color(merge_color(Color8(255, 196, 150), Color8(255, 244, 228), ci2 / 4.0))
		draw_set_alpha(0.045 * pul * fundo_a)
		draw_ellipse(lx - cr * 1.4, ly - cr, lx + cr * 1.4, ly + cr, false)
	if q > 0:
		draw_set_color(Color8(255, 220, 180))
		for ri in 9:
			var ra := tempo_total / 900.0 + ri * 0.698
			draw_set_alpha((0.035 + 0.02 * sin(tempo_total / 50.0 + ri * 2)) * fundo_a)
			draw_triangle(lx, ly, lx + cos(ra - 0.05) * gw, ly + sin(ra - 0.05) * gw, lx + cos(ra + 0.05) * gw, ly + sin(ra + 0.05) * gw, false)
	gpu_set_blendmode(bm_normal)
	# névoa passando
	if q > 0:
		gpu_set_blendmode(bm_add)
		draw_set_color(Color8(170, 130, 130))
		for n in 6:
			var fx := fmod(tempo_total * (0.18 + n * 0.06) + n * 380, gw + 800) - 400
			var fy := gh * (0.66 + 0.05 * n)
			draw_set_alpha(0.035 * fundo_a)
			draw_ellipse(fx - 380, fy - 50, fx + 380, fy + 50, false)
		gpu_set_blendmode(bm_normal)
	# o busto de Twilight à direita, olhando para o menu, recortado pela luz
	if img_retrato != null:
		var rh := gh * 0.98
		var re := rh / float(img_retrato.get_height())
		var rw := img_retrato.get_width() * re
		var rx := minf(gw - rw * 0.9, gw * 0.83 - rw / 2.0) + paralaxe_x * 12     # v1.17: paralaxe
		var ry := gh * 0.08 + sin(tempo_total / 80.0) * 2 + paralaxe_y * 5
		gpu_set_fog(true, Color8(255, 170, 110))
		G.pen.textura(img_retrato, rx - 6, ry, rw, rh, c_white, 0.55 * fundo_a)
		gpu_set_fog(false, c_white)
		G.pen.textura(img_retrato, rx, ry, rw, rh, Color8(178, 150, 150), fundo_a)
	else:
		var her := Spr.spr_player_idle
		var he := (gh * 0.34) * her.k / maxf(1.0, her.yo - her.bt)
		draw_sprite_hd(her, fmod(tempo_total / 10.0, float(her.n)), gw * 0.62, gh * 0.965, -he, he, 0, Color8(46, 30, 32), fundo_a)	# chão escuro, tom da maldição e vinheta
	retangulo_gradiente(0, gh * 0.82, gw, gh, c_black, 0, c_black, 0.92 * fundo_a)
	draw_set_alpha((0.10 + 0.04 * sin(tempo_total / 160.0)) * fundo_a)
	draw_set_color(Color8(110, 0, 10))
	draw_rectangle(0, 0, gw, gh, false)
	desenhar_vinheta(gw, gh, 0.9 * fundo_a)
	if relampago > 0:
		var ra := (26 - relampago) / 6.0 if relampago > 20 else relampago / 20.0
		draw_set_alpha(clampf(ra, 0, 1) * 0.3 * fundo_a)
		draw_set_color(Color8(255, 205, 205))
		draw_rectangle(0, 0, gw, gh, false)
	# cinzas caindo
	draw_set_color(Color8(150, 140, 140))
	draw_set_alpha(0.5 * fundo_a)
	for c in cinzas:
		draw_rectangle(c.x, c.y, c.x + c.r, c.y + c.r, false)
	# legibilidade: a coluna do menu escurece à esquerda; nas outras telas, tudo
	if estado == "menu":
		retangulo_gradiente_h(0, 0, gw * 0.5, gh, c_black, 0.6 * fundo_a, c_black, 0)
	elif estado != "intro_titulo" and estado != "pressione":
		draw_set_alpha(0.5 * fundo_a)
		draw_set_color(c_black)
		draw_rectangle(0, 0, gw, gh, false)
	# v1.17: braseiros, tochas ao lado da lista e as faíscas do dedo / ponteiro
	if estado == "menu" or estado == "pressione" or estado == "opcoes":
		V117.menu_fogo_desenhar(self, fundo_a * clampf(menu_aparece / 30.0, 0, 1), tempo_total, estado == "menu")
		desenho_resetar()
	# faixas pretas de cinema
	var barra := gh * 0.05 * fundo_a
	draw_set_alpha(1)
	draw_set_color(c_black)
	draw_rectangle(0, 0, gw, barra, false)
	draw_rectangle(0, gh - barra, gw, gh, false)


# v1.14: PRESSIONE QUALQUER BOTÃO (a logo grande sobre a cena)
func _desenhar_pressione(gw: float, gh: float, cx: float) -> void:
	var pe := clampf(tempo / 40.0, 0, 1)
	_menu_cabecalho(pe)
	var pa := (0.45 + 0.55 * (0.5 + 0.5 * sin(tempo_total / 22.0))) * pe
	var msg := "TOQUE NA TELA" if G.usando_toque else "PRESSIONE QUALQUER BOTÃO"
	txt_sombra(menu_x() + 6, menu_y(0) + 20, msg, FONTE.PEQUENA, Color8(214, 44, 34), pa, fa_left, fa_middle)
	txt(gw - 18, gh - 16, JOGO_VERSAO, FONTE.MINI, Color8(110, 105, 110), pe, fa_right, fa_middle)

# v1.14: a lista logo abaixo da logo, sobre a pincelada de sangue: a escolhida
# em pergaminho claro, as outras em vermelho-sangue
func _desenhar_menu_inicial(gw: float, gh: float, ma: float, cinza: Color, toque: bool) -> void:
	_menu_cabecalho(ma)
	var mx := menu_x()
	for o in opcoes_menu.size():
		var oy := menu_y(o)
		var e := clampf((menu_aparece - 14 - o * 6) / 22.0, 0, 1)
		var ease := 1 - pow(1 - e, 3)
		var a: float = anim[o]
		var x0 := mx + 6 - (1 - ease) * 40 + 8 * a
		var sem_save: bool = opcoes_menu[o] == "CARREGAR JOGO" and not tem_save
		if a > 0.02:
			# brilho quente atrás da escolhida
			gpu_set_blendmode(bm_add)
			draw_set_color(Color8(200, 60, 30))
			draw_set_alpha(0.16 * a * ease)
			draw_ellipse(x0 - 30, oy - 22, x0 + txt_largura(opcoes_menu[o], FONTE.MEDIA, 0.86) + 30, oy + 22, false)
			gpu_set_blendmode(bm_normal)
			draw_set_alpha(1)
			# v1.17: chamas pequenas lambendo a escolhida
			var wl := txt_largura(opcoes_menu[o], FONTE.MEDIA, 0.86)
			for fl in 5:
				desenhar_chamas(x0 + wl * (fl + 0.5) / 5.0, oy + 21, 5 * a, (8 + 4 * sin(tempo_total / 9.0 + fl)) * a, tempo_total + fl * 13, 0.75 * a * ease, fl, 2)
		var cor := merge_color(Color8(204, 38, 30), Color8(248, 234, 208), a)
		if sem_save:
			txt(x0, oy, opcoes_menu[o], FONTE.MEDIA, Color8(120, 40, 36), ease * 0.65, fa_left, fa_middle, 0.82)
		else:
			txt_sombra(x0, oy, opcoes_menu[o], FONTE.MEDIA, cor, ease, fa_left, fa_middle, 0.82 + 0.04 * a)
	# canto de baixo: o botão que seleciona (como nos menus de console)
	var by := gh - 58
	if toque:
		txt_sombra(mx + 6, by, "TOQUE NUMA OPÇÃO", FONTE.PEQUENA, Color8(232, 220, 200), ma * 0.95, fa_left, fa_middle, 0.8)
	else:
		draw_set_alpha(ma * 0.9)
		draw_set_color(Color8(70, 76, 100))
		draw_circle(mx + 8, by, 10, false)
		draw_set_color(Color8(200, 206, 230))
		draw_line_width(mx + 3, by - 5, mx + 13, by + 5, 2)
		draw_line_width(mx + 13, by - 5, mx + 3, by + 5, 2)
		draw_set_alpha(1)
		txt_sombra(mx + 26, by, "=  SELECIONAR   (" + nome_confirmar() + ")", FONTE.PEQUENA, Color8(232, 220, 200), ma * 0.95, fa_left, fa_middle, 0.8)
	txt(gw - 18, gh - 16, JOGO_VERSAO, FONTE.MINI, Color8(110, 105, 110), ma, fa_right, fa_middle)

func _desenhar_titulo(gw: float, gh: float, cx: float, ouro: Color, ouro2: Color, cinza: Color) -> void:
	var t := tempo
	var saida_t := clampf((titulo_total - t) / 45.0, 0, 1)
	var ent := clampf((t - 10) / 40.0, 0, 1)
	gpu_set_blendmode(bm_add)
	draw_set_alpha((0.18 + 0.08 * sin(current_time() / 260.0)) * ent * saida_t)
	draw_set_color(Color8(120, 0, 15))
	draw_ellipse(cx - gw * 0.48, gh * 0.40 - 160, cx + gw * 0.48, gh * 0.40 + 160, false)
	gpu_set_blendmode(bm_normal)
	var esc_t := minf(1, (gw * 0.92) / maxf(1, txt_largura(JOGO_TITULO, FONTE.TITULO)))
	var ty := gh * 0.40
	var trem := 2.5 if (t > titulo_inicio and t < sub_inicio) else 0.6
	var ox := randf_range(-trem, trem) * saida_t
	var sub_y := 0.0
	if G.logo_img != null:
		var lk := clampf((t - titulo_inicio) / 70.0, 0, 1)
		var le := 1 - pow(1 - lk, 3)
		var lh := minf(gh * 0.50, gw * 0.62) * (1.10 - 0.10 * le)
		ty = gh * 0.36
		logo_desenhar(cx + ox * (1 - le * 0.7), ty, lh, lk * saida_t)
		if lk > 0 and lk < 1:
			gpu_set_blendmode(bm_add)
			logo_desenhar(cx, ty, lh * (1 + 0.15 * (1 - lk)), (1 - lk) * 0.6 * saida_t)
			gpu_set_blendmode(bm_normal)
		titulo_x1 = cx - lh * 0.40
		titulo_x2 = cx + lh * 0.40
		titulo_base = ty - lh / 2 + lh * 0.655
		sub_y = ty + minf(gh * 0.50, gw * 0.62) / 2 + 30
	else:
		txt_amaldicoado(cx + ox, ty, JOGO_TITULO, FONTE.TITULO, Color8(225, 35, 35), t - titulo_inicio, titulo_intervalo, esc_t, saida_t)
		var tw := txt_largura(JOGO_TITULO, FONTE.TITULO, esc_t)
		titulo_x1 = cx - tw / 2
		titulo_x2 = cx + tw / 2
		titulo_base = ty + txt_altura("A", FONTE.TITULO, esc_t) * 0.30
		sub_y = ty + 88 * esc_t + 14
	for g in gotas:
		var ga := clampf(g.vida / 40.0, 0, 1) * saida_t
		draw_set_alpha(ga)
		draw_set_color(Color8(120, 6, 14))
		draw_line_width(g.x, g.y, g.x, g.y + g.comp, 2.5)
		draw_circle(g.x, g.y + g.comp + g.queda, 2.6, false)
	draw_set_alpha(1)
	var esc_s := minf(1, (gw * 0.8) / maxf(1, txt_largura(JOGO_SUBTITULO, FONTE.GRANDE)))
	txt_amaldicoado(cx, sub_y, JOGO_SUBTITULO, FONTE.GRANDE, ouro, t - sub_inicio, sub_intervalo, esc_s * 0.85, saida_t)
	var dv := maxf(gh * 0.70, sub_y + 42)
	var da := clampf((t - devs_inicio) / 40.0, 0, 1) * saida_t
	desenhar_divisor(cx, dv, 220, da)
	# os nomes da equipe passam nos créditos do fim da demo
	txt(cx, dv + gh * 0.045, "UM JOGO DA", FONTE.MINI, ouro2, da, fa_center, fa_middle)
	txt_sombra(cx, dv + gh * 0.095, "GAMBITECH STUDIO", FONTE.PEQUENA, c_white, da, fa_center, fa_middle)


func _desenhar_menus(gw: float, gh: float, cx: float, ouro: Color, ouro2: Color, cinza: Color) -> void:
	var ma := clampf(menu_aparece / 30.0, 0, 1)
	var toque := _rodape_toque()
	# ----- cabeçalho (o menu inicial desenha a logo na própria coluna) -----
	if estado == "menu":
		pass
	else:
		var cab := ""
		match estado:
			"dificuldade":
				cab = "DIFICULDADE"
			"carregar":
				cab = "CARREGAR JOGO"
			"slot_novo":
				cab = "ESCOLHA UM SLOT"
			"opcoes":
				cab = "OPÇÕES"
			"teclado":
				cab = "TECLADO"
			"controle":
				cab = "CONTROLE"
		txt(cx, 46, JOGO_TITULO + "  ·  " + JOGO_SUBTITULO, FONTE.MINI, Color8(200, 70, 60), ma * 0.9, fa_center, fa_middle)
		txt_sombra(cx, 96, cab, FONTE.GRANDE, ouro, ma, fa_center, fa_middle)
		desenhar_divisor(cx, 134, 260, ma)
	match estado:
		"menu":
			_desenhar_menu_inicial(gw, gh, ma, cinza, toque)
		"dificuldade":
			for d in DIF.TOTAL:
				var dy2 := dif_y(d)
				var ad: float = anim[d]
				desenhar_painel(cx - 260, dy2 - 24, cx + 260, dy2 + 24, ad, 1)
				var cd := dificuldade_cor(d)
				if d == DIF.EXTREMO:
					cd = merge_color(cd, c_white, 0.15 + 0.15 * sin(current_time() / 90.0))
				txt_sombra(cx, dy2, dificuldade_nome(d), FONTE.MEDIA, merge_color(c_white, cd, 0.55 + 0.45 * ad), 1, fa_center, fa_middle, 1 + 0.06 * ad)
				if ad > 0.05:
					draw_set_alpha(ad)
					desenhar_espada(cx - 260 - 62 + 22 * ad, dy2, 1)
					desenhar_espada(cx + 260 + 62 - 22 * ad, dy2, -1)
					draw_set_alpha(1)
			var pw4 := minf(gw - 100, 720)
			desenhar_painel(cx - pw4 / 2, 452, cx + pw4 / 2, 600, 0, 1)
			var desc := dificuldade_descricao(selecionado)
			txt(cx, 474, NOME_GUERREIRO.to_upper() + "  ·  " + dificuldade_nome(selecionado), FONTE.PEQUENA, dificuldade_cor(selecionado), 1, fa_center, fa_middle)
			for l2 in desc.size():
				txt(cx, 508 + l2 * 27, desc[l2], FONTE.MINI, c_white, 1, fa_center, fa_middle, minf(1, (pw4 - 30) / maxf(1, txt_largura(desc[l2], FONTE.MINI))))
			var tut_txt := "«  DICAS NO CARREGAMENTO: " + ("LIGADO" if G.cfg_tutorial else "DESLIGADO") + "  »"
			txt_sombra(cx, 628, tut_txt, FONTE.PEQUENA, ouro if G.cfg_tutorial else Color8(190, 150, 140), 1, fa_center, fa_middle)
			var aj := "Toque na dificuldade para começar a jornada   ·   toque nas dicas para ligar / desligar" if toque \
				else (nome_setas() + " escolhem   ·   « » dicas   ·   " + nome_confirmar() + " começa a jornada   ·   " + nome_voltar() + " volta")
			txt(cx, gh - 40, aj, FONTE.MINI, cinza, 1, fa_center, fa_middle, minf(1, (gw - 40) / maxf(1, txt_largura(aj, FONTE.MINI))))
		"carregar", "slot_novo":
			var cw := minf(300, gw * 0.23)
			for s in 3:
				var sx := gw * (s + 1) / 4.0
				var sel := 1.0 if selecionado == s else 0.0
				var info: Dictionary = slots[s]
				desenhar_painel(sx - cw / 2, 250, sx + cw / 2, 470, sel, 1)
				if estado == "slot_novo" and confirmar_slot == s:
					draw_set_color(Color8(255, 60, 50))
					draw_rectangle(sx - cw / 2 - 4, 246, sx + cw / 2 + 4, 474, true)
					draw_rectangle(sx - cw / 2 - 5, 245, sx + cw / 2 + 5, 475, true)
				txt(sx, 284, "SLOT " + str(s + 1), FONTE.MEDIA, ouro, 1, fa_center, fa_middle)
				if info.existe:
					# v1.20: o save é do PERFIL de quem joga (saves antigos mostram o herói)
					var dono: String = str(info.perfil if info.perfil != "" else info.nome).to_upper()
					txt(sx, 324, dono, FONTE.PEQUENA, c_white, 1, fa_center, fa_middle, minf(1, (cw - 24) / maxf(1, txt_largura(dono, FONTE.PEQUENA))))
					txt(sx, 350, dificuldade_nome(info.dificuldade), FONTE.MINI, dificuldade_cor(info.dificuldade), 1, fa_center, fa_middle)
					txt(sx, 378, "CAPÍTULO " + str(info.fase), FONTE.MINI, ouro2, 1, fa_center, fa_middle)
					txt_bloco(sx, 392, fase_nome(info.fase), FONTE.MINI, Color8(220, 215, 210), 1, cw - 24)
					if info.data != "":
						txt(sx, 452, str(info.data) + "  ·  " + tempo_jogo_texto(info.tempo), FONTE.MINI, Color8(140, 140, 145), 1, fa_center, fa_middle, 0.85)
				else:
					txt(sx, 370, "VAZIO", FONTE.PEQUENA, Color8(140, 140, 145), 1, fa_center, fa_middle)
				if estado == "slot_novo" and confirmar_slot == s:
					txt(sx, 500, "SOBRESCREVER?", FONTE.PEQUENA, Color8(255, 90, 70), 0.7 + 0.3 * sin(current_time() / 90.0), fa_center, fa_middle)
			var aj2 := "Toque num slot para confirmar" if toque else ("« » escolhe o slot   ·   " + nome_confirmar() + " confirma   ·   " + nome_voltar() + " volta")
			txt(cx, gh - 44, aj2, FONTE.MINI, cinza, 1, fa_center, fa_middle)
		"opcoes":
			var pw2 := minf(gw - 80, 860)
			for r in opcoes_cfg.size():
				var ry := cfg_y(r)
				var ar: float = anim[r]
				desenhar_painel(cx - pw2 / 2, ry - 15, cx + pw2 / 2, ry + 15, ar, 1)
				if r == opcoes_cfg.size() - 1:
					txt(cx, ry, opcoes_cfg[r], FONTE.PEQUENA, merge_color(c_white, ouro, ar), 1, fa_center, fa_middle)
					continue
				txt(cx - pw2 / 2 + 24, ry, opcoes_cfg[r], FONTE.PEQUENA, merge_color(c_white, ouro, ar), 1, fa_left, fa_middle)
				var val := valor_opcao(r)
				if r <= CFG_ULTIMO_VALOR:
					val = "«  " + val + "  »"
				var vx := cx + pw2 / 2 - 24
				if opcoes_cfg[r].begins_with("VOLUME"):
					var vol := G.cfg_volume if r == 4 else (G.cfg_vol_musica if r == 5 else G.cfg_vol_efeitos)
					var bx2 := vx - 120
					draw_set_color(Color8(40, 34, 30))
					draw_rectangle(bx2 - 140, ry - 4, bx2 - 20, ry + 4, false)
					draw_set_color(ouro)
					draw_rectangle(bx2 - 140, ry - 4, bx2 - 140 + 120 * vol, ry + 4, false)
				txt(vx, ry, val, FONTE.PEQUENA, ouro, 1, fa_right, fa_middle, minf(1, (pw2 * 0.5) / maxf(1, txt_largura(val, FONTE.PEQUENA))))
			txt_bloco(cx, gh - 104, descricao_opcao(selecionado), FONTE.MINI, Color8(215, 210, 205), 1, pw2)
			var aj3 := "Toque no « para diminuir e no » para aumentar   ·   VOLTAR volta" if toque \
				else (nome_setas() + " escolhem   ·   « » altera   ·   " + nome_voltar() + " volta")
			txt(cx, gh - 34, aj3, FONTE.MINI, cinza, 1, fa_center, fa_middle)
		"hud":
			_hud_desenhar(gw, gh, cx, ouro, cinza)
		"teclado", "controle":
			_desenhar_remap(gw, gh, cx, ouro, ouro2, cinza)
	if mensagem_tempo > 0 and mensagem != "":
		var ma2 := clampf(mensagem_tempo / 20.0, 0, 1)
		var mw := minf(gw - 40, txt_largura(mensagem, FONTE.PEQUENA) + 60)
		draw_set_alpha(0.95 * ma2)
		draw_set_color(Color8(34, 8, 8))
		draw_rectangle(cx - mw / 2, gh - 60, cx + mw / 2, gh - 16, false)
		draw_set_color(Color8(150, 50, 40))
		draw_rectangle(cx - mw / 2, gh - 60, cx + mw / 2, gh - 16, true)
		draw_set_alpha(1)
		txt(cx, gh - 38, mensagem, FONTE.PEQUENA, Color8(255, 180, 150), ma2, fa_center, fa_middle, minf(1, (gw - 80) / maxf(1, txt_largura(mensagem, FONTE.PEQUENA))))


func _desenhar_remap(gw: float, gh: float, cx: float, ouro: Color, ouro2: Color, cinza: Color) -> void:
	var modo_pad := estado == "controle"
	var mp0 := map_pos(0)
	var mp7 := map_pos(MAP_COL1)
	txt(mp0[0], 146, "MOVIMENTO", FONTE.MINI, ouro2, 1, fa_center, fa_middle)
	txt(mp7[0], 146, "COMBATE", FONTE.MINI, ouro2, 1, fa_center, fa_middle)
	for l in ACAO.TOTAL + 2:
		var mp := map_pos(l)
		var lx1: float = mp[0] - mp[2] / 2
		var lx2: float = mp[0] + mp[2] / 2
		var ly: float = mp[1]
		var al: float = anim[l]
		desenhar_painel(lx1, ly - 21, lx2, ly + 21, al, 1)
		if l == ACAO.TOTAL:
			txt(mp[0], ly, "RESTAURAR PADRÃO", FONTE.PEQUENA, merge_color(Color8(230, 150, 130), ouro, al), 1, fa_center, fa_middle)
			continue
		if l == ACAO.TOTAL + 1:
			txt(mp[0], ly, "VOLTAR", FONTE.PEQUENA, merge_color(c_white, ouro, al), 1, fa_center, fa_middle)
			continue
		var ac: int = acoes_tela[l]
		var wv := 0.0
		if capturando and selecionado == l:
			var pisca := 0.55 + 0.45 * sin(current_time() / 90.0)
			var msg := "APERTE UM BOTÃO..." if modo_pad else "APERTE UMA TECLA..."
			wv = txt_largura(msg, FONTE.MINI)
			txt(lx2 - 16, ly, msg, FONTE.MINI, Color8(255, 120, 90), pisca, fa_right, fa_middle)
		elif modo_pad:
			var bt: int = G.botoes[ac]
			var nm := nome_pad(bt)
			var wn := txt_largura(nm, FONTE.MINI)
			txt(lx2 - 16, ly, nm, FONTE.MINI, ouro, 1, fa_right, fa_middle)
			var ix0 := lx2 - 16 - wn - 8
			var wic := icone_pad_largura(bt, 26)
			desenhar_icone_pad(ix0 - wic, ly, bt, 26, 1)
			wv = wn + 8 + wic
		else:
			var nk := nome_tecla(G.teclas[ac])
			wv = desenhar_tecla_largura(nk, 26)
			desenhar_tecla(lx2 - 16 - wv, ly, nk, 26, 1)
		var nome_a: String = acoes[ac]
		var esc_a := minf(1, (mp[2] - 40 - wv) / maxf(1, txt_largura(nome_a, FONTE.PEQUENA)))
		txt(lx1 + 16, ly, nome_a, FONTE.PEQUENA, merge_color(c_white, ouro, al), 1, fa_left, fa_middle, esc_a)
	if modo_pad:
		var info := "CONTROLE: " + gamepad_descricao_conectado()
		txt(cx, 622, info, FONTE.MINI, Color8(150, 210, 140) if G.pad_slot >= 0 else Color8(230, 140, 120), 1, fa_center, fa_middle, minf(1, (gw - 60) / maxf(1, txt_largura(info, FONTE.MINI))))
	else:
		var s := "As setas também funcionam para correr, pular e agachar, se não estiverem em uso."
		txt(cx, 622, s, FONTE.MINI, Color8(190, 185, 180), 1, fa_center, fa_middle, minf(1, (gw - 60) / maxf(1, txt_largura(s, FONTE.MINI))))
	var rod := ("Aperte o novo botão (ou gatilho / direcional)   ·   START cancela" if modo_pad else "Aperte a nova tecla   ·   ESC cancela") if capturando \
		else (nome_setas() + " escolhem   ·   " + nome_confirmar() + " altera   ·   " + nome_voltar() + " volta")
	txt(cx, gh - 34, rod, FONTE.MINI, cinza, 1, fa_center, fa_middle)
