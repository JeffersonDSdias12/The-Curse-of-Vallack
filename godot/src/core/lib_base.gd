class_name LibBase
extends GMObj
# =====================================================================
#  THE CURSE OF VALLACK  ·  A MALDIÇÃO DE VALLACK
#  Funções globais (scripts do GameMaker), parte 1:
#  scr_globais, scr_input, scr_audio, scr_menu e scr_camera
# =====================================================================

const JOGO_TITULO := "THE CURSE OF VALLACK"
const JOGO_SUBTITULO := "A MALDIÇÃO DE VALLACK"
const JOGO_VERSAO := "BETA 0.5"
const CAMERA_ALTURA := 280.0     # v1.13: 420 -> 280, a câmera bem mais perto do herói
const GUI_ALTURA := 720.0
const ESPECIAL_SEGUNDOS := 10.0
const FASE_TOTAL := 2
const DEMO_FIM_NA_FASE_1 := true
const NOME_GUERREIRO := "Twilight Vetrus"
const NOME_CURTO := "Twilight"
const ESSENCIA_MAX := 9
const ESSENCIA_INICIO := 3
const ESPADA_NIVEL_MAX := 5
const MAP_COL1 := 7
const PAUSA_MUSICA := 1
const PAUSA_EFEITOS := 2
const CONTROLES_VERSAO := 5


# =====================================================================
# scr_globais
# =====================================================================
func globais_iniciar() -> void:
	if G.globais_ok:
		return
	G.globais_ok = true
	G.nome_guerreiro = NOME_GUERREIRO
	G.dificuldade = DIF.MEDIO
	G.save_slot_atual = 1
	G.capitulo = 1
	G.checkpoint_ativo = false
	G.checkpoint_room = ""
	G.checkpoint_x = 0
	G.checkpoint_y = 0
	G.vida_carregada = -1
	G.transicao_fase = false
	G.jogo_finalizado = false
	G.intro_vista = false
	G.ultima_vida = 100
	G.combo = 0
	G.combo_tempo = 0
	G.attacks_total = 0
	G.hits_total = 0
	G.inimigos_derrotados = 0
	G.orbs = 0
	G.orbs_coletados = 0
	G.espada_nivel = 1
	G.tempo_jogo = 0
	G.abertos = []
	G.marca = {"orbs": 0, "coletados": 0, "derrotados": 0, "nivel": 1}
	G.hitstop = 0
	G.lenta_t = 0
	G.lenta_fator = 1
	G.dt_real = 1
	G.dt = 1
	G.teclas = teclas_padrao()
	G.botoes = botoes_padrao()
	G.inp_segurado = []
	G.inp_apertado = []
	G.inp_pad_apertado = []
	for i in ACAO.TOTAL:
		G.inp_segurado.append(false)
		G.inp_apertado.append(false)
		G.inp_pad_apertado.append(false)
	G.essencia = ESSENCIA_INICIO
	G.essencia_coletada = 0
	G.usando_toque = OS.has_feature("mobile")
	input_nav_iniciar()


# Zera tudo o que pertence a uma partida (novo jogo / fim de jogo).
func partida_resetar() -> void:
	G.nome_guerreiro = NOME_GUERREIRO
	G.capitulo = 1
	G.checkpoint_ativo = false
	G.checkpoint_room = ""
	G.checkpoint_x = 0
	G.checkpoint_y = 0
	G.vida_carregada = -1
	G.transicao_fase = false
	G.jogo_finalizado = false
	G.combo = 0
	G.combo_tempo = 0
	G.attacks_total = 0
	G.hits_total = 0
	G.last_hit_flash = 0
	G.camera_impact = 0
	G.camera_zoom = 1
	G.terremoto = 0
	G.inimigos_derrotados = 0
	G.orbs = 0
	G.orbs_coletados = 0
	G.espada_nivel = 1
	G.tempo_jogo = 0
	G.abertos = []
	G.marca = {"orbs": 0, "coletados": 0, "derrotados": 0, "nivel": 1, "essencia": ESSENCIA_INICIO}
	G.essencia = ESSENCIA_INICIO
	G.essencia_coletada = 0
	G.essencia_fx = 0
	G.hitstop = 0
	G.lenta_t = 0
	G.lenta_fator = 1


# Pausar / retomar o mundo (o controlador do sistema nunca é congelado)
func mundo_pausar() -> void:
	G.desativar_todos(self)


func mundo_retomar() -> void:
	G.ativar_todos()


# ----- Fases -----
static func fase_numero(r: String) -> int:
	if r == "Room1":
		return 1
	if r == "Room2":
		return 2
	return 0


static func fase_room(n: int) -> String:
	return "Room2" if n >= 2 else "Room1"


static func fase_nome(n: int) -> String:
	if n >= 2:
		return "O SALÃO REAL EM RUÍNAS"
	return "A CAMINHO DO CASTELO"


static func fase_sub(n: int) -> String:
	if n >= 2:
		return "No coração do castelo, a maldição aguarda. Derrote todos os inimigos."
	return "A estrada até as muralhas de Vallack está tomada por bestas amaldiçoadas."


static func fase_objetivo(n: int) -> String:
	if n >= 2:
		return "Derrote todos os inimigos do salão"
	return "Siga para o leste até o castelo  »"


# ----- Saves (3 slots) -----
static func slot_arquivo(s: int) -> String:
	return "save_slot" + str(clampi(s, 1, 3)) + ".ini"


static func slot_existe(s: int) -> bool:
	return G.arquivo_existe(slot_arquivo(s))


static func slot_vazio_primeiro() -> int:
	for i in range(1, 4):
		if not slot_existe(i):
			return i
	return -1


static func slot_info(s: int) -> Dictionary:
	var info := {"existe": false, "nome": NOME_GUERREIRO, "fase": 1, "data": "", "vida": 100, "dificuldade": DIF.MEDIO, "nivel": 1, "orbs": 0, "perfil": "", "tempo": 0.0}
	if not slot_existe(s):
		return info
	var c := G.ini_abrir(slot_arquivo(s))
	info.existe = true
	var sala: String = str(c.get_value("jogo", "sala", "Room1"))
	info.fase = clampi(int(round(float(c.get_value("jogo", "fase", maxi(1, fase_numero(sala)))))), 1, FASE_TOTAL)
	info.data = str(c.get_value("jogo", "data", ""))
	info.vida = float(c.get_value("jogo", "vida", 100))
	info.dificuldade = clampi(int(round(float(c.get_value("jogo", "dificuldade", DIF.MEDIO)))), 0, DIF.TOTAL - 1)
	info.nivel = clampi(int(round(float(c.get_value("jogo", "espada_nivel", 1)))), 1, ESPADA_NIVEL_MAX)
	info.orbs = float(c.get_value("jogo", "orbs", 0))
	info.nome = NOME_GUERREIRO
	info.perfil = str(c.get_value("jogo", "perfil", ""))     # v1.20: de quem é o progresso
	info.tempo = float(c.get_value("jogo", "tempo", 0))
	return info


# v1.20: o save mais recente do perfil (o do CONTINUAR); -1 se não há nenhum
static func slot_recente() -> int:
	if G.perfil.is_empty():
		V117.perfil_carregar()
	var u := int(G.perfil.get("ultimo_slot", 0))
	if u >= 1 and u <= 3 and slot_existe(u):
		return u
	for i in range(1, 4):
		if slot_existe(i):
			return i
	return -1


# tempo de jogo de um save, em texto (ex.: 1h 05min)
static func tempo_jogo_texto(segundos: float) -> String:
	var seg := int(segundos)
	var h := seg / 3600
	var m := (seg % 3600) / 60
	return ("%dh %02dmin" % [h, m]) if h > 0 else ("%d min" % m)


func salvar_slot(s: int, mostrar := true) -> bool:
	s = clampi(s, 1, 3)
	# v1.20: o perfil guarda qual é o seu save mais recente e até onde já chegou
	if G.perfil.is_empty():
		V117.perfil_carregar()
	if fase_numero(G.room) > 0:
		G.perfil.ultimo_slot = s
		G.perfil.fase_max = maxi(int(G.perfil.get("fase_max", 1)), fase_numero(G.room))
		G.perfil.sujo = true
	V117.perfil_salvar_se_mudou()      # v1.17: os números do perfil vão junto
	# O jogador grava sua posição em G.ultimo_x/y todo quadro. Assim o save
	# funciona mesmo com o jogo pausado (jogador desativado).
	var px := G.ultimo_x
	var py := G.ultimo_y
	var pv := G.ultima_vida
	var p = instance_find("obj_player", 0)
	if p != null:
		px = p.x
		py = p.y
		pv = p.vida
	var fase := fase_numero(G.room)
	if fase <= 0:
		return false
	G.save_slot_atual = s
	var c := ConfigFile.new()
	c.set_value("jogo", "nome", G.nome_guerreiro)
	c.set_value("jogo", "perfil", V117.perfil_nome_exibir())
	c.set_value("jogo", "sala", G.room)
	c.set_value("jogo", "fase", fase)
	c.set_value("jogo", "dificuldade", G.dificuldade)
	c.set_value("jogo", "x", px)
	c.set_value("jogo", "y", py)
	c.set_value("jogo", "vida", maxf(1, pv))
	c.set_value("jogo", "orbs", G.orbs)
	c.set_value("jogo", "orbs_coletados", G.orbs_coletados)
	c.set_value("jogo", "espada_nivel", G.espada_nivel)
	c.set_value("jogo", "tempo", G.tempo_jogo)
	c.set_value("jogo", "derrotados", G.inimigos_derrotados)
	c.set_value("jogo", "essencia", G.essencia)
	c.set_value("jogo", "abertos", abertos_texto())
	c.set_value("jogo", "data", data_hora_texto())
	G.ini_salvar(c, slot_arquivo(s))
	G.checkpoint_ativo = true
	G.checkpoint_room = G.room
	G.checkpoint_x = px
	G.checkpoint_y = py
	progresso_marcar()
	if mostrar:
		aviso_mostrar("JOGO SALVO  ·  SLOT " + str(s), false)
	return true


