extends Node
# =====================================================================
#  G — o "motor" do jogo e as variáveis global.* do GameMaker
#  * laço fixo de 60 (ou 30) passos por segundo: Begin Step, Step,
#    End Step, animação (Animation End) e troca de sala, como no GameMaker
#  * instâncias, hierarquia de objetos, ativar/desativar (pausas)
#  * salas (instâncias, camadas de tiles e cor de fundo) vindas do conversor
#  * colisão por caixas, câmera, desenho em camadas, entrada, áudio e fontes
# =====================================================================


# ---------------------------------------------------------------------
# OBJETOS: pai, sprite, máscara e eventos (do projeto GameMaker)
# letras dos eventos: s step, b begin step, e end step, a animation end,
# d draw, f draw end, g draw gui, r room start, c clean up
# ---------------------------------------------------------------------
const PAIS := {
	"obj_alquimista": "obj_inimigo_02", "obj_aranha": "obj_inimigo_base", "obj_barril": "obj_caixote",
	"obj_besta_elite": "obj_inimigo_01", "obj_boss_01": "obj_inimigo_base", "obj_caixote": "obj_destrutivel",
	"obj_coluna_quebrada": "obj_coluna", "obj_esqueleto": "obj_inimigo_01", "obj_esqueleto_elite": "obj_esqueleto",
	"obj_estatua": "obj_inimigo_base", "obj_inimigo_01": "obj_inimigo_base", "obj_inimigo_02": "obj_inimigo_base",
	"obj_inimigo_03": "obj_inimigo_01", "obj_inimigo_base": "obj_entidade", "obj_lampiao": "obj_destrutivel",
	"obj_mini_boss": "obj_inimigo_base", "obj_muro_segredo": "obj_parede_quebravel", "obj_parede_quebravel": "obj_destrutivel",
	"obj_player": "obj_entidade", "obj_porco": "obj_inimigo_base", "obj_ruina_fundo": "obj_muralha_fundo",
	"obj_solido": "obj_chao",
}

const DEF := {
	"obj_alquimista": ["spr_inimigo02_parado", ""], "obj_aranha": ["spr_aranha_parada", "spr_mascara_aranha"],
	"obj_balaustrada": ["spr_balaustrada", ""], "obj_barril": ["spr_barril", ""], "obj_bau": ["spr_bau", ""],
	"obj_besta_elite": ["spr_inimigo01_parado", ""], "obj_bola_fogo": ["spr_boss_01_bola_de_fogo", "spr_hitbox"],
	"obj_boss_01": ["spr_boss_01", "spr_mascara_boss"], "obj_caixote": ["spr_caixote", ""],
	"obj_caverna": ["spr_caverna", ""], "obj_chao": ["spr_chao", ""], "obj_plataforma": ["spr_chao", ""], "obj_checkpoint": ["spr_hitbox", ""],
	"obj_coluna": ["spr_coluna", ""], "obj_coluna_quebrada": ["spr_coluna", ""], "obj_espinhos": ["spr_espinhos", ""],
	"obj_esqueleto": ["spr_esqueleto_parado", "spr_mascara_esqueleto"], "obj_esqueleto_elite": ["spr_esqueleto_parado", ""],
	"obj_estatua": ["spr_estatua", "spr_mascara_estatua"], "obj_inimigo_01": ["spr_inimigo01_parado", "spr_mascara_inimigo"],
	"obj_inimigo_02": ["spr_inimigo02_parado", "spr_mascara_arqueiro"], "obj_inimigo_03": ["spr_inimigo01_parado", ""],
	"obj_lampiao": ["spr_lampiao", ""], "obj_mato": ["spr_mato", ""], "obj_mini_boss": ["spr_inimigo01_parado", ""],
	"obj_morador": ["spr_morador_parado", ""], "obj_muralha": ["spr_muralha", ""], "obj_muralha_fundo": ["spr_muralha", ""],
	"obj_muro_segredo": ["spr_muro_segredo", ""], "obj_nevoa_veneno": ["spr_nevoa_veneno", ""],
	"obj_parede_quebravel": ["spr_parede_rachada", ""], "obj_pedras": ["spr_pedras", ""], "obj_placa": ["spr_placa", ""],
	"obj_player": ["spr_player_idle", "spr_mascara_player"], "obj_porco": ["spr_porco_parado", "spr_mascara_porco"],
	"obj_portao": ["spr_portao", ""], "obj_ruina_fundo": ["spr_muralha", ""], "obj_solido": ["spr_chao", ""],
	"obj_tocha": ["spr_tocha", ""], "obj_tronco": ["spr_tronco", ""], "obj_viga_fogo": ["spr_viga", ""],
}

const INVISIVEIS := ["obj_chao", "obj_solido", "obj_plataforma"]

const EVENTOS_PROPRIOS := {
	"obj_aranha": "sd", "obj_aviso": "sg", "obj_balaustrada": "d", "obj_bau": "sd", "obj_bola_fogo": "sd",
	"obj_boss_01": "seadg", "obj_bumerangue": "sd", "obj_caixote": "sd", "obj_caverna": "sd", "obj_cenario": "sdf",
	"obj_benchmark": "sgc", "obj_chama_sylla": "sd", "obj_checkpoint": "sd", "obj_clima": "sf", "obj_coluna": "d", "obj_cutscene": "sgc",
	"obj_destrutivel": "sc", "obj_dialogo": "sgc", "obj_entidade": "e", "obj_espinhos": "sd", "obj_esqueleto": "s",
	"obj_essencia": "sd", "obj_estatua": "sd", "obj_fagulha": "sd", "obj_fala": "sd", "obj_final": "sg",
	"obj_flecha": "sd", "obj_fogo_chao": "sd", "obj_frasco_veneno": "sd", "obj_fundo_hd": "d", "obj_fx": "sd",
	"obj_galho": "sd", "obj_game_over": "sg", "obj_inimigo_01": "sad", "obj_inimigo_02": "sad", "obj_inimigo_base": "e",
	"obj_lampiao": "sd", "obj_loading": "srg", "obj_magia": "sd", "obj_menu": "sgc", "obj_menu_armas": "sgc",
	"obj_mini_boss": "sadg", "obj_morador": "sd", "obj_muralha": "dc", "obj_muralha_fundo": "d", "obj_nevoa_veneno": "sd",
	"obj_orb": "sd", "obj_parede_magica": "sdc", "obj_portao_trancado": "sdc", "obj_qte": "sgc", "obj_mapa": "sg", "obj_perfil": "sg", "obj_parede_quebravel": "d", "obj_pausa": "sgc", "obj_pedras": "d",
	"obj_placa": "sdf", "obj_player": "seadg", "obj_poca_veneno": "sd", "obj_popup": "sd", "obj_porco": "sad",
	"obj_portao": "d", "obj_raiz": "sd", "obj_resultado": "sg", "obj_sangue": "sd", "obj_save_menu": "sgc",
	"obj_save_point": "sd", "obj_sistema": "berg", "obj_tocha": "sd", "obj_tronco": "d", "obj_viga_fogo": "sd",
	"obj_vila": "sd", "obj_mato_lote": "sd", "obj_guerra": "sdf", "obj_terreno": "sd",
}

# ---------------------------------------------------------------------
# VARIÁVEIS GLOBAIS (global.* do GameMaker)
# ---------------------------------------------------------------------
var globais_ok := false
var nome_guerreiro := "Twilight Vetrus"
var dificuldade := 1
var save_slot_atual := 1
var capitulo := 1
var checkpoint_ativo := false
var checkpoint_room := ""
var checkpoint_x := 0.0
var checkpoint_y := 0.0
var vida_carregada := -1.0
var transicao_fase := false
var jogo_finalizado := false
var intro_vista := false
var ultimo_x := 0.0
var ultimo_y := 0.0
var ultima_vida := 100.0

