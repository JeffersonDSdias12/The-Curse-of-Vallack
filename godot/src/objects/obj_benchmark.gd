extends Lib
# =====================================================================
#  obj_benchmark — TESTE DE DESEMPENHO (v1.19, só Android)
#  OPÇÕES > TESTE DE DESEMPENHO. Roda sozinho (~2 min), sem tocar nos saves
#  (arquivos "bench_" apagados no fim), e mede o celular nas cenas que mais
#  pesam, em cada nível de desempenho (MÁXIMO, EQUILIBRADO, LEVE, MÍNIMO):
#    MENU     a tela inicial (retrato grande, fogo e luz em camadas)
#    VILA     Twilight correndo entre as casas em chamas
#    COMBATE  4 inimigos e golpes sem parar (efeitos de luta)
#    ÁRVORE   o chefe acordado, com a chuva de fogo
#  Por cena e nível: FPS médio, 1% mais lento, pior quadro e o tempo de CPU
#  por quadro (o que mostra a folga do processador mesmo travado em 60).
#  No fim: a ficha do aparelho (arquitetura, processador, GPU, memória, tela),
#  a tabela e o nível recomendado; o relatório fica em
#  user://relatorio_desempenho.txt e sai no logcat com a marca [bench].
# =====================================================================

const NIVEIS := [4, 3, 2, 1]
const CENAS := ["menu", "vila", "combate", "arvore"]
const NOMES_CENA := {"menu": "MENU", "vila": "VILA", "combate": "COMBATE", "arvore": "ÁRVORE"}
const AQUECER_MS := 1500
const MEDIR_MS := 5000

var etapa := "menu"            # menu -> carregar -> fase -> resultado
var fila: Array = []           # [cena, nivel] a medir, em ordem
var passo := -1
var fase_passo := ""           # aquecer | medir
var t0 := 0
var quadros: PackedFloat32Array = PackedFloat32Array()
var cpu_soma := 0.0
var gpu_soma := 0.0
var ultimo_us := 0
var resultados := {}           # "cena/nivel" -> {fps, low1, pior, cpu, gpu}
var ficha := {}
var recomendado := 1
var relatorio: PackedStringArray = PackedStringArray()
var golpe_t := 0
var cfg_antes := {}
var prefixo_antes := ""
var botoes := {}               # nome -> Rect2 (tela de resultado)


func ev_create() -> void:
	persistent = true
	depth = -12000
	# guarda o que o jogador tinha e isola os arquivos (saves, perfil e config)
	prefixo_antes = G.prefixo_arquivos
	cfg_antes = {"desempenho": G.cfg_desempenho, "nivel_auto": G.nivel_auto}
	G.prefixo_arquivos = "bench_"
	G.cfg_desempenho = Desempenho.PERSONALIZADO      # o automático não mexe no meio do teste
	RenderingServer.viewport_set_measure_render_time(G.get_viewport().get_viewport_rid(), true)
	if G.toque != null:
		G.toque.visible = false        # os botões de toque não entram na medição nem cobrem o resultado
	ficha = _ficha_aparelho()
	for c in CENAS:
		for n in NIVEIS:
			fila.append([c, n])
	_proximo()
	print("[bench] começou: ", ficha)


func _ficha_aparelho() -> Dictionary:
	var mem := 0.0
	var info := OS.get_memory_info()
	if info.has("physical") and int(info["physical"]) > 0:
		mem = float(info["physical"]) / 1073741824.0
	if mem <= 0.0 and OS.has_feature("android"):
		# Android: a memória vem do /proc/meminfo (MemTotal em kB); file_exists dá
		# falso em /proc, então abre direto
		var mi := FileAccess.get_file_as_string("/proc/meminfo")
		if mi == "":
			var saida := []
			if OS.execute("cat", ["/proc/meminfo"], saida) == 0 and saida.size() > 0:
				mi = str(saida[0])
		var rx := RegEx.create_from_string("MemTotal:\\s+(\\d+)")
		var m := rx.search(mi)
		if m != null:
			mem = float(m.get_string(1)) / 1048576.0
	var chip := OS.get_processor_name()
	if chip.strip_edges() == "" and OS.has_feature("android"):
		# Android: o modelo do chip vem das propriedades do sistema
		for prop in ["ro.soc.model", "ro.board.platform", "ro.hardware"]:
			var saida := []
			if OS.execute("getprop", [prop], saida) == 0 and saida.size() > 0 and str(saida[0]).strip_edges() != "":
				chip = str(saida[0]).strip_edges()
				break
	var tela := DisplayServer.screen_get_size()
	return {
		"modelo": OS.get_model_name(),
		"sistema": OS.get_name() + " " + OS.get_version(),
		"arquitetura": Engine.get_architecture_name(),
		"processador": chip if chip != "" else "?",
		"nucleos": OS.get_processor_count(),
		"gpu": RenderingServer.get_video_adapter_name(),
		"gpu_fabricante": RenderingServer.get_video_adapter_vendor(),
		"memoria_gb": snappedf(mem, 0.1),
		"tela": "%dx%d" % [tela.x, tela.y],
		"hz": snappedf(DisplayServer.screen_get_refresh_rate(), 1),
		"nivel_detectado": Desempenho.nome(Desempenho.detectar()),
	}