func carregar_slot(s: int) -> bool:
	s = clampi(s, 1, 3)
	if not slot_existe(s):
		return false
	partida_resetar()
	var c := G.ini_abrir(slot_arquivo(s))
	G.nome_guerreiro = NOME_GUERREIRO
	G.dificuldade = clampi(int(round(float(c.get_value("jogo", "dificuldade", DIF.MEDIO)))), 0, DIF.TOTAL - 1)
	var sala: String = str(c.get_value("jogo", "sala", "Room1"))
	if fase_numero(sala) == 0:
		sala = fase_room(int(c.get_value("jogo", "fase", 1)))
	G.checkpoint_room = sala
	G.checkpoint_x = float(c.get_value("jogo", "x", 80))
	G.checkpoint_y = float(c.get_value("jogo", "y", 640))
	G.vida_carregada = float(c.get_value("jogo", "vida", 100))
	G.orbs = float(c.get_value("jogo", "orbs", 0))
	G.orbs_coletados = float(c.get_value("jogo", "orbs_coletados", 0))
	G.espada_nivel = clampi(int(round(float(c.get_value("jogo", "espada_nivel", 1)))), 1, ESPADA_NIVEL_MAX)
	G.tempo_jogo = float(c.get_value("jogo", "tempo", 0))
	G.inimigos_derrotados = int(c.get_value("jogo", "derrotados", 0))
	G.essencia = clampi(int(round(float(c.get_value("jogo", "essencia", ESSENCIA_INICIO)))), 0, ESSENCIA_MAX)
	G.abertos = abertos_de_texto(str(c.get_value("jogo", "abertos", "")))
	progresso_marcar()
	G.capitulo = fase_numero(sala)
	G.save_slot_atual = s
	G.checkpoint_ativo = true
	return true


static func data_hora_texto() -> String:
	var d := Time.get_datetime_dict_from_system()
	return "%02d/%02d/%04d %02d:%02d" % [d.day, d.month, d.year, d.hour, d.minute]


# v1.16: o aviso toca o som da MENSAGEM IMPORTANTE (sfx_important_message);
# avisos de sistema (jogo salvo, checkpoint, controle, desempenho) passam com_som = false
func aviso_mostrar(texto: String, com_som := true) -> void:
	for a in todos("obj_aviso"):
		instance_destroy(a)
	var av = instance_create_depth(0, 0, -10001, "obj_aviso")
	av.texto = texto
	if com_som:
		som_mensagem()


# ----- Níveis de dificuldade -----
static func dif_valor(lista: Array):
	return lista[clampi(G.dificuldade, 0, DIF.TOTAL - 1)]


static func dificuldade_nome(d := -1) -> String:
	if d < 0:
		d = G.dificuldade
	return ["FÁCIL", "MÉDIO", "DIFÍCIL", "EXTREMO"][clampi(d, 0, DIF.TOTAL - 1)]


static func dificuldade_cor(d := -1) -> Color:
	if d < 0:
		d = G.dificuldade
	return [Color8(120, 220, 110), Color8(255, 210, 90), Color8(255, 140, 50), Color8(235, 40, 40)][clampi(d, 0, DIF.TOTAL - 1)]


static func dificuldade_descricao(d: int) -> Array:
	match d:
		DIF.FACIL:
			return ["Inimigos fracos, lentos e só com o golpe básico.", "Só 1 inimigo ataca de cada vez.", "Chefes com menos vida."]
		DIF.MEDIO:
			return ["A experiência equilibrada: saltos, teias e ondas.", "Até 2 inimigos atacam ao mesmo tempo.", "A vida volta nos baús e nos cristais dourados."]
		DIF.DIFICIL:
			return ["Inimigos rápidos, resistentes e com golpes novos.", "O porco invoca esqueletos; arqueiros atiram 2 flechas.", "Até 3 atacam juntos; a guarda quebra mais."]
	return ["Inimigos implacáveis: dano e vida dobrados.", "Arqueiros atiram 3 flechas; até 4 atacam juntos.", "O cristal dourado não cura: só os baús de vida."]


# v1.13: níveis BEM SEPARADOS e combate mais intenso (a mesma tabela da versão
# PC, scr_globais). Cada nível muda a vida, o dano, a espera entre golpes, a
# velocidade, quantos atacam juntos e QUAIS golpes cada inimigo usa
# (dif_golpe_liberado). O nível do inimigo no mapa (Nv 1-5) sobe mais forte nas
# dificuldades altas: a fase 2 aperta mais.        FÁCIL  MÉDIO  DIFÍCIL EXTREMO
static func dif_dano_inimigo() -> float:
	return dif_valor([0.5, 0.85, 1.25, 1.7])

static func dif_vida_inimigo() -> float:
	return dif_valor([0.65, 1.0, 1.4, 1.9])

static func dif_vida_boss() -> float:
	return dif_valor([0.7, 1.0, 1.35, 1.8])

static func dif_recarga_inimigo() -> float:
	return dif_valor([1.5, 1.0, 0.78, 0.6])

static func dif_atordoamento() -> float:
	return dif_valor([1.3, 1.0, 0.8, 0.6])

static func dif_atacantes_max() -> int:
	return dif_valor([1, 2, 3, 4])

static func dif_velocidade() -> float:
	return dif_valor([0.88, 1.0, 1.1, 1.2])

static func dif_nivel_vida() -> float:
	return dif_valor([0.08, 0.15, 0.22, 0.3])

static func dif_nivel_dano() -> float:
	return dif_valor([0.05, 0.10, 0.15, 0.2])

static func dif_cristal_cura() -> bool:
	return G.dificuldade != DIF.EXTREMO

static func dif_boss_recarga() -> float:
	return dif_valor([150, 100, 75, 55])

static func dif_quebra_guarda() -> int:
	return dif_valor([6, 4, 3, 2])

# golpes especiais dos inimigos: liberados a partir de um nível (DIF.FACIL = sempre)
static func dif_golpe_liberado(nivel: int) -> bool:
	return G.dificuldade >= nivel

# ----- Utilidades -----
# lerp independente da taxa de quadros
static func lerp_dt(a: float, b: float, k: float) -> float:
	return lerpf(a, b, 1.0 - pow(1.0 - clampf(k, 0.0, 1.0), G.dt))


static func array_tem(arr: Array, v) -> bool:
	return arr.has(v)


# ----- Baús abertos, paredes quebradas e segredos (gravados no save) -----
static func aberto_chave(tipo: String, px: float, py: float) -> String:
	return G.room + ":" + tipo + ":" + str(int(round(px))) + ":" + str(int(round(py)))

static func aberto_tem(chave: String) -> bool:
	return G.abertos.has(chave)

static func aberto_marcar(chave: String) -> void:
	if not aberto_tem(chave):
		G.abertos.append(chave)

static func abertos_texto() -> String:
	return "|".join(G.abertos)

static func abertos_de_texto(s: String) -> Array:
	var r := []
	if s == "":
		return r
	for p in s.split("|"):
		if p != "":
			r.append(p)
	return r


# Progresso guardado no checkpoint: ao morrer, orbs e contadores voltam a ele
static func progresso_marcar() -> void:
	G.marca = {"orbs": G.orbs, "coletados": G.orbs_coletados, "derrotados": G.inimigos_derrotados, "nivel": G.espada_nivel, "essencia": G.essencia}

static func progresso_reverter() -> void:
	G.orbs = G.marca.get("orbs", 0)
	G.orbs_coletados = G.marca.get("coletados", 0)
	G.inimigos_derrotados = G.marca.get("derrotados", 0)
	G.espada_nivel = maxi(G.espada_nivel, G.marca.get("nivel", 1))
	if G.marca.has("essencia"):
		G.essencia = G.marca["essencia"]


# Pausa curtinha (impacto) e câmera lenta
static func impacto(quadros: float) -> void:
	G.hitstop = maxf(G.hitstop, quadros)

static func camera_lenta(quadros: float, fator: float) -> void:
	G.lenta_t = maxf(G.lenta_t, quadros)
	G.lenta_fator = minf(G.lenta_fator, fator)


# PESO DO GOLPE: a câmera leva um "chute" na direção do impacto e volta aos
# poucos depois da pausa (o tremor aleatório sozinho não mostra de onde veio
# a pancada). Segura durante o hit-stop: a imagem "trava" deslocada.
# v1.21: força da CÂMERA DE AÇÃO (OPÇÕES): suave, normal ou intensa. Não depende da
# qualidade visual: mexer a câmera não custa nada, até o celular mais simples aguenta.
static func camera_forca() -> float:
	return [0.55, 1.0, 1.35][clampi(G.cfg_camera_acao, 0, 2)]


static func camera_empurrar(dir_x: float, forca: float, dir_y := 0.0) -> void:
	forca *= camera_forca()
	G.cam_chute_x = clampf(G.cam_chute_x + dir_x * forca, -18, 18)
	G.cam_chute_y = clampf(G.cam_chute_y + dir_y * forca, -12, 12)
	camera_soco(absf(forca) * 0.012)     # v1.20: toda pancada também fecha a câmera um instante


# v1.20: "soco" de zoom — a câmera fecha de repente e abre de volta
static func camera_soco(forca: float) -> void:
	G.cam_soco = minf(0.16, G.cam_soco + forca * camera_forca())


static func tempo_texto(seg: float) -> String:
	var m := int(floor(seg / 60.0))
	var s := int(floor(fmod(seg, 60.0)))
	return str(m) + ":" + ("0" if s < 10 else "") + str(s)


# Altura do CHÃO PRINCIPAL da sala, ou -1 se o chão ainda não existe ou está
# desativado. Soma a largura das peças de obj_chao em cada altura e fica com
# a altura que tem mais chão (sem contar os sólidos filhos e paredes laterais).
func chao_da_sala() -> float:
	var topos := []
	var largs := []
	for c in todos("obj_chao"):
		if c.obj != "obj_chao":
			continue
		var l: float = c.bbox_right - c.bbox_left
		var h: float = c.bbox_bottom - c.bbox_top
		if l > 0 and not (h > 250 and h > l):
			var achou := -1
			for i in topos.size():
				if absf(topos[i] - c.bbox_top) <= 2:
					achou = i
					break
			if achou < 0:
				topos.append(c.bbox_top)
				largs.append(l)
			else:
				largs[achou] += l
	var melhor := -1.0
	var maior := 0.0
	for i in topos.size():
		if largs[i] > maior:
			maior = largs[i]
			melhor = topos[i]
	return melhor


