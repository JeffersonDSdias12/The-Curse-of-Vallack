extends Lib
# =====================================================================
#  obj_pausa — menu de pausa e opções rápidas (ESC / SELECT / VOLTAR)
#  * volume da música e dos efeitos
#  * efeito de abrir e fechar (a tela "desce" com um corte carmesim)
#  O jogo fica congelado ao fundo (as instâncias são desativadas).
# =====================================================================

var tempo := 0.0
var abre := 0.0
var fechando := false
var fechar_t := 0.0
var acao_ao_fechar := ""
var selecionado := 0
var mouse_antes := Vector2(-1, -1)
var confirmar := -1
var mudou_config := false
var opcoes := ["CONTINUAR", "VOLUME DA MÚSICA", "VOLUME DOS EFEITOS", "REINICIAR DO CHECKPOINT", "VOLTAR AO MENU", "SAIR DO JOGO"]
var anim: Array = []
var faiscas: Array = []


func ev_create() -> void:
	globais_iniciar()
	anim.resize(opcoes.size())
	anim.fill(0.0)
	mundo_pausar()
	som("sfx_menu_abrir", 0.8, 0)


func opcao_y(i: int) -> float:
	return GUI_ALTURA * 0.33 + i * 56


func fechar_com(acao: String) -> void:
	if fechando:
		return
	fechando = true
	fechar_t = 0
	acao_ao_fechar = acao
	som("sfx_menu_fechar", 0.8, 0)
	if mudou_config:
		config_salvar()
		mudou_config = false


func continuar() -> void:
	mundo_retomar()
	G.io_clear()
	G.bloqueio_input = 10
	instance_destroy()


func mudar_volume(i: int, passo: int) -> void:
	if i == PAUSA_MUSICA:
		G.cfg_vol_musica = clampf(round((G.cfg_vol_musica + passo * 0.1) * 10) / 10.0, 0, 1)
	else:
		G.cfg_vol_efeitos = clampf(round((G.cfg_vol_efeitos + passo * 0.1) * 10) / 10.0, 0, 1)
		som("atk_corte_1", 0.9)
	mudou_config = true


