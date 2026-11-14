extends Lib
# =====================================================================
#  obj_game_over — tela de derrota
# =====================================================================

var tempo := 0.0
var alpha := 0.0
var selecionado := 0
var mouse_antes := Vector2(-1, -1)
var opcoes := ["TENTAR NOVAMENTE", "VOLTAR AO MENU"]
var anim := [0.0, 0.0]


func ev_create() -> void:
	globais_iniciar()


func botao_y(i: int) -> float:
	return GUI_ALTURA / 2.0 + 70 + i * 62


func ev_step() -> void:
	var dt := G.dt_real
	tempo += dt
	alpha = minf(1, tempo / 60.0)
	var cx := G.gui_w / 2.0
	var m := G.mouse_gui()
	var mexeu := mouse_antes.x != -1 and m != mouse_antes
	mouse_antes = m
	if tempo - dt < 2 and tempo >= 2:
		som("sfx_derrota", 0.9, 0)
	if tempo < 40:
		return
	if G.nav_cima or G.nav_baixo:
		selecionado = 1 - selecionado
		som("sfx_menu_mover", 0.5, 0)
	var ok := G.nav_ok
	for i in 2:
		var by := botao_y(i)
		if point_in_rectangle(m.x, m.y, cx - 190, by - 24, cx + 190, by + 24):
			if mexeu:
				selecionado = i
			if G.mouse_apertado:
				selecionado = i
				ok = true
	for a in 2:
		anim[a] = lerp_dt(anim[a], 1.0 if a == selecionado else 0.0, 0.2)
	if ok and not instance_exists("obj_loading"):
		som("sfx_menu_ok", 0.8, 0)
		if selecionado == 0:
			# recomeça do último checkpoint (ou do início da fase);
			# orbs e contadores voltam ao que eram no checkpoint
			progresso_reverter()
			G.room_restart()
		else:
			var l = instance_create_depth(0, 0, -11000, "obj_loading")
			l.modo = "menu"
			l.destino = "rm_menu"


func ev_draw_gui() -> void:
	var gw := G.gui_w
	var gh := G.gui_h
	var cx := gw / 2.0
	draw_set_alpha(alpha * 0.82)
	draw_set_color(c_black)
	draw_rectangle(0, 0, gw, gh, false)
	desenhar_vinheta(gw, gh, alpha * 0.8, Color8(90, 0, 0))
	txt_amaldicoado(cx, gh / 2 - 60, "VOCÊ MORREU", FONTE.TITULO, Color8(210, 20, 20), tempo - 10, 5, minf(0.9, (gw * 0.8) / maxf(1, txt_largura("VOCÊ MORREU", FONTE.TITULO))), alpha)
	var ba := clampf((tempo - 40) / 20.0, 0, 1)
	for i in 2:
		var by := botao_y(i)
		desenhar_painel(cx - 190, by - 24, cx + 190, by + 24, anim[i], ba)
		txt(cx, by, opcoes[i], FONTE.MEDIA, merge_color(c_white, Color8(255, 210, 90), anim[i]), ba, fa_center, fa_middle)
	var cp := "Você voltará ao último checkpoint." if (G.checkpoint_ativo and G.room == G.checkpoint_room) else "Você voltará ao início da fase."
	txt(cx, botao_y(1) + 56, cp, FONTE.MINI, Color8(170, 170, 175), ba, fa_center, fa_middle)
	desenho_resetar()
