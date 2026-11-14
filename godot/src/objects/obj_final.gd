extends Lib
# =====================================================================
#  obj_final — fim do jogo (Fase 2 sem nenhum inimigo)
#  tela escurece -> "CONTINUA..." (efeito amaldiçoado) -> carregamento ->
#  volta ao menu inicial.
# =====================================================================

var fase := "escurecer"
var tempo := 0.0
var duracao_texto := 420.0
var brasas: Array = []


func ev_create() -> void:
	globais_iniciar()
	G.jogo_finalizado = true
	som("fase_concluida", 1, 0)


func ev_step() -> void:
	var dt := G.dt_real
	tempo += dt
	match fase:
		"escurecer":
			# o último inimigo caiu: a tela escurece devagar
			if tempo >= 150:
				mundo_pausar()
				fase = "continua"
				tempo = 0
		"continua":
			if tempo >= duracao_texto:
				fase = "continua_sai"
				tempo = 0
		"continua_sai":
			if tempo >= 50:
				fase = "creditos"
				tempo = 0
		"creditos":
			# os nomes da equipe sobem pela tela; tocar / ENTER acelera
			if (input_confirmar_pergaminho() or G.mouse_apertado) and tempo > 60:
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
	# brasas vermelhas subindo
	if fase != "escurecer" and G.cfg_qualidade > 0 and brasas.size() < 50 and randf() < 0.5 * dt:
		brasas.append({"x": randf() * G.gui_w, "y": GUI_ALTURA + 6.0, "vy": randf_range(-1.4, -0.4), "vida": float(randi_range(80, 200)), "vmax": 200.0})
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
	if fase == "escurecer":
		draw_set_alpha(clampf(tempo / 150.0, 0, 1))
		draw_set_color(c_black)
		draw_rectangle(0, 0, gw, gh, false)
		draw_set_alpha(1)
		return
	draw_set_color(c_black)
	draw_rectangle(0, 0, gw, gh, false)
	# créditos com os nomes da equipe
	if fase == "creditos" or fase == "sair":
		desenhar_vinheta(gw, gh, 0.8, Color8(40, 0, 0))
		var ac := clampf(tempo / 40.0, 0, 1) if fase == "creditos" else maxf(0, 1 - tempo / 50.0)
		creditos_desenhar(tempo if fase == "creditos" else creditos_duracao() + 240, ac)
		_desenhar_brasas(1.0)
		return
	var sai := 1 - clampf(tempo / 50.0, 0, 1) if fase == "continua_sai" else 1.0
	var t := tempo if fase == "continua" else duracao_texto
	# brilho vermelho pulsando atrás do texto
	var pulso := 0.2 + 0.1 * sin(current_time() / 300.0)
	gpu_set_blendmode(bm_add)
	draw_set_alpha(pulso * sai * clampf(t / 60.0, 0, 1))
	draw_set_color(Color8(110, 0, 12))
	draw_ellipse(cx - gw * 0.35, gh / 2 - 120, cx + gw * 0.35, gh / 2 + 120, false)
	gpu_set_blendmode(bm_normal)
	draw_set_alpha(1)
	# "CONTINUA..." letra por letra
	var esc := minf(1.15, (gw * 0.85) / maxf(1, txt_largura("CONTINUA...", FONTE.TITULO)))
	txt_amaldicoado(cx, gh / 2 - 10, "CONTINUA...", FONTE.TITULO, Color8(235, 40, 40), t - 20, 9, esc, sai)
	var fa := clampf((t - 160) / 40.0, 0, 1) * sai
	txt(cx, gh / 2 + 78, "A maldição de Vallack ainda não foi quebrada.", FONTE.PEQUENA, Color8(200, 195, 195), fa, fa_center, fa_middle)
	var fb := clampf((t - 230) / 40.0, 0, 1) * sai
	txt(cx, gh / 2 + 112, "A jornada de Twilight continua.  Obrigado por jogar!", FONTE.MINI, Color8(255, 210, 90), fb, fa_center, fa_middle)
	_desenhar_brasas(sai)


func _desenhar_brasas(alfa: float) -> void:
	gpu_set_blendmode(bm_add)
	for b in brasas:
		draw_set_alpha(clampf(b.vida / b.vmax, 0, 1) * 0.7 * alfa)
		draw_set_color(Color8(220, 50, 30))
		draw_circle(b.x, b.y, 1.8, false)
	gpu_set_blendmode(bm_normal)
	desenho_resetar()
