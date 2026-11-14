class_name Desempenho
extends RefCounted
# =====================================================================
#  Desempenho — perfis para celulares (v1.14)
#  Nem todo celular roda o jogo no máximo. Quatro níveis:
#   1 MÍNIMO       qualidade baixa, 30 FPS, resolução 720p e cenário econômico
#                  (sem as fileiras de casas do fundo nem os incêndios ao longe)
#   2 LEVE         qualidade baixa, 60 FPS, resolução 720p
#   3 EQUILIBRADO  qualidade média, 60 FPS, resolução da tela
#   4 MÁXIMO       qualidade alta, 60 FPS, resolução da tela
#  v1.19: o jogo busca os 60 FPS: a qualidade cai antes da taxa de quadros
#  (só o MÍNIMO volta para 30).
#  No AUTOMÁTICO (o padrão) o jogo escolhe o nível pelo aparelho (núcleos do
#  processador, memória e placa de vídeo) na primeira vez e, durante as fases,
#  mede os quadros por segundo: se o aparelho não aguenta, desce um nível; se
#  sobra folga por bastante tempo, sobe um. O nível encontrado fica salvo no
#  config.ini e a próxima partida já começa nele.
#  PERSONALIZADO = o jogador mexeu na qualidade, na taxa de quadros ou na
#  resolução à mão.
# =====================================================================

const AUTO := 0
const PERSONALIZADO := 5
const NOMES := ["AUTOMÁTICO", "MÍNIMO", "LEVE", "EQUILIBRADO", "MÁXIMO", "PERSONALIZADO"]

# medição (só no celular, no AUTOMÁTICO)
static var _sala := ""
static var _espera := 4.0
static var _janela_t := 0.0
static var _janela_q := 0
static var _proc := 0.0
static var _ruins := 0
static var _bons := 0
static var _desceu_de := {}        # níveis de onde já desceu nesta sessão (não sobe de volta para eles)


static func nome(n: int) -> String:
	return NOMES[clampi(n, 0, NOMES.size() - 1)]


# aplica um nível (1 a 4) nas opções de vídeo
static func aplicar_nivel(n: int) -> void:
	n = clampi(n, 1, 4)
	G.nivel_desempenho = n
	G.cfg_qualidade = [0, 0, 0, 1, 2][n]
	G.cfg_fps = 0 if n == 1 else 1      # v1.19: 60 FPS em todos menos no MÍNIMO
	G.cfg_resolucao = 1 if n <= 2 else 0
	G.cenario_economico = n == 1


# depois de carregar o config.ini: o perfil escolhido manda nas opções de vídeo
static func iniciar() -> void:
	match G.cfg_desempenho:
		AUTO:
			if G.nivel_auto <= 0:
				G.nivel_auto = detectar()
			aplicar_nivel(G.nivel_auto)
		PERSONALIZADO:
			G.nivel_desempenho = 4 if G.cfg_fps == 1 else (3 if G.cfg_qualidade >= 1 else 2)
			G.cenario_economico = false
		_:
			aplicar_nivel(G.cfg_desempenho)


# o jogador trocou o perfil nas OPÇÕES
static func escolher(perfil: int) -> void:
	G.cfg_desempenho = clampi(perfil, 0, PERSONALIZADO)
	_desceu_de = {}
	_ruins = 0
	_bons = 0
	iniciar()


# o jogador mexeu na qualidade, na taxa de quadros ou na resolução
static func personalizar() -> void:
	G.cfg_desempenho = PERSONALIZADO
	G.cenario_economico = false


