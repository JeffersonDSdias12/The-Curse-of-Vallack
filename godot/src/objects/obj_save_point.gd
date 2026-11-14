extends Lib
# =====================================================================
#  obj_save_point — CRISTAL DOURADO (2 por fase, no início e no meio)
#  * ao chegar perto: vira o checkpoint e salva automaticamente
#  * INTERAGIR: abre a tela de salvar e recupera a vida (menos no EXTREMO)
# =====================================================================

var perto := false
var marcado := false
var marcado_fx := 0.0


func ev_create() -> void:
	image_alpha = 0


func ev_step() -> void:
	var p = instance_find("obj_player", 0)
	perto = p != null and point_distance(x, y, p.x, p.y) < 70
	if marcado_fx > 0:
		marcado_fx -= G.dt
	# primeira vez perto: este cristal vira o checkpoint
	if not marcado and p != null and not p.morto and absf(p.x - x) < 90 and absf(p.y - y) < 120 and not G.transicao_fase:
		marcado = true
		marcado_fx = 45
		var novo := not (G.checkpoint_ativo and G.checkpoint_room == G.room and absf(G.checkpoint_x - p.x) < 120)
		salvar_slot(G.save_slot_atual, false)
		if novo:
			aviso_mostrar("CHECKPOINT  ·  JOGO SALVO AUTOMATICAMENTE", false)


func ev_draw() -> void:
	var t := current_time() / 16.0
	var cy := y - 40 + sin(current_time() / 400.0) * 4
	desenhar_cristal(x, cy, 11, Color8(235, 175, 60), Color8(255, 215, 110), 1.0 if perto else 0.65, t)
	if marcado_fx > 0:
		var k := 1 - marcado_fx / 45.0
		gpu_set_blendmode(bm_add)
		draw_set_alpha(1 - k)
		draw_set_color(Color8(255, 200, 90))
		draw_circle(x, cy, 10 + 70 * k, true)
		draw_circle(x, cy, 8 + 50 * k, true)
		gpu_set_blendmode(bm_normal)
		draw_set_alpha(1)
	if perto:
		gpu_set_texfilter(true)
		var acao := " SALVAR E RECUPERAR VIDA" if dif_cristal_cura() else " SALVAR"
		txt(x, cy - 30, rotulo_acao(ACAO.INTERAGIR) + acao, FONTE.MINI, c_white, 1, fa_center, fa_bottom, 0.55)
		gpu_set_texfilter(false)
	desenho_resetar()