var combo := 0
var combo_tempo := 0.0
var attacks_total := 0
var hits_total := 0
var last_hit_flash := 0.0
var last_hit_damage := 0.0
var camera_impact := 0.0
var camera_zoom := 1.0
var terremoto := 0.0

var inimigos_derrotados := 0
var orbs := 0.0
var orbs_coletados := 0.0
var espada_nivel := 1
var tempo_jogo := 0.0
var abertos: Array = []
var marca := {}

var hitstop := 0.0
var lenta_t := 0.0
var lenta_fator := 1.0
var dt_real := 1.0
var dt := 1.0

var cam_x := 0.0
var cam_y := 0.0
var video_intro_ativo := false  # o vídeo do estúdio está passando (abertura)
var cam_frente := 40.0          # "olhar à frente" atual da câmera (desliza)
var cam_frente_alvo := 40.0
var cam_chute_x := 0.0         # "chute" da câmera na direção do golpe (volta aos poucos)
var cam_chute_y := 0.0
var fatal_t := 0.0             # intervalo da câmera lenta do golpe fatal
var cam_zoom_atual := 1.0
var cam_snap := true
var cam_baixo := 0.0            # v1.20: quanto a câmera desce além do fim da sala (pontes que desabam)
var cam_baixo_alvo := 0.0
var cam_combate := 0.0          # v1.20: 0..1, quanto a câmera está "em duelo" (fecha e enquadra o inimigo)
var cam_foco_x := 0.0           # v1.20: desvio da câmera na direção dos inimigos próximos
var cam_soco := 0.0             # v1.20: "soco" de zoom a cada pancada (some rápido)
var cam_lim_esq := 0.0
var cam_lim_dir := 100000.0
var fala_espera := 0.0
var grito_espera := 0.0          # v1.19: um grito com balão por leva de inimigos
var fala_batalha_room := ""      # v1.19: fase em que Twilight já fez a fala de batalha
var veu_t := 0.0                 # v1.19: véu de transição entre telas (V117.transicao_revelar)
var veu_dur := 0.0
var _no_veu: Node2D              # camada própria, por cima da GUI e dos botões de toque
var _alvo_veu = null
var orb_som_t := 0.0
var orb_seq := 0

var tela_aspecto := 16.0 / 9.0
var debug_hitbox := false

var teclas: Array = []
var botoes: Array = []
var inp_segurado: Array = []
var inp_apertado: Array = []
var inp_pad_apertado: Array = []
var inp_cima := false
var pad_slot := -1
var pad_desc := ""
var pad_botoes := 0
var usando_pad := false
var usando_toque := false
var pad_eixo := 0.0
var esquiva_stick := 0
var eixo_dir_antes := 0.0
var orbs_fx := 0.0
var essencia := 3
var essencia_coletada := 0
var essencia_fx := 0.0
var bloqueio_input := 0.0
var nav_cima := false
var nav_baixo := false
var nav_esq := false
var nav_dir := false
var nav_ok := false
var nav_voltar := false
var nav_seg: Array = [0.0, 0.0, 0.0, 0.0]

var cfg_qualidade := 2
var cfg_fps := 1
var cfg_volume := 1.0
var cfg_vol_musica := 0.75
var cfg_vol_efeitos := 1.0
var cfg_fundo_hd := 1
var cfg_tutorial := 1
var cfg_toque_tam := 1          # tamanho dos botões de toque (0 pequeno, 1 médio, 2 grande)
var cfg_toque_opac := 0.55      # opacidade dos botões de toque
var cfg_vibrar := 1             # vibração ao levar dano / impactos fortes
# v1.21 — HUD personalizada e câmera de ação
var cfg_hud_modo := 0           # 0 = 2 dedos (polegares), 1 = 4 dedos (garra), 2 = 8 dedos (um botão por golpe)
var cfg_hud_tam := 1.0          # tamanho da HUD de toque (0.6 a 1.6)
var cfg_hud_pos := {}           # "modo_botão" -> Vector2: quanto o jogador arrastou cada botão
var cfg_camera_acao := 2        # 0 suave, 1 normal, 2 intensa (não depende da qualidade visual)
var cfg_padrao_v121 := 0        # 1 = o padrão MÍNIMO do celular já foi aplicado uma vez
# v1.14: perfis de desempenho para celulares (ver Desempenho)
var cfg_desempenho := 0         # 0 automático, 1 mínimo, 2 leve, 3 equilibrado, 4 máximo, 5 personalizado
var cfg_resolucao := 0          # 0 a da tela, 1 reduzida (720p)
var nivel_desempenho := 4       # nível em uso (1 a 4)
var nivel_auto := 0             # nível que o automático encontrou (salvo; 0 = ainda não mediu)
var cenario_economico := false  # nível MÍNIMO: sem as fileiras do fundo nem os incêndios ao longe
# v1.14: escadas de mão / cordas / correntes da sala (obj_terreno) e a chave do portão
var escalaveis: Array = []
var chave_portao := false
var portao_visto := false
var arena_chave := false
# áudio (scr_audio)
var audio_ok := false
var audio_cena := "titulo"
var sfx := {}
var sfx_tocando: Array = []
var sfx_saindo: Array = []
var streams := {}
var musica_nome := ""
var musica_inst = null
var musica_saindo: Array = []
var musica_alvo := 0.0
var ambientes := {}
var audio_pausa := false
var msg_som_t := -100000.0     # v1.16: último toque do sfx_important_message (ms)
# v1.17 (V117): perfil e conquistas, sequência de golpes e o mapa
var perfil := {}
var conquistas_fila: Array = []
var qte_alvo = null
var dano_na_luta := 0.0
var img_mapa: Texture2D = null
var texto_digitado := ""        # letras digitadas no teclado de verdade (nome do perfil)
var texto_tick := ""
var _roda_ev := 0
var roda := 0                   # rodinha do mouse neste passo (-1 para cima, 1 para baixo)

# imagens externas
var logo_img: Texture2D = null

# ---------------------------------------------------------------------
# RUNTIME
# ---------------------------------------------------------------------
var pen: Pen
var lib                          # instância "solta" de Lib (funções globais fora dos objetos)
var cor_desenho := Color(1, 1, 1)
var alfa_desenho := 1.0

var room := ""
var room_width := 1366.0
var room_height := 768.0
var view_x := 0.0
var view_y := 0.0
var view_w := 1366.0
var view_h := 768.0
var gui_w := 1280.0
var gui_h := 720.0
var mundo_k := 1.0
var velocidade_jogo := 60.0

var instancias: Array = []
var listas := {}
var _scripts := {}
var _cadeias := {}
var _eventos := {}
var _proximo_id := 100001
var _sala_pendente := ""
var _acc := 0.0
var _teve_passo := false

var _no_mundo: Node2D
var _camada_fim: CanvasLayer
var _no_fim: Node2D
var _camada_gui: CanvasLayer
var _no_gui: Node2D
var toque: Node                 # controles de toque (TouchControls)
var _tiles: Array = []          # RIDs das camadas de tiles e do fundo

# chão (obj_chao e filhos) em cache para as colisões
var chao_sujo := true
var _chao := PackedFloat64Array()
var _chao_inst: Array = []
var _chao_n := 0

# fontes
var fontes: Array = []
const FONTE_EM := [92.0, 46.0, 27.0, 19.0, 15.0]

