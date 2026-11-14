extends Lib
# =====================================================================
#  obj_loading — transições e telas de carregamento
#  modo:
#   "novo_jogo" / "carregar" / "transicao":
#       escurece -> troca de sala (congelada) -> título do capítulo ->
#       carregamento com o tutorial COMO JOGAR -> clareia e libera o jogo
#   "menu": carregamento -> volta ao menu inicial
#  O COMO JOGAR é o único tutorial do jogo. Ele aparece só aqui,
#  no carregamento das fases, e espera o jogador apertar para começar.
#  Quem cria define "modo" e "destino" logo após instance_create.
# =====================================================================

var modo := "transicao"
var destino := "Room1"
var fase := "inicio"          # inicio, escurecer, capitulo, carregando, clarear
var tempo := 0.0
var progresso := 0.0
var congelou := false
var fundo_preto := false      # true = a tela já está preta (ex.: vindo do final)
var rapido := false           # v1.19: teste de desempenho (carrega em ~1 s)
var tutorial := false         # decidido no primeiro Step (o "modo" chega depois do Create)
var tutorial_abre := 0.0
var pronto_t := 0.0
var duracao_carregamento := 240.0
var duracao_capitulo := 220.0
# v1.17: CARREGAMENTO DAS FASES EM 30 s (título do capítulo + barra), com DICAS de
# combos e ataques passando embaixo e a foto do cenário da fase ao fundo
var dicas: Array = []
var dica_i := 0
var dica_t := 0.0
const DICA_TEMPO := 300.0


func ev_create() -> void:
	persistent = true
	globais_iniciar()
	dicas = V117.dicas_carregamento()
	dica_i = randi() % dicas.size()
	if G.img_mapa == null:
		G.img_mapa = imagem_carregar("mapa_fases.jpg")
	audio_cena_definir("carregamento")
	musica("bgm_loading_screen", 1500)     # v1.16: a trilha do menu/fase sai (fade) e entra a do carregamento


# a sala de destino acabou de ser criada: o Step congela a fase nova no próximo quadro
func ev_room_start() -> void:
	if fase == "capitulo" or fase == "carregando":
		if modo != "menu":
			congelou = false


func ev_step() -> void:
	var dt := G.dt_real
	tempo += dt
	match fase:
		"inicio":
			G.transicao_fase = true
			tempo = 0
			# v1.17: sem o pergaminho do COMO JOGAR: as fases carregam em 30 s (título do
			# capítulo + barra) com dicas de combos passando embaixo; o menu, rápido
			tutorial = false
			duracao_carregamento = (1800.0 - duracao_capitulo) if modo != "menu" else 150.0
			if rapido:
				# v1.19: TESTE DE DESEMPENHO: sem os 30 s de dicas (o mundo fica congelado
				# no carregamento, e quem pediu não consegue encurtar de fora)
				duracao_capitulo = 30.0
				duracao_carregamento = 40.0
			if modo == "menu":
				fase = "carregando" if fundo_preto else "escurecer"
			else:
				fase = "escurecer"
		"escurecer":
			if tempo >= 45:
				tempo = 0
				if modo == "menu":
					fase = "carregando"
					progresso = 0
				else:
					# congela a sala atual e troca para a fase de destino
					mundo_pausar()
					fase = "capitulo"
					congelou = false
					G.room_goto(destino)
		"capitulo":
			if not congelou:
				mundo_pausar()
				congelou = true
			if tempo >= duracao_capitulo:
				tempo = 0
				progresso = 0
				fase = "carregando"
		"carregando":
			if modo != "menu" and not congelou:
				mundo_pausar()
				congelou = true
			progresso = minf(100, progresso + (100 / duracao_carregamento) * dt)
			dica_t += dt
			if dica_t >= DICA_TEMPO and dicas.size() > 0:
				dica_t = 0
				dica_i = (dica_i + 1) % dicas.size()
			if tutorial:
				if tutorial_abre <= 0:
					som_mensagem()     # v1.16: o pergaminho do COMO JOGAR se abre
				tutorial_abre = minf(1, tutorial_abre + dt / 26.0)
			var liberar := progresso >= 100 and tempo >= duracao_carregamento + 25
			if tutorial and liberar:
				# espera o jogador ler: [X] / [ENTER] (ou toque) começa a fase
				pronto_t += dt
				liberar = pronto_t > 12 and (input_confirmar_pergaminho() or G.mouse_apertado)
				if liberar:
					som("sfx_pagina", 0.7, 0)
					G.io_clear()
					G.bloqueio_input = 12
			if liberar:
				tempo = 0
				fase = "clarear"
				if modo == "menu":
					partida_resetar()
					G.room_goto("rm_menu")
				else:
					mundo_retomar()
					G.cam_snap = true
					audio_cena_definir("fase")
					musica(musica_fase(), 1500)     # fase 1: bgm_battle_phase1
					# ao chegar na fase, o progresso é salvo no slot da partida
					if modo == "transicao" or modo == "novo_jogo":
						salvar_slot(G.save_slot_atual, false)
		"clarear":
			if tempo >= 40:
				G.transicao_fase = false
				persistent = false
				instance_destroy()


