extends Lib
# =====================================================================
#  obj_cutscene — PRÓLOGO: "O Herói e o Dragão"
#  Aparece só no NOVO JOGO, depois de escolher a dificuldade e antes do
#  carregamento da fase 1. X / ENTER (ou A / toque) passa as imagens;
#  ESC / BOLA / VOLTAR pula o prólogo. No fim começa o carregamento da fase 1.
#  As imagens ficam em assets/data: cutscene_1.jpg, cutscene_2.jpg, ...
# =====================================================================

var imagens: Array[Texture2D] = []
var indice := 0
var tempo := 0.0
var troca := 0.0
var fase := "fim"
var carregamento_criado := false


func ev_create() -> void:
	audio_cena_definir("cutscene")
	musica("mus_prologo", 800)
	for i in range(1, 31):
		var s := imagem_carregar("cutscene_" + str(i) + ".jpg")
		if s == null:
			break
		imagens.append(s)
	fase = "entrando" if imagens.size() > 0 else "fim"
	G.io_clear()


func ev_cleanup() -> void:
	imagens.clear()


func ev_step() -> void:
	var dt := G.dt_real
	tempo += dt
	var n := imagens.size()
	var passar := G.nav_ok or G.keyboard_check_pressed(KEY_X) or G.mouse_apertado
	var pular := G.nav_voltar
	match fase:
		"entrando":
			if tempo >= 50:
				fase = "mostrando"
				tempo = 0
		"mostrando":
			if pular and tempo > 10:
				fase = "saindo"
				tempo = 0
				som("cut_passar", 0.7, 0)
			elif passar and tempo > 20:
				som("cut_passar", 0.8, 0.03)
				if indice < n - 1:
					fase = "trocando"
					troca = 0
					tempo = 0
				else:
					fase = "saindo"
					tempo = 0
		"trocando":
			troca += dt / 26.0
			if troca >= 1:
				troca = 0
				indice += 1
				fase = "mostrando"
				tempo = 0
		"saindo":
			if tempo >= 45:
				fase = "fim"
				tempo = 0
		"fim":
			if not carregamento_criado:
				carregamento_criado = true
				var l = instance_create_depth(0, 0, -10000, "obj_loading")
				l.modo = "novo_jogo"
				l.destino = "Room1"


func ev_draw_gui() -> void:
	var gw := G.gui_w
	var gh := G.gui_h
	var n := imagens.size()
	draw_set_alpha(1)
	draw_set_color(c_black)
	draw_rectangle(0, 0, gw, gh, false)
	if n == 0 or fase == "fim":
		return
	var i := mini(indice, n - 1)
	var a := 1.0
	if fase == "entrando":
		a = clampf(tempo / 50.0, 0, 1)
	elif fase == "saindo":
		a = clampf(1 - tempo / 45.0, 0, 1)
	imagem_desenhar_ajustada(imagens[i], 0, 0, gw, gh, a)
	if fase == "trocando" and i + 1 < n:
		imagem_desenhar_ajustada(imagens[i + 1], 0, 0, gw, gh, clampf(troca, 0, 1))
	# canto de cima: página e botões
	if fase == "mostrando" or fase == "trocando":
		var ha := clampf((tempo - 20) / 20.0, 0, 1) if fase == "mostrando" else 0.6
		var pisca := 0.75 + 0.25 * sin(current_time() / 180.0)
		var t := ""
		if G.usando_toque and not usando_controle():
			t = "TOQUE NA TELA  continua   ·   PULAR  pula a cena"
		else:
			var conf := nome_confirmar() if usando_controle() else "X / ENTER"
			t = conf + "  continua   ·   " + nome_voltar() + "  pula"
		var pag := str(mini(i + 1 + (1 if fase == "trocando" else 0), n)) + " / " + str(n)
		var w := txt_largura(t, FONTE.MINI) + txt_largura(pag, FONTE.MINI) + 60
		draw_set_alpha(0.55 * ha)
		draw_set_color(c_black)
		draw_roundrect_ext(gw - w - 18, 10, gw - 10, 42, 10, 10, false)
		draw_set_alpha(1)
		txt(gw - 30, 26, t, FONTE.MINI, Color8(235, 220, 190), ha * pisca, fa_right, fa_middle)
		txt(gw - w - 4, 26, pag, FONTE.MINI, Color8(255, 210, 90), ha, fa_left, fa_middle)
	desenho_resetar()