func ev_step() -> void:
	var dt := G.dt_real
	tempo += dt
	var gw := G.gui_w
	var cx := gw / 2.0
	var m := G.mouse_gui()
	var clicou := G.mouse_apertado
	var mexeu := mouse_antes.x != -1 and m != mouse_antes
	mouse_antes = m
	var total := opcoes.size()
	# brasas no rastro do mouse / toque
	for i in (12 if clicou else (2 if mexeu else 0)):
		faiscas.append({"x": m.x + randf_range(-5, 5), "y": m.y + randf_range(-5, 5), "vx": randf_range(-0.8, 0.8), "vy": randf_range(-2.2, -0.6), "vida": float(randi_range(30, 70)), "vmax": 70.0})
	for i in range(faiscas.size() - 1, -1, -1):
		var f: Dictionary = faiscas[i]
		f.x += f.vx * dt
		f.y += f.vy * dt
		f.vida -= dt
		if f.vida <= 0:
			faiscas.remove_at(i)
	# ----- animação de abrir / fechar -----
	if fechando:
		fechar_t += dt
		abre = maxf(0, 1 - fechar_t / 12.0)
		if fechar_t >= 12:
			match acao_ao_fechar:
				"continuar":
					continuar()
				"reiniciar":
					progresso_reverter()
					mundo_retomar()
					G.io_clear()
					G.room_restart()
					instance_destroy()
				"menu":
					var l = instance_create_depth(0, 0, -11000, "obj_loading")
					l.modo = "menu"
					l.destino = "rm_menu"
					instance_destroy()
				"sair":
					G.get_tree().quit()
		return
	abre = minf(1, abre + dt / 14.0)
	# ESC / SELECT / BOLA / VOLTAR continuam o jogo
	if tempo > 8 and (input_pausa_apertada() or (G.pad_slot >= 0 and G.pad_botao_apertado(gp_face2))):
		fechar_com("continuar")
		return
	var sel_antes := selecionado
	if G.nav_cima:
		selecionado = (selecionado + total - 1) % total
		confirmar = -1
	if G.nav_baixo:
		selecionado = (selecionado + 1) % total
		confirmar = -1
	var confirmou := G.nav_ok
	var passo := int(G.nav_dir) - int(G.nav_esq)
	for o in total:
		var oy := opcao_y(o)
		if point_in_rectangle(m.x, m.y, cx - 250, oy - 24, cx + 250, oy + 24):
			if mexeu and selecionado != o:
				selecionado = o
				confirmar = -1
			if clicou:
				selecionado = o
				if o == PAUSA_MUSICA or o == PAUSA_EFEITOS:
					# toque na barra: ajusta direto pela posição
					var bx1 := cx + 20
					var bx2 := cx + 200
					if m.x >= bx1 - 10:
						var v := clampf(round((m.x - bx1) / (bx2 - bx1) * 10) / 10.0, 0, 1)
						if o == PAUSA_MUSICA:
							G.cfg_vol_musica = v
						else:
							G.cfg_vol_efeitos = v
							som("atk_corte_1", 0.9)
						mudou_config = true
					else:
						passo = 1
				else:
					confirmou = true
	if selecionado != sel_antes:
		som("sfx_menu_mover", 0.5, 0)
	if (selecionado == PAUSA_MUSICA or selecionado == PAUSA_EFEITOS) and passo != 0:
		mudar_volume(selecionado, passo)
	if confirmou and tempo > 8 and selecionado != PAUSA_MUSICA and selecionado != PAUSA_EFEITOS:
		# opções que perdem o progresso não salvo pedem confirmação
		if selecionado >= 3 and confirmar != selecionado:
			confirmar = selecionado
			som("sfx_menu_mover", 0.7, 0)
		else:
			som("sfx_menu_ok", 0.7, 0)
			match selecionado:
				0:
					fechar_com("continuar")
					return
				3:
					fechar_com("reiniciar")
					return
				4:
					fechar_com("menu")
					return
				5:
					fechar_com("sair")
					return
	for a in total:
		anim[a] = lerp_dt(anim[a], 1.0 if a == selecionado else 0.0, 0.2)