# Classe do aparelho pela ficha técnica (a medição em jogo corrige depois)
static func detectar() -> int:
	if not OS.has_feature("mobile"):
		return 4
	var nucleos := OS.get_processor_count()
	var mem_gb := 0.0
	var info := OS.get_memory_info()
	if info.has("physical") and int(info["physical"]) > 0:
		mem_gb = float(info["physical"]) / 1073741824.0
	var gpu := RenderingServer.get_video_adapter_name().to_lower()
	var n := 3
	# placas de vídeo de entrada
	for fraca in ["mali-4", "mali-t", "mali-g31", "mali-g51", "mali-g52", "adreno (tm) 3", "adreno (tm) 4",
			"adreno (tm) 50", "adreno (tm) 51", "adreno (tm) 610", "adreno (tm) 612", "powervr ge", "powervr rogue ge"]:
		if gpu.contains(fraca):
			n = 2
	# pouca memória ou poucos núcleos
	if (mem_gb > 0 and mem_gb < 2.5) or nucleos <= 4:
		n = mini(n, 1 if (mem_gb > 0 and mem_gb < 1.6) else 2)
	# topo de linha: Adreno 7xx/8xx, Mali-G610 em diante, Immortalis, Xclipse
	var forte := false
	for f in ["adreno (tm) 7", "adreno (tm) 8", "immortalis", "xclipse", "mali-g77", "mali-g78", "mali-g610",
			"mali-g615", "mali-g710", "mali-g715", "mali-g720"]:
		if gpu.contains(f):
			forte = true
	if forte and nucleos >= 8 and mem_gb >= 5.5:
		n = 4
	print("[desempenho] aparelho: gpu=%s nucleos=%d memoria=%.1f GB -> %s" % [gpu, nucleos, mem_gb, nome(n)])
	return n


# Resolução: 0 = a da tela (nítida); 1 = reduzida (720p, ampliada para a tela:
# bem mais leve para a placa de vídeo dos celulares com tela grande)
static func aplicar_resolucao() -> void:
	var raiz: Window = G.get_tree().root
	var modo := Window.CONTENT_SCALE_MODE_VIEWPORT if G.cfg_resolucao == 1 else Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	if raiz.content_scale_mode != modo:
		raiz.content_scale_mode = modo


# Chamado a cada quadro pelo G: mede os quadros por segundo nas fases e ajusta
static func monitorar(delta: float) -> void:
	if G.cfg_desempenho != AUTO or not OS.has_feature("mobile"):
		return
	if G.room != _sala:
		_sala = G.room
		_recomecar(4.0)
	var lib = G.lib
	if lib == null or G.room == "rm_menu" or G.room == "" or G.audio_pausa or lib.instance_exists("obj_loading") \
			or lib.instance_exists("obj_cutscene") or not lib.instance_exists("obj_player"):
		_recomecar(maxf(_espera, 1.0))
		return
	if _espera > 0:
		_espera -= delta
		return
	_janela_t += delta
	_janela_q += 1
	_proc += Performance.get_monitor(Performance.TIME_PROCESS)
	if _janela_t < 4.0:
		return
	var fps := _janela_q / _janela_t
	var proc_ms := _proc / _janela_q * 1000.0
	var alvo := 60.0 if G.cfg_fps == 1 else 30.0
	var n := G.nivel_desempenho
	_janela_t = 0
	_janela_q = 0
	_proc = 0
	if fps < alvo * 0.86:
		# não aguenta: desce um nível depois de 2 medições ruins seguidas (8 s)
		_bons = 0
		_ruins += 1
		if _ruins >= 2 and n > 1:
			_desceu_de[n] = true
			_mudar(n - 1, fps)
	else:
		_ruins = 0
		# folga: o processamento cabe com sobra no tempo do nível de cima
		var orcamento := 1000.0 / 60.0      # v1.19: todos os níveis acima do MÍNIMO rodam a 60
		if n < 4 and not _desceu_de.has(n + 1) and proc_ms < orcamento * 0.5:
			_bons += 1
			if _bons >= 5:
				_mudar(n + 1, fps)
		else:
			_bons = 0


static func _recomecar(espera: float) -> void:
	_espera = espera
	_janela_t = 0
	_janela_q = 0
	_proc = 0


static func _mudar(n: int, fps: float) -> void:
	print("[desempenho] %.1f fps no nível %s -> %s" % [fps, nome(G.nivel_desempenho), nome(n)])
	G.nivel_auto = n
	aplicar_nivel(n)
	LibBase.config_aplicar()
	LibBase.config_salvar()
	_ruins = 0
	_bons = 0
	_recomecar(4.0)
	if G.lib != null:
		G.lib.aviso_mostrar("DESEMPENHO AJUSTADO  ·  " + nome(n), false)
