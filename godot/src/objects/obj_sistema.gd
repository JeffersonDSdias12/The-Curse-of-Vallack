extends Lib
# =====================================================================
#  obj_sistema — controlador único e persistente do jogo
#  * configurações, áudio e leitura dos controles 1x por passo
#  * impacto (hit-stop) e câmera lenta: o "dt" do jogo
#  É criado pelo obj_menu (ou pelo obj_player, ao testar uma fase direto)
#  e nunca é congelado pelas pausas.
# =====================================================================


func ev_create() -> void:
	persistent = true
	depth = -9500      # v1.17: a interface dele (aviso de conquista) fica por cima do HUD
	globais_iniciar()
	config_carregar()
	G.marca_inicio("config")
	audio_iniciar()
	G.marca_inicio("sons")
	G.dt = clampf(60.0 / G.velocidade_jogo, 0.5, 3)
	sala_preparar()


func ev_room_start() -> void:
	sala_preparar()


# ===== BEGIN STEP: roda antes de todos os objetos =====
func ev_step_begin() -> void:
	G.dt_real = clampf(60.0 / G.velocidade_jogo, 0.5, 3)
	# as animações que o End Step congelou (impacto / câmera lenta) voltam ao normal
	for e in todos("obj_entidade"):
		if e.hs_on:
			e.image_speed = e.hs_vel
			e.hs_on = false
	for b in todos("obj_bola_fogo"):
		if b.hs_on:
			b.image_speed = b.hs_vel
			b.hs_on = false
	G.dt = G.dt_real
	if G.hitstop > 0:
		G.hitstop = maxf(0, G.hitstop - G.dt_real)
		G.dt = 0
	elif G.lenta_t > 0:
		G.lenta_t = maxf(0, G.lenta_t - G.dt_real)
		G.dt = G.dt_real * G.lenta_fator
		if G.lenta_t <= 0:
			G.lenta_fator = 1
	if G.room == "rm_menu":
		G.hitstop = 0
		G.lenta_t = 0
		G.lenta_fator = 1
		G.dt = G.dt_real
	# tempo de jogo (só conta com o jogador ativo: pausas e menus não contam)
	if instance_exists("obj_player"):
		G.tempo_jogo += G.dt_real / 60.0
	# áudio: música, ambientes e a pausa abafando o som
	G.audio_pausa = instance_exists("obj_pausa") or instance_exists("obj_menu_armas") or instance_exists("obj_save_menu") or instance_exists("obj_dialogo")
	audio_atualizar()
	if G.orbs_fx > 0:
		G.orbs_fx = maxf(0, G.orbs_fx - G.dt_real)
	if G.essencia_fx > 0:
		G.essencia_fx = maxf(0, G.essencia_fx - G.dt_real)
	if G.fala_espera > 0:
		G.fala_espera -= G.dt
	if G.grito_espera > 0:
		G.grito_espera -= G.dt
	if G.veu_t < G.veu_dur:
		G.veu_t += G.dt_real     # v1.19: véu de transição
	if G.perfil_salvar_t > 0:                 # v1.18: conquistas gravadas juntas (V117.conquista)
		G.perfil_salvar_t -= G.dt_real
		if G.perfil_salvar_t <= 0:
			V117.perfil_salvar_se_mudou()
	if G.fatal_t > 0:
		G.fatal_t -= G.dt_real
	if G.orb_som_t > 0:
		G.orb_som_t -= G.dt_real
	elif not instance_exists("obj_orb"):
		G.orb_seq = 0
	input_atualizar()
	if G.bloqueio_input > 0:
		G.bloqueio_input -= G.dt
	# F1: mostra máscaras de colisão e hitboxes (verificação)
	if G.keyboard_check_pressed(KEY_F1):
		G.debug_hitbox = not G.debug_hitbox
	# F11: tela cheia (computador)
	if G.keyboard_check_pressed(KEY_F11):
		var m := DisplayServer.window_get_mode()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if m == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
	# o app foi para o fundo (Android): no meio da fase, o jogo pausa sozinho
	if G.pausa_auto:
		G.pausa_auto = false
		var p = instance_find("obj_player", 0)
		if G.room != "rm_menu" and p != null and not p.morto and not instance_exists("obj_pausa") and not instance_exists("obj_save_menu") \
				and not instance_exists("obj_menu_armas") and not instance_exists("obj_loading") and not instance_exists("obj_dialogo") \
				and not instance_exists("obj_game_over") and not instance_exists("obj_final") and not instance_exists("obj_resultado"):
			instance_create_depth(0, 0, -10000, "obj_pausa")


# ===== END STEP: impacto (hit-stop) e câmera lenta também param as animações =====
func ev_step_end() -> void:
	var f := 1.0
	if G.hitstop > 0:
		f = 0.0
	elif G.lenta_t > 0:
		f = G.lenta_fator
	if f < 1.0:
		for e in todos("obj_entidade"):
			e.hs_vel = e.image_speed
			e.hs_on = true
			e.image_speed = e.hs_vel * f
		for b in todos("obj_bola_fogo"):
			b.hs_vel = b.image_speed
			b.hs_on = true
			b.image_speed = b.hs_vel * f


# ===== DRAW GUI: depuração (F1) =====
func ev_draw_gui() -> void:
	V117.conquistas_toast_desenhar()     # v1.17: aviso de conquista (por cima de tudo)
	if not G.debug_hitbox:
		return
	var gw := G.gui_w
	var info := "DEPURAÇÃO (F1)  ·  " + str(Engine.get_frames_per_second()) + " FPS  ·  GUI " + str(int(gw)) + "x" + str(int(G.gui_h)) + "  ·  instâncias " + str(G.instancias.size())
	draw_set_alpha(0.7)
	draw_set_color(c_black)
	draw_rectangle(0, GUI_ALTURA - 26, gw, GUI_ALTURA, false)
	txt(10, GUI_ALTURA - 13, info, FONTE.MINI, Color8(120, 255, 140), 1, fa_left, fa_middle)
	desenho_resetar()