# aplica o nível do próximo passo e prepara a cena
func _proximo() -> void:
	passo += 1
	if passo >= fila.size():
		_concluir()
		return
	var cena: String = fila[passo][0]
	var nivel: int = fila[passo][1]
	Desempenho.aplicar_nivel(nivel)
	LibBase.config_aplicar()
	if cena != "menu" and etapa == "menu":
		etapa = "carregar"
		_carregar_fase()
		return
	_preparar(cena)
	fase_passo = "aquecer"
	t0 = Time.get_ticks_msec()


func _carregar_fase() -> void:
	partida_resetar()
	G.save_slot_atual = 3              # arquivo bench_save_slot3 (o slot real não é tocado)
	G.dificuldade = 1
	var l = instance_create_depth(0, 0, -11000, "obj_loading")
	l.modo = "novo_jogo"
	l.destino = "Room1"
	l.rapido = true


func _preparar(cena: String) -> void:
	_tecla(KEY_D, false)
	var p = instance_find("obj_player", 0)
	match cena:
		"menu":
			var m = instance_find("obj_menu", 0)
			if m != null:
				m.estado = "menu"
		"vila":
			_limpar()
			if p != null:
				_teleportar(p, 700.0, 690.0)
			_tecla(KEY_D, true)
		"combate":
			_limpar()
			if p != null:
				_teleportar(p, 2300.0, 690.0)
				var tipos := ["obj_inimigo_01", "obj_esqueleto", "obj_inimigo_01", "obj_inimigo_02"]
				for i in tipos.size():
					var e = instance_create_depth(p.x + (-1 if i % 2 == 0 else 1) * (90 + 40 * i), p.y - 2, 100, tipos[i])
					if "surgir_fase" in e:
						e.surgir_fase = "ativo"
					e.ativo = true
					e.estado_ia = "parado" if tipos[i] == "obj_inimigo_02" else "perseguir"
		"arvore":
			_limpar()
			var b = instance_find("obj_boss_01", 0)
			if b != null and p != null:
				_teleportar(p, b.x - 300.0, b.y - 4.0)
				if not b.acordado:
					b.despertar()


func _teleportar(p, px: float, py: float) -> void:
	p.x = px
	p.y = py
	p.velv = 0.0
	G.cam_snap = true


func _limpar() -> void:
	for e in todos("obj_inimigo_base"):
		if not e.eh_boss:
			instance_destroy(e)