# entrada (teclado, mouse e controle)
var _teclas_seg := {}
var _teclas_ev := {}
var _teclas_tick := {}
var _alguma_tecla_ev := false
var alguma_tecla := false
var ultima_tecla := 0
var _mouse_seg := false
var _mouse_ev := false
var _mouse_dir_ev := false
var mouse_apertado := false
var mouse_dir_apertado := false
var mouse_segurado := false
var _ponteiro := Vector2(-1, -1)  # última posição do mouse ou do 1º dedo (coordenadas da GUI)
var voltar_ev := false            # botão VOLTAR do Android (ou da tela)
var voltar_apertado := false
var _pad_antes := {}
var _pad_agora := {}
var pausa_auto := false           # o app foi para o fundo: o jogo pausa sozinho

# som (instâncias de áudio)
class SomInst:
	var player: AudioStreamPlayer
	var stream: AudioStream
	var ger := 0
	var ganho := 1.0
	var alvo := 1.0
	var vel := 0.0
	var parado := false

var _players: Array = []
var _player_ger: Array = []
var _player_inst: Array = []
var _sons_ativos: Array = []
var _bus_master := 0


func _ready() -> void:
	if "checar" in OS.get_cmdline_user_args():
		set_process(false)
		return
	marca_inicio("motor pronto")
	process_mode = Node.PROCESS_MODE_ALWAYS
	randomize()
	pen = Pen.new()
	_no_mundo = Node2D.new()
	_no_mundo.name = "Mundo"
	add_child(_no_mundo)
	_camada_fim = CanvasLayer.new()
	_camada_fim.layer = 1
	_camada_fim.follow_viewport_enabled = true
	add_child(_camada_fim)
	_no_fim = Node2D.new()
	_camada_fim.add_child(_no_fim)
	_criar_pos()
	_camada_gui = CanvasLayer.new()
	_camada_gui.layer = 3
	add_child(_camada_gui)
	_no_gui = Node2D.new()
	_camada_gui.add_child(_no_gui)
	var camada_toque := CanvasLayer.new()
	camada_toque.layer = 4
	add_child(camada_toque)
	toque = load("res://src/core/touch_controls.gd").new()
	camada_toque.add_child(toque)
	var camada_veu := CanvasLayer.new()
	camada_veu.layer = 5
	add_child(camada_veu)
	_no_veu = Node2D.new()
	camada_veu.add_child(_no_veu)
	marca_inicio("camadas")
	_carregar_fontes()
	marca_inicio("fontes")
	for i in 48:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
		_player_ger.append(0)
		_player_inst.append(null)
	Input.joy_connection_changed.connect(_controle_mudou)
	lib = load("res://src/core/lib.gd").new()
	marca_inicio("lib")
	UI.precarregar()
	marca_inicio("arte da interface")
	# os scripts dos objetos carregam em segundo plano (ver _fundo_passo)
	_fundo_iniciar()
	_atualizar_tela()
	# medidor de desempenho no aparelho: só com o arquivo user://perf.ligado
	if FileAccess.file_exists("user://perf.ligado"):
		perf_ligado = true
		perf_log = true
	# ferramenta de teste automático (só quando pedida na linha de comando)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("teste="):
			prefixo_arquivos = "teste_"
			for f in ["save_slot1.ini", "save_slot2.ini", "save_slot3.ini", "config.ini"]:
				DirAccess.remove_absolute("user://teste_" + f)
			add_child(load("res://src/tools/teste.gd").new())
			if not a.begins_with("teste=intro"):
				lib.globais_iniciar()
				intro_vista = true
	# a primeira sala é o menu (como no GameMaker)
	_sala_pendente = "rm_menu"
	_trocar_sala()
	marca_inicio("sala do menu")


# tempo desde que o app abriu, por etapa da inicialização (no log)
var _inicio_quadros := 0


func marca_inicio(etapa: String) -> void:
	print("[inicio] %s: %d ms" % [etapa, Time.get_ticks_msec()])


# ---------------------------------------------------------------------
# PÓS-PROCESSAMENTO (só no mundo; o HUD fica por cima, sem efeito). v1.13:
# tons menos cartum (a mesma conta do sh_pos da versão PC): roxo neon apagado,
# saturação menor, curva de filme, sombras frias, luzes quentes e vinheta.
# Desligado na qualidade BAIXA.
# ---------------------------------------------------------------------
var _pos: ColorRect
var _pos_mat: ShaderMaterial

const _POS_SHADER := """shader_type canvas_item;
render_mode unshaded;
uniform sampler2D tela : hint_screen_texture, filter_linear;
uniform float saturacao = 0.78;
uniform float curva = 0.38;
uniform vec3 sombra = vec3(0.004, 0.012, 0.024);
uniform vec3 luz = vec3(1.05, 1.00, 0.92);
uniform float vinheta = 0.42;
uniform float proporcao = 1.777;
void fragment() {
	vec3 c = texture(tela, SCREEN_UV).rgb;
	float mag = clamp(min(c.r, c.b) - c.g, 0.0, 1.0);
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(c, vec3(l) * vec3(1.02, 0.92, 1.10), mag * 0.5);
	l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, saturacao);
	c = mix(c, c * c * (3.0 - 2.0 * c), curva);
	l = dot(c, vec3(0.299, 0.587, 0.114));
	c *= mix(vec3(1.0), luz, smoothstep(0.35, 0.95, l));
	c += sombra * (1.0 - smoothstep(0.0, 0.45, l));
	vec2 d = (SCREEN_UV - 0.5) * vec2(proporcao, 1.0);
	float v = smoothstep(1.15, 0.35, length(d * vec2(0.62, 1.0)));
	c *= mix(1.0 - vinheta, 1.0, v);
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
"""


func _criar_pos() -> void:
	var camada := CanvasLayer.new()
	camada.layer = 2
	add_child(camada)
	_pos = ColorRect.new()
	_pos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pos.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sh := Shader.new()
	sh.code = _POS_SHADER
	_pos_mat = ShaderMaterial.new()
	_pos_mat.shader = sh
	_pos.material = _pos_mat
	camada.add_child(_pos)


func _atualizar_pos() -> void:
	# só nas fases (o menu tem o próprio visual) e fora da qualidade BAIXA
	var ligado := cfg_qualidade > 0 and room != "rm_menu" and room != ""
	_pos.visible = ligado
	if ligado:
		_pos_mat.set_shader_parameter("proporcao", gui_w / maxf(1.0, gui_h))
		# fase 2 (salão em chamas) um pouco mais quente; fase 1 (tempestade) mais fria
		_pos_mat.set_shader_parameter("sombra", Vector3(0.020, 0.010, 0.006) if room == "Room2" else Vector3(0.004, 0.012, 0.024))


func _carregar_fontes() -> void:
	var titulo: FontFile = load("res://assets/data/TeXGyreBonum-Bold.otf")
	var texto: FontFile = load("res://assets/data/DejaVuSerifCondensed-Bold.ttf")
	var reserva: FontFile = load("res://assets/data/DejaVuSerif-Bold.ttf")
	titulo.fallbacks = [reserva]
	texto.fallbacks = [reserva]
	fontes = [titulo, titulo, titulo, texto, texto]