# Primeiro ponto de chão (obj_chao) abaixo de (px, py). Retorna py se não achar.
static func chao_abaixo(px: float, py: float, maximo := 400) -> float:
	for i in maximo:
		if G.chao_ponto(px, py + i):
			return py + i
	return py


# =====================================================================
# scr_input: teclado + controle + toque, navegação dos menus e nomes
# =====================================================================
static func acoes_nomes() -> Array:
	return ["CORRER À ESQUERDA", "CORRER À DIREITA", "PULAR", "ATAQUE (COMBO)", "ESPECIAL · ONDA", "DEFENDER / APARAR", "INTERAGIR / SUB-ARMA", "AGACHAR",
		"GOLPE PESADO", "RASTEIRA / FINALIZADOR", "ESPECIAL · QUEDA", "ESPECIAL · TREMOR", "ESQUIVA / BACKDASH", "FÚRIA"]


static func acoes_ordem_tela() -> Array:
	return [ACAO.ESQUERDA, ACAO.DIREITA, ACAO.PULAR, ACAO.AGACHAR, ACAO.ESQUIVA, ACAO.DEFENDER, ACAO.INTERAGIR,
		ACAO.ATACAR, ACAO.ATAQUE_FORTE, ACAO.ATAQUE_SALTO, ACAO.ESPECIAL_3, ACAO.ESPECIAL, ACAO.ESPECIAL_2, ACAO.FURIA]


# Teclado: A/D correm, W pula, S agacha, ESPAÇO esquiva, Q defende, E interage,
# R fúria, J ataque, I golpe pesado, K rasteira, U / L / O especiais.
static func teclas_padrao() -> Array:
	return [KEY_A, KEY_D, KEY_W, KEY_J, KEY_L, KEY_Q, KEY_E, KEY_S, KEY_I, KEY_K, KEY_O, KEY_U, KEY_SPACE, KEY_R]


static func teclas_secundarias() -> Array:
	var s := []
	s.resize(ACAO.TOTAL)
	s.fill(-1)
	s[ACAO.ESQUERDA] = KEY_LEFT
	s[ACAO.DIREITA] = KEY_RIGHT
	s[ACAO.PULAR] = KEY_UP
	s[ACAO.AGACHAR] = KEY_DOWN
	return s


# Controle (nomes do PlayStation): QUADRADO ataca, TRIÂNGULO golpe pesado,
# BOLA rasteira / finalizador, X pula, L1 defende, L2 esquiva, R1 / R2 / R3
# especiais, L3 fúria, D-pad cima interage. SELECT pausa e START armas.
static func botoes_padrao() -> Array:
	return [gp_padl, gp_padr, gp_face1, gp_face3, gp_shoulderrb, gp_shoulderl, gp_padu, gp_padd,
		gp_face4, gp_face2, gp_stickr, gp_shoulderr, gp_shoulderlb, gp_stickl]


static func botoes_remapeaveis() -> Array:
	return [gp_face1, gp_face2, gp_face3, gp_face4, gp_shoulderl, gp_shoulderr, gp_shoulderlb, gp_shoulderrb,
		gp_stickl, gp_stickr, gp_padu, gp_padd, gp_padl, gp_padr]


static func tecla_reservada(k: int) -> bool:
	return k == KEY_ESCAPE or k == KEY_ENTER or k == KEY_TAB or k == KEY_F1 or k == KEY_F11 or k <= 0


func gamepad_escolher() -> int:
	var atual := G.pad_conectado()
	if atual != G.pad_slot:
		G.pad_slot = atual
		if atual >= 0:
			G.pad_desc = Input.get_joy_name(atual)
			G.pad_botoes = 16
		else:
			G.pad_desc = ""
			G.pad_botoes = 0
	return atual


func gamepad_alguma_entrada(_pad: int) -> bool:
	for b in botoes_remapeaveis():
		if G.pad_botao(b):
			return true
	return G.pad_botao(gp_start) or G.pad_botao(gp_select)


static func pad_estilo() -> String:
	var d := G.pad_desc.to_lower()
	if d.contains("ps") or d.contains("sony") or d.contains("dual") or d.contains("playstation"):
		return "ps"
	return "xbox"


static func gamepad_descricao_conectado() -> String:
	if G.pad_slot < 0:
		return "NENHUM CONECTADO"
	var d := G.pad_desc
	if d == "":
		d = "CONTROLE " + str(G.pad_slot + 1)
	if d.length() > 26:
		d = d.substr(0, 24) + ".."
	return d.to_upper()


static func pad_entrada(pad: int, codigo: int) -> bool:
	if pad < 0 or codigo < 0:
		return false
	return G.pad_botao(codigo)


# Chamado 1x por passo pelo obj_sistema (Begin Step)
func input_atualizar() -> void:
	var pad := gamepad_escolher()
	var ax := 0.0
	var ay := 0.0
	if pad >= 0:
		ax = G.pad_eixo_valor(JOY_AXIS_LEFT_X)
		ay = G.pad_eixo_valor(JOY_AXIS_LEFT_Y)
	var t = G.toque
	var tv: Vector2 = t.eixo if t != null else Vector2.ZERO
	G.pad_eixo = absf(ax)
	G.inp_cima = (pad >= 0 and ay < -0.6 and absf(ay) > absf(ax)) or (tv.y < -0.6 and absf(tv.y) > absf(tv.x))
	var rx := G.pad_eixo_valor(JOY_AXIS_RIGHT_X) if pad >= 0 else 0.0
	G.esquiva_stick = 0
	if absf(rx) > 0.7 and absf(G.eixo_dir_antes) <= 0.7:
		G.esquiva_stick = int(signf(rx))
	G.eixo_dir_antes = rx
	if G.alguma_tecla:
		G.usando_pad = false
		G.usando_toque = false
	if pad >= 0 and (absf(ax) > 0.5 or absf(ay) > 0.5 or gamepad_alguma_entrada(pad)):
		G.usando_pad = true
		G.usando_toque = false
	var sec := teclas_secundarias()
	for i in ACAO.TOTAL:
		var h: bool = G.keyboard_check(G.teclas[i])
		var k2: int = sec[i]
		if not h and k2 > 0 and not G.teclas.has(k2) and G.keyboard_check(k2):
			h = true
		var hp := pad >= 0 and pad_entrada(pad, G.botoes[i])
		if i == ACAO.ESQUERDA and ax < -0.35:
			hp = true
		if i == ACAO.DIREITA and ax > 0.35:
			hp = true
		if i == ACAO.AGACHAR and ay > 0.65 and ay > absf(ax):
			hp = true
		var ht: bool = t != null and t.segurado(i)
		var total := h or hp or ht
		G.inp_apertado[i] = total and not G.inp_segurado[i]
		G.inp_pad_apertado[i] = G.inp_apertado[i] and hp
		G.inp_segurado[i] = total
	if t != null:
		t.fim_tick()
	input_nav_atualizar(pad, ax, ay)


static func input_segurado(a: int) -> bool:
	return G.inp_segurado[a]

static func input_apertado(a: int) -> bool:
	return G.inp_apertado[a]


# ESC / SELECT / botão de pausa da tela / VOLTAR do Android: pausa
static func input_pausa_apertada() -> bool:
	return G.keyboard_check_pressed(KEY_ESCAPE) or (G.pad_slot >= 0 and G.pad_botao_apertado(gp_select)) \
		or G.voltar_apertado or (G.toque != null and G.toque.pausa_apertada)


# TAB / START / botão de armas da tela: tela de armas e evolução
static func input_armas_apertado() -> bool:
	return G.keyboard_check_pressed(KEY_TAB) or (G.pad_slot >= 0 and G.pad_botao_apertado(gp_start)) \
		or (G.toque != null and G.toque.armas_apertada)


# fecha qualquer menu de jogo (ESC, TAB, START, SELECT, BOLA ou VOLTAR)
static func input_fechar_menu() -> bool:
	return G.keyboard_check_pressed(KEY_ESCAPE) or G.keyboard_check_pressed(KEY_TAB) or G.voltar_apertado \
		or (G.pad_slot >= 0 and (G.pad_botao_apertado(gp_start) or G.pad_botao_apertado(gp_select) or G.pad_botao_apertado(gp_face2)))


# ENTER ou X (cruz / A): fecha o pergaminho
static func input_confirmar_pergaminho() -> bool:
	return G.keyboard_check_pressed(KEY_ENTER) or G.keyboard_check_pressed(KEY_KP_ENTER) or (G.pad_slot >= 0 and G.pad_botao_apertado(gp_face1))


static func input_nav_iniciar() -> void:
	G.nav_cima = false
	G.nav_baixo = false
	G.nav_esq = false
	G.nav_dir = false
	G.nav_ok = false
	G.nav_voltar = false
	G.nav_seg = [0.0, 0.0, 0.0, 0.0]


static func input_nav_atualizar(pad: int, ax: float, ay: float) -> void:
	var p := pad >= 0
	var dirs := [
		G.keyboard_check(KEY_UP) or G.keyboard_check(KEY_W) or (p and (G.pad_botao(gp_padu) or ay < -0.55)),
		G.keyboard_check(KEY_DOWN) or G.keyboard_check(KEY_S) or (p and (G.pad_botao(gp_padd) or ay > 0.55)),
		G.keyboard_check(KEY_LEFT) or G.keyboard_check(KEY_A) or (p and (G.pad_botao(gp_padl) or ax < -0.55)),
		G.keyboard_check(KEY_RIGHT) or G.keyboard_check(KEY_D) or (p and (G.pad_botao(gp_padr) or ax > 0.55)),
	]
	var res := [false, false, false, false]
	for i in 4:
		if dirs[i]:
			var antes: float = G.nav_seg[i]
			G.nav_seg[i] += G.dt_real
			# aperto inicial, depois repete a cada 6 quadros após 24 quadros segurando
			if antes == 0:
				res[i] = true
			elif G.nav_seg[i] >= 24 and floor((G.nav_seg[i] - 24) / 6.0) != floor((antes - 24) / 6.0):
				res[i] = true
		else:
			G.nav_seg[i] = 0.0
	G.nav_cima = res[0]
	G.nav_baixo = res[1]
	G.nav_esq = res[2]
	G.nav_dir = res[3]
	G.nav_ok = G.keyboard_check_pressed(KEY_ENTER) or G.keyboard_check_pressed(KEY_KP_ENTER) or G.keyboard_check_pressed(KEY_SPACE) \
		or (p and G.pad_botao_apertado(gp_face1))
	G.nav_voltar = G.keyboard_check_pressed(KEY_ESCAPE) or G.voltar_apertado \
		or (p and (G.pad_botao_apertado(gp_face2) or G.pad_botao_apertado(gp_select)))