func _tecla(k: int, apertada: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = k
	e.physical_keycode = k
	e.pressed = apertada
	Input.parse_input_event(e)


func ev_step() -> void:
	var agora := Time.get_ticks_msec()
	# Twilight não morre e os diálogos fecham sozinhos durante o teste
	var p = instance_find("obj_player", 0)
	if p != null:
		p.vida = p.vida_max
		p.tempo_invencivel = maxf(p.tempo_invencivel, 30.0)
	var d = instance_find("obj_dialogo", 0)
	if d != null and not d.pendente:
		d.fechando = true
	match etapa:
		"carregar":
			if not instance_exists("obj_loading") and G.room == "Room1" and p != null:
				etapa = "fase"
				_preparar(fila[passo][0])
				fase_passo = "aquecer"
				t0 = agora
		"menu", "fase":
			var cena: String = fila[passo][0]
			if cena == "combate" or cena == "arvore":
				golpe_t += 1
				if golpe_t % 20 == 0:
					_tecla(KEY_J, true)
				elif golpe_t % 20 == 3:
					_tecla(KEY_J, false)
			# o primeiro nível de cada cena aquece mais (texturas e efeitos carregando)
			var aquecer: int = AQUECER_MS + (2000 if fila[passo][1] == NIVEIS[0] else 0)
			if fase_passo == "aquecer" and agora - t0 >= aquecer:
				fase_passo = "medir"
				t0 = agora
				quadros.clear()
				cpu_soma = 0.0
				gpu_soma = 0.0
				ultimo_us = 0
				if cena == "arvore":
					var b = instance_find("obj_boss_01", 0)
					if b != null and b.chuva_fila.is_empty():
						b.chuva_grande()
			elif fase_passo == "medir" and agora - t0 >= MEDIR_MS:
				_guardar(cena, fila[passo][1])
				_proximo()
		"resultado":
			_resultado_entrada()


# mede por quadro DESENHADO (o passo do jogo é fixo; o desenho é o que trava)
func ev_draw_gui() -> void:
	if fase_passo == "medir" and etapa != "resultado":
		var us := Time.get_ticks_usec()
		if ultimo_us > 0:
			quadros.append((us - ultimo_us) / 1000.0)
			cpu_soma += G.quadro_trabalho_ms     # trabalho do quadro, sem a espera do VSync
			gpu_soma += RenderingServer.viewport_get_measured_render_time_gpu(G.get_viewport().get_viewport_rid())
		ultimo_us = us
	_desenhar()


func _guardar(cena: String, nivel: int) -> void:
	var n := quadros.size()
	var r := {"fps": 0.0, "low1": 0.0, "pior": 0.0, "cpu": 0.0, "gpu": 0.0}
	if n > 0:
		var soma := 0.0
		for q in quadros:
			soma += q
		var ord := quadros.duplicate()
		ord.sort()
		r.fps = 1000.0 * n / maxf(1.0, soma)
		r.low1 = 1000.0 / maxf(1.0, ord[mini(n - 1, int(n * 0.99))])
		r.pior = ord[n - 1]
		r.cpu = cpu_soma / n
		r.gpu = gpu_soma / n
	resultados[cena + "/" + str(nivel)] = r
	print("[bench] %s nivel=%s fps=%.1f low1=%.1f pior=%.1fms cpu=%.2fms gpu=%.2fms quadros=%d" % [
		cena, Desempenho.nome(nivel), r.fps, r.low1, r.pior, r.cpu, r.gpu, n])


func _concluir() -> void:
	_tecla(KEY_D, false)
	_tecla(KEY_J, false)
	etapa = "resultado"
	fase_passo = ""
	# recomendado: o nível mais alto que segura os 60 em todas as cenas da fase
	recomendado = 1
	for n in [4, 3, 2]:
		var ok := true
		for c in ["vila", "combate", "arvore"]:
			var r = resultados.get(c + "/" + str(n))
			if r == null or r.fps < 55.0 or r.low1 < 40.0:
				ok = false
		if ok:
			recomendado = n
			break
	relatorio = PackedStringArray()
	relatorio.append("THE CURSE OF VALLACK — TESTE DE DESEMPENHO (v1.19)")
	relatorio.append(Time.get_datetime_string_from_system(false, true))
	for k in ficha:
		relatorio.append("%s: %s" % [k, str(ficha[k])])
	relatorio.append("cena;nivel;fps_medio;fps_1pct;pior_ms;cpu_ms;gpu_ms")
	for c in CENAS:
		for n in NIVEIS:
			var r = resultados.get(c + "/" + str(n), {})
			if r.is_empty():
				continue
			relatorio.append("%s;%s;%.1f;%.1f;%.1f;%.2f;%.2f" % [c, Desempenho.nome(n), r.fps, r.low1, r.pior, r.cpu, r.gpu])
	relatorio.append("recomendado: " + Desempenho.nome(recomendado))
	var f := FileAccess.open("user://relatorio_desempenho.txt", FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(relatorio))
		f.close()
	for linha in relatorio:
		print("[bench] ", linha)
	# devolve o jogo ao estado do jogador (arquivos reais, config e perfil)
	_restaurar()


func _restaurar() -> void:
	for arq in DirAccess.get_files_at("user://"):
		if arq.begins_with("bench_"):
			DirAccess.remove_absolute("user://" + arq)
	G.prefixo_arquivos = prefixo_antes
	LibBase.config_carregar()
	G.cfg_desempenho = cfg_antes["desempenho"]
	G.nivel_auto = cfg_antes["nivel_auto"]
	Desempenho.iniciar()
	LibBase.config_aplicar()
	V117.perfil_carregar()


func _resultado_entrada() -> void:
	var mp := G.mouse_gui()
	var aplicar := false
	var sair := G.nav_voltar
	if G.mouse_apertado:
		if botoes.has("aplicar") and botoes["aplicar"].has_point(mp):
			aplicar = true
		elif botoes.has("sair") and botoes["sair"].has_point(mp):
			sair = true
	if G.nav_ok:
		aplicar = true
	if aplicar:
		# fica no AUTOMÁTICO começando pelo nível recomendado (ele ainda se ajusta jogando)
		G.cfg_desempenho = Desempenho.AUTO
		G.nivel_auto = recomendado
		Desempenho.iniciar()
		LibBase.config_aplicar()
		LibBase.config_salvar()
		aviso_mostrar("DESEMPENHO: " + Desempenho.nome(recomendado), false)
		sair = true
	if sair:
		partida_resetar()
		G.room_goto("rm_menu")
		instance_destroy()


func _desenhar() -> void:
	var gw := G.gui_w
	var gh := G.gui_h
	var pen: Pen = G.pen
	var ouro := Color8(236, 186, 84)
	if etapa != "resultado":
		pen.retangulo(0, 0, gw, 54, Color.BLACK, 0.72, false)
		var info := "TESTE DE DESEMPENHO  ·  não toque na tela"
		if passo >= 0 and passo < fila.size():
			info += "  ·  %s  ·  %s  ·  %d/%d" % [NOMES_CENA[fila[passo][0]], Desempenho.nome(fila[passo][1]), passo + 1, fila.size()]
		if etapa == "carregar":
			info = "TESTE DE DESEMPENHO  ·  carregando a fase..."
		txt(gw / 2.0, 27, info, FONTE.PEQUENA, ouro, 1, fa_center, fa_middle)
		desenho_resetar()
		return
	# ----- tela de resultado -----
	pen.retangulo(0, 0, gw, gh, Color8(8, 6, 10), 0.96, false)
	txt(gw / 2.0, 46, "TESTE DE DESEMPENHO", FONTE.MEDIA, ouro, 1, fa_center, fa_middle)
	var linha := "%s  ·  %s  ·  %s  ·  %d núcleos  ·  %s  ·  %.1f GB  ·  tela %s %d Hz" % [ficha.modelo, ficha.arquitetura, ficha.processador, ficha.nucleos, ficha.gpu, ficha.memoria_gb, ficha.tela, ficha.hz]
	txt(gw / 2.0, 88, linha, FONTE.MINI, Color8(210, 205, 200), 1, fa_center, fa_middle, minf(1.0, (gw - 40) / maxf(1.0, txt_largura(linha, FONTE.MINI))))
	var x0 := gw / 2.0 - 500
	var colw := 185.0
	var c0 := 330.0            # onde começa a 1ª coluna de cenas (o nome do nível cabe antes)
	txt(x0, 140, "NÍVEL", FONTE.PEQUENA, ouro, 1, fa_left, fa_middle)
	for ci in CENAS.size():
		txt(x0 + c0 + ci * colw, 140, NOMES_CENA[CENAS[ci]], FONTE.PEQUENA, ouro, 1, fa_center, fa_middle)
	for ni in NIVEIS.size():
		var n: int = NIVEIS[ni]
		var y := 190 + ni * 62.0
		if n == recomendado:
			pen.retangulo(x0 - 16, y - 26, x0 + c0 + (CENAS.size() - 0.5) * colw, y + 26, ouro, 0.14, false)
		txt(x0, y, Desempenho.nome(n) + ("  (30)" if n == 1 else "  (60)"), FONTE.PEQUENA, Color.WHITE, 1, fa_left, fa_middle)
		for ci in CENAS.size():
			var r = resultados.get(CENAS[ci] + "/" + str(n), {})
			if r.is_empty():
				continue
			var alvo := 30.0 if n == 1 else 60.0
			var cor := Color8(120, 230, 120) if r.fps >= alvo * 0.92 else (Color8(240, 200, 90) if r.fps >= alvo * 0.7 else Color8(240, 90, 80))
			var cx := x0 + c0 + ci * colw
			txt(cx, y - 9, "%d fps" % roundi(r.fps), FONTE.PEQUENA, cor, 1, fa_center, fa_middle)
			txt(cx, y + 14, "1%%: %d · cpu %.1f ms" % [roundi(r.low1), r.cpu], FONTE.MINI, Color8(190, 185, 180), 1, fa_center, fa_middle)
	txt(gw / 2.0, gh - 150, "RECOMENDADO PARA ESTE CELULAR: " + Desempenho.nome(recomendado), FONTE.MEDIA, ouro, 1, fa_center, fa_middle)
	txt(gw / 2.0, gh - 114, "Relatório salvo em relatorio_desempenho.txt", FONTE.MINI, Color8(170, 165, 160), 1, fa_center, fa_middle)
	botoes["aplicar"] = Rect2(gw / 2.0 - 330, gh - 86, 310, 56)
	botoes["sair"] = Rect2(gw / 2.0 + 20, gh - 86, 310, 56)
	for k in botoes:
		var rr: Rect2 = botoes[k]
		pen.retangulo(rr.position.x, rr.position.y, rr.end.x, rr.end.y, Color8(60, 20, 18), 0.95, false)
		pen.retangulo(rr.position.x, rr.position.y, rr.end.x, rr.end.y, ouro, 0.9, true)
		txt(rr.get_center().x, rr.get_center().y, "APLICAR O RECOMENDADO" if k == "aplicar" else "VOLTAR AO MENU", FONTE.PEQUENA, Color.WHITE, 1, fa_center, fa_middle)
	desenho_resetar()


func ev_cleanup() -> void:
	_tecla(KEY_D, false)
	_tecla(KEY_J, false)
	if G.toque != null:
		G.toque.visible = true
