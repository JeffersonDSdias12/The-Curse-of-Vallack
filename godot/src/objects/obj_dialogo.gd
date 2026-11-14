extends Lib
# =====================================================================
#  obj_dialogo — caixa de diálogo
#  Pausa o mundo (como os pergaminhos), mostra o retrato e o nome de quem
#  fala e escreve o texto letra por letra. ENTER / X / toque (ou ataque)
#  completa o texto e passa para a próxima fala; ESC / BOLA / VOLTAR pula.
#  As falas ficam em dialogo_falas(). Abrir com dialogo_iniciar().
# =====================================================================

var falas: Array = []
var i := 0
var letras := 0.0
var tempo := 0.0
var abre := 0.0
var fechando := false
var ao_fim = null
var blip := 0
var pendente := true        # o diálogo começa no Step dele (nunca no meio do código de outro objeto)


func ev_create() -> void:
	globais_iniciar()


func dialogo_comecar() -> void:
	mundo_pausar()
	G.io_clear()
	som("dialogo_abrir", 0.7, 0)


func dialogo_fechar() -> void:
	mundo_retomar()
	G.io_clear()
	G.nav_ok = false
	G.nav_voltar = false
	G.bloqueio_input = 12          # o botão que fechou não vira golpe nem pulo
	var f = ao_fim
	ao_fim = null
	instance_destroy()
	if f is Callable and f.is_valid():
		f.call()


func ev_step() -> void:
	var dt := G.dt_real
	# começa no primeiro Step livre: espera um pergaminho, a pausa ou uma tela fechar
	if pendente:
		if instance_exists("obj_pausa") or instance_exists("obj_save_menu") or instance_exists("obj_menu_armas") \
				or instance_exists("obj_loading") or instance_exists("obj_game_over"):
			return
		pendente = false
		dialogo_comecar()
		return
	tempo += dt
	if fechando:
		abre = maxf(0, abre - 0.16 * dt)
		if abre <= 0:
			dialogo_fechar()
		return
	abre = minf(1, abre + 0.12 * dt)
	if falas.is_empty():
		fechando = true
		return
	var f: Dictionary = falas[i]
	var n: int = f.t.length()
	# o texto aparece letra por letra (com um "bip" grave a cada 3 letras)
	if abre >= 1 and letras < n:
		var antes := floorf(letras)
		letras = minf(n, letras + 1.1 * dt)
		if floorf(letras) != antes:
			blip += 1
			if blip % 3 == 0:
				som("dialogo_texto", 0.45, 0.06)
	var ok := G.nav_ok or input_apertado(ACAO.ATACAR) or input_apertado(ACAO.INTERAGIR) or G.mouse_apertado
	if tempo > 10 and ok:
		if letras < n:
			letras = n          # completa a fala
		else:
			i += 1
			letras = 0
			if i >= falas.size():
				i = falas.size() - 1
				letras = falas[i].t.length()
				fechando = true
			else:
				som("sfx_pagina", 0.35, 0.05)
	# ESC / BOLA / VOLTAR pula o diálogo inteiro
	if tempo > 10 and G.nav_voltar:
		fechando = true


func ev_draw_gui() -> void:
	if pendente:
		return
	var gw := G.gui_w
	var gh := G.gui_h
	var e := 1 - pow(1 - abre, 3)
	retangulo_gradiente(0, gh - 260, gw, gh, c_black, 0, c_black, 0.55 * e)
	if falas.is_empty():
		return
	var f: Dictionary = falas[i]
	var vermelho := Color8(128, 18, 16)
	var tinta := Color8(54, 32, 16)
	var tinta2 := Color8(110, 74, 40)
	# pergaminho entre dois rolos, centrado embaixo
	var bw := minf(gw - 160, 860)
	var bx1 := (gw - bw) / 2.0
	var bx2 := bx1 + bw
	var by2 := gh - 30 + (1 - e) * 40
	var by1 := by2 - 168
	pergaminho_dialogo(bx1, by1, bx2, by2, e)
	# retrato de quem fala, à direita, numa moldura
	var rw := 120.0
	var rx2 := bx2 - 34
	var rx1 := rx2 - rw
	var ry1 := by1 + 22
	var ry2 := ry1 + rw
	draw_set_alpha(e)
	draw_set_color(Color8(70, 44, 20))
	draw_rectangle(rx1 - 5, ry1 - 5, rx2 + 5, ry2 + 5, false)
	draw_set_color(Color8(24, 16, 14))
	draw_rectangle(rx1, ry1, rx2, ry2, false)
	var r := dialogo_retrato(f.q)
	if r[0] != null:
		var spr: GMSprite = r[0]
		var k := hd_escala(spr)
		var hw := spr.h / k
		var ww := spr.w / k
		var s := minf((ry2 - ry1 - 12) / hw, (rw - 12) / ww)
		var ox := spr.xo / k
		var oy := spr.yo / k
		var px := (rx1 + rx2) / 2 - (ww / 2 - ox) * s
		var py := ry2 - 6 - (hw - oy) * s
		draw_sprite_hd(spr, r[1], px, py, s, s, 0, r[2], e)
	draw_set_alpha(e)
	draw_set_color(Color8(196, 150, 74))
	draw_rectangle(rx1 - 2, ry1 - 2, rx2 + 2, ry2 + 2, true)
	draw_set_color(Color8(70, 44, 20))
	draw_rectangle(rx1 - 5, ry1 - 5, rx2 + 5, ry2 + 5, true)
	# nome e fala em tinta escura
	var tx := bx1 + 34
	var tw := rx1 - 22 - tx
	txt(tx, by1 + 18, dialogo_nome(f.q) + ":", FONTE.PEQUENA, vermelho, e, fa_left, fa_top)
	txt_bloco(tx, by1 + 52, f.t.substr(0, int(floor(letras))), FONTE.PEQUENA, tinta, e, tw, fa_left, fa_top)
	var toque := G.usando_toque and not usando_controle()
	if letras >= f.t.length():
		var pa := 0.55 + 0.45 * sin(current_time() / 180.0)
		var cont := "CONTINUAR  »" if toque else nome_confirmar() + ":  CONTINUAR  »"
		txt(rx1 - 22, by2 - 16, cont, FONTE.MINI, vermelho, e * pa, fa_right, fa_bottom)
	# no toque, o botão do canto já se chama PULAR
	txt(tx, by2 - 16, "PULAR: BOTÃO NO ALTO" if toque else nome_voltar() + ": PULAR", FONTE.MINI, tinta2, e * 0.85, fa_left, fa_bottom)
	desenho_resetar()