func ev_draw_gui() -> void:
	var gw := G.gui_w
	var gh := G.gui_h
	var cx := gw / 2.0
	var ouro := Color8(255, 210, 90)
	var ouro2 := Color8(176, 141, 70)
	var num := maxi(1, fase_numero(destino))
	# ----- escurecer / clarear -----
	# v1.19: a cortina em brasa entra pela esquerda e, depois do carregamento, sai pela direita
	if fase == "inicio" or fase == "escurecer":
		var ke := clampf(tempo / 45.0, 0, 1)
		V117.transicao_cortina_desenhar(0.0 if fase == "inicio" else ke * ke * (3 - 2 * ke))
		return
	if fase == "clarear":
		var kc := clampf(tempo / 40.0, 0, 1)
		V117.transicao_cortina_desenhar(1 - kc * kc * (3 - 2 * kc), true)
		return
	# ----- fundo preto com brilho vermelho amaldiçoado -----
	draw_set_color(c_black)
	draw_rectangle(0, 0, gw, gh, false)
	var pulso := 0.10 + 0.06 * sin(current_time() / 400.0)
	retangulo_gradiente(0, gh * 0.45, gw, gh, Color8(90, 0, 10), 0, Color8(90, 0, 10), pulso + 0.15)
	# ----- TÍTULO DO CAPÍTULO (letra por letra, efeito amaldiçoado) -----
	if fase == "capitulo":
		var sai := clampf((duracao_capitulo - tempo) / 30.0, 0, 1)
		var a := minf(clampf(tempo / 25.0, 0, 1), sai)
		txt(cx, gh / 2 - 92, "CAPÍTULO " + str(num), FONTE.MEDIA, ouro, a, fa_center, fa_middle)
		txt_amaldicoado(cx, gh / 2 - 30, fase_nome(num), FONTE.GRANDE, c_white, tempo - 15, 3, minf(1, (gw * 0.9) / maxf(1, txt_largura(fase_nome(num), FONTE.GRANDE))), sai)
		desenhar_divisor(cx, gh / 2 + 22, 240, a * clampf((tempo - 60) / 30.0, 0, 1))
		txt_bloco(cx, gh / 2 + 44, fase_sub(num), FONTE.PEQUENA, Color8(210, 205, 205), a * clampf((tempo - 70) / 30.0, 0, 1), minf(gw - 120, 820))
		desenho_resetar()
		return
	# ----- CARREGANDO -----
	# nas fases, o único tutorial do jogo (COMO JOGAR) num pergaminho
	if tutorial:
		var tam_w := minf(gw - 60, 880)
		var tam_h := 650.0
		var tcy := gh / 2 - 8
		var pag := tutorial_carregamento()
		var ta := clampf(tempo / 12.0, 0, 1)
		var pronto := progresso >= 100 and tempo >= duracao_carregamento + 25
		var rodape := "COMEÇAR" if pronto else ""
		pergaminho_desenhar(cx, tcy, tam_w, tam_h, tutorial_abre, pag, ta, rodape, "", 0.75 + 0.25 * sin(current_time() / 160.0))
		# capítulo e progresso no pé do pergaminho (enquanto carrega)
		if tutorial_abre >= 1 and not pronto:
			var y2 := tcy + tam_h / 2
			var bw2 := 300.0
			var tinta2 := Color8(96, 64, 34)
			var base := "CAPÍTULO " + str(num) + "  ·  " + fase_nome(num) + "  ·  carregando "
			txt(cx, y2 - 48, base + str(int(floor(progresso))) + "%", FONTE.MINI, tinta2, ta, fa_center, fa_middle, minf(1, (tam_w - 200) / maxf(1, txt_largura(base + "100%", FONTE.MINI))))
			draw_set_alpha(ta)
			draw_set_color(Color8(150, 120, 80))
			draw_rectangle(cx - bw2 / 2, y2 - 30, cx + bw2 / 2, y2 - 26, false)
			draw_set_color(Color8(128, 18, 16))
			draw_rectangle(cx - bw2 / 2, y2 - 30, cx - bw2 / 2 + bw2 * progresso / 100, y2 - 26, false)
			draw_set_alpha(1)
		desenho_resetar()
		return
	# v1.17: CARREGAMENTO DA FASE (30 s): a foto do cenário ao fundo (aproximando
	# devagar), o capítulo, a barra e as DICAS de combos passando embaixo
	if modo != "menu":
		var pen: Pen = G.pen
		var ent2 := clampf(tempo / 20.0, 0, 1)
		var k := clampf(progresso / 100.0, 0, 1)
		var fi := clampi(num - 1, 0, V117.MAPA_FASES - 1)
		if G.img_mapa != null:
			var ez := maxf(gw / 320.0, gh / 180.0) * (1.06 + 0.1 * k)
			pen.filtro = true
			pen.textura_parte(G.img_mapa, (fi % 6) * 320, (fi / 6) * 180, 320, 180, cx - 160 * ez - 30 * k, gh / 2.0 - 90 * ez, ez, ez, Color8(150, 130, 140), 0.7 * ent2)
			pen.filtro = false
		retangulo_gradiente(0, 0, gw, gh * 0.5, c_black, 0.8, c_black, 0.25)
		retangulo_gradiente(0, gh * 0.5, gw, gh, c_black, 0.25, c_black, 0.92)
		txt(cx, 96, "CAPÍTULO " + str(num), FONTE.MEDIA, ouro, ent2, fa_center, fa_middle)
		var nf: String = V117.fases_mapa()[fi].nome
		txt_sombra(cx, 150, nf, FONTE.GRANDE, c_white, ent2, fa_center, fa_middle, minf(1, (gw * 0.9) / maxf(1, txt_largura(nf, FONTE.GRANDE))))
		desenhar_divisor(cx, 196, 240, ent2)
		# barra
		var bw3 := minf(gw - 160, 640)
		var by3 := gh * 0.6
		draw_set_alpha(ent2)
		draw_set_color(Color8(30, 26, 26))
		draw_rectangle(cx - bw3 / 2, by3, cx + bw3 / 2, by3 + 12, false)
		var fim3 := cx - bw3 / 2 + bw3 * k
		draw_rectangle_color(cx - bw3 / 2, by3, fim3, by3 + 12, Color8(150, 20, 25), Color8(255, 200, 80), Color8(255, 200, 80), Color8(150, 20, 25), false)
		gpu_set_blendmode(bm_add)
		draw_set_alpha((0.5 + 0.3 * sin(current_time() / 90.0)) * ent2)
		draw_set_color(Color8(255, 140, 60))
		draw_circle(fim3, by3 + 6, 9, false)
		gpu_set_blendmode(bm_normal)
		draw_set_alpha(ent2)
		draw_set_color(ouro2)
		draw_rectangle(cx - bw3 / 2 - 3, by3 - 3, cx + bw3 / 2 + 3, by3 + 15, true)
		draw_set_alpha(1)
		txt(cx, by3 + 36, "PRONTO" if k >= 1 else "Carregando...  " + str(int(floor(progresso))) + "%", FONTE.PEQUENA, Color8(190, 186, 190), ent2, fa_center, fa_middle)
		# a dica da vez: entra deslizando da direita e sai pela esquerda
		if dicas.size() > 0 and G.cfg_tutorial != 0:
			var d: Dictionary = dicas[dica_i]
			var kin := clampf(dica_t / 24.0, 0, 1)
			var kout := clampf((DICA_TEMPO - dica_t) / 24.0, 0, 1)
			var da := minf(kin, kout) * ent2
			var desl := (1 - kin) * 140 - (1 - kout) * 140
			var y1 := gh - 150.0
			hud_faixa(60, y1, gw - 60, gh - 34, 0.92 * ent2)
			txt(96, y1 + 22, "DICA  ·  COMBOS E ATAQUES", FONTE.MINI, ouro, ent2, fa_left, fa_middle)
			var ix := 96 + desl
			for ic in d.ic:
				var iw := icone_acao_largura(ic, 34)
				desenhar_icone_acao(ix, y1 + 70, ic, 34, da)
				ix += iw + 8
			var tx := maxf(ix + 18, 96 + desl + 180)
			txt_sombra(tx, y1 + 54, d.n, FONTE.PEQUENA, c_white, da, fa_left, fa_middle, minf(1, (gw - 100 - tx) / maxf(1, txt_largura(d.n, FONTE.PEQUENA))))
			txt(tx, y1 + 86, d.t, FONTE.MINI, Color8(215, 205, 200), da, fa_left, fa_middle, minf(1, (gw - 100 - tx) / maxf(1, txt_largura(d.t, FONTE.MINI))))
		desenho_resetar()
		return
	# sem o tutorial (volta ao menu, ou tutorial desligado): título e barra
	var titulo := "VOLTANDO AO MENU INICIAL" if modo == "menu" else "CARREGANDO  ·  CAPÍTULO " + str(num)
	var sub := JOGO_TITULO + "  ·  " + JOGO_SUBTITULO if modo == "menu" else fase_nome(num)
	var ent := clampf(tempo / 20.0, 0, 1)
	txt_sombra(cx, gh * 0.36, titulo, FONTE.MEDIA, ouro, ent, fa_center, fa_middle)
	txt(cx, gh * 0.36 + 36, sub, FONTE.PEQUENA, Color8(200, 200, 205), ent, fa_center, fa_middle)
	# barra de progresso
	var bw := minf(gw - 160, 640)
	var by := gh * 0.56
	draw_set_color(Color8(30, 26, 26))
	draw_rectangle(cx - bw / 2, by, cx + bw / 2, by + 16, false)
	var fim := cx - bw / 2 + bw * progresso / 100
	draw_rectangle_color(cx - bw / 2, by, fim, by + 16, Color8(150, 20, 25), Color8(255, 200, 80), Color8(255, 200, 80), Color8(150, 20, 25), false)
	gpu_set_blendmode(bm_add)
	draw_set_alpha(0.5 + 0.3 * sin(current_time() / 90.0))
	draw_set_color(Color8(255, 140, 60))
	draw_circle(fim, by + 8, 10, false)
	gpu_set_blendmode(bm_normal)
	draw_set_alpha(1)
	draw_set_color(ouro2)
	draw_rectangle(cx - bw / 2 - 3, by - 3, cx + bw / 2 + 3, by + 19, true)
	var estado := "PRONTO" if progresso >= 100 else "Carregando...  " + str(int(floor(progresso))) + "%"
	txt(cx, by + 44, estado, FONTE.PEQUENA, c_white if progresso >= 100 else Color8(170, 170, 175), 1, fa_center, fa_middle)
	desenho_resetar()