static func nome_tecla(k: int) -> String:
	match k:
		KEY_SHIFT:
			return "SHIFT"
		KEY_CTRL:
			return "CTRL"
		KEY_ALT:
			return "ALT"
		KEY_SPACE:
			return "ESPAÇO"
		KEY_ENTER:
			return "ENTER"
		KEY_ESCAPE:
			return "ESC"
		KEY_TAB:
			return "TAB"
		KEY_BACKSPACE:
			return "BACKSPACE"
		KEY_UP:
			return "SETA CIMA"
		KEY_DOWN:
			return "SETA BAIXO"
		KEY_LEFT:
			return "SETA ESQ."
		KEY_RIGHT:
			return "SETA DIR."
	var s := OS.get_keycode_string(k)
	if s == "":
		return "TECLA " + str(k)
	return s.to_upper()


static func nome_pad(b: int) -> String:
	var ps := pad_estilo() == "ps"
	match b:
		gp_face1:
			return "X (CRUZ)" if ps else "A"
		gp_face2:
			return "BOLA" if ps else "B"
		gp_face3:
			return "QUADRADO" if ps else "X"
		gp_face4:
			return "TRIÂNGULO" if ps else "Y"
		gp_shoulderl:
			return "L1" if ps else "LB"
		gp_shoulderr:
			return "R1" if ps else "RB"
		gp_shoulderlb:
			return "L2" if ps else "LT"
		gp_shoulderrb:
			return "R2" if ps else "RT"
		gp_start:
			return "OPTIONS" if ps else "START"
		gp_select:
			return "SHARE / SELECT" if ps else "BACK"
		gp_stickl:
			return "L3"
		gp_stickr:
			return "R3"
		gp_padu:
			return "D-PAD CIMA"
		gp_padd:
			return "D-PAD BAIXO"
		gp_padl:
			return "D-PAD ESQ."
		gp_padr:
			return "D-PAD DIR."
		-1:
			return "ANALÓGICO"
	return "BOTÃO " + str(b)


# Rótulos dos botões de menu (mudam sozinhos entre toque, teclado e controle)
static func usando_controle() -> bool:
	return G.usando_pad and G.pad_slot >= 0

static func nome_confirmar() -> String:
	if usando_controle():
		return "X" if pad_estilo() == "ps" else "A"
	if G.usando_toque:
		return "TOQUE"
	return "ENTER"

static func nome_voltar() -> String:
	if usando_controle():
		return "BOLA" if pad_estilo() == "ps" else "B"
	if G.usando_toque:
		return "VOLTAR"
	return "ESC"

static func nome_pausa() -> String:
	if usando_controle():
		return "SELECT" if pad_estilo() == "ps" else "BACK"
	if G.usando_toque:
		return "VOLTAR"
	return "ESC"

static func nome_setas() -> String:
	if usando_controle():
		return "D-pad / analógico"
	if G.usando_toque:
		return "Toques"
	return "Setas"


# o botão de toque desta ação já está liberado? (especiais dependem do nível da espada)
static func especial_liberado_s(a: int) -> bool:
	if a == ACAO.ESPECIAL:
		return G.espada_nivel >= 2
	if a == ACAO.ESPECIAL_2:
		return G.espada_nivel >= 4
	return true


# HD (scr_hd): draw_sprite_ext que já desconta a escala HD (1/k) com filtro suave
func draw_sprite_hd(s: GMSprite, img: float, px: float, py: float, xs: float, ys: float, rot: float, c: Color, a: float) -> void:
	if s == null:
		return
	if s.k > 1.0:
		var tf: bool = G.pen.filtro
		G.pen.filtro = true
		G.pen.sprite(s, img, px, py, xs / s.k, ys / s.k, rot, c, a)
		G.pen.filtro = tf
	else:
		G.pen.sprite(s, img, px, py, xs, ys, rot, c, a)


static func hd_escala(s: GMSprite) -> float:
	return s.k if s != null else 1.0


# nomes dos botões de toque (tela) de cada ação
static func toque_nome(a: int) -> String:
	return ["◄", "►", "PULO", "ATAQUE", "ONDA", "DEFESA", "AÇÃO", "▼", "PESADO", "RASTEIRA", "QUEDA", "TREMOR", "ESQUIVA", "FÚRIA"][a]


static func toque_curto(a: int) -> String:
	return ["◄", "►", "PULO", "ATQ", "ONDA", "DEF", "AÇÃO", "▼", "PES", "RAS", "QUED", "TREM", "ESQ", "FÚR"][a]


static func toque_cor(a: int) -> Color:
	match a:
		ACAO.ATACAR:
			return Color8(255, 120, 80)
		ACAO.ATAQUE_FORTE:
			return Color8(255, 200, 90)
		ACAO.ATAQUE_SALTO:
			return Color8(255, 90, 90)
		ACAO.PULAR:
			return Color8(120, 190, 255)
		ACAO.ESQUIVA:
			return Color8(150, 230, 255)
		ACAO.DEFENDER:
			return Color8(140, 170, 255)
		ACAO.INTERAGIR:
			return Color8(255, 230, 150)
		ACAO.ESPECIAL, ACAO.ESPECIAL_2, ACAO.ESPECIAL_3:
			return Color8(130, 180, 255)
		ACAO.FURIA:
			return Color8(255, 60, 40)
	return Color8(220, 220, 220)


static func rotulo_acao(a: int) -> String:
	if G.usando_pad and G.pad_slot >= 0:
		var b: int = G.botoes[a]
		if b < 0:
			return "[ANALÓGICO]"
		var ps := pad_estilo() == "ps"
		if b == gp_face1:
			return "[X]" if ps else "[A]"
		return "[" + nome_pad(b) + "]"
	if G.usando_toque:
		return "[" + toque_nome(a) + "]"
	return "[" + nome_tecla(G.teclas[a]) + "]"


# Controle conectado / desconectado (evento assíncrono do obj_sistema)
func controle_mudou(dev: int, conectado: bool) -> void:
	if conectado:
		G.pad_slot = -1
		gamepad_escolher()
		var d := Input.get_joy_name(dev)
		if d == "":
			d = "CONTROLE " + str(dev + 1)
		aviso_mostrar("CONTROLE CONECTADO  ·  " + d.to_upper(), false)
	elif dev == G.pad_slot:
		G.pad_slot = -1
		G.usando_pad = false
		gamepad_escolher()
		aviso_mostrar("CONTROLE DESCONECTADO", false)
		# no meio da fase, o jogo pausa sozinho
		var p = instance_find("obj_player", 0)
		if G.room != "rm_menu" and p != null and not p.morto and not instance_exists("obj_pausa") and not instance_exists("obj_save_menu") \
				and not instance_exists("obj_loading") and not instance_exists("obj_dialogo") and not instance_exists("obj_game_over") and not instance_exists("obj_final"):
			instance_create_depth(0, 0, -10000, "obj_pausa")


# =====================================================================
# scr_audio: efeitos sonoros, músicas e ambientes (cada som na sua "cena")
# =====================================================================
static func audio_lista_efeitos() -> Array:
	return [
		["tit_mover", "titulo", 3], ["tit_selecao", "titulo", 2], ["tit_alterar", "titulo", 3], ["tit_voltar", "titulo", 2],
		["tit_negado", "titulo", 2], ["tit_logo", "titulo", 1], ["tit_start", "transicao", 1],
		["cut_passar", "cutscene", 2],
		["sfx_menu_abrir", "ui", 2], ["sfx_menu_fechar", "ui", 2], ["sfx_menu_mover", "ui", 3], ["sfx_menu_ok", "ui", 2],
		["sfx_negado", "ui", 2], ["sfx_pagina", "ui", 2], ["sfx_salvar", "ui", 1], ["sfx_derrota", "ui", 1],
		["atk_corte_1", "fase", 3], ["atk_corte_2", "fase", 3], ["atk_aereo", "fase", 2], ["atk_pesado", "fase", 3],
		["atk_rasteira", "fase", 2], ["atk_mergulho", "fase", 2], ["sfx_inimigo_golpe", "fase", 4], ["sfx_flecha", "fase", 3],
		["esp_carga", "fase", 2], ["esp_tremor", "fase", 2], ["esp_onda", "fase", 2], ["esp_queda", "fase", 2],
		["esp_furia", "fase", 1], ["esp_furia_impacto", "fase", 1], ["sfx_finalizador", "fase", 2], ["sfx_impacto", "fase", 3],
		["hit_1", "fase", 4], ["hit_2", "fase", 4], ["hit_3", "fase", 4], ["hit_pesado", "fase", 3], ["sfx_dano", "fase", 3],
		["sfx_bloqueio", "fase", 3], ["sfx_aparar", "fase", 2], ["sfx_escudo_quebra", "fase", 2],
		["dest_madeira", "fase", 3], ["dest_pedra", "fase", 3], ["dest_viga", "fase", 2], ["dest_quique", "fase", 3],
		["fase_concluida", "fase", 1], ["espada_evoluir", "fase", 1], ["sfx_segredo", "fase", 1],
		["fogo_whoosh", "fase", 3], ["fogo_bola", "fase", 3], ["fogo_explosao", "fase", 3],
		["sfx_esquiva", "fase", 2], ["sfx_pulo", "fase", 3], ["sfx_pouso", "fase", 3], ["sfx_orb", "fase", 4],
		["sfx_bau", "fase", 1], ["sfx_cura", "fase", 2], ["sfx_portal", "fase", 3], ["sfx_rugido", "fase", 2],
		["sfx_espinhos", "fase", 3], ["sfx_trovao_1", "fase", 1], ["sfx_trovao_2", "fase", 1], ["sfx_trovao_3", "fase", 1],
		["osso_chocalho", "fase", 2], ["osso_desmonta", "fase", 3], ["osso_ergue", "fase", 2], ["osso_quebra", "fase", 3],
		["teia_disparo", "fase", 3], ["teia_prende", "fase", 2], ["aranha_chiado", "fase", 2],
		["porco_grunhido", "fase", 2], ["porco_impacto", "fase", 2], ["magia_onda", "fase", 2],
		["pedra_tinido", "fase", 3], ["estatua_carga", "fase", 2], ["estatua_disparo", "fase", 2], ["pedra_desmorona", "fase", 2],
		["maldicao_evaporar", "fase", 4], ["maldicao_grande", "fase", 1],
		["tocha_acender", "fase", 3], ["lampiao_bater", "fase", 2],
		["sfx_critico", "fase", 3], ["sfx_contra", "fase", 2], ["sfx_backdash", "fase", 2], ["sfx_petrificar", "fase", 3],
		["furia_inicio", "fase", 1], ["furia_fim", "fase", 1], ["sangue_lamina", "fase", 3],
		["essencia", "fase", 3], ["bumerangue", "fase", 2], ["chama_sylla", "fase", 2],
		["veneno_frasco", "fase", 3], ["veneno_poca", "fase", 3], ["veneno_dano", "fase", 2],
		["dialogo_texto", "ui", 3], ["dialogo_abrir", "ui", 1],
		["viga_aviso", "fase", 2], ["raiz_aviso", "fase", 3], ["galho_aviso", "fase", 1], ["boss_carga", "fase", 2],
		# v1.16: mensagem importante (aviso, objetivo, alerta, tutorial) e o corte de espada
		# (sfx_sword_slash é opcional: se o arquivo existir, vira o som dos cortes; ver golpe_som)
		["sfx_important_message", "transicao", 2], ["sfx_sword_slash", "fase", 3],
	]