# ---------------------------------------------------------------------
# LAÇO PRINCIPAL
# ---------------------------------------------------------------------
func _process(delta: float) -> void:
	if _inicio_quadros < 3:
		_inicio_quadros += 1
		marca_inicio("quadro %d (delta %.0f ms)" % [_inicio_quadros, delta * 1000])
	if _fundo_atual != "" or not _fundo_fila.is_empty() or _fundo_marcar:
		_fundo_passo()
	if perf_ligado:
		# perf_picos > 0 (ferramenta de teste): cada quadro mais lento que isto (ms)
		# é impresso com o que custou caro nele
		var acumulado := _perf
		if perf_picos > 0:
			_perf = {}
		var t0 := Time.get_ticks_usec()
		_process_jogo(delta)
		var dur := Time.get_ticks_usec() - t0
		if perf_picos > 0:
			if dur > perf_picos * 1000:
				var itens := []
				for k in _perf:
					itens.append([k, _perf[k]])
				itens.sort_custom(func(a, b): return a[1] > b[1])
				var s := ""
				for i in mini(8, itens.size()):
					s += "  %s=%.1f" % [itens[i][0], itens[i][1] / 1000.0]
				print("[pico] %.1fms sala=%s inst=%d%s" % [dur / 1000.0, room, instancias.size(), s])
			for k in _perf:
				acumulado[k] = acumulado.get(k, 0) + _perf[k]
			_perf = acumulado
		_perf_somar("PROCESS", dur)
		_perf_somar("#quadros", 1000)
		# medição no aparelho (arquivo user://perf.ligado): relatório no log a cada 4 s
		if perf_log:
			_perf_t += int(delta * 1000)
			if _perf_t >= 4000:
				print("[perf] sala=%s inst=%d fps=%d %s" % [room, instancias.size(), Engine.get_frames_per_second(), perf_relatorio()])
				_perf_t = 0
	else:
		# v1.19: tempo de trabalho do quadro (lógica + montar o desenho), sem a espera
		# pelo próximo quadro — o teste de desempenho usa para medir a folga da CPU
		var tq := Time.get_ticks_usec()
		_process_jogo(delta)
		quadro_trabalho_ms = (Time.get_ticks_usec() - tq) / 1000.0
	Desempenho.monitorar(delta)


func _process_jogo(delta: float) -> void:
	_atualizar_tela()
	velocidade_jogo = 30.0 if cfg_fps == 0 else 60.0
	# em 30 FPS a tela também é limitada a 30 (como o game_set_speed do GameMaker):
	# poupa bateria e deixa o ritmo dos quadros regular
	# v1.19: em 60 também limita (telas de 120 Hz alternavam quadros com 0 e 1 passo)
	var limite := 30 if cfg_fps == 0 else 60
	if Engine.max_fps != limite:
		Engine.max_fps = limite
	var passo := 1.0 / velocidade_jogo
	# v1.19: FLUIDEZ — o tempo de cada quadro oscila um pouco (33,2 / 33,5 ms...)
	# e o acumulador às vezes dava um quadro com 0 passos (imagem repetida) e o
	# seguinte com 2 (pulo). Quadro que durou quase N passos conta como N exatos.
	var d := minf(delta, 0.25)
	var passos_q := roundf(d / passo)
	if passos_q >= 1 and absf(d / passo - passos_q) < SNAP_TOLERANCIA:
		d = passos_q * passo
	_acc += d
	var n := 0
	# v1.18: TRAVADAS — no máximo 2 passos de lógica por quadro (antes 4). Um
	# quadro atrasado fazia o seguinte rodar 4 passos, que atrasava ainda mais
	# (espiral): o jogo dava "pulos". Agora, se atrasar, ele fica um instante
	# mais lento, como no GameMaker, em vez de engasgar.
	while _acc >= passo - 0.0005 and n < PASSOS_MAX:   # folga: restos de ponto flutuante do snap
		_acc -= passo
		_tick()
		n += 1
	if n >= PASSOS_MAX:
		_acc = minf(_acc, passo * 0.5)
	if n > 0:
		var t0 := Time.get_ticks_usec()
		_atualizar_pos()
		_desenhar()
		if perf_ligado:
			_perf_somar("DESENHO", Time.get_ticks_usec() - t0)
	_audio_fades(delta)


var fx_lotes := {}          # profundidade -> obj_fx que agrupa partículas (ver Lib.fx_em)
# v1.18: orçamento dos efeitos de combate (Lib.fx_orcamento)
var fx_recentes: Array = []  # [tipo, x, y, ms] dos decorativos recém-criados
var fx_carga := 0.0
var fx_carga_t := 0
var fx_flash_t := -1000
const PASSOS_MAX := 2          # passos de lógica por quadro, no máximo (ver _process_jogo)
const SNAP_TOLERANCIA := 0.12  # v1.19: fração de passo tratada como "no ritmo" (ver _process_jogo)
var perfil_salvar_t := 0.0     # v1.18: >0 = conquista esperando para ser gravada (V117.conquista)
var perf_ligado := false
var perf_log := false
var perf_picos := 0.0        # ms (só a ferramenta de teste liga)
var _perf := {}
var _perf_t := 0


func _perf_somar(chave: String, us: int) -> void:
	_perf[chave] = _perf.get(chave, 0) + us


func perf_relatorio() -> String:
	var itens := []
	for k in _perf:
		itens.append([k, _perf[k]])
	itens.sort_custom(func(a, b): return a[1] > b[1])
	var s := ""
	for i in mini(18, itens.size()):
		s += "  %s=%.1fms" % [itens[i][0], itens[i][1] / 1000.0]
	_perf = {}
	return s


func _tick_perf() -> void:
	_perf_somar("#ticks", 1000)
	var t0 := Time.get_ticks_usec()
	_entrada_comecar_tick()
	var lista := instancias.duplicate()
	for fase in ["b", "s", "e"]:
		for inst in lista:
			if inst._ativo and not inst._destruido and inst._ev.contains(fase):
				var t := Time.get_ticks_usec()
				match fase:
					"b":
						inst.ev_step_begin()
					"s":
						inst.ev_step()
					"e":
						inst.ev_step_end()
				_perf_somar(fase + ":" + inst.obj, Time.get_ticks_usec() - t)
	var ta := Time.get_ticks_usec()
	_animar_todos(lista)
	_perf_somar("animar", Time.get_ticks_usec() - ta)
	if _sala_pendente != "":
		_trocar_sala()
	_entrada_terminar_tick()
	_perf_somar("TICK", Time.get_ticks_usec() - t0)


# instâncias com Begin Step / Step / End Step (na ordem de criação)
var _ev_listas := {"b": [], "s": [], "e": []}


# Animação dos sprites. Quem não tem lógica (sem Step nem Animation End) só
# anima perto da câmera: o quadro dela só aparece no desenho.
func _animar_todos(lista: Array) -> void:
	var x1 := view_x - 300.0
	var x2 := view_x + view_w + 300.0
	for inst in lista:
		if inst.image_speed == 0.0 or inst.sprite_index == null or not inst._ativo or inst._destruido:
			continue
		if inst._anim_livre and (inst.x < x1 or inst.x > x2):
			continue
		inst._animar()


func _tick() -> void:
	if perf_ligado:
		_tick_perf()
		return
	_entrada_comecar_tick()
	# quem nasce durante o passo só age no próximo (as listas são copiadas antes)
	var lista := instancias.duplicate()
	var lb: Array = _ev_listas["b"].duplicate()
	var ls: Array = _ev_listas["s"].duplicate()
	var le: Array = _ev_listas["e"].duplicate()
	for inst in lb:
		if inst._ativo and not inst._destruido:
			inst.ev_step_begin()
	for inst in ls:
		if inst._ativo and not inst._destruido:
			inst.ev_step()
	for inst in le:
		if inst._ativo and not inst._destruido:
			inst.ev_step_end()
	_animar_todos(lista)
	if _sala_pendente != "":
		_trocar_sala()
	_entrada_terminar_tick()