func ev_draw_gui() -> void:
	var gw := G.gui_w
	var gh := G.gui_h
	var cx := gw / 2.0
	var ouro := Color8(255, 210, 90)
	var ab := clampf(abre, 0, 1)
	var ease := 1 - pow(1 - ab, 3)
	var fade := ease
	draw_set_alpha(0.74 * fade)
	draw_set_color(c_black)
	draw_rectangle(0, 0, gw, gh, false)
	desenhar_vinheta(gw, gh, 0.6 * fade, Color8(40, 0, 4))
	var corte := (1 - ab) if fechando else ab
	if corte < 1:
		gpu_set_blendmode(bm_add)
		var lx := lerpf(-80, gw + 80, corte)
		draw_set_alpha(0.55 * (1 - corte))
		draw_set_color(Color8(220, 30, 30))
		draw_triangle(lx - 220, gh * 0.62, lx + 40, gh * 0.18, lx + 60, gh * 0.2, false)
		draw_set_color(Color8(255, 210, 160))
		draw_line_width(lx - 200, gh * 0.6, lx + 50, gh * 0.19, 2)
		gpu_set_blendmode(bm_normal)
	var desce := (1 - ease) * -26
	txt_sombra(cx, gh * 0.17 + desce, "PAUSADO", FONTE.GRANDE, ouro, fade, fa_center, fa_middle, 1.2)
	desenhar_divisor(cx, gh * 0.17 + 46 + desce, 220, fade)
	var nf := maxi(1, fase_numero(G.room))
	txt(cx, gh * 0.17 + 72 + desce, "CAPÍTULO " + str(nf) + "  ·  " + fase_nome(nf) + "  ·  " + dificuldade_nome(), FONTE.MINI, Color8(190, 170, 130), fade, fa_center, fa_middle)
	for o in opcoes.size():
		var ao := clampf(ease * 1.6 - o * 0.09, 0, 1)
		var oy := opcao_y(o) + (1 - ao) * 18
		var a: float = anim[o]
		desenhar_painel(cx - 250, oy - 24, cx + 250, oy + 24, a, ao)
		var texto: String = opcoes[o]
		var cor := merge_color(c_white, ouro, a)
		if o == PAUSA_MUSICA or o == PAUSA_EFEITOS:
			var vol := G.cfg_vol_musica if o == PAUSA_MUSICA else G.cfg_vol_efeitos
			txt_sombra(cx - 230, oy, texto, FONTE.PEQUENA, cor, ao, fa_left, fa_middle)
			var bx1 := cx + 20
			var bx2 := cx + 200
			draw_set_alpha(ao)
			draw_set_color(Color8(34, 26, 24))
			draw_rectangle(bx1 - 2, oy - 7, bx2 + 2, oy + 7, false)
			var c1 := Color8(255, 120, 60)
			var c2 := Color8(150, 20, 20)
			if vol > 0:
				draw_rectangle_color(bx1, oy - 5, bx1 + (bx2 - bx1) * vol, oy + 5, c2, c1, c1, c2, false)
			draw_set_color(Color8(176, 141, 70))
			draw_rectangle(bx1 - 2, oy - 7, bx2 + 2, oy + 7, true)
			for mk in range(1, 10):
				var mx2 := bx1 + (bx2 - bx1) * mk / 10.0
				draw_set_color(Color8(20, 14, 12))
				draw_line(mx2, oy - 5, mx2, oy + 5)
			txt(cx + 236, oy, str(int(round(vol * 100))) + "%", FONTE.MINI, ouro, ao, fa_right, fa_middle)
			if a > 0.5:
				txt(bx1 - 14, oy, "«", FONTE.PEQUENA, ouro, ao * a, fa_center, fa_middle)
			draw_set_alpha(1)
		else:
			if confirmar == o:
				texto = "CONFIRMAR?  (progresso não salvo será perdido)"
				cor = Color8(255, 120, 90)
			var esc := minf(1 + 0.06 * a, 450 / maxf(1, txt_largura(texto, FONTE.MEDIA)))
			if confirmar == o:
				txt_sombra(cx, oy, texto, FONTE.PEQUENA, cor, ao, fa_center, fa_middle, minf(1, 460 / maxf(1, txt_largura(texto, FONTE.PEQUENA))))
			else:
				txt_sombra(cx, oy, texto, FONTE.MEDIA, cor, ao, fa_center, fa_middle, esc)
		if a > 0.05:
			draw_set_alpha(a * ao)
			desenhar_espada(cx - 250 - 62 + 22 * a, oy, 1)
			desenhar_espada(cx + 250 + 62 - 22 * a, oy, -1)
			draw_set_alpha(1)
	var rod := ""
	if G.usando_toque and not usando_controle():
		rod = "Toque numa opção   ·   VOLTAR continua   ·   toque na barra para mudar o volume"
	else:
		rod = (nome_pausa() + " / " + nome_voltar() if usando_controle() else "ESC") + " continua   ·   « » muda o volume   ·   " + botao_menu_armas() + " no jogo abre as ARMAS"
	txt(cx, gh - 30, rod, FONTE.MINI, Color8(170, 170, 175), fade, fa_center, fa_middle, minf(1, (gw - 40) / maxf(1, txt_largura(rod, FONTE.MINI))))
	gpu_set_blendmode(bm_add)
	for f in faiscas:
		var p: float = f.vida / f.vmax
		draw_set_alpha(minf(1, p * 1.5))
		draw_set_color(Color8(255, int(120 + 120 * p), 40))
		draw_circle(f.x, f.y, 2.5, false)
	gpu_set_blendmode(bm_normal)
	desenho_resetar()