static func audio_iniciar() -> void:
	if G.audio_ok:
		return
	G.audio_ok = true
	G.audio_cena = "titulo"
	G.sfx = {}
	G.sfx_tocando = []
	G.sfx_saindo = []
	for e in audio_lista_efeitos():
		var s := G.audio_carregar(e[0] + ".ogg")
		if s == null:
			continue
		G.sfx[e[0]] = {"s": s, "copias": e[2], "amb": e[1], "tocando": []}
	G.streams = {}
	# v1.16: trilha sonora nova (bgm_*), pronta para o loop (ferramentas/converter_trilha.ps1)
	for m in ["bgm_main_menu", "bgm_loading_screen", "bgm_battle_phase1", "bgm_mini_boss", "bgm_final_boss_phase1",
			"mus_prologo", "mus_fase", "amb_chuva", "amb_fogo"]:
		var s := G.audio_carregar(m + ".ogg")
		if s != null:
			G.streams[m] = s
	G.musica_nome = ""
	G.musica_inst = null
	G.musica_saindo = []
	G.musica_alvo = 0
	G.ambientes = {}
	G.audio_pausa = false


static func som_permitido(amb: String) -> bool:
	match amb:
		"transicao":
			return true
		"titulo":
			return G.audio_cena == "titulo"
		"cutscene":
			return G.audio_cena == "cutscene"
		"ui", "fase":
			return G.audio_cena == "fase"
	return false


static func audio_cena_definir(cena: String) -> void:
	if not G.audio_ok:
		return
	if G.audio_cena == cena:
		return
	G.audio_cena = cena
	for i in range(G.sfx_tocando.size() - 1, -1, -1):
		var t: Dictionary = G.sfx_tocando[i]
		if som_permitido(t.amb):
			continue
		if G.audio_is_playing(t.inst):
			G.audio_sound_gain(t.inst, 0, 200)
			G.sfx_saindo.append(t.inst)
		G.sfx_tocando.remove_at(i)
	if cena != "fase":
		ambientes_parar()


# Toca um efeito. var_tom muda um pouco o tom a cada vez (não fica repetitivo)
static func som(nome: String, vol := 1.0, var_tom := 0.05):
	if not G.audio_ok:
		return null
	var e = G.sfx.get(nome)
	if e == null:
		return null
	if not som_permitido(e.amb):
		return null
	var g: float = vol * G.cfg_vol_efeitos
	if g <= 0.01:
		return null
	# cada efeito tem um número de cópias: a mais antiga dá lugar à nova
	var lista: Array = e.tocando
	for i in range(lista.size() - 1, -1, -1):
		if not G.audio_is_playing(lista[i]):
			lista.remove_at(i)
	if lista.size() >= int(e.copias):
		G.audio_stop_sound(lista[0])
		lista.remove_at(0)
	var inst = G.audio_play_sound(e.s, false, g, 1.0 + randf_range(-var_tom, var_tom))
	if inst != null:
		lista.append(inst)
		G.sfx_tocando.append({"inst": inst, "amb": e.amb})
	return inst


# Efeito com volume pela distância até o centro da tela
static func som_em(nome: String, px: float, _py: float, vol := 1.0, var_tom := 0.05):
	var cx := G.cam_x + CAMERA_ALTURA * G.tela_aspecto / 2.0
	var d := absf(px - cx)
	var a := clampf(1.0 - (d - 300.0) / 700.0, 0.0, 1.0)
	if a <= 0.02:
		return null
	return som(nome, vol * a, var_tom)


static func som_var(base: String, qtd: int, vol := 1.0):
	return som(base + "_" + str(randi_range(1, qtd)), vol)


static func musica(nome: String, fade_ms := 1500.0) -> void:
	if not G.audio_ok:
		return
	if G.musica_nome == nome:
		return
	if G.musica_inst != null and G.audio_is_playing(G.musica_inst):
		G.audio_sound_gain(G.musica_inst, 0, fade_ms)
		G.musica_saindo.append(G.musica_inst)
	G.musica_inst = null
	G.musica_nome = nome
	if nome == "":
		return
	var s = G.streams.get(nome)
	if s == null:
		return
	G.musica_inst = G.audio_play_sound(s, true, 0.0)
	G.musica_alvo = musica_ganho()
	G.audio_sound_gain(G.musica_inst, G.musica_alvo, fade_ms)


static func musica_ganho() -> float:
	return G.cfg_vol_musica * (0.35 if G.audio_pausa else 1.0)


# v1.16: a trilha de cada fase (fase 1: a batalha da vila; fase 2: a antiga)
static func musica_fase() -> String:
	return "bgm_battle_phase1" if G.room == "Room1" else "mus_fase"


# v1.16: o som da MENSAGEM IMPORTANTE (aviso na tela, objetivo novo, alerta,
# tutorial). Um intervalo curto evita dois toques quando o aviso e o
# objetivo mudam no mesmo instante.
static func som_mensagem():
	var agora := float(Time.get_ticks_msec())
	if agora - G.msg_som_t < 900.0:
		return null
	G.msg_som_t = agora
	return som("sfx_important_message", 0.9, 0)


# Sons de ambiente em loop (chuva, fogo): só tocam com a fase rodando
func ambiente(nome: String, alvo: float) -> void:
	if not G.audio_ok:
		return
	if G.audio_cena != "fase" or instance_exists("obj_loading"):
		alvo = 0.0
	var a = G.ambientes.get(nome)
	if a == null:
		if alvo <= 0.01:
			return
		var s = G.streams.get(nome)
		if s == null:
			return
		a = {"inst": G.audio_play_sound(s, true, 0.0), "alvo": alvo, "atual": 0.0}
		G.ambientes[nome] = a
	a.alvo = alvo


# Chamado 1x por passo pelo obj_sistema
func audio_atualizar() -> void:
	if not G.audio_ok:
		return
	if G.musica_inst != null and G.audio_is_playing(G.musica_inst):
		var g := musica_ganho()
		if absf(G.musica_alvo - g) > 0.01:
			G.musica_alvo = g
			G.audio_sound_gain(G.musica_inst, g, 400)
	for i in range(G.musica_saindo.size() - 1, -1, -1):
		var m = G.musica_saindo[i]
		if not G.audio_is_playing(m) or G.audio_sound_get_gain(m) <= 0.01:
			G.audio_stop_sound(m)
			G.musica_saindo.remove_at(i)
	for k in range(G.sfx_tocando.size() - 1, -1, -1):
		if not G.audio_is_playing(G.sfx_tocando[k].inst):
			G.sfx_tocando.remove_at(k)
	for k in range(G.sfx_saindo.size() - 1, -1, -1):
		var sx = G.sfx_saindo[k]
		if not G.audio_is_playing(sx) or G.audio_sound_get_gain(sx) <= 0.01:
			G.audio_stop_sound(sx)
			G.sfx_saindo.remove_at(k)
	var carregando := instance_exists("obj_loading")
	for nome in G.ambientes.keys():
		var a: Dictionary = G.ambientes[nome]
		if G.audio_cena != "fase" or carregando:
			a.alvo = 0.0
		var alvo: float = a.alvo * G.cfg_vol_efeitos * (0.4 if G.audio_pausa else 1.0)
		a.atual = lerpf(a.atual, alvo, 0.05)
		G.audio_sound_gain(a.inst, a.atual, 0)
		if a.alvo <= 0.01 and a.atual <= 0.01:
			G.audio_stop_sound(a.inst)
			G.ambientes.erase(nome)


static func ambientes_parar() -> void:
	if not G.audio_ok:
		return
	for nome in G.ambientes:
		G.ambientes[nome].alvo = 0.0


# =====================================================================
# scr_menu: configurações, fontes e funções de desenho da interface
# =====================================================================
static func config_nomes_qualidade() -> Array:
	return ["BAIXA", "MÉDIA", "ALTA"]

static func config_nomes_fps() -> Array:
	return ["30 FPS", "60 FPS"]


static func config_chaves_controles() -> Array:
	return ["left", "right", "jump", "attack", "special", "block", "interact", "crouch", "heavy", "sweep", "special2", "special3", "dodge", "rage"]


