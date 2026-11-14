extends Lib
# =====================================================================
#  obj_save_menu — escolher um dos 3 slots para salvar
#  (aberto pelo cristal dourado)
# =====================================================================

var selecionado := 0
var tempo := 0.0
var confirmado := false
var modo := "salvar"
var mouse_antes := Vector2(-1, -1)
var slots: Array = []
var vindo_da_pausa := false


func ev_create() -> void:
	globais_iniciar()
	selecionado = clampi(G.save_slot_atual - 1, 0, 2)
	slots = [slot_info(1), slot_info(2), slot_info(3)]
	vindo_da_pausa = instance_exists("obj_pausa")
	mundo_pausar()


func fechar() -> void:
	if vindo_da_pausa:
		G.ativar_obj("obj_pausa")
		for p in todos("obj_pausa"):
			p.tempo = 0
	else:
		mundo_retomar()
	G.io_clear()
	G.nav_ok = false
	G.nav_voltar = false
	G.bloqueio_input = 10
	instance_destroy()


func ev_step() -> void:
	var dt := G.dt_real
	tempo += dt
	var gw := G.gui_w
	var cartao := minf(300, gw * 0.23)
	var m := G.mouse_gui()
	var click := G.mouse_apertado
	var mexeu := mouse_antes.x != -1 and m != mouse_antes
	mouse_antes = m
	if confirmado:
		if tempo > 55:
			fechar()
		return
	if G.nav_voltar and tempo > 8:
		som("sfx_menu_fechar", 0.7, 0)
		fechar()
		return
	var sel_antes := selecionado
	if G.nav_esq or G.nav_cima:
		selecionado = (selecionado + 2) % 3
	if G.nav_dir or G.nav_baixo:
		selecionado = (selecionado + 1) % 3
	var confirm := G.nav_ok
	for i in 3:
		var cx := gw * (i + 1) / 4.0
		if point_in_rectangle(m.x, m.y, cx - cartao / 2, 300, cx + cartao / 2, 500):
			if mexeu:
				selecionado = i
			if click:
				selecionado = i
				confirm = true
	if selecionado != sel_antes:
		som("sfx_menu_mover", 0.5, 0)
	if confirm and tempo > 8:
		if modo == "salvar":
			if salvar_slot(selecionado + 1, true):
				som("sfx_salvar", 0.9, 0)
				slots[selecionado] = slot_info(selecionado + 1)
				confirmado = true
				tempo = 0
		elif carregar_slot(selecionado + 1):
			som("sfx_menu_ok", 0.8, 0)
			var l = instance_create_depth(0, 0, -11000, "obj_loading")
			l.modo = "carregar"
			l.destino = G.checkpoint_room
			instance_destroy()


func ev_draw_gui() -> void:
	var gw := G.gui_w
	var gh := G.gui_h
	var ouro := Color8(255, 210, 90)
	var a := minf(1, tempo / 12.0)
	if confirmado:
		a = 1
	draw_set_alpha(0.93 * a)
	draw_set_color(c_black)
	draw_rectangle(0, 0, gw, gh, false)
	desenhar_vinheta(gw, gh, 0.5 * a, Color8(50, 0, 6))
	txt_sombra(gw / 2, 150, "SALVAR JOGO" if modo == "salvar" else "CARREGAR JOGO", FONTE.GRANDE, ouro, a, fa_center, fa_middle)
	desenhar_divisor(gw / 2, 192, 220, a)
	txt(gw / 2, 240, "Escolha um dos três slots", FONTE.PEQUENA, c_white, a, fa_center, fa_middle)
	var cartao := minf(300, gw * 0.23)
	for i in 3:
		var px := gw * (i + 1) / 4.0
		var sel := 1.0 if selecionado == i else 0.0
		var info: Dictionary = slots[i]
		desenhar_painel(px - cartao / 2, 300, px + cartao / 2, 500, sel, a)
		txt(px, 334, "SLOT " + str(i + 1), FONTE.MEDIA, ouro, a, fa_center, fa_middle)
		if info.existe:
			txt(px, 372, str(info.nome).to_upper(), FONTE.PEQUENA, c_white, a, fa_center, fa_middle, minf(1, (cartao - 24) / maxf(1, txt_largura(str(info.nome).to_upper(), FONTE.PEQUENA))))
			txt(px, 396, dificuldade_nome(info.dificuldade), FONTE.MINI, dificuldade_cor(info.dificuldade), a, fa_center, fa_middle)
			txt(px, 422, "CAPÍTULO " + str(info.fase), FONTE.MINI, Color8(176, 141, 70), a, fa_center, fa_middle)
			txt_bloco(px, 436, fase_nome(info.fase), FONTE.MINI, Color8(215, 210, 205), a, cartao - 24)
			if info.data != "":
				txt(px, 484, info.data, FONTE.MINI, Color8(140, 140, 145), a, fa_center, fa_middle, 0.85)
		else:
			txt(px, 410, "VAZIO", FONTE.PEQUENA, Color8(140, 140, 145), a, fa_center, fa_middle)
	if confirmado:
		txt_sombra(gw / 2, 552, "JOGO SALVO NO SLOT " + str(selecionado + 1), FONTE.MEDIA, Color8(140, 255, 150), 1, fa_center, fa_middle)
	var rod := "Toque num slot para salvar   ·   VOLTAR cancela" if (G.usando_toque and not usando_controle()) \
		else ("« » escolhe   ·   " + nome_confirmar() + " confirma   ·   " + nome_voltar() + " cancela")
	txt(gw / 2, gh - 40, rod, FONTE.MINI, Color8(190, 190, 190), a, fa_center, fa_middle)
	desenho_resetar()
