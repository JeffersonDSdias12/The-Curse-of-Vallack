extends Lib
# =====================================================================
#  obj_resultado — FIM DA DEMO (depois de vencer o boss e seguir em frente)
#  escurecer -> RESULTADO (tempo, inimigos, orbs...) -> "Obrigado por
#  jogar nossa Demo." -> carregamento -> menu inicial
# =====================================================================

var fase := "escurecer"
var tempo := 0.0
var brasas: Array = []
var linhas: Array = []
var mostrar_t := 0.0
var pode_continuar := false


func ev_create() -> void:
	globais_iniciar()
	G.jogo_finalizado = true
	var taxa := minf(100, float(G.hits_total) / G.attacks_total * 100) if G.attacks_total > 0 else 0.0
	linhas = [
		{"nome": "TEMPO DE JOGO", "valor": G.tempo_jogo, "tipo": "tempo"},
		{"nome": "INIMIGOS DERROTADOS", "valor": float(G.inimigos_derrotados), "tipo": "num"},
		{"nome": "ORBS COLETADAS", "valor": float(G.orbs_coletados), "tipo": "num"},
		{"nome": "NÍVEL DA ESPADA", "valor": float(G.espada_nivel), "tipo": "nivel"},
		{"nome": "TAXA DE ACERTO", "valor": taxa, "tipo": "pct"},
		{"nome": "DIFICULDADE", "valor": 0.0, "tipo": "dif"},
	]
	som("fase_concluida", 1, 0)
	musica("bgm_main_menu", 3000)     # v1.16: o tema principal fecha a demo (resultado e créditos)
	# v1.17: CONQUISTAS do fim da fase 1
	V117.perfil_somar("fases")
	V117.conquista("fase1")
	if G.dificuldade >= DIF.DIFICIL:
		V117.conquista("dificil")
	if G.dificuldade >= DIF.EXTREMO:
		V117.conquista("extremo")
	if G.tempo_jogo < 15 * 60:
		V117.conquista("veloz")
	V117.perfil_salvar()


func ev_step() -> void:
	var dt := G.dt_real
	tempo += dt
	var ok := input_confirmar_pergaminho() or G.mouse_apertado or G.keyboard_check_pressed(KEY_SPACE)
	match fase:
		"escurecer":
			if tempo >= 110:
				mundo_pausar()
				fase = "resultado"
				tempo = 0
		"resultado":
			mostrar_t += dt
			pode_continuar = mostrar_t > 40 + linhas.size() * 26
			if (ok and pode_continuar) or mostrar_t > 900:
				som("sfx_menu_ok", 0.8, 0)
				fase = "obrigado"
				tempo = 0
		"obrigado":
			if tempo >= 360 or (ok and tempo > 90):
				fase = "obrigado_sai"
				tempo = 0
		"obrigado_sai":
			if tempo >= 45:
				fase = "creditos"
				tempo = 0
		"creditos":
			# os nomes da equipe sobem pela tela; tocar / ENTER acelera
			if ok and tempo > 60:
				tempo += 120
			if tempo >= creditos_duracao() + 240:
				fase = "sair"
				tempo = 0
		"sair":
			if tempo >= 50:
				var l = instance_create_depth(0, 0, -11000, "obj_loading")
				l.modo = "menu"
				l.destino = "rm_menu"
				l.fundo_preto = true
				instance_destroy()
	# brasas subindo
	if fase != "escurecer" and G.cfg_qualidade > 0 and brasas.size() < 60 and randf() < 0.6 * dt:
		brasas.append({"x": randf() * G.gui_w, "y": GUI_ALTURA + 6.0, "vy": randf_range(-1.6, -0.5), "vida": float(randi_range(80, 220)), "vmax": 220.0})
	for i in range(brasas.size() - 1, -1, -1):
		var b: Dictionary = brasas[i]
		b.y += b.vy * dt
		b.vida -= dt
		if b.vida <= 0:
			brasas.remove_at(i)