static func config_carregar() -> void:
	var chaves := config_chaves_controles()
	# v1.14: no celular o perfil AUTOMÁTICO escolhe qualidade, taxa de quadros e
	# resolução pelo aparelho e se ajusta durante o jogo (Desempenho)
	if G.arquivo_existe("config.ini"):
		var c := G.ini_abrir("config.ini")
		G.cfg_qualidade = int(c.get_value("video", "qualidade", G.cfg_qualidade))
		G.cfg_fps = int(c.get_value("video", "fps", G.cfg_fps))
		G.cfg_desempenho = int(c.get_value("video", "desempenho", G.cfg_desempenho))
		G.nivel_auto = int(c.get_value("video", "nivel_auto", G.nivel_auto))
		G.cfg_resolucao = int(c.get_value("video", "resolucao", G.cfg_resolucao))
		G.cfg_volume = float(c.get_value("audio", "volume", G.cfg_volume))
		G.cfg_fundo_hd = int(c.get_value("video", "fundo_hd", G.cfg_fundo_hd))
		G.cfg_tutorial = int(c.get_value("jogo", "tutorial", G.cfg_tutorial))
		G.cfg_vol_musica = float(c.get_value("audio", "musica", G.cfg_vol_musica))
		G.cfg_vol_efeitos = float(c.get_value("audio", "efeitos", G.cfg_vol_efeitos))
		G.cfg_toque_tam = int(c.get_value("toque", "tamanho", G.cfg_toque_tam))
		G.cfg_toque_opac = float(c.get_value("toque", "opacidade", G.cfg_toque_opac))
		G.cfg_vibrar = int(c.get_value("toque", "vibrar", G.cfg_vibrar))
		# v1.21: HUD personalizada (o tamanho antigo, 3 passos, vira a porcentagem)
		G.cfg_hud_tam = float(c.get_value("hud", "tamanho", [0.85, 1.0, 1.15][clampi(G.cfg_toque_tam, 0, 2)]))
		G.cfg_hud_modo = int(c.get_value("hud", "modo", G.cfg_hud_modo))
		G.cfg_hud_pos = {}
		if c.has_section("hud_pos"):
			for k in c.get_section_keys("hud_pos"):
				var pv = c.get_value("hud_pos", k, Vector2.ZERO)
				if pv is Vector2:
					G.cfg_hud_pos[k] = pv
		G.cfg_camera_acao = int(c.get_value("video", "camera_acao", G.cfg_camera_acao))
		G.cfg_padrao_v121 = int(c.get_value("video", "padrao_v121", 0))
		if int(c.get_value("controles", "versao", 0)) >= CONTROLES_VERSAO:
			for i in ACAO.TOTAL:
				G.teclas[i] = int(c.get_value("teclado", chaves[i], G.teclas[i]))
				G.botoes[i] = int(c.get_value("controle", chaves[i], G.botoes[i]))
	# v1.21: no celular o jogo começa no MÍNIMO (roda liso em qualquer aparelho);
	# quem quiser mais sobe em OPÇÕES > DESEMPENHO. Vale uma vez, na primeira abertura.
	if G.cfg_padrao_v121 == 0:
		G.cfg_padrao_v121 = 1
		if OS.has_feature("mobile"):
			G.cfg_desempenho = 1
	config_validar_controles()
	Desempenho.iniciar()
	config_aplicar()


static func config_salvar() -> void:
	var chaves := config_chaves_controles()
	var c := ConfigFile.new()
	c.set_value("video", "qualidade", G.cfg_qualidade)
	c.set_value("video", "fps", G.cfg_fps)
	c.set_value("video", "desempenho", G.cfg_desempenho)
	c.set_value("video", "nivel_auto", G.nivel_auto)
	c.set_value("video", "resolucao", G.cfg_resolucao)
	c.set_value("audio", "volume", G.cfg_volume)
	c.set_value("video", "fundo_hd", G.cfg_fundo_hd)
	c.set_value("jogo", "tutorial", G.cfg_tutorial)
	c.set_value("audio", "musica", G.cfg_vol_musica)
	c.set_value("audio", "efeitos", G.cfg_vol_efeitos)
	c.set_value("toque", "tamanho", G.cfg_toque_tam)
	c.set_value("toque", "opacidade", G.cfg_toque_opac)
	c.set_value("toque", "vibrar", G.cfg_vibrar)
	c.set_value("hud", "tamanho", G.cfg_hud_tam)
	c.set_value("hud", "modo", G.cfg_hud_modo)
	for k in G.cfg_hud_pos.keys():
		c.set_value("hud_pos", k, G.cfg_hud_pos[k])
	c.set_value("video", "camera_acao", G.cfg_camera_acao)
	c.set_value("video", "padrao_v121", G.cfg_padrao_v121)
	c.set_value("controles", "versao", CONTROLES_VERSAO)
	for i in ACAO.TOTAL:
		c.set_value("teclado", chaves[i], G.teclas[i])
		c.set_value("controle", chaves[i], G.botoes[i])
	G.ini_salvar(c, "config.ini")


static func config_validar_controles() -> void:
	var tp := teclas_padrao()
	var bp := botoes_padrao()
	var remap := botoes_remapeaveis()
	for i in ACAO.TOTAL:
		if tecla_reservada(G.teclas[i]):
			G.teclas[i] = tp[i]
		if not remap.has(G.botoes[i]) and G.botoes[i] != -1:
			G.botoes[i] = bp[i]
		for j in i:
			if G.teclas[j] == G.teclas[i]:
				G.teclas[i] = tp[i]
				G.teclas[j] = tp[j]
			if G.botoes[j] == G.botoes[i] and G.botoes[i] != -1:
				G.botoes[i] = bp[i]
				G.botoes[j] = bp[j]


static func config_aplicar() -> void:
	G.cfg_qualidade = clampi(G.cfg_qualidade, 0, 2)
	G.cfg_fps = clampi(G.cfg_fps, 0, 1)
	G.cfg_volume = clampf(G.cfg_volume, 0, 1)
	G.cfg_vol_musica = clampf(G.cfg_vol_musica, 0, 1)
	G.cfg_vol_efeitos = clampf(G.cfg_vol_efeitos, 0, 1)
	G.cfg_fundo_hd = clampi(G.cfg_fundo_hd, 0, 1)
	G.cfg_tutorial = clampi(G.cfg_tutorial, 0, 1)
	G.cfg_toque_tam = clampi(G.cfg_toque_tam, 0, 2)
	G.cfg_toque_opac = clampf(G.cfg_toque_opac, 0.2, 1.0)
	G.cfg_vibrar = clampi(G.cfg_vibrar, 0, 1)
	G.cfg_hud_tam = clampf(G.cfg_hud_tam, 0.6, 1.6)
	G.cfg_hud_modo = clampi(G.cfg_hud_modo, 0, 2)
	G.cfg_camera_acao = clampi(G.cfg_camera_acao, 0, 2)
	G.cfg_desempenho = clampi(G.cfg_desempenho, 0, Desempenho.PERSONALIZADO)
	G.cfg_resolucao = clampi(G.cfg_resolucao, 0, 1)
	Desempenho.aplicar_resolucao()
	G.audio_master_gain(G.cfg_volume)


# ----- Texto -----
static func fonte_em(f: int) -> float:
	return G.FONTE_EM[clampi(f, 0, FONTE.TOTAL - 1)]


# Texto com fonte, cor, transparência, alinhamento e escala
static func txt(px: float, py: float, s: String, f: int, cor := Color(1, 1, 1), alfa := 1.0, ha := 0, va := 0, esc := 1.0) -> void:
	G.cor_desenho = cor
	G.alfa_desenho = alfa
	G.pen.texto(px, py, s, G.fontes[f], fonte_em(f), cor, alfa, ha, va, esc)


# Texto com sombra escura (melhor leitura sobre o cenário)
static func txt_sombra(px: float, py: float, s: String, f: int, cor := Color(1, 1, 1), alfa := 1.0, ha := 0, va := 0, esc := 1.0) -> void:
	txt(px + 2, py + 2, s, f, c_black, alfa * 0.75, ha, va, esc)
	txt(px, py, s, f, cor, alfa, ha, va, esc)


# Texto com quebra de linha automática
static func txt_bloco(px: float, py: float, s: String, f: int, cor: Color, alfa: float, largura: float, ha := 1, va := 0) -> void:
	G.cor_desenho = cor
	G.alfa_desenho = alfa
	G.pen.texto_bloco(px, py, s, G.fontes[f], fonte_em(f), cor, alfa, largura, ha, va)


static func txt_largura(s: String, f: int, esc := 1.0) -> float:
	return Pen.largura_texto(s, G.fontes[f], fonte_em(f), esc)


static func txt_altura(s: String, f: int, esc := 1.0) -> float:
	return Pen.altura_texto(s, G.fontes[f], fonte_em(f), esc)


static func txt_bloco_altura(s: String, f: int, largura: float) -> float:
	return Pen.altura_bloco(s, G.fontes[f], fonte_em(f), largura)


static func desenho_resetar() -> void:
	G.alfa_desenho = 1.0
	G.cor_desenho = Color(1, 1, 1)
	G.pen.blend_add = false
	G.pen.fog = false


# ----- Elementos visuais -----
func retangulo_gradiente(x1: float, y1: float, x2: float, y2: float, c1: Color, a1: float, c2: Color, a2: float) -> void:
	draw_primitive_begin(pr_trianglestrip)
	draw_vertex_color(x1, y1, c1, a1)
	draw_vertex_color(x2, y1, c1, a1)
	draw_vertex_color(x1, y2, c2, a2)
	draw_vertex_color(x2, y2, c2, a2)
	draw_primitive_end()


func retangulo_gradiente_h(x1: float, y1: float, x2: float, y2: float, c1: Color, a1: float, c2: Color, a2: float) -> void:
	draw_primitive_begin(pr_trianglestrip)
	draw_vertex_color(x1, y1, c1, a1)
	draw_vertex_color(x2, y1, c2, a2)
	draw_vertex_color(x1, y2, c1, a1)
	draw_vertex_color(x2, y2, c2, a2)
	draw_primitive_end()


# Vinheta escura nas bordas da tela (GUI)
func desenhar_vinheta(gw: float, gh: float, forca: float, cor := Color(0, 0, 0)) -> void:
	var b := gh * 0.28
	retangulo_gradiente(0, 0, gw, b, cor, forca, cor, 0)
	retangulo_gradiente(0, gh - b, gw, gh, cor, 0, cor, forca)
	retangulo_gradiente_h(0, 0, b, gh, cor, forca, cor, 0)
	retangulo_gradiente_h(gw - b, 0, gw, gh, cor, 0, cor, forca)


