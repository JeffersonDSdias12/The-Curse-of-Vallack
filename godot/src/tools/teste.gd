extends Node
# Ferramenta de desenvolvimento: roteiro de teste automático com capturas de tela.
# Uso: godot --path godot -- teste=<roteiro> shots=<pasta>
# Cada passo: [segundos desde o passo anterior, ação, parâmetro]
#   "shot" nome | "tecla" keycode | "segura" [keycode, segundos] | "toque" Vector2
#   "arrasta" [de, para, segundos] (dedo do analógico) | "sair"

var roteiro: Array = []
var pasta := "user://shots"
var passo := 0
var espera := 0.0
var segurando: Array = []      # [keycode, tempo restante]
var arrasto = null             # {de, para, t, dur}
var _perf_frames := 0
var _perf_t0 := 0
var _inim = null               # inimigo criado pelo roteiro

const ROTEIROS := {
	"intro": [
		[3.0, "shot", "i0_video"],
		[2.5, "shot", "i1_video"],
		[6.0, "shot", "i2_video"],
		[10.5, "shot", "i3_aviso"],
		[1.5, "tecla", KEY_ENTER],
		[2.0, "shot", "i4_titulo"],
		[16.0, "shot", "i5_menu"],
		[0.5, "sair", null],
	],
	# o vídeo NÃO pode ser pulado: toque, ENTER e ESC são ignorados até ele acabar
	"intro_pular": [
		[2.0, "shot", "p0_video"],
		[0.2, "toque", Vector2(640, 360)],
		[0.3, "tecla", KEY_ENTER],
		[0.3, "tecla", KEY_ESCAPE],
		[1.0, "shot", "p1_ainda_video"],
		[15.5, "shot", "p2_fim_video"],
		[2.5, "shot", "p3_aviso"],
		[0.5, "sair", null],
	],
	# v1.19: TESTE DE DESEMPENHO (obj_benchmark) do começo ao fim, com fotos
	"benchmark": [
		[2.0, "bench", null],
		[3.0, "shot", "b00_menu"],
		[30.0, "shot", "b01_vila"],
		[25.0, "shot", "b02_combate"],
		[25.0, "shot", "b03_arvore"],
		[40.0, "shot", "b04_resultado"],
		[1.0, "sair", null],
	],
	# v1.19: vídeo novo, aviso novo e a cortina em brasa no meio de cada troca de tela
	# (começa com "intro": o teste não pula a abertura)
	"intro_transicoes": [
		[3.0, "shot", "tr00_video"],
		[4.0, "shot", "tr00b_video"],
		[5.0, "shot", "tr01_aviso"],
		[2.0, "shot", "tr01b_aviso"],
		[0.5, "tecla", KEY_ENTER],
		[2.0, "shot", "tr01c_titulo"],
		[16.0, "shot", "tr02_menu"],
		[0.3, "toque_menu", 3],
		[0.1, "shot", "tr03_veu_opcoes"],
		[0.8, "shot", "tr04_opcoes"],
		[0.3, "tecla", KEY_ESCAPE],
		[0.12, "shot", "tr05_veu_volta"],
		[1.0, "toque_menu", 0],
		[0.12, "shot", "tr06_veu_abre"],
		[1.5, "shot", "tr07_aberto"],
		[0.3, "tecla", KEY_ENTER],
		[0.3, "shot", "tr08_seguinte"],
		[1.5, "shot", "tr09_seguinte"],
		[0.3, "tecla", KEY_ENTER],
		[0.3, "shot", "tr10_seguinte"],
		[1.5, "shot", "tr11_seguinte"],
		[0.5, "tecla", KEY_ESCAPE],
		[0.4, "shot", "tr12_loading_cortina"],
		[0.3, "shot", "tr12b_loading_cortina"],
		[0.3, "shot", "tr12c_loading_cortina"],
		[1.5, "shot", "tr13_loading"],
		[0.5, "sair", null],
	],
	"jogo": [
		[2.5, "shot", "01_menu"],
		[0.2, "tecla", KEY_ENTER],
		[1.2, "shot", "02_dificuldade"],
		[0.2, "tecla", KEY_ENTER],
		[2.0, "shot", "03_cutscene"],
		[0.5, "tecla", KEY_ESCAPE],
		[2.0, "shot", "04_capitulo"],
		[5.5, "shot", "05_tutorial"],
		[4.0, "tecla", KEY_ENTER],
		[1.5, "shot", "06_jogo"],
		[0.1, "segura", [KEY_RIGHT, 2.5]],
		[1.0, "shot", "07_andando"],
		[2.0, "tecla", KEY_J],
		[0.15, "shot", "08_ataque"],
		[0.6, "tecla", KEY_W],
		[0.2, "shot", "09_pulo"],
		[1.5, "tecla", KEY_ESCAPE],
		[1.0, "shot", "10_pausa"],
		[0.3, "tecla", KEY_ESCAPE],
		[1.0, "tecla", KEY_TAB],
		[1.2, "shot", "11_armas"],
		[0.3, "tecla", KEY_ESCAPE],
		[1.0, "shot", "12_volta"],
		[0.5, "sair", null],
	],
	# v1.20: PONTES QUE DESABAM e PISO FRÁGIL — atravessa a de madeira e a de pedra
	# correndo, depois para em cima de uma laje frágil até ela ceder
	"pontes": [
		[2.0, "jogo_direto", null],
		[1.5, "acelerar_carregamento", null],
		[3.0, "acelerar_carregamento", null],
		[4.0, "pular_dialogo", null],
		[1.0, "teleporta_xy", [1290.0, 690.0]],
		[1.0, "shot", "p01_madeira_antes"],
		[0.1, "segura", [KEY_D, 2.4]],
		[0.75, "shot", "p02_madeira_aviso"],
		[0.5, "shot", "p03_madeira_caindo"],
		[0.5, "shot", "p04_madeira_caindo2"],
		[1.6, "shot", "p05_madeira_depois"],
		[0.5, "teleporta_xy", [1740.0, 690.0]],
		[1.0, "shot", "p06_pedra_antes"],
		[0.1, "segura", [KEY_D, 2.6]],
		[0.8, "shot", "p07_pedra_aviso"],
		[0.6, "shot", "p08_pedra_caindo"],
		[0.6, "shot", "p09_pedra_caindo2"],
		[1.6, "shot", "p10_pedra_depois"],
		[0.5, "teleporta_xy", [990.0, 690.0]],
		[1.0, "shot", "p11_fragil_antes"],
		[0.1, "segura", [KEY_D, 0.26]],
		[0.2, "segura", [KEY_W, 0.1]],
		[0.25, "segura", [KEY_D, 0.12]],
		[0.6, "shot", "p12_fragil_tremendo"],
		[0.5, "shot", "p13_fragil_cedeu"],
		[1.2, "shot", "p14_fragil_queda"],
		[2.5, "shot", "p15_depois"],
		[0.5, "sair", null],
	],
	# corre para a direita, vira para a esquerda e volta: registra a posição na tela
	"virar": [
		[2.5, "tecla", KEY_ENTER],
		[1.2, "tecla", KEY_ENTER],
		[2.0, "tecla", KEY_ESCAPE],
		[11.0, "tecla", KEY_ENTER],
		[1.5, "teleporta", 1500.0],
		[1.5, "registrar", 4.6],
		[0.0, "segura", [KEY_D, 1.4]],
		[1.5, "segura", [KEY_A, 1.4]],
		[1.5, "segura", [KEY_D, 1.4]],
		[1.8, "sair", null],
	],
	"perf": [
		[2.5, "tecla", KEY_ENTER],
		[1.2, "tecla", KEY_ENTER],
		[2.0, "tecla", KEY_ESCAPE],
		[11.0, "tecla", KEY_ENTER],
		[3.0, "perf_on", null],
		[3.0, "perf", "parado"],
		[0.0, "segura", [KEY_D, 3.0]],
		[3.0, "perf", "andando"],
		[0.5, "sair", null],
	],
	# FPS real (sem o medidor) com os controles de toque na tela
	"fps": [
		[2.0, "toque", Vector2(640, 60)],
		[0.5, "toque_menu", 0],
		[1.0, "toque_dif", 1],
		[2.0, "toque", Vector2(90, 43)],
		[11.0, "toque", Vector2(640, 360)],
		[3.0, "fps_on", null],
		[3.0, "fps", "parado_toque"],
		[0.0, "shot", "fps_toque_parado"],
		[0.1, "arrasta", [Vector2(200, 560), Vector2(290, 560), 9.0]],
		[1.5, "pular_dialogo", null],
		[0.5, "pular_dialogo", null],
		[0.5, "pular_dialogo", null],
		[0.5, "fps_on", null],
		[3.0, "fps", "andando_toque"],
		[0.0, "shot", "fps_toque_andando"],
		[0.5, "sair", null],
	],
	"menus": [
		[2.0, "toque", Vector2(640, 60)],
		[0.5, "shot", "m00_menu"],
		[0.3, "toque_menu", 2],
		[1.2, "shot", "m01_opcoes"],
		[0.3, "toque_c", [150.0, 140.0 + 9 * 31.0]],
		[0.6, "toque_c", [150.0, 140.0 + 10 * 31.0]],
		[0.8, "shot", "m02_opcoes_mudou"],
		[0.3, "toque", Vector2(90, 43)],
		[1.0, "toque_menu", 0],
		[1.0, "toque_dif", 1],
		[2.0, "toque", Vector2(90, 43)],
		[11.0, "toque", Vector2(640, 360)],
		[2.0, "shot", "m03_jogo"],
		[0.5, "info", null],
		[0.5, "toque_pausa", null],
		[1.0, "toque_c", [0.0, 237.6 + 4 * 56]],
		[0.5, "shot", "m04_confirmar"],
		[0.3, "toque_c", [0.0, 237.6 + 4 * 56]],
		[5.0, "shot", "m05_menu"],
		[0.5, "toque_menu", 1],
		[1.2, "shot", "m06_carregar"],
		[0.3, "toque_frac", [0.25, 360.0]],
		[4.0, "shot", "m07_carregando"],
		[8.0, "toque", Vector2(640, 360)],
		[2.0, "shot", "m08_jogo_carregado"],
		[0.5, "info", null],
		[0.5, "sair", null],
	],
	"toque": [
		[2.0, "toque", Vector2(640, 60)],
		[1.0, "shot", "t01_menu"],
		[0.5, "toque_menu", 0],
		[1.2, "shot", "t02_dificuldade"],
		[0.3, "toque_dif", 1],
		[2.0, "shot", "t03_cutscene"],
		[0.5, "toque", Vector2(640, 360)],
		[1.0, "shot", "t04_cutscene2"],
		[0.3, "toque", Vector2(90, 43)],
		[8.0, "shot", "t05_tutorial"],
		[3.0, "toque", Vector2(640, 360)],
		[1.5, "shot", "t06_jogo"],
		[0.1, "arrasta", [Vector2(200, 560), Vector2(290, 560), 2.5]],
		[1.2, "shot", "t07_andando"],
		[1.6, "botao", "ATACAR"],
		[0.15, "shot", "t08_ataque"],
		[0.8, "botao", "PULAR"],
		[0.25, "shot", "t09_pulo"],
		[1.5, "toque_pausa", null],
		[1.0, "shot", "t10_pausa"],
		[0.5, "toque", Vector2(90, 43)],
		[1.0, "toque_armas", null],
		[1.2, "shot", "t11_armas"],
		[0.5, "toque", Vector2(90, 43)],
		[1.0, "shot", "t12_volta"],
		[0.5, "sair", null],
	],
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		if a.begins_with("teste="):
			match a:
				"teste=corrida":
					roteiro = _corrida()
				"teste=chefe":
					roteiro = _chefe()
				"teste=fase2":
					roteiro = _fase2()
				"teste=fim":
					roteiro = _fim()
				"teste=castlevania":
					roteiro = _castlevania()
				"teste=terreno":
					roteiro = _terreno()
				"teste=vila":
					roteiro = _vila()
				"teste=andares":
					roteiro = _andares()
				"teste=escada":
					roteiro = _escada()
				"teste=caixas":
					roteiro = _caixas()
				"teste=chave":
					roteiro = _chave()
				"teste=arvore":
					roteiro = _arvore()
				"teste=castelo":
					roteiro = _castelo()
				"teste=v117":
					roteiro = _v117()
				"teste=combate":
					roteiro = _combate()
				"teste=varredura":
					roteiro = _varredura()
				"teste=surgir":
					roteiro = _surgir()
				"teste=vila_fogo":
					roteiro = _vila_fogo()
				"teste=arvore_invoca":
					roteiro = _arvore_invoca()
				"teste=movimento":
					roteiro = _movimento()
				"teste=segunda_vida":
					roteiro = _segunda_vida()
				"teste=camera":
					roteiro = _camera()
				"teste=hud":
					roteiro = _hud()
				"teste=pontes":
					roteiro = _pontes()
				_:
					roteiro = ROTEIROS.get(a.substr(6), [])
		elif a.begins_with("shots="):
			pasta = a.substr(6)
		elif a.begins_with("perfil="):
			G.cfg_desempenho = int(a.substr(7))     # 1 mínimo .. 4 máximo
		elif a == "fps30":
			G.cfg_fps = 0
			G.cfg_desempenho = Desempenho.PERSONALIZADO     # o automático não troca o modo do teste
	DirAccess.make_dir_recursive_absolute(pasta)
	if not roteiro.is_empty():
		espera = roteiro[0][0]
	print("[teste] roteiro com ", roteiro.size(), " passos")


var _registrar := 0.0
var _reg_ant := Vector2.ZERO


func _process(dt: float) -> void:
	if _registrar > 0:
		_registrar -= dt
		var p = G.lib.instance_find("obj_player", 0)
		if p != null:
			var tela: float = (p.x - G.view_x) * G.mundo_k
			print("[pos] t=%.3f x=%.1f vx=%.1f tela=%.1f dtela=%.1f velh=%.2f facing=%d spr=%s img=%.2f" % [
				Time.get_ticks_msec() / 1000.0, p.x, G.view_x, tela, tela - _reg_ant.x, p.velh, p.facing,
				p.sprite_index.nome if p.sprite_index != null else "-", p.image_index])
			_reg_ant = Vector2(tela, 0)
	for i in range(segurando.size() - 1, -1, -1):
		segurando[i][1] -= dt
		if segurando[i][1] <= 0:
			_tecla(segurando[i][0], false)
			segurando.remove_at(i)
	if arrasto != null:
		arrasto.t += dt
		var k := clampf(arrasto.t / arrasto.dur, 0, 1)
		var e := InputEventScreenDrag.new()
		e.index = 1
		e.position = _janela(arrasto.de.lerp(arrasto.para, minf(1, k * 4)))
		Input.parse_input_event(e)
		if k >= 1:
			var s := InputEventScreenTouch.new()
			s.index = 1
			s.position = e.position
			s.pressed = false
			Input.parse_input_event(s)
			arrasto = null
	if passo >= roteiro.size():
		return
	espera -= dt
	if espera > 0:
		return
	var p: Array = roteiro[passo]
	passo += 1
	if passo < roteiro.size():
		espera = roteiro[passo][0]
	_executar(p[1], p[2])


# atravessa a fase: segura para a direita, ataca, pula e passa os diálogos
func _corrida() -> Array:
	var r := [
		[2.5, "tecla", KEY_ENTER],
		[1.2, "tecla", KEY_ENTER],
		[2.0, "tecla", KEY_ESCAPE],
		[11.0, "tecla", KEY_ENTER],
		[1.5, "shot", "c00"],
	]
	for i in 140:
		if i % 10 == 0:
			r.append([0.0, "segura", [KEY_D, 5.2]])
		r.append([0.25, "tecla", KEY_J])
		r.append([0.25, "tecla", [KEY_W, KEY_J, KEY_I, KEY_SPACE][i % 4]])
		if i % 12 == 11:
			r.append([0.0, "shot", "c%02d" % (i / 12 + 1)])
	r.append([0.5, "sair", null])
	return r


func _inicio() -> Array:
	return [
		[2.5, "tecla", KEY_ENTER],
		[1.2, "tecla", KEY_ENTER],
		[2.0, "tecla", KEY_ESCAPE],
		[11.0, "tecla", KEY_ENTER],
	]


# luta contra o boss da fase 1 (sem morrer), depois morre de propósito e tenta de novo
func _chefe() -> Array:
	var r := _inicio()
	r.append([1.5, "teleporta", 4300.0])
	r.append([1.0, "shot", "b00"])
	for i in 120:
		if i % 10 == 0:
			r.append([0.0, "segura", [KEY_D, 1.2]])
			r.append([0.0, "cura", null])
		r.append([0.25, "tecla", KEY_J])
		r.append([0.25, "tecla", [KEY_J, KEY_I, KEY_J, KEY_SPACE, KEY_W][i % 5]])
		if i % 15 == 14:
			r.append([0.0, "shot", "b%02d" % (i / 15 + 1)])
	r.append([0.5, "matar", null])
	r.append([3.5, "shot", "b_derrota"])
	r.append([0.3, "tecla", KEY_ENTER])
	r.append([3.0, "shot", "b_tentar_de_novo"])
	r.append([0.5, "sair", null])
	return r


# derrota o boss da fase 1 (dano forçado), segue em frente e passa pelo fim da demo
func _fim() -> Array:
	var r := _inicio()
	r.append([1.5, "teleporta", 4300.0])
	r.append([2.0, "shot", "e00"])
	for i in 60:
		r.append([0.3, "pular_dialogo", null])
		r.append([0.3, "dano_boss", null])
		if i % 5 == 0:
			r.append([0.0, "cura", null])
		if i % 15 == 14:
			r.append([0.0, "shot", "e%02d" % (i / 15 + 1)])
	r.append([3.0, "shot", "e_boss_morto"])
	for i in 6:
		r.append([0.0, "pular_dialogo", null])
		r.append([0.0, "segura", [KEY_D, 1.6]])
		r.append([0.0, "cura", null])
		r.append([1.8, "shot", "e_anda%d" % i])
	r.append([4.0, "shot", "e_resultado1"])
	r.append([3.0, "shot", "e_resultado2"])
	r.append([0.5, "tecla", KEY_ENTER])
	r.append([3.0, "shot", "e_obrigado"])
	r.append([0.5, "tecla", KEY_ENTER])
	for k in 6:
		r.append([4.5 if k > 0 else 2.5, "shot", "e_creditos%d" % k])
	r.append([9.0, "shot", "e_saindo"])
	r.append([4.0, "shot", "e_menu"])
	r.append([0.5, "sair", null])
	return r


# v1.18: VARREDURA de travadas — atravessa a fase lutando e imprime cada quadro
# mais lento que 30 ms com o que custou caro nele ([pico] no log)
func _varredura() -> Array:
	var r := [
		[0.5, "picos_on", 30.0],
		[1.5, "jogo_direto", null],
		[1.5, "acelerar_carregamento", null],
		[3.0, "acelerar_carregamento", null],
		[4.0, "pular_dialogo", null],
	]
	for i in 200:
		if i % 10 == 0:
			r.append([0.0, "segura", [KEY_D, 5.2]])
			r.append([0.0, "cura", null])
			r.append([0.0, "pular_dialogo", null])
		r.append([0.25, "tecla", KEY_J])
		r.append([0.25, "tecla", [KEY_W, KEY_J, KEY_I, KEY_SPACE][i % 4]])
		if i % 20 == 19:
			r.append([0.0, "fx_resumo", "passo%d" % i])
	r.append([0.5, "sair", null])
	return r


# v1.19: a árvore invoca servos contra quem fica colado batendo (ou parado num
# canto) e faz CHUVA DE FOGO nos marcos da vida
func _arvore_invoca() -> Array:
	var r := [
		[1.5, "jogo_direto", null],
		[1.5, "acelerar_carregamento", null],
		[3.0, "acelerar_carregamento", null],
		[4.0, "pular_dialogo", null],
		[0.5, "ir_para", ["obj_boss_01", 120.0]],
	]
	for i in 6:
		r.append([0.6, "pular_dialogo", null])
	r.append([0.5, "arvore_pronta", null])
	r.append([0.0, "arvore_info", "inicio"])
	# colado no tronco, batendo sem parar (com cura para não morrer)
	for i in 36:
		r.append([0.25, "tecla", KEY_J])
		if i % 6 == 0:
			r.append([0.0, "cura", null])
			r.append([0.0, "ir_para", ["obj_boss_01", 120.0]])
		if i % 4 == 0:
			r.append([0.0, "arvore_info", "batendo%d" % i])
		if i == 24 or i == 30:
			r.append([0.0, "shot", "a_invoca%d" % i])
	r.append([1.5, "shot", "a_servos"])
	r.append([0.0, "arvore_info", "servos"])
	# marco de 85%: CHUVA DE FOGO na arena inteira
	r.append([0.3, "limpar", null])
	r.append([0.2, "arvore_vida", 0.84])
	for i in 8:
		r.append([0.35, "cura", null])
		r.append([0.0, "arvore_info", "chuva%d" % i])
		if i == 2 or i == 5:
			r.append([0.0, "shot", "a_chuva%d" % i])
	# canto: parado longe, sem levar dano
	r.append([0.5, "limpar", null])
	r.append([0.0, "arvore_pronta", null])
	r.append([0.0, "ir_para", ["obj_boss_01", 700.0]])
	for i in 12:
		r.append([1.0, "cura", null])
		r.append([0.0, "arvore_info", "canto%d" % i])
	r.append([1.5, "shot", "a_canto"])
	r.append([0.5, "sair", null])
	return r


# v1.19: o incêndio das casas pela vila (fotos em vários pontos da Fase 1)
func _vila_fogo() -> Array:
	var r := [
		[1.5, "jogo_direto", null],
		[1.5, "acelerar_carregamento", null],
		[3.0, "acelerar_carregamento", null],
		[4.0, "pular_dialogo", null],
		[0.0, "perf_on", null],
	]
	for i in 9:
		r.append([0.6, "teleporta_xy", [500.0 + i * 850.0, 690.0]])
		r.append([0.0, "limpar", null])
		r.append([0.0, "pular_dialogo", null])
		r.append([1.2, "shot", "v%02d" % i])
	r.append([0.0, "perf", "vila"])
	r.append([0.5, "sair", null])
	return r


# v1.19: inimigos escalando do portal, o grito e a fala de batalha de Twilight
func _surgir() -> Array:
	var r := [
		[1.5, "jogo_direto", null],
		[1.5, "acelerar_carregamento", null],
		[3.0, "acelerar_carregamento", null],
		[4.0, "teleporta_xy", [1500.0, 690.0]],
		[1.0, "pular_dialogo", null],
		[0.5, "pular_dialogo", null],
		[1.0, "limpar", null],
		[0.2, "inimigo_portal", ["obj_inimigo_01", 150.0]],
	]
	for i in 30:
		r.append([0.1, "shot", "s%02d" % i])
	r.append([0.5, "sair", null])
	return r


# v1.19: segunda vida do Carrasco, cura da sequência e chuva de brasas da Árvore
func _segunda_vida() -> Array:
	var r := [
		[1.5, "jogo_direto", null],
		[1.5, "acelerar_carregamento", null],
		[3.0, "acelerar_carregamento", null],
		[4.0, "pular_dialogo", null],
		[0.5, "ir_para", ["obj_mini_boss", 160.0]],
		[1.5, "pular_dialogo", null],
		[0.6, "pular_dialogo", null],
		[0.6, "pular_dialogo", null],
		[0.5, "mini_info", "antes"],
		[0.0, "mini_vencer", null],
		[0.0, "mini_info", "1a_sequencia"],
	]
	for i in 10:
		r.append([0.3, "mini_info", "renascendo%d" % i])
		r.append([0.0, "shot", "m%02d" % i])
	r.append([0.5, "pular_dialogo", null])
	r.append([0.5, "pular_dialogo", null])
	r.append([0.5, "mini_info", "depois"])
	r.append([0.0, "cura_qte", null])
	r.append([0.2, "mini_vencer", null])
	r.append([0.0, "mini_info", "2a_sequencia"])
	r.append([1.0, "shot", "m_morto"])
	r.append([1.0, "pular_dialogo", null])
	r.append([0.5, "ir_para", ["obj_boss_01", 420.0]])
	r.append([1.0, "pular_dialogo", null])
	r.append([0.6, "pular_dialogo", null])
	r.append([0.3, "arvore_chuva", null])
	for i in 8:
		r.append([0.2, "shot", "a%02d" % i])
	r.append([1.0, "sair", null])
	return r


# v1.19: parado, corrida e andar (preso na teia) com as sprites novas
func _movimento() -> Array:
	var r := [
		[1.5, "jogo_direto", null],
		[1.5, "acelerar_carregamento", null],
		[3.0, "acelerar_carregamento", null],
		[4.0, "teleporta_xy", [1500.0, 690.0]],
		[1.0, "pular_dialogo", null],
		[0.5, "pular_dialogo", null],
		[1.0, "limpar", null],
	]
	for i in 4:
		r.append([0.15, "heroi_spr", "parado"])
		r.append([0.0, "shot", "p%d" % i])
	r.append([0.0, "segura", [KEY_D, 2.0]])
	for i in 8:
		r.append([0.12, "heroi_spr", "corre"])
		r.append([0.0, "shot", "c%d" % i])
	r.append([1.2, "teia", 300.0])
	r.append([0.0, "segura", [KEY_A, 2.5]])
	for i in 8:
		r.append([0.15, "heroi_spr", "teia"])
		r.append([0.0, "shot", "a%d" % i])
	r.append([1.5, "sair", null])
	return r


# v1.18: luta contra um grupo (orçamento dos efeitos de combate e balões de ataque)
func _combate() -> Array:
	var r := [
		[2.0, "jogo_direto", null],
		[1.5, "acelerar_carregamento", null],
		[3.0, "acelerar_carregamento", null],
		[4.0, "teleporta_xy", [1500.0, 690.0]],
		[1.0, "pular_dialogo", null],
		[0.5, "pular_dialogo", null],
	]
	r.append([1.0, "limpar", null])
	r.append([0.2, "inimigo_tipo", ["obj_inimigo_01", 70.0]])
	r.append([0.0, "inimigo_tipo", ["obj_inimigo_01", 110.0]])
	r.append([0.0, "inimigo_tipo", ["obj_esqueleto", 150.0]])
	r.append([0.0, "inimigo_tipo", ["obj_porco", 220.0]])
	r.append([0.0, "inimigo_tipo", ["obj_aranha", 180.0]])
	r.append([0.0, "fps_on", null])
	for i in 60:
		if i % 8 == 0:
			r.append([0.0, "cura", null])
		r.append([0.12, "tecla", [KEY_J, KEY_J, KEY_I, KEY_J][i % 4]])
		if i % 6 == 5:
			r.append([0.0, "shot", "cb%02d" % (i / 6)])
	r.append([0.0, "fps", "combate"])
	r.append([0.5, "sair", null])
	return r


# HUD gótico, botão ABRIR do baú (toque), golpe fatal e barra do chefe embaixo
func _castlevania() -> Array:
	var r := _inicio()
	r.append([1.5, "toque", Vector2(640, 360)])      # modo toque (fecha o tutorial)
	r.append([1.0, "bau", 30.0])
	r.append([0.6, "shot", "cv01_abrir"])
	r.append([0.3, "botao", "INTERAGIR"])
	r.append([0.8, "shot", "cv02_bau_aberto"])
	r.append([1.5, "inimigo", 80.0])
	r.append([2.0, "botao", "ATACAR"])
	r.append([0.08, "shot", "cv03_golpe"])
	r.append([0.4, "botao", "ATACAR"])
	r.append([0.5, "inimigo_fraco", null])
	r.append([0.1, "botao", "ATAQUE_FORTE"])
	r.append([0.6, "shot", "cv04_finalizavel"])
	r.append([0.1, "botao", "ATAQUE_SALTO"])     # finalizador: o golpe fatal
	for k in 8:
		r.append([0.25, "shot", "cv05_fatal%d" % k])
	r.append([0.2, "inimigo_matar", null])
	r.append([0.3, "shot", "cv06_chamas"])
	r.append([1.0, "teleporta", 4300.0])
	r.append([0.0, "segura", [KEY_D, 1.5]])
	r.append([4.0, "toque", Vector2(640, 360)])
	r.append([0.5, "pular_dialogo", null])
	r.append([3.0, "shot", "cv07_chefe"])
	r.append([0.5, "sair", null])
	return r


# analógico + 4 botões, abismo, plataformas e a morte por queda (fase 1)
func _terreno() -> Array:
	var r := _inicio()
	r.append([1.5, "toque", Vector2(640, 360)])      # modo toque (fecha o tutorial)
	r.append([1.0, "teleporta", 1305.0])
	r.append([1.2, "shot", "tr01_abismo"])
	r.append([0.2, "teleporta", 1470.0])
	r.append([1.0, "shot", "tr02_plataformas"])
	r.append([0.2, "teleporta", 3990.0])
	r.append([1.0, "segura", [KEY_D, 1.2]])
	r.append([0.6, "shot", "tr03_caindo"])
	r.append([4.0, "shot", "tr04_morreu"])
	r.append([0.5, "sair", null])
	return r


# passeio pelo cenário desenhado da fase 1 (fotos em vários pontos)
func _vila() -> Array:
	var r := _inicio()
	r.append([1.5, "toque", Vector2(640, 360)])
	for px in [380.0, 900.0, 1600.0, 2060.0, 2500.0, 3350.0, 3900.0, 4500.0]:
		r.append([0.5, "teleporta", px])
		r.append([0.6, "pular_dialogo", null])
		r.append([0.9, "shot", "v_%d" % int(px)])
	r.append([0.5, "sair", null])
	return r


# v1.13: fase em andares (escadaria, passarela de mão única, ▼ + PULO, ilhas,
# adarve, torre do arqueiro) e a vila mais densa
func _andares() -> Array:
	var r := _inicio()
	r.append([1.5, "toque", Vector2(640, 360)])
	# o morador fala quando o herói passa: conversa primeiro, depois o teste
	r.append([1.0, "teleporta_xy", [430.0, 690.0]])
	r.append([1.5, "pular_dialogo", null])
	r.append([1.0, "pular_dialogo", null])
	r.append([0.5, "teleporta_xy", [250.0, 690.0]])
	r.append([0.8, "segura", [KEY_D, 1.6]])
	r.append([0.6, "shot", "an01_escada"])
	r.append([1.4, "posicao", "subiu a escada (esperado y=605)"])
	r.append([0.2, "shot", "an02_ponte"])
	r.append([0.0, "segura", [KEY_S, 0.5]])
	r.append([0.1, "tecla", KEY_W])
	r.append([0.8, "posicao", "desceu pela ponte (esperado y=693)"])
	r.append([0.1, "shot", "an03_desceu"])
	r.append([0.3, "segura", [KEY_W, 0.45]])
	r.append([1.2, "posicao", "pulou de baixo para a ponte (esperado y=605)"])
	r.append([0.1, "teleporta_xy", [1000.0, 420.0]])
	r.append([1.2, "posicao", "adarve (esperado y=470)"])
	r.append([0.1, "shot", "an04_adarve"])
	r.append([0.1, "teleporta_xy", [1400.0, 480.0]])
	r.append([1.2, "posicao", "ilha sobre o abismo (esperado y=560)"])
	r.append([0.1, "shot", "an05_ilha"])
	r.append([0.1, "teleporta_xy", [3420.0, 690.0]])
	r.append([0.5, "segura", [KEY_D, 1.2]])
	r.append([1.5, "posicao", "torre do arqueiro (esperado y=605)"])
	r.append([0.1, "shot", "an06_torre"])
	r.append([0.1, "teleporta_xy", [3762.0, 520.0]])
	r.append([1.0, "shot", "an07_espinhos"])
	for px in [150.0, 2150.0, 4400.0]:
		r.append([0.2, "teleporta_xy", [px, 690.0]])
		r.append([0.6, "pular_dialogo", null])
		r.append([0.9, "shot", "an_v%d" % int(px)])
	r.append([0.5, "sair", null])
	return r


# v1.13: o herói parado no meio da escadaria (os pés têm que pisar nos degraus)
# e virando de lado (o corpo não pode pular)
func _escada() -> Array:
	var r := _inicio()
	r.append([1.5, "toque", Vector2(640, 360)])
	r.append([1.0, "teleporta_xy", [430.0, 690.0]])
	r.append([1.5, "pular_dialogo", null])
	r.append([1.0, "pular_dialogo", null])
	for px in [340.0, 362.0, 384.0]:
		r.append([0.5, "teleporta_xy", [px, 600.0]])
		r.append([0.8, "posicao", "escada x=%d" % int(px)])
		r.append([0.0, "shot", "es_%d" % int(px)])
	r.append([0.2, "teleporta_xy", [560.0, 600.0]])
	r.append([0.8, "segura", [KEY_D, 0.2]])
	r.append([0.3, "shot", "vi_direita"])
	r.append([0.0, "posicao", "antes de virar"])
	r.append([0.0, "segura", [KEY_A, 0.06]])
	r.append([0.07, "shot", "vi_esquerda"])
	r.append([0.0, "posicao", "depois de virar"])
	r.append([0.5, "sair", null])
	return r


# v1.14: portão trancado -> escada de mão -> plataforma pendurada -> corda -> forte
# -> guardiões -> baú selado -> chave -> portão aberto
func _chave() -> Array:
	var r := _inicio()
	r.append([1.5, "toque", Vector2(640, 360)])
	r.append([1.0, "teleporta_xy", [430.0, 690.0]])
	r.append([1.5, "pular_dialogo", null])
	r.append([1.0, "pular_dialogo", null])
	r.append([0.4, "teleporta_xy", [2380.0, 690.0]])
	r.append([0.2, "segura", [KEY_D, 1.2]])
	r.append([1.3, "shot", "k1_portao"])
	r.append([0.0, "estado_chave", "portao trancado (visto)"])
	r.append([0.2, "teleporta_xy", [2142.0, 690.0]])
	r.append([0.3, "segura", [KEY_W, 1.6]])
	r.append([0.5, "shot", "k2_escada"])
	r.append([0.0, "estado_chave", "subindo a escada"])
	r.append([1.4, "posicao", "plataforma pendurada (esperado y=590)"])
	r.append([0.0, "shot", "k3_pendurada"])
	r.append([0.2, "teleporta_xy", [2344.0, 520.0]])
	r.append([0.0, "segura", [KEY_W, 2.8]])
	r.append([0.8, "shot", "k4_corda"])
	r.append([0.0, "estado_chave", "na corda"])
	r.append([2.4, "posicao", "alto do forte (esperado y=360)"])
	r.append([0.0, "shot", "k5_forte"])
	r.append([0.0, "estado_chave", "arena"])
	r.append([1.8, "shot", "k6_guardioes"])
	for k in 5:
		r.append([0.8, "matar_guardioes", null])
	r.append([2.0, "estado_chave", "selo"])
	r.append([0.1, "teleporta_xy", [2196.0, 360.0]])
	r.append([0.4, "tecla", KEY_E])
	r.append([0.6, "shot", "k7_chave"])
	r.append([1.4, "estado_chave", "pegou a chave"])
	r.append([0.1, "teleporta_xy", [2380.0, 690.0]])
	r.append([0.2, "segura", [KEY_D, 1.0]])
	r.append([1.2, "shot", "k8_abrindo"])
	r.append([0.4, "segura", [KEY_D, 1.4]])
	r.append([1.6, "posicao", "passou do portão (esperado x > 2480)"])
	r.append([0.0, "shot", "k9_passou"])
	r.append([0.0, "estado_chave", "fim"])
	r.append([0.5, "sair", null])
	return r


# v1.14: máscaras e áreas de golpe (F1) de cada inimigo ao lado do herói
func _caixas() -> Array:
	var r := _inicio()
	r.append([1.5, "toque", Vector2(640, 360)])
	r.append([1.0, "teleporta_xy", [430.0, 690.0]])
	r.append([1.5, "pular_dialogo", null])
	r.append([1.0, "pular_dialogo", null])
	r.append([0.2, "caixas", true])
	for o in ["obj_inimigo_01", "obj_esqueleto", "obj_porco", "obj_aranha", "obj_inimigo_02", "obj_inimigo_03"]:
		r.append([0.3, "teleporta_xy", [2140.0, 690.0]])
		r.append([0.1, "cura", null])
		r.append([0.0, "limpar", null])
		r.append([0.1, "inimigo_tipo", [o, 64.0]])
		r.append([0.9, "shot", "cx_%s_a" % o])
		r.append([0.0, "inim_info", null])
		r.append([0.0, "tecla", KEY_J])
		r.append([0.1, "shot", "cx_%s_b" % o])
		r.append([0.6, "shot", "cx_%s_c" % o])
		r.append([0.7, "shot", "cx_%s_d" % o])
		r.append([0.0, "inimigo_matar", null])
		r.append([1.5, "info", null])
	r.append([0.5, "sair", null])
	return r


# v1.13: chefe — o herói vai até o pé da árvore e bate (a árvore não pode sumir)
func _arvore() -> Array:
	var r := _inicio()
	r.append([1.5, "toque", Vector2(640, 360)])
	r.append([1.0, "teleporta_xy", [4300.0, 690.0]])
	r.append([0.2, "segura", [KEY_D, 1.5]])
	r.append([4.0, "pular_dialogo", null])
	r.append([1.0, "pular_dialogo", null])
	r.append([1.0, "chefe", null])
	r.append([0.0, "segura", [KEY_D, 1.2]])
	for k in 14:
		r.append([0.35, "tecla", KEY_J])
		r.append([0.0, "chefe", null])
		if k % 3 == 0:
			r.append([0.0, "shot", "ar%02d" % k])
	r.append([0.0, "segura", [KEY_D, 0.6]])
	for k in 8:
		r.append([0.35, "tecla", KEY_J])
		r.append([0.0, "chefe", null])
		if k % 2 == 0:
			r.append([0.0, "shot", "ar_atras%02d" % k])
	r.append([0.0, "segura", [KEY_A, 1.5]])
	r.append([1.6, "chefe", null])
	r.append([0.0, "shot", "ar_longe"])
	r.append([0.5, "sair", null])
	return r


# v1.13: o salão da fase 2 com a arte nova do castelo
func _castelo() -> Array:
	var r := _inicio()
	r.append([1.5, "sala", "Room2"])
	r.append([13.0, "tecla", KEY_ENTER])
	r.append([2.0, "tecla", KEY_ENTER])
	r.append([2.5, "pular_dialogo", null])
	r.append([1.0, "pular_dialogo", null])
	r.append([1.5, "shot", "ca01"])
	r.append([0.2, "teleporta_xy", [2300.0, 600.0]])
	r.append([1.2, "shot", "ca02"])
	r.append([0.5, "sair", null])
	return r


# v1.17: entra direto na fase 1 (sem menu / mapa), escala a escada e a corda,
# faz a sequência de 4 toques do ATACAR num inimigo e deixa o corpo arder
func _v117() -> Array:
	var r := [
		[2.0, "jogo_direto", null],
		[1.5, "acelerar_carregamento", null],
		[3.0, "acelerar_carregamento", null],
		[4.0, "shot", "v00_fase"],
		[0.3, "teleporta_xy", [430.0, 690.0]],
		[1.5, "pular_dialogo", null],
		[1.0, "pular_dialogo", null],
		[0.4, "teleporta_xy", [2142.0, 690.0]],
		[0.3, "segura", [KEY_W, 1.1]],
		[0.35, "shot", "v01_escada_a"],
		[0.2, "shot", "v02_escada_b"],
		[0.2, "shot", "v03_escada_c"],
		[0.5, "segura", [KEY_S, 0.5]],
		[0.25, "shot", "v04_desce"],
		[0.6, "teleporta_xy", [2344.0, 520.0]],
		[0.0, "segura", [KEY_W, 2.0]],
		[0.1, "shot", "v05_agarra"],
		[0.15, "shot", "v06_agarra2"],
		[0.45, "shot", "v07_corda"],
		[0.35, "shot", "v08_corda2"],
		[1.3, "teleporta_xy", [1900.0, 690.0]],
		[0.6, "limpar", null],
		[0.1, "cura", null],
		[0.1, "inimigo_tipo", ["obj_porco", 52.0]],
		[0.6, "tecla", KEY_J],
		[0.08, "shot", "v10_rapido_a"],
		[0.08, "shot", "v11_rapido_b"],
		[0.19, "tecla", KEY_J],
		[0.08, "shot", "v12_duplo_a"],
		[0.1, "shot", "v13_duplo_b"],
		[0.17, "tecla", KEY_J],
		[0.1, "shot", "v14_triplo_a"],
		[0.12, "shot", "v15_triplo_b"],
		[0.2, "tecla", KEY_J],
		[0.1, "shot", "v16_fren_a"],
		[0.15, "shot", "v17_fren_b"],
		[0.15, "shot", "v18_fren_c"],
		[0.15, "shot", "v19_fren_d"],
		[0.15, "shot", "v20_fren_e"],
		[0.15, "shot", "v21_fren_f"],
		[0.2, "info_golpe", null],
		[0.3, "inimigo_matar", null],
		[1.4, "shot", "v30_queima_a"],
		[0.7, "shot", "v31_queima_b"],
		[0.5, "sair", null],
	]
	return r


# vai direto para a fase 2 e atravessa lutando
func _fase2() -> Array:
	var r := _inicio()
	r.append([1.5, "sala", "Room2"])
	r.append([3.0, "shot", "f00"])
	r.append([5.5, "shot", "f01"])
	r.append([4.0, "tecla", KEY_ENTER])
	r.append([2.0, "shot", "f02"])
	for i in 160:
		if i % 10 == 0:
			r.append([0.0, "segura", [KEY_D, 4.5]])
			r.append([0.0, "cura", null])
		r.append([0.25, "tecla", KEY_J])
		r.append([0.25, "tecla", [KEY_W, KEY_J, KEY_I, KEY_SPACE][i % 4]])
		if i % 16 == 15:
			r.append([0.0, "shot", "f%02d" % (i / 16 + 3)])
	r.append([0.5, "sair", null])
	return r


# v1.20: lajes frágeis, ponte de madeira e ponte de pedra que desabam, abismo da árvore
func _pontes() -> Array:
	return [
		[1.5, "jogo_direto", null],
		[1.5, "acelerar_carregamento", null],
		[3.0, "acelerar_carregamento", null],
		[4.0, "pular_dialogo", null],
		[0.5, "teleporta_xy", [1290, 690]],
		[0.4, "shot", "p01_madeira_antes"],
		[0.0, "segura", [KEY_D, 2.4]],
		[0.7, "shot", "p02_madeira_correndo"],
		[0.7, "shot", "p03_madeira_caindo"],
		[1.2, "shot", "p04_madeira_depois"],
		[0.1, "posicao", "apos_madeira"],
		[0.1, "cura", null],
		[0.1, "teleporta_xy", [1740, 690]],
		[0.4, "shot", "p05_pedra_antes"],
		[0.0, "segura", [KEY_D, 2.6]],
		[0.8, "shot", "p06_pedra_correndo"],
		[0.8, "shot", "p07_pedra_caindo"],
		[1.3, "shot", "p08_pedra_depois"],
		[0.1, "posicao", "apos_pedra"],
		[0.1, "cura", null],
		[0.1, "teleporta_xy", [3990, 690]],
		[0.6, "shot", "p09_abismo_arvore"],
		[0.1, "posicao", "abismo_arvore"],
		# a laje frágil fica por último: quem demora em cima dela cai no abismo e morre
		[0.1, "teleporta_xy", [1083, 690]],
		[0.35, "shot", "p10_fragil_tremendo"],
		[0.1, "posicao", "na_laje"],
		[0.5, "shot", "p11_fragil_cedeu"],
		[0.1, "posicao", "laje_cedeu"],
		[1.2, "shot", "p12_caiu_no_abismo"],
		[0.5, "sair", null],
	]

# v1.20: menu com CONTINUAR / perfil, e a câmera de combate fechando no duelo
func _camera() -> Array:
	var r := [
		[9.0, "shot", "c00_menu"],
		[0.5, "jogo_direto", null],
		[1.5, "acelerar_carregamento", null],
		[3.0, "acelerar_carregamento", null],
		[4.0, "pular_dialogo", null],
		[0.5, "teleporta_xy", [2500, 690]],
		[0.6, "shot", "c01_sem_inimigo"],
		[0.1, "inimigo", 150],
		[1.6, "shot", "c02_duelo_enquadrado"],
		[0.1, "info_cam", "duelo"],
	]
	for i in 6:
		r.append([0.28, "tecla", KEY_J])
		r.append([0.06, "shot", "c1%d_golpe" % i])
		r.append([0.0, "info_cam", "golpe%d" % i])
	r.append([0.1, "inimigo_matar", null])
	r.append([0.08, "shot", "c20_morte"])
	r.append([0.0, "info_cam", "morte"])
	r.append([2.5, "info_cam", "depois"])
	r.append([0.1, "shot", "c21_relaxou"])
	r.append([0.5, "sair", null])
	return r


# v1.21: OPÇÕES novas, editor da HUD (2 / 4 / 8 dedos, tamanho, arrastar) e a HUD no jogo
func _hud() -> Array:
	return [
		[9.0, "toque", Vector2(640, 300)],
		[1.2, "menu_estado", ["opcoes", 11]],
		[1.0, "shot", "h00_opcoes"],
		[0.2, "menu_estado", ["hud", 0]],
		[1.0, "shot", "h01_editor_2dedos"],
		[0.2, "cfg", ["cfg_hud_modo", 1]],
		[0.4, "shot", "h02_editor_4dedos"],
		[0.2, "cfg", ["cfg_hud_modo", 2]],
		[0.4, "shot", "h03_editor_8dedos"],
		[0.2, "arrasta_botao", [GMObj.ACAO.ATACAR, Vector2(-260, -150), 0.6]],
		[0.3, "shot", "h04_arrastando"],
		[0.6, "hud_info", "depois_de_arrastar"],
		[0.1, "cfg", ["cfg_hud_tam", 1.3]],
		[0.4, "shot", "h05_tamanho_130"],
		[0.1, "toque_hud_linha", [0, 1]],
		[0.4, "hud_info", "toque_no_modo"],
		[0.1, "toque_hud_linha", [1, -1]],
		[0.4, "hud_info", "toque_no_tamanho"],
		[0.1, "toque_hud_linha", [3, 1]],
		[0.4, "hud_info", "restaurar"],
		[0.1, "cfg", ["cfg_hud_tam", 1.0]],
		[0.1, "cfg", ["cfg_hud_modo", 2]],
		[0.2, "jogo_direto", null],
		[1.5, "acelerar_carregamento", null],
		[3.0, "acelerar_carregamento", null],
		[4.0, "pular_dialogo", null],
		[0.5, "toque", Vector2(640, 200)],
		[0.6, "shot", "h06_jogo_8dedos"],
		[0.1, "cfg", ["cfg_hud_modo", 1]],
		[0.4, "shot", "h07_jogo_4dedos"],
		[0.1, "botao", "DEFENDER"],
		[0.3, "shot", "h08_defesa_4dedos"],
		[0.1, "hud_info", "fim"],
		[0.4, "sair", null],
	]


func _executar(acao: String, v) -> void:
	print("[teste] ", acao, " ", v)
	match acao:
		"shot":
			# v1.16: a trilha tocando em cada foto (confere os gatilhos da música)
			print("[teste] MUSICA=", G.musica_nome if G.musica_nome != "" else "(nenhuma)", " tocando=",
				G.musica_inst != null and G.audio_is_playing(G.musica_inst), " cena=", G.audio_cena, " sala=", G.room)
			await RenderingServer.frame_post_draw
			var img := get_viewport().get_texture().get_image()
			img.save_png(pasta.path_join(str(v) + ".png"))
		"tecla":
			_tecla(v, true)
			segurando.append([v, 0.1])
		"segura":
			_tecla(v[0], true)
			segurando.append([v[0], v[1]])
		"toque":
			_toque(0, v)
		"arrasta":
			var s := InputEventScreenTouch.new()
			s.index = 1
			s.position = _janela(v[0])
			s.pressed = true
			Input.parse_input_event(s)
			arrasto = {"de": v[0], "para": v[1], "t": 0.0, "dur": v[2]}
		"toque_menu":
			var m = G.lib.instance_find("obj_menu", 0)
			_toque(0, m.menu_caixa(v).get_center())
		"toque_dif":
			var m = G.lib.instance_find("obj_menu", 0)
			_toque(0, Vector2(G.gui_w / 2, m.dif_y(v)))
		"botao":
			var a: int = GMObj.ACAO[v]
			for b in G.toque.layout():
				if b[0] == a:
					_toque(2, b[1])
		"toque_pausa":
			_toque(2, Vector2(G.gui_w - 46, 44))
		"toque_armas":
			_toque(2, Vector2(G.gui_w - 118, 44))
		"teleporta":
			var p = G.lib.instance_find("obj_player", 0)
			if p != null:
				p.x = v
				p.y = 600.0
				G.cam_snap = true
		"teleporta_xy":
			var p = G.lib.instance_find("obj_player", 0)
			if p != null:
				p.x = v[0]
				p.y = v[1]
				p.velv = 0.0
				G.cam_snap = true
		"chefe":
			var b = G.lib.instance_find("obj_boss_01", 0)
			var p = G.lib.instance_find("obj_player", 0)
			if b != null and p != null:
				print("[teste] CHEFE x=", roundi(b.x), " dir=", b.dir, " est=", b.estado_ia, " spr=", b.sprite_index.nome if b.sprite_index != null else "-",
					" img=", snappedf(b.image_index, 0.1), " vis=", b.visible, " alfa=", snappedf(b.image_alpha, 0.01), " heroi=", roundi(p.x),
					" cam=", roundi(G.view_x), "..", roundi(G.view_x + G.view_w), " vida=", roundi(b.vida), " caixa=", roundi(b.bbox_left), "..", roundi(b.bbox_right), " ativo=", b.ativo, " inv=", b.tempo_invencivel, " acordado=", b.acordado)
		"posicao":
			var p = G.lib.instance_find("obj_player", 0)
			if p != null:
				print("[teste] POS x=", roundi(p.x), " y=", snappedf(p.y, 0.1), "  ", v)
		"cura":
			var p = G.lib.instance_find("obj_player", 0)
			if p != null:
				p.vida = p.vida_max
		"bau":
			var p = G.lib.instance_find("obj_player", 0)
			if p != null:
				G.lib.instance_create_depth(p.x + v, p.y, p.depth + 2, "obj_bau")
		"inimigo":
			var p = G.lib.instance_find("obj_player", 0)
			if p != null:
				_inim = G.lib.instance_create_depth(p.x + v * p.facing, p.y - 2, p.depth + 1, "obj_inimigo_01")
		"inimigo_tipo":
			# [objeto, distância à frente do herói]
			var p = G.lib.instance_find("obj_player", 0)
			if p != null:
				_inim = G.lib.instance_create_depth(p.x + v[1] * p.facing, p.y - 2, 100, v[0])
				if "surgir_fase" in _inim:
					_inim.surgir_fase = "ativo"
				_inim.ativo = true
				_inim.estado_ia = "parado" if v[0] == "obj_inimigo_02" else "perseguir"
				_inim.recarga = 0.0
		"inimigo_portal":
			# [objeto, distância à frente do herói]: surge pelo portal de verdade
			var p = G.lib.instance_find("obj_player", 0)
			if p != null:
				G.fala_batalha_room = ""
				_inim = G.lib.instance_create_depth(p.x + v[1] * p.facing, p.y - 2, 100, v[0])
		"ir_para":
			# leva o herói para v[1] px à esquerda do objeto v[0] (mini-boss / árvore)
			var o = G.lib.instance_find(v[0], 0)
			var p = G.lib.instance_find("obj_player", 0)
			if o != null and p != null:
				p.x = o.x - v[1]
				p.y = o.y - 4
				p.velv = 0.0
				G.cam_snap = true
		"mini_vencer":
			# simula a SEQUÊNCIA DE GOLPES completa com o finalizador acertando
			var m = G.lib.instance_find("obj_mini_boss", 0)
			if m != null:
				if not m.acordado:
					m.despertar()
				m.qte_vencido = true
				m.vida = 0.0
				m.reagir_dano(1, 1, 1)
		"mini_info":
			var m = G.lib.instance_find("obj_mini_boss", 0)
			if m == null:
				print("[teste] MINI %s nao existe" % v)
			else:
				print("[teste] MINI %s est=%s vida=%d/%d segunda=%s na_segunda=%s morrendo=%s inv=%.0f" % [v, m.estado_ia, m.vida, m.vida_max, m.segunda_vida, m.na_segunda_vida, m.morrendo, m.tempo_invencivel])
		"cura_qte":
			var p = G.lib.instance_find("obj_player", 0)
			if p != null:
				p.vida = round(p.vida_max * 0.3)
				var antes: float = p.vida
				V117.qte_curar(p)
				print("[teste] CURA_QTE %d -> %d (max %d)" % [antes, p.vida, p.vida_max])
		"bench":
			G.lib.instance_create_depth(0, 0, -12000, "obj_benchmark")
		"arvore_info":
			var b = G.lib.instance_find("obj_boss_01", 0)
			if b != null:
				var hp = G.lib.instance_find("obj_player", 0)
				print("[teste] ARVORE %s est=%s vida=%d/%d acampar=%d canto=%d recarga_inv=%d servos=%d chuva=%d marco=%d chuva_t=%d heroi=%.1f,%.1f hv=%.2f canto_xy=%.1f,%.1f" % [
					str(v), b.estado_ia, b.vida, b.vida_max, b.acampar_t, b.canto_t, b.invocar_recarga, b.servos_vivos(), b.chuva_fila.size(), b.chuva_marco_i, b.chuva_grande_t,
					hp.x if hp != null else 0.0, hp.y if hp != null else 0.0, hp.vida if hp != null else 0.0, b.canto_x, b.canto_y])
		"arvore_vida":
			var b = G.lib.instance_find("obj_boss_01", 0)
			if b != null:
				b.vida = b.vida_max * float(v)
				b.vida_atraso = b.vida
		"arvore_pronta":
			var b = G.lib.instance_find("obj_boss_01", 0)
			if b != null:
				b.invocar_recarga = 0.0
				b.acampar_t = 0.0
				b.canto_t = 0.0
		"arvore_chuva":
			var b = G.lib.instance_find("obj_boss_01", 0)
			if b != null:
				if not b.acordado:
					b.acordado = true
					b.estado_ia = "parado"
				b.fase = 3
				b.chuva_lancar(7)
				print("[teste] CHUVA fila=%d" % b.chuva_fila.size())
		"teia":
			# prende o herói na teia por v quadros (anda devagar: sprite de andar)
			var p = G.lib.instance_find("obj_player", 0)
			if p != null:
				p.enredado = v
				p.enredado_max = v
		"heroi_spr":
			var p = G.lib.instance_find("obj_player", 0)
			if p != null:
				print("[teste] HEROI %s spr=%s img=%.2f velh=%.2f" % [v, p.sprite_index.nome if p.sprite_index != null else "-", p.image_index, p.velh])
		"fx_resumo":
			# partículas vivas por tipo (nos lotes, conta pelos efeitos ainda vivos)
			var n_inst := 0
			var n_parts := 0
			var por := {}
			for fx in G.lib.todos("obj_fx"):
				n_inst += 1
				n_parts += fx.parts.size()
				var chave: String = ("lote@" + str(fx.depth)) if fx.lote else fx.tipo
				por[chave] = por.get(chave, 0) + fx.parts.size()
			print("[fx] ", v, ": inst=", n_inst, " parts=", n_parts, " ", por)
		"info_cam":
			print("[cam] ", v, ": combate=", snappedf(G.cam_combate, 0.01), " foco=", snappedf(G.cam_foco_x, 0.1), " soco=", snappedf(G.cam_soco, 0.001), " zoom=", snappedf(G.cam_zoom_atual, 0.001), " view_w=", roundi(G.view_w))
		"menu_estado":
			var mm = G.lib.instance_find("obj_menu", 0)
			if mm != null:
				mm.mudar_estado(v[0], v[1], false)
		"cfg":
			G.set(v[0], v[1])
		"arrasta_botao":
			for bb in G.toque.layout(true):
				if bb[0] == v[0]:
					var s2 := InputEventScreenTouch.new()
					s2.index = 1
					s2.position = _janela(bb[1])
					s2.pressed = true
					Input.parse_input_event(s2)
					arrasto = {"de": bb[1], "para": bb[1] + v[1], "t": 0.0, "dur": v[2]}
		"toque_hud_linha":
			var mh = G.lib.instance_find("obj_menu", 0)
			var rl: Rect2 = mh.hud_linha(v[0])
			_toque(0, rl.get_center() + Vector2(rl.size.x * 0.3 * v[1], 0))
		"hud_info":
			var pj = G.lib.instance_find("obj_player", 0)
			print("[hud] ", v, ": modo=", G.cfg_hud_modo, " tam=", G.cfg_hud_tam, " pos=", G.cfg_hud_pos, " desempenho=", G.cfg_desempenho, " cam=", G.cfg_camera_acao,
				" toque_modo=", G.toque.calcular_modo(), " defendendo=", (pj.defendendo if pj != null and "defendendo" in pj else "-"))
		"inim_fase":
			if _inim != null and G.existe(_inim):
				var falas := []
				for f in G.lib.todos("obj_fala"):
					falas.append(f.texto)
				var p = G.lib.instance_find("obj_player", 0)
				print("[teste] FASE %s t=%.1f ativo=%s dir=%s x=%d heroi_x=%d est=%s falas=%s" % [_inim.surgir_fase, _inim.surgir_t, _inim.ativo, _inim.dir, _inim.x, p.x if p != null else -1, _inim.estado_ia, falas])
		"caixas":
			G.debug_hitbox = v
		"limpar":
			# tira os inimigos da fase (o teste fica só com o que ele criar)
			for e in G.lib.todos("obj_inimigo_base"):
				if not e.eh_boss:
					G.lib.instance_destroy(e)
		"inim_info":
			if _inim != null and G.existe(_inim):
				var p = G.lib.instance_find("obj_player", 0)
				print("[teste] INIM ", _inim.obj, " x=", roundi(_inim.x), " y=", roundi(_inim.y), " alfa=", _inim.image_alpha, " vis=", _inim.visible,
					" spr=", _inim.sprite_index.nome if _inim.sprite_index != null else "-", " img=", snappedf(_inim.image_index, 0.1), " prof=", _inim.depth,
					" heroi_prof=", p.depth if p != null else 0, " ativo=", _inim.ativo, " est=", _inim.estado_ia, " k=", _inim.sprite_index.k if _inim.sprite_index != null else 0.0, " ev=", _inim._ev, " alvo=", _inim._alvo_mundo != null, " bbox=", roundi(_inim.bbox_left), "..", roundi(_inim.bbox_right), " heroi_x=", roundi(p.x), " view_x=", roundi(G.view_x))
			else:
				print("[teste] INIM nao existe")
		"matar_guardioes":
			for e in G.lib.todos("obj_inimigo_base"):
				if e.limite_x2 > 0 and e.ativo and not e.morrendo:
					e.vida = 0.0
					e.inimigo_morrer(1.0)
		"estado_chave":
			var pt = G.lib.instance_find("obj_portao_trancado", 0)
			var pl = G.lib.instance_find("obj_player", 0)
			print("[teste] CHAVE=", G.chave_portao, " arena=", G.arena_chave, " visto=", G.portao_visto, " portao=", pt.estado if pt != null else "-",
				" heroi=", roundi(pl.x) if pl != null else 0, ",", roundi(pl.y) if pl != null else 0, " escalando=", pl.escalando if pl != null else false, "  ", v)
		"inimigo_fraco":
			if _inim != null and G.existe(_inim):
				_inim.vida = 1.0
		"inimigo_matar":
			if _inim != null and G.existe(_inim) and not _inim.morrendo:
				print("[teste] inimigo ainda vivo: matando")
				_inim.vida = 0.0
				_inim.inimigo_morrer(1.0)
		"matar":
			var p = G.lib.instance_find("obj_player", 0)
			if p != null:
				p.vida = 1.0
				p.levar_dano(999.0, p.x - 10, false)
		"toque_c":
			_toque(0, Vector2(G.gui_w / 2 + v[0], v[1]))
		"toque_frac":
			_toque(0, Vector2(G.gui_w * v[0], v[1]))
		"registrar":
			_registrar = v
		"fps_on":
			_perf_frames = Engine.get_process_frames()
			_perf_t0 = Time.get_ticks_msec()
		"fps":
			var fq := Engine.get_process_frames() - _perf_frames
			var fms := Time.get_ticks_msec() - _perf_t0
			print("[fps] ", v, ": ", snappedf(fq * 1000.0 / maxf(1, fms), 0.1), " fps  instancias=", G.instancias.size(), " drawcalls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
			_perf_frames = Engine.get_process_frames()
			_perf_t0 = Time.get_ticks_msec()
		"picos_on":
			G.perf_ligado = true
			G.perf_picos = v
		"perf_on":
			G.perf_ligado = true
			G.perf_relatorio()
			_perf_frames = Engine.get_process_frames()
			_perf_t0 = Time.get_ticks_msec()
		"perf":
			var f := Engine.get_process_frames() - _perf_frames
			var ms := Time.get_ticks_msec() - _perf_t0
			print("[perf] ", v, ": ", f, " quadros em ", ms, " ms (", snappedf(f * 1000.0 / maxf(1, ms), 0.1), " fps) instancias=", G.instancias.size())
			print("[perf] ", G.perf_relatorio())
			var cont := {}
			var segs := 0
			for inst in G.instancias:
				cont[inst.obj] = cont.get(inst.obj, 0) + 1
				for alv in [inst._alvo_mundo, inst._alvo_fim, inst._alvo_gui]:
					if alv != null:
						segs += alv.usados
			var lst := []
			for k in cont:
				lst.append([k, cont[k]])
			lst.sort_custom(func(a, b): return a[1] > b[1])
			print("[perf] segmentos=", segs, " objetos=", lst.slice(0, 10))
			var tipos := {}
			for inst in G.lib.todos("obj_fx"):
				var chave: String = inst.tipo + "@" + str(int(inst.x / 100) * 100)
				tipos[chave] = tipos.get(chave, 0) + 1
			print("[perf] fx=", tipos)
			print("[perf] process=", snappedf(Performance.get_monitor(Performance.TIME_PROCESS) * 1000, 0.1), "ms drawcalls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
				" objetos_render=", Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME), " primitivas=", Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
				" vram_tex=", snappedf(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0, 0.1), "MB")
			_perf_frames = Engine.get_process_frames()
			_perf_t0 = Time.get_ticks_msec()
		"info":
			var tocando := []
			for pl in G._players:
				if pl.playing and pl.stream != null:
					tocando.append(pl.stream.resource_path.get_file())
			print("[teste] fps=", Engine.get_frames_per_second(), " instancias=", G.instancias.size(), " sala=", G.room, " sons=", tocando)
		"pular_dialogo":
			var d = G.lib.instance_find("obj_dialogo", 0)
			if d != null and not d.pendente:
				d.fechando = true
		"dano_boss":
			var b = G.lib.instance_find("obj_boss_01", 0)
			var p = G.lib.instance_find("obj_player", 0)
			if b != null and p != null:
				b.levar_dano(300.0, b.x - 40, true, 4.0, p)
		"jogo_direto":
			# v1.17: começa a partida no slot 3 (o de teste) sem passar pelo menu e pelo mapa
			G.lib.partida_resetar()
			G.save_slot_atual = 3
			G.dificuldade = 1
			var lj = G.lib.instance_create_depth(0, 0, -11000, "obj_loading")
			lj.modo = "novo_jogo"
			lj.destino = "Room1"
		"acelerar_carregamento":
			var la = G.lib.instance_find("obj_loading", 0)
			if la != null:
				la.duracao_capitulo = minf(la.duracao_capitulo, 30.0)
				la.duracao_carregamento = 40.0
		"info_golpe":
			var pg = G.lib.instance_find("obj_player", 0)
			if pg != null:
				print("[teste] GOLPE=", pg.golpe.chave if pg.golpe != null else "-", " cadeia=", pg.cadeia, " spr=", pg.sprite_index.nome if pg.sprite_index != null else "-",
					" fogo=", pg.fogo_rastro.size(), " chamas=", pg.fogo_chamas.size())
		"sala":
			var l = G.lib.instance_create_depth(0, 0, -11000, "obj_loading")
			l.modo = "transicao"
			l.destino = v
		"sair":
			get_tree().quit()


func _tecla(k: int, apertada: bool) -> void:
	var e := InputEventKey.new()
	e.keycode = k
	e.physical_keycode = k
	e.pressed = apertada
	Input.parse_input_event(e)


# coordenadas da GUI -> coordenadas da janela (eventos de entrada chegam na escala da janela)
func _janela(p: Vector2) -> Vector2:
	return get_viewport().get_final_transform() * p


func _toque(i: int, p: Vector2) -> void:
	p = _janela(p)
	var e := InputEventScreenTouch.new()
	e.index = i
	e.position = p
	e.pressed = true
	Input.parse_input_event(e)
	await get_tree().create_timer(0.08).timeout
	var s := InputEventScreenTouch.new()
	s.index = i
	s.position = p
	s.pressed = false
	Input.parse_input_event(s)