func ev_draw_gui() -> void:
	var gw := G.gui_w
	var gh := G.gui_h
	var cx := gw / 2.0
	var ouro := Color8(255, 210, 90)
	var ouro2 := Color8(176, 141, 70)
	# escurecendo sobre o jogo
	var esc := clampf(tempo / 110.0, 0, 1) if fase == "escurecer" else 1.0
	draw_set_alpha(esc * (0.88 if fase == "resultado" else 1.0))
	draw_set_color(c_black)
	draw_rectangle(0, 0, gw, gh, false)
	draw_set_alpha(1)
	if fase == "resultado":
		desenhar_vinheta(gw, gh, 0.7, Color8(50, 0, 0))
		var a0 := clampf(mostrar_t / 30.0, 0, 1)
		txt_amaldicoado(cx, 92, "CAPÍTULO I CONCLUÍDO", FONTE.GRANDE, Color8(235, 45, 35), mostrar_t, 3, minf(1, (gw * 0.85) / maxf(1, txt_largura("CAPÍTULO I CONCLUÍDO", FONTE.GRANDE))), a0)
		txt(cx, 146, "A CAMINHO DO CASTELO  ·  RESULTADO", FONTE.PEQUENA, ouro, a0, fa_center, fa_middle)
		desenhar_divisor(cx, 172, 240, a0)
		var pw := minf(gw - 120, 640)
		for i in linhas.size():
			var ln: Dictionary = linhas[i]
			var k := clampf((mostrar_t - 40 - i * 26) / 22.0, 0, 1)
			if k <= 0:
				continue
			var y := 216.0 + i * 62
			desenhar_painel(cx - pw / 2 + (1 - k) * 60, y - 24, cx + pw / 2 + (1 - k) * 60, y + 24, 0, k)
			txt(cx - pw / 2 + 24 + (1 - k) * 60, y, ln.nome, FONTE.PEQUENA, c_white, k, fa_left, fa_middle)
			var v: float = ln.valor * clampf((mostrar_t - 40 - i * 26) / 40.0, 0, 1)
			var s := ""
			match ln.tipo:
				"tempo":
					s = tempo_texto(v)
				"num":
					s = str(int(round(v)))
				"nivel":
					s = str(int(round(v))) + " / " + str(ESPADA_NIVEL_MAX)
				"pct":
					s = str(int(round(v))) + "%"
				"dif":
					s = dificuldade_nome()
			txt(cx + pw / 2 - 24 + (1 - k) * 60, y, s, FONTE.MEDIA, dificuldade_cor() if ln.tipo == "dif" else ouro, k, fa_right, fa_middle)
		if pode_continuar:
			var ra := 0.7 + 0.3 * sin(current_time() / 160.0)
			var ry := gh - 46
			if G.usando_toque and not usando_controle():
				txt(cx, ry, "TOQUE PARA CONTINUAR", FONTE.PEQUENA, ouro, ra, fa_center, fa_middle)
			else:
				var w := 28 + 18 + desenhar_tecla_largura("ENTER", 28) + 12 + txt_largura("CONTINUAR", FONTE.PEQUENA)
				var rx := cx - w / 2
				rx += desenhar_icone_pad(rx, ry, gp_face1, 28, ra)
				txt(rx + 9, ry, "/", FONTE.PEQUENA, ouro2, ra, fa_center, fa_middle)
				rx += 18
				rx += desenhar_tecla(rx, ry, "ENTER", 28, ra)
				txt(rx + 12, ry, "CONTINUAR", FONTE.PEQUENA, ouro, ra, fa_left, fa_middle)
	if fase == "obrigado" or fase == "obrigado_sai":
		var a := clampf(tempo / 50.0, 0, 1) if fase == "obrigado" else maxf(0, 1 - tempo / 45.0)
		var tt := tempo if fase == "obrigado" else 999.0
		desenhar_vinheta(gw, gh, 0.8, Color8(40, 0, 0))
		var t := "Obrigado por jogar nossa Demo."
		txt_amaldicoado(cx, gh * 0.44, t, FONTE.GRANDE, Color8(240, 225, 200), tt, 2, minf(1, (gw * 0.88) / maxf(1, txt_largura(t, FONTE.GRANDE))), a)
		txt(cx, gh * 0.44 + 62, JOGO_TITULO + "  ·  " + JOGO_SUBTITULO, FONTE.PEQUENA, ouro, a * clampf((tt - 60) / 40.0, 0, 1), fa_center, fa_middle)
	# créditos com os nomes da equipe
	if fase == "creditos" or fase == "sair":
		desenhar_vinheta(gw, gh, 0.8, Color8(40, 0, 0))
		var ac := clampf(tempo / 40.0, 0, 1) if fase == "creditos" else maxf(0, 1 - tempo / 50.0)
		creditos_desenhar(tempo if fase == "creditos" else creditos_duracao() + 240, ac)
	# brasas
	gpu_set_blendmode(bm_add)
	for bi in brasas.size():
		var br: Dictionary = brasas[bi]
		var p: float = br.vida / br.vmax
		draw_set_alpha(minf(1, p * 1.4) * 0.8)
		draw_set_color(Color8(255, int(90 + 110 * p), 40))
		draw_circle(br.x + sin((br.y + bi * 20) / 30.0) * 6, br.y, 2.2, false)
	gpu_set_blendmode(bm_normal)
	desenho_resetar()