# Painel ornamentado: fundo escuro em degradê, moldura dupla dourada com
# cantos chanfrados e losangos; selecionado ganha brilho carmesim por dentro
func desenhar_painel(x1: float, y1: float, x2: float, y2: float, sel := 0.0, alfa := 1.0) -> void:
	if alfa <= 0.01:
		return
	var ouro_cl := Color8(247, 222, 158)
	var ouro := Color8(206, 164, 86)
	var ouro_esc := Color8(104, 74, 36)
	var c := minf(10.0, (y2 - y1) * 0.25)
	# sombra
	draw_set_alpha(0.45 * alfa)
	draw_set_color(c_black)
	draw_rectangle(x1 + 3, y1 + 5, x2 + 3, y2 + 5, false)
	# fundo: degradê vertical (mais claro em cima), carmesim quando selecionado
	var topo := merge_color(Color8(30, 22, 22), Color8(92, 30, 22), sel)
	var base := merge_color(Color8(10, 7, 8), Color8(40, 10, 10), sel)
	retangulo_gradiente(x1 + 1, y1 + 1, x2 - 1, y2 - 1, topo, (0.86 + 0.1 * sel) * alfa, base, (0.9 + 0.08 * sel) * alfa)
	if sel > 0.05:
		gpu_set_blendmode(bm_add)
		retangulo_gradiente_h(x1, y1, (x1 + x2) / 2.0, y2, Color8(255, 60, 30), 0, Color8(255, 60, 30), 0.14 * sel * alfa)
		retangulo_gradiente_h((x1 + x2) / 2.0, y1, x2, y2, Color8(255, 60, 30), 0.14 * sel * alfa, Color8(255, 60, 30), 0)
		gpu_set_blendmode(bm_normal)
	# moldura externa (cantos chanfrados) e filete interno
	var cor_m := merge_color(ouro_esc.lerp(ouro, 0.4), ouro_cl, sel)
	draw_set_alpha(alfa)
	draw_set_color(cor_m)
	draw_line_width(x1 + c, y1, x2 - c, y1, 2)
	draw_line_width(x1 + c, y2, x2 - c, y2, 2)
	draw_line_width(x1, y1 + c, x1, y2 - c, 2)
	draw_line_width(x2, y1 + c, x2, y2 - c, 2)
	draw_line_width(x1, y1 + c, x1 + c, y1, 2)
	draw_line_width(x2 - c, y1, x2, y1 + c, 2)
	draw_line_width(x1, y2 - c, x1 + c, y2, 2)
	draw_line_width(x2 - c, y2, x2, y2 - c, 2)
	draw_set_alpha(alfa * (0.35 + 0.4 * sel))
	draw_set_color(ouro)
	draw_rectangle(x1 + 4, y1 + 4, x2 - 4, y2 - 4, true)
	# losangos nos cantos e no meio dos lados
	draw_set_alpha(alfa)
	draw_set_color(merge_color(ouro, ouro_cl, sel))
	var r := 3.5 + 1.5 * sel
	for p in [Vector2(x1 + c * 0.5, y1 + c * 0.5), Vector2(x2 - c * 0.5, y1 + c * 0.5), Vector2(x1 + c * 0.5, y2 - c * 0.5), Vector2(x2 - c * 0.5, y2 - c * 0.5),
			Vector2(x1, (y1 + y2) / 2.0), Vector2(x2, (y1 + y2) / 2.0)]:
		draw_triangle(p.x - r, p.y, p.x, p.y - r, p.x + r, p.y, false)
		draw_triangle(p.x - r, p.y, p.x, p.y + r, p.x + r, p.y, false)
	# brilho externo quando selecionado
	if sel > 0.05:
		gpu_set_blendmode(bm_add)
		draw_set_alpha(alfa * sel * 0.35)
		draw_set_color(Color8(255, 170, 90))
		draw_rectangle(x1 - 3, y1 - 3, x2 + 3, y2 + 3, true)
		gpu_set_blendmode(bm_normal)
	draw_set_alpha(1)


# Divisor ornamental (filete dourado que some nas pontas, losango no centro)
func desenhar_divisor(cx: float, py: float, meia: float, alfa := 1.0) -> void:
	var ouro := Color8(206, 164, 86)
	retangulo_gradiente_h(cx - meia, py - 1, cx - 14, py + 1, ouro, 0, ouro, alfa)
	retangulo_gradiente_h(cx + 14, py - 1, cx + meia, py + 1, ouro, alfa, ouro, 0)
	draw_set_alpha(alfa)
	draw_set_color(Color8(247, 222, 158))
	draw_triangle(cx - 10, py, cx, py - 7, cx + 10, py, false)
	draw_triangle(cx - 10, py, cx, py + 7, cx + 10, py, false)
	draw_set_color(Color8(150, 26, 20))
	draw_triangle(cx - 5, py, cx, py - 3.5, cx + 5, py, false)
	draw_triangle(cx - 5, py, cx, py + 3.5, cx + 5, py, false)
	draw_set_alpha(1)

func desenhar_espada(px: float, py: float, d: float) -> void:
	draw_set_color(Color8(205, 210, 220))
	draw_line_width(px, py, px + d * 34, py, 6)
	draw_triangle(px + d * 34, py - 3, px + d * 34, py + 3, px + d * 46, py, false)
	draw_set_color(Color8(255, 210, 90))
	draw_line_width(px, py - 12, px, py + 12, 5)
	draw_set_color(Color8(110, 60, 30))
	draw_line_width(px - d * 16, py, px, py, 4)
	draw_set_color(Color8(255, 210, 90))
	draw_circle(px - d * 19, py, 4, false)


func desenhar_tocha(px: float, py: float, alfa := 1.0) -> void:
	draw_set_alpha(alfa)
	draw_set_color(Color8(40, 40, 46))
	draw_rectangle(px - 12, py - 4, px + 12, py + 10, false)
	draw_set_color(Color8(80, 48, 24))
	draw_rectangle(px - 5, py + 10, px + 5, py + 120, false)
	var f := sin(current_time() / 80.0) * 2 + randf_range(-1.5, 1.5)
	gpu_set_blendmode(bm_add)
	draw_set_alpha(0.06 * alfa)
	draw_set_color(Color8(255, 130, 30))
	for i in range(1, 8):
		draw_circle(px, py - 24, 12 * i + f, false)
	gpu_set_blendmode(bm_normal)
	draw_set_alpha(alfa)
	draw_set_color(Color8(255, 110, 20))
	draw_circle(px, py - 6, 11, false)
	draw_triangle(px - 12, py - 4, px + 12, py - 4, px + f, py - 54 + f, false)
	draw_set_color(Color8(255, 200, 70))
	draw_triangle(px - 7, py - 4, px + 7, py - 4, px + f * 0.6, py - 36, false)
	draw_set_color(Color8(255, 245, 190))
	draw_triangle(px - 3, py - 4, px + 3, py - 4, px, py - 20, false)
	draw_set_alpha(1)


# Texto "amaldiçoado": aparece letra por letra, com tremor, brilho vermelho
# e falhas (glitch). Retorna o tempo em que a última letra termina de surgir.
func txt_amaldicoado(cx: float, cy: float, s: String, f: int, cor: Color, t: float, intervalo: float, esc := 1.0, alfa := 1.0) -> float:
	var n := s.length()
	var larg := txt_largura(s, f, esc)
	var px := cx - larg / 2.0
	var vermelho := Color8(150, 8, 20)
	var glitch := randi_range(0, 70) == 0
	for i in range(1, n + 1):
		var c := s[i - 1]
		var w := txt_largura(c, f, esc)
		var ti := t - (i - 1) * intervalo
		if ti > 0 and c != " ":
			var a := clampf(ti / 14.0, 0, 1)
			if ti < 22 and randi_range(0, 3) == 0:
				a *= 0.35
			var treme := maxf(0.0, 1.0 - ti / 30.0) * 6.0
			var ox := randf_range(-treme, treme) + (randf_range(-5, 5) if glitch else 0.0)
			var oy := randf_range(-treme, treme) + maxf(0.0, 1.0 - ti / 18.0) * -10.0
			# v1.18: TRAVADAS — a escala anda em degraus de 10%: cada tamanho de
			# fonte novo rasteriza os glifos de novo (antes ~40 tamanhos por título,
			# 15-28 ms por quadro no PC na tela VOCÊ MORREU; no celular, engasgos)
			var e := esc * snappedf(1.0 + maxf(0.0, 1.0 - ti / 16.0) * 0.6, 0.1)
			var lx := px + w / 2.0 + ox
			gpu_set_blendmode(bm_add)
			var pulso := 0.45 + 0.25 * sin(current_time() / 140.0 + i)
			txt(lx - 3, cy + oy, c, f, vermelho, a * pulso * alfa, fa_center, fa_middle, e * 1.04)
			txt(lx + 3, cy + oy, c, f, vermelho, a * pulso * alfa, fa_center, fa_middle, e * 1.04)
			gpu_set_blendmode(bm_normal)
			txt(lx + 4, cy + oy + 4, c, f, c_black, a * 0.8 * alfa, fa_center, fa_middle, e)
			var cor_l := c_white if ti < 8 else cor
			txt(lx, cy + oy, c, f, cor_l, a * alfa, fa_center, fa_middle, e)
		px += w
	desenho_resetar()
	return (n - 1) * intervalo + 30


# ----- Imagens externas (logo, aviso, cutscene) -----
static func imagem_carregar(arq: String) -> Texture2D:
	var caminho := "res://assets/data/" + arq
	if not ResourceLoader.exists(caminho):
		return null
	return load(caminho)


# Desenha a imagem inteira dentro do retângulo, centralizada, sem cortar
func imagem_desenhar_ajustada(tx: Texture2D, px: float, py: float, w: float, h: float, alfa := 1.0, zoom := 1.0) -> void:
	if tx == null:
		return
	var sw := float(tx.get_width())
	var sh := float(tx.get_height())
	var e := minf(w / sw, h / sh) * zoom
	var f := gpu_get_texfilter()
	gpu_set_texfilter(true)
	G.pen.textura(tx, px + (w - sw * e) / 2.0, py + (h - sh * e) / 2.0, sw * e, sh * e, c_white, alfa)
	gpu_set_texfilter(f)