func _atualizar_tela() -> void:
	var vis := get_viewport().get_visible_rect().size
	if vis.y <= 0:
		return
	gui_w = vis.x
	gui_h = vis.y
	tela_aspecto = gui_w / gui_h


# ---------------------------------------------------------------------
# DESENHO (Draw, Draw End e Draw GUI)
# ---------------------------------------------------------------------
func _desenhar() -> void:
	mundo_k = gui_h / maxf(1.0, view_h)
	get_viewport().canvas_transform = Transform2D(0.0, Vector2(mundo_k, mundo_k), 0.0, Vector2(-view_x * mundo_k, -view_y * mundo_k))
	var vx1 := view_x - 96.0
	var vx2 := view_x + view_w + 96.0
	var vy1 := view_y - 96.0
	var vy2 := view_y + view_h + 96.0
	# ----- mundo -----
	pen.escala_texto = mundo_k
	pen.blend_add = false
	pen.fog = false
	pen.filtro = false
	for inst in instancias:
		if inst._destruido or not inst._ativo:
			continue
		var tem_d: bool = inst._ev.contains("d")
		if not inst.visible or (not tem_d and inst.sprite_index == null):
			if inst._alvo_mundo != null:
				inst._alvo_mundo.limpar()
				inst._cache_padrao = []
			continue
		var z := clampi(-inst.depth, -4096, 4096)
		if inst._alvo_mundo == null:
			inst._alvo_mundo = Pen.Alvo.new(_no_mundo.get_canvas_item(), z, true)
		else:
			inst._alvo_mundo.definir_z(z)
		if not tem_d:
			# desenho padrão (draw_self): só se estiver na tela e se mudou
			var s: GMSprite = inst.sprite_index
			var ax := absf(inst.image_xscale)
			var ay := absf(inst.image_yscale)
			var r := maxf(s.w, s.h) * maxf(ax, ay)
			if inst.x + r < vx1 or inst.x - r > vx2 or inst.y + r < vy1 or inst.y - r > vy2:
				if not inst._cache_padrao.is_empty():
					inst._alvo_mundo.limpar()
					inst._cache_padrao = []
				continue
			var chave := [s, int(floor(inst.image_index)), inst.x, inst.y, inst.image_xscale, inst.image_yscale, inst.image_angle, inst.image_blend, inst.image_alpha]
			if chave == inst._cache_padrao:
				continue
			inst._cache_padrao = chave
		var td := Time.get_ticks_usec() if perf_ligado else 0
		pen.comecar(inst._alvo_mundo)
		inst.ev_draw()
		pen.terminar()
		if perf_ligado:
			_perf_somar("d:" + inst.obj, Time.get_ticks_usec() - td)
	# ----- Draw End -----
	for inst in instancias:
		if inst._destruido or not inst._ativo or not inst._ev.contains("f"):
			continue
		if inst._alvo_fim == null:
			inst._alvo_fim = Pen.Alvo.new(_no_fim.get_canvas_item(), clampi(-inst.depth, -4096, 4096), true)
		if not inst.visible:
			inst._alvo_fim.limpar()
			continue
		var tf := Time.get_ticks_usec() if perf_ligado else 0
		pen.comecar(inst._alvo_fim)
		inst.ev_draw_end()
		pen.terminar()
		if perf_ligado:
			_perf_somar("f:" + inst.obj, Time.get_ticks_usec() - tf)
	# ----- GUI -----
	pen.escala_texto = 1.0
	pen.blend_add = false
	pen.fog = false
	pen.filtro = true
	for inst in instancias:
		if inst._destruido or not inst._ev.contains("g"):
			continue
		var zg := clampi(int(round(-inst.depth / 2.6)), -4096, 4096)
		if inst._alvo_gui == null:
			inst._alvo_gui = Pen.Alvo.new(_no_gui.get_canvas_item(), zg, false)
		else:
			inst._alvo_gui.definir_z(zg)
		if not inst._ativo or not inst.visible:
			inst._alvo_gui.visivel(false)
			inst._cache_gui = null
			continue
		inst._alvo_gui.visivel(true)
		var chave_gui = inst.gui_chave()
		if chave_gui != null:
			chave_gui.append(gui_w)
			chave_gui.append(gui_h)
			if chave_gui == inst._cache_gui:
				continue
		inst._cache_gui = chave_gui
		var tg := Time.get_ticks_usec() if perf_ligado else 0
		pen.comecar(inst._alvo_gui)
		inst.ev_draw_gui_begin()
		inst.ev_draw_gui()
		inst.ev_draw_gui_end()
		pen.terminar()
		if perf_ligado:
			_perf_somar("g:" + inst.obj, Time.get_ticks_usec() - tg)
	# v1.19: a cortina que revela a tela nova (o GM desenha no Draw GUI End do obj_sistema)
	if _alvo_veu == null:
		_alvo_veu = Pen.Alvo.new(_no_veu.get_canvas_item(), 0, false)
	pen.comecar(_alvo_veu)
	if veu_t < veu_dur:
		V117.transicao_veu_desenhar()
	pen.terminar()
	pen.filtro = false
	if toque != null:
		toque.queue_redraw()


# ---------------------------------------------------------------------
# INSTÂNCIAS
# ---------------------------------------------------------------------
func cadeia_de(o: String) -> Array:
	if _cadeias.has(o):
		return _cadeias[o]
	var c := [o]
	var p: String = PAIS.get(o, "")
	while p != "":
		c.append(p)
		p = PAIS.get(p, "")
	_cadeias[o] = c
	return c


func _eventos_de(o: String) -> String:
	if _eventos.has(o):
		return _eventos[o]
	var e := ""
	for a in cadeia_de(o):
		e += EVENTOS_PROPRIOS.get(a, "")
	_eventos[o] = e
	return e


func _script_de(o: String) -> Script:
	if not _scripts.has(o):
		var caminho := "res://src/objects/%s.gd" % o
		if _fundo_atual == o:
			# já está sendo carregado em segundo plano: espera terminar
			_scripts[o] = ResourceLoader.load_threaded_get(caminho)
			_fundo_atual = ""
		else:
			_scripts[o] = load(caminho)
	return _scripts[o]


# ---------------------------------------------------------------------
# Scripts dos objetos carregados em SEGUNDO PLANO (uma thread), um por vez,
# enquanto o vídeo da abertura passa. Cada um custa ~0,3 s (o Godot reanalisa
# a biblioteca base); carregar todos antes da primeira imagem deixava ~10 s
# de tela preta no celular. Quem precisar de um antes, carrega na hora.
# ---------------------------------------------------------------------
var _fundo_fila: Array = []
var _fundo_atual := ""


func _fundo_iniciar() -> void:
	for o in EVENTOS_PROPRIOS.keys() + PAIS.keys() + DEF.keys():
		if not _scripts.has(o) and not _fundo_fila.has(o) and ResourceLoader.exists("res://src/objects/%s.gd" % o):
			_fundo_fila.append(o)


func _fundo_passo() -> void:
	if _fundo_atual != "":
		var caminho := "res://src/objects/%s.gd" % _fundo_atual
		var st := ResourceLoader.load_threaded_get_status(caminho)
		if st == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			return
		if st == ResourceLoader.THREAD_LOAD_LOADED and not _scripts.has(_fundo_atual):
			_scripts[_fundo_atual] = ResourceLoader.load_threaded_get(caminho)
		_fundo_atual = ""
	while not _fundo_fila.is_empty():
		var o: String = _fundo_fila.pop_front()
		if _scripts.has(o):
			continue
		ResourceLoader.load_threaded_request("res://src/objects/%s.gd" % o)
		_fundo_atual = o
		return
	if _fundo_marcar:
		_fundo_marcar = false
		marca_inicio("scripts em segundo plano prontos")


var _fundo_marcar := true


func criar(px: float, py: float, prof: int, o: String, pre: Dictionary = {}) -> GMObj:
	var inst: GMObj = _script_de(o).new()
	inst.obj = o
	inst.id = _proximo_id
	_proximo_id += 1
	inst._cadeia = cadeia_de(o)
	inst._ev = _eventos_de(o)
	inst._anim_livre = not (inst._ev.contains("s") or inst._ev.contains("b") or inst._ev.contains("e") or inst._ev.contains("a"))
	inst.x = px
	inst.y = py
	inst.xstart = px
	inst.ystart = py
	inst.depth = prof
	var d = DEF.get(o)
	if d != null:
		inst.sprite_index = Spr.por_nome(d[0])
		if d[1] != "":
			inst.mask_index = Spr.por_nome(d[1])
	if INVISIVEIS.has(o):
		inst.visible = false
	for k in pre:
		inst.set(k, pre[k])
	instancias.append(inst)
	for k in _ev_listas:
		if inst._ev.contains(k):
			_ev_listas[k].append(inst)
	for a in inst._cadeia:
		if not listas.has(a):
			listas[a] = []
		listas[a].append(inst)
	if inst._cadeia.has("obj_chao"):
		chao_sujo = true
	inst.ev_create()
	return inst


func destruir(inst: GMObj) -> void:
	if inst == null or inst._destruido:
		return
	inst._destruido = true
	if inst._ev.contains("c"):
		inst.ev_cleanup()
	instancias.erase(inst)
	for k in _ev_listas:
		if inst._ev.contains(k):
			_ev_listas[k].erase(inst)
	for a in inst._cadeia:
		listas[a].erase(inst)
	if inst._cadeia.has("obj_chao"):
		chao_sujo = true
	for alvo in [inst._alvo_mundo, inst._alvo_fim, inst._alvo_gui]:
		if alvo != null:
			alvo.liberar()
	inst._alvo_mundo = null
	inst._alvo_fim = null
	inst._alvo_gui = null


func existe(inst) -> bool:
	return inst != null and inst is GMObj and not inst._destruido and inst._ativo


func existe_obj(o: String) -> bool:
	for i in listas.get(o, []):
		if i._ativo:
			return true
	return false


func numero(o: String) -> int:
	var n := 0
	for i in listas.get(o, []):
		if i._ativo:
			n += 1
	return n


func achar(o: String, n := 0):
	var c := 0
	for i in listas.get(o, []):
		if i._ativo:
			if c == n:
				return i
			c += 1
	return null


func todos(o: String) -> Array:
	var r := []
	for i in listas.get(o, []):
		if i._ativo:
			r.append(i)
	return r


func mais_perto(px: float, py: float, o: String):
	var melhor = null
	var dm := INF
	for i in listas.get(o, []):
		if not i._ativo:
			continue
		var d: float = (i.x - px) * (i.x - px) + (i.y - py) * (i.y - py)
		if d < dm:
			dm = d
			melhor = i
	return melhor


# mundo_pausar / mundo_retomar
func desativar_todos(exceto: GMObj) -> void:
	for i in instancias:
		if i == exceto or i.obj == "obj_sistema" or i.obj == "obj_fundo_hd" or i.obj == "obj_benchmark":     # v1.19: o teste de desempenho nunca congela
			continue
		i._ativo = false
	chao_sujo = true


func ativar_todos() -> void:
	for i in instancias:
		i._ativo = true
	chao_sujo = true


func ativar_obj(o: String) -> void:
	for i in listas.get(o, []):
		i._ativo = true
	chao_sujo = true


# ---------------------------------------------------------------------
# SALAS
# ---------------------------------------------------------------------
func room_goto(nome: String) -> void:
	_sala_pendente = nome


func room_restart() -> void:
	_sala_pendente = room


func _trocar_sala() -> void:
	var nome := _sala_pendente
	_sala_pendente = ""
	for inst in instancias.duplicate():
		if not inst.persistent or not inst._ativo:
			destruir(inst)
	_limpar_tiles()
	room = nome
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/rooms/%s.json" % nome))
	room_width = float(d["w"])
	room_height = float(d["h"])
	view_x = 0.0
	view_y = 0.0
	if nome == "rm_menu":
		view_w = 1366.0
		view_h = 768.0
	else:
		view_w = LibBase.CAMERA_ALTURA * tela_aspecto
		view_h = LibBase.CAMERA_ALTURA
	if d.get("fundo") != null:
		_criar_fundo(d["fundo"])
	for t in d["tiles"]:
		_criar_tiles(t)
	var lote_mato = null
	for e in d["instancias"]:
		# os tufos de mato (centenas) vão para um objeto só
		if e["obj"] == "obj_mato":
			if lote_mato == null:
				lote_mato = criar(0.0, 0.0, 150, "obj_mato_lote")
			lote_mato.adicionar(float(e["x"]), float(e["y"]), float(e["sx"]), float(e["sy"]), float(e["rot"]), Color.html("#" + str(e["cor"])))
			continue
		criar(float(e["x"]), float(e["y"]), int(e["prof"]), e["obj"], {
			"image_xscale": float(e["sx"]), "image_yscale": float(e["sy"]), "image_angle": float(e["rot"]),
			"image_blend": Color.html("#" + str(e["cor"])), "image_index": float(e["img"])})
	for inst in instancias.duplicate():
		if not inst._destruido and inst._ativo and inst._ev.contains("r"):
			inst.ev_room_start()
	chao_sujo = true


func _limpar_tiles() -> void:
	for r in _tiles:
		RenderingServer.free_rid(r)
	_tiles.clear()


func _criar_fundo(f: Dictionary) -> void:
	if not f.get("visivel", true):
		return
	var ci := RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(ci, _no_mundo.get_canvas_item())
	RenderingServer.canvas_item_set_z_index(ci, clampi(-int(f["prof"]), -4096, 4096))
	RenderingServer.canvas_item_add_rect(ci, Rect2(-20000, -20000, 60000, 60000), Color.html("#" + str(f["cor"])))
	_tiles.append(ci)


func _criar_tiles(t: Dictionary) -> void:
	if not t.get("visivel", true):
		return
	# fase 1: a pintura de fundo deu lugar ao cenário desenhado por código (obj_vila)
	if room == "Room1" and t.get("nome", "") == "fundo" and ResourceLoader.exists("res://assets/data/cenario_fase1.png"):
		return
	# fase 2: a arte do salão em alta resolução (obj_cenario) no lugar dos tiles antigos
	if room == "Room2" and t.get("nome", "") == "fundo" and ResourceLoader.exists("res://assets/data/castelo_a.png"):
		return
	var s := Spr.por_nome(t["spr"])
	var tex := s.tex(0)
	var tw := float(t["tw"])
	var th := float(t["th"])
	var cols := int(t["colunas"])
	var w := int(t["w"])
	var h := int(t["h"])
	var dados: Array = t["dados"]
	var por_bloco := maxi(1, int(512.0 / tw))
	var z := clampi(-int(t["prof"]), -4096, 4096)
	var bx := 0
	while bx < w:
		var ci := RenderingServer.canvas_item_create()
		RenderingServer.canvas_item_set_parent(ci, _no_mundo.get_canvas_item())
		RenderingServer.canvas_item_set_z_index(ci, z)
		RenderingServer.canvas_item_set_default_texture_filter(ci, RenderingServer.CANVAS_ITEM_TEXTURE_FILTER_NEAREST)
		var tem := false
		for j in h:
			for i in range(bx, mini(w, bx + por_bloco)):
				var v := int(dados[j * w + i])
				if v == 0 or v < 0:
					continue
				var idx := v & 0x7FFFF
				if idx == 0:
					continue
				var sx := float(t["ox"]) + (idx % cols) * (tw + float(t["sepx"]))
				var sy := float(t["oy"]) + (idx / cols) * (th + float(t["sepy"]))
				var dw := tw
				var dh := th
				var dx := float(t["x"]) + i * tw
				var dy := float(t["y"]) + j * th
				if v & (1 << 28):
					dx += tw
					dw = -tw
				if v & (1 << 29):
					dy += th
					dh = -th
				RenderingServer.canvas_item_add_texture_rect_region(ci, Pen._ret(dx, dy, dw, dh), tex.get_rid(), Rect2(sx, sy, tw, th))     # v1.14: espelho no lugar certo
				tem = true
		if tem:
			_tiles.append(ci)
		else:
			RenderingServer.free_rid(ci)
		bx += por_bloco