# Logo do jogo centralizada em (cx, cy) com a altura pedida
func logo_desenhar(cx: float, cy: float, altura: float, alfa := 1.0) -> bool:
	if G.logo_img == null:
		return false
	var e := altura / float(G.logo_img.get_height())
	var f := gpu_get_texfilter()
	gpu_set_texfilter(true)
	G.pen.textura(G.logo_img, cx - G.logo_img.get_width() * e / 2.0, cy - altura / 2.0, G.logo_img.get_width() * e, altura, c_white, alfa)
	gpu_set_texfilter(f)
	return true


# =====================================================================
# scr_camera: câmera controlada por código
# =====================================================================
func sala_preparar() -> void:
	G.cam_snap = true
	G.camera_zoom = 1
	G.cam_zoom_atual = 1
	G.hitstop = 0
	G.lenta_t = 0
	G.lenta_fator = 1
	G.cam_lim_esq = 0
	G.cam_lim_dir = G.room_width
	G.fala_espera = 0
	ambientes_parar()
	if G.room == "rm_menu":
		audio_cena_definir("titulo")
		# durante o vídeo do estúdio a trilha do menu espera (o vídeo tem som próprio)
		if not G.video_intro_ativo:
			musica("bgm_main_menu")
		return
	if not instance_exists("obj_loading"):
		audio_cena_definir("fase")
		musica(musica_fase())
	# voltando do checkpoint: o que ficou para trás não renasce
	sala_limpar_checkpoint()
	# Fase 1: tempestade, fundo HD e vila em chamas
	if G.room == "Room1" and not instance_exists("obj_clima"):
		instance_create_depth(0, 0, -200, "obj_clima")
	# Fase 1: o CENÁRIO desenhado por código (casas, igreja, torre, ponte...)
	# no lugar da pintura de fundo (a camada de tiles "fundo" nem é criada:
	# G._criar_tiles). "longe" (céu e montanhas) atrás do clima de guerra
	# (397); "perto" (a vila com fogo, fumaça e janelas) na frente dele.
	if G.room == "Room1" and not instance_exists("obj_vila") and cenario_carregar():
		var longe = instance_create_depth(0, 0, 405, "obj_vila")
		longe.camada = "longe"
		instance_create_depth(0, 0, 396, "obj_vila")
	# Fase 2: cenário de fundo que preenche toda a tela
	if G.room == "Room2" and not instance_exists("obj_cenario"):
		instance_create_depth(0, 0, 450, "obj_cenario")
	# clima de guerra (flechas incendiárias, catapultas, brasas e cinzas)
	if (G.room == "Room1" or G.room == "Room2") and not instance_exists("obj_guerra"):
		instance_create_depth(0, 0, 397, "obj_guerra")
	# abismos mortais e plataformas (Castlevania), na frente do chão e atrás dos personagens
	if (G.room == "Room1" or G.room == "Room2") and not instance_exists("obj_terreno"):
		instance_create_depth(0, 0, 280, "obj_terreno")


# implementado em Lib (scr_cenario)
func sala_limpar_checkpoint() -> void:
	pass


# CENÁRIO DA FASE 1 desenhado por código (ferramentas/gerar_cenario.ps1):
# atlas cenario_fase1.png + cenario_fase1.json (peças, âncoras dos efeitos
# e disposição da fase), os mesmos da versão PC. Carregado uma vez.
static var cen: Dictionary = {}
static var cen_tex: Texture2D = null


static func cenario_carregar() -> bool:
	if not cen.is_empty():
		return true
	if not ResourceLoader.exists("res://assets/data/cenario_fase1.png") or not FileAccess.file_exists("res://assets/data/cenario_fase1.json"):
		return false
	cen_tex = load("res://assets/data/cenario_fase1.png")
	var d = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/cenario_fase1.json"))
	if d == null or cen_tex == null:
		return false
	cen = d
	return true


# Peças do Alex (paredes, ruínas, chão e ilhas): ferramentas/gerar_pecas.ps1
static var atlas_pecas: Dictionary = {}
static var pecas_tex: Texture2D = null


static func pecas_carregar() -> bool:
	if not atlas_pecas.is_empty():
		return true
	if not ResourceLoader.exists("res://assets/data/pecas_fase1.png") or not FileAccess.file_exists("res://assets/data/pecas_fase1.json"):
		return false
	pecas_tex = load("res://assets/data/pecas_fase1.png")
	var d = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/pecas_fase1.json"))
	if d == null or pecas_tex == null:
		return false
	atlas_pecas = d["pecas"]
	return true


# Tamanho da visão em pixels do mundo
static func camera_tamanho() -> Array:
	var h := minf(G.room_height, CAMERA_ALTURA / maxf(0.5, G.cam_zoom_atual + G.cam_soco))     # v1.20: + o soco de zoom, sem suavização
	var w := minf(G.room_width, h * G.tela_aspecto)
	return [w, h]


# Chamado no End Step do jogador, DEPOIS do movimento
static func camera_atualizar(alvo) -> void:
	if not G.existe(alvo):
		return
	# v1.20: CÂMERA DE COMBATE — com inimigo por perto ela fecha um pouco e puxa o
	# enquadramento para o duelo; cada pancada dá um "soco" de zoom (camera_soco)
	var perto := 0
	var soma_dx := 0.0
	if not G.cam_snap:
		for ini in G.todos("obj_inimigo_base"):
			if ini.morrendo:
				continue
			var ddx: float = ini.x - alvo.x
			if absf(ddx) < 300.0 and absf(ini.y - alvo.y) < 170.0:
				perto += 1
				soma_dx += ddx
	else:
		G.cam_combate = 0.0
		G.cam_foco_x = 0.0
		G.cam_soco = 0.0
	G.cam_combate = lerp_dt(G.cam_combate, 1.0 if perto > 0 else 0.0, 0.035)
	G.cam_foco_x = lerp_dt(G.cam_foco_x, clampf(soma_dx / maxf(1.0, perto) * 0.3, -64.0, 64.0), 0.045)
	G.cam_soco *= pow(0.84, G.dt_real)
	if G.cam_soco < 0.002:
		G.cam_soco = 0.0
	var zoom_alvo := G.camera_zoom * (1.0 + 0.07 * camera_forca() * G.cam_combate)
	G.cam_zoom_atual = zoom_alvo if G.cam_snap else lerp_dt(G.cam_zoom_atual, zoom_alvo, 0.12)
	var tam := camera_tamanho()
	var w: float = tam[0]
	var h: float = tam[1]
	# "olhar à frente": a câmera mostra mais do lado para onde o herói corre.
	# Ela desliza devagar (menos que a velocidade da corrida) e só quando ele
	# anda de fato: virar de lado não arremessa a tela, e o herói não parece
	# "teletransportar" para trás ao trocar de direção.
	var frente: float = alvo.facing if ("facing" in alvo) else 1.0
	var vh: float = alvo.velh if ("velh" in alvo) else 0.0
	if absf(vh) > 0.5:
		G.cam_frente_alvo = signf(vh) * 28.0     # v1.13: 40 -> 28 (a visão ficou menor)
	if G.cam_snap:
		G.cam_frente_alvo = frente * 28.0
		G.cam_frente = G.cam_frente_alvo
	else:
		var falta := G.cam_frente_alvo - G.cam_frente
		var passo := minf(absf(falta) * 0.05 + 0.05, 0.85) * G.dt_real
		G.cam_frente += clampf(falta, -passo, passo)
	var tx := clampf(alvo.x + G.cam_frente + G.cam_foco_x - w / 2.0, 0, G.room_width - w)
	# arena fechada (mini-boss / boss): a câmera fica entre as muralhas
	var lo := maxf(0, G.cam_lim_esq)
	var hi := minf(G.room_width, G.cam_lim_dir)
	if hi - lo <= w:
		tx = clampf((lo + hi) / 2.0 - w / 2.0, 0, G.room_width - w)
	else:
		tx = clampf(tx, lo, hi - w)
	var ty := clampf(alvo.y - h * 0.64, 0, G.room_height - h)
	# v1.20: sobre as pontes que desabam a câmera desce e mostra o abismo
	G.cam_baixo = G.cam_baixo_alvo if G.cam_snap else lerp_dt(G.cam_baixo, G.cam_baixo_alvo, 0.05)
	ty += G.cam_baixo
	if G.cam_snap:
		G.cam_x = tx
		G.cam_y = ty
		G.cam_snap = false
	else:
		G.cam_x = lerp_dt(G.cam_x, tx, 0.12)
		G.cam_y = lerp_dt(G.cam_y, ty, 0.10)
	# tremor de impacto (desligado na qualidade BAIXA)
	var sx := 0.0
	var sy := 0.0
	if G.camera_impact > 0:
		var f := G.camera_impact * 0.5 * camera_forca()     # v1.21: treme em qualquer qualidade visual
		sx = randf_range(-f, f)
		sy = randf_range(-f, f)
	# terremoto (especiais que batem no chão): tremor longo, mais vertical
	if G.terremoto > 0:
		var q := minf(1.0, 0.75 * camera_forca())
		var ft := minf(G.terremoto, 30) * 0.2 * q
		sx += randf_range(-ft, ft) * 0.7
		sy += randf_range(-ft, ft) * 1.2
	# "chute" do golpe (camera_empurrar): fica parado no hit-stop e volta depois
	sx += G.cam_chute_x
	sy += G.cam_chute_y
	var amort := pow(0.78, G.dt)
	G.cam_chute_x *= amort
	G.cam_chute_y *= amort
	if absf(G.cam_chute_x) < 0.05:
		G.cam_chute_x = 0
	if absf(G.cam_chute_y) < 0.05:
		G.cam_chute_y = 0
	G.view_w = w
	G.view_h = h
	# arredonda para o pixel da TELA (não do mundo): sem tremido de 1-2 px
	var k := maxf(1.0, G.gui_h / h)
	G.view_x = round(clampf(G.cam_x + sx, 0, G.room_width - w) * k) / k
	G.view_y = round(clampf(G.cam_y + sy, 0, G.room_height - h + G.cam_baixo) * k) / k