# ---------------------------------------------------------------------
# COLISÃO
# ---------------------------------------------------------------------
func _atualizar_chao() -> void:
	if not chao_sujo:
		return
	chao_sujo = false
	_chao.clear()
	_chao_inst.clear()
	for i in listas.get("obj_chao", []):
		if not i._ativo or i._destruido:
			continue
		var c: Array = i._caixa(i.x, i.y)
		_chao.append(c[0])
		_chao.append(c[1])
		_chao.append(c[2])
		_chao.append(c[3])
		_chao_inst.append(i)
	_chao_n = _chao.size() / 4


# place_meeting(obj_chao) ignorando um bloco (o caixote não colide com o próprio sólido)
func chao_colide_inst(inst: GMObj, px: float, py: float, exceto) -> bool:
	_atualizar_chao()
	var c: Array = inst._caixa(px, py)
	var i := 0
	while i < _chao_n:
		if _chao_inst[i] != exceto:
			var k := i * 4
			if c[0] < _chao[k + 2] and c[2] > _chao[k] and c[1] < _chao[k + 3] and c[3] > _chao[k + 1]:
				return true
		i += 1
	return false


func chao_colide(l: float, t: float, r: float, b: float) -> bool:
	_atualizar_chao()
	var i := 0
	while i < _chao_n:
		var k := i * 4
		if l < _chao[k + 2] and r > _chao[k] and t < _chao[k + 3] and b > _chao[k + 1]:
			return true
		i += 1
	return false


func chao_ponto(px: float, py: float) -> bool:
	_atualizar_chao()
	var i := 0
	while i < _chao_n:
		var k := i * 4
		if px >= _chao[k] and px < _chao[k + 2] and py >= _chao[k + 1] and py < _chao[k + 3]:
			return true
		i += 1
	return false


func place_meeting(inst: GMObj, px: float, py: float, o: String) -> bool:
	var m := inst._mascara()
	if m == null:
		return false
	var c: Array = inst._caixa(px, py)
	if o == "obj_chao":
		return chao_colide(c[0], c[1], c[2], c[3])
	for i in listas.get(o, []):
		if i == inst or not i._ativo or i._mascara() == null:
			continue
		var d: Array = i._caixa(i.x, i.y)
		if c[0] < d[2] and c[2] > d[0] and c[1] < d[3] and c[3] > d[1]:
			return true
	return false


func position_meeting(px: float, py: float, o: String) -> bool:
	if o == "obj_chao":
		return chao_ponto(px, py)
	return collision_point(px, py, o, null) != null


func collision_point(px: float, py: float, o: String, exceto):
	for i in listas.get(o, []):
		if i == exceto or not i._ativo or i._mascara() == null:
			continue
		var d: Array = i._caixa(i.x, i.y)
		if px >= d[0] and px < d[2] and py >= d[1] and py < d[3]:
			return i
	return null


func collision_rectangle(x1: float, y1: float, x2: float, y2: float, o: String, exceto):
	var l := minf(x1, x2)
	var r := maxf(x1, x2)
	var t := minf(y1, y2)
	var b := maxf(y1, y2)
	for i in listas.get(o, []):
		if i == exceto or not i._ativo or i._mascara() == null:
			continue
		var d: Array = i._caixa(i.x, i.y)
		if d[0] <= r and d[2] > l and d[1] <= b and d[3] > t:
			return i
	return null


func collision_rectangle_list(x1: float, y1: float, x2: float, y2: float, o: String, exceto) -> Array:
	var res := []
	var l := minf(x1, x2)
	var r := maxf(x1, x2)
	var t := minf(y1, y2)
	var b := maxf(y1, y2)
	for i in listas.get(o, []):
		if i == exceto or not i._ativo or i._mascara() == null:
			continue
		var d: Array = i._caixa(i.x, i.y)
		if d[0] <= r and d[2] > l and d[1] <= b and d[3] > t:
			res.append(i)
	return res


# ---------------------------------------------------------------------
# ENTRADA: teclado, mouse/toque (menus), controle e botão VOLTAR
# ---------------------------------------------------------------------
# teclas do próprio aparelho (Voltar, volume...): não contam como "usando teclado"
const TECLAS_DO_APARELHO := [KEY_BACK, KEY_MENU, KEY_VOLUMEUP, KEY_VOLUMEDOWN, KEY_VOLUMEMUTE, KEY_HOMEPAGE, KEY_SEARCH, KEY_UNKNOWN]


func _input(ev: InputEvent) -> void:
	if ev is InputEventKey:
		if ev.keycode in TECLAS_DO_APARELHO:
			return
		if ev.pressed and not ev.echo:
			_teclas_ev[ev.keycode] = true
			_teclas_seg[ev.keycode] = true
			_alguma_tecla_ev = true
			ultima_tecla = ev.keycode
			usando_toque = false
			if ev.unicode >= 32:
				texto_digitado += char(ev.unicode)     # v1.17: o nome do perfil
		elif not ev.pressed:
			_teclas_seg.erase(ev.keycode)
	elif ev is InputEventMouseButton:
		if ev.button_index == MOUSE_BUTTON_LEFT:
			_ponteiro = ev.position
			_ponteiro_botao(ev.pressed)
		elif ev.button_index == MOUSE_BUTTON_RIGHT and ev.pressed:
			_mouse_dir_ev = true
		elif ev.pressed and (ev.button_index == MOUSE_BUTTON_WHEEL_UP or ev.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			_roda_ev += -1 if ev.button_index == MOUSE_BUTTON_WHEEL_UP else 1     # v1.17: mapa e conquistas
	elif ev is InputEventMouseMotion:
		_ponteiro = ev.position
	elif ev is InputEventScreenTouch:
		if ev.pressed:
			usando_toque = true
			usando_pad = false
		# o 1º dedo funciona como o mouse nos menus
		if ev.index == 0:
			_ponteiro = ev.position
			_ponteiro_botao(ev.pressed)
	elif ev is InputEventScreenDrag:
		if ev.index == 0:
			_ponteiro = ev.position


func _ponteiro_botao(apertado: bool) -> void:
	if not apertado:
		_mouse_seg = false
		return
	# o toque no botão VOLTAR da tela não conta como clique no menu
	if toque != null and toque.toca_voltar(_ponteiro):
		return
	_mouse_seg = true
	_mouse_ev = true


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		voltar_ev = true
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		_salvar_pendente()
		get_tree().quit()
	elif what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if what == NOTIFICATION_APPLICATION_PAUSED:
			_salvar_pendente()
		if prefixo_arquivos == "":     # no teste automático a janela pode perder o foco
			pausa_auto = true


# v1.18: conquista ainda não gravada (V117.conquista adia a gravação)
func _salvar_pendente() -> void:
	if perfil_salvar_t > 0:
		perfil_salvar_t = 0.0
		V117.perfil_salvar_se_mudou()


func _entrada_comecar_tick() -> void:
	_teclas_tick = _teclas_ev
	_teclas_ev = {}
	alguma_tecla = _alguma_tecla_ev
	_alguma_tecla_ev = false
	mouse_apertado = _mouse_ev
	_mouse_ev = false
	mouse_dir_apertado = _mouse_dir_ev
	_mouse_dir_ev = false
	mouse_segurado = _mouse_seg
	voltar_apertado = voltar_ev
	voltar_ev = false
	texto_tick = texto_digitado
	texto_digitado = ""
	roda = _roda_ev
	_roda_ev = 0
	if toque != null:
		toque.comecar_tick()
	# controle: estado de cada botão neste passo (para os "apertados")
	_pad_antes = _pad_agora
	_pad_agora = {}
	if pad_slot >= 0:
		for b in [0, 1, 2, 3, 4, 6, 7, 8, 9, 10, 11, 12, 13, 14, 100, 101]:
			_pad_agora[b] = _pad_le(pad_slot, b)


func _entrada_terminar_tick() -> void:
	_teclas_tick = {}


func _pad_le(dev: int, b: int) -> bool:
	if b == 100:
		return Input.get_joy_axis(dev, JOY_AXIS_TRIGGER_LEFT) > 0.45
	if b == 101:
		return Input.get_joy_axis(dev, JOY_AXIS_TRIGGER_RIGHT) > 0.45
	return Input.is_joy_button_pressed(dev, b)


func keyboard_check(k: int) -> bool:
	return _teclas_seg.has(k)


func keyboard_check_pressed(k: int) -> bool:
	return _teclas_tick.has(k)


func io_clear() -> void:
	_teclas_tick = {}
	_teclas_ev = {}
	mouse_apertado = false
	_mouse_ev = false
	voltar_apertado = false
	nav_ok = false
	nav_voltar = false
	for i in inp_apertado.size():
		inp_apertado[i] = false
	if toque != null:
		toque.limpar_apertos()


func pad_botao(b: int) -> bool:
	return _pad_agora.get(b, false)


func pad_botao_apertado(b: int) -> bool:
	return _pad_agora.get(b, false) and not _pad_antes.get(b, false)


func pad_eixo_valor(eixo: int) -> float:
	if pad_slot < 0:
		return 0.0
	var v := Input.get_joy_axis(pad_slot, eixo)
	return 0.0 if absf(v) < 0.25 else v


func pad_conectado() -> int:
	var lista := Input.get_connected_joypads()
	if lista.is_empty():
		return -1
	if pad_slot >= 0 and lista.has(pad_slot):
		return pad_slot
	return lista[0]


func mouse_gui() -> Vector2:
	if _ponteiro.x < 0:
		return get_viewport().get_mouse_position()
	return _ponteiro


func _controle_mudou(dev: int, conectado: bool) -> void:
	if lib != null:
		lib.controle_mudou(dev, conectado)


func vibrar(ms: int) -> void:
	if cfg_vibrar == 1 and OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)


# ---------------------------------------------------------------------
# ÁUDIO (como as funções audio_* do GameMaker)
# ---------------------------------------------------------------------
func audio_carregar(arq: String) -> AudioStream:
	var caminho := "res://assets/data/" + arq
	if not ResourceLoader.exists(caminho):
		return null
	return load(caminho)


func audio_play_sound(s: AudioStream, loop: bool, ganho: float, tom := 1.0) -> SomInst:
	if s == null:
		return null
	# acha um player livre (ou o que toca há mais tempo)
	var escolhido := -1
	for i in _players.size():
		if not _players[i].playing and _player_inst[i] == null:
			escolhido = i
			break
	if escolhido == -1:
		for i in _players.size():
			if not _players[i].playing:
				escolhido = i
				break
	if escolhido == -1:
		escolhido = randi() % _players.size()
	var p: AudioStreamPlayer = _players[escolhido]
	var antigo = _player_inst[escolhido]
	if antigo != null:
		antigo.parado = true
		_sons_ativos.erase(antigo)
	_player_ger[escolhido] += 1
	if s is AudioStreamOggVorbis:
		s.loop = loop
	p.stream = s
	p.pitch_scale = maxf(0.05, tom)
	var inst := SomInst.new()
	inst.player = p
	inst.stream = s
	inst.ger = _player_ger[escolhido]
	inst.ganho = ganho
	inst.alvo = ganho
	p.volume_db = linear_to_db(maxf(0.0001, ganho))
	p.play()
	_player_inst[escolhido] = inst
	_sons_ativos.append(inst)
	return inst


func audio_is_playing(h) -> bool:
	if h == null or not (h is SomInst) or h.parado:
		return false
	return h.player.playing


func audio_stop_sound(h) -> void:
	if h == null or not (h is SomInst) or h.parado:
		return
	h.parado = true
	h.player.stop()
	var i := _players.find(h.player)
	if i >= 0 and _player_inst[i] == h:
		_player_inst[i] = null
	_sons_ativos.erase(h)


# muda o volume até "ganho" em "ms" milissegundos
func audio_sound_gain(h, ganho: float, ms: float) -> void:
	if h == null or not (h is SomInst) or h.parado:
		return
	h.alvo = ganho
	if ms <= 0:
		h.ganho = ganho
		h.vel = 0.0
		h.player.volume_db = linear_to_db(maxf(0.0001, ganho))
	else:
		h.vel = absf(ganho - h.ganho) / ms


func audio_sound_get_gain(h) -> float:
	if h == null or not (h is SomInst) or h.parado:
		return 0.0
	return h.ganho


func audio_sound_pitch(h, tom: float) -> void:
	if h == null or not (h is SomInst) or h.parado:
		return
	h.player.pitch_scale = maxf(0.05, tom)


func audio_master_gain(g: float) -> void:
	AudioServer.set_bus_volume_db(_bus_master, linear_to_db(maxf(0.0001, g)))


func _audio_fades(delta: float) -> void:
	var ms := delta * 1000.0
	for h in _sons_ativos.duplicate():
		if not h.player.playing:
			h.parado = true
			var i := _players.find(h.player)
			if i >= 0 and _player_inst[i] == h:
				_player_inst[i] = null
			_sons_ativos.erase(h)
			continue
		if h.ganho != h.alvo:
			h.ganho = move_toward(h.ganho, h.alvo, h.vel * ms) if h.vel > 0 else h.alvo
			h.player.volume_db = linear_to_db(maxf(0.0001, h.ganho))


# ---------------------------------------------------------------------
# ARQUIVOS (ini do GameMaker -> ConfigFile em user://)
# ---------------------------------------------------------------------
var prefixo_arquivos := ""     # "teste_" no teste automático (não mexe nos saves reais)
var quadro_trabalho_ms := 0.0  # v1.19: duração do último _process_jogo (teste de desempenho)


func ini_abrir(arq: String) -> ConfigFile:
	var c := ConfigFile.new()
	c.load("user://" + prefixo_arquivos + arq)
	return c


func ini_salvar(c: ConfigFile, arq: String) -> void:
	c.save("user://" + prefixo_arquivos + arq)


func arquivo_existe(arq: String) -> bool:
	return FileAccess.file_exists("user://" + prefixo_arquivos + arq)